--[[
文件: 53_party_status.lua
定位: DejaVu 队伍单位状态模块


状态:
  waiting_real_test（今日接通, 待实战验证）
]]

local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local string_format = string.format
local insert = table.insert

-- WoW 官方 API
local UnitCanAttack = UnitCanAttack
local UnitExists = UnitExists
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local GetUnitAuraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs

-- 第三方库
local LibStub = LibStub
local LRC = LibStub("LibRangeCheck-3.0")

-- 插件内引用
local InitUI = addonTable.Listeners.InitUI
local PARTY_CHANGED = addonTable.Listeners.PARTY_CHANGED
local COLOR = addonTable.COLOR                                       -- 颜色表
local Cell = addonTable.Cell                                         -- 基础色块单元
local OnUpdateHigh = addonTable.Listeners.OnUpdateHigh               -- 高频刷新回调列表
local OnUpdateLow = addonTable.Listeners.OnUpdateLow                 -- 低频刷新回调列表
local UNIT_HEALTH_CHANGED = addonTable.Listeners.UNIT_HEALTH_CHANGED -- 单位生命变化回调列表
local UNIT_POWER_CHANGED = addonTable.Listeners.UNIT_POWER_CHANGED   -- 单位能量变化回调列表
local UNIT_AURA_CHANGED = addonTable.Listeners.UNIT_AURA_CHANGED     -- 单位Aura变化回调列表
local zeroToOneCurve = addonTable.Slots.zeroToOneCurve               -- 0-1 百分比颜色曲线
if not LRC then
    print("|cffff0000[单位状态]|r LibRangeCheck-3.0 未找到, 模块无法工作。")
    return
end


