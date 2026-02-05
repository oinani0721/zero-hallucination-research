---
name: zhr-verify
description: |
  ⚠️ **已弃用** - 请使用 `/zhr-run` 替代（v5.0 合并版）

  零幻觉调研 - 验收阶段（独立会话架构）。
  执行 Phase 6-7：Ralph 迭代验收 + Graphiti 持久化。
  支持外部循环控制：每次迭代后输出 EXIT_SIGNAL。
  符合原始 Ralph 设计：独立上下文窗口 + 文件系统状态传递。

  > 此 skill 已被 `/zhr-run` 合并版替代。
  > `/zhr-run` 使用内部 Ralph Wiggum 循环，无需外部脚本。
  > 修复阶段支持 Subagent + /chrome。
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - AskUserQuestion
  - mcp__graphiti__*
---

# 零幻觉调研 - 验收阶段 (Phase 6-7)

> **架构**: 独立上下文窗口（符合原始 Ralph 设计）
> **外部循环控制**: 每次迭代输出 `EXIT_SIGNAL: true/false`
> **状态传递**: 通过 `.research/state.json` 文件系统

你是调研验收员，负责**执行单次 Ralph 验收迭代和 Graphiti 持久化**。

---

## 🏗️ 外部循环控制架构

```
┌─────────────────────────────────────────────────────────────────────┐
│  外部脚本 (ralph-zhr.bat/sh) 驱动循环                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  外部脚本:                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ while state.json.verify.exit_signal != "true":                  ││
│  │     claude "/zhr-verify"   # 独立会话                            ││
│  │     read state.json        # 检查 EXIT_SIGNAL                   ││
│  │     if iteration >= 5: break                                    ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  /zhr-verify (单次迭代):                                             │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ 1. 读取 state.json.verify.iteration                             ││
│  │ 2. 执行验收检查                                                  ││
│  │ 3. 计算 pass_rate                                               ││
│  │ 4. 如果 pass_rate >= 0.95:                                      ││
│  │       输出 "EXIT_SIGNAL: true"                                  ││
│  │       执行 Phase 7 Graphiti 持久化                              ││
│  │    否则:                                                        ││
│  │       输出 "EXIT_SIGNAL: false"                                 ││
│  │       生成修复计划                                               ││
│  │ 5. 更新 state.json                                              ││
│  │ 6. 结束会话                                                      ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ✅ 每次验收是独立会话，上下文从干净状态开始                           │
│  ✅ 循环由外部脚本控制，不依赖 AI 自律                                │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🚨 启动时状态检查（强制！）

**在执行任何操作之前，必须先检查状态文件！**

```python
# 1. 读取 state.json
state = read_json(".research/state.json")

# 2. 前置条件检查
if state.phase_status.execute != "completed":
    ERROR("执行阶段未完成！请先执行 /zhr-execute")
    EXIT

# 3. 读取迭代状态
iteration = state.verify.iteration
max_iterations = state.verify.max_iterations  # 默认 5

# 4. 检查是否已达到最大迭代
if iteration >= max_iterations:
    WARNING("已达到最大迭代次数，询问用户是否继续")
    # ... 询问用户逻辑
```

---

## 🎯 你的任务

执行 **单次** Ralph 验收迭代。
**根据验收结果输出 `EXIT_SIGNAL: true` 或 `EXIT_SIGNAL: false`。**
**如果通过，执行 Phase 7 Graphiti 持久化后结束。**
**如果未通过，生成修复计划后结束，等待外部脚本决定是否继续。**

---

## Phase 6: Ralph 迭代验收

### 6.1 Ralph 循环架构

```
┌─────────┐      ┌─────────┐      ┌─────────┐      ┌─────────┐
│  READ   │ ──→ │ EXECUTE │ ──→ │  TRACK  │ ──→ │EVALUATE │
│PROMPT.md│      │ 执行检查 │      │ 更新状态 │      │ 检查结果 │
└────┬────┘      └─────────┘      └─────────┘      └────┬────┘
     │                                                   │
     │                    ┌──────────────────────────────┘
     │                    │
     │                    ▼
     │           ┌─────────────────┐
     │           │ passes: true?   │
     │           └────────┬────────┘
     │                    │
     │         ┌──────────┴──────────┐
     │         ▼                     ▼
     │    ✅ COMPLETE           ❌ 继续迭代
     │                               │
     └───────────────────────────────┘
```

### 6.2 创建 PROMPT.md

如果不存在，创建 `.research/PROMPT.md`：
```markdown
# 调研验收循环指令

<!-- RALPH_STATUS -->
**Current Status**: RUNNING
**Iteration**: 1/5
**Last Updated**: [当前时间]
<!-- /RALPH_STATUS -->

