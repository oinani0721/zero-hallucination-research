# Zero-Hallucination Research - 详细参考文档 v4.0

> 本文档包含完整的模板、示例和配置，供 SKILL.md 引用。
> 版本：v4.0 - 增加行业最佳实践（CoVe、Adder Agent、Source Confidence Ratings、时效性优先级）

---

## 🆕 v4.0 新增功能

| 功能 | 来源 | 说明 |
|------|------|------|
| **Adder Agent** | Multi-hop 研究 (arxiv.org/pdf/2510.14278) | 专门审计遗漏的独立 Agent |
| **CoVe 四步验证** | Meta Research (arxiv.org/abs/2309.11495) | Chain-of-Verification |
| **Source Confidence Ratings** | Perplexity Deep Research | HIGH/MEDIUM/LOW/UNCERTAIN |
| **时效性优先级** | 用户明确要求 | Ralph 检查第一优先级 |
| **Fail Safe 机制** | Defence in Depth | 超限后输出未验证列表 |
| **强制内联引用** | 用户反馈 | 报告正文每个声明必须有来源 |
| **教授完整性检查** | 实际案例（CS 189 遗漏教授） | 强制调研所有授课教授 |

---

## 📐 可信度评分系统详解

### 等级定义

| 等级 | 分数 | 标识 | 来源类型 | 使用建议 |
|------|------|------|---------|---------|
| **A** | 90-100% | 🟢 | 官方一手来源 | 直接使用 |
| **B** | 80-89% | 🟢 | 官方二手来源 | 可信，建议交叉验证 |
| **C** | 60-79% | 🟡 | 半官方/学术 | 需交叉验证 |
| **D** | 40-59% | 🟠 | 社区/用户生成 | 仅供参考 |
| **F** | <40% | 🔴 | 未验证/过时 | 不可用 |

### 来源分类示例

**🟢 A级 (90-100%)**: berkeley.edu, 课程官网, CalCentral, bCourses Syllabus
**🟢 B级 (80-89%)**: classes.berkeley.edu, EECS Directory, Ed/Piazza 公告
**🟡 C级 (60-79%)**: Berkeleytime, 教授个人页, 往年课程网站
**🟠 D级 (40-59%)**: Reddit, Rate My Professor, Discord, 学生博客
**🔴 F级 (<40%)**: 超过2年的信息, URL不可访问, AI推测

### 调整因子
```
+10: 多源交叉验证 | +5: 7天内获取 | +5: URL可访问
-10: 超过30天 | -15: URL无法访问 | -20: 与其他来源冲突
```

---

## 📊 Source Confidence Ratings (新增 v4.0)

> **借鉴来源**: Perplexity Deep Research (93.9% SimpleQA 准确率)

### Confidence 等级定义

| Rating | 标识 | 来源类型 | 验证方式 | 使用建议 |
|--------|------|---------|---------|---------|
| **HIGH** | 🟢 | 官方一手来源 | 直接访问验证 | 直接使用 |
| **MEDIUM** | 🟡 | 官方二手/半官方 | 间接验证 | 建议交叉验证 |
| **LOW** | 🟠 | 社区/用户生成 | 主观内容 | 仅供参考 |
| **UNCERTAIN** | 🔴 | 无法验证/已过时 | 验证失败 | 不可用 |

### Confidence 分类示例

| Rating | 来源示例 |
|--------|---------|
| 🟢 HIGH | berkeley.edu, CalCentral, 课程官网 Staff 页面, bCourses Syllabus |
| 🟡 MEDIUM | classes.berkeley.edu, Ed/Piazza 公告, EECS Directory, Berkeleytime |
| 🟠 LOW | Reddit r/berkeley, RateMyProfessor, Discord, 学生博客, Course Hero |
| 🔴 UNCERTAIN | 超过30天未更新, URL 404, 需要登录但无法验证 |

### 来源审计表模板 (含 Confidence)

```markdown
## 📚 来源审计表

| # | 信息摘要 | 来源URL | URL验证 | Confidence | 获取时间 | 用户验收 |
|---|---------|---------|--------|------------|---------|---------|
| 1 | CS 189 教授 | https://eecs189.org | ✅ | 🟢 HIGH | 2026-01-27 10:30 | ⬜ |
| 2 | RMP 评分 2.6 | https://ratemyprofessors.com/... | ✅ | 🟠 LOW | 2026-01-27 10:35 | ⬜ |
| 3 | 学生评价 | https://reddit.com/r/berkeley/... | ✅ | 🟠 LOW | 2026-01-27 10:40 | ⬜ |
| 4 | 录播链接 | https://youtube.com/@... | ❌ 失效 | 🔴 UNCERTAIN | 2026-01-27 10:45 | ⬜ |

### Confidence 统计
- 🟢 HIGH: 5 个 (官方一手)
- 🟡 MEDIUM: 3 个 (官方二手/半官方)
- 🟠 LOW: 4 个 (社区来源)
- 🔴 UNCERTAIN: 1 个 (无法验证)
```

---

## 📝 模板：task_plan.md (PRD - 固定路径)

**⚠️ 路径固定为：`.research/task_plan.md`**
**⚠️ 版本历史：`.research/versions/task_plan_v{X.Y}.md`**

```markdown
# 调研任务计划 (PRD)

## 文档信息
- **版本**: v1.0
- **创建时间**: [YYYY-MM-DD HH:MM]
- **最后更新**: [YYYY-MM-DD HH:MM]
- **用户审批状态**: ⏳ 待审批 | ✅ 已审批 | 🔄 修订中

---

## 调研配置
- **执行模式**: [快速/Chrome/混合]
- **调研引擎**: [claude-deep/Cranot/自动]
- **Graphiti**: [启用/禁用]
- **预估主题数**: [N]

---

## 核心需求 (用户原始需求)

> 用户原话记录，保持原文不做修改

1. [需求1] - 原文
2. [需求2] - 原文
3. [需求3] - 原文

---

## 验收标准 (Acceptance Criteria)

### 原始需求验收
| # | 需求描述 | 验收条件 | 状态 | 来源要求 |
|---|---------|---------|------|---------|
| AC-1 | [需求1摘要] | [具体可验证条件] | ⏳ | 📌 [指定来源] |
| AC-2 | [需求2摘要] | [具体可验证条件] | ⏳ | 🔍 AI搜索 |

### 增量需求验收 (调研中发现)
| # | 需求描述 | 发现时间 | 用户确认 | 验收条件 | 状态 |
|---|---------|---------|---------|---------|------|
| AC-I-1 | [增量需求] | [HH:MM] | ✅/❌ | [条件] | ⏳ |

---

## 用户指定来源（📌 必须使用）
- 📌 [来源名称1] (URL) - [用途说明]
- 📌 [来源名称2] (URL) - [用途说明]

---

## 主题列表与进度

| # | 主题名称 | 状态 | 负责引擎 | Findings文件 | 最后更新 |
|---|---------|------|---------|-------------|---------|
| 1 | [主题1] | ⏳ 待开始 | - | - | - |
| 2 | [主题2] | 🔄 进行中 | claude-deep | findings/topic_2.md | HH:MM |
| 3 | [主题3] | ✅ 完成 | cranot | findings/topic_3.md | HH:MM |

状态图例：⏳ 待开始 | 🔄 进行中 | ✅ 完成 | ❌ 失败

---

## 幻觉记录 (Hallucination Log)

> 调研过程中发现的幻觉，写入此处防止重复

| # | 幻觉描述 | 发现时间 | 原因分析 | 防止规则 |
|---|---------|---------|---------|---------|
| H-1 | [描述幻觉内容] | [HH:MM] | [为什么产生] | [如何避免] |

### 幻觉防止规则
- ❌ 禁止：[从幻觉中学到的禁止行为]
- ✅ 应该：[正确做法]

---

## 版本历史

| 版本 | 时间 | 变更内容 | 变更原因 |
|------|------|---------|---------|
| v1.0 | [创建时间] | 初始版本 | 用户需求 |
| v1.1 | [时间] | 增加 AC-I-1 | 调研中发现新需求 |
```

