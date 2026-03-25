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
local InitUI = addonTable.Listeners.InitUI             -- 初始化入口列表
local Cell   = addonTable.Cell                         -- 基础色块单元
local Config = addonTable.Config                       -- 配置对象工厂


addonTable.RangedRange = 30   -- 近战范围阈值，单位为码


do
    local runic_power_max = Config("runic_power_max") -- 最大符文能量

    table.insert(addonTable.Panel.Rows, {             -- 滑块示例行
        type = "slider",
        key = "runic_power_max",
        name = "最大符文能量",
        tooltip = "设置最大符文能量值",
        min_value = 100,
        max_value = 140,
        step = 5,
        default_value = 125,           -- 默认值
        bind_config = runic_power_max, -- 绑定的配置对象
        -- callback = callback, -- 回调函数
    })

    local dk_interrupt_mode = Config("dk_interrupt_mode") -- 打断模式

    table.insert(addonTable.Panel.Rows, {
        type = "combo",
        key = "dk_interrupt_mode",
        name = "打断模式",
        tooltip = "选择打断模式",
        default_value = "blacklist",
        options = {
            { k = "blacklist", v = "使用黑名单" },
            { k = "all", v = "任意打断" }
        },
        bind_config = dk_interrupt_mode
    })

    local function InitializeDKSetting() -- 符文能量 Cell 初始化函数
        local runic_power_max_cell = Cell:New(55, 12)

        local function set_runic_power_max(value)
            runic_power_max_cell:setCellRGBA(value / 255)
        end
        set_runic_power_max(runic_power_max:get_value()) -- 初始化时设置一次颜色
        runic_power_max:register_callback(set_runic_power_max)


        local dk_interrupt_mode_cell = Cell:New(56, 12)

        local function set_dk_interrupt_mode(value)
            if value == "blacklist" then
                dk_interrupt_mode_cell:setCellRGBA(255 / 255) -- 绿色表示黑名单模式
            else
                dk_interrupt_mode_cell:setCellRGBA(127 / 255) -- 红色表示任意打断模式
            end
        end
        set_dk_interrupt_mode(dk_interrupt_mode:get_value()) -- 初始化时设置一次颜色
        dk_interrupt_mode:register_callback(set_dk_interrupt_mode)
    end







    insert(InitUI, InitializeDKSetting) -- 注册 aura 序列初始化入口
end

if currentSpec == 1 then
    -- 血DK
    do
        local blood_death_strike_health_threshold = Config("blood_death_strike_health_threshold")                             -- 死亡打击生命值阈值
        local blood_death_strike_runic_power_overflow_threshold = Config("blood_death_strike_runic_power_overflow_threshold") -- 死亡打击泄能阈值
        local reaper_mark_health_threshold = Config("reaper_mark_health_threshold")                                           -- 死亡打击泄能阈值

        insert(addonTable.Panel.Rows, {
            type = "slider",
            key = "blood_death_strike_health_threshold",
            name = "死亡打击生命值阈值",
            tooltip = "当前生命值低于该百分比时，使用死亡打击",
            min_value = 40,
            max_value = 70,
            step = 5,
            default_value = 55,
            bind_config = blood_death_strike_health_threshold,
        })

        insert(addonTable.Panel.Rows, {
            type = "slider",
            key = "blood_death_strike_runic_power_overflow_threshold",
            name = "死亡打击泄能阈值",
            tooltip = "当前符文能量高于该值时，使用死亡打击避免浪费",
            min_value = 80,
            max_value = 120,
            step = 10,
            default_value = 100,
            bind_config = blood_death_strike_runic_power_overflow_threshold,
        })

        insert(addonTable.Panel.Rows, {
            type = "slider",
            key = "reaper_mark_health_threshold",
            name = "死神印记血量阈值",
            tooltip = "当敌人生命值低于此值时，就不会再使用死神印记",
            min_value = 10,
            max_value = 60,
            step = 10,
            default_value = 30,
            bind_config = reaper_mark_health_threshold,
        })

        local function InitializeBloodSettingCell() -- 符文能量 Cell 初始化函数
            local blood_death_strike_health_threshold_cell = Cell:New(57, 12)
            local blood_death_strike_runic_power_overflow_threshold_cell = Cell:New(58, 12)
            local reaper_mark_health_threshold_cell = Cell:New(59, 12)


            local function set_blood_death_strike_health_threshold(value)
                blood_death_strike_health_threshold_cell:setCellRGBA(value / 255)
            end
            set_blood_death_strike_health_threshold(blood_death_strike_health_threshold:get_value()) -- 初始化时设置一次颜色
            blood_death_strike_health_threshold:register_callback(set_blood_death_strike_health_threshold)

            local function set_blood_death_strike_runic_power_overflow_threshold(value)
                blood_death_strike_runic_power_overflow_threshold_cell:setCellRGBA(value / 255)
            end
            set_blood_death_strike_runic_power_overflow_threshold(blood_death_strike_runic_power_overflow_threshold:get_value()) -- 初始化时设置一次颜色
            blood_death_strike_runic_power_overflow_threshold:register_callback(set_blood_death_strike_runic_power_overflow_threshold)

            local function set_reaper_mark_health_threshold(value)
                reaper_mark_health_threshold_cell:setCellRGBA(value / 255)
            end
            set_reaper_mark_health_threshold(reaper_mark_health_threshold:get_value()) -- 初始化时设置一次颜色
            reaper_mark_health_threshold:register_callback(set_reaper_mark_health_threshold)
        end
        insert(InitUI, InitializeBloodSettingCell) -- 注册 aura 序列初始化入口
    end
end