## 验收标准检查清单

### 核心需求
[从 task_plan.md 复制验收标准]

### 信息质量
- [ ] 所有 [事实] 都有来源 URL
- [ ] 所有 [未验证] 都标注了原因
- [ ] 无未解决的 [冲突]

### 来源透明
- [ ] 用户指定来源 📌 全部使用
- [ ] AI 自主发现来源 🔍 已标明
```

### 6.3 验收检查逻辑

```
对于每个验收标准：
1. 读取 task_plan.md 中的验收标准
2. 读取 report.md 中的内容
3. 检查是否满足
4. 标记状态：
   - ✅ 满足
   - ⚠️ 部分满足
   - ❌ 未满足
```

### 6.4 生成修复计划

如果存在问题，创建 `.research/@fix_plan.md`：
```markdown
# 优先修复计划

## 🔴 关键问题（必须修复）

### 问题 1：[问题描述]
- **位置**：[文件:行号]
- **内容**：[具体内容]
- **修复策略**：[如何修复]

## 🟡 次要问题（建议修复）
- [ ] 问题描述

## ✅ 已修复问题
- [x] 问题描述（修复时间：HH:MM）
```

### 6.5 执行修复

对于 @fix_plan.md 中的每个问题：
1. 执行修复策略
2. 更新相关文件
3. 标记为 ✅ 已修复

### 6.6 单次迭代逻辑（外部循环控制）

**⚠️ 重要：本 skill 只执行单次迭代，循环由外部脚本控制！**

```python
# 1. 读取当前迭代状态
state = read_json(".research/state.json")
iteration = state.verify.iteration + 1  # 本次迭代编号

# 2. 执行验收检查
results = check_acceptance_criteria()

# 3. 计算通过率
pass_rate = results.passed / results.total

# 4. 根据结果决定 EXIT_SIGNAL
if pass_rate >= 0.95:
    exit_signal = True
    # 执行 Phase 7 Graphiti 持久化
    persist_to_graphiti()
else:
    exit_signal = False
    # 生成修复计划供下次迭代使用
    generate_fix_plan(results.failed)

# 5. 更新状态
update_state_json(iteration, pass_rate, exit_signal)

# 6. 输出 EXIT_SIGNAL 并结束会话
output_exit_signal(exit_signal)
```

### 6.7 更新状态 (v2.0 格式)

**更新 state.json：**
```json
{
  "current_phase": "verify",
  "phase_status": {
    "plan": "completed",
    "execute": "completed",
    "verify": "in_progress"
  },
  "verify": {
    "started_at": "YYYY-MM-DD HH:MM:SS",
    "completed_at": null,
    "iteration": 2,
    "max_iterations": 5,
    "pass_rate": 0.85,
    "exit_signal": false,
    "status": "in_progress",
    "checks": {
      "timeliness": {"passed": 5, "failed": 1, "total": 6},
      "completeness": {"passed": 4, "failed": 0, "total": 4},
      "accuracy": {"passed": 8, "failed": 2, "total": 10},
      "citation": {"passed": 3, "failed": 1, "total": 4}
    },
    "failed_items": ["准确性检查: 来源5 URL失效", "引用检查: 结论缺少内联引用"],
    "fixed_items": ["来源3 已重新验证"]
  },
  "session_history": [
    {"session_id": "plan-001", "phase": "plan", "...": "..."},
    {"session_id": "execute-001", "phase": "execute", "...": "..."},
    {"session_id": "verify-001", "phase": "verify", "iteration": 1, "pass_rate": 0.70},
    {"session_id": "verify-002", "phase": "verify", "iteration": 2, "pass_rate": 0.85}
  ],
  "last_updated": "YYYY-MM-DD HH:MM:SS"
}
```

---

## Phase 7: Graphiti 持久化

### 7.1 检查服务状态

```python
# 检查 Graphiti MCP 服务
mcp__graphiti__get_status()

# 如果返回错误，提示用户启动服务
```

### 7.2 存储已验证事实

**MUST 存储每个 ✅ 已验证的事实！**

```python
for fact in verified_facts:
    mcp__graphiti__add_memory(
        name=f"{topic} - {info_type}",
        episode_body=f"[事实] {content} (来源: {url}) [时间: {time}]",
        group_id="zero-hallucination-research",
        source="text",
        source_description="调研验证结果"
    )
