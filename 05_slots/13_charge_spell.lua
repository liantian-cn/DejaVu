--[[
文件定位:
  DejaVu 充能技能槽位显示模块, 负责充能技能的 Cell 布局与刷新。



状态:
  draft
]]

-- luacheck: globals C_SpellActivationOverlay
local addonName, addonTable = ... -- luacheck: ignore addonName

-- WoW 官方 API
local GetSpellTexture = C_Spell.GetSpellTexture
local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
local IsSpellUsable = C_Spell.IsSpellUsable
local IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean
local GetSpellCharges = C_Spell.GetSpellCharges
local GetSpellChargeDuration = C_Spell.GetSpellChargeDuration

-- 插件内引用
local COLOR = addonTable.COLOR
local Slots = addonTable.Slots
local Cell = addonTable.Cell
local BadgeCell = addonTable.BadgeCell
local CharCell = addonTable.CharCell
local InitUI = addonTable.Listeners.InitUI                 -- 初始化 UI 函数列表
local SPELLS_CHANGED = addonTable.Listeners.SPELLS_CHANGED -- SPELLS_CHANGED 回调列表
local OnUpdateLow = addonTable.Listeners.OnUpdateLow       -- 低频刷新回调列表（约 2 Hz）
local OnUpdateHigh = addonTable.Listeners.OnUpdateHigh     -- 高频刷新回调列表（约 10 Hz）

local chargeSpells = Slots.chargeSpells                    -- 充能技能列表

local CHARGE_LENGTH = 11

local remainingCurve = Slots.remainingCurve



local function InitializeChargeFrame()
    local chargeCells = {}
    for i = 1, CHARGE_LENGTH do
        local x = 60 + 2 * i
        local y = 4
        table.insert(chargeCells, {
            icon = BadgeCell:New(x, y),         -- 技能图标
            remaining = Cell:New(x, y + 2),     -- 充能恢复剩余时间的颜色映射
            overlayed = Cell:New(x + 1, y + 2), -- 技能高亮提示
            isUsable = Cell:New(x, y + 3),      -- 当前不可施放时显示白色
            isKnown = Cell:New(x + 1, y + 3),   -- 不在法术书中时显示白色
            count = CharCell:New(x, y + 4)      -- 当前可用层数
        })
    end



    local function updateIcon() -- 更新图标
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
                local spellID = spell.spellID

                local iconID = GetSpellTexture(spellID)
                cell.icon:setCell(iconID, COLOR.SPELL_TYPE.PLAYER_SPELL)
            else
                cell.icon:clearCell()
            end
        end
    end

    local function updateRemaining() -- 更新充能恢复剩余时间与当前层数
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
                local spellID = spell.spellID
                local duration = GetSpellChargeDuration(spellID)
                local result = duration:EvaluateRemainingDuration(remainingCurve)
                cell.remaining:setCell(result)

                local chargeInfo = GetSpellCharges(spellID)
                cell.count:setCell(tostring(chargeInfo.currentCharges))
            else
                cell.remaining:clearCell()
            end
        end
    end

    local function updateOverlayed() -- 更新技能高亮状态
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
                local spellID = spell.spellID

                local isOverlayed = EvaluateColorFromBoolean(IsSpellOverlayed(spellID), COLOR.WHITE, COLOR.BLACK)
                cell.overlayed:setCell(isOverlayed)
            else
                cell.overlayed:clearCell()
            end
        end
    end

    local function updateUnknown() -- 更新技能是否不在法术书中
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
                local spellID = spell.spellID

                local isKnown = EvaluateColorFromBoolean(IsSpellInSpellBook(spellID), COLOR.SPELL_BOOLEAN.IS_KNOWN, COLOR.BLACK)
                cell.isKnown:setCell(isKnown)
            else
                cell.isKnown:clearCell()
            end
        end
    end

    local function updateUnusable() -- 更新技能不可施放状态
        for i = 1, CHARGE_LENGTH do
            local cell = chargeCells[i]
            if i <= #chargeSpells then
                local spell = chargeSpells[i]
                local spellID = spell.spellID
                local isUsable = EvaluateColorFromBoolean(IsSpellUsable(spellID), COLOR.SPELL_BOOLEAN.IS_USABLE, COLOR.BLACK)
                cell.isUsable:setCell(isUsable)
            else
                cell.isUsable:clearCell()
            end
        end
    end

    local function fullUpdate() -- 全量更新
        updateIcon()
        updateRemaining()
        updateOverlayed()
        updateUnknown()
        updateUnusable()
    end
    fullUpdate()
    table.insert(SPELLS_CHANGED, updateIcon)      -- 技能变更时更新图标
    table.insert(SPELLS_CHANGED, updateRemaining) -- 技能变更时更新充能剩余时间
    table.insert(SPELLS_CHANGED, updateOverlayed) -- 技能变更时更新高亮状态
    table.insert(SPELLS_CHANGED, updateUnknown)   -- 技能变更时更新法术书收录状态
    table.insert(OnUpdateHigh, updateIcon)        -- 高频更新充能剩余时间
    table.insert(OnUpdateHigh, updateRemaining)   -- 高频更新充能剩余时间
    table.insert(OnUpdateLow, updateOverlayed)    -- 低频更新技能高亮状态
    table.insert(OnUpdateLow, updateUnusable)     -- 低频更新技能不可施放状态
end
table.insert(InitUI, InitializeChargeFrame)       -- 初始化时创建充能技能槽位
