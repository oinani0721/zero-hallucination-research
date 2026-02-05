# 多终端调研合并报告

## 📋 执行摘要

- **合并时间**: {{merge_time}}
- **调研主题**: {{topic_count}} 个
- **Worktrees 使用**: {{worktree_list}}
- **完成状态**: {{completed_count}}/{{total_count}} 完成
- **冲突数量**: {{conflict_count}} 个
- **待确认项**: {{pending_count}} 个

---

## 📚 逐主题汇总

{{#each topics}}
### {{name}}

**来源 Worktree**: `{{worktree_path}}`
**调研完成时间**: {{completed_at}}

#### 已验证信息

| 信息类型 | 内容 | 来源 | 获取时间 | 状态 |
|---------|------|------|---------|------|
{{#each verified_facts}}
| {{type}} | {{content}} | {{source}} | {{timestamp}} | ✅ |
{{/each}}

#### 推理信息

{{#each inferences}}
- [推理] {{content}} (依据: {{basis}})
{{/each}}

#### 未验证信息

{{#each unverified}}
- [未验证] {{content}} (原因: {{reason}})
{{/each}}

#### 来源追溯

**📌 用户指定来源**:
{{#each user_sources}}
- {{this}}
{{/each}}

**🔍 AI 自主发现**:
{{#each ai_sources}}
- {{this}} (待用户确认可靠性)
{{/each}}

---

{{/each}}

## 📊 交叉对比表

| 主题 | {{#each comparison_headers}}{{this}} | {{/each}}
|------|{{#each comparison_headers}}------|{{/each}}
{{#each comparison_rows}}
| {{topic}} | {{#each values}}{{this}} | {{/each}}
{{/each}}

---

## ⚠️ 冲突检测

### 时间冲突

{{#if time_conflicts}}
{{#each time_conflicts}}
- ❌ **{{topic_a}}** ({{time_a}}) 与 **{{topic_b}}** ({{time_b}}) 冲突
{{/each}}
{{else}}
✅ 无时间冲突
{{/if}}

### 先修课程问题

{{#if prerequisite_issues}}
{{#each prerequisite_issues}}
- ⚠️ **{{course}}** 要求先修 **{{prerequisite}}**，但你尚未完成
{{/each}}
{{else}}
✅ 无先修课程问题
{{/if}}

### 信息冲突

{{#if info_conflicts}}
{{#each info_conflicts}}
- [冲突] **{{topic}}** 的 **{{info_type}}**:
  {{#each sources}}
  - {{worktree}} 说：{{content}}
  {{/each}}
  - **请手动确认哪个正确**
{{/each}}
{{else}}
✅ 无信息冲突
{{/if}}

---

## ❓ 待确认项

{{#if pending_items}}
{{#each pending_items}}
{{@index}}. [{{type}}] {{content}} (原因: {{reason}})
{{/each}}
{{else}}
✅ 无待确认项
{{/if}}

---

## ✅ 验收检查

| 验收标准 | 状态 | 说明 |
|---------|------|------|
{{#each acceptance_criteria}}
| {{criterion}} | {{status_icon}} | {{note}} |
{{/each}}

---

## 📝 增量需求记录

调研过程中发现的新需求：

{{#each incremental_requirements}}
- [{{status}}] {{description}}
{{/each}}

---

## 🔗 Worktree 详情

| 名称 | 路径 | 分支 | 状态 | 创建时间 | 完成时间 |
|------|------|------|------|---------|---------|
{{#each worktrees}}
| {{name}} | {{path}} | {{branch}} | {{status_icon}} | {{created_at}} | {{completed_at}} |
{{/each}}

---

*报告生成时间: {{merge_time}}*
*使用 zero-hallucination-research skill*