---

## 📝 模板：state.json (执行状态)

```json
{
  "version": "3.0",
  "created_at": "YYYY-MM-DD HH:MM:SS",
  "last_updated": "YYYY-MM-DD HH:MM:SS",

  "prd": {
    "file": ".research/task_plan.md",
    "version": "1.0",
    "user_approved": false,
    "approved_at": null,
    "versions_dir": ".research/versions/"
  },

  "phase": {
    "current": "plan",
    "completed": ["scope"],
    "checkpoints": {
      "phase_0": { "status": "completed", "timestamp": "..." },
      "phase_1": { "status": "completed", "timestamp": "..." },
      "user_approval_1": { "status": "pending", "timestamp": null },
      "phase_2": { "status": "pending", "timestamp": null }
    }
  },

  "config": {
    "execution_mode": "fast|chrome|mixed",
    "research_engine": "claude-deep|cranot|auto",
    "graphiti_enabled": true,
    "graphiti_group_id": "zero-hallucination-research"
  },

  "topics": [
    {
      "id": "topic_1",
      "name": "主题名称",
      "status": "pending|in_progress|completed|failed",
      "engine": "claude-deep-research",
      "findings_file": ".research/findings/topic_1.md",
      "task_id": null,
      "started_at": null,
      "completed_at": null
    }
  ],

  "user_approvals": {
    "prd_approval": {
      "required": true,
      "approved": false,
      "approved_at": null,
      "user_feedback": null
    },
    "source_audit_approval": {
      "required": true,
      "approved": false,
      "approved_at": null,
      "user_feedback": null
    }
  },

  "ralph": {
    "enabled": true,
    "status": "idle|running|passed|failed|max_iterations",
    "iteration": 0,
    "max_iterations": 5,
    "pass_threshold": 0.95,
    "current_pass_rate": 0.0,
    "entry_file": ".research/PROMPT.md",
    "fix_file": ".research/@fix_plan.md",
    "history": [
      {
        "iteration": 1,
        "timestamp": "...",
        "pass_rate": 0.6,
        "failed_criteria": ["AC-1", "AC-3"],
        "fix_actions": ["重新搜索来源", "交叉验证"]
      }
    ]
  },

  "source_audit": {
    "file": ".research/source_audit.md",
    "total_sources": 0,
    "user_verified": 0,
    "pending_verification": 0,
    "sources": [
      {
        "id": "src_1",
        "url": "https://...",
        "name": "来源名称",
        "type": "📌|🔍",
        "credibility": "A|B|C|D|F",
        "user_verified": false,
        "verified_at": null
      }
    ]
  },

  "incremental_requirements": [
    {
      "id": "AC-I-1",
      "description": "增量需求描述",
      "discovered_at": "...",
      "user_confirmed": true,
      "confirmed_at": "...",
      "added_to_prd": true
    }
  ],

  "hallucinations": [
    {
      "id": "H-1",
      "description": "幻觉描述",
      "discovered_at": "...",
      "cause": "原因",
      "prevention_rule": "防止规则",
      "added_to_prd": true
    }
  ],

  "graphiti_knowledge": {
    "total_facts": 0,
    "total_entities": 0,
    "last_sync": null,
    "conflicts_resolved": 0
  }
}
```

---

## 📝 模板：@completeness_audit.md (Adder Agent 输出)

> **新增 v4.0** - Adder Agent 完整性审计报告

**⚠️ 路径固定为：`.research/@completeness_audit.md`**

```markdown
# 完整性审计报告 (Adder Agent)

## 审计时间
- **执行时间**: [YYYY-MM-DD HH:MM]
- **审计范围**: .research/findings/*.md

---

## 教授完整性检查

| 课程 | 官网教授数 | findings记录 | 状态 | 遗漏教授 | 建议行动 |
|------|-----------|-------------|------|---------|---------|
| CS 189 | 2 | 1 | ❌ 遗漏 | Alex Dimakis | 补充调研 |
| CS 61A | 1 | 1 | ✅ 完整 | - | 无需行动 |
| CS 170 | 2 | 2 | ✅ 完整 | - | 无需行动 |

### 遗漏详情

#### CS 189 - 遗漏 Alex Dimakis
- **官网 Staff 页面**: https://eecs189.org/staff
- **官网显示**: Jennifer Listgarten (Lead), Alex Dimakis (Co-instructor)
- **findings 记录**: 仅 Jennifer Listgarten
- **行动**: 需要补充调研 Alex Dimakis
  - RMP 评分
  - 研究方向
  - 学生评价

---

## 信息完整性检查

| 课程 | 核心信息 | 状态 | 缺失项 | 建议行动 |
|------|---------|------|--------|---------|
| CS 189 | 教授 | ⚠️ 部分 | 第二位教授信息 | 补充调研 |
| CS 189 | Office Hours | ❌ 缺失 | 全部 | 查询课程官网 |
| CS 61A | 所有 | ✅ 完整 | - | 无需行动 |

---

## 时效性检查

| 信息 | 获取时间 | 时效状态 | 建议行动 |
|------|---------|---------|---------|
| CS 189 教授 | 2026-01-20 | 🟢 新鲜 (7天内) | 无需行动 |
| MATH 55 考试日期 | 2026-01-10 | 🔴 过时 (>7天) | 需重新验证 |

---

## 审计汇总

| 检查维度 | 通过 | 未通过 | 通过率 |
|---------|------|--------|--------|
| 教授完整性 | 9 | 1 | 90% |
| 信息完整性 | 8 | 2 | 80% |
| 时效性 | 10 | 0 | 100% |
| **总体** | **27** | **3** | **90%** |

---

## 行动计划

### 🔴 高优先级
1. [ ] 补充调研 CS 189 Alex Dimakis

### 🟡 中优先级
2. [ ] 查询 CS 189 Office Hours
3. [ ] 重新验证 MATH 55 考试日期
```

---

## 📝 模板：CoVe 验证记录

> **新增 v4.0** - Chain-of-Verification 四步验证模板

