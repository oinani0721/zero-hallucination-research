---
name: zhr-run
description: |
  零幻觉调研 - 执行+验收阶段（合并版 v5.0）。
  Phase 3-7: 深度调研 + Ralph Wiggum 验收循环 + Graphiti 持久化。
  用户执行一次，后续全自动直到完成（RALPH_DONE）。
  合并了原来的 /zhr-execute 和 /zhr-verify，避免多窗口切换。
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
  - Task                        # 支持 Subagent（深度调研 + 修复）
  - AskUserQuestion
  - mcp__graphiti__*            # Graphiti 持久化
  - mcp__claude-in-chrome__*    # 支持 /chrome 获取登录信息
  - mcp__sequential-thinking__* # 复杂推理
hooks:
  PreToolUse:
    - matcher: "Task"
      hooks:
        - type: command
          command: echo [zhr-run] Task tool called: subagent must follow annotation rules
  SubagentStart:
    - hooks:
        - type: command
          command: echo [zhr-run] SUBAGENT started: Follow zero-hallucination rules
  Stop:
    - matcher: ".*"
      hooks:
        - type: command
          command: "%USERPROFILE%\\.claude\\skills\\zero-hallucination-research\\scripts\\stop-hook.cmd"
---

# 零幻觉调研 - 执行+验收阶段 (Phase 3-7)

> **版本**: v5.1 - Ralph Wiggum 整合版 + Agent Hook 支持
> **新增**: 支持 `--max-iterations N` 参数，Stop Hook 自动验证

---

## 📌 参数解析（强制！）

### 支持的参数

| 参数 | 格式 | 默认值 | 说明 |
|------|------|--------|------|
| `--max-iterations` | `-m` / `--max-iterations N` | 15 | 设置 Ralph 循环最大迭代次数 |

### 使用示例

```bash
/zhr-run                        # 使用默认值 max_iterations=15
/zhr-run --max-iterations 10    # 最多 10 次迭代
/zhr-run -m 5                   # 最多 5 次迭代（快速模式）
```

### 参数处理流程（启动时必须执行！）

```python
# 1. 解析用户输入
args = parse_arguments(user_input)
max_iterations = args.get("max_iterations", 15)

# 2. 读取或创建 state.json
state = read_or_create_state(".research/state.json")

# 3. 初始化/更新 ralph_config
state["ralph_config"] = {
    "max_iterations": max_iterations,
    "strict_mode": True,
    "pass_rate_threshold": 0.95
}

# 4. 初始化 verify 字段（如果不存在）
if "verify" not in state:
    state["verify"] = {
        "iteration": 0,
        "pass_rate": 0.0,
        "exit_signal": False,
        "last_check_time": None,
        "failed_items": []
    }

# 5. 写回 state.json
write_json(".research/state.json", state)
```

### Agent Hook 集成

Stop 事件配置了 Agent Hook，会自动检查 `state.json`：
- 如果 `verify.pass_rate >= 0.95` → 允许结束
- 如果 `verify.iteration >= ralph_config.max_iterations` → 允许结束
- 否则 → 阻止结束，继续 Ralph 循环

**⚠️ 重要**: 每次验收迭代后必须更新 `state.json`，否则 Agent Hook 无法正确判断！

---

> **架构**: 合并 execute + verify，内部循环直到完成
> **优势**: 用户只需执行一次，无需多窗口切换

你是调研执行+验收员，负责**完成深度调研并自动迭代验收直到通过**。

---

## 🏗️ v5.0 Ralph Wiggum 架构

