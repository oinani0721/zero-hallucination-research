# 优先修复计划

**生成时间**: {{timestamp}}
**Ralph 迭代**: {{iteration}} / {{max_iterations}}

---

## 🔴 关键问题（必须修复）

{{#each critical_issues}}
### 问题 {{@index}}: {{title}}

- **类型**: {{type}}
- **位置**: {{location}}
- **内容**: {{content}}
- **修复策略**: {{fix_strategy}}
- **预期成功率**: {{success_rate}}

{{/each}}

{{#unless critical_issues}}
✅ 无关键问题
{{/unless}}

---

## 🟡 次要问题（建议修复）

{{#each minor_issues}}
- [ ] {{description}}
  - 位置: {{location}}
  - 建议: {{suggestion}}

{{/each}}

{{#unless minor_issues}}
✅ 无次要问题
{{/unless}}

---

## ✅ 已修复问题

{{#each fixed_issues}}
- [x] {{description}}
  - 修复时间: {{fixed_at}}
  - 修复方式: {{fix_method}}

{{/each}}

{{#unless fixed_issues}}
（暂无已修复问题）
{{/unless}}

---

## 📈 修复进度

| 迭代 | 修复数量 | 剩余数量 | 成功率 |
|------|---------|---------|--------|
{{#each fix_history}}
| {{iteration}} | {{fixed}} | {{remaining}} | {{success_rate}} |
{{/each}}

---

## 🎯 本次迭代目标

1. {{primary_goal}}
2. {{secondary_goal}}

---

*自动生成于 Ralph 迭代循环 - 请勿手动编辑*
