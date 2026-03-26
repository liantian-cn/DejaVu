--[[
文件定位:
  DejaVu 玩家状态槽位模块。

状态:
  draft
]]

local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local min = math.min
local insert = table.insert

-- WoW 官方 API
local GetCurrentKeyBoardFocus = GetCurrentKeyBoardFocus
local GetInventoryItemID = GetInventoryItemID
local GetUnitSpeed = GetUnitSpeed
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local IsMounted = IsMounted
local IsUsableItem = C_Item.IsUsableItem
local SpellIsTargeting = SpellIsTargeting
local UnitCanAttack = UnitCanAttack
local UnitChannelInfo = UnitChannelInfo
local UnitEmpoweredStageDurations = UnitEmpoweredStageDurations
local UnitExists = UnitExists
local UnitInVehicle = UnitInVehicle
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local GetUnitAuraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs

local GetItemCooldown = C_Container.GetItemCooldown

-- 第三方库
local LibStub = LibStub
local LRC = LibStub("LibRangeCheck-3.0")
if not LRC then
    print("|cffff0000[玩家状态]|r LibRangeCheck-3.0 未找到, 模块无法工作。")
    return
end

-- 插件内引用
local InitUI = addonTable.Listeners.InitUI                           -- 初始化入口列表
local COLOR = addonTable.COLOR                                       -- 颜色表
local Cell = addonTable.Cell                                         -- 基础色块单元
local BadgeCell = addonTable.BadgeCell                               -- BadgeCell
local OnUpdateHigh = addonTable.Listeners.OnUpdateHigh               -- 高频刷新回调列表
local OnUpdateLow = addonTable.Listeners.OnUpdateLow                 -- 低频刷新回调列表
local UNIT_CAST_CHANGED = addonTable.Listeners.UNIT_CAST_CHANGED     -- 单位施法改变事件列表
local UNIT_HEALTH_CHANGED = addonTable.Listeners.UNIT_HEALTH_CHANGED -- 单位生命值改变事件列表
local UNIT_POWER_CHANGED = addonTable.Listeners.UNIT_POWER_CHANGED   -- 单位能量百分改变事件列表
local UNIT_AURA_CHANGED = addonTable.Listeners.UNIT_AURA_CHANGED     -- 单位法术改变事件列表

local zeroToOneCurve = addonTable.Slots.zeroToOneCurve               -- 0-1 百分比颜色曲线


local function itemUsable(itemId)
    if not itemId then
        return false
    end

    local startTime, duration, enable = GetItemCooldown(itemId) -- luacheck: ignore startTime
    local usable, noMana = IsUsableItem(itemId)
    return enable == 1 and duration == 0 and usable and not noMana
end

local function slotUsable(slotId)
    return itemUsable(GetInventoryItemID("player", slotId))
end