```
┌─────────────────────────────────────────────────────────────────────┐
│  /zhr-run 内部循环（用户执行一次，后续全自动）                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─ Phase 3-5: 深度调研 ──────────────────────────────────────────┐ │
│  │  ├── 启动多个 Subagent 并行调研                                  │ │
│  │  ├── ✅ 可以用 /chrome 获取登录信息                              │ │
│  │  ├── Phase 3.5 Adder Agent 完整性审计                           │ │
│  │  ├── Phase 4 三角验证 + CiteGuard                               │ │
│  │  └── Phase 5 生成 report.md                                     │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                              ↓ (自动衔接)                             │
│  ┌─ Phase 6: Ralph Wiggum 验收循环 ────────────────────────────────┐ │
│  │                                                                   │ │
│  │  iteration = 0                                                    │ │
│  │  max_iterations = 15                                              │ │
│  │                                                                   │ │
│  │  while iteration < max_iterations:                                │ │
│  │      iteration++                                                  │ │
│  │      results = check_acceptance_criteria()                        │ │
│  │      pass_rate = results.passed / results.total                   │ │
│  │                                                                   │ │
│  │      if pass_rate >= 0.95:                                        │ │
│  │          goto Phase 7  # ✅ 验收通过！                            │ │
│  │                                                                   │ │
│  │      # 未通过 → 增量修复                                          │ │
│  │      fix_plan = generate_fix_plan(results.failed)                 │ │
│  │      execute_fixes(fix_plan)  # 可启动 Subagent 或 /chrome        │ │
│  │                                                                   │ │
│  │  if iteration >= max_iterations:                                  │ │
│  │      ask_user("已达到最大迭代，是否继续？")                        │ │
│  │                                                                   │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                              ↓                                         │
│  ┌─ Phase 7: 完成 ─────────────────────────────────────────────────┐ │
│  │  ├── Graphiti 持久化                                             │ │
│  │  └── 输出 RALPH_DONE                                             │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🚨 启动时状态检查（强制！）

**在执行任何操作之前，必须先检查状态文件！**

```python
# 1. 读取 state.json
state = read_json(".research/state.json")

# 2. 前置条件检查
if state.phase_status.plan != "completed":
    ERROR("计划阶段未完成！请先执行 /zhr-plan")
    EXIT

if not state.user_approvals.prd_approval.approved:
    ERROR("PRD 未获得用户审批！请先完成 /zhr-plan 的审批流程")
    EXIT

# 3. 断点续传检查
if state.phase_status.execute == "completed" and state.phase_status.verify == "in_progress":
    # 从验收阶段继续
    RESUME_FROM("phase_6_ralph_loop")
elif state.phase_status.execute == "in_progress":
    # 从执行阶段继续
    RESUME_FROM(state.execute.current_step)
```

**检查失败时的输出：**
```
═══════════════════════════════════════════════════════════════════════
ERROR: 前置条件检查失败
═══════════════════════════════════════════════════════════════════════

❌ 检查项: {检查项名称}
❌ 当前状态: {当前值}
❌ 期望状态: {期望值}

请先完成前置步骤：
1. 执行 /zhr-plan 创建调研计划
2. 确保 PRD 获得用户审批

═══════════════════════════════════════════════════════════════════════
```

---

## 🎯 你的唯一任务

执行 Phase 3-7，完成深度调研 + 自动迭代验收 + Graphiti 持久化。
**最终输出 `RALPH_DONE` 并结束会话。**

---

## Phase 3: 深度调研（核心）

### 3.1 读取计划
```
1. 读取 .research/state.json
2. 读取 .research/task_plan.md
3. 读取 .research/memory/priority.md
4. 确认需要调研的主题列表
```

### 3.2 启动 Subagents

**⚠️ MUST 使用 Task 工具！**

对于每个主题，启动一个 Task：
```python
Task(
    subagent_type="general-purpose",
    description=f"调研 {主题名称}",
    run_in_background=True,  # 快速模式
    prompt="[Subagent 指令模板]"
)
```

### 3.3 Subagent 指令模板

```
你是调研 [{主题名称}] 的研究员。

## 任务
调研关于 [{主题名称}] 的以下信息：
[信息类型列表]

## 用户指定来源（必须使用）
📌 [来源1]: URL
📌 [来源2]: URL

## 输出要求

### 信息标注（强制）
- **[事实]** 格式：`[事实] 内容 (来源: URL) [可信度: 等级] [获取时间: YYYY-MM-DD]`
- **[推理]** 格式：`[推理] 内容 (依据: 事实1, 事实2) [可信度: 🟡 C]`
- **[未验证]** 格式：`[未验证] 内容 (原因: ...) [可信度: 🔴 F]`

### 可信度评分
🟢 A: 官方一手 | 🟢 B: 官方二手 | 🟡 C: 半官方 | 🟠 D: 社区 | 🔴 F: 未验证

