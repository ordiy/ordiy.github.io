---
layout: post
title: GitHub Copilot CLI vs VS Code Copilot Plugin 使用心得
date: 2026-03-04 10:00 +08:00
categories:
 - AI
tags:
 - Copilot
 - AI
 - 开发工具
 - 效率
 - SDLC
excerpt: 用了一段时间 GitHub Copilot 的两种形态——VS Code Plugin 和 Copilot CLI——发现它们并不是同一个工具的两个入口，而是面向完全不同使用场景的两个产品。本文记录实际使用中的核心差异、各自优势，以及如何在 SDLC 各阶段合理搭配使用。
---

## 前言

用了一段时间 GitHub Copilot 的两种形态——**VS Code Plugin** 和 **Copilot CLI**——发现它们并不是同一个工具的两个入口，而是面向完全不同使用场景的两个产品。本文记录实际使用中的核心差异、各自优势，以及如何在 SDLC 各阶段合理搭配使用。

---

## 一、本质定位差异

| 维度 | Copilot CLI | VS Code Copilot Plugin |
|---|---|---|
| 设计哲学 | **面向任务的 AI 代理** | **面向文件的编码助手** |
| 交互模式 | 长对话 + 工具执行闭环 | 内联补全 + 短对话 |
| 上下文感知 | 系统级（跨机器、跨服务） | 编辑器级（当前文件/选中代码） |
| 执行能力 | 真实执行命令、SSH、脚本 | 代码生成和修改建议 |
| 记忆持久性 | Session + Checkpoint 跨对话 | 基本每次对话独立 |

一句话：

> **VS Code Copilot 是"智能键盘"，Copilot CLI 是"AI 同事"。**

---

## 二、核心能力对比

### 2.1 模型能力

| | Copilot CLI | VS Code Copilot |
|---|---|---|
| 默认模型 | Claude Sonnet 4.6 | GPT-4o 为主 |
| 可切换模型 | ✅ `/model` 命令切换 | ✅ 设置中切换 |
| 上下文窗口 | 更大（适合长任务） | 受编辑器集成限制 |
| 推理能力 | Claude 在长链推理、指令跟随上更强 | GPT-4o 代码补全响应更快 |

### 2.2 工具调用

Copilot CLI 拥有完整的工具集：

```
bash          — 真实执行 shell 命令
async bash    — 交互式进程控制（可发送输入、读取输出）
grep / glob   — 精准代码搜索
view / edit / create — 文件操作
SQL           — 任务状态追踪
web_fetch     — 实时抓取网页
web_search    — AI 驱动的联网搜索
GitHub MCP    — 操作 PR / Issues / Actions / Commits
ask_user      — 主动询问用户决策
```

VS Code Copilot 的工具边界：主要是代码生成、文件读写、终端执行（有限）。

### 2.3 记忆与上下文管理

**Copilot CLI 的 Session 机制：**

```
当前 session
  ├── 完整对话历史
  ├── 执行过的命令及输出
  ├── 已修改的文件记录
  └── Checkpoint（关键节点快照）

/compact   — 超出上下文时自动摘要压缩，保留关键信息
/resume    — 恢复历史 session，跨天继续工作
/context   — 实时查看 token 占用可视化
/session   — 查看 session 详情和工作区摘要
```

**实际效果举例：**  
一天内部署 EC2 + 安装 Xray + 配置 OpenClaw + 申请证书 + 调试 nginx，整个过程在同一个 session 里，UUID、密码、配置路径无需重复说明，CLI 全程记得上下文。

VS Code Copilot 每次打开新文件或刷新对话，基本从零开始。

---

## 三、SDLC 各阶段适用性

```
需求分析
└── VS Code Copilot Chat ★★★★★
    对话式梳理需求、生成 PRD、拆解 User Story
    Copilot CLI ★★★
    适合复杂需求的深度研究（/research 命令）

系统设计
└── VS Code Copilot ★★★★★
    接口设计、数据模型、架构图描述、技术选型分析
    Copilot CLI ★★★★
    多文件联动的架构调整、查阅在线文档

编码（核心开发）
└── VS Code Copilot ★★★★★  ← 强项
    内联补全、Tab 接受、函数级生成、重构建议
    Copilot CLI ★★★★
    多文件改动、生成后立即执行验证的闭环

Code Review
└── Copilot CLI ★★★★★  ← 强项
    /review 命令做全局代码审查
    /diff 查看变更摘要
    跨文件安全漏洞、逻辑错误分析
    VS Code Copilot ★★★
    单文件 inline review

测试
└── Copilot CLI ★★★★★  ← 强项
    生成测试 → 执行 → 读取失败输出 → 修复 → 再执行（闭环）
    VS Code Copilot ★★★
    生成测试用例，但无法自动运行验证

CI/CD & 部署
└── Copilot CLI ★★★★★  ← 独占优势
    SSH 远程操作、服务配置、日志分析、实时调试
    VS Code Copilot ★  
    基本做不了

运维监控
└── Copilot CLI ★★★★★  ← 独占优势
    系统诊断、日志分析、配置调优
    VS Code Copilot ★
    不适用
```

### 推荐工作流

