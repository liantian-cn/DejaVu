-- 这是个测试文件, 开发阶段使用。正式使用时, 应直接文件头部return

-- return nil

local addonName, addonTable = ...          -- luacheck: ignore addonName
local InitUI = addonTable.Listeners.InitUI -- 初始化 UI 函数列表


local function TestSlot()
    -- local badgeCell = BadgeCell:New(10, 10)
    -- badgeCell:setCell(136243, COLOR.WHITE)
    -- local megaCell = MegaCell:New(12, 12)
    -- megaCell:setCell(136243)
    return
end
table.insert(InitUI, TestSlot) -- 初始化时创建测试槽位
