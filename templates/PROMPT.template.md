# 调研验收循环指令

<!-- RALPH_STATUS -->
**Current Status**: PENDING
**Iteration**: 0/5
**Last Updated**: {{timestamp}}
<!-- /RALPH_STATUS -->

## 📋 验收标准检查清单

### 核心需求
{{#each core_requirements}}
- [ ] {{this}}
{{/each}}

### 信息质量
- [ ] 所有 [事实] 都有来源 URL
- [ ] 所有 [未验证] 都标注了原因
- [ ] 无未解决的 [冲突]

### 来源透明
- [ ] 用户指定来源 📌 全部使用
- [ ] AI 自主发现来源 🔍 已标明

## 📊 检查结果

### 核心需求满足度
| 需求 | 状态 | 说明 |
|------|------|------|
{{#each requirement_status}}
| {{name}} | {{status}} | {{note}} |
{{/each}}

### 信息质量统计
- 有来源的事实数量: {{facts_with_source}} / {{total_facts}}
- 未验证信息数量: {{unverified_count}}
- 未解决冲突数量: {{conflict_count}}

### 来源使用统计
- 用户指定来源: {{user_sources_used}} / {{user_sources_total}}
- AI 自主发现来源: {{ai_sources_count}}

## 🔧 当前阶段任务

{{#if has_fix_plan}}
请参考 @fix_plan.md 中的修复计划
{{else}}
无待修复问题
{{/if}}

## ➡️ 下一步行动

{{#if all_passed}}
✅ **所有验收标准满足，调研完成！**

输出: `<completion-promise>COMPLETE</completion-promise>`
{{else}}
❌ **存在以下问题需要修复：**

{{#each pending_issues}}
{{@index}}. {{this}}
{{/each}}

执行修复后，更新 RALPH_STATUS 并重新检查。
{{/if}}

---

*Ralph 自主验收循环 - 由 zero-hallucination-research skill 驱动*
