# 配置项访问说明

这份文档说明 DejaVu 里“面板配置项的值”应该怎么访问。

## 1. 先记住一个核心点

`Config("xxx")` 返回的不是“配置值”, 而是“配置对象”。

真正取值要用:

```lua
local Config = addonTable.Config
local myConfig = Config("your_config_key")
local value = myConfig:get_value()
```

真正写值要用:

```lua
myConfig:set_value(newValue)
```

相关实现见:

- `02_core/02_config.lua`

## 2. 面板里新增配置项时, 通常怎么写

示例:

```lua
local Config = addonTable.Config

local assisted_combat_enabled_config = Config("assisted_combat_enabled")

local row = {
    type = "combo",
    key = "assisted_combat_enabled_row",
    name = "辅助战斗显示",
    tooltip = "控制是否显示辅助战斗图标",
    default_value = true,
    bind_config = assisted_combat_enabled_config
}
```

这里要区分两个东西:

- `key`: 这一行面板配置的行标识, 主要给 UI 行自己用
- `bind_config`: 真正绑定到保存数据的配置对象

平时业务代码要读取配置值, 重点看的是 `bind_config` 对应的那个 `Config("...")` key。

## 3. 业务代码里怎么访问这个值

只要再次用同一个 key 调一次 `Config("...")`, 拿到的还是同一个配置对象。

示例:

```lua
local Config = addonTable.Config
local assistedCombatEnabledConfig = Config("assisted_combat_enabled")

local function UpdateSomething()
    local enabled = assistedCombatEnabledConfig:get_value()
    if not enabled then
        return
    end

    -- 后面继续你的业务逻辑
end
```

也可以直接临时读取:

```lua
local enabled = addonTable.Config("assisted_combat_enabled"):get_value()
```

但如果一个文件里会多次用到, 通常还是先保存成局部变量更清楚。

## 4. 默认值是怎么生效的

面板在创建控件时, 会把行配置里的 `default_value` 设进配置对象。

如果当前 profile 还没有存过这个 key:

- `get_value()` 会返回默认值

如果当前 profile 已经存过这个 key:

- `get_value()` 会返回保存过的值

所以你平时读配置, 一般直接 `get_value()` 就够了, 不需要自己再判断“有没有默认值”。

## 5. 值最后存到哪里

配置值最终保存在当前 profile 下面:

```lua
DejaVuSave.profiles[DejaVuSave.current_profile][config_key]
```

也就是说:

- 切换 profile 后, 同一个配置项可能读到不同值
- 如果新 profile 还没存过, 就会回到默认值

相关实现见:

- `02_core/01_profile.lua`
- `02_core/02_config.lua`

## 6. 三种常见配置的读取结果

滑块:

```lua
local value = Config("slider_example_config"):get_value()
-- 读出来通常是 number
```

下拉框:

```lua
local value = Config("combo_example_config"):get_value()
-- 读出来通常是选项的 k, 比如 "zhangsan"
```

法术列表:

```lua
local value = Config("spell_list_example_config"):get_value()
-- 读出来通常是 table, 例如: 
-- { [294929] = true, [5487] = true }
```

示例来源:

- `06_spec/99_test.lua`
- `04_panel/02_slider.lua`
- `04_panel/03_combo.lua`
- `04_panel/04_spell_list.lua`

## 7. 最容易搞混的地方

不要把下面两个概念混在一起:

- `row_info.key`
- `Config("xxx")` 里的 key

在当前项目里, 真正决定“配置值存取”的, 是 `Config("xxx")` 里的 key, 不是行配置表里的 `row_info.key`。

## 8. 推荐写法

如果某个业务文件要读配置, 建议写成这样:

```lua
local Config = addonTable.Config
local AssistedCombatEnabledConfig = Config("assisted_combat_enabled")

local function IsAssistedCombatEnabled()
    return AssistedCombatEnabledConfig:get_value()
end
```

这样比到处手写字符串更不容易出错, 也更方便以后改名。
