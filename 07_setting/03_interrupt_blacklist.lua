--[[
文件定位:
  DejaVu 打断黑名单模块
状态:
  draft
]]

local addonName, addonTable = ... -- luacheck: ignore addonName

-- Lua 原生函数
local insert = table.insert
local pairs = pairs

-- WoW 官方 API
local GetSpellTexture = C_Spell.GetSpellTexture

-- 插件内引用
local Config = addonTable.Config           -- 配置对象工厂
local InitUI = addonTable.Listeners.InitUI -- 初始化 UI 函数列表
local COLOR = addonTable.COLOR             -- 颜色表
local BadgeCell = addonTable.BadgeCell     -- 图标单元



-- 创建配置对象
local interrupt_blacklist = Config("interrupt_blacklist")      -- 驱散黑名单配置项
local MAX_COUNT = 20                                           -- 最大数量
local POS_X = 43                                               -- X轴位置
local POS_Y = 17                                               -- Y轴位置
local BADGE_COLOR = COLOR.SPELL_TYPE.ENEMY_SPELL_INTERRUPTIBLE -- 图标颜色

-- 添加到面板
do
    local spell_list_row = { -- 技能列表示例行
        type = "spell_list", -- 设置类型
        key = "interrupt_blacklist", -- 行标识
        name = "打断黑名单", -- 标题文本
        tooltip = "不可以自动打断的技能列表。", -- 提示信息
        default_value = { -- 默认技能集合
            [1284627] = true, -- 示例技能1
        }, -- default_value 结束
        bind_config = interrupt_blacklist -- 绑定的配置对象
    } -- spell_list_row 结束

    table.insert(addonTable.Panel.Rows, spell_list_row) -- 写入技能列表示例
end



local function InitializeListCell() -- 初始化列表槽
    local cells = {}
    for i = 1, MAX_COUNT do         -- 预创建固定数量的槽位
        local x = POS_X - 2 + 2 * i -- 计算当前槽位 x 坐标
        local y = POS_Y             -- 当前槽位 y 坐标
        local icon = BadgeCell:New(x, y)
        insert(cells, icon)
    end

    local tableValue = interrupt_blacklist:get_value()
    local function updateCell(_tableValue)
        local i = 1
        for spellID in pairs(_tableValue) do
            if i > MAX_COUNT then
                break
            end
            local cell = cells[i]
            cell:setCell(GetSpellTexture(spellID), BADGE_COLOR)

            i = i + 1
        end

        for j = i, MAX_COUNT do
            local cell = cells[j]
            cell:clearCell()
        end
    end
    updateCell(tableValue)
    interrupt_blacklist:register_callback(updateCell)
end -- InitializeListCell 结束
insert(InitUI, InitializeListCell)