```
产品需求  ──→  [VS Code] 写 PRD、拆 Story
    ↓
系统设计  ──→  [VS Code] 定接口、画架构
    ↓
开发      ──→  [VS Code] 写代码（内联补全效率最高）
    ↓           [CLI] 跑测试、分析报错、修复
Code Review ─→  [CLI] /review 全局审查
    ↓
部署上线  ──→  [CLI] SSH 部署、配置服务
    ↓
运维      ──→  [CLI] 监控、调试、故障排查
    ↓
文档沉淀  ──→  [VS Code] 生成文档 → 存 Obsidian
```

---

## 四、Copilot CLI 的独特亮点

### 4.1 交互式进程控制

CLI 可以接管需要人机交互的命令：

```bash
# 例：certbot 申请证书，需要实时输入 Email、同意条款、等待 DNS 生效、按 Enter
# Copilot CLI 全程代劳，包括判断何时输入、等待 DNS 传播、确认后继续
```

这类任务 VS Code 完全无法做到。

### 4.2 真实执行 + 动态修正

```
执行命令 → 读取输出 → 分析报错 → 自动修正 → 再执行
```

实际案例：
- nginx 报 502 → 查 openclaw 日志 → 发现 trustedProxies 未配置 → 修改配置 → 重启 → 验证 WS 握手 101

全程无需人工介入，自动完成 5 轮迭代调试。

### 4.3 GitHub 深度集成

```bash
# 通过 GitHub MCP Server 直接操作：
- 查看 PR diff 和 review comments
- 分析 CI/CD 失败的 job logs
- 搜索全仓库代码
- 读取任意 commit 的变更
```

### 4.4 自定义指令文件

在项目根目录放置指令文件，CLI 会自动加载：

```
AGENTS.md                          — 通用 agent 指令
CLAUDE.md                          — Claude 专属指令  
.github/copilot-instructions.md    — 项目级指令
~/.copilot/copilot-instructions.md — 全局用户指令
```

可以定义代码规范、技术栈偏好、禁止操作等，让 CLI 始终遵循项目约定。

### 4.5 Skills 扩展机制

```bash
/skills   — 查看和管理技能
```

可以封装复杂的重复操作为 Skill，在不同项目复用。

### 4.6 Fleet 并行子代理

```bash
/fleet   — 启用多 agent 并行执行
/tasks   — 查看后台任务状态
```

复杂任务可以拆分给多个子代理并行处理，提升效率。

---

## 五、VS Code Copilot 的独特优势

### 5.1 内联补全体验无可替代

- **Tab 补全**：写一半代码自动补全，延迟极低
- **Ghost text**：实时预览建议，流畅自然
- **多行补全**：函数体、循环结构一次补全

这种"光标上下文感知"是 CLI 无法复制的体验。

### 5.2 编辑器深度集成

- 直接在文件内 inline 修改（不需要描述文件路径）
- 选中代码右键 → Copilot 解释/重构/生成测试
- 错误提示 → Copilot Fix 一键修复

### 5.3 多文件 Workspace 模式

在 VS Code Agent 模式下，可以同时感知整个工作区的文件结构，适合：
- 理解大型代码库
- 跨文件重构（改接口签名影响所有调用方）

---

## 六、常见误区

### ❌ 误区 1：CLI 只是 VS Code 的命令行版

不对。两者工具集、记忆机制、适用场景完全不同，是互补关系而非替代关系。

### ❌ 误区 2：CLI 性能更强是因为"缓存更多"

更准确的说法是：CLI 通过 **Session + Checkpoint + /compact 压缩** 机制，在长任务中保持上下文连贯性。并非缓存更多原始数据，而是更好地管理了上下文窗口。

### ❌ 误区 3：部署类任务用 VS Code 终端也能做

VS Code 终端只是执行命令，没有 AI 读取输出、分析结果、自动修正的能力。CLI 的核心价值在于**执行-观察-修正的闭环**，不是执行本身。

---

## 七、选择建议

| 场景 | 推荐工具 |
|---|---|
| 写业务代码 | VS Code Copilot（补全效率最高） |
| 调试复杂问题 | Copilot CLI（分析 + 修复闭环） |
| 部署/运维 | Copilot CLI（唯一选择） |
| Code Review | Copilot CLI `/review` |
| 查 PR/Issue/Actions | Copilot CLI（GitHub MCP） |
| 生成文档 | 两者均可，CLI 可直接写入文件 |

---

## 八、快速参考：Copilot CLI 常用命令

```bash
# 模式切换
Shift+Tab          — 切换 interactive / plan / autopilot 模式

# 会话管理
/resume            — 恢复历史 session
/compact           — 压缩上下文
/context           — 查看 token 占用
/session           — 查看 session 详情

# 代码
/diff              — 查看当前变更
/review            — 运行 code review agent
/plan              — 生成实现计划再执行

# 研究
/research          — 深度调研（联网 + GitHub 搜索）

# 工具
/model             — 切换 AI 模型
/skills            — 管理技能扩展
/mcp               — 管理 MCP 服务器
/fleet             — 启用并行子代理
/allow-all         — 开放所有工具权限

# 分享
/share             — 导出 session 为 Markdown 或 GitHub Gist
```

---

## 参考

- [Copilot CLI 官方文档](https://docs.github.com/copilot/concepts/agents/about-copilot-cli)
- [GitHub Copilot 计划对比](https://github.com/features/copilot/plans)
- [VS Code Copilot 文档](https://code.visualstudio.com/docs/copilot/overview)
