# 职业测试设定怎么写

这篇文档专门总结 `06_spec/deathknight` 和 `06_spec/durid` 现在的写法, 目的是以后你要给别的职业补“测试专用设定”时, 可以直接照这个结构落地。

这里说的“测试设定”, 指的是两类东西：

1. 方便你手动按键验证的测试宏
2. 方便你临时调阈值、并把阈值显示到固定 Cell 上的面板配置

它不是自动战斗逻辑, 也不是替玩家做决定。

## 先看现有样例

完整样例在死亡骑士：

- `06_spec/deathknight/spec.lua`
- `06_spec/deathknight/setting.lua`
- `06_spec/deathknight/blood.lua`

简化样例在德鲁伊：

- `06_spec/durid/spec.lua`
- `06_spec/durid/guardian.lua`

从这两个目录可以看出, 职业测试设定通常拆成 2 层或 3 层文件。

## 推荐目录结构

### 1. `spec.lua`

作用：写这个职业本身的“资源显示”或“职业公共显示”。

例子：

- 死亡骑士 `spec.lua` 用符文数量驱动 Cell
- 德鲁伊 `spec.lua` 用连击点驱动 Cell

这个文件一般负责：

- 判断是不是目标职业
- 拿职业公共资源
- 把结果写进固定坐标的 Cell
- 挂到 `InitUI`、事件监听或高频刷新里

### 2. `<专精名>.lua`

作用：写这个专精测试时要用的宏绑定。

例子：

- `06_spec/deathknight/blood.lua`
- `06_spec/durid/guardian.lua`

这个文件一般负责：

- 判断职业和专精, 不符合就直接 `return`
- 准备 `macroList`
- 循环创建安全按钮
- 给按键绑定测试宏
- 打日志, 方便确认绑定有没有成功

### 3. `setting.lua`（可选）

作用：当这个职业需要“可调测试阈值”时, 再单独加这个文件。

死亡骑士就是完整示例, 它做了两件事：

1. 往 `addonTable.Panel.Rows` 里插入面板配置项
2. 把配置值同步到固定 Cell, 方便你边打边看当前阈值

德鲁伊目录没有这个文件, 说明一件事：  
如果你只是想先验证技能、目标、宏、资源显示, 那么只写 `spec.lua` 和 `<专精名>.lua` 就够了, 不需要强行补一个 `setting.lua`。

## 什么时候该加 `setting.lua`

满足下面任意一种情况, 就建议加：

- 你要反复调某个阈值, 比如血量阈值、泄能阈值、打断模式
- 你希望这些值能在面板里改, 而不是去 Lua 里手改
- 你希望这些值能实时映射到某几个固定 Cell, 方便录制或观察

如果只是临时加几个手动测试宏, 不需要加。

## 标准写法

## 第一步：文件开头先做职业/专精挡板

这两个样例都遵守了同一个思路：  
文件一加载, 先判断职业；专精专用文件再额外判断专精；不符合立刻退出。

```lua
local addonName, addonTable = ... -- luacheck: ignore addonName addonTable

local insert = table.insert

local UnitClass = UnitClass
local GetSpecialization = GetSpecialization

local className, classFilename, classId = UnitClass("player")
local currentSpec = GetSpecialization()

if classFilename ~= "DEATHKNIGHT" then return end
if currentSpec ~= 1 then return end
```

注意：

- `local addonName, addonTable = ...` 后面, 马上把本文件会用到的全局函数本地化
- 不要用 `_` 当占位返回值

## 第二步：如果只是做测试按键, 就写 `macroList`

`blood.lua` 和 `guardian.lua` 的核心结构是一样的。

先准备一个列表：

```lua
local macroList = {}

insert(macroList, { title = "reloadUI", key = "CTRL-F12", text = "/reload" })
insert(macroList, { title = "target技能A", key = "ALT-NUMPAD1", text = "/cast [@target] 技能A" })
insert(macroList, { title = "focus技能A", key = "ALT-NUMPAD2", text = "/cast [@focus] 技能A" })
```

