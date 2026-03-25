local addonName, addonTable = ... -- luacheck: ignore addonName
-- 插件内引用
local COLOR = addonTable.COLOR
local Cell = addonTable.Cell
local InitUI = addonTable.Listeners.InitUI -- 初始化 UI 函数列表


local function InitializeMarkPoint()
    Cell:New(0, 0, COLOR.MARK_POINT.NEAR_BLACK_1)
    Cell:New(1, 1, COLOR.MARK_POINT.NEAR_BLACK_1)
    Cell:New(0, 1, COLOR.MARK_POINT.NEAR_BLACK_2)
    Cell:New(1, 0, COLOR.MARK_POINT.NEAR_BLACK_2)
    Cell:New(82, 26, COLOR.MARK_POINT.NEAR_BLACK_1)
    Cell:New(83, 27, COLOR.MARK_POINT.NEAR_BLACK_1)
    Cell:New(82, 27, COLOR.MARK_POINT.NEAR_BLACK_2)
    Cell:New(83, 26, COLOR.MARK_POINT.NEAR_BLACK_2)
end
table.insert(InitUI, InitializeMarkPoint) -- 初始化时创建标记点
