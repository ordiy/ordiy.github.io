---
title: 当 AI Agent自动化后，工程师的工作在往哪走？
date: 2026-04-16 10:30:00
tags:
  - AI Agents
  - Coding Agents
  - Harness Engineering
  - Software Engineering
  - Gemma
  - Aider
  - OpenCode
categories:
  - AI Engineering
---

# 当 AI Agent自动化后，工程师的工作在往哪走？

> 我们用同一个模型（gemma-4-31b-it）驱动了两套 AI 编码工具，让它们从零构建一个完整的 Streamlit 股票分析应用。测试结束后，我得出了一个让自己意外的结论——真正决定生产力的，不是模型，是 harness。

---

## 一、一次意外的实验

几天前，我做了一个对比实验：用相同的模型（Google Gemma-4-31B），分别驱动 **aider** 和 **opencode** 两套 AI 编码工具，完成五轮渐进式任务——从脚手架搭建、功能迭代，到 bug 修复，再到复杂数据计算。

任务对象是一个真实的 Python Web 项目：类似 [StockPeers](https://demo-stockpeers.streamlit.app) 的股票同伴分析仪表盘，包含归一化走势图、MA 均线叠加、相关性热力图、绩效汇总表。

结果如下：

| 轮次 | 任务 | aider 耗时 | opencode 耗时 | 备注 |
|---|---|---|---|---|
| R1 | 脚手架 | **129s** | 218s | aider 更快，但 opencode 代码更简洁 |
| R2 | 相关性热力图 | **167s** | 600s* | opencode 超时，但编辑已完成 |
| R3 | MA 均线叠加 | **165s** | 600s* | opencode 自动修复了自己的误删 |
| R4 | Bug 修复 | **135s** | 600s* | 两者都立即识别出错误根因 |
| R5 | 绩效汇总表 | 600s（失败）| 601s* | **aider 推理完成但未写文件，需人工干预** |

*超时但任务已完成，超时发生在编辑后的后处理阶段。

这个数据让我重新思考了一个问题：**我们在评估 AI 工具的时候，评估的到底是什么？**

---

## 二、生产力的真正来源：不是模型，是 harness

我的个人观察排序是：

> **AI Agent 生产力指数：claudeCode > opencode > gemini CLI > aider**

但这个排序不是在比模型能力。即便是最强的模型，套上一个糟糕的运行框架，生产力也会大打折扣。

OpenAI 的工程团队将这一层框架命名为 **harness engineering**（驾驭工程），Martin Fowler 给出了更清晰的定义：

> **Harness = 除了模型本身之外的一切。**  
> 它由两部分组成：  
> - **Guides（前馈控制）**：在模型生成之前约束行为——规则文件、架构模板、lint 规则、skill 体系  
> - **Sensors（反馈控制）**：在模型输出之后观察结果——测试、review agent、CI 流水线

这次实验里，同一个 gemma-4-31b-it 模型：
- 在 aider 的 harness 里，R5 任务推理完整但卡在工具调用上，无法自救
- 在 opencode 的 harness 里，R3 意外删除了代码块，但第三次 Edit 调用自动恢复了它

**相同大脑，不同骨架，行为天差地别。**

---

## 三、HITL：不是"人工审核"，是"战略性介入"

**HITL（Human-in-the-Loop）** 常被误解为"AI 干活，人来点击审批"。这是一种低效的理解。

真正有价值的 HITL 是一种**精准介入设计**：

```
AI 执行流程
    │
    ├─── [低风险操作] ──→ 自动通过（读文件、写临时变量）
    │
    ├─── [中等风险] ───→ Sensor 检测（测试、lint）→ 失败则 AI 自修复
    │
    └─── [高风险节点] ──→ HITL 暂停 → 人类判断 → 继续
              │
              ▼
         什么是高风险？
         - 需求理解的正确性
         - 架构边界的选择
         - 业务逻辑的合理性
         - 安全敏感的操作
```

这次实验里，我介入了两次：
1. R1 结束后，code review subagent 发现了可变列表作为缓存键的 bug，我决定修复（而不是忽略）
2. aider R5 超时后，我判断这是模型层的生成停滞，直接手动实现（而不是再等一轮）

这两次介入都不是"点击批准"，而是**需要判断的决策**。这就是真正的 HITL 价值。

---

## 四、范式迁移正在发生，但方向不是"工程师变轻松了"

这里我想提出一个反直觉的观点：

> **新范式下，工程师的工作量不一定减少，但工作的性质在改变。**

过去，实现代码是核心工作，需求可以模糊，设计可以边做边调。

现在，AI 接管了实现细节，但这不意味着上游工作变容易了——恰恰相反：

| 工作 | 旧范式 | 新范式 |
|---|---|---|
| 写实现代码 | 工程师主要工作 | AI 执行，工程师验证 |
| 需求表达 | 模糊 OK，工程师会补全 | **必须精确，是 harness 的输入** |
| 架构设计 | 细化到模块级 | **还需设计 agent 粒度和 harness 边界** |
| 验证逻辑 | 写 test case | **设计 acceptance criteria + sensor 触发策略** |

需求模糊在旧世界会导致 bug，需要几天时间在 code review 里发现。在新世界，同样的模糊需求会让 agent 在错误方向上高速推进，发现时已经跑偏了很远。

这不是"工程师变轻松了"，而是工作重心从后端（写实现）移到了前端（想清楚）。

---

## 五、真正的危机：验证赤字

有一个问题，没有人愿意直说：

> AI 生成代码的速度，正在超过人类理解和验证它的能力。

这是新范式下的结构性矛盾。OpenAI 的 harness engineering 报告里有一个数据点令人印象深刻：一个三人工程团队，在五个月内合并了约 1500 个 PR，代码量达到 100 万行——这些代码绝大多数由 AI 生成。

问题是：100 万行代码，谁来保证它是正确的？

**唯一可行的出路是：用 AI 验证 AI。**

这就是为什么"sensor 层 AI 化"是下一个关键工程方向——不是让人来 review 每一行，而是构建能够：
- 自动检测语义回归（而不只是语法错误）
- 识别业务逻辑违反
- 在高置信度时自动放行，低置信度时触发 HITL

的 review agent 体系。

---

## 六、未来工程师的核心技能

基于这个框架，我认为未来最有价值的工程师技能将是：

**1. Harness 设计能力**  
知道如何为 AI agent 设计有效的 guides 和 sensors。能写好 CLAUDE.md、设计 skill 体系、配置 CI 作为 sensor——这是一种新型的"基础设施即代码"。

**2. 精准规格能力**  
能够将模糊需求转化为足够精确的规格，让 agent 不需要猜测。这比写代码更难，因为它要求你提前想清楚所有边界条件。

**3. 战略性 HITL 判断**  
知道在哪个节点介入，介入时问什么问题，以及什么情况下可以信任 AI 自主完成。这是一种新的元技能，不是简单的"点击批准"。

**4. 验证策略设计**  
不是写 test case，而是设计测试策略——什么需要 unit test，什么需要 integration test，什么只需要 review agent 过一遍，什么必须人眼看。

---

## 七、结论：这是一场效率革命，但效率的分布是不均匀的

这次实验最直接的结论就是：**编码效率确实大幅提升了**。五轮任务，两套工具，从零到一个有五个功能模块的 Web 应用，总时间不超过一个工作日。这放在两年前，是一个完整 sprint 的工作量。说这是效率革命，数据支撑得住。

但效率的提升不是均匀的，这是我觉得最值得认真想一想的地方。

实现层加速了——写代码这件事，AI 比人快得多，而且在有清晰规格的情况下，质量也不差。

但设计层 and 验证层并没有同步加速，反而因为实现层太快，被放到了更突出的位置上：

- **设计**要更早、更精确。以前可以边写边想，现在规格模糊直接导致 agent 跑偏，返工成本更高。
- **验证**成了新瓶颈。代码生成速度超过了人理解它的速度，harness 里的 sensor 层——测试、review agent、CI——变得比以前更重要，而不是更轻松。

所以这场效率革命的实质，是**把工程师的时间从"怎么写"挤向了"写什么"和"写得对不对"**。这两件事本来就更难，只是过去被实现工作稀释了注意力。

生产力排序 `claudeCode > opencode > gemini > aider` 背后的逻辑也是这个：不是谁的模型更强，而是谁的 harness 在设计层和验证层给工程师提供了更好的结构——更清晰的介入点，更完善的 sensor，更少需要猜测的地方。

工程师的工作没有消失，重心在移动。

---

*本文基于 openclaw + aider/opencode + gemma-4-31b-it 的实测数据，完整 benchmark 报告见 [docs/benchmark/conclusion.md](../benchmark/conclusion.md)。*

## References

- [Harness engineering for coding agent users — Martin Fowler](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html)
- [Harness engineering: leveraging Codex in an agent-first world — OpenAI](https://openai.com/index/harness-engineering/)
