--[[
文件定位:
  DejaVu Aura 序列槽位显示模块, 负责 Buff / Debuff 的 Cell 布局与刷新。



状态:
  draft
]]

-- luacheck: globals C_UnitAuras
local addonName, addonTable = ... -- luacheck: ignore addonName -- 插件入口固定写法

-- Lua 原生函数
local string_sub = string.sub
local insert = table.insert
local pairs = pairs
local wipe = wipe

-- WoW 官方 API
local GetUnitAuraInstanceIDs = C_UnitAuras.GetUnitAuraInstanceIDs                 -- 读取单位 aura 实例 ID 列表
local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID       -- 读取 aura 数据
local GetAuraDuration = C_UnitAuras.GetAuraDuration                               -- 读取 aura 剩余时长对象
local GetAuraApplicationDisplayCount = C_UnitAuras.GetAuraApplicationDisplayCount -- 读取 aura 层数字符串
local GetAuraDispelTypeColor = C_UnitAuras.GetAuraDispelTypeColor                 -- 按曲线映射 aura 类型颜色
local DoesAuraHaveExpirationTime = C_UnitAuras.DoesAuraHaveExpirationTime         -- 判断 aura 是否会自然结束
local UnitExists = UnitExists                                                     -- 本地化单位存在判断
local UnitCanAttack = UnitCanAttack                                               -- 本地化敌对判断
local EvaluateColorFromBoolean = C_CurveUtil.EvaluateColorFromBoolean             -- 把布尔值映射成颜色

-- 插件内引用
local InitUI = addonTable.Listeners.InitUI                                           -- 初始化 UI 函数列表
local COLOR = addonTable.COLOR                                                       -- 颜色表
local Cell = addonTable.Cell                                                         -- 基础色块单元
local BadgeCell = addonTable.BadgeCell                                               -- 图标单元
local CharCell = addonTable.CharCell                                                 -- 文字单元

local OnUpdateHigh = addonTable.Listeners.OnUpdateHigh                               -- 高频刷新回调列表
local UNIT_AURA_CHANGED = addonTable.Listeners.UNIT_AURA_CHANGED                     -- UNIT_AURA 回调列表
local TARGET_CHANGED = addonTable.Listeners.TARGET_CHANGED                           -- 目标变化回调列表
local FOCUS_CHANGED = addonTable.Listeners.FOCUS_CHANGED                             -- 焦点变化回调列表
local MOUSEOVER_CHANGED = addonTable.Listeners.MOUSEOVER_CHANGED                     -- 鼠标悬停单位存在状态变化回调列表
local PARTY_CHANGED = addonTable.Listeners.PARTY_CHANGED                             -- 阘伍成员变化回调列表

local remainingCurve = addonTable.Slots.remainingCurve                               -- 剩余时间颜色曲线
local debuffOnFriendlyCurve = addonTable.Slots.debuffOnFriendlyCurve                 -- 玩家身上减益颜色曲线
local buffOnFriendlyCurve = addonTable.Slots.buffOnFriendlyCurve                     -- 玩家身上增益颜色曲线

