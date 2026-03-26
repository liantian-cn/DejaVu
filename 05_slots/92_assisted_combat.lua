--[[
文件定位:
  DejaVu Assisted Combat 槽位显示模块, 负责显示系统当前建议施放的技能图标。

状态:
  draft
]]

-- luacheck: globals C_AssistedCombat
local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local insert = table.insert

-- WoW 官方 API
local GetSpellTexture = C_Spell.GetSpellTexture
local GetNextCastSpell = C_AssistedCombat.GetNextCastSpell

-- 插件内引用
local COLOR = addonTable.COLOR
local BadgeCell = addonTable.BadgeCell
local InitUI = addonTable.Listeners.InitUI             -- 初始化 UI 函数列表
local OnUpdateHigh = addonTable.Listeners.OnUpdateHigh -- 高频刷新回调列表（约 10 Hz）


local function InitializeAssistedCombat()
    local assistedCombatIcon = BadgeCell:New(43, 14)

    -- 这里只负责显示系统给出的下一个技能建议, 不在 Lua 里做额外判断或排序。
    local function updateAssistedCombatIcon()
        local spellID = GetNextCastSpell(false)
        if not spellID then
            assistedCombatIcon:clearCell()
            return
        end

        local iconID = GetSpellTexture(spellID)
        if not iconID then
            assistedCombatIcon:clearCell()
            return
        end

        assistedCombatIcon:setCell(iconID, COLOR.SPELL_TYPE.PLAYER_SPELL)
    end

    insert(OnUpdateHigh, updateAssistedCombatIcon)
    updateAssistedCombatIcon()
end

insert(InitUI, InitializeAssistedCombat) -- 初始化时创建 Assisted Combat 槽位
