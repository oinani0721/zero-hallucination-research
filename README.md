# 零幻觉多主题并行调研（企业级增强版）

一个为 Claude Code 设计的深度调研 Skill，整合多种调研引擎和持久化记忆，确保信息可追溯、零幻觉、上下文隔离。

## ✨ 核心特性

| 特性 | 说明 |
|------|------|
| 🔍 **双引擎调研** | claude-deep-research (8.5阶段) + Cranot/deep-research (递归分解) |
| 🧠 **持久化记忆** | Graphiti 时序知识图谱，跨会话可查询 |
| 🔒 **零幻觉保证** | `[事实]/[推理]/[未验证]` 强制标注 + CiteGuard 验证 |
| 📌 **来源透明** | 用户指定 📌 vs AI 发现 🔍 明确区分 |
| 🔄 **迭代验收** | Ralph Wiggum 循环，直到满足验收标准 |
| 💾 **断点续传** | 中断后可自动恢复 |
| 🌐 **多模式支持** | 快速模式（并行）/ Chrome 模式（登录）/ 混合模式 |
| 🖥️ **多终端并行** | Worktree 隔离 + 自动合并 + 冲突检测 |

## 🚀 快速开始

### 1. 安装依赖

```powershell
# Windows
.\setup.ps1

# 或手动安装
pip install graphiti-core[kuzu]
pip install deep-research-cli
```

### 2. 配置 Claude Code 插件（可选）

```bash
# Superpowers (用于 brainstorm)
/plugin install superpowers@superpowers-marketplace

# Ralph Wiggum (用于迭代验收)
/plugin install ralph-wiggum
```

### 3. 验证 Graphiti MCP

```bash
claude mcp list
# 应该看到 graphiti 服务
```

## 📖 使用方式

### 基本用法

```bash
/zero-hallucination-research "UC Berkeley 7门课程: MATH 54, CS 61A, ECON 1..."
```

### 指定模式

```bash
# 快速模式：后台并行，适合公开信息
/zero-hallucination-research --mode=fast "主题"

# Chrome 模式：前台顺序，支持登录网站
/zero-hallucination-research --mode=chrome "主题"

# 混合模式（推荐）：先并行后顺序
/zero-hallucination-research --mode=mixed "主题"
```

### 指定调研引擎

```bash
# 结构化调研（8.5阶段流水线）
/zero-hallucination-research --engine=claude-deep "主题"

# 探索性调研（递归分解）
/zero-hallucination-research --engine=cranot "主题"

# 自动选择（默认）
/zero-hallucination-research "主题"
```

### 子命令

```bash
/zero-hallucination-research status    # 查看进度
/zero-hallucination-research resume    # 恢复调研
/zero-hallucination-research report    # 查看报告
/zero-hallucination-research verify    # 验收检查
/zero-hallucination-research graphiti  # 查询知识图谱
```

### 多终端 Worktree 命令

```bash
# 创建独立 worktree（在主目录执行）
/zero-hallucination-research worktree create math54
/zero-hallucination-research worktree create cs61a
/zero-hallucination-research worktree create econ1

# 查看所有 worktrees 状态
/zero-hallucination-research worktree list
/zero-hallucination-research worktree status

# 合并所有 worktrees（所有终端完成后执行）
/zero-hallucination-research merge

# 指定路径合并
/zero-hallucination-research merge --worktrees="path1,path2,path3"

# 清理已完成的 worktrees
/zero-hallucination-research worktree clean
```

### 多终端工作流示例

```bash
# 步骤 1：在主目录创建 worktrees
cd ~/research-hub
/zero-hallucination-research worktree create math54
/zero-hallucination-research worktree create cs61a

# 步骤 2：每个终端独立调研（并行运行）
# 终端 1:
cd ../worktree-math54 && claude
/zero-hallucination-research --mode=chrome "MATH 54"

# 终端 2:
cd ../worktree-cs61a && claude
/zero-hallucination-research --mode=chrome "CS 61A"

# 步骤 3：所有终端完成后，回到主目录合并
cd ../research-hub && claude
/zero-hallucination-research merge
```

## 🏗️ 系统架构

```
Phase 0: 需求明确化 (Superpowers brainstorm)
    ↓
Phase 1-2: Scope + Plan (task_plan.md + state.json)
    ↓
Phase 3: 深度调研 (claude-deep-research 或 Cranot)
    ↓
Phase 4-5: 验证 + 合成 (CiteGuard + report.md)
    ↓
Phase 6: 迭代验收 (Ralph Wiggum 循环)
    ↓
Phase 7: 持久化 (Graphiti 知识图谱)
    ↓
Phase 8: 断点续传 (state.json 恢复)
    ↓
Phase 9: 多终端 Worktree 模式 (创建/合并/冲突检测)
```