```markdown
# CoVe 验证记录 - [课程/主题名]

## Step 1: Draft Review - 待验证声明列表

| # | 声明 | 来源 | 报告位置 |
|---|------|------|---------|
| 1 | CS 189 教授是 Jennifer Listgarten | eecs189.org | report.md L45 |
| 2 | RMP 评分 2.6/5 | ratemyprofessors.com | report.md L52 |
| 3 | "does not really teach" | reddit | report.md L58 |

---

## Step 2: Plan Verification Questions

| 声明# | 验证问题 | 验证来源 |
|-------|---------|---------|
| 1 | eecs189.org Staff 页面显示几位教授？名单是什么？ | 直接访问 eecs189.org |
| 2 | RMP 上 Jennifer Listgarten 的当前评分是多少？ | 直接访问 RMP 页面 |
| 3 | Reddit 原帖是否存在？原文是否一致？ | 直接访问 Reddit 链接 |

---

## Step 3: Independent Answer (独立执行，不参考原报告)

| 验证问题 | 独立验证结果 | 验证时间 |
|---------|-------------|---------|
| Staff 页面教授数量？ | **2位**: Listgarten + Dimakis | 2026-01-27 10:30 |
| RMP 当前评分？ | 2.6/5 (14条评价) | 2026-01-27 10:35 |
| Reddit 原帖？ | ✅ 存在，原文一致 | 2026-01-27 10:38 |

---

## Step 4: Verified Output - 对比与更新

| 声明# | 原声明 | 验证结果 | 一致性 | 行动 |
|-------|-------|---------|--------|------|
| 1 | 1位教授 | 2位教授 | ❌ 不一致 | 更新：添加 Dimakis |
| 2 | 2.6/5 | 2.6/5 | ✅ 一致 | 保持 |
| 3 | 引用内容 | 原文一致 | ✅ 一致 | 保持 |

---

## 验证结论

- **总声明数**: 3
- **验证通过**: 2 (67%)
- **需要更新**: 1 (33%)
- **更新内容**: 添加遗漏的教授 Alex Dimakis
```

---

## 📝 模板：PROMPT.md (Ralph 循环入口) - v2.0

**⚠️ 路径固定为：`.research/PROMPT.md`**
**⚠️ v2.0 新增：时效性优先、CoVe 验证、Fail Safe 机制**

```markdown
# Ralph 验收循环指令 v2.0

## 循环状态
- **Status**: RUNNING
- **Iteration**: 1 / 5
- **Current Pass Rate**: 0.00%
- **Target Pass Rate**: 95%
- **CoVe 状态**: 待执行

---

## 验收检查清单 (按优先级排序！)

### Priority 1: 🕐 时效性检查 (核心！)
- [ ] 所有 [事实] 的获取时间 < 7 天？
- [ ] 教授名单与课程官网 Staff 页面一致？
- [ ] 课程时间与 CalCentral 一致？
- [ ] 信息来源 URL 仍可访问？
- [ ] 如有超过 7 天的信息，是否已重新验证？

### Priority 2: 📋 完整性检查
- [ ] Adder Agent 审计通过（无遗漏教授）？
- [ ] 所有授课教授都已独立调研？
- [ ] 所有验收标准都有对应信息？
- [ ] 无逻辑空白？

### Priority 3: ✅ 准确性检查
- [ ] 所有 [事实] 有来源 URL？
- [ ] 所有来源 URL 已验证可访问 [URL验证: ✅/⚠️/❌]？
- [ ] 无未解决的 [冲突]？
- [ ] 所有 [未验证] 标注了原因？

### Priority 4: 📚 引用检查
- [ ] 报告正文有内联引用？(尤其是结论和评价！)
- [ ] Source Confidence Rating 已标注？
- [ ] 用户指定来源 📌 全部使用？
- [ ] 来源审计表已生成？

### 需求满足检查
- [ ] AC-1: [验收条件] → 状态: ⏳
- [ ] AC-2: [验收条件] → 状态: ⏳
- [ ] AC-COMPLETENESS: 所有教授已调研 → 状态: ⏳
- [ ] AC-TIMELINESS: 信息时效性 < 7天 → 状态: ⏳

---

## CoVe 四步验证执行

### Step 1: 列出待验证声明
| # | 声明 | 来源 |
|---|------|------|
| 1 | [待填] | [待填] |

### Step 2: 生成验证问题
| 声明# | 验证问题 |
|-------|---------|
| 1 | [待填] |

### Step 3: 独立验证 (不参考原报告！)
| 验证问题 | 独立结果 | 验证时间 |
|---------|---------|---------|
| [待填] | [待填] | [待填] |

### Step 4: 对比并更新
| 声明# | 原声明 | 验证结果 | 一致性 | 行动 |
|-------|-------|---------|--------|------|
| 1 | [待填] | [待填] | ⏳ | [待填] |

---

## 执行指令

1. **READ**: 读取 `.research/task_plan.md` 获取验收标准
2. **COVE**: 执行 CoVe 四步验证
3. **CHECK**: 按优先级逐条检查清单
4. **TRACK**: 更新 `state.json.ralph` 记录结果
5. **EVALUATE**: 计算 pass_rate = 通过数 / 总检查数
6. **DECIDE**:
   - pass_rate >= 0.95 → 输出 "✅ PASSED"，进入 Phase 7
   - pass_rate < 0.95 AND iteration < 5 → 生成 `@fix_plan.md`，执行修复
   - iteration >= 5 → 输出 "⚠️ FAIL SAFE"，列出未验证项供用户决定

---

## 本次检查结果

| 优先级 | 检查项 | 通过/总数 | 状态 |
|--------|--------|-----------|------|
| P1 | 时效性 | _/_ | ⏳ |
| P2 | 完整性 | _/_ | ⏳ |
| P3 | 准确性 | _/_ | ⏳ |
| P4 | 引用 | _/_ | ⏳ |
| - | 需求满足 | _/_ | ⏳ |

**总体 Pass Rate**: 0.00%
**CoVe 不一致项**: _
**决定**: [CONTINUE/PASSED/FAIL_SAFE]

---

## ⚠️ Fail Safe 报告模板 (iteration >= 5 时使用)

如果达到最大迭代仍未通过，输出以下报告：

```
⚠️ FAIL SAFE 触发 - 达到最大迭代次数

### 无法完全验证的信息

| # | 信息 | 验证状态 | 原因 | 最终可信度 |
|---|------|---------|------|-----------|
| 1 | [信息] | [未验证] | [原因] | 🔴 UNCERTAIN |

### 说明
这些信息已标记为 [未验证]，可信度降为 🔴 UNCERTAIN。
报告中相关结论已添加警告标注。

### 用户决定
请确认是否接受部分结果？
- [ ] 接受，继续 Phase 7
- [ ] 拒绝，需要人工补充信息
```
```

---

## 📝 模板：@fix_plan.md (Ralph 修复计划)

**⚠️ 路径固定为：`.research/@fix_plan.md`**

