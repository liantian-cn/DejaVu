--[[
文件定位:



状态:
  draft
]]

-- 插件入口
local addonName, addonTable = ...

-- WoW 官方 API
local CreateFrame = CreateFrame
local C_Timer = C_Timer

-- Lua 原生函数
local wipe = wipe

-- WoW 官方 API
local UnitExists = UnitExists

addonTable.Event = {}
addonTable.Listeners = {}
addonTable.UpdateFunc = addonTable.Listeners

addonTable.Listeners.InitUI = {}

addonTable.Listeners.OnUpdateHigh = {}
addonTable.Listeners.OnUpdateLow = {}

addonTable.Listeners.SPELLS_CHANGED = {}
addonTable.Listeners.PLAYER_TALENT_CHANGED = {}           -- 所有涉及天赋变化的事件
addonTable.Listeners.UNIT_AURA_CHANGED = {}               -- 单位Aura变化事件
addonTable.Listeners.UNIT_CAST_CHANGED = {}               -- 单位Cast/Channel变化事件
addonTable.Listeners.UNIT_HEALTH_CHANGED = {}             -- 单位生命变化事件
addonTable.Listeners.UNIT_MAX_HEALTH_CHANGED = {}         -- 单位最大生命值变化事件
addonTable.Listeners.UNIT_POWER_CHANGED = {}              -- 单位能量变化事件
addonTable.Listeners.TARGET_CHANGED = {}                  -- 目标改变时触发, 并不存在这个事件, 多个事件会触发这个事件
addonTable.Listeners.FOCUS_CHANGED = {}                   -- 焦点改变时触发, 并不存在这个事件, 多个事件会触发这个事件
addonTable.Listeners.MOUSEOVER_CHANGED = {}               -- 鼠标悬停单位存在状态变化时触发, 并不存在这个事件, 多个事件会触发这个事件
addonTable.Listeners.PLAYER_MOVING = {}                   -- 玩家移动时触发
addonTable.Listeners.UNIT_HEAL_ABSORB_AMOUNT_CHANGED = {} -- 单单位治疗吸收量变化事件
addonTable.Listeners.UNIT_ABSORB_AMOUNT_CHANGED = {}      -- 单单位伤害吸收量变化事件
addonTable.Listeners.PARTY_CHANGED = {}                   -- 阘伍成员变化事件

local eventThisFrame = {}                                 -- 帧内放重复
local mouseoverExists = UnitExists("mouseover")

local function DispatchSpellsChanged()
    if eventThisFrame["SPELLS_CHANGED"] then
        return
    end
    eventThisFrame["SPELLS_CHANGED"] = true
    for funcIndex = 1, #addonTable.Listeners.SPELLS_CHANGED do
        local func = addonTable.Listeners.SPELLS_CHANGED[funcIndex]
        func()
    end
end

local function DispatchPlayerTalentChanged()
    if eventThisFrame["PLAYER_TALENT_CHANGED"] then
        return
    end
    eventThisFrame["PLAYER_TALENT_CHANGED"] = true
    for funcIndex = 1, #addonTable.Listeners.PLAYER_TALENT_CHANGED do
        local func = addonTable.Listeners.PLAYER_TALENT_CHANGED[funcIndex]
        func()
    end
end

local function DispatchTargetChanged()
    for funcIndex = 1, #addonTable.Listeners.TARGET_CHANGED do
        local func = addonTable.Listeners.TARGET_CHANGED[funcIndex]
        func()
    end
end

local function DispatchFocusChanged()
    if eventThisFrame["PLAYER_FOCUS_CHANGED"] then
        return
    end
    eventThisFrame["PLAYER_FOCUS_CHANGED"] = true
    for funcIndex = 1, #addonTable.Listeners.FOCUS_CHANGED do
        local func = addonTable.Listeners.FOCUS_CHANGED[funcIndex]
        func()
    end
end

local function DispatchMouseoverChanged()
    for funcIndex = 1, #addonTable.Listeners.MOUSEOVER_CHANGED do
        local func = addonTable.Listeners.MOUSEOVER_CHANGED[funcIndex]
        func()
    end
end

local function DispatchUnitAuraChanged(unitToken)
    if eventThisFrame["UNIT_AURA_CHANGED_" .. unitToken] then
        return
    end
    eventThisFrame["UNIT_AURA_CHANGED" .. unitToken] = true
    for funcIndex = 1, #addonTable.Listeners.UNIT_AURA_CHANGED do
        local updaterInfo = addonTable.Listeners.UNIT_AURA_CHANGED[funcIndex]
        if updaterInfo.unit == unitToken then
            updaterInfo.func()
        end
    end
end

local function DispatchUnitCastChanged(unitToken)
    if eventThisFrame["UNIT_CAST_CHANGED_" .. unitToken] then
        return
    end
    eventThisFrame["UNIT_CAST_CHANGED" .. unitToken] = true
    for funcIndex = 1, #addonTable.Listeners.UNIT_CAST_CHANGED do
        local updaterInfo = addonTable.Listeners.UNIT_CAST_CHANGED[funcIndex]
        if updaterInfo.unit == unitToken then
            updaterInfo.func()
        end
    end
