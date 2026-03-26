--[[
文件定位:
  DejaVu 通用单位状态显示模块。



状态:
  draft
]]

-- luacheck: globals LibStub UnitHealthPercent UnitPowerPercent UnitClass UnitGroupRolesAssigned UnitIsUnit UnitIsEnemy UnitIsDeadOrGhost UnitPowerType UnitChannelDuration UnitCastingDuration UnitAffectingCombat UnitCastingInfo UnitChannelInfo
local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local print = print
local select = select
local insert = table.insert

-- WoW 官方 API
local UnitHealthPercent = UnitHealthPercent
local UnitPowerPercent = UnitPowerPercent
local UnitClass = UnitClass
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitIsUnit = UnitIsUnit
local UnitIsEnemy = UnitIsEnemy
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitExists = UnitExists
local UnitCanAttack = UnitCanAttack
local UnitPowerType = UnitPowerType
local UnitChannelDuration = UnitChannelDuration
local UnitCastingDuration = UnitCastingDuration
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean
local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo

-- 第三方库
local LibStub = LibStub
local LRC = LibStub("LibRangeCheck-3.0")
if not LRC then
    print("|cffff0000[单位状态]|r LibRangeCheck-3.0 未找到, 模块无法工作。")
    return
end

-- 插件内引用
local InitUI = addonTable.Listeners.InitUI                           -- 初始化 UI 函数列表
local COLOR = addonTable.COLOR                                       -- 颜色表
local Cell = addonTable.Cell                                         -- 基础色块单元
local BadgeCell = addonTable.BadgeCell                               -- 图标单元

local OnUpdateHigh = addonTable.Listeners.OnUpdateHigh               -- 高频刷新回调列表
local OnUpdateLow = addonTable.Listeners.OnUpdateLow                 -- 低频刷新回调列表
local TARGET_CHANGED = addonTable.Listeners.TARGET_CHANGED           -- 目标变化回调列表
local FOCUS_CHANGED = addonTable.Listeners.FOCUS_CHANGED             -- 焦点变化回调列表
local MOUSEOVER_CHANGED = addonTable.Listeners.MOUSEOVER_CHANGED     -- 鼠标悬停单位存在状态变化回调列表
local UNIT_CAST_CHANGED = addonTable.Listeners.UNIT_CAST_CHANGED     -- UNIT_SPELLCAST 回调列表
local UNIT_HEALTH_CHANGED = addonTable.Listeners.UNIT_HEALTH_CHANGED -- 单位生命变化回调列表
local UNIT_POWER_CHANGED = addonTable.Listeners.UNIT_POWER_CHANGED   -- 单位能量变化回调列表

local zeroToOneCurve = addonTable.Slots.zeroToOneCurve               -- 0-1 百分比颜色曲线