### 多终端架构

```
主目录 (research-hub/)
├── .research/
│   ├── worktrees.json        ← Worktree 注册表
│   └── report.md             ← 合并后的最终报告
│
├── worktree-math54/          ← 终端 1（/chrome 可用）
│   └── .research/findings/
│
├── worktree-cs61a/           ← 终端 2（/chrome 可用）
│   └── .research/findings/
│
└── worktree-econ1/           ← 终端 3（/chrome 可用）
    └── .research/findings/
```

## 📁 文件结构

```
.research/
├── task_plan.md          # 任务计划 + 验收标准
├── state.json            # 执行状态（用于断点续传）
├── worktrees.json        # Worktree 注册表（多终端模式）
├── report.md             # 最终报告 / 合并报告
├── findings/
│   ├── topic_1.md        # 主题1调研结果
│   └── topic_2.md        # 主题2调研结果
├── memory/
│   ├── priority.md       # 优先上下文（每次必读）
│   ├── working.md        # 工作记忆（7天清理）
│   └── permanent.md      # 永久笔记
└── deep-research-output/ # 深度调研引擎输出

# Skill 模板文件
~/.claude/skills/zero-hallucination-research/templates/
├── task_plan.template.md       # 任务计划模板
├── findings.template.md        # 发现记录模板
├── worktrees.template.json     # Worktree 注册表模板
└── merge-report.template.md    # 合并报告模板
```

## ⚠️ 重要限制

### MCP 工具限制

**官方文档确认：MCP 工具（如 /chrome）在后台 subagent 中不可用。**

| 模式 | 并行性 | /chrome 支持 | 说明 |
|------|-------|-------------|------|
| 快速模式 | ✅ 后台并行 | ❌ | 适合纯公开信息 |
| Chrome 模式 | ❌ 前台顺序 | ✅ | 适合单主题深度调研 |
| 混合模式 | ⚠️ 部分并行 | ✅ | 推荐：公开+登录结合 |
| **多终端模式** | ✅ **真并行** | ✅ | **解决方案：每个终端独立** |

### 多终端模式的优势

多终端 Worktree 模式是解决 "并行 + /chrome" 需求的**唯一完整方案**：

```
┌────────────────────────────────────────────────────────────────┐
│  每个终端 = 独立进程 = 独立 /chrome = 真正并行                   │
├────────────────────────────────────────────────────────────────┤
│  终端 1: worktree-math54 + /chrome → CalCentral MATH 54        │
│  终端 2: worktree-cs61a  + /chrome → CalCentral CS 61A         │
│  终端 3: worktree-econ1  + /chrome → CalCentral ECON 1         │
│  ...（同时运行，互不干扰）                                       │
├────────────────────────────────────────────────────────────────┤
│  最后: /zero-hallucination-research merge → 合并 + 冲突检测     │
└────────────────────────────────────────────────────────────────┘
```

### 调研引擎对比

| 引擎 | 适用场景 | 特点 |
|------|---------|------|
| claude-deep-research | 结构化数据收集 | 8.5阶段流水线，CiteGuard 内置 |
| Cranot/deep-research | 探索性问题 | 递归分解，多模型交叉验证 |

## 📝 信息标注规范

### 强制标注

```markdown
- [事实] 内容 (来源: URL) [获取时间: 2026-01-25 14:00]
- [推理] 内容 (依据: 事实1, 事实2)
- [未验证] 内容 (原因: 无法访问/信息过时)
```

### 来源标注

```markdown
- 📌 用户指定来源：用户明确要求使用的网站
- 🔍 AI 自主发现：AI 搜索发现的来源（需用户确认）
```

## 🔧 配置文件

### Graphiti MCP 配置

```json
// ~/.claude/mcp/mcp.json
{
  "graphiti": {
    "command": "python",
    "args": ["-m", "graphiti.mcp_server"],
    "env": {
      "GRAPHITI_DB_TYPE": "kuzu",
      "GRAPHITI_DB_PATH": "~/.claude/graphiti-db"
    }
  }
}
```

### 全局规则

见 `~/.claude/CLAUDE.md` 中的"零幻觉调研规则"部分。

## 🤝 相关工具

- [Superpowers](https://github.com/obra/superpowers) - brainstorm + /write-plan
- [Ralph Wiggum](https://github.com/anthropics/claude-code) - 迭代验收循环
- [Graphiti](https://github.com/getzep/graphiti) - 时序知识图谱
- [Planning with Files](https://github.com/OthmanAdi/planning-with-files) - 文件持久化
- [claude-deep-research-skill](https://github.com/199-biotechnologies/claude-deep-research-skill) - 8.5阶段调研
- [Cranot/deep-research](https://github.com/Cranot/deep-research) - 递归调研

## 📄 License

MIT
