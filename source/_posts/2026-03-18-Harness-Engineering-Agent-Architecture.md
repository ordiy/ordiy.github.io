---
title: Harness Engineering：Agent-First 时代的架构革命（OpenAI 实践总结）
date: 2026-03-18 03:55:00
categories: [AI_ML]
tags: [Harness Engineering, AI Agent, Architecture]
---

OpenAI 团队在 5 个月内实现了一个百万行代码的产品，且保持了 **“0 行人工代码”** 的约束。这种极端实验催生了 **Harness Engineering（挂载工程/马具工程）**。

本文深度解析 Harness Engineering 的核心理念及我们在 Watadot Studio 中的实战应用。

<!-- more -->

## 🏗️ 核心哲学：Humans steer, Agents execute

Harness 不是简单的 Prompt，而是为 Agent 量身定制的 **“确定性运行环境”**。它将 LLM 的不可预测性包裹在严谨的工程约束中。

## 🧠 Harness 的三大支柱

### 1. Context Engineering (上下文工程)
- **知识地图**：`AGENTS.md` 不再是百科全书，而是 Table of Contents。
- **可感知的环境**：将 Chrome DevTools、LogQL、PromQL 直接挂载给 Agent，让它具备自主观测能力。

### 2. Architectural Constraints (架构约束)
- **强制层级依赖**：`Types ➔ Config ➔ Repo ➔ Service ➔ UI`。
- **机械化执行**：通过自定义 Linter 和结构化测试，确保架构不发生漂移。

### 3. Garbage Collection (代码治理)
- **对抗熵增**：运行周期性 Agent 扫描文档不一致。
- **技术债实时偿还**：Agent 自动发起 PR 修复偏差，人类只需 Automerge。

## 🚀 Relocating Rigor（严谨性的转移）

工程师的严谨性（Rigor）不再体现在手写的每一行代码中，而是转移到了：
1. **环境设计** (Environment Design)
2. **意图定义** (Specifying Intent)
3. **反馈回路** (Feedback Loops)

## 💡 Watadot Studio 的实战反思

- **环境优先**：当 Agent 失败时，首要问句是：“我的 Harness 缺了什么？”
- **拥抱 Boring Tech**：Agent 在成熟、稳定的技术栈上表现更佳。

---
*Ref: [Martin Fowler - Harness Engineering](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html)*
