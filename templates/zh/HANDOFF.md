# Session Bootstrap

> 本文件存放 session agent 的 bootstrap prompt。
> 内容是稳定的——每次 spawn session agent 都用同一个 prompt。
> 变化的是 CURRENT.md，session agent 读 prompt 后自然会去读它。

## Session Prompt

```text
读取 .project/RULES.md 和 .project/CURRENT.md。
核对代码和 Git 状态与 CURRENT.md 是否一致；如有漂移或冲突，先报告。
从"下一步"中选取可执行动作，直接开始，不为例行步骤等待确认。
完成后执行 RULES.md 中定义的收工流程：
更新 CURRENT.md、运行验证检查、报告已完成/未完成/阻塞/证据/下一步。
```

## 环境入口

<!-- 填入本项目的关键命令，供 session agent 快速上手 -->

构建：`<命令>`
测试：`<命令>`
Lint：`<命令>`
开发服务器：`<命令>`

## 常用路径

<!-- 填入 session agent 经常需要操作的目录/文件 -->

源码入口：
配置文件：
测试目录：