local function UnitStatusSequenceCreator(options)                   -- 创建一组单位状态显示槽位
    local unit = options.unit                                       -- 目标单位
    local posX = options.posX                                       -- 左上角 x 坐标
    local posY = options.posY                                       -- 左上角 y 坐标
    local cell = {}                                                 -- 单元格对象列表
    cell.unitExists = Cell:New(posX + 0, posY + 0)                  -- 单位存在状态
    cell.unitIsAlive = Cell:New(posX + 0, posY + 1)                 -- 单位是否存活
    cell.unitClass = Cell:New(posX + 1, posY + 0)                   -- 单位职业
    cell.unitRole = Cell:New(posX + 1, posY + 1)                    -- 单位角色
    cell.unitHealthPercent = Cell:New(posX + 2, posY + 0)           -- 单位生命值百分比
    cell.unitPowerPercent = Cell:New(posX + 2, posY + 1)            -- 单位能量百分比
    cell.unitIsEnemy = Cell:New(posX + 3, posY + 0)                 -- 单位是否敌对
    cell.unitCanAttack = Cell:New(posX + 3, posY + 1)               -- 单位是否可攻击
    cell.unitIsInRangedRange = Cell:New(posX + 4, posY + 0)         -- 单位是否在远程范围内
    cell.unitIsInMeleeRange = Cell:New(posX + 4, posY + 1)          -- 单位是否在近战范围内
    cell.unitIsInCombat = Cell:New(posX + 5, posY + 0)              -- 单位是否在战斗中
    cell.unitIsTarget = Cell:New(posX + 5, posY + 1)                -- 单位是否为目标
    cell.unitCastIcon = BadgeCell:New(posX + 6, posY + 0)           -- 单位施法图标
    cell.unitChannelIcon = BadgeCell:New(posX + 8, posY + 0)        -- 单位通道图标
    cell.unitCastDuration = Cell:New(posX + 10, posY + 0)           -- 单位施法持续时间
    cell.unitChannelDuration = Cell:New(posX + 10, posY + 1)        -- 单位通道持续时间
    cell.unitCastIsInterruptible = Cell:New(posX + 11, posY + 0)    -- 单位施法是否可中断
    cell.unitChannelIsInterruptible = Cell:New(posX + 11, posY + 1) -- 单位通道是否可中断

    local function clearAllCells()
        cell.unitExists:clearCell()
        cell.unitIsAlive:clearCell()
        cell.unitClass:clearCell()
        cell.unitRole:clearCell()
        cell.unitHealthPercent:clearCell()
        cell.unitPowerPercent:clearCell()
        cell.unitIsEnemy:clearCell()
        cell.unitCanAttack:clearCell()
        cell.unitCastIcon:clearCell()
        cell.unitChannelIcon:clearCell()
        cell.unitCastDuration:clearCell()
        cell.unitChannelDuration:clearCell()
        cell.unitCastIsInterruptible:clearCell()
        cell.unitChannelIsInterruptible:clearCell()
        cell.unitIsInRangedRange:clearCell()
        cell.unitIsInMeleeRange:clearCell()
        cell.unitIsInCombat:clearCell()
        cell.unitIsTarget:clearCell()
    end

    local unitExists = false
    if unit == "player" then
        unitExists = true
    end

    local function updateHighFrequency()
        unitExists = UnitExists(unit)
        if not unitExists then
            return
        end
        cell.unitIsAlive:setCellBoolean(UnitIsDeadOrGhost(unit), COLOR.BLACK, COLOR.STATUS_BOOLEAN.IS_ALIVE)          -- 单位是否存活
        cell.unitIsInCombat:setCellBoolean(UnitAffectingCombat(unit), COLOR.STATUS_BOOLEAN.IS_IN_COMBAT, COLOR.BLACK) -- 单位是否在战斗中
        cell.unitIsTarget:setCellBoolean(UnitIsUnit(unit, "target"), COLOR.STATUS_BOOLEAN.IS_TARGET, COLOR.BLACK)     -- 单位是否为目标
    end
    insert(OnUpdateHigh, updateHighFrequency)

    local function updateLowFrequency()
        if not unitExists then
            return
        end
        local maxRange = select(2, LRC:GetRange(unit)) or 99
        cell.unitClass:setCell(COLOR.CLASS[select(2, UnitClass(unit))])                                                                   -- 单位职业
        cell.unitRole:setCell(COLOR.ROLE[UnitGroupRolesAssigned(unit)] or COLOR.ROLE.NONE)                                                -- 单位角色
        cell.unitIsEnemy:setCellBoolean(UnitIsEnemy(unit, "player"), COLOR.STATUS_BOOLEAN.IS_ENEMY, COLOR.BLACK)                          -- 单位是否敌对
        cell.unitCanAttack:setCellBoolean(UnitCanAttack(unit, "player"), COLOR.STATUS_BOOLEAN.CAN_ATTACK, COLOR.BLACK)                    -- 单位是否可攻击
        cell.unitIsInRangedRange:setCellBoolean(maxRange <= addonTable.RangedRange, COLOR.STATUS_BOOLEAN.IS_IN_RANGED_RANGE, COLOR.BLACK) -- 单位是否在远程范围内
        cell.unitIsInMeleeRange:setCellBoolean(maxRange <= 5, COLOR.STATUS_BOOLEAN.IS_IN_MELEE_RANGE, COLOR.BLACK)                        -- 单位是否在近战范围内
    end
    insert(OnUpdateLow, updateLowFrequency)

    local function updateHealthPercentCell()
        if not unitExists then
            return
        end
        cell.unitHealthPercent:setCell(UnitHealthPercent(unit, true, zeroToOneCurve)) -- 单位生命值百分比
    end
    insert(UNIT_HEALTH_CHANGED, { unit = unit, func = updateHealthPercentCell })

    local function updatePowerPercentCell()
        if not unitExists then
            return
        end
        cell.unitPowerPercent:setCell(UnitPowerPercent(unit, UnitPowerType(unit), true, zeroToOneCurve)) -- 单位能量百分比
    end
    insert(UNIT_POWER_CHANGED, { unit = unit, func = updatePowerPercentCell })

    local unitIsCasting = false
    local unitIsChanneling = false

    local function getUnitSpellColor()
        local spellInterruptibleColor = COLOR.SPELL_TYPE.ENEMY_SPELL_INTERRUPTIBLE
        local spellNotInterruptibleColor = COLOR.SPELL_TYPE.ENEMY_SPELL_NOT_INTERRUPTIBLE
        if not UnitCanAttack(unit, "player") then
            spellInterruptibleColor = COLOR.SPELL_TYPE.PLAYER_SPELL
            spellNotInterruptibleColor = COLOR.SPELL_TYPE.PLAYER_SPELL
        end
        return spellInterruptibleColor, spellNotInterruptibleColor
    end

    local function updateCastVisual()
        if not unitExists then
            return
        end

        local spellInterruptibleColor, spellNotInterruptibleColor = getUnitSpellColor()
        local unitCastIcon = select(3, UnitCastingInfo(unit))
        local unitCastNotInterruptible = select(8, UnitCastingInfo(unit))
        if unitCastIcon then
            unitIsCasting = true
            unitIsChanneling = false
            cell.unitCastIcon:setCell(
                unitCastIcon,
                EvaluateColorFromBoolean(
                    unitCastNotInterruptible,
                    spellNotInterruptibleColor,
                    spellInterruptibleColor
                )
            ) -- 单位施法图标
            cell.unitCastIsInterruptible:setCellBoolean(
                unitCastNotInterruptible,
                spellNotInterruptibleColor,
                spellInterruptibleColor
            )                                           -- 单位施法是否可中断
            cell.unitChannelIcon:clearCell()            -- 单位通道施法图标
            cell.unitChannelIsInterruptible:clearCell() -- 单位通道施法是否可中断
            cell.unitChannelDuration:clearCell()        -- 单位通道施法持续时间
        else
            unitIsCasting = false
            cell.unitCastIcon:clearCell()            -- 单位施法图标
            cell.unitCastIsInterruptible:clearCell() -- 单位施法是否可中断
        end
    end

    local function updateChannelVisual()
        if not unitExists then
            return
        end

        local spellInterruptibleColor, spellNotInterruptibleColor = getUnitSpellColor()
        local unitChannelIcon = select(3, UnitChannelInfo(unit))
        local unitChannelNotInterruptible = select(7, UnitChannelInfo(unit))
        if unitChannelIcon then
            unitIsChanneling = true
            cell.unitChannelIcon:setCell(
                unitChannelIcon,
                EvaluateColorFromBoolean(
                    unitChannelNotInterruptible,
                    spellNotInterruptibleColor,
                    spellInterruptibleColor
                )
            ) -- 单位通道施法图标
            cell.unitChannelIsInterruptible:setCellBoolean(
                unitChannelNotInterruptible,
                spellNotInterruptibleColor,
                spellInterruptibleColor
            )                                        -- 单位通道施法是否可中断
            cell.unitCastIcon:clearCell()            -- 单位施法图标
            cell.unitCastIsInterruptible:clearCell() -- 单位施法是否可中断
            cell.unitCastDuration:clearCell()        -- 单位施法持续时间
        else
            unitIsChanneling = false
            cell.unitChannelIcon:clearCell()            -- 单位通道施法图标
            cell.unitChannelIsInterruptible:clearCell() -- 单位通道施法是否可中断
        end
    end

    local function updateCastState()
        if not unitExists then
            return
        end

        updateCastVisual()
        if unitIsCasting then
            return -- 在施法就不可能在通道, 这里可以直接返回
        end

        updateChannelVisual()
    end
    -- if unit == "mouseover" then
    insert(OnUpdateHigh, updateCastState)
    -- else
    -- insert(UNIT_CAST_CHANGED, { unit = unit, func = updateCastState })
    -- end

    local function updateCastDuration()
        if not unitExists then
            return
        end

        local unitCastDuration = unitIsCasting and UnitCastingDuration(unit) or nil
        if unitCastDuration then
            cell.unitCastDuration:setCell(unitCastDuration:EvaluateElapsedPercent(zeroToOneCurve)) -- 单位施法持续时间
        else
            cell.unitCastDuration:clearCell()                                                      -- 单位施法持续时间
        end

        local unitChannelDuration = unitIsChanneling and UnitChannelDuration(unit) or nil
        if unitChannelDuration then
            cell.unitChannelDuration:setCell(unitChannelDuration:EvaluateElapsedPercent(zeroToOneCurve)) -- 单位通道施法持续时间
        else
            cell.unitChannelDuration:clearCell()                                                         -- 单位通道施法持续时间
        end
    end
    insert(OnUpdateHigh, updateCastDuration)

    local function updateFullStatus()
        if not UnitExists(unit) then
            unitExists = false
            clearAllCells()
        else
            unitExists = true
            cell.unitExists:setCell(COLOR.STATUS_BOOLEAN.EXISTS) -- 单位存在状态
            updateHighFrequency()
            updateLowFrequency()
            updateHealthPercentCell()
            updatePowerPercentCell()
            updateCastState()
            updateCastDuration()
        end
    end
    updateFullStatus()

    if unit == "target" then
        insert(TARGET_CHANGED, updateFullStatus)
    elseif unit == "focus" then
        insert(FOCUS_CHANGED, updateFullStatus)
    elseif unit == "mouseover" then
        insert(MOUSEOVER_CHANGED, updateFullStatus)
    end
    -- insert(OnUpdateLow, updateFullStatus)
end

local function InitializeUniversalUnitStatus() -- 初始化通用单位状态槽位
    UnitStatusSequenceCreator {                -- 目标状态槽位
        unit = "target",                       -- 目标单位
        posX = 55,                             -- 起始 x 坐标
        posY = 10,                             -- 起始 y 坐标
    }
    UnitStatusSequenceCreator {                -- 焦点状态槽位
        unit = "focus",                        -- 焦点单位
        posX = 70,                             -- 起始 x 坐标
        posY = 10,                             -- 起始 y 坐标
    }
    UnitStatusSequenceCreator {                -- 鼠标悬停状态槽位
        unit = "mouseover",                    -- 鼠标悬停单位
        posX = 70,                             -- 起始 x 坐标
        posY = 12,                             -- 起始 y 坐标
    }
end

insert(InitUI, InitializeUniversalUnitStatus) -- 注册通用单位状态初始化入口
