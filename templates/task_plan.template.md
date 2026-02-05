# 调研任务计划

## 元信息
- **创建时间**: {{CREATED_AT}}
- **最后更新**: {{UPDATED_AT}}
- **状态**: {{STATUS}}

---

## 🎯 核心需求

### 调研目标
{{RESEARCH_GOAL}}

### 需要收集的信息
{{#each INFO_TYPES}}
- [ ] {{this}}
{{/each}}

---

## ✅ 验收标准

{{#each ACCEPTANCE_CRITERIA}}
- [ ] {{this}}
{{/each}}

---

## 📌 用户指定来源

以下来源是用户明确要求使用的，**必须优先访问**：

| 来源名称 | URL | 状态 | 备注 |
|---------|-----|------|------|
{{#each USER_SOURCES}}
| 📌 {{this.name}} | {{this.url}} | {{this.status}} | {{this.notes}} |
{{/each}}

---

## 📋 调研主题列表

| # | 主题 ID | 主题名称 | 状态 | Subagent | 开始时间 | 完成时间 |
|---|--------|---------|------|----------|---------|---------|
{{#each TOPICS}}
| {{@index}} | {{this.id}} | {{this.name}} | {{this.status}} | {{this.subagent}} | {{this.started}} | {{this.completed}} |
{{/each}}

### 状态说明
- ⏳ 待开始
- 🔄 进行中
- ✅ 已完成
- ❌ 失败
- ⏸️ 暂停

---

## 📝 增量需求记录

调研过程中发现的新需求会追加到这里。

### 已确认追加
{{#each INCREMENTAL_CONFIRMED}}
- [✅ 已追加] {{this.description}} (发现于: {{this.discovered_at}}, 来源: {{this.source}})
{{/each}}

### 待用户确认
{{#each INCREMENTAL_PENDING}}
- [❓ 待确认] {{this.description}} (发现于: {{this.discovered_at}}, 来源: {{this.source}})
{{/each}}

### 用户拒绝
{{#each INCREMENTAL_REJECTED}}
- [❌ 已拒绝] {{this.description}} (原因: {{this.reason}})
{{/each}}

---

## 🔍 幻觉记录

记录调研过程中发现的潜在幻觉或需要验证的信息。

| 时间 | 主题 | 内容 | 来源 | 验证状态 |
|------|------|------|------|---------|
{{#each HALLUCINATION_LOG}}
| {{this.time}} | {{this.topic}} | {{this.content}} | {{this.source}} | {{this.verification}} |
{{/each}}

---

## 📊 进度汇总

- **总主题数**: {{TOTAL_TOPICS}}
- **已完成**: {{COMPLETED_TOPICS}}
- **进行中**: {{IN_PROGRESS_TOPICS}}
- **待开始**: {{PENDING_TOPICS}}
- **失败**: {{FAILED_TOPICS}}

### 完成百分比
```
[{{PROGRESS_BAR}}] {{PROGRESS_PERCENT}}%
```

---

## 📅 时间线

{{#each TIMELINE}}
- **{{this.time}}**: {{this.event}}
{{/each}}

---

## 💾 恢复信息

如果调研中断，可以从以下状态恢复：

- **当前阶段**: {{CURRENT_PHASE}}
- **下一步操作**: {{NEXT_ACTION}}
- **状态文件**: `.research/state.json`
