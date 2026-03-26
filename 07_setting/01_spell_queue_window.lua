local addonName, addonTable = ... -- luacheck: ignore addonName


-- Lua 原生函数
local insert             = table.insert
-- 插件内引用
local InitUI             = addonTable.Listeners.InitUI       -- 初始化入口列表
local Cell               = addonTable.Cell                   -- 基础色块单元
local Config             = addonTable.Config                 -- 配置对象工厂
local OnUpdateHigh       = addonTable.Listeners.OnUpdateHigh -- 高频刷新回调列表（约 10 Hz）

-- 示例配置对象
local spell_queue_window = Config("spell_queue_window") -- 滑块配置项

local slider_row         = { -- 滑块示例行
    type = "slider", -- 设置类型
    key = "spell_queue_window", -- 行标识
    name = "延迟窗口", -- 标题文本
    tooltip = "延迟窗口的时间, 单位ms, 这个值越小, 按键越晚", -- 提示信息
    min_value = 200, -- 最小值
    max_value = 400, -- 最大值
    step = 10, -- 步进
    default_value = 300, -- 默认值
    bind_config = spell_queue_window, -- 绑定的配置对象
    -- callback = callback, -- 回调函数
} -- slider_row 结束
table.insert(addonTable.Panel.Rows, slider_row) -- 写入滑块示例

local function InitializeCell()
    local cell = Cell:New(57, 9)
    cell:setCellRGBA(20 / 255)
    local function Updater(value)
        local mean = (value / 10) / 255
        -- print(mean)
        cell:setCellRGBA(mean)
    end
    spell_queue_window:register_callback(Updater)
    -- insert(OnUpdateHigh, Updater)
end
insert(InitUI, InitializeCell) -- 注册 aura 序列初始化入口