local function InitializePartyBar()
    for partyIndex = 1, 4 do
        local unitToken = string_format("party%d", partyIndex)
        local baseX = 21 * partyIndex
        local cell = {}
        cell.unitExists = Cell:New(baseX - 9, 24)               -- 单位存在状态
        cell.unitIsAlive = Cell:New(baseX - 9, 25)              -- 单位是否存活
        cell.unitClass = Cell:New(baseX - 8, 24)                -- 单位职业
        cell.unitRole = Cell:New(baseX - 8, 25)                 -- 单位角色
        cell.unitHealthPercent = Cell:New(baseX - 7, 24)        -- 单位生命值百分比
        cell.unitPowerPercent = Cell:New(baseX - 7, 25)         -- 单位能量百分比
        cell.unitIsEnemy = Cell:New(baseX - 6, 24)              -- 单位是否敌对
        cell.unitCanAttack = Cell:New(baseX - 6, 25)            -- 单位是否可攻击
        cell.unitIsInRangedRange = Cell:New(baseX - 5, 24)      -- 单位是否在远程范围内
        cell.unitIsInMeleeRange = Cell:New(baseX - 5, 25)       -- 单位是否在近战范围内
        cell.unitIsInCombat = Cell:New(baseX - 4, 24)           -- 单位是否在战斗中
        cell.unitIsTarget = Cell:New(baseX - 4, 25)             -- 单位是否为目标
        cell.unitHasBigDefense = Cell:New(baseX - 3, 24)        -- 有大防御值
        cell.unitHasDispellableDebuff = Cell:New(baseX - 3, 25) -- 有可驱散的减益效果
        local unitExists = false

        local function updateHighFrequency()
            if not unitExists then
                return
            end
            cell.unitExists:setCellBoolean(unitExists, COLOR.STATUS_BOOLEAN.EXISTS, COLOR.BLACK)
            cell.unitIsAlive:setCellBoolean(UnitIsDeadOrGhost(unitToken), COLOR.BLACK, COLOR.STATUS_BOOLEAN.IS_ALIVE)          -- 单位是否存活
            cell.unitIsInCombat:setCellBoolean(UnitAffectingCombat(unitToken), COLOR.STATUS_BOOLEAN.IS_IN_COMBAT, COLOR.BLACK) -- 单位是否在战斗中
            cell.unitIsTarget:setCellBoolean(UnitIsUnit(unitToken, "target"), COLOR.STATUS_BOOLEAN.IS_TARGET, COLOR.BLACK)     -- 单位是否为目标
        end
        insert(OnUpdateHigh, updateHighFrequency)

        local function updateLowFrequency()
            unitExists = UnitExists(unitToken)
            if not unitExists then
                return
            end
            cell.unitClass:setCell(COLOR.CLASS[select(2, UnitClass(unitToken))])                                                              -- 单位职业
            cell.unitRole:setCell(COLOR.ROLE[UnitGroupRolesAssigned(unitToken)] or COLOR.ROLE.NONE)                                           -- 单位角色
            local maxRange = select(2, LRC:GetRange(unitToken)) or 99
            cell.unitIsEnemy:setCellBoolean(UnitIsEnemy(unitToken, "player"), COLOR.STATUS_BOOLEAN.IS_ENEMY, COLOR.BLACK)                     -- 单位是否敌对
            cell.unitCanAttack:setCellBoolean(UnitCanAttack(unitToken, "player"), COLOR.STATUS_BOOLEAN.CAN_ATTACK, COLOR.BLACK)               -- 单位是否可攻击
            cell.unitIsInRangedRange:setCellBoolean(maxRange <= addonTable.RangedRange, COLOR.STATUS_BOOLEAN.IS_IN_RANGED_RANGE, COLOR.BLACK) -- 单位是否在远程范围内
            cell.unitIsInMeleeRange:setCellBoolean(maxRange <= 5, COLOR.STATUS_BOOLEAN.IS_IN_MELEE_RANGE, COLOR.BLACK)                        -- 单位是否在近战范围内
        end
        insert(OnUpdateLow, updateLowFrequency)

        local function updateHealthPercentCell()
            if not unitExists then
                return
            end
            cell.unitHealthPercent:setCell(UnitHealthPercent(unitToken, true, zeroToOneCurve)) -- 单位生命值百分比
        end
        insert(UNIT_HEALTH_CHANGED, { unit = unitToken, func = updateHealthPercentCell })

        local function updatePowerPercentCell()
            if not unitExists then
                return
            end
            cell.unitPowerPercent:setCell(UnitPowerPercent(unitToken, UnitPowerType(unitToken), true, zeroToOneCurve)) -- 单位能量百分比
        end
        insert(UNIT_POWER_CHANGED, { unit = unitToken, func = updatePowerPercentCell })

        local function updateOnAuraEvent()
            local bigDefenseTable = GetUnitAuraInstanceIDs(unitToken, "HELPFUL|BIG_DEFENSIVE")
            local dispellableDebuffTable = GetUnitAuraInstanceIDs(unitToken, "HARMFUL|RAID_PLAYER_DISPELLABLE")
            cell.unitHasBigDefense:setCellBoolean(#bigDefenseTable > 0, COLOR.STATUS_BOOLEAN.HAS_BIG_DEFENSE, COLOR.BLACK)
            cell.unitHasDispellableDebuff:setCellBoolean(#dispellableDebuffTable > 0, COLOR.STATUS_BOOLEAN.HAS_DISPELLABLE_DEBUFF, COLOR.BLACK)
        end
        insert(UNIT_AURA_CHANGED, { unit = unitToken, func = updateOnAuraEvent })


        local function updateOnParthChanged()
            unitExists = UnitExists(unitToken)
            cell.unitClass:setCell(COLOR.CLASS[select(2, UnitClass(unitToken))])                    -- 单位职业
            cell.unitRole:setCell(COLOR.ROLE[UnitGroupRolesAssigned(unitToken)] or COLOR.ROLE.NONE) -- 单位角色
            updateHighFrequency()
            updateLowFrequency()
            updateHealthPercentCell()
            updatePowerPercentCell()
            updateOnAuraEvent()
        end
        insert(PARTY_CHANGED, updateOnParthChanged)
        updateOnParthChanged()
    end
end

insert(InitUI, InitializePartyBar)