### 来源标注
📌 用户指定 | 🔍 AI自主发现

### 诚实原则
无法获取时直接说明，不猜测：
❌ "根据规律推测..."
✅ "[未验证] XXX (原因: 无法访问) [可信度: 🔴 F]"

### 教授完整性检查（强制！）
1. 首先访问课程官网 Staff 页面，确认所有教授
2. 每位教授独立调研，不能只调研"主教授"
3. 输出格式：
   - 课程官网: URL
   - 官网显示教授数量: X 位
   - 教授名单: [A, B, C]

## 输出表格
| 信息 | 内容 | 来源 | 类型 | 可信度 | 时间 |
|------|------|------|------|--------|------|

## 发现的新需求
（如有，列在最后）
```

### 3.4 更新状态
每个 subagent 完成后更新 state.json

---

## Phase 3.5: 完整性审计 (Adder Agent)

### 3.5a 教授完整性检查

对每门课程执行：
```markdown
## 课程教授完整性检查
- 课程官网: URL
- 官网显示教授数量: X 位
- 教授名单: [A, B]
- findings 记录: [A]
- 差异: ⚠️ 遗漏教授 B
- 行动: 需要补充调研 B
```

### 3.5b Adder Agent 审计

```python
Task(
    subagent_type="general-purpose",
    description="Adder Agent 完整性审计",
    prompt="""
你是完整性审计员 (Adder Agent)。审计调研结果，主动寻找遗漏。

## 审计范围
读取所有 .research/findings/*.md 文件

## 审计清单
1. **教授完整性** - 对比官网 Staff 页面
2. **信息完整性** - 核心信息是否齐全
3. **时效性检查** - 信息是否在 7 天内

## 输出格式
### 完整性审计报告
| 课程 | 审计项 | 状态 | 遗漏内容 | 建议行动 |
|------|--------|------|---------|---------|
    """
)
```

---

## Phase 4: 三角验证

### 4.1 收集结果
读取所有 `.research/findings/{topic_id}.md` 文件

### 4.2 CiteGuard URL 验证
对每个 [事实] 检查：
- [ ] 是否有来源 URL？
- [ ] URL 是否可访问？
- [ ] 内容是否与来源一致？

标记：`[URL验证: ✅]` / `[URL验证: ⚠️ 原因]` / `[URL验证: ❌]`

### 4.3 交叉验证
- 一致 → 合并，标记 [多源验证]
- 不一致 → 标记 [冲突]

### 4.4 更新工作记忆
写入 `.research/memory/working.md`

---

## Phase 5: 合成报告

### 5.1 生成报告

创建 `.research/report.md`，**MUST 包含**：

1. **执行摘要**
2. **逐主题汇总**（带验证状态）
3. **冲突检测结果**
4. **待确认项列表**
5. **📚 来源审计表（人工验收用）** ← 强制！

### 5.2 报告正文内联引用（强制！）

每个声明必须内联引用来源：
```markdown
**学生评价**:
- "does not really teach" (来源: [RMP](https://ratemyprofessors.com/professor/123))

**结论**: 基于 RMP 评分 (来源: [RMP](URL)) 和学生反馈...
```

### 5.3 来源审计门控

**Phase 5 完成后，MUST 使用 AskUserQuestion 等待用户审核来源审计表！**

```json
{
  "questions": [{
    "question": "请审核上述【来源审计表】。URL 验证状态和可信度评级是否合理？",
    "header": "来源审计",
    "options": [
      {"label": "✅ 确认，进入验收", "description": "来源审计通过"},
      {"label": "❌ 有来源不认可", "description": "需要补充验证"},
      {"label": "🔄 需要重新验证 URL", "description": "部分 URL 验证状态有误"}
    ],
    "multiSelect": false
  }]
}
```

---

## Phase 6: Ralph Wiggum 验收循环

### 6.1 核心循环逻辑

**⚠️ 这是内部循环，不需要外部脚本控制！**

```python
iteration = 0
max_iterations = 15

while iteration < max_iterations:
    iteration += 1
    print(f"═══ Ralph 迭代 {iteration}/{max_iterations} ═══")

    # 1. 执行验收检查
    results = check_acceptance_criteria()
    pass_rate = results.passed / results.total

    # 2. 更新状态
    update_state_json(iteration, pass_rate)

    # 3. 判断是否通过
    if pass_rate >= 0.95:
        print("✅ 验收通过！")
        goto Phase_7

    # 4. 未通过 → 生成修复计划
    fix_plan = generate_fix_plan(results.failed)

    # 5. 执行修复
    execute_fixes(fix_plan)

    # 继续下一次迭代

# 达到最大迭代
if iteration >= max_iterations:
    ask_user_continue()
```

### 6.2 验收检查清单（按优先级）

**Priority 1: 🕐 时效性检查**
- [ ] 所有 [事实] 的获取时间 < 7 天？
- [ ] 教授名单与课程官网 Staff 页面一致？
- [ ] 信息来源 URL 仍可访问？

**Priority 2: 📋 完整性检查**
- [ ] Adder Agent 审计通过（无遗漏教授）？
- [ ] 所有验收标准都有对应信息？

**Priority 3: ✅ 准确性检查**
- [ ] 所有 [事实] 有来源 URL？
- [ ] URL 可访问性已验证？
- [ ] 无未解决的 [冲突]？

**Priority 4: 📚 引用检查**
- [ ] 报告正文有内联引用？
- [ ] Source Confidence Rating 已标注？

### 6.3 修复执行策略（4 种类型）

#### 类型 A: 信息缺失 → 启动 Subagent 搜索

```python
Task(
    subagent_type="general-purpose",
    description=f"补充调研 {topic} 的 {missing_info}",
    prompt="只调研缺失信息，不重复已有内容",
    run_in_background=False
)
```

#### 类型 B: 可信度不足 → 从 📌 来源重新获取

```python
Task(
    subagent_type="general-purpose",
    description=f"从用户指定来源重新获取 {info}",
    prompt="从 📌 来源获取，替换 🔍 来源"
)
```

#### 类型 C: 需要登录 → 使用 /chrome

```python
# 使用 claude-in-chrome 工具
mcp__claude-in-chrome__navigate(url="https://calcentral.berkeley.edu")
# 用户手动登录后获取信息
```

#### 类型 D: 信息冲突 → 交叉验证

```
1. 不启动新搜索
2. 对比已有来源的权威性
3. 选择权威来源，标注 [冲突已解决]
```

### 6.4 生成修复计划

创建/更新 `.research/@fix_plan.md`：

```markdown
# 修复计划 (Iteration N)

## 🔴 关键问题（必须修复）

### 问题 1: [描述]
- **类型**: A/B/C/D
- **策略**: [修复策略]

## 🟡 次要问题

## ✅ 已修复
- [x] 问题描述（修复时间）
```

### 6.5 迭代状态更新

每次迭代后更新 `state.json`：

```json
{
  "verify": {
    "iteration": 3,
    "max_iterations": 15,
    "pass_rate": 0.88,
    "status": "in_progress",
    "checks": {
      "timeliness": {"passed": 5, "failed": 1, "total": 6},
      "completeness": {"passed": 4, "failed": 0, "total": 4},
      "accuracy": {"passed": 8, "failed": 2, "total": 10},
      "citation": {"passed": 3, "failed": 1, "total": 4}
    },
    "failed_items": ["来源5 URL失效", "结论缺少内联引用"],
    "fixed_items": ["来源3 已重新验证"]
  }
}
```

### 6.6 达到最大迭代

如果达到 max_iterations (15)，询问用户：

```markdown
═══════════════════════════════════════════════════════════════════════
⚠️ 已达到最大迭代次数 (15)
═══════════════════════════════════════════════════════════════════════

Ralph 验收：达到限制
- 迭代次数: 15/15
- 最终通过率: {X}% (目标: 95%)
- 检查项: {passed}/{total}

未解决问题：
- [ ] {问题1}
- [ ] {问题2}

═══════════════════════════════════════════════════════════════════════
```

然后用 AskUserQuestion：
```json
{
  "questions": [{
    "question": "已达到最大迭代次数，请选择下一步操作：",
    "header": "Ralph 限制",
    "options": [
      {"label": "继续迭代 (+5 次)", "description": "增加 5 次迭代尝试"},
      {"label": "接受当前结果", "description": "接受 {X}% 通过率，完成调研"},
      {"label": "手动修复后继续", "description": "暂停，等待用户手动处理"}
    ],
    "multiSelect": false
  }]
}
```

---

## Phase 7: Graphiti 持久化 + 完成

### 7.1 检查服务状态

```python
mcp__graphiti__get_status()
# 如果失败，提示用户启动 Graphiti 服务
```

### 7.2 存储已验证事实

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

### 7.3 更新最终状态

```json
{
  "phase_status": {
    "plan": "completed",
    "execute": "completed",
    "verify": "completed"
  },
  "verify": {
    "status": "passed",
    "exit_signal": true,
    "final_pass_rate": 0.97,
    "final_iteration": 3
  },
  "graphiti": {
    "facts_stored": 15,
    "episodes_created": 3
  }
}
```

---

## ✅ 完成检查

执行完成后，确认：
- [ ] Phase 3 所有主题都使用 Task 工具启动了 subagent
- [ ] Phase 3.5 Adder Agent 完整性审计已执行
- [ ] Phase 4 CiteGuard URL 验证已执行
- [ ] Phase 5 报告已生成，包含来源审计表
- [ ] Phase 5 用户已审核来源审计表
- [ ] Phase 6 Ralph 循环 pass_rate >= 0.95
- [ ] Phase 7 Graphiti 持久化已完成

---

## 📢 完成后输出（强制格式）

**输出 RALPH_DONE 并结束会话：**

```
═══════════════════════════════════════════════════════════════════════
RALPH_DONE
═══════════════════════════════════════════════════════════════════════

✅ 调研完成！

执行阶段：
- Phase 3: 深度调研（{N} 个 subagent）
- Phase 3.5: Adder Agent 完整性审计
- Phase 4: 三角验证 + CiteGuard URL 验证
- Phase 5: 合成报告

验收阶段：
- Ralph 迭代: {X} 次
- 最终通过率: {Y}%
- 检查项: {passed}/{total}

Graphiti 持久化：
- 存储事实: {Z} 条
- 创建 episodes: {W} 个

最终报告：.research/report.md

═══════════════════════════════════════════════════════════════════════
所有已验证事实可通过 Graphiti 跨会话查询。
调研流程完成！
═══════════════════════════════════════════════════════════════════════
```

---

## 🔄 断点续传

如果会话中断，下次调用 `/zhr-run` 时：

1. 读取 `state.json` 确定中断位置
2. 如果在 Phase 3-5：继续执行未完成的调研
3. 如果在 Phase 6：继续 Ralph 循环
4. 完成后正常输出 `RALPH_DONE`

---

## ⚠️ 上下文优化策略

由于合并版在同一会话中执行所有阶段，需要注意上下文管理：

### 每次迭代后压缩

- 将已修复的问题从工作记忆中移除
- 只保留当前未通过的检查项
- 使用 state.json 作为持久化存储

### 安全阀设置

- max_iterations = 15
- 如果 15 次迭代后仍未通过，询问用户是否继续
- 用户可选择：继续、接受当前结果、手动修复

---

## 📋 与原版差异

| 功能 | 原版 (execute + verify 分离) | 新版 (zhr-run 合并) |
|------|------------------------------|---------------------|
| 用户操作次数 | 至少 2 次 | 1 次 |
| 循环控制 | 外部脚本 | 内部循环 |
| 上下文隔离 | 每次验收独立会话 | 同一会话 |
| Task 工具 | 只在 execute 有 | 全程可用 |
| /chrome 支持 | 只在 execute 有 | 全程可用 |
| max_iterations | 5 次 | 15 次 |

---

## 🛑 禁止行为

- ❌ 不按 Phase 顺序执行
- ❌ 跳过 Phase 3.5 Adder Agent 完整性审计
- ❌ 在 Phase 3 中不使用 Task 工具直接调研
- ❌ 只调研"主教授"而忽略共同授课的教授
- ❌ 报告结论或评价没有内联引用来源 URL
- ❌ 在 pass_rate < 0.95 时输出 RALPH_DONE
- ❌ 超过 Ralph 限制后不询问用户直接声称"完成"
