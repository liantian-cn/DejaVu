# DejaVu 工作指引

这是 `DejaVu/` 的独立开发入口，只处理 WoW 插件这一侧。

## 必读文档

1. `./.context/README.md`
2. `./.context/01_shared_protocol.md`
3. `./.context/03_color_conventions.md`
4. `./.context/00_secret_values.md`

## 开发边界

- 只开发 `DejaVu/`
- 不顺手修改 `Terminal/`
- 如果用户一句话同时提到两边，先拆任务，不要双边一起改
- 如果只是协议、颜色、矩阵语义要改，先改 `DejaVu/.context/` 里的协议文档，再决定是否继续动代码

## 开发规则

- Git 永远工作在小写的 `wip` 分支；如果不在 `wip`，先切过去
- 任何修改文件前，先提交一次 `backup`
- 修改完成后，再提交一次这次改动的简要信息
- 不主动“优化”用户代码；只有用户明确要求，或用户先指出实际异常，才处理
- 处理异常时，只改异常相关部分，不顺手扩散修改
- 补注释时，不要强行套主流规范；函数中间注释和行尾注释都允许
- 不要顺手帮用户做额外操作，除非用户明确要求
- API 问题先用 `wow-api-mcp`
- 如果返回值是否属于 `secret values` 判断不清，继续查 `https://warcraft.wiki.gg/`
- 只要涉及血量、能量、冷却、光环、施法、威胁、单位身份、战斗中判断，先读 `./.context/00_secret_values.md`
- Lua 检查用 `luacheck 01_utils 02_core 03_matrix 04_panel 05_slots 06_spec`
- 改代码前先看 `git status --short`；无论是否脏工作区，都先按项目规则提交一次 `backup`
- `local addonName, addonTable = ...` 之后，马上做当前文件会用到的全局函数本地化
- 禁止用 `_` 当返回值占位符
- 不实现自动战斗或代替玩家决策的逻辑
