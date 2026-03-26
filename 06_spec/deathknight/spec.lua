--[[
文件定位:
  DejaVu 德鲁伊职业特色Cell组配置模块, 定义德鲁伊形态相关的Cell布局。



状态:
  draft
]]

-- 插件入口
local addonName, addonTable = ... -- luacheck: ignore addonName addonTable


-- Lua 原生函数
local insert                            = table.insert

-- WoW 官方 API
local UnitPower                         = UnitPower
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization
-- 专精错误则停止
local className, classFilename, classId = UnitClass("player")
local currentSpec                       = GetSpecialization()
if classFilename ~= "DEATHKNIGHT" then return end
-- 插件内引用
local InitUI       = addonTable.Listeners.InitUI       -- 初始化入口列表
local Cell         = addonTable.Cell                   -- 基础色块单元
local OnUpdateHigh = addonTable.Listeners.OnUpdateHigh -- 高频刷新回调列表
-- local UNIT_POWER_CHANGED = addonTable.Listeners.UNIT_POWER_CHANGED -- 单位能量百分改变事件列表



local function InitializeDKSpec()
    local readyRunesCell = Cell:New(55, 13)

    local function UpdateSpec()
        local readyRunes = 0
        for runeIndex = 1, 6 do
            local startTime, duration, runeReady = GetRuneCooldown(runeIndex) -- luacheck: ignore startTime duration
            if runeReady then
                readyRunes = readyRunes + 1
            end
        end
        readyRunesCell:setCellRGBA(readyRunes * 10 / 255)
    end
    insert(OnUpdateHigh, UpdateSpec)
end
insert(InitUI, InitializeDKSpec) -- 注册 aura 序列初始化入口


local readyRunes = 0
for runeIndex = 1, 6 do
    local startTime, duration, runeReady = GetRuneCooldown(runeIndex) -- luacheck: ignore startTime duration
    if runeReady then
        readyRunes = readyRunes + 1
    end
end
return readyRunes
