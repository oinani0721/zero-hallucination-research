# {{TOPIC_NAME}} 调研结果

## 📋 调研元信息

| 属性 | 值 |
|------|---|
| 主题 ID | {{TOPIC_ID}} |
| 主题名称 | {{TOPIC_NAME}} |
| 调研员 | course-researcher subagent |
| 开始时间 | {{STARTED_AT}} |
| 完成时间 | {{COMPLETED_AT}} |
| 上下文隔离 | ✅ 是（独立 200K token 上下文） |

---

## 📌 基本信息

| 信息类型 | 内容 | 来源 | 标注 | 获取时间 |
|---------|------|------|------|---------|
{{#each BASIC_INFO}}
| {{this.type}} | {{this.content}} | {{this.source}} | {{this.tag}} | {{this.time}} |
{{/each}}

---

## 📚 详细信息

{{#each DETAILED_SECTIONS}}
### {{this.title}}

{{this.content}}

{{/each}}

---

## 📋 来源汇总

### 📌 用户指定来源

#### 已成功访问
{{#each USER_SOURCES_ACCESSED}}
- ✅ {{this.name}}: {{this.url}}
  - 访问时间: {{this.accessed_at}}
  - 获取信息: {{this.info_retrieved}}
{{/each}}

#### 未能访问
{{#each USER_SOURCES_FAILED}}
- ❌ {{this.name}}: {{this.url}}
  - 原因: {{this.reason}}
  - 建议: {{this.suggestion}}
{{/each}}

### 🔍 AI 自主发现来源

{{#each AI_DISCOVERED_SOURCES}}
- 🔍 {{this.name}}: {{this.url}}
  - 可靠性: {{this.reliability}}
  - 注意: {{this.notes}}
{{/each}}

---

## ❓ 未获取的信息

| 信息类型 | 原因 | 建议操作 |
|---------|------|---------|
{{#each MISSING_INFO}}
| {{this.type}} | {{this.reason}} | {{this.suggestion}} |
{{/each}}

---

## ⚠️ 需要用户确认的信息

以下信息需要用户手动验证或确认：

{{#each NEEDS_CONFIRMATION}}
### {{@index}}. {{this.title}}

- **当前信息**: {{this.current}}
- **来源**: {{this.source}}
- **需要确认**: {{this.what_to_confirm}}
- **确认方式**: {{this.how_to_confirm}}

{{/each}}

---

## 💡 发现的新需求

调研过程中发现用户可能需要的额外信息：

{{#each DISCOVERED_NEEDS}}
- [{{this.status}}] {{this.description}}
  - 发现原因: {{this.reason}}
  - 相关信息: {{this.related_info}}
{{/each}}

---

## 🔍 信息可信度评估

| 信息类型 | 可信度 | 来源数量 | 来源类型 | 备注 |
|---------|-------|---------|---------|------|
{{#each CREDIBILITY_ASSESSMENT}}
| {{this.info_type}} | {{this.credibility}} | {{this.source_count}} | {{this.source_types}} | {{this.notes}} |
{{/each}}

### 可信度说明
- ⭐⭐⭐ 高：多个官方来源一致
- ⭐⭐ 中：单一官方来源或多个非官方来源一致
- ⭐ 低：仅有非官方来源或信息存在冲突

---

## ✅ 调研完成度自检

### 必要信息
{{#each REQUIRED_INFO_CHECK}}
- [{{this.status}}] {{this.item}}: {{this.notes}}
{{/each}}

### 来源覆盖
{{#each SOURCE_COVERAGE_CHECK}}
- [{{this.status}}] {{this.source}}: {{this.notes}}
{{/each}}

### 标注完整性
- [{{TAGGING_COMPLETE}}] 所有信息已标注 [事实]/[推理]/[未验证]
- [{{SOURCE_MARKED}}] 所有来源已标注 📌/🔍
- [{{TIME_MARKED}}] 所有 [事实] 已标注获取时间

---

## 📝 调研日志

{{#each RESEARCH_LOG}}
| {{this.time}} | {{this.action}} | {{this.result}} |
{{/each}}
