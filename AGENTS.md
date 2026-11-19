# Git 提交约定

本仓库后续提交遵循 [Conventional Commits 1.0.0](https://www.conventionalcommits.org/zh-hans/v1.0.0/)。

- 标题采用 `type(scope): 描述`。范围可省略，类型使用小写英文，描述沿用简洁中文。
- 新增功能使用 `feat`，修复问题使用 `fix`。文档、重构、测试或构建改动分别使用 `docs`、`refactor`、`test` 或 `build`。
- 范围按改动涉及的模块填写，例如 `metronome`、`tuner` 或 `audio`。
- 破坏性变更在冒号前加 `!`，或在页脚用 `BREAKING CHANGE: 描述` 说明影响。

示例：`feat(metronome): 支持从曲目菜单切换预设`、`fix(audio): 修正贝斯参考音的音高`。