local function InitializePlayerStatus() -- 初始化玩家状态槽位
    local cell = {}
    -- cell.unitCastIcon = BadgeCell:New(45, 14)           -- 单位施法图标 / 移入 InitializePlayerCastStatus
    -- cell.unitChannelIcon = BadgeCell:New(47, 14)        -- 单位通道图标/ 移入 InitializePlayerCastStatus
    -- 48列
    cell.unitIsAlive = Cell:New(49, 15) -- 存活
    -- 49列
    cell.unitClass = Cell:New(50, 14)   -- 玩家的职业
    cell.unitRole = Cell:New(50, 15)    -- 玩家的角色
    -- 50 列
    -- cell.unitHealthPercent = Cell:New(51, 14)        -- 生命值百分比 / 移入 InitializePlayerHealthPowerStatus
    -- cell.unitPowerPercent = Cell:New(51, 14)         -- 主能量百分比 / 移入 InitializePlayerHealthPowerStatus
    -- 51列
    cell.unitIsInCombat = Cell:New(52, 14) -- 在战斗中
    cell.unitIsTarget = Cell:New(52, 15)   -- 是目标
    -- 52列
    -- cell.unitHasBigDefense = Cell:New(53, 14)        -- 有大防御值 / 移入 InitializePlayerAuraStatus
    -- cell.unitHasDispellableDebuff = Cell:New(53, 15) -- 有可驱散的减益效果 / 移入 InitializePlayerAuraStatus
    -- 53列
    -- cell.unitCastDuration = Cell:New(54, 14)                -- 施法持续时间 / 移入 InitializePlayerCastStatus
    -- cell.unitChannelDuration = Cell:New(54, 14)             -- 通道持续时间 / 移入 InitializePlayerCastStatus
    -- -- 54列
    -- cell.unitIsEmpowering = Cell:New(55, 14)                -- 在蓄力 / 移入 InitializePlayerCastStatus
    -- cell.unitEmpoweringStage = Cell:New(55, 15)             -- 蓄力阶段 / 移入 InitializePlayerCastStatus
    -- 55列
    cell.unitIsMoving = Cell:New(56, 14)                    -- 在移动
    cell.unitIsMounted = Cell:New(56, 15)                   -- 在坐骑
    -- 56列
    cell.unitEnemyCount = Cell:New(57, 14)                  -- 敌人数量
    cell.unitIsSpellTargeting = Cell:New(57, 15)            -- 正在选择目标
    -- 57列
    cell.unitIsChatInputActive = Cell:New(58, 14)           -- 正在聊天输入
    cell.unitIsInGroupOrRaid = Cell:New(58, 15)             -- 在队伍/团队中
    -- 58列
    cell.unitTrinket1CooldownUsable = Cell:New(59, 14)      -- 饰品 1可用
    cell.unitTrinket2CooldownUsable = Cell:New(59, 15)      -- 饰品 2可用
    -- 59列
    cell.unitHealthstoneCooldownUsable = Cell:New(60, 14)   -- 生命石可用
    cell.unitHealingPotionCooldownUsable = Cell:New(60, 15) -- 治疗药水可用


    local function updateLowFrequency()
        cell.unitClass:setCell(COLOR.CLASS[select(2, UnitClass("player"))])                    -- 单位职业
        cell.unitRole:setCell(COLOR.ROLE[UnitGroupRolesAssigned("player")] or COLOR.ROLE.NONE) -- 单位角色
        local unitEnemyCount = 0

        for plateIndex = 1, 40 do
            local unitToken = "nameplate" .. plateIndex
            if UnitExists(unitToken) and UnitCanAttack("player", unitToken) and not UnitIsDeadOrGhost(unitToken) then
                local minRange, maxRange = LRC:GetRange(unitToken) -- luacheck: ignore minRange
                if maxRange and maxRange <= 5 then
                    unitEnemyCount = unitEnemyCount + 1
                end
            end
        end -- for plateIndex

        cell.unitEnemyCount:setCellRGBA(min(unitEnemyCount / 51, 1))
    end -- updateLowFrequency
    insert(OnUpdateLow, updateLowFrequency)


    local function updateHighFrequency()
        cell.unitIsAlive:setCellBoolean(UnitIsDeadOrGhost("player"), COLOR.BLACK, COLOR.STATUS_BOOLEAN.IS_ALIVE)          -- 单位是否存活
        cell.unitIsInCombat:setCellBoolean(UnitAffectingCombat("player"), COLOR.STATUS_BOOLEAN.IS_IN_COMBAT, COLOR.BLACK) -- 单位是否在战斗中
        cell.unitIsTarget:setCellBoolean(UnitIsUnit("player", "target"), COLOR.STATUS_BOOLEAN.IS_TARGET, COLOR.BLACK)     -- 单位是否为目标
        cell.unitIsMoving:setCellBoolean(GetUnitSpeed("player") > 0, COLOR.STATUS_BOOLEAN.IS_MOVING, COLOR.BLACK)
        cell.unitIsMounted:setCellBoolean(UnitInVehicle("player") or IsMounted(), COLOR.STATUS_BOOLEAN.IS_MOUNTED, COLOR.BLACK)
        cell.unitIsChatInputActive:setCellBoolean(
            GetCurrentKeyBoardFocus() ~= nil,
            COLOR.STATUS_BOOLEAN.IS_CHAT_INPUT_ACTIVE,
            COLOR.BLACK
        )
        cell.unitIsSpellTargeting:setCellBoolean(SpellIsTargeting(), COLOR.STATUS_BOOLEAN.IS_SPELL_TARGETING, COLOR.BLACK)
        cell.unitIsInGroupOrRaid:setCellBoolean(IsInGroup() or IsInRaid(), COLOR.STATUS_BOOLEAN.IS_IN_GROUP_OR_RAID, COLOR.BLACK)


        cell.unitTrinket1CooldownUsable:setCellBoolean(slotUsable(13), COLOR.STATUS_BOOLEAN.TRINKET_1_USABLE, COLOR.BLACK)
        cell.unitTrinket2CooldownUsable:setCellBoolean(slotUsable(14), COLOR.STATUS_BOOLEAN.TRINKET_2_USABLE, COLOR.BLACK)
        cell.unitHealthstoneCooldownUsable:setCellBoolean(itemUsable(224464), COLOR.STATUS_BOOLEAN.HEALTHSTONE_USABLE, COLOR.BLACK)
        cell.unitHealingPotionCooldownUsable:setCellBoolean(itemUsable(258138), COLOR.STATUS_BOOLEAN.HEALING_POTION_USABLE, COLOR.BLACK)
    end -- updateHighFrequency
    insert(OnUpdateHigh, updateHighFrequency)
