--[[
文件定位:
  DejaVu 日志组件, 提供统一的日志输出与调试辅助功能。



状态:
  draft
]]

-- 插件入口
local addonName, addonTable = ... -- luacheck: ignore addonName

-- Lua 原生函数
local print = print
local tostring = tostring

local function logging(msg)
    print("|cFFFFBB66[DéjàVu]|r" .. tostring(msg))
end

addonTable.Logging = logging