```markdown
# Ralph 修复计划

## 修复状态
- **Iteration**: 2 / 5
- **Previous Pass Rate**: 60%
- **Target Pass Rate**: 95%
- **Failed Criteria Count**: 4

---

## 失败的验收标准

| # | 验收标准 | 失败原因 | 修复策略 | 优先级 |
|---|---------|---------|---------|--------|
| AC-1 | [描述] | 缺少来源URL | 重新搜索 | 🔴 高 |
| AC-2 | [描述] | 信息冲突 | 交叉验证 | 🟡 中 |
| AC-3 | [描述] | 需求未满足 | 针对性调研 | 🔴 高 |

---

## 修复行动计划

### 🔴 高优先级修复

#### Fix-1: 补充 AC-1 来源
- **问题**: [具体问题描述]
- **行动**: 使用 WebSearch/WebFetch 搜索 [关键词]
- **目标来源**: 📌 [用户指定来源] 或 🔍 [建议来源]
- **执行状态**: ⏳ 待执行

#### Fix-2: 解决 AC-3 需求
- **问题**: [具体问题描述]
- **行动**: [具体修复步骤]
- **执行状态**: ⏳ 待执行

### 🟡 中优先级修复

#### Fix-3: 解决信息冲突
- **冲突内容**: [来源A] vs [来源B]
- **行动**: 确定权威来源，标注 [冲突] 并说明
- **执行状态**: ⏳ 待执行

---

## 执行记录

| 时间 | 行动 | 结果 | 新 Pass Rate |
|------|------|------|-------------|
| [HH:MM] | Fix-1 执行 | ✅ 成功 | 70% |
| [HH:MM] | Fix-2 执行 | ⚠️ 部分成功 | 80% |

---

## 下一步

- [ ] 执行所有高优先级修复
- [ ] 重新运行 PROMPT.md 验收检查
- [ ] 更新 state.json.ralph 状态
```

---

## 📝 模板：source_audit.md (人工审计清单)

**⚠️ 路径固定为：`.research/source_audit.md`**
**⚠️ 用户必须审核此文件！**

```markdown
# 来源审计表 - 人工验收清单

> ⚠️ 请逐条审核以下信息来源，确认可靠性

## 审计状态
- **总来源数**: [N]
- **用户已验证**: [X]
- **待验证**: [Y]
- **审计完成率**: [X/N * 100]%

---

## 📌 用户指定来源 (必须全部使用)

| # | 来源名称 | URL | 使用状态 | 获取信息 | 用户验收 |
|---|---------|-----|---------|---------|---------|
| 1 | CalCentral | https://calcentral.berkeley.edu | ✅ 已使用 | 课程时间、地点 | ☐ 待验收 |
| 2 | BerkeleyTime | https://berkeleytime.com | ✅ 已使用 | 评分数据 | ☐ 待验收 |

**用户指定来源使用率**: [X]/[Y] = [100]%

---

## 🔍 AI 自主发现来源 (需用户确认可靠性)

| # | 来源名称 | URL | AI可信度 | 获取信息 | 用户判定 |
|---|---------|-----|---------|---------|---------|
| 1 | Rate My Professor | https://ratemyprofessors.com | 🟠 D (50%) | 教授评价 | ☐ 可靠 ☐ 不可靠 |
| 2 | Reddit r/berkeley | https://reddit.com/r/berkeley | 🟠 D (45%) | 学生体验 | ☐ 可靠 ☐ 不可靠 |

---

## 信息-来源映射表

| # | 信息内容 | 来源URL | 来源类型 | AI可信度 | 获取时间 | 用户验收 |
|---|---------|---------|---------|---------|---------|---------|
| 1 | MATH 54 教授: XXX | https://... | 📌 用户指定 | 🟢 A | 2026-01-26 10:00 | ☐ |
| 2 | CS 61A 评分: 4.5/5 | https://... | 🔍 AI发现 | 🟡 C | 2026-01-26 10:15 | ☐ |
| 3 | 时间冲突检测 | [推理] | [推理] | 🟡 C | - | ☐ |

---

## 验收说明

### 用户需要做的事：
1. **检查每个来源的 URL** - 点击确认是否可访问
2. **验证信息是否匹配** - 来源内容是否与报告一致
3. **判定 AI 发现来源的可靠性** - 标记 ☐ 可靠 或 ☐ 不可靠
4. **勾选用户验收列** - 确认后打勾 ☑

### AI 可信度说明
- 🟢 A (90-100%): 官方一手来源，可直接信任
- 🟢 B (80-89%): 官方二手来源，基本可信
- 🟡 C (60-79%): 半官方来源，建议验证
- 🟠 D (40-59%): 社区来源，仅供参考
- 🔴 F (<40%): 未验证/过时，需谨慎

---

## 审计签名

- **用户审核完成时间**: _________________
- **用户签名/确认**: _________________
- **备注**: _________________
```

---

## 📝 模板：report.md (最终报告 - 含强制来源审计表) v2.0

> **v4.0 更新**: 强制内联引用、Source Confidence Ratings

### ⚠️ 内联引用规范（强制执行！）

**规则：报告正文中每个声明都必须内联引用来源！**

**正确示例 ✅:**
```markdown
## CS 189 教授评价

### Jennifer Listgarten
- **RMP 评分**: 2.6/5 (来源: [RMP](https://ratemyprofessors.com/professor/2691363))
- **学生评价**:
  - "does not really teach, she just reads slides" (来源: [RMP](https://ratemyprofessors.com/professor/2691363))
  - "Her research is amazing, but teaching is not her passion" (来源: [RMP](https://ratemyprofessors.com/professor/2691363))

### Alex Dimakis
- **RMP 评分**: 4.2/5 (来源: [RMP](https://ratemyprofessors.com/professor/XXX))
- **学生评价**:
  - "Great lecturer, explains complex topics clearly" (来源: [RMP](https://ratemyprofessors.com/professor/XXX))

### 结论
基于 RMP 评分对比 (Listgarten: 2.6/5, Dimakis: 4.2/5, 来源: [RMP](https://ratemyprofessors.com))
和学生反馈，建议重点关注 Dimakis 的讲座内容。
(来源: [eecs189.org](https://eecs189.org), [RMP](https://ratemyprofessors.com))
```

**错误示例 ❌ (禁止！):**
```markdown
## CS 189 教授评价
- "does not really teach"  ← 没有来源！
- RMP 评分 2.6/5  ← 没有来源 URL！

### 结论
除非对 ML 课程内容本身有强烈需求... ← 没有来源！
```

---