end
insert(InitUI, InitializePlayerStatus)

local function InitializePlayerHealthPowerStatus()
    local cell = {}
    -- 50 列
    cell.unitHealthPercent = Cell:New(51, 14) -- 生命值百分比
    cell.unitPowerPercent = Cell:New(51, 15)  -- 主能量百分比

    local function updateHealthPercentCell()
        local unitHealthPercent = UnitHealthPercent("player", true, zeroToOneCurve)
        cell.unitHealthPercent:setCell(unitHealthPercent) -- 单位生命值百分比
    end
    insert(UNIT_HEALTH_CHANGED, { unit = "player", func = updateHealthPercentCell })

    local function updatePowerPercentCell()
        local unitPowerPercent = UnitPowerPercent("player", UnitPowerType("player"), true, zeroToOneCurve)
        cell.unitPowerPercent:setCell(unitPowerPercent) -- 单位能量百分比
    end
    insert(UNIT_POWER_CHANGED, { unit = "player", func = updatePowerPercentCell })

    updatePowerPercentCell()  -- 初始刷新
    updateHealthPercentCell() -- 初始刷新
end
insert(InitUI, InitializePlayerHealthPowerStatus)

local function InitializePlayerCastStatus()      -- 初始化玩家施法状态
    local cell = {}
    cell.unitCastIcon = BadgeCell:New(45, 14)    -- 单位施法图标
    cell.unitChannelIcon = BadgeCell:New(47, 14) -- 单位通道图标
    -- 53 列
    cell.unitCastDuration = Cell:New(54, 14)     -- 施法持续时间
    cell.unitChannelDuration = Cell:New(54, 15)  -- 通道持续时间
    -- 54列
    cell.unitIsEmpowering = Cell:New(55, 14)     -- 在蓄力
    cell.unitEmpoweringStage = Cell:New(55, 15)  -- 蓄力阶段

    local inCasting = false
    local inChanneling = false

    local function updateOnEvent()
        local unitCastIcon = select(3, UnitCastingInfo("player"))

        if unitCastIcon then
            inCasting = true
            cell.unitCastIcon:setCell(unitCastIcon, COLOR.SPELL_TYPE.PLAYER_SPELL) -- 单位施法图标
            cell.unitChannelIcon:clearCell()                                       -- 通道图标
            cell.unitChannelDuration:clearCell()                                   -- 通道持续时间
            return                                                                 -- 在施法就不可在通道, 这里可以返回了。
        else
            inCasting = false
            cell.unitCastIcon:clearCell()     -- 单位施法图标
            cell.unitCastDuration:clearCell() -- 单位施法是否可中断
        end

        local unitChannelIcon = select(3, UnitChannelInfo("player"))


        if unitChannelIcon then
            inChanneling = true
            cell.unitChannelIcon:setCell(unitChannelIcon, COLOR.SPELL_TYPE.PLAYER_SPELL) -- 单位通道图标
            cell.unitCastIcon:clearCell()                                                -- 单位施法图标
            cell.unitCastDuration:clearCell()                                            -- 单位施法剩余
            local isEmpowered = select(9, UnitChannelInfo("player"))
            if isEmpowered then
                cell.unitIsEmpowering:setCellBoolean(true, COLOR.STATUS_BOOLEAN.IS_EMPOWERING, COLOR.BLACK)
                cell.unitEmpoweringStage:setCell(zeroToOneCurve(UnitEmpoweredStageDurations("player")))
            else
                cell.unitIsEmpowering:setCell(COLOR.BLACK)
                cell.unitEmpoweringStage:setCell(COLOR.BLACK)
            end -- isEmpowered
        else
            inChanneling = false
            cell.unitChannelIcon:clearCell()     -- 通道图标
            cell.unitChannelDuration:clearCell() -- 通道持续时间
        end
    end                                          -- updateOnEvent
    -- insert(UNIT_CAST_CHANGED, { unit = "player", func = updateOnEvent })
    insert(OnUpdateHigh, updateOnEvent)


    local function updateHighFrequency()
        local unitCastDuration = inCasting and UnitCastingDuration("player") or nil
        if unitCastDuration then
            cell.unitCastDuration:setCell(unitCastDuration:EvaluateElapsedPercent(zeroToOneCurve)) -- 单位施法持续时间
        else
            cell.unitCastDuration:clearCell()                                                      -- 单位施法持续时间
        end

        local unitChannelDuration = inChanneling and UnitChannelDuration("player") or nil
        if unitChannelDuration then
            cell.unitChannelDuration:setCell(unitChannelDuration:EvaluateElapsedPercent(zeroToOneCurve)) -- 单位通道施法持续时间
        else
            cell.unitChannelDuration:clearCell()                                                         -- 单位通道施法持续时间
        end
    end
    insert(OnUpdateHigh, updateHighFrequency)
end
insert(InitUI, InitializePlayerCastStatus)

local function InitializePlayerAuraStatus()
    local cell = {}
    cell.unitHasBigDefense = Cell:New(53, 14)        -- 有大防御值
    cell.unitHasDispellableDebuff = Cell:New(53, 15) -- 有可驱散的减益效果
    local function updateOnEvent()
        local bigDefenseTable = GetUnitAuraInstanceIDs("player", "HELPFUL|BIG_DEFENSIVE")
        local dispellableDebuffTable = GetUnitAuraInstanceIDs("player", "HARMFUL|RAID_PLAYER_DISPELLABLE")
        cell.unitHasBigDefense:setCellBoolean(#bigDefenseTable > 0, COLOR.STATUS_BOOLEAN.HAS_BIG_DEFENSE, COLOR.BLACK)
        cell.unitHasDispellableDebuff:setCellBoolean(#dispellableDebuffTable > 0, COLOR.STATUS_BOOLEAN.HAS_DISPELLABLE_DEBUFF, COLOR.BLACK)
    end
    insert(UNIT_AURA_CHANGED, { unit = "player", func = updateOnEvent })
    updateOnEvent()
end
insert(InitUI, InitializePlayerAuraStatus)
