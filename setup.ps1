# Zero-Hallucination Research Skill - 安装脚本 (Windows PowerShell)
# 运行方式: .\setup.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  零幻觉调研系统 - 安装向导" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Python
Write-Host "[1/6] 检查 Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  ✓ Python 已安装: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Python 未安装，请先安装 Python 3.10+" -ForegroundColor Red
    exit 1
}

# 检查 pip
Write-Host "[2/6] 检查 pip..." -ForegroundColor Yellow
try {
    $pipVersion = pip --version 2>&1
    Write-Host "  ✓ pip 已安装" -ForegroundColor Green
} catch {
    Write-Host "  ✗ pip 未安装" -ForegroundColor Red
    exit 1
}

# 安装 Graphiti
Write-Host "[3/6] 安装 Graphiti (本地模式)..." -ForegroundColor Yellow
pip install graphiti-core[kuzu] --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Graphiti 已安装 (kuzu 后端)" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Graphiti 安装失败，请手动运行: pip install graphiti-core[kuzu]" -ForegroundColor Yellow
}

# 安装 Cranot/deep-research
Write-Host "[4/6] 安装 Cranot/deep-research..." -ForegroundColor Yellow
pip install deep-research-cli --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ deep-research-cli 已安装" -ForegroundColor Green
} else {
    Write-Host "  ⚠ deep-research-cli 安装可选，如需递归调研请手动安装" -ForegroundColor Yellow
}

# 配置 Graphiti MCP
Write-Host "[5/6] 配置 Graphiti MCP..." -ForegroundColor Yellow
$mcpDir = "$env:USERPROFILE\.claude\mcp"
$mcpConfig = "$mcpDir\mcp.json"

# 创建目录
if (-not (Test-Path $mcpDir)) {
    New-Item -ItemType Directory -Path $mcpDir -Force | Out-Null
}

# 创建或更新 mcp.json
$graphitiConfig = @{
    graphiti = @{
        command = "python"
        args = @("-m", "graphiti.mcp_server")
        type = "stdio"
        disabled = $false
        env = @{
            GRAPHITI_DB_TYPE = "kuzu"
            GRAPHITI_DB_PATH = "$env:USERPROFILE\.claude\graphiti-db"
            GRAPHITI_LLM_PROVIDER = "anthropic"
        }
    }
}

if (Test-Path $mcpConfig) {
    # 合并现有配置
    $existingConfig = Get-Content $mcpConfig | ConvertFrom-Json -AsHashtable
    $existingConfig["graphiti"] = $graphitiConfig.graphiti
    $existingConfig | ConvertTo-Json -Depth 10 | Set-Content $mcpConfig
    Write-Host "  ✓ Graphiti MCP 配置已添加到现有 mcp.json" -ForegroundColor Green
} else {
    # 创建新配置
    $graphitiConfig | ConvertTo-Json -Depth 10 | Set-Content $mcpConfig
    Write-Host "  ✓ Graphiti MCP 配置已创建" -ForegroundColor Green
}

# 创建 Graphiti 数据库目录
$graphitiDbDir = "$env:USERPROFILE\.claude\graphiti-db"
if (-not (Test-Path $graphitiDbDir)) {
    New-Item -ItemType Directory -Path $graphitiDbDir -Force | Out-Null
    Write-Host "  ✓ Graphiti 数据库目录已创建" -ForegroundColor Green
}

# 提示安装 Claude Code 插件
Write-Host "[6/6] Claude Code 插件安装提示..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  请在 Claude Code 中手动执行以下命令：" -ForegroundColor White
Write-Host ""
Write-Host "  # 安装 Superpowers 插件 (可选，用于 brainstorm)" -ForegroundColor Gray
Write-Host "  /plugin marketplace add obra/superpowers-marketplace" -ForegroundColor Cyan
Write-Host "  /plugin install superpowers@superpowers-marketplace" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # 安装 Ralph Wiggum 插件 (可选，用于迭代验收)" -ForegroundColor Gray
Write-Host "  /plugin marketplace add anthropics/ralph-wiggum" -ForegroundColor Cyan
Write-Host "  /plugin install ralph-wiggum" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # 验证 Graphiti MCP 连接" -ForegroundColor Gray
Write-Host "  claude mcp list" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "使用方式：" -ForegroundColor White
Write-Host "  /zero-hallucination-research '调研主题'" -ForegroundColor Cyan
Write-Host ""
Write-Host "查看帮助：" -ForegroundColor White
Write-Host "  /zero-hallucination-research --help" -ForegroundColor Cyan
Write-Host ""
