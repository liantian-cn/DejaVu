--[[
文件定位:
  DejaVu 玩家吸收条模块。

状态:
  draft
]]

-- luacheck: globals UnitGetTotalAbsorbs UnitGetTotalHealAbsorbs UnitHealthMax
local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local insert = table.insert

-- WoW 官方 API
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
local UnitHealthMax = UnitHealthMax

-- 插件内引用
local InitUI = addonTable.Listeners.InitUI
local Bar = addonTable.Bar
local UNIT_ABSORB_AMOUNT_CHANGED = addonTable.Listeners.UNIT_ABSORB_AMOUNT_CHANGED
local UNIT_HEAL_ABSORB_AMOUNT_CHANGED = addonTable.Listeners.UNIT_HEAL_ABSORB_AMOUNT_CHANGED
local UNIT_MAX_HEALTH_CHANGED = addonTable.Listeners.UNIT_MAX_HEALTH_CHANGED

local function InitializePlayerBar()
    local damageAbsorbsBar = Bar:New(43, 16, 20)
    local healAbsorbsBar = Bar:New(64, 14, 20)

    -- 这两条都按玩家最大生命值做刻度, 直接把官方数值透传给 StatusBar。
    local function updateMaxHealth()
        local maxHealth = UnitHealthMax("player") or 0
        damageAbsorbsBar:setMinMaxValues(0, maxHealth)
        healAbsorbsBar:setMinMaxValues(0, maxHealth)
    end

    local function updateDamageAbsorbs()
        damageAbsorbsBar:setValue(UnitGetTotalAbsorbs("player") or 0)
    end

    local function updateHealAbsorbs()
        healAbsorbsBar:setValue(UnitGetTotalHealAbsorbs("player") or 0)
    end

    insert(UNIT_MAX_HEALTH_CHANGED, { unit = "player", func = updateMaxHealth })
    insert(UNIT_ABSORB_AMOUNT_CHANGED, { unit = "player", func = updateDamageAbsorbs })
    insert(UNIT_HEAL_ABSORB_AMOUNT_CHANGED, { unit = "player", func = updateHealAbsorbs })

    updateMaxHealth()
    updateDamageAbsorbs()
    updateHealAbsorbs()
end

insert(InitUI, InitializePlayerBar)