end

local function DispatchUnitHealthChanged(unitToken)
    if eventThisFrame["UNIT_HEALTH_CHANGED_" .. unitToken] then
        return
    end
    eventThisFrame["UNIT_HEALTH_CHANGED" .. unitToken] = true
    for funcIndex = 1, #addonTable.Listeners.UNIT_HEALTH_CHANGED do
        local updaterInfo = addonTable.Listeners.UNIT_HEALTH_CHANGED[funcIndex]
        if updaterInfo.unit == unitToken then
            updaterInfo.func()
        end
    end
end

local function DispatchUnitMaxHealthChanged(unitToken)
    if eventThisFrame["UNIT_MAX_HEALTH_CHANGED_" .. unitToken] then
        return
    end
    eventThisFrame["UNIT_MAX_HEALTH_CHANGED" .. unitToken] = true
    for funcIndex = 1, #addonTable.Listeners.UNIT_MAX_HEALTH_CHANGED do
        local updaterInfo = addonTable.Listeners.UNIT_MAX_HEALTH_CHANGED[funcIndex]
        if updaterInfo.unit == unitToken then
            updaterInfo.func()
        end
    end
end

local function DispatchUnitPowerChanged(unitToken)
    if eventThisFrame["UNIT_POWER_CHANGED_" .. unitToken] then
        return
    end
    eventThisFrame["UNIT_POWER_CHANGED" .. unitToken] = true
    for funcIndex = 1, #addonTable.Listeners.UNIT_POWER_CHANGED do
        local updaterInfo = addonTable.Listeners.UNIT_POWER_CHANGED[funcIndex]
        if updaterInfo.unit == unitToken then
            updaterInfo.func()
        end
    end
end

local function DispatchUnitHealAbsorbAmountChanged(unitToken)
    if eventThisFrame["UNIT_HEAL_ABSORB_AMOUNT_CHANGED" .. unitToken] then
        return
    end
    eventThisFrame["UNIT_HEAL_ABSORB_AMOUNT_CHANGED" .. unitToken] = true
    for funcIndex = 1, #addonTable.Listeners.UNIT_HEAL_ABSORB_AMOUNT_CHANGED do
        local updaterInfo = addonTable.Listeners.UNIT_HEAL_ABSORB_AMOUNT_CHANGED[funcIndex]
        if updaterInfo.unit == unitToken then
            updaterInfo.func()
        end
    end
end

local function DispatchUnitDamageAbsorbAmountChanged(unitToken)
    if eventThisFrame["UNIT_ABSORB_AMOUNT_CHANGED" .. unitToken] then
        return
    end
    eventThisFrame["UNIT_ABSORB_AMOUNT_CHANGED" .. unitToken] = true
    for funcIndex = 1, #addonTable.Listeners.UNIT_ABSORB_AMOUNT_CHANGED do
        local updaterInfo = addonTable.Listeners.UNIT_ABSORB_AMOUNT_CHANGED[funcIndex]
        if updaterInfo.unit == unitToken then
            updaterInfo.func()
        end
    end
end

local function DispatchPlayerMovingChanged()
    if eventThisFrame["PLAYER_MOVING"] then
        return
    end
    eventThisFrame["PLAYER_MOVING"] = true
    for funcIndex = 1, #addonTable.Listeners.PLAYER_MOVING do
        local func = addonTable.Listeners.PLAYER_MOVING[funcIndex]
        func()
    end
end

local function DispatchPartyChanged()
    if eventThisFrame["PARTY_CHANGED"] then
        return
    end
    eventThisFrame["PARTY_CHANGED"] = true
    for funcIndex = 1, #addonTable.Listeners.PARTY_CHANGED do
        local func = addonTable.Listeners.PARTY_CHANGED[funcIndex]
        func()
    end
end



local eventFrame = CreateFrame("EventFrame", addonName .. "Frame")
addonTable.Event.Frame = eventFrame




function eventFrame:PLAYER_ENTERING_WORLD()
    C_Timer.After(0, function()
        wipe(addonTable.Listeners.OnUpdateHigh)
        wipe(addonTable.Listeners.OnUpdateLow)

        for funcIndex = 1, #addonTable.Listeners.InitUI do
            local func = addonTable.Listeners.InitUI[funcIndex]
            func()
        end
    end)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function eventFrame:SPELLS_CHANGED()

end

function eventFrame:SPELL_UPDATE_ICON()
    DispatchSpellsChanged()
end

function eventFrame:PLAYER_TALENT_CHANGED()
    DispatchPlayerTalentChanged()
end

function eventFrame:PLAYER_TALENT_UPDATE()
    self:PLAYER_TALENT_CHANGED()
end

function eventFrame:TRAIT_NODE_CHANGED()
    self:PLAYER_TALENT_CHANGED()
end

function eventFrame:TRAIT_CONFIG_UPDATED()
    self:PLAYER_TALENT_CHANGED()
end

function eventFrame:PLAYER_TARGET_CHANGED()
    DispatchTargetChanged()
end

function eventFrame:PLAYER_FOCUS_CHANGED()
    DispatchFocusChanged()