```markdown
# 调研报告

## 📋 执行摘要

### 基本信息
- **调研主题**: [N] 个
- **完成状态**: [X]/[Y] 完成
- **验收标准**: [X]/[Y] 满足
- **Ralph 循环**: [N] 次迭代
- **最终 Pass Rate**: [XX]%

### 可信度统计
| 等级 | 数量 | 占比 | 说明 |
|------|------|------|------|
| 🟢 A | X | XX% | 官方一手 |
| 🟢 B | X | XX% | 官方二手 |
| 🟡 C | X | XX% | 半官方 |
| 🟠 D | X | XX% | 社区 |
| 🔴 F | X | XX% | 未验证 |

---

## ⚠️ 来源审计表 (强制 - 用户必须审核)

> **详细审计表见：`.research/source_audit.md`**

### 来源使用汇总

| 来源类型 | 数量 | 使用率 | 用户验收状态 |
|---------|------|--------|-------------|
| 📌 用户指定 | X | 100% | ⏳ 待验收 |
| 🔍 AI 自主发现 | Y | - | ⏳ 待验收 |

### 关键来源列表

| # | 来源名称 | URL | 类型 | 可信度 | 用户验收 |
|---|---------|-----|------|--------|---------|
| 1 | [名称] | [URL] | 📌 | 🟢 A | ☐ |
| 2 | [名称] | [URL] | 🔍 | 🟡 C | ☐ |

---

## 📚 逐主题汇总

### [主题1名称]

#### 基本信息
| 信息 | 内容 | 来源 | 类型 | 可信度 | 获取时间 | 验证 |
|------|------|------|------|--------|---------|------|
| 教授 | XXX | [URL] | 📌 | 🟢 A | 2026-01-26 | ✅ |
| 时间 | MWF 10-11 | [URL] | 📌 | 🟢 A | 2026-01-26 | ✅ |
| 评分 | 4.2/5 | [URL] | 🔍 | 🟡 C | 2026-01-26 | ⚠️ |

#### 未验证信息
| 信息 | 原因 | 建议 |
|------|------|------|
| 期末考试日期 | 官网未公布 | 等待官方通知 |

### [主题2名称]
... (同样格式)

---

## 📊 交叉对比表

| 主题 | 教授 | 时间 | 地点 | 评分 | 工作量 |
|------|------|------|------|------|--------|
| [主题1] | XXX | MWF 10-11 | XXX | 4.2/5 | 中 |
| [主题2] | YYY | TuTh 2-3:30 | YYY | 4.5/5 | 高 |

---

## ⚠️ 冲突检测

### 时间冲突
| 冲突类型 | 主题A | 主题B | 冲突时间 | 严重程度 |
|---------|-------|-------|---------|---------|
| 时间重叠 | MATH 54 | ECON 1 | MWF 10-11 | 🔴 严重 |

### 信息冲突
| 信息 | 来源A | 来源B | 冲突内容 | 处理建议 |
|------|-------|-------|---------|---------|
| [信息] | [URL-A] | [URL-B] | [描述] | 以 A 为准 (可信度更高) |

---

## ❓ 待确认项

| # | 信息 | 原因 | 需要用户做什么 |
|---|------|------|--------------|
| 1 | [信息] | 无法登录验证 | 请用户自行登录确认 |
| 2 | [AI发现来源] 可靠性 | 需用户判定 | 请在 source_audit.md 标记 |

---

## ✅ 验收检查

### 原始需求验收
| # | 验收标准 | 状态 | 来源 | 备注 |
|---|---------|------|------|------|
| AC-1 | [标准1] | ✅ | [URL] | - |
| AC-2 | [标准2] | ⚠️ | - | 部分满足 |
| AC-3 | [标准3] | ❌ | - | 无法获取 |

### 增量需求验收
| # | 验收标准 | 状态 | 来源 | 备注 |
|---|---------|------|------|------|
| AC-I-1 | [增量标准1] | ✅ | [URL] | - |

### 最终验收率
- **原始需求**: X/Y = XX%
- **增量需求**: X/Y = XX%
- **总体验收率**: X/Y = XX%

---

## 📝 幻觉记录 (调研中发现)

| # | 幻觉描述 | 发现时间 | 原因 | 已修正 |
|---|---------|---------|------|--------|
| H-1 | [描述] | [时间] | [原因] | ✅ |

---

## 🔄 Ralph 循环历史

| 迭代 | Pass Rate | 失败项 | 修复行动 |
|------|-----------|--------|---------|
| 1 | 60% | AC-1, AC-3 | 重新搜索来源 |
| 2 | 80% | AC-3 | 交叉验证 |
| 3 | 95% | - | 通过 |

---

## 📎 附件

- `.research/task_plan.md` - PRD 文件
- `.research/source_audit.md` - 来源审计表 (请用户审核)
- `.research/findings/*.md` - 各主题调研结果
- `.research/state.json` - 执行状态
```

---

## 📝 模板：priority.md (优先上下文)

**⚠️ 路径固定为：`.research/memory/priority.md`**
**⚠️ 每次 session 启动必须读取**

```markdown
# 优先上下文 - 每次启动必读

## 核心需求 (从 task_plan.md 同步)

1. [需求1]
2. [需求2]
3. [需求3]

## 验收标准 (从 task_plan.md 同步)

- [ ] AC-1: [标准1]
- [ ] AC-2: [标准2]
- [ ] AC-I-1: [增量标准1]

## 用户指定来源 (📌 必须使用)

- 📌 [来源1]: URL
- 📌 [来源2]: URL

## 禁止行为 (从幻觉记录学习)

- ❌ [禁止行为1]
- ❌ [禁止行为2]

## 当前进度

- **Phase**: [当前阶段]
- **已完成主题**: X/Y
- **Ralph 状态**: [状态]

## 上次中断点

- **中断时间**: [时间]
- **中断原因**: [原因]
- **继续任务**: [任务描述]
```

---

## 📝 Subagent 调研指令模板 (v4.0)

> **v4.0 更新**: 新增教授完整性检查、Source Confidence Rating、内联引用要求

```
你是调研 [{主题名称}] 的研究员。

## 任务
调研关于 [{主题名称}] 的以下信息：
[信息类型列表]

## ⚠️ 用户指定来源（必须使用）
📌 [来源1]: URL - [用途说明]
📌 [来源2]: URL - [用途说明]

## 🚨 教授完整性检查（强制！）

### 第一步：访问课程官网 Staff 页面
在调研任何教授信息之前，必须先：
1. 访问课程官方网站
2. 找到 Staff / People / Instructors 页面
3. 记录**所有**授课教授（不只是第一位！）

### 第二步：记录教授名单
┌─────────────────────────────────────────────────────────────────┐
│ 课程教授完整性检查                                               │
├─────────────────────────────────────────────────────────────────┤
│ 课程官网: https://[课程网站]                                    │
│ Staff 页面 URL: https://[课程网站]/staff                        │
│ 官网显示教授数量: ___ 位                                        │
│ 教授名单: [教授A, 教授B, ...]                                   │
│ 需要独立调研的教授: [全部！]                                    │
└─────────────────────────────────────────────────────────────────┘

### 第三步：每位教授独立调研
❌ 禁止只调研"第一位"或"主教授"
✅ 共同授课的每位教授都需要**同等深度调研**

## 输出要求

### 信息标注（强制）
- **[事实]** 格式：`[事实] 内容 (来源: [网站名](URL)) [Confidence: HIGH/MEDIUM/LOW] [获取时间: YYYY-MM-DD HH:MM]`
- **[推理]** 格式：`[推理] 内容 (依据: 事实1, 事实2) [Confidence: MEDIUM]`
- **[未验证]** 格式：`[未验证] 内容 (原因: ...) [Confidence: UNCERTAIN]`

### Source Confidence Ratings (新增！)
| Rating | 来源类型 | 示例 |
|--------|---------|------|
| 🟢 HIGH | 官方一手 | berkeley.edu, 课程官网 |
| 🟡 MEDIUM | 官方二手/半官方 | Berkeleytime, Ed公告 |
| 🟠 LOW | 社区来源 | Reddit, RateMyProfessor |
| 🔴 UNCERTAIN | 无法验证 | URL失效, 需要登录 |

### 可信度评分 (旧版兼容)
🟢 A (90-100%): 官方一手 | 🟢 B (80-89%): 官方二手 | 🟡 C (60-79%): 半官方 | 🟠 D (40-59%): 社区 | 🔴 F (<40%): 未验证

### 来源标注
📌 用户指定来源 | 🔍 AI自主发现来源

### 诚实原则（最高优先级）
无法获取时直接说明，**绝不猜测**：
❌ 错误："根据规律推测..."
❌ 错误："通常来说..."
✅ 正确："[未验证] XXX (原因: 无法访问/需要登录) [Confidence: UNCERTAIN]"

### 增量需求发现
如果调研中发现用户可能需要的新信息：
1. 在输出末尾标注：`[新需求发现] 描述...`
2. 主 Agent 会询问用户是否加入验收标准

## 输出格式

### 教授完整性检查（必须输出！）
| 课程 | 官网教授数 | 已调研教授 | 状态 |
|------|-----------|-----------|------|
| [课程] | _ | [名单] | ✅/❌ |

### 信息表格
| # | 信息 | 内容 | 来源URL | Confidence | 获取时间 |
|---|------|------|---------|------------|---------|
| 1 | 教授 | XXX | https://... | 🟢 HIGH | 2026-01-26 10:00 |
| 2 | RMP评分 | 2.6/5 | https://... | 🟠 LOW | 2026-01-26 10:05 |

### 未验证信息
| # | 信息 | 原因 | Confidence | 建议 |
|---|------|------|------------|------|
| 1 | 期末日期 | 官网未公布 | 🔴 UNCERTAIN | 等待通知 |

### 新需求发现 (如有)
| # | 描述 | 原因 |
|---|------|------|
| 1 | [新需求] | [为什么认为用户需要] |
```

---

## 🔄 Ralph 迭代验收详解

### 循环架构
```
┌─────────────────────────────────────────────────────────────────────┐
│                    Ralph 循环流程                                    │
├─────────────────────────────────────────────────────────────────────┤
│  iteration = 0                                                       │
│  while iteration < 5 AND pass_rate < 0.95:                          │
│                                                                      │
│    1. READ: 读取 PROMPT.md 验收检查清单                              │
│             读取 task_plan.md 验收标准                               │
│                                                                      │
│    2. CHECK: 逐条检查：                                              │
│       - 来源完整性（所有[事实]有URL）                                │
│       - 信息质量（无未解决[冲突]）                                   │
│       - 需求满足（AC-* 验收标准）                                    │
│       - 报告完整（来源审计表已生成）                                 │
│                                                                      │
│    3. TRACK: 更新 state.json.ralph：                                │
│       - 记录 pass_rate                                               │
│       - 记录失败的验收标准                                           │
│       - 记录修复历史                                                 │
│                                                                      │
│    4. EVALUATE: 计算 pass_rate                                       │
│       pass_rate = 通过检查数 / 总检查数                              │
│                                                                      │
│    5. DECIDE:                                                        │
│       IF pass_rate >= 0.95:                                          │
│         → 输出 "✅ PASSED"，进入 Phase 7                             │
│       ELIF iteration < 5:                                            │
│         → 生成 @fix_plan.md                                          │
│         → 执行修复行动                                               │
│         → iteration++                                                │
│       ELSE:                                                          │
│         → 输出 "⚠️ MAX_ITERATIONS"                                   │
│         → 列出剩余问题供用户决定                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 修复策略优先级
| 问题类型 | 修复策略 | 优先级 | 预期成功率 |
|---------|---------|--------|-----------|
| 缺少来源URL | 重新搜索，使用📌来源 | 🔴 高 | 90% |
| 需求未满足 | 针对性调研 | 🔴 高 | 85% |
| 信息冲突 | 确定权威来源，标注[冲突] | 🟡 中 | 75% |
| 验证失败 | 交叉验证，多源确认 | 🟡 中 | 70% |
| 时效性问题 | 搜索最新信息 | 🟠 低 | 60% |

### 断点条件
- **成功退出**: `pass_rate >= 0.95`
- **最大迭代**: `iteration >= 5`
- **用户中断**: 用户主动停止循环

---

## 💾 Graphiti 持久化详解

### MCP 工具使用

```python
# 添加事实
mcp__graphiti__add_memory(
  name="{主题} - {信息类型}",
  episode_body="[事实] {内容} (来源: URL) [可信度: 等级] [时间: ...]",
  group_id="zero-hallucination-research",
  source="text"
)

# 搜索节点
mcp__graphiti__search_nodes(
  query="主题 信息",
  group_ids=["zero-hallucination-research"],
  max_nodes=10
)

# 搜索事实
mcp__graphiti__search_memory_facts(
  query="主题 信息",
  group_ids=["zero-hallucination-research"],
  max_facts=10
)
```

### Bi-Temporal 冲突处理
1. 新事实进入 → 自动搜索现有记录
2. LLM 判断冲突 → 旧记录设置 expired_at
3. 历史保留可追溯

### 服务配置
```yaml
Python: C:\Users\ROG\graphiti-official\mcp_server\.venv\Scripts\python.exe
Config: C:\Users\ROG\graphiti-official\mcp_server\config\config-gemini-neo4j.yaml
Neo4j: bolt://localhost:7687
Group ID: zero-hallucination-research
```

---

## 🖥️ 多终端 Worktree 模式详解

### 架构
```
主目录 (research-hub/)
├── .research/task_plan.md, worktrees.json, report.md
│
终端 1 → worktree-topic1/.research/findings/topic1.md
终端 2 → worktree-topic2/.research/findings/topic2.md
```

### 命令
```bash
# 创建
/zero-hallucination-research worktree create <topic>

# 列出
/zero-hallucination-research worktree list

# 状态
/zero-hallucination-research worktree status

# 合并
/zero-hallucination-research merge

# 清理
/zero-hallucination-research worktree clean
```

### 合并流程
1. 收集所有 findings/*.md
2. 提取 [事实]/[推理]/[未验证]
3. 交叉验证、检测冲突
4. 生成合并报告 + 来源审计表

---

## 🚀 执行模式详解

### 快速模式（后台并行，无 /chrome）
```
Task 参数:
- subagent_type: "general-purpose"
- run_in_background: true
- 工具: WebSearch, WebFetch, Read, Write
```

### Chrome 模式（前台顺序，支持 /chrome）
```
Task 参数:
- subagent_type: "general-purpose"
- run_in_background: false  # 必须前台！
- 工具: 继承所有 MCP 工具（包括 mcp__claude-in-chrome__*）
```

### 混合模式（推荐）
1. 后台并行收集公开信息
2. 前台顺序收集需登录信息
3. 合并结果

---

## 📋 调研引擎对比

### claude-deep-research（8.5 阶段流水线）
```
Scope → Plan → Retrieve(并行) → Triangulate →
Outline → Synthesize → Critique → Refine → Package
```
适合：结构化数据收集、严格来源验证

### Cranot/deep-research（递归分解）
```
DECOMPOSE → PARALLEL_EXPLORE → SYNTHESIZE → VALIDATE → OUTPUT
```
适合：探索性问题、多角度分析

---

## 📂 完整目录结构

```
.research/
├── task_plan.md           # 📌 PRD：核心需求和验收标准（固定路径！）
├── state.json             # 执行状态 + Phase 检查点 + Ralph 状态
├── report.md              # 最终报告（含来源审计表）
├── source_audit.md        # 来源审计表（独立文件，用户必须审核）
├── PROMPT.md              # Ralph 循环入口指令
├── @fix_plan.md           # Ralph 修复计划
├── findings/              # 各主题调研结果
│   ├── topic_1.md
│   └── topic_2.md
├── versions/              # PRD 版本历史
│   ├── task_plan_v1.0.md
│   └── task_plan_v1.1.md
├── archive/               # 归档（之前的调研）
└── memory/                # 三层记忆
    ├── priority.md        # 优先上下文（每次启动必读）
    ├── working.md         # 工作记忆（7天清理）
    └── permanent.md       # 永久笔记（永不清理）
```

---

## 📋 用户审批门控清单

### Phase 1 → Phase 2 门控
- [ ] 用户已查看 task_plan.md (PRD)
- [ ] 用户确认核心需求正确
- [ ] 用户确认验收标准明确
- [ ] 用户确认指定来源列表完整
- [ ] 用户明确授权开始调研

### Phase 5 → Phase 6 门控
- [ ] 用户已查看 source_audit.md
- [ ] 用户已验证📌指定来源全部使用
- [ ] 用户已判定🔍AI发现来源可靠性
- [ ] 用户已审核信息-来源映射表
- [ ] 用户明确授权进入 Ralph 验收循环

---

## 🧠 Sequential Thinking 集成模板

### Phase 4 三角验证时使用

```markdown
## Sequential Thinking: 冲突分析

### 冲突项
- **信息**: MATH 54 上课时间
- **来源 A**: CalCentral 显示 MWF 10:00-11:00
- **来源 B**: BerkeleyTime 显示 MWF 9:00-10:00

### 思考链
1. **来源可信度比较**
   - CalCentral: 🟢A (官方一手来源)
   - BerkeleyTime: 🟡C (半官方聚合)

2. **时效性比较**
   - CalCentral 获取时间: 2026-01-26 10:30
   - BerkeleyTime 获取时间: 2026-01-26 10:35

3. **推理**
   - CalCentral 是学校官方系统，应优先信任
   - BerkeleyTime 可能数据同步延迟

4. **结论**
   - 采用 CalCentral 数据: MWF 10:00-11:00
   - 标注: [冲突已解决] 采用 🟢A 来源

### 下一步思考
need_more_thinking: false
```

### Phase 6 Ralph 验收时使用

```markdown
## Sequential Thinking: 验收标准检查

### 检查项: AC-1 "所有课程基本信息已收集"

### 思考链
1. **定义解析**
   - "基本信息" = 教授、时间、地点、评分
   - 共 7 门课程

2. **逐课检查**
   | 课程 | 教授 | 时间 | 地点 | 评分 |
   |------|------|------|------|------|
   | MATH 54 | ✅ | ✅ | ✅ | ⚠️ 未验证 |
   | CS 61A | ✅ | ✅ | ✅ | ✅ |
   ...

3. **统计**
   - 完整: 5/7 = 71.4%
   - 缺失: MATH 54 评分, ECON 1 地点

4. **判定**
   - AC-1 状态: ❌ 未通过
   - 原因: 2 门课程信息不完整

### 修复策略
- MATH 54 评分: 搜索 RateMyProfessor
- ECON 1 地点: 重新查询 CalCentral

need_more_thinking: false
```

---

## 📄 PDF 处理模板

### PDF 发现报告模板（Subagent 输出）

```markdown
## 📄 待处理 PDF 列表

### 需要登录下载
| # | 平台 | 文件名 | 预期内容 | 优先级 |
|---|------|--------|---------|-------|
| 1 | bCourses | MATH54_Syllabus.pdf | 课程大纲、评分政策 | 高 |
| 2 | bCourses | MATH54_Schedule.pdf | 考试日期、作业截止 | 高 |

### 可直接下载
| # | URL | 文件名 | 预期内容 | 优先级 |
|---|-----|--------|---------|-------|
| 1 | https://math.berkeley.edu/~prof/notes.pdf | notes.pdf | 补充讲义 | 中 |

### 无法访问
| # | 原因 | 处理建议 |
|---|------|---------|
| 1 | 需要 VPN | 请用户手动下载 |

---
⚠️ 请确认是否下载上述 PDF？
回复 "下载全部" 或指定下载哪些。
```

### PDF 信息提取模板

```markdown
## PDF 信息提取: {文件名}

### 元数据
- **文件**: {文件名}
- **来源**: {平台/URL}
- **下载时间**: {YYYY-MM-DD HH:MM}
- **本地路径**: .research/downloads/{文件名}
- **页数**: {N} 页

### 提取的信息

#### 第 1 页
- [事实] {内容}
  (来源: {文件名}, P.1) [可信度: 🟢A] [获取时间: {时间}]

#### 第 2 页
- [事实] {内容}
  (来源: {文件名}, P.2) [可信度: 🟢A] [获取时间: {时间}]

### 无法提取
- [未验证] {内容} (原因: PDF 图片无法 OCR / 页面模糊)

### 与其他来源交叉验证
| PDF 内容 | 网页内容 | 一致性 |
|---------|---------|-------|
| 考试日期: 5/15 | 考试日期: 5/15 | ✅ 一致 |
| 作业截止: 周五 | 作业截止: 周六 | ❌ 冲突 |
```

### downloads 文件夹结构

```
.research/
├── downloads/           # PDF 下载目录
│   ├── MATH54_Syllabus.pdf
│   ├── MATH54_Schedule.pdf
│   └── manifest.json    # 下载记录
└── ...
```

### manifest.json 模板

```json
{
  "downloads": [
    {
      "filename": "MATH54_Syllabus.pdf",
      "source_url": "https://bcourses.berkeley.edu/...",
      "source_platform": "bCourses",
      "download_time": "2026-01-26T10:30:00Z",
      "local_path": ".research/downloads/MATH54_Syllabus.pdf",
      "file_size": "1.2MB",
      "pages": 5,
      "processed": true,
      "extracted_facts": 12,
      "user_approval": "2026-01-26T10:28:00Z"
    }
  ],
  "pending": [
    {
      "filename": "lecture_notes.pdf",
      "source_url": "https://...",
      "reason_pending": "需要用户确认下载"
    }
  ]
}
```

---

## 🛡️ 防提前完成模板 (Anti-Premature-Completion Templates)

> **来源**: 深度调研 - Claude Code Issues #599, #6159, #4766, #4284; NeurIPS 2025 论文
> **问题**: AI 在 50-60% 完成度时错误停止

### Completion Promise 格式（每个 Phase 完成时必须输出）

```markdown
## ✅ COMPLETION PROMISE - Phase [N]

### 证据清单
- [x] 证据1: [具体内容] - 验证方式: [如何验证]
- [x] 证据2: [具体内容] - 验证方式: [如何验证]

### 文件产出
- [文件路径]: [文件大小/行数] - [内容摘要]

### 下一步
- 即将进入: Phase [N+1]
- 预计操作: [具体描述]

我确认 Phase [N] 已完成，所有证据已提供。
```

### 各 Phase 证据要求表

| Phase | 完成证据 | 验证方式 | 失败处理 |
|-------|---------|---------|---------|
| Phase 0 | Graphiti 返回历史知识 | state.json.graphiti.knowledge_loaded == true | 标记不可用，继续 |
| Phase 0.5 | 用户选择需求类型 | state.json.requirement_type != null | 等待用户选择 |
| Phase 1 | task_plan.md 存在且 >100 字节 | exists && size > 100 | 重新创建 PRD |
| **门控** | **用户批准 PRD** | user_approvals.prd_approval.approved == true | **等待用户确认** |
| Phase 2 | state.json.topics 数组非空 | len(topics) > 0 | 重新规划 |
| Phase 3 | findings/*.md 数量 >= topics 数量 | len(glob) >= len(topics) | 重新调研缺失主题 |
| Phase 4 | working.md 包含冲突分析 | 冲突分析 in working.md | 执行冲突检测 |
| Phase 5 | report.md 包含来源审计表 | 来源审计表 in report.md | 添加审计表 |
| **门控** | **用户审核来源** | source_audit_approval.approved == true | **等待用户审核** |
| Phase 6 | Ralph pass_rate >= 0.95 或 iteration >= 5 | ralph.pass_rate >= 0.95 | 继续 Ralph 循环 |
| Phase 7 | Graphiti 存储成功 | add_memory() 返回成功 | 标记持久化失败 |

### 禁止的完成声明（出现这些词句应触发警告）

- ❌ "我认为已经完成了"
- ❌ "应该已经足够了"
- ❌ "差不多完成了"
- ❌ "主要内容已完成"
- ❌ "基本调研完成（还有剩余 Phase）"
- ❌ 未提供证据的完成声明
- ❌ 在 todo list 还有剩余项时的完成声明

### 正确的暂停声明模板

```markdown
## ⏸️ PAUSE DECLARATION - Phase [N]

### 当前状态
- 已完成: [具体内容]
- 未完成: [具体内容]
- 完成度: [X]% (基于验收标准 [已满足数]/[总数])

### 暂停原因
- [原因描述]

### 恢复所需
- [具体条件]

我确认当前 Phase 未完成，需要 [具体操作] 才能继续。
```

### 研究来源（防提前完成）

| 来源 | URL | 贡献 |
|------|-----|------|
| Claude Code #599 | github.com/anthropics/claude-code-action/issues/599 | 官方确认：50-60% 停止 |
| Claude Code #6159 | github.com/anthropics/claude-code/issues/6159 | 官方确认：伪装完成 |
| NeurIPS 2025 论文 | arxiv.org/abs/2503.13657 | 6.20% 验证不足失败率 |
| Alibaba Ralph Loop | alibabacloud.com/blog/from-react-to-ralph-loop | 外部验证模式 |
| todo.ai | github.com/fxstein/todo.ai | Evidence-Based Validation |
| Anthropic 最佳实践 | anthropic.com/engineering/claude-code-best-practices | 官方建议 |

---

## 🔗 URL 可访问性验证模板

> **问题来源**: 用户反馈报告中的链接失效（如 Math121B 录播链接）
> **根本原因**: AI 声称 URL 有效但实际未验证，或从过时缓存获取

### Phase 4 URL 验证执行流程

```markdown
## URL 验证记录 - [主题名]

### 验证时间: YYYY-MM-DD HH:MM

| # | URL | 验证方式 | HTTP状态 | 内容匹配 | 验证结果 |
|---|-----|---------|---------|---------|---------|
| 1 | https://math.berkeley.edu/~prof | WebFetch | 200 OK | ✅ 包含教授信息 | ✅ 已验证 |
| 2 | https://calcentral.berkeley.edu/... | WebFetch | 401 Unauthorized | - | ⚠️ 需登录 |
| 3 | https://youtube.com/@UCosjeaN7RTLW_qAoNcCiVA | WebFetch | 404 Not Found | - | ❌ 链接失效 |

### 验证失败处理

| # | 原 URL | 失败原因 | 处理方式 | 新状态 |
|---|--------|---------|---------|--------|
| 3 | https://youtube.com/@UCos... | 404 频道不存在 | 降级为 [未验证] | 🔴F |

### 处理记录
- URL #3: 原标注 "[事实] Math121B 有录播" → 修正为 "[未验证] 声称有录播 (原因: 链接失效 404)"
```

### URL 验证状态标注规范

**在每个 URL 后必须添加验证状态：**

```markdown
格式: (来源: URL) [URL验证: 状态]

示例:
(来源: https://math.berkeley.edu/courses/121B) [URL验证: ✅]
(来源: https://calcentral.berkeley.edu/...) [URL验证: ⚠️ 需登录]
(来源: https://youtube.com/@XXX) [URL验证: ❌ 404失效]
```

### 验证状态与可信度映射

| URL验证状态 | 最高允许可信度 | 说明 |
|------------|--------------|------|
| ✅ 已验证 | 🟢A/B | 可根据来源类型评定 |
| ⚠️ 无法验证 | 🟡C | 降一级，需用户确认 |
| ❌ 验证失败 | 🔴F | 强制降级，必须标为 [未验证] |

### 常见失效 URL 类型及处理

| URL 类型 | 常见失效原因 | 检测方法 | 处理方式 |
|---------|------------|---------|---------|
| YouTube 频道 | 频道删除/改名 | WebFetch 404 | 搜索正确频道名 |
| 课程网页 | 学期结束后下线 | WebFetch 404 | 使用 archive.org |
| CalCentral | 需要登录 | WebFetch 401 | 标注 ⚠️，让用户验证 |
| Google Doc | 权限限制 | WebFetch 403 | 标注 ⚠️，让用户验证 |
| RateMyProfessor | 教授页面变更 | WebFetch 404 | 重新搜索教授名 |

### ⛔ 绝对禁止

1. **禁止声称 URL 有效但未执行 WebFetch 验证**
   - 错误: 直接从 WebSearch 结果复制 URL 声称有效
   - 正确: 对每个 URL 执行 WebFetch 验证

2. **禁止对 404 链接仍标注为 [事实]**
   - 错误: `[事实] 有录播 (来源: 失效URL) [可信度: 🟢B]`
   - 正确: `[未验证] 声称有录播 (来源: 失效URL) [URL验证: ❌] [可信度: 🔴F]`

3. **禁止省略 URL 验证状态**
   - 错误: `(来源: URL)`
   - 正确: `(来源: URL) [URL验证: ✅/⚠️/❌]`

---