```

### 7.3 存储结构化数据

对于课程等结构化信息：
```python
mcp__graphiti__add_memory(
    name="课程信息",
    episode_body='{"course": "MATH 54", "professor": "XXX", ...}',
    group_id="zero-hallucination-research",
    source="json",
    source_description="调研结果"
)
```

### 7.4 冲突自动处理

Graphiti 的 Bi-Temporal 模型会自动：
1. 检测与现有记录的冲突
2. 将旧记录标记 `expired_at`
3. 保留历史记录可追溯

### 7.5 更新状态

```json
{
  "phase": "completed",
  "completed_at": "YYYY-MM-DD HH:MM:SS",
  "graphiti": {
    "facts_stored": 15,
    "episodes_created": 3
  }
}
```

---

## ✅ 完成检查

单次验收迭代完成后，必须确认：
- [ ] 状态检查已通过（execute completed）
- [ ] 读取了当前迭代编号
- [ ] 执行了验收检查并计算 pass_rate
- [ ] 更新了 `state.json.verify` 状态
- [ ] 输出了正确的 EXIT_SIGNAL

---

## 📢 完成后输出（强制格式）

### 情况 A: 验收通过 (pass_rate >= 0.95)

**输出 EXIT_SIGNAL: true，执行 Phase 7 后结束：**

```
═══════════════════════════════════════════════════════════════════════
EXIT_SIGNAL: true
PHASE_COMPLETE: verify
═══════════════════════════════════════════════════════════════════════

✅ 调研完成！

Ralph 验收：通过
- 迭代次数: {N}
- 通过率: {X}%
- 检查项: {passed}/{total}

Graphiti 持久化：
- 存储事实: {Y} 条
- 创建 episodes: {Z} 个

最终报告：.research/report.md

状态文件检查点：
- verify.exit_signal: true
- verify.status: passed
- phase_status.verify: completed

═══════════════════════════════════════════════════════════════════════
所有已验证事实可通过 Graphiti 跨会话查询。
调研流程完成！
═══════════════════════════════════════════════════════════════════════
```

### 情况 B: 验收未通过 (pass_rate < 0.95)

**输出 EXIT_SIGNAL: false，生成修复计划后结束：**

```
═══════════════════════════════════════════════════════════════════════
EXIT_SIGNAL: false
═══════════════════════════════════════════════════════════════════════

⚠️ 验收迭代 {N} 完成，未达到通过标准

Ralph 验收：进行中
- 当前迭代: {N}/{max}
- 通过率: {X}% (目标: 95%)
- 检查项: {passed}/{total}

未通过检查项：
- [ ] {失败项1}
- [ ] {失败项2}

修复计划已生成：.research/@fix_plan.md

状态文件检查点：
- verify.exit_signal: false
- verify.iteration: {N}
- verify.pass_rate: {X}

═══════════════════════════════════════════════════════════════════════
下一步（由外部脚本自动执行或手动执行）：
  - 继续迭代: /zhr-verify
  - 或使用外部脚本: ralph-zhr.bat (Windows) / ralph-zhr.sh (Linux/Mac)
═══════════════════════════════════════════════════════════════════════
```

### 情况 C: 达到最大迭代

**询问用户是否继续：**

```
═══════════════════════════════════════════════════════════════════════
EXIT_SIGNAL: max_iterations_reached
═══════════════════════════════════════════════════════════════════════

⚠️ 已达到最大迭代次数

Ralph 验收：达到限制
- 迭代次数: {max}/{max}
- 最终通过率: {X}% (目标: 95%)
- 检查项: {passed}/{total}

未解决问题：
- [ ] {问题1}
- [ ] {问题2}

═══════════════════════════════════════════════════════════════════════
请选择：
A) 继续迭代（增加 3 次）
B) 接受当前结果并完成
C) 手动修复后重新验收
═══════════════════════════════════════════════════════════════════════
```

---

## 🛑 会话结束规则

**⛔ 输出 EXIT_SIGNAL 后，本会话必须结束！**

- **EXIT_SIGNAL: true** → Phase 7 完成后结束，调研流程完成
- **EXIT_SIGNAL: false** → 生成修复计划后结束，等待外部脚本或用户决定是否继续
- **EXIT_SIGNAL: max_iterations_reached** → 询问用户后结束

**原因**：保持独立上下文窗口，循环由外部脚本控制。

---

## 📋 验收检查清单（单次迭代）

本次迭代需确保：
- [ ] 所有 `[事实]` 有来源 URL
- [ ] 所有 `[未验证]` 标注原因
- [ ] 无未解决的 `[冲突]`
- [ ] 📌 来源全部使用
- [ ] 🔍 来源已标明
- [ ] 可信度等级已评估
- [ ] 报告正文有内联引用
- [ ] 来源审计表完整

**优先级顺序**（按 Ralph 要求）：
1. 🕐 时效性 - 信息是否在 7 天内？
2. 📋 完整性 - 所有教授都已调研？
3. ✅ 准确性 - URL 可访问？
4. 📚 引用规范 - 有内联引用？