end

function eventFrame:UPDATE_MOUSEOVER_UNIT()
    mouseoverExists = UnitExists("mouseover")
    DispatchMouseoverChanged()
end

function eventFrame:UNIT_AURA(unitToken)
    DispatchUnitAuraChanged(unitToken)
end

function eventFrame:UNIT_SPELLCAST_INTERRUPTED(unitToken)
    DispatchUnitCastChanged(unitToken)
end

function eventFrame:UNIT_SPELLCAST_START(unitToken)
    DispatchUnitCastChanged(unitToken)
end

function eventFrame:UNIT_SPELLCAST_STOP(unitToken)
    DispatchUnitCastChanged(unitToken)
end

function eventFrame:UNIT_SPELLCAST_SUCCEEDED(unitToken)
    DispatchUnitCastChanged(unitToken)
end

function eventFrame:UNIT_SPELLCAST_FAILED(unitToken)
    DispatchUnitCastChanged(unitToken)
end

function eventFrame:UNIT_SPELLCAST_CHANNEL_START(unitToken)
    DispatchUnitCastChanged(unitToken)
end

function eventFrame:UNIT_SPELLCAST_CHANNEL_STOP(unitToken)
    DispatchUnitCastChanged(unitToken)
end

function eventFrame:UNIT_SPELLCAST_CHANNEL_UPDATE(unitToken)
    DispatchUnitCastChanged(unitToken)
end

function eventFrame:UNIT_SPELLCAST_EMPOWER_START(unitToken)
    DispatchUnitCastChanged(unitToken)
end

function eventFrame:UNIT_SPELLCAST_EMPOWER_STOP(unitToken)
    DispatchUnitCastChanged(unitToken)
end

function eventFrame:UNIT_HEALTH(unitToken)
    DispatchUnitHealthChanged(unitToken)
end

function eventFrame:UNIT_MAXHEALTH(unitToken)
    DispatchUnitHealthChanged(unitToken)
    DispatchUnitMaxHealthChanged(unitToken)
end

function eventFrame:UNIT_POWER_UPDATE(unitToken)
    DispatchUnitPowerChanged(unitToken)
end

function eventFrame:UNIT_HEAL_ABSORB_AMOUNT_CHANGED(unitToken)
    DispatchUnitHealAbsorbAmountChanged(unitToken)
end

function eventFrame:UNIT_ABSORB_AMOUNT_CHANGED(unitToken)
    DispatchUnitDamageAbsorbAmountChanged(unitToken)
end

function eventFrame:PLAYER_STOPPED_MOVING()
    DispatchPlayerMovingChanged()
end

function eventFrame:PLAYER_STARTED_MOVING()
    DispatchPlayerMovingChanged()
end

function eventFrame:GROUP_ROSTER_UPDATE()
    DispatchPartyChanged()
end

function eventFrame:GROUP_JOINED()
    DispatchPartyChanged()
end

function eventFrame:GROUP_LEFT()
    DispatchPartyChanged()
end

function eventFrame:UNIT_NAME_UPDATE(unitToken)
    DispatchPartyChanged()
end

-- 注册事件
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_AURA")
-- eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_ICON")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("TRAIT_NODE_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT") -- 这个事件无法捕获失去鼠标悬停事件
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
eventFrame:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
eventFrame:RegisterEvent("UNIT_POWER_POINT_CHARGE")
eventFrame:RegisterEvent("PLAYER_STOPPED_MOVING")
eventFrame:RegisterEvent("PLAYER_STARTED_MOVING")
eventFrame:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
eventFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("GROUP_JOINED")
eventFrame:RegisterEvent("GROUP_LEFT")
eventFrame:RegisterEvent("UNIT_NAME_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

-- 时间流逝变量
local timeElapsed = 0
local lowFrequencyTimeElapsed = 0
-- 钩子OnUpdate脚本, 用于定时更新
eventFrame:HookScript("OnUpdate", function(self, elapsed)
    wipe(eventThisFrame)
    local tickOffset             = 1.0 / 20;
    local lowFrequencyTickOffset = 1.0 / 5;
    timeElapsed                  = timeElapsed + elapsed
    lowFrequencyTimeElapsed      = lowFrequencyTimeElapsed + elapsed
    if timeElapsed > tickOffset then
        timeElapsed = 0
        local currentMouseoverExists = UnitExists("mouseover")
        if currentMouseoverExists ~= mouseoverExists then
            mouseoverExists = currentMouseoverExists
            DispatchMouseoverChanged()
        end
        for updaterIndex = 1, #addonTable.Listeners.OnUpdateHigh do
            local updater = addonTable.Listeners.OnUpdateHigh[updaterIndex]
            updater()
        end
    end
    if lowFrequencyTimeElapsed > lowFrequencyTickOffset then
        lowFrequencyTimeElapsed = 0
        -- print("LowFrequencyTimeElapsed")
        for updaterIndex = 1, #addonTable.Listeners.OnUpdateLow do
            local updater = addonTable.Listeners.OnUpdateLow[updaterIndex]
            updater()
        end
    end
end)
