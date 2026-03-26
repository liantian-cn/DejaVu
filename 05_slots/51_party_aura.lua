--[[
文件: 51_party_aura.lua
定位: DejaVu 队伍单位 Aura 序列布局模块
功能:
  - 为 party1 到 party4 创建独立的增益 / 减益显示序列
  - 复用 AuraSequenceCreator, 集中声明队友 Aura 的布局参数
依赖:
  - addonTable.Listeners.InitUI 初始化回调列表
  - addonTable.AuraSequenceCreator Aura 序列槽位工厂

状态:
  waiting_real_test（今日接通, 待实战验证）
]]

local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local string_format = string.format
local insert = table.insert

-- WoW 官方 API
local UnitAuraSortRule = Enum.UnitAuraSortRule
local UnitAuraSortDirection = Enum.UnitAuraSortDirection

-- 插件内引用
local InitUI = addonTable.Listeners.InitUI
local AuraSequenceCreator = addonTable.AuraSequenceCreator


local function InitializePartyAura()
    for partyIndex = 1, 4 do
        local unitToken = string_format("party%d", partyIndex)
        local baseX = 21 * partyIndex
        AuraSequenceCreator({
            unit = unitToken, -- 当前队友单位
            filter = "HELPFUL|PLAYER",
            maxCount = 7,
            posX = baseX - 20,
            posY = 19,
            sortRule = UnitAuraSortRule.Expiration,
            sortDirection = UnitAuraSortDirection.Normal,

        })
        AuraSequenceCreator({
            unit = unitToken, -- 当前队友单位
            filter = "HARMFUL",
            maxCount = 3,
            posX = baseX - 6,
            posY = 19,
            sortRule = UnitAuraSortRule.Expiration,
            sortDirection = UnitAuraSortDirection.Normal,

        })
    end
end

insert(InitUI, InitializePartyAura)
