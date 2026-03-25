--[[
文件定位:




状态:
  draft
]]

-- 插件入口
local addonName, addonTable = ... -- luacheck: ignore addonName

-- WoW 官方 API
local GetPhysicalScreenSize = GetPhysicalScreenSize
local GetScreenHeight = GetScreenHeight

addonTable.Size = {}

addonTable.Size.GetUIScaleFactor = function(pixelValue)
    local physicalHeight = select(2, GetPhysicalScreenSize())
    local logicalHeight = GetScreenHeight()
    return (pixelValue * logicalHeight) / physicalHeight
end
