---
title: GitHub CLI (gh) 深度实战：脱离浏览器的开发者生存指南
date: 2026-03-18 06:40:00
categories: [DevOps]
tags: [GitHub, CLI, Productivity, Automation]
---

GitHub CLI (`gh`) 不仅仅是一个命令行工具，它是现代 **Harness Engineering** 的核心挂载点。通过 `gh`，我们可以将代码托管、协作评审和 CI/CD 监控完全集成进我们的自动化脚本和 AI Agent 流水线中。

本文总结了 `gh` 从基础到端到端复杂场景的核心技能。

<!-- more -->

## 🔐 1. 身份认证与配置 (Auth & Config)
*一切自动化的起点。*

- **交互式登录**：`gh auth login`
  - 建议选择 SSH 方式，并关联 GitHub 账号。
- **状态检查**：`gh auth status`
- **环境变量认证** (自动化脚本必备)：
  - `export GITHUB_TOKEN=your_token` (gh 会优先识别此变量)。
- **配置编辑器**：`gh config set editor "vim"`

## 📦 2. 仓库管理 (Repo Operations)
*从创建到克隆的高频操作。*

- **克隆仓库**：`gh repo clone <owner>/<repo>`
- **快速创建**：`gh repo create <name> --public --add-readme`
- **查看状态**：`gh repo view --web` (直接在浏览器打开当前仓库页面)。
- **Fork 仓库**：`gh repo fork <owner>/<repo> --clone`

## 🛠️ 3. 议题与拉取请求 (Issue & PR)
*端到端的协作核心。*

- **Issue 流程**：
  - 列出未结：`gh issue list --author "@me"`
  - 快速创建：`gh issue create --title "Bug: Login fails" --body "Detailed desc..."`
- **PR 流程** (硬核用法)：
  - **创建并直接提交**：`gh pr create --title "feat: new component" --body "Logic summary..."`
  - **本地检出 PR 代码**：`gh pr checkout <number>` (调试他人代码的神器)。
  - **快速合并**：`gh pr merge --squash --delete-branch`

## ⚡ 4. GitHub Actions (Run & Workflow)
*CI/CD 的终端监控站。*

- **查看运行日志**：`gh run list --limit 5`
- **实时监控流水线**：`gh run watch <run-id>`
- **手动触发工作流**：`gh workflow run <name_or_id>.yml`

## 🚀 5. 高级端到端场景

### **场景 A：全自动 PR 修复链 (Ralph Wiggum Loop)**
> 逻辑：检测失败 ➔ 检出 PR ➔ 修复代码 ➔ 提交 ➔ 重新运行。
```bash
gh pr checkout 123
# ... 执行本地修复脚本 ...
git commit -am "fix: resolve CI failure"
git push
gh workflow run deploy.yml # 手动重触发
```

### **场景 B：跨仓库资产同步 (Secret Management)**
> 逻辑：批量同步 API Key 到多个仓库。
```bash
gh secret set MY_API_KEY --body "$SECRET_VALUE" --repo <owner>/<repo>
```

---
*Ref: [GitHub CLI Manual](https://cli.github.com/manual/)*