local function AuraSequenceCreator(options)                                          -- 创建一组 aura 序列槽位
    local unit = options.unit                                                        -- 目标单位
    local filter = options.filter                                                    -- aura 过滤条件
    local maxCount = options.maxCount                                                -- 最多显示数量
    local posX = options.posX                                                        -- 左上角 x 坐标
    local posY = options.posY                                                        -- 左上角 y 坐标
    local sortRule = options.sortRule or Enum.UnitAuraSortRule.Default               -- aura 排序规则
    local sortDirection = options.sortDirection or Enum.UnitAuraSortDirection.Normal -- aura 排序方向

    local isBuff = string.find(filter, "HELPFUL", 1, true) ~= nil                    -- 是否是 buff 序列
    local isDebuff = not isBuff                                                      -- 非 buff 就按 debuff 处理
    local auraCells = {}                                                             -- 当前序列的显示单元
    local instanceIDToCell = {}                                                      -- aura 实例 ID 到显示单元的映射

    for i = 1, maxCount do                                                           -- 预创建固定数量的槽位
        local x = posX - 2 + 2 * i                                                   -- 计算当前槽位 x 坐标
        local y = posY                                                               -- 当前槽位 y 坐标

        insert(auraCells, {                                                          -- 追加一个 aura 显示分组
            icon = BadgeCell:New(x, y),                                              -- aura 图标
            remaining = Cell:New(x, y + 2),                                          -- 剩余时间颜色
            forever = Cell:New(x, y + 2),                                            -- 是否永久覆盖层
            spellType = Cell:New(x + 1, y + 2),                                      -- aura 类型颜色
            count = CharCell:New(x, y + 3),                                          -- aura 层数文本
        })
    end

    local function clearAuraCell(cell) -- 清空单个 aura 槽位, 避免残留旧画面
        cell.icon:clearCell()
        cell.remaining:clearCell()
        cell.forever:clearCell()
        cell.spellType:clearCell()
        cell.count:clearCell()
    end

    local function clearAllCells()    -- 清空整组槽位显示
        for i = 1, maxCount do        -- 遍历全部槽位
            local cell = auraCells[i] -- 取出当前槽位

            clearAuraCell(cell)       -- 清空这个槽位的全部显示
        end
    end

    local function updateFullSequence() -- 全量刷新当前 aura 序列
        wipe(instanceIDToCell)          -- 先清空实例映射

        if not UnitExists(unit) then    -- 单位不存在时直接清空
            clearAllCells()             -- 清空画面残留
            return                      -- 提前结束刷新
        end

        local isEnemy = UnitCanAttack("player", unit)   -- 判断这个单位对玩家是否敌对
        local isFriendly = not isEnemy                  -- 非敌对就按友方处理
        local auraInstanceIDs = GetUnitAuraInstanceIDs( -- 获取排序后的 aura 实例列表
            unit,
            filter,
            maxCount,
            sortRule,
            sortDirection
        ) or {}

        for i = 1, maxCount do                                                                     -- 固定刷新每个显示槽位
            local cell = auraCells[i]                                                              -- 当前槽位对象

            if i > #auraInstanceIDs then                                                           -- 超出实际 aura 数量时清空显示
                clearAuraCell(cell)                                                                -- 清空整个槽位
            else
                local auraInstanceID = auraInstanceIDs[i]                                          -- 当前 aura 的实例 ID
                local aura = GetAuraDataByAuraInstanceID(unit, auraInstanceID)                     -- 取当前 aura 数据

                if aura ~= nil then                                                                -- 取到 aura 数据才继续刷新
                    instanceIDToCell[auraInstanceID] = cell                                        -- 建立实例到槽位的映射

                    local remaining = GetAuraDuration(unit, auraInstanceID)                        -- 剩余时间对象
                    local hasExpirationTime = DoesAuraHaveExpirationTime(unit, auraInstanceID)     -- 是否会到时结束
                    local count = GetAuraApplicationDisplayCount(unit, auraInstanceID, 1, 9)       -- 取层数字符串
                    local spellTypeColor = nil                                                     -- 本次 aura 的边框 / 类型颜色

                    cell.count:setCell(count)                                                      -- 写入层数文本

                    if remaining ~= nil then                                                       -- 有剩余时间对象时更新颜色
                        local remainingColor = remaining:EvaluateRemainingDuration(remainingCurve) -- 计算时间颜色

                        cell.remaining:setCell(remainingColor)                                     -- 写入剩余时间颜色
                    else
                        cell.remaining:clearCell()                                                 -- 没有剩余时间时清空显示
                    end

                    if hasExpirationTime ~= nil then                   -- 只有拿到布尔值时才做映射
                        local foreverColor = EvaluateColorFromBoolean( -- true 透明, false 白色
                            hasExpirationTime,
                            COLOR.TRANSPARENT,
                            COLOR.WHITE
                        )

                        cell.forever:setCell(foreverColor) -- 写入永久标记颜色
                    else
                        cell.forever:clearCell()           -- 取不到时清空永久标记
                    end

                    if isFriendly and isDebuff then                                                          -- 友方单位的减益效果
                        spellTypeColor = GetAuraDispelTypeColor(unit, auraInstanceID, debuffOnFriendlyCurve) -- 计算减益颜色
                    elseif isFriendly and isBuff then                                                        -- 友方单位的增益效果
                        -- spellTypeColor = GetAuraDispelTypeColor(unit, auraInstanceID, buffOnFriendlyCurve)   -- 计算增益颜色
                        spellTypeColor = COLOR.SPELL_TYPE.BUFF_ON_FRIENDLY                                   -- 友方增益使用固定颜色
                    elseif isEnemy and isDebuff then                                                         -- 敌方单位的减益效果
                        spellTypeColor = COLOR.SPELL_TYPE.DEBUFF_ON_ENEMY                                    -- 敌方减益使用固定颜色
                    end

                    if spellTypeColor ~= nil then
                        cell.icon:setCell(aura.icon, spellTypeColor) -- 写入图标和边色
                        cell.spellType:setCell(spellTypeColor)       -- 写入类型颜色
                    else
                        cell.icon:clearCell()                        -- 当前组合没有定义显示颜色时清空
                        cell.spellType:clearCell()                   -- 避免沿用上一次颜色
                    end
                else
                    clearAuraCell(cell) -- 取不到 aura 数据时清空, 避免旧图标残留
                end
            end
        end
    end

    local function updateRemaining()                                                           -- 高频补刷剩余时间颜色
        for auraInstanceID, cell in pairs(instanceIDToCell) do                                 -- 遍历当前仍显示的 aura
            if cell ~= nil then                                                                -- 防御式判断, 避免空引用
                local remaining = GetAuraDuration(unit, auraInstanceID)                        -- 重新读取剩余时间对象

                if remaining ~= nil then                                                       -- 能读取到时就更新颜色
                    local remainingColor = remaining:EvaluateRemainingDuration(remainingCurve) -- 重新计算时间颜色

                    cell.remaining:setCell(remainingColor)                                     -- 写入新的时间颜色
                else
                    cell.remaining:clearCell()                                                 -- 没有剩余时间时清空显示
                end
            end
        end
    end

    insert(OnUpdateHigh, updateRemaining)                                 -- 注册高频时间刷新
    insert(UNIT_AURA_CHANGED, { unit = unit, func = updateFullSequence }) -- 注册 aura 事件刷新

    if unit == "target" then                                              -- 目标单位额外监听目标切换
        insert(TARGET_CHANGED, updateFullSequence)                        -- 注册目标切换回调
    elseif unit == "focus" then                                           -- 焦点单位额外监听焦点切换
        insert(FOCUS_CHANGED, updateFullSequence)                         -- 注册焦点切换回调
    elseif unit == "mouseover" then                                       -- 鼠标悬停单位额外监听存在状态变化
        insert(MOUSEOVER_CHANGED, updateFullSequence)                     -- 注册鼠标悬停存在状态变化回调
    elseif string_sub(unit, 1, 5) == "party" then                         -- 阘伍单位额外监听成员变化
        insert(PARTY_CHANGED, updateFullSequence)                         -- 注册队伍成员变化回调
    end
    -- insert(OnUpdateHigh, updateFullSequence)
    updateFullSequence() -- 初始化时先全量刷新一次
