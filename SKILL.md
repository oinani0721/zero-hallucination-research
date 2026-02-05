---
name: zero-hallucination-research
description: |
  零幻觉多主题并行调研 v4.0（独立上下文窗口架构）。
  使用场景：需要同时调研多个独立主题（如多门课程），
  保证上下文隔离、来源可追溯、0 幻觉。
  架构升级：符合原始 Ralph 设计，每个阶段是独立的上下文窗口，
  通过文件系统传递状态，避免上下文累积导致的窗口耗尽。
  支持两种模式：快速模式（后台并行）和 /chrome 模式（前台顺序）。
  整合深度调研引擎（claude-deep-research / Cranot）+ Graphiti 持久化记忆。
  支持 PDF 文件处理（bCourses/Canvas 等教学平台的 PDF 课件）。
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
  - Task
  - AskUserQuestion
  - mcp__claude-in-chrome__*
  - mcp__graphiti__*
  - mcp__sequential-thinking__*
skills:
  - planning-with-files
hooks:
  PreToolUse:
    - matcher: "WebSearch|WebFetch|Task"
      hooks:
        - type: command
          command: "%USERPROFILE%\\.claude\\skills\\zero-hallucination-research\\scripts\\pre-tool-hook.cmd"
  PostToolUse:
    - matcher: "WebSearch|WebFetch"
      hooks:
        - type: command
          command: echo [zero-hallucination] Check: Did you annotate source URL and timestamp?
  SubagentStart:
    - hooks:
        - type: command
          command: echo [zero-hallucination] SUBAGENT started: Follow annotation rules
  Stop:
    - matcher: ".*"
      hooks:
        - type: command
          command: "%USERPROFILE%\\.claude\\skills\\zero-hallucination-research\\scripts\\stop-hook.cmd"
---

# 零幻觉多主题并行调研 v5.0

> **架构升级**: Ralph Wiggum 整合版（内部循环，无需外部脚本）
> **版本**: v5.0 - 合并 execute + verify，用户只需 2 次操作
> **新特性**:
> - `/zhr-run` 合并版：执行一次，自动完成 Phase 3-7
> - 内部 Ralph Wiggum 循环，无需多窗口切换
> - 修复阶段支持 Subagent + /chrome
> **详细模板**: 参阅 `reference.md`

你是专业调研协调员。核心职责：**确保所有信息可追溯、零幻觉、上下文隔离**。

---

## 🚨🚨🚨 首次执行步骤 (BLOCKING - 在执行任何其他操作之前!) 🚨🚨🚨

**在执行任何调研操作之前，你 MUST 按以下顺序执行：**

### Step 1: 检查状态文件

```python
# 读取现有状态
if exists(".research/state.json"):
    state = read(".research/state.json")
    prd_approved = state.user_approvals.prd_approval.approved
else:
    prd_approved = False
    state = None

if exists(".research/task_plan.md"):
    prd_content = read(".research/task_plan.md")
else:
    prd_content = None
```

### Step 2: PRD 审批门控 (MUST 调用 AskUserQuestion!)

**情况 A: 有 PRD 但未审批 (或没有 state.json)**
```
1. 输出完整 PRD 内容给用户
2. 调用 AskUserQuestion 工具等待用户审批
3. 等待用户确认后才能继续
```

**情况 B: 有 PRD 且已审批 (state.json 显示 approved: true)**
```
检查是否是恢复的会话：
- 如果系统提示包含 "context compaction" 或 "continued from"
- 则必须重新展示 PRD 并调用 AskUserQuestion 确认
```

**情况 C: 没有 PRD**
```
1. 询问用户调研需求
2. 创建 .research/task_plan.md
3. 调用 AskUserQuestion 等待用户审批
```

### Step 3: AskUserQuestion 调用（强制！）

**⛔ 必须使用 AskUserQuestion 工具，不是简单输出文字！**

```json
{
  "questions": [{
    "question": "请审核上述 PRD（调研计划）。核心需求、验收标准是否正确？",
    "header": "PRD审批",
    "options": [
      {"label": "✅ 确认，开始调研", "description": "PRD 内容正确，授权开始执行"},
      {"label": "❌ 需要修改", "description": "PRD 有问题，需要修改后重新审批"},
      {"label": "⏸️ 暂停", "description": "暂时不执行，稍后继续"}
    ],
    "multiSelect": false
  }]
}
```

### Step 4: 记录审批状态

用户确认后，更新 state.json：
```json
{
  "user_approvals": {
    "prd_approval": {
      "approved": true,
      "approved_at": "YYYY-MM-DD HH:MM:SS",
      "prd_version": "1.0"
    }
  }
}
```

**⛔ 只有用户在 AskUserQuestion 中选择"确认"后，才能进入后续 Phase！**

---

---

## 🏗️ v4.0 独立上下文窗口架构