每一项通常有 3 个字段：

- `title`：内部名字, 同时会拼进按钮名里, 所以最好短一点、稳定一点
- `key`：你测试时实际按的快捷键
- `text`：宏正文

常见宏类型：

- `@target`
- `@focus`
- `@cursor`
- “最近目标”测试宏
- 纯自保技能
- `reload`

这些宏是帮你手动压测、录制、对照显示, 不是让插件自动施法。

## 第三步：循环注册安全按钮和按键绑定

两个职业样例都是同一套注册方式：

```lua
local pairs = pairs
local CreateFrame = CreateFrame
local SetOverrideBindingClick = SetOverrideBindingClick
local logging = addonTable.Logging

for _, macro in pairs(macroList) do
    local buttonName = addonName .. "Button" .. macro.title
    local frame = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("macrotext", macro.text)
    frame:RegisterForClicks("AnyDown", "AnyUp")
    SetOverrideBindingClick(frame, true, macro.key, buttonName)
    logging("RegMacro[" .. macro.title .. "] > " .. macro.key .. " > " .. macro.text)
end
```

这里你真正要记住的是：

- 用的是 `SecureActionButtonTemplate`
- 绑定走 `SetOverrideBindingClick`
- 宏正文直接塞进 `macrotext`
- 最后打一条日志, 出问题时好查

## 第四步：如果要做“可调测试阈值”, 就用 `Config("xxx")`

死亡骑士 `setting.lua` 的结构可以直接照搬。

先拿配置对象：

```lua
local Config = addonTable.Config

local runic_power_max = Config("runic_power_max")
local dk_interrupt_mode = Config("dk_interrupt_mode")
```

然后把面板行塞进去：

```lua
insert(addonTable.Panel.Rows, {
    type = "slider",
    key = "runic_power_max",
    name = "最大符文能量",
    tooltip = "设置最大符文能量值",
    min_value = 100,
    max_value = 140,
    step = 5,
    default_value = 125,
    bind_config = runic_power_max,
})

insert(addonTable.Panel.Rows, {
    type = "combo",
    key = "dk_interrupt_mode",
    name = "打断模式",
    tooltip = "选择打断模式",
    default_value = "blacklist",
    options = {
        { k = "blacklist", v = "使用黑名单" },
        { k = "all", v = "任意打断" },
    },
    bind_config = dk_interrupt_mode,
})
```

要点只有两个：

- `key` 是这行 UI 自己的标识
- 真正存值、取值的是 `bind_config = Config("xxx")`

如果你对配置对象怎么读写还要回看, 可以再看 `docs/CONFIG_ACCESS.md`。

## 第五步：把配置值映射到固定 Cell

这一步也是死亡骑士样例的重点。  
思路不是“做复杂逻辑”, 而是“把当前测试值直接画出来”。

标准写法：

```lua
local InitUI = addonTable.Listeners.InitUI
local Cell = addonTable.Cell

local function InitializeSettingCell()
    local sampleCell = Cell:New(55, 12)

    local function set_sample(value)
        sampleCell:setCellRGBA(value / 255)
    end

    set_sample(sample_config:get_value())
    sample_config:register_callback(set_sample)
end

insert(InitUI, InitializeSettingCell)
```

这里分两步：

1. 初始化时先用当前配置值画一次
2. 再注册 `callback`, 以后面板一改, Cell 跟着变

这样做的好处很直接：

- 不用重载就能看到阈值变化
- 录屏时能直接看到当前测的是哪套参数
- 方便排查“是逻辑错了, 还是设定值不对”

## 第六步：职业公共资源放进 `spec.lua`

这两个职业的 `spec.lua` 也给了一个很明确的分工：

- 德鲁伊：资源变化适合事件驱动, 就挂 `UNIT_POWER_CHANGED`
- 死亡骑士：符文状态适合持续看, 就挂 `OnUpdateHigh`