end

addonTable.AuraSequenceCreator = AuraSequenceCreator

local function InitializeAuraSequence()                    -- 初始化 aura 序列槽位
    AuraSequenceCreator {                                  -- 玩家 buff 序列
        unit = "player",                                   -- 玩家单位
        filter = "HELPFUL",                                -- 只看增益
        maxCount = 30,                                     -- 最多显示 30 个
        posX = 1,                                          -- 起始 x 坐标
        posY = 4,                                          -- 起始 y 坐标
        sortRule = Enum.UnitAuraSortRule.Expiration,       -- 按到期时间排序
        sortDirection = Enum.UnitAuraSortDirection.Normal, -- 正序排列
    }

    AuraSequenceCreator {                                  -- 玩家 debuff 序列
        unit = "player",                                   -- 玩家单位
        filter = "HARMFUL",                                -- 只看减益
        maxCount = 10,                                     -- 最多显示 10 个
        posX = 1,                                          -- 起始 x 坐标
        posY = 9,                                          -- 起始 y 坐标
        sortRule = Enum.UnitAuraSortRule.Expiration,       -- 按到期时间排序
        sortDirection = Enum.UnitAuraSortDirection.Normal, -- 正序排列
    }

    AuraSequenceCreator {                                  -- 目标上的玩家减益序列
        unit = "target",                                   -- 目标单位
        filter = "HARMFUL|PLAYER",                         -- 只看玩家施加的减益
        maxCount = 16,                                     -- 最多显示 15 个
        posX = 22,                                         -- 起始 x 坐标
        posY = 9,                                          -- 起始 y 坐标
        sortRule = Enum.UnitAuraSortRule.Expiration,       -- 按到期时间排序
        sortDirection = Enum.UnitAuraSortDirection.Normal, -- 正序排列
    }

    AuraSequenceCreator {                                  -- 焦点上的玩家减益序列
        unit = "focus",                                    -- 焦点单位
        filter = "HARMFUL|PLAYER",                         -- 只看玩家施加的减益
        maxCount = 10,                                     -- 最多显示 10 个
        posX = 1,                                          -- 起始 x 坐标
        posY = 14,                                         -- 起始 y 坐标
        sortRule = Enum.UnitAuraSortRule.Expiration,       -- 按到期时间排序
        sortDirection = Enum.UnitAuraSortDirection.Normal, -- 正序排列
    }

    AuraSequenceCreator {                                  -- 鼠标悬停单位上的玩家减益序列
        unit = "mouseover",                                -- 鼠标悬停单位
        filter = "HARMFUL|PLAYER",                         -- 只看玩家施加的减益
        maxCount = 10,                                     -- 最多显示 10 个
        posX = 22,                                         -- 起始 x 坐标
        posY = 14,                                         -- 起始 y 坐标
        sortRule = Enum.UnitAuraSortRule.Expiration,       -- 按到期时间排序
        sortDirection = Enum.UnitAuraSortDirection.Normal, -- 正序排列
    }
end

insert(InitUI, InitializeAuraSequence) -- 注册 aura 序列初始化入口