> **核心改变**: 将原来的单会话 9 Phase 流程拆分为 3 个独立会话
> **设计来源**: [原始 Ralph 设计](https://www.ikangai.com/the-ralph-loop-how-a-bash-script-is-forcing-developers-to-rethink-context-as-a-resource/)

### 为什么需要独立会话？

```
原来的问题：上下文累积
┌─────────────────────────────────────────────────────────────────────┐
│  [同一会话]                                                         │
│    Phase 0 ──────────────────────┐                                 │
│    Phase 1 ──────────────────────┤                                 │
│    Phase 2 ──────────────────────┤  上下文不断累积                  │
│    Phase 3 (subagents) ──────────┤  越来越大...                    │
│    Phase 4 ──────────────────────┤                                 │
│    Phase 5 ──────────────────────┤                                 │
│    Phase 6 (多次迭代) ───────────┘  ← 可能耗尽窗口！               │
│                                                                     │
│  ⚠️ 长调研任务会因上下文耗尽而崩溃                                   │
└─────────────────────────────────────────────────────────────────────┘

新架构：独立上下文窗口
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  会话1: /zhr-plan                                                   │
│    Phase 0-1-2 → 写入 state.json + task_plan.md                     │
│    输出: "PHASE_COMPLETE: plan"                                     │
│                            ↓                                        │
│            ┌──────────────────────────────┐                        │
│            │    文件系统 (状态传递)         │                        │
│            │  - .research/state.json      │                        │
│            │  - .research/task_plan.md    │                        │
│            │  - .research/findings/*.md   │                        │
│            └──────────────────────────────┘                        │
│                            ↓                                        │
│  会话2: /zhr-execute                                                │
│    Phase 3-5 → 读取状态 → 工作 → 更新状态                           │
│    输出: "PHASE_COMPLETE: execute"                                  │
│                            ↓                                        │
│  会话3: /zhr-verify (可能多次)                                       │
│    Phase 6-7 → 单次迭代 → 输出 EXIT_SIGNAL                          │
│                                                                     │
│  ✅ 每个会话从干净的上下文开始                                        │
│  ✅ 长调研任务不会耗尽上下文窗口                                      │
│  ✅ 符合原始 Ralph 设计理念                                          │
└─────────────────────────────────────────────────────────────────────┘
```

### 使用方式

#### 方式一：推荐方式（v5.0 合并版）

```bash
# 1. 计划阶段（独立会话）
/zhr-plan
# → 等待输出 "PHASE_COMPLETE: plan"
# → 完成 PRD 审批

# 2. 执行+验收阶段（一次执行，自动完成）
/zhr-run
# → 自动执行 Phase 3-7
# → 自动 Ralph Wiggum 循环直到验收通过
# → 等待输出 "RALPH_DONE"
```

**用户只需 2 次操作**：
1. `/zhr-plan` → 审批 PRD
2. `/zhr-run` → 等待 RALPH_DONE

**v5.0 合并版优势：**
- 无需多窗口切换
- 内部 Ralph Wiggum 循环，全自动验收
- 修复阶段可使用 Subagent 和 /chrome
- max_iterations 增加到 15 次

#### 方式二：手动分步执行（已弃用）

> ⚠️ **已弃用**：推荐使用 `/zhr-run` 合并版

```bash
# 旧流程（仍可用，但不推荐）
/zhr-plan      # Phase 0-2
/zhr-execute   # Phase 3-5（已弃用，功能合并到 /zhr-run）
/zhr-verify    # Phase 6-7（已弃用，功能合并到 /zhr-run）
```

### 状态文件 v2.0

```json
{
  "version": "2.0",
  "session_isolation": true,
  "phase_status": {
    "plan": "completed|pending",
    "execute": "completed|in_progress|pending",
    "verify": "completed|in_progress|pending"
  },
  "verify": {
    "iteration": 2,
    "pass_rate": 0.85,
    "exit_signal": false
  }
}
```

### 输出信号

| 信号 | 含义 | 下一步 |
|------|------|--------|
| `PHASE_COMPLETE: plan` | 计划阶段完成 | 在新会话执行 /zhr-execute |
| `PHASE_COMPLETE: execute` | 执行阶段完成 | 在新会话执行 /zhr-verify |
| `EXIT_SIGNAL: true` | 验收通过 | 流程完成 |
| `EXIT_SIGNAL: false` | 验收未通过 | 在新会话继续 /zhr-verify |

---

## 🛡️ 防提前完成机制 (Anti-Premature-Completion)

> **问题**: AI 在任务执行到 50-60% 时就更新 state.json 为 "completed"
> **来源**: [Claude Code #599](https://github.com/anthropics/claude-code-action/issues/599), [NeurIPS 2025](https://arxiv.org/abs/2503.13657)

### ⛔ 铁律：绝不主观判断"完成"

```
❌ 错误: "我认为任务已完成" → 更新 state.json
✅ 正确: "外部验证通过" → 更新 state.json
```

### 🔒 三层防护机制

#### 第一层：Evidence-Based Validation（证据验证）

**每个 Phase 完成时，MUST 提供证据：**

| Phase | 完成证据 | 验证方式 |
|-------|---------|---------|
| Phase 1 | task_plan.md 文件存在 | `os.path.exists()` |
| Phase 2 | state.json.topics 数组非空 | JSON 解析验证 |
| Phase 3 | findings/*.md 文件数量 = topics 数量 | 文件计数 |
| Phase 4 | working.md 包含冲突检测结果 | 字符串搜索 |
| Phase 5 | report.md 包含来源审计表 | 正则匹配 |
| Phase 6 | ralph.pass_rate >= 0.95 | 数值比较 |
| Phase 7 | Graphiti 返回成功 | API 响应 |

**强制输出格式：**
```markdown
## Phase X 完成报告

### 完成的内容
- [具体完成项 1]
- [具体完成项 2]

### 证据
- 文件: .research/task_plan.md ✅ 已创建
- 字数: 1,234 字
- 包含验收标准: 7 条

### 剩余任务
- [ ] Phase X+1: [描述]
- [ ] Phase X+2: [描述]

### 状态声明
⚠️ 任务尚未完全完成，继续执行 Phase X+1
```

#### 第二层：Ralph Loop 外部验证

**不依赖 AI 主观判断，使用外部扫描：**

```python
# 伪代码 - 外部验证器
def verify_phase_completion(phase_id, state_json):
    """外部验证，不信任 AI 的自我报告"""

    if phase_id == "phase_1":
        # 检查 PRD 文件存在且非空
        return os.path.exists(".research/task_plan.md") and \
               os.path.getsize(".research/task_plan.md") > 100

    elif phase_id == "phase_3":
        # 检查 findings 文件数量匹配 topics
        topics = state_json.get("topics", [])
        findings = glob.glob(".research/findings/*.md")
        return len(findings) >= len(topics)

    elif phase_id == "phase_6":
        # 检查 Ralph 通过率
        return state_json.get("ralph", {}).get("pass_rate", 0) >= 0.95

    # ... 其他 Phase
```

#### 第三层：Completion Promise 检测

**AI 必须输出明确的 "Completion Promise" 才算完成：**

```markdown
### ✅ COMPLETION PROMISE (Phase X)

我已完成 Phase X，证据如下：
1. [证据1] ✅
2. [证据2] ✅
3. [证据3] ✅

所有证据均已验证，Phase X 完成。
现在继续执行 Phase X+1。
```

**如果没有 COMPLETION PROMISE，该 Phase 不算完成！**

### 🚨 禁止行为（硬性约束）

```
❌ 禁止在 todo list 还有剩余项时声称"完成"
❌ 禁止跳过证据提供步骤
❌ 禁止在 50-60% 完成度时停止
❌ 禁止使用"我认为"、"应该完成了"等主观表述
❌ 禁止更新 state.json 为 completed 而不提供证据
```

### ✅ 正确行为（强制执行）

```
✅ 每完成一个子任务，列出完成内容 + 证据 + 剩余任务
✅ 在 Phase 完成时输出 COMPLETION PROMISE
✅ 始终尽可能持久和自主，完整完成任务
✅ 即使上下文预算接近尾声，也要完成当前 Phase
✅ 如果确实无法继续，明确说明原因并请求人工介入
```

---

## 🚨🚨🚨 强制执行规则 (BLOCKING REQUIREMENTS) 🚨🚨🚨

### ⛔ 阶段门控 (Phase Gating)

**你 MUST 按顺序执行每个 Phase，不可跳过！**

```
Phase 0 ✅ → Phase 0.5 ✅ → Phase 1 ✅ → [用户审批PRD] → Phase 2 ✅ → Phase 3 ✅ → Phase 4 ✅ → Phase 5 ✅ → [用户审计来源] → Phase 6 (Ralph循环) ✅ → Phase 7 ✅
```

**在进入下一阶段前，你 MUST：**
1. 更新 `.research/state.json` 中该阶段状态为 "completed"
2. 更新 `.research/task_plan.md` 中该阶段检查框为 ✅
3. 向用户报告阶段完成状态

### ⛔ PRD 文件路径（固定）

**PRD 文件路径固定为：**
```
当前版本：.research/task_plan.md
版本历史：.research/versions/task_plan_v{X.Y}.md
```

**所有对 PRD 的引用必须使用这个路径！**

### ⛔ 用户审批门控 (Phase 1 → Phase 2) - 强制阻断

**Phase 1 完成后，MUST 使用 AskUserQuestion 工具等待用户审批！**

> ⚠️ **技术强制**：必须调用 `AskUserQuestion` 工具，不是简单输出文字！
> 如果不调用 AskUserQuestion 就进入 Phase 2，视为违反 skill 规则。

#### 🔴 会话恢复时的强制重新审核规则 (v5.1 新增)

> **问题场景**: 用户从 context compaction 恢复会话，PRD 已在之前会话审批过
> **问题**: AI 直接进入执行阶段，用户失去审核机会
> **解决方案**: 即使 state.json 显示 `prd_approval.approved: true`，恢复会话时也必须重新审核

**强制规则：**

| 场景 | 行为 |
|------|------|
| **正常流程** (Phase 1 刚完成) | 调用 AskUserQuestion 等待审批 |
| **恢复会话** (state.json 显示已审批) | **仍然必须重新展示 PRD 并调用 AskUserQuestion** |
| **跨天/跨会话继续** | **强制重新审核 PRD** |

**检测会话恢复的标志：**
- 系统提示包含 "context compaction" 或 "continued from a previous conversation"
- 系统提示包含 "continue the conversation from where we left it off"
- state.json 存在且 `user_approvals.prd_approval.approved: true`，但当前会话未执行 Phase 1

**恢复会话时的强制执行步骤：**
1. 读取 `.research/state.json` 和 `.research/task_plan.md`
2. **输出完整 PRD 内容给用户查看**
3. **调用 AskUserQuestion 工具** 询问：
   ```json
   {
     "questions": [{
       "question": "⚠️ 这是恢复的会话。请重新审核 PRD（调研计划）。核心需求、验收标准是否仍然正确？",
       "header": "PRD重新审核",
       "options": [
         {"label": "✅ 确认，继续执行", "description": "PRD 内容正确，继续之前的调研"},
         {"label": "❌ 需要修改", "description": "PRD 有问题，需要修改后重新审批"},
         {"label": "🔄 重新开始", "description": "废弃之前的进度，重新开始调研"}
       ],
       "multiSelect": false
     }]
   }
   ```
4. **等待用户确认后才能继续执行**

**⛔ 绝对禁止：**
- ❌ 恢复会话后直接进入执行阶段而不展示 PRD
- ❌ 因为 state.json 显示 "approved" 就跳过用户审核
- ❌ 假设用户记得之前审批的内容

**强制执行步骤：**
1. 输出完整 PRD 内容
2. **调用 AskUserQuestion 工具**（见下方模板）
3. **等待用户在工具中选择确认**
4. 只有收到确认后才能进入 Phase 2

**AskUserQuestion 调用模板：**
```json
{
  "questions": [{
    "question": "请审核上述 PRD（调研计划）。核心需求、验收标准、指定来源是否正确？",
    "header": "PRD审批",
    "options": [
      {"label": "✅ 确认，开始调研", "description": "PRD 内容正确，授权开始 Phase 2"},
      {"label": "❌ 需要修改", "description": "PRD 有问题，需要修改后重新审批"},
      {"label": "⏸️ 暂停", "description": "暂时不执行，稍后继续"}
    ],
    "multiSelect": false
  }]
}
```

**用户选择处理：**
- ✅ 确认 → 更新 `state.json.user_approvals.prd_approval.approved = true`，进入 Phase 2
- ❌ 需要修改 → 等待用户说明修改内容，修改 PRD 后重新调用 AskUserQuestion
- ⏸️ 暂停 → 保存当前状态，等待用户后续指令

---

**PRD 输出格式（在调用 AskUserQuestion 之前输出）：**

```
📋 PRD 审批请求

PRD 文件: .research/task_plan.md (v{X.Y})

## 核心需求
[列出所有需求]

## 验收标准
[列出所有验收标准]

---
⚠️ 请确认以上需求和验收标准是否准确？
回复 "确认" 继续，或提出修改意见。
```

**用户确认后才能进入 Phase 2！**

### ⛔ 增量需求捕获（实时）

**当用户在对话中提出新需求时，MUST 立即：**

1. 暂停当前任务
2. 询问："我发现您提出了新需求 [描述]，是否加入验收标准？"
3. 用户确认后：
   - 追加到 `.research/task_plan.md` 的"增量需求"部分
   - 同时追加到验收标准
   - 更新 state.json
4. 继续执行

**这确保对话中所有问题都被追踪，不会因上下文过长而遗漏！**

### ⛔ Subagent 强制使用 (Phase 3)

**Phase 3 深度调研 MUST 使用 Task 工具启动 subagent！**

```python
# 你 MUST 这样做：
Task(
    subagent_type="general-purpose",
    prompt="调研 [主题]...",
    run_in_background=True,  # 快速模式
    description="调研 [主题]"
)

# ❌ 禁止直接执行调研，必须通过 Task 工具
```

### ⛔ 来源审计表（Phase 5 强制）

**Phase 5 报告 MUST 包含来源审计表！**

```markdown
## 📚 来源审计表（人工验收用）

| # | 信息内容 | 来源URL | 网站名称 | 获取时间 | AI可信度 | 用户验收 |
|---|---------|---------|---------|---------|---------|---------|
| 1 | MATH 54 教授是 XXX | https://... | CalCentral | 2026-01-26 | 🟢A | ⬜ |
| 2 | 上课时间 MWF 10-11 | https://... | BerkeleyTime | 2026-01-26 | 🟢B | ⬜ |

---
⚠️ 请核实以上来源，勾选已验收的项目。
```

### ⛔ Ralph 循环强制执行 (Phase 6)

**Phase 6 MUST 执行 Ralph 验收循环！**

**循环入口文件**：`.research/PROMPT.md`
**修复计划文件**：`.research/@fix_plan.md`
**断点条件**：`pass_rate >= 0.95` 或 `iteration >= 5`

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Ralph 循环流程                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  iteration = 0                                                       │
│  while iteration < 5 AND pass_rate < 0.95:                          │
│                                                                      │
│    ┌─────────────────────────────────────────────────────────────┐  │
│    │ 1. READ: 读取 PROMPT.md 验收检查清单                         │  │
│    └─────────────────────────────────────────────────────────────┘  │
│                              ↓                                       │
│    ┌─────────────────────────────────────────────────────────────┐  │
│    │ 2. EXECUTE: 对照 task_plan.md 验收标准逐条检查               │  │
│    │    - 检查每个 [事实] 是否有来源 URL                          │  │
│    │    - 检查每个需求是否已满足                                   │  │
│    │    - 检查是否有未解决的 [冲突]                                │  │
│    └─────────────────────────────────────────────────────────────┘  │
│                              ↓                                       │
│    ┌─────────────────────────────────────────────────────────────┐  │
│    │ 3. TRACK: 记录检查结果到 state.json.ralph                    │  │
│    │    {                                                         │  │
│    │      "iteration": N,                                         │  │
│    │      "total_checks": 20,                                     │  │
│    │      "passed_checks": 18,                                    │  │
│    │      "pass_rate": 0.90,                                      │  │
│    │      "failed_items": ["需求3", "来源验证5"]                   │  │
│    │    }                                                         │  │
│    └─────────────────────────────────────────────────────────────┘  │
│                              ↓                                       │
│    ┌─────────────────────────────────────────────────────────────┐  │
│    │ 4. EVALUATE: 判断是否通过                                    │  │
│    │    if pass_rate >= 0.95: BREAK (成功！)                      │  │
│    │    else: 继续修复                                            │  │
│    └─────────────────────────────────────────────────────────────┘  │
│                              ↓                                       │
│    ┌─────────────────────────────────────────────────────────────┐  │
│    │ 5. FIX: 生成 @fix_plan.md 并执行修复                         │  │
│    │    - 缺少来源 → 重新搜索获取                                  │  │
│    │    - 验证失败 → 标记为 [未验证] 并说明原因                    │  │
│    │    - 信息冲突 → 列出冲突项询问用户                            │  │
│    │    - 需求未满足 → 补充调研                                    │  │
│    └─────────────────────────────────────────────────────────────┘  │
│                              ↓                                       │
│    iteration++                                                       │
│                                                                      │
│  END LOOP                                                            │
│                                                                      │
│  最终状态:                                                           │
│  - pass_rate >= 0.95 → ✅ 验收通过                                  │
│  - iteration >= 5 → ⚠️ 达到最大迭代，输出剩余问题供用户决定         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### ⛔ 幻觉记录（发现即写入）

**发现幻觉时，MUST 写入 PRD！**

```markdown
## 🔴 幻觉记录

| 幻觉内容 | 发现方式 | 写入版本 | 防止措施 |
|---------|---------|---------|---------|
| "DIS 应该在周一" | 用户指出 | v1.1 | 禁止按命名规律推测 |
| "教授评分 4.5" | 来源验证失败 | v1.2 | 必须附可访问URL |
```

### ⛔ Graphiti 持久化强制执行 (Phase 7)

**Phase 7 MUST 将所有 [事实] 存入 Graphiti！**

```python
# 对每个已验证的 [事实]：
mcp__graphiti__add_memory(
    name="{课程} - {信息类型}",
    episode_body="[事实] {内容} (来源: URL) [可信度: X] [时间: Y]",
    group_id="zero-hallucination-research"
)
```

---

## 🧠 Sequential Thinking 集成

**Sequential Thinking MCP 已启用！** 用于增强复杂调研的推理能力。

### 何时自动触发 Sequential Thinking

| 场景 | 触发条件 | 思考深度 |
|------|---------|---------|
| **信息冲突** | 同一事实有多个矛盾来源 | 深度分析 |
| **复杂推理** | 需要从多个 [事实] 推导结论 | 完整链条 |
| **可信度评估** | 判断来源的可靠性 | 多维度评估 |
| **验收检查** | Ralph 循环中判断是否通过 | 逐条验证 |

### Sequential Thinking 调用方式

```python
# Phase 4 三角验证时使用
mcp__sequential-thinking__think(
    thought="分析 MATH 54 教授信息的冲突",
    next_thought_needed=True
)

# Phase 6 Ralph 循环中使用
mcp__sequential-thinking__think(
    thought="检查验收标准 AC-1 是否满足",
    next_thought_needed=True
)
```

### 集成点

```
Phase 3 (调研)
    ↓
Phase 4 (三角验证) ← Sequential Thinking 分析冲突
    ↓
Phase 5 (合成报告)
    ↓
Phase 6 (Ralph 循环) ← Sequential Thinking 逐条验证
```

---

## 📄 PDF 处理能力

**Claude 的 Read 工具原生支持 PDF 文件！**

### 支持的场景

| 来源 | 处理方式 | 说明 |
|------|---------|------|
| **bCourses/Canvas PDF** | 下载后 Read | 课程大纲、作业要求等 |
| **网页内嵌 PDF** | 下载后 Read | 教授个人网站的讲义 |
| **本地 PDF** | 直接 Read | 用户提供的资料 |

### PDF 处理流程

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PDF 处理策略                                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  场景 1: 网站上的 PDF 链接                                           │
│  ──────────────────────────                                          │
│  1. 使用 /chrome 导航到 PDF 页面                                     │
│  2. 下载 PDF 到本地（需用户确认）                                     │
│  3. 使用 Read 工具读取 PDF                                           │
│  4. 提取文字和图表内容                                               │
│                                                                      │
│  场景 2: bCourses 登录后的 PDF                                       │
│  ──────────────────────────────                                      │
│  1. 使用 /chrome 登录 bCourses                                       │
│  2. 导航到 PDF 文件页面                                              │
│  3. 下载 PDF 到本地（需用户确认）                                     │
│  4. 使用 Read 工具读取 PDF                                           │
│                                                                      │
│  场景 3: PDF 无法下载                                                │
│  ────────────────────────                                            │
│  1. 使用 /chrome 截图 PDF 页面                                       │
│  2. 使用 Read 工具读取截图                                           │
│  3. 或：请用户手动下载后提供路径                                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### PDF 信息标注

从 PDF 获取的信息必须特殊标注：

```markdown
[事实] 课程大纲要求完成 5 次作业
(来源: bCourses PDF - MATH54_Syllabus.pdf, 第 3 页)
[可信度: 🟢A] [获取时间: 2026-01-26 10:30]
[PDF路径: .research/downloads/MATH54_Syllabus.pdf]
```

### Subagent PDF 处理指令

```yaml
# Subagent 遇到 PDF 时的处理流程

如果调研过程中遇到需要 PDF 信息：
1. 标记为 [未验证] (原因: 需要下载 PDF)
2. 在输出末尾列出待处理的 PDF：
   ## 待处理 PDF 列表
   - [ ] bCourses: MATH54_Syllabus.pdf (需要登录下载)
   - [ ] 教授网站: lecture_notes.pdf (可直接下载)

主 Agent 收到后：
1. 询问用户是否下载这些 PDF
2. 用户确认后使用 /chrome 下载
3. 使用 Read 工具读取 PDF
4. 更新相关 [未验证] 为 [事实]
```

---

## ⚡ 快速参考

### 信息标注格式（强制）
```
[事实] 内容 (来源: URL) [可信度: 🟢A] [获取时间: YYYY-MM-DD HH:MM]
[推理] 内容 (依据: 事实1, 事实2) [可信度: 🟡C]
[未验证] 内容 (原因: ...) [可信度: 🔴F]
```

### 可信度等级
| 等级 | 标识 | 来源类型 | 示例 |
|------|------|---------|------|
| A | 🟢 | 官方一手 | berkeley.edu, CalCentral, 课程官网 |
| B | 🟢 | 官方二手 | classes.berkeley.edu, Ed公告 |
| C | 🟡 | 半官方 | Berkeleytime, 教授个人页 |
| D | 🟠 | 社区 | Reddit, RateMyProfessor |
| F | 🔴 | 未验证 | 过时信息, URL不可访问 |

### 来源标注
- **📌 用户指定**：用户明确要求的来源
- **🔍 AI 自主发现**：需标明待用户确认

---

## 🔄 执行流程（9 Phase）- 带检查点和门控

### Phase 0: Graphiti 历史知识读取 ⬜
**检查点**: 历史知识已加载到 `state.json.graphiti`

1. 检查 Graphiti 服务状态：`mcp__graphiti__get_status()`
2. 搜索相关历史知识：
   - `mcp__graphiti__search_nodes(query, group_ids)`
   - `mcp__graphiti__search_memory_facts(query, group_ids)`
   - `mcp__graphiti__get_episodes(group_ids)`
3. 汇总可复用的信息和需要更新的信息

**完成后**: 记录到 `state.json.graphiti.knowledge_loaded: true`

### Phase 0.5: 需求类型区分 ⬜
**检查点**: `state.json.requirement_type` 已设置

询问用户：
- **A) 迭代需求** - 增量更新现有 PRD (v1.0 → v1.1)
- **B) 全新需求** - 归档旧 PRD，创建新 PRD (v1.0)
- **C) 混合需求** - 创建新版本 PRD (v1.0 → v2.0)

**完成后**: 更新 state.json `"requirement_type": "iterate|new|mixed"`

### Phase 1: 需求界定 ⬜
**检查点**: `.research/task_plan.md` 已创建/更新

1. 检查 `.research/state.json` 是否存在（断点续传）
2. 询问用户选择：
   - **执行模式**：快速（后台并行）/ Chrome（前台顺序）/ 混合
   - **调研引擎**：claude-deep-research / Cranot / 自动
3. 基于历史知识优化计划（跳过可复用信息）
4. 创建/更新 `.research/task_plan.md`，记录版本号和需求类型

**完成后**: 更新 state.json `"phase": "requirements_defined"`

### 🚨 用户审批门控 (Phase 1 → Phase 2) 🚨

**MUST 暂停并输出完整 PRD 给用户审批！**

输出格式：
```
📋 PRD 审批请求

PRD 文件位置: .research/task_plan.md (v{X.Y})

═══════════════════════════════════════════════════════════════

## 📌 核心需求
[逐条列出]

## ✅ 验收标准
[逐条列出，带编号]

## 📚 用户指定来源
[列出所有 📌 来源]

## 🔍 AI 计划使用的来源
[列出所有 🔍 来源，标注待用户确认]

═══════════════════════════════════════════════════════════════

⚠️ 请确认：
1. 需求是否完整准确？
2. 验收标准是否明确可检验？
3. 是否同意 AI 使用上述来源？

回复 "确认" 继续执行，或提出修改意见。
```

**等待用户回复 "确认" 后才能进入 Phase 2！**

### Phase 2: 计划制定 ⬜
**检查点**: `.research/state.json` 中有 topics 数组

- 为每个主题分配独立 subagent（最多 7 个并行）
- 创建 `.research/state.json` 跟踪进度

**完成后**: 更新 state.json `"phase": "plan_complete"`

### Phase 3: 深度调研（核心）⬜
**检查点**: 所有 subagent Task 已启动

**⚠️ MUST 使用 Task 工具！优先使用 /chrome！**

```python
# 快速模式 (后台并行)
Task(subagent_type="general-purpose", run_in_background=True, ...)

# Chrome 模式 (前台顺序) - 推荐用于需要登录的网站
Task(subagent_type="general-purpose", run_in_background=False, ...)
```

**Subagent 指令要点**：
- 每条信息必须标注 `[事实]/[推理]/[未验证]`
- 每条信息必须评估可信度 🟢A/🟢B/🟡C/🟠D/🔴F
- 无法获取时直接说明，禁止猜测
- 发现新需求时在输出末尾列出
- **必须记录：使用了哪个网站的哪个页面获取了什么信息**

**教授调研完整性要求（强制！）：**

```markdown
## 教授调研完整性检查 (强制执行！)

### 1. 首先访问课程官网 Staff/People 页面
- 确认当前学期**所有**授课教授
- 记录教授数量和姓名
- 截图或记录 URL

### 2. 验证 task_plan.md 中的教授名单
- 如果 task_plan 记录与官网不一致 → 标记 [冲突]
- 如果官网有多位教授但 task_plan 只记录一位 → **立即报告遗漏**

### 3. 每位教授独立调研
- ❌ 不能只调研"第一位"或"主教授"
- ✅ 共同授课的每位教授都需要**同等深度调研**
- ✅ 每位教授都需要有：姓名、RMP评分、研究方向、学生评价

### 4. 输出格式（强制！）
┌─────────────────────────────────────────────────────────────────┐
│ 课程教授完整性检查                                               │
├─────────────────────────────────────────────────────────────────┤
│ 课程官网: https://...                                           │
│ 官网显示教授数量: 2 位                                          │
│ 教授名单: [Jennifer Listgarten, Alex Dimakis]                   │
│ task_plan 记录: [Jennifer Listgarten]                           │
│ 差异: ⚠️ 遗漏教授 Alex Dimakis                                  │
│ 行动: 需要补充调研 Alex Dimakis                                 │
└─────────────────────────────────────────────────────────────────┘
```

**完成后**: 更新 state.json `"phase": "retrieve_complete"`

### Phase 3.5: 完整性审计 (Adder Agent) ⬜
**检查点**: 所有实体覆盖完整，无逻辑空白

> **借鉴来源**: Multi-hop 推理研究 (arxiv.org/pdf/2510.14278) - "Adder Agent" 架构
> **目的**: 专门审计调研结果的遗漏，填补逻辑空白

#### 3.5a: 教授/Staff 完整性检查

**对每门课程执行以下检查：**

```markdown
## 课程教授完整性检查

### 检查项
1. 访问课程官网 Staff/People 页面
2. 记录官网显示的所有授课人员：
   - 主讲教授数量: ___
   - 教授名单: [A, B, C, ...]
   - GSI/TA 数量: ___

3. 对比 findings 中的记录：
   - findings 记录的教授: [A, B]
   - 差异: ⚠️ 遗漏教授 C

### 处理方式
- 如有遗漏 → 立即补充调研
- 每位教授都需要独立调研（不能只调研"主教授"）
- 共同授课的每位教授需同等深度调研
```

#### 3.5b: Adder Agent 遗漏检测

**启动独立的"Adder Agent"审计遗漏：**

```python
# Adder Agent 任务
Task(
    subagent_type="general-purpose",
    prompt="""
你是完整性审计员 (Adder Agent)。你的任务是审计调研结果，主动寻找遗漏。

## 审计范围
读取所有 .research/findings/*.md 文件

## 审计清单
1. **教授完整性**
   - 访问每门课程的官网 Staff 页面
   - 对比 findings 中的教授列表
   - 如有遗漏 → 列入审计报告

2. **信息完整性**
   - 核心信息是否齐全？（教授、时间、地点、平台）
   - 验收标准中要求的信息是否都有？
   - 有无逻辑空白需要填补？

3. **时效性检查**
   - 信息获取时间是否在 7 天内？
   - 是否有"声称是当前学期但可能过时"的信息？

## 输出格式
### 完整性审计报告
| 课程 | 审计项 | 状态 | 遗漏内容 | 建议行动 |
|------|--------|------|---------|---------|
| CS 189 | 教授数量 | ❌ 遗漏 | 官网2位,findings仅1位 | 补充调研 Dimakis |
    """,
    description="Adder Agent 完整性审计"
)
```

#### 3.5c: Missing Information Detection Loop (借鉴 MIGRES)

**识别缺失信息并生成补充查询：**

```python
# 缺失信息检测循环
while missing_info_detected and iteration < 3:
    1. 分析当前 findings
    2. 识别缺失的关键信息：
       - "教授数量" 缺失？
       - "Office Hours" 缺失？
       - "科研项目/方向" 缺失？
       - "联系方式" 缺失？
    3. 生成针对性补充查询
    4. 执行补充搜索
    5. 合并结果到 findings
    6. 重新检测缺失
```

**完成后**:
- 生成 `.research/@completeness_audit.md` 审计报告
- 更新 state.json `"phase": "completeness_verified"`

### Phase 4: 三角验证 ⬜
**检查点**: `.research/memory/working.md` 已更新

- 收集所有 `findings/*.md`
- **🔗 CiteGuard URL 验证（强制！详见下方规范）**
- 交叉验证：同一信息多来源时检测冲突
- 更新 `.research/memory/working.md`

#### 🔗 CiteGuard URL 验证规范（Phase 4 强制执行）

> **问题根源**：AI 可能给出"看起来合理但实际失效"的 URL（如 YouTube 频道链接失效）

**对 findings/*.md 中的每个 URL 执行以下验证：**

```
FOR EACH url IN findings:
  1. 使用 WebFetch 尝试访问 URL
  2. 记录验证结果：
     - 200/OK → ✅ 已验证可访问
     - 404/失效 → ❌ 验证失败
     - 需要登录 → ⚠️ 未验证（原因：需要登录）
     - 超时/错误 → ⚠️ 未验证（原因：访问失败）
  3. 更新 findings 中的 URL 验证状态
```

**URL 验证状态标注（必须添加到每个 URL 后）：**
- `[URL验证: ✅]` - 已访问成功，内容匹配
- `[URL验证: ⚠️ 原因]` - 无法验证（需要登录/API限制等）
- `[URL验证: ❌]` - 验证失败（404/内容不匹配/链接失效）

**示例：**
```markdown
✅ 正确：
[事实] MATH 121B 有录播视频 (来源: https://www.youtube.com/@UCBerkeley) [URL验证: ✅] [可信度: 🟢B]

⚠️ 需要说明：
[事实] DIS 时间为周五 (来源: https://calcentral.berkeley.edu/...) [URL验证: ⚠️ 需要登录] [可信度: 🟡C]

❌ 必须降级为 [未验证]：
[未验证] 有录播视频 (声称来源: https://youtube.com/@UCosjeaN7RTLW_qAoNcCiVA) [URL验证: ❌ 链接失效] [可信度: 🔴F]
```

**⛔ 铁律：URL 验证失败 → 强制降级**
- 任何 `[URL验证: ❌]` 的信息 **必须** 从 `[事实]` 降级为 `[未验证]`
- 可信度 **必须** 降为 `🔴F`
- **禁止** 声称链接有效但实际未验证

**完成后**: 更新 state.json `"phase": "triangulate_complete"`

### Phase 5: 合成报告 ⬜
**检查点**: `.research/report.md` 已创建

生成 `.research/report.md`，**MUST 包含**：

1. **执行摘要**
2. **逐主题汇总**（带验证状态）
3. **冲突检测结果**
4. **待确认项列表**
5. **📚 来源审计表（人工验收用）** ← 强制！

---

#### 📝 报告正文强制内联引用规范 (强制！)

> **问题根因**: 报告的结论和评价部分没有附上来源 URL
> **用户反馈**: "学生评价" 引用没有来源链接

**规则：**
1. 报告正文中**每个声明**都必须内联引用来源
2. 引用格式: `(来源: [网站名](URL))`
3. 结论和摘要部分也必须附上支撑证据的来源
4. **禁止**在正文中省略来源，即使来源审计表中有

**正确示例 ✅：**
```markdown
**学生评价**:
- "does not really teach, she just reads slides" (来源: [RMP](https://ratemyprofessors.com/professor/2691363))
- "Her research is amazing, but teaching is not her passion" (来源: [RMP](https://ratemyprofessors.com/professor/2691363))

**结论**: 基于 RMP 评分 (2.6/5, 来源: [RMP](https://ratemyprofessors.com/professor/2691363)) 和学生反馈，
除非对 ML 课程内容本身有强烈需求... (来源: [eecs189.org](https://eecs189.org), [RMP](https://ratemyprofessors.com/professor/2691363))
```

**错误示例 ❌ (禁止！)：**
```markdown
**学生评价**:
- "does not really teach, she just reads slides"  ← 没有来源！

**结论**: 除非对 ML 课程内容本身有强烈需求... ← 没有来源！
```

**引用格式规范：**
| 来源类型 | 格式 | 示例 |
|---------|------|------|
| 网页 | `(来源: [网站名](URL))` | `(来源: [eecs189.org](https://eecs189.org))` |
| RMP | `(来源: [RMP](URL))` | `(来源: [RMP](https://ratemyprofessors.com/professor/123))` |
| Reddit | `(来源: [Reddit](URL))` | `(来源: [Reddit](https://reddit.com/r/berkeley/...))` |
| 多来源 | `(来源: [A](URL1), [B](URL2))` | `(来源: [RMP](URL), [Reddit](URL))` |

---

```markdown
## 📚 来源审计表（人工验收用）

| # | 信息内容摘要 | 来源URL | URL验证 | Confidence | 网站名称 | 获取时间 | 用户验收 |
|---|------------|---------|--------|------------|---------|---------|---------|
| 1 | MATH 54 教授 | https://math.berkeley.edu/~prof | ✅ 已验证 | 🟢 HIGH | Berkeley Math | 2026-01-26 10:30 | ⬜ |
| 2 | 上课时间 | https://calcentral.berkeley.edu/... | ⚠️ 需登录 | 🟡 MEDIUM | CalCentral | 2026-01-26 10:35 | ⬜ |
| 3 | RMP 评分 | https://ratemyprofessors.com/... | ✅ 已验证 | 🟠 LOW | RMP | 2026-01-26 10:38 | ⬜ |
| 4 | 有录播 | https://youtube.com/@XXX | ❌ 链接失效 | 🔴 UNCERTAIN | YouTube | 2026-01-26 10:40 | ⬜ |

### URL 验证统计
- ✅ 已验证可访问: X 个
- ⚠️ 无法验证（需登录等）: Y 个
- ❌ 验证失败（链接失效）: Z 个

### Source Confidence 统计
- 🟢 HIGH: X 个 (官方一手)
- 🟡 MEDIUM: Y 个 (官方二手/半官方)
- 🟠 LOW: Z 个 (社区来源)
- 🔴 UNCERTAIN: W 个 (无法验证)

### 来源统计
- 📌 用户指定来源: X 个，已使用 Y 个
- 🔍 AI 自主发现来源: Z 个，待用户确认

---
⚠️ **请特别注意 URL验证 列为 ❌ 或 Confidence 为 🔴 的条目！**
这些信息可能不准确，需要额外确认。

请在"用户验收"列标记：
- ✅ 已验收（点击链接确认有效）
- ❌ 不认可（链接失效或内容不匹配）
- ⚠️ 需要补充信息
```

**完成后**: 更新 state.json `"phase": "synthesize_complete"`

### ⛔ 用户来源审计门控 (Phase 5 → Phase 6) - 强制阻断

**Phase 5 完成后，MUST 使用 AskUserQuestion 工具等待用户审核来源审计表！**

> ⚠️ **技术强制**：必须调用 `AskUserQuestion` 工具，不是简单输出文字！
> 如果不调用 AskUserQuestion 就进入 Phase 6，视为违反 skill 规则。

**AskUserQuestion 调用模板：**
```json
{
  "questions": [{
    "question": "请审核上述【来源审计表】。URL 验证状态和可信度评级是否合理？是否有需要重新验证的来源？",
    "header": "来源审计",
    "options": [
      {"label": "✅ 确认，进入验收", "description": "来源审计通过，授权进入 Phase 6 Ralph 验收"},
      {"label": "❌ 有来源不认可", "description": "部分来源需要标记为不可靠，需要补充验证"},
      {"label": "🔄 需要重新验证 URL", "description": "部分 URL 验证状态有误，需要重新访问验证"}
    ],
    "multiSelect": false
  }]
}
```

**用户反馈处理：**
- **✅ 确认** → 继续 Phase 6
- **❌ 有来源不认可** → 用户需指明哪些来源：
  - 将该来源的信息标记为 `[未验证]`
  - 可信度降为 `🔴F`
  - 在 Phase 6 中尝试寻找替代来源
- **🔄 需要重新验证 URL** → 用户需指明哪些 URL：
  - 重新执行 WebFetch 验证
  - 更新验证状态
  - 重新输出来源审计表

### Phase 6: Ralph 迭代验收 ⬜
**检查点**: `ralph.status` 为 "passed" 或 iteration >= 5

> **借鉴来源**:
> - Chain-of-Verification (CoVe) - Meta Research (arxiv.org/abs/2309.11495)
> - Perplexity Deep Research - Source Confidence Ratings
> - Defence in Depth - Fail Safe 机制

**Ralph 循环入口**：读取 `.research/PROMPT.md`

---

#### 🕐 Ralph 检查优先级 (重新排序！)

> **用户明确要求**: 时效性是最重要的迭代重点！

**Priority 1: 🕐 时效性验证 (Timeliness)** ← 核心指标！
- [ ] 所有信息获取时间是否在 7 天内？
- [ ] 教授名单是否与当前学期官网一致？
- [ ] 课程时间是否与 CalCentral 一致？
- [ ] 信息来源 URL 是否仍然可访问？
- [ ] 学期变化（Fall → Spring）后的信息是否已重新验证？

**Priority 2: 📋 完整性验证 (Completeness)**
- [ ] 所有授课教授都已调研？（Adder Agent 审计通过）
- [ ] 所有验收标准都有对应信息？
- [ ] 无逻辑空白？
- [ ] 共同授课的每位教授都有独立调研记录？

**Priority 3: ✅ 准确性验证 (Accuracy)**
- [ ] 所有 [事实] 有来源 URL？
- [ ] 所有来源 URL 已验证可访问？
- [ ] 所有引用可在来源中找到原文？
- [ ] 无未解决的信息冲突？

**Priority 4: 📚 引用规范 (Citation)**
- [ ] 报告正文有内联引用？
- [ ] 来源审计表完整？
- [ ] Source Confidence Rating 已标注？

---

#### 🔗 Chain-of-Verification (CoVe) 四步验证

**每次 Ralph 迭代执行 CoVe：**

```
Step 1: Draft Review
  - 读取 report.md 中的声明
  - 列出所有待验证的声明

Step 2: Plan Verification Questions
  - 为每个声明生成验证问题
  - 例如: "CS 189 教授是谁？" → 验证问题: "eecs189.org Staff 页面显示几位教授？"

Step 3: Independent Answer (独立执行，避免偏差)
  - 直接访问来源获取答案
  - 不参考原报告内容

Step 4: Verified Output
  - 对比 Step 1 的声明和 Step 3 的答案
  - 标记不一致项
  - 更新或降级不一致的信息
```

---

#### 📊 Source Confidence Ratings (来源可信度评级)

**在来源审计表中添加 Confidence 列：**

| # | 信息 | 来源URL | Confidence | 验证方式 | 时效性 |
|---|------|---------|------------|----------|--------|
| 1 | CS 189 教授 | eecs189.org | 🟢 HIGH | 直接访问官网 | ✅ 当前 |
| 2 | RMP 评分 2.6 | ratemyprofessors.com | 🟡 MEDIUM | RMP 数据可变 | ⚠️ 可能变化 |
| 3 | 学生评价 | reddit.com | 🟠 LOW | 社区来源 | ⚠️ 主观 |

**Confidence 定义：**
- 🟢 **HIGH**: 官方一手来源，直接验证（berkeley.edu, 课程官网）
- 🟡 **MEDIUM**: 官方二手或半官方，间接验证（Ed/Piazza 公告, Berkeleytime）
- 🟠 **LOW**: 社区来源，主观内容（Reddit, RateMyProfessor）
- 🔴 **UNCERTAIN**: 无法验证或已过时

---

#### 🛡️ Fail Safe 机制 (借鉴 Defence in Depth)

**迭代限制：**
- Ralph 循环最多 5 次
- Adder Agent 补充最多 3 次
- Missing Info 检测最多 3 轮

**超限后行为（绝对禁止静默通过！）：**
```markdown
⚠️ FAIL SAFE 触发

已达到最大迭代次数，以下信息无法完全验证：

| # | 信息 | 验证状态 | 原因 |
|---|------|---------|------|
| 1 | [信息] | [未验证] | 来源无法访问 |
| 2 | [信息] | [未验证] | 超过验证尝试次数 |

这些信息已标记为 [未验证]，可信度降为 🔴F。
请用户确认是否接受部分结果。
```

**绝对禁止：**
- ❌ 超过限制后声称"已完成"
- ❌ 隐藏无法验证的信息
- ❌ 用推理填补事实空白
- ❌ 执行"fallback"或"default"行为而不告知用户

---

**PROMPT.md 内容**：
```markdown
# Ralph 验收循环指令 (v2.0 - 含 CoVe + 时效性优先)

## 验收清单 (按优先级排序！)

### Priority 1: 🕐 时效性检查 (核心！)
- [ ] 所有 [事实] 的获取时间 < 7 天？
- [ ] 教授名单与课程官网 Staff 页面一致？
- [ ] 信息来源 URL 仍可访问？
- [ ] 如有超过 7 天的信息，是否已重新验证？

### Priority 2: 📋 完整性检查
- [ ] Adder Agent 审计通过（无遗漏教授）？
- [ ] 所有验收标准都有对应信息？

### Priority 3: ✅ 准确性检查
- [ ] 所有 [事实] 有来源 URL？
- [ ] URL 可访问性已验证？
- [ ] 无未解决的 [冲突]？

### Priority 4: 📚 引用检查
- [ ] 报告正文有内联引用？
- [ ] Source Confidence Rating 已标注？
- [ ] 用户指定来源 📌 全部使用？

## CoVe 验证执行
1. 列出所有待验证声明
2. 为每个声明生成验证问题
3. 独立执行验证（不参考原报告）
4. 对比并标记不一致项

## 执行
1. 按优先级顺序检查上述清单
2. 记录通过/未通过状态
3. 计算 pass_rate
4. 如果 pass_rate < 0.95，生成 @fix_plan.md
```

**@fix_plan.md 格式**：
```markdown
# 修复计划 (Iteration N)

## 未通过项
| # | 检查项 | 问题描述 | 修复策略 |
|---|-------|---------|---------|
| 1 | 需求3 | 缺少课程评分 | 重新搜索 RateMyProfessor |
| 2 | 来源5 | URL 不可访问 | 标记为 [未验证] |

## 执行修复
[执行上述修复策略]

## 重新验证
[执行完毕后重新运行 PROMPT.md 检查]
```

**循环直到**：
- `pass_rate >= 0.95` → ✅ 验收通过
- `iteration >= max_iterations` → ⚠️ 输出剩余问题，询问用户是否接受

---

#### ⚠️ 每次迭代必须更新 state.json！（Agent Hook 依赖）

**Stop Hook Agent 会读取 `state.json` 判断是否允许结束对话。**
**如果不更新，Agent Hook 无法正确判断！**

```python
# 每次验收检查后，MUST 执行：
import json
from datetime import datetime

# 1. 读取 state.json
with open(".research/state.json", "r") as f:
    state = json.load(f)

# 2. 更新迭代计数
state["verify"]["iteration"] += 1
state["verify"]["pass_rate"] = calculated_pass_rate  # 例如 0.85
state["verify"]["last_check_time"] = datetime.now().isoformat()

# 3. 记录未通过项
state["verify"]["failed_items"] = [
    "需求3: 缺少课程评分",
    "来源5: URL 不可访问"
]

# 4. 判断是否通过
if pass_rate >= 0.95:
    state["verify"]["exit_signal"] = True

# 5. 写回 state.json
with open(".research/state.json", "w") as f:
    json.dump(state, f, indent=2, ensure_ascii=False)

# 6. 如果通过，输出完成标记
if state["verify"]["exit_signal"]:
    print("RALPH_DONE")
```

**循环结束条件（与 Agent Hook 对应）**:
| 条件 | Agent Hook 返回 | 结果 |
|------|-----------------|------|
| `pass_rate >= 0.95` | `{"decision": "allow"}` | ✅ 验收通过 |
| `iteration >= max_iterations` | `{"decision": "allow", "reason": "..."}` | ⚠️ 达到上限 |
| `exit_signal == true` | `{"decision": "allow"}` | ✅ 手动通过 |
| 其他情况 | `{"decision": "block", "reason": "..."}` | 🔄 继续循环 |

**RALPH_DONE 输出格式**：
```
✅ RALPH_DONE

验收通过！
- 迭代次数: 3
- 通过率: 100% (8/8 AC)
- 验证时间: 2026-02-05T22:00:00

所有验收标准满足，进入 Phase 7 持久化。
```

---

**完成后**: 更新 state.json `"phase": "verify_complete"`

### Phase 7: Graphiti 持久化 ⬜
**检查点**: 所有 [事实] 已存入 Graphiti

**MUST 存储每个验证过的事实！**

```python
for fact in verified_facts:
    mcp__graphiti__add_memory(
        name=f"{topic} - {info_type}",
        episode_body=fact,
        group_id="zero-hallucination-research"
    )
```

- 调研前查询已有知识（减少重复工作）
- 调研后存入已验证事实（跨会话可用）
- Bi-Temporal 模型自动处理冲突

**完成后**: 更新 state.json `"phase": "completed"`

---

## 🎮 使用方式

### 基本调研
```
/zero-hallucination-research "调研主题描述"
```

### 主命令
```
/zhr-plan      # Phase 0-2: 计划阶段（独立会话）
/zhr-run       # Phase 3-7: 执行+验收（v5.0 合并版，推荐）
```

### 子命令（已弃用）
```
/zhr-execute   # ⚠️ 已弃用，功能合并到 /zhr-run
/zhr-verify    # ⚠️ 已弃用，功能合并到 /zhr-run
```

### 辅助命令
```
/zero-hallucination-research status    # 查看进度
/zero-hallucination-research resume    # 断点恢复
/zero-hallucination-research report    # 查看报告
/zero-hallucination-research audit     # 查看来源审计表
```

### 指定模式/引擎
```
/zero-hallucination-research --mode=fast "主题"
/zero-hallucination-research --mode=chrome "主题"
/zero-hallucination-research --engine=claude-deep "主题"
```

### 强制执行特定 Phase
```
/zero-hallucination-research phase3    # 强制执行 Phase 3
/zero-hallucination-research phase6    # 强制执行 Ralph 循环
```

---

## ⚠️ 核心原则

### 诚实原则（最高优先级）
```
❌ "根据规律推测，DIS 应该在周一"
✅ "[未验证] DIS 时间 (原因: 无法登录 CalCentral) [可信度: 🔴F]"
```

### 禁止行为
- 用逻辑填补事实空白
- 假装知道无法验证的信息
- 编造看起来合理的 URL
- **声称 URL 有效但实际未用 WebFetch 验证**
- **对验证失败的 URL 仍标注为 [事实]（必须降级为 [未验证]）**
- **省略 URL 验证状态标注（每个 URL 必须有 [URL验证: ✅/⚠️/❌]）**
- **跳过任何 Phase（包括 Phase 3.5 完整性审计！）**
- **跳过用户审批门控**
- **不使用 Task 工具直接执行调研**
- **只调研"第一位"或"主教授"而忽略共同授课的其他教授**
- **报告结论或评价没有内联引用来源 URL**
- **超过 Ralph 限制后声称"已完成"而不报告未验证项**
- **隐藏或省略无法验证的信息**

### 必须做到
- 所有信息标注 `[事实]/[推理]/[未验证]`
- 所有来源标注 `📌/🔍` + 可信度等级 + **Source Confidence Rating**
- 无法获取时直接询问用户
- 发现新需求时暂停询问并追加到 PRD
- **按顺序执行所有 Phase（包括 Phase 3.5！）**
- **Phase 1 后等待用户审批 PRD**
- **Phase 3.5 执行 Adder Agent 完整性审计**
- **Phase 5 后输出来源审计表（含 Source Confidence Rating）**
- **Phase 5 报告正文必须有内联引用（尤其是结论和评价部分！）**
- **Phase 6 执行 Ralph 循环直到通过或达到最大迭代**
- **Phase 6 按优先级顺序检查：时效性 > 完整性 > 准确性 > 引用**
- **超过 Ralph 限制时，输出 Fail Safe 报告并询问用户**
- **每门课程调研所有授课教授（共同授课的每位都要独立调研！）**

---

## 📂 文件结构

```
.research/
├── task_plan.md       # 📌 PRD：核心需求和验收标准（固定路径！）
├── state.json         # 执行状态（断点续传）+ Phase 检查点 + Ralph 状态
├── report.md          # 最终报告（含来源审计表）
├── source_audit.md    # 来源审计表（独立文件，便于用户审核）
├── PROMPT.md          # Ralph 循环指令
├── @fix_plan.md       # Ralph 修复计划
├── findings/          # 各主题调研结果
│   ├── topic1.md
│   └── topic2.md
├── versions/          # PRD 版本历史
│   ├── task_plan_v1.0.md
│   └── task_plan_v1.1.md
├── archive/           # 归档（全新需求时）
└── memory/
    ├── priority.md    # 优先上下文（每次必读）
    └── working.md     # 工作记忆
```

---

## 📋 验收检查清单 (v2.0 - 含完整性和时效性检查)

执行调研时，确保：

### 核心门控
- [ ] Phase 1 后用户已审批 PRD
- [ ] **所有 Phase 按顺序完成（包括 Phase 3.5 完整性审计！）**
- [ ] **用户审批门控已通过**
- [ ] **Phase 6 Ralph 循环已执行**
- [ ] **Phase 7 Graphiti 持久化已完成**

### 🕐 时效性检查 (Priority 1)
- [ ] 所有 [事实] 的获取时间 < 7 天？
- [ ] 教授名单与当前学期课程官网一致？
- [ ] 超过 7 天的信息已重新验证或标记为 [未验证]？

### 📋 完整性检查 (Priority 2)
- [ ] **所有授课教授都已识别？**（对照课程官网 Staff 页面）
- [ ] **每位教授都有独立调研记录？**
- [ ] **task_plan.md 中的教授名单与 findings 文件一致？**
- [ ] Adder Agent 完整性审计通过？
- [ ] 无逻辑空白？

### ✅ 准确性检查 (Priority 3)
- [ ] 所有 `[事实]` 有来源 URL
- [ ] 所有 `[未验证]` 标注原因
- [ ] 无未解决的 `[冲突]`
- [ ] 📌 来源全部使用
- [ ] 🔍 来源已标明待用户确认

### 📚 引用检查 (Priority 4)
- [ ] 可信度等级已评估
- [ ] **Source Confidence Rating 已标注**
- [ ] 来源审计表已生成
- [ ] **报告正文有内联引用**（结论和评价必须有来源 URL！）

### 其他
- [ ] **增量需求已追加到 PRD**
- [ ] **幻觉已记录到 PRD**

---

> **详细模板**：task_plan.md、state.json、report.md、subagent 指令等完整模板请参阅 `reference.md`
