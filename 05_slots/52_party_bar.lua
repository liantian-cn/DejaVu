--[[
文件: 52_party_bar.lua
定位: DejaVu 队伍单位吸收条模块


状态:
  waiting_real_test（今日接通, 待实战验证）
]]

local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local string_format = string.format
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
local PARTY_CHANGED = addonTable.Listeners.PARTY_CHANGED


local function InitializePartyBar()
    for partyIndex = 1, 4 do
        local unitToken = string_format("party%d", partyIndex)
        local baseX = 21 * partyIndex


        local unitDamageAbsorbsBar = Bar:New(baseX - 20, 24, 10)
        local unitHealAbsorbsBar = Bar:New(baseX - 20, 25, 10)

        local function updateMaxHealth()
            local maxHealth = UnitHealthMax(unitToken) or 0
            unitDamageAbsorbsBar:setMinMaxValues(0, maxHealth)
            unitHealAbsorbsBar:setMinMaxValues(0, maxHealth)
        end

        local function updateDamageAbsorbs()
            unitDamageAbsorbsBar:setValue(UnitGetTotalAbsorbs(unitToken) or 0)
        end

        local function updateHealAbsorbs()
            unitHealAbsorbsBar:setValue(UnitGetTotalHealAbsorbs(unitToken) or 0)
        end
        local function updatePartyBar()
            updateMaxHealth()
            updateDamageAbsorbs()
            updateHealAbsorbs()
        end

        insert(UNIT_MAX_HEALTH_CHANGED, { unit = unitToken, func = updateMaxHealth })
        insert(UNIT_ABSORB_AMOUNT_CHANGED, { unit = unitToken, func = updateDamageAbsorbs })
        insert(UNIT_HEAL_ABSORB_AMOUNT_CHANGED, { unit = unitToken, func = updateHealAbsorbs })
        insert(PARTY_CHANGED, updatePartyBar)
        updatePartyBar()
    end
end

insert(InitUI, InitializePartyBar)