也就是说, 不要死套一种更新方式。  
哪个资源更适合事件, 就用事件；哪个资源更适合持续轮询, 就用轮询。

简化模板：

```lua
local InitUI = addonTable.Listeners.InitUI
local Cell = addonTable.Cell

local function InitializeClassSpec()
    local resourceCell = Cell:New(55, 13)

    local function UpdateSpec()
        local value = 0
        resourceCell:setCellRGBA(value / 255)
    end

    -- 这里按资源特点决定挂事件还是高频更新
end

insert(InitUI, InitializeClassSpec)
```

## 建议你照着做的落地顺序

给一个新职业补测试设定时, 按这个顺序最稳：

1. 先写 `spec.lua`, 只做职业资源显示
2. 再写 `<专精名>.lua`, 只放手动测试宏
3. 只有当你真的需要“面板可调阈值”时, 再补 `setting.lua`
4. 最后把文件顺序挂到 `DejaVu.toc`

当前样例在 `DejaVu.toc` 里的顺序也说明了这个思路：

```text
06_spec/durid/spec.lua
06_spec/durid/guardian.lua
06_spec/deathknight/spec.lua
06_spec/deathknight/setting.lua
06_spec/deathknight/blood.lua
```

也就是：

- 先公共资源
- 再公共设定（如果有）
- 最后专精测试文件

## 写这类文件时, 最容易踩的坑

### 1. 不要把“测试设定”写成“自动战斗”

这类文件可以做：

- 快捷键测试
- 手动验证
- 参数可视化
- 面板调试

不要做：

- 自动选技能
- 自动打断
- 自动决定战斗动作

### 2. 只要碰战斗数据, 先警惕 secret values

如果你的测试设定要碰这些东西：

- 血量
- 能量
- 冷却
- Aura
- 施法
- 威胁
- 单位身份

先回头看 `.context/00_secret_values.md`。  
能用百分比 API 就优先用百分比 API, 能只显示就不要自己做复杂计算。

### 3. 能复用模板, 就别一上来写大而全

从现有样例看, 最实用的不是一开始把所有测试能力一次性写满, 而是：

- 先做最小可测结构
- 宏能按
- Cell 能亮
- 日志能看
- 真有需要再补 `setting.lua`

德鲁伊目录就是这个“先够用”的例子。

## 最小模板

如果你只是要给一个新职业快速补测试按键, 最小结构可以直接照这个骨架改：

```lua
local addonName, addonTable = ... -- luacheck: ignore addonName addonTable

local insert = table.insert
local pairs = pairs

local CreateFrame = CreateFrame
local SetOverrideBindingClick = SetOverrideBindingClick
local UnitClass = UnitClass
local GetSpecialization = GetSpecialization

local className, classFilename, classId = UnitClass("player")
local currentSpec = GetSpecialization()
if classFilename ~= "职业英文名" then return end
if currentSpec ~= 专精编号 then return end

local logging = addonTable.Logging

local macroList = {}
insert(macroList, { title = "reloadUI", key = "CTRL-F12", text = "/reload" })
insert(macroList, { title = "target技能A", key = "ALT-NUMPAD1", text = "/cast [@target] 技能A" })

for _, macro in pairs(macroList) do
    local buttonName = addonName .. "Button" .. macro.title
    local frame = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("macrotext", macro.text)
    frame:RegisterForClicks("AnyDown", "AnyUp")
    SetOverrideBindingClick(frame, true, macro.key, buttonName)
    logging("RegMacro[" .. macro.title .. "] > " .. macro.key .. " > " .. macro.text)
end
```

如果你还要做阈值调试, 再补一个 `setting.lua`, 不要把两类职责硬塞进同一个文件。

## 一句话总结

参考现有代码, 最稳的职业测试设定写法就是：

- `spec.lua` 管职业公共资源显示
- `<专精名>.lua` 管该专精的手动测试宏
- `setting.lua` 只在确实需要面板调参时才加

先做能测、能看、能调, 再决定要不要继续扩展。
