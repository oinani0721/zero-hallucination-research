# Ralph Wiggum Stop Hook - Windows PowerShell
# 备用脚本：主要使用 Agent Hook，此脚本作为备用验证
#
# 功能：检查 state.json 判断是否允许结束对话
# 退出码：
#   0 = 允许结束
#   2 = 阻止结束（继续 Ralph 循环）

param()

# CRITICAL: First check if we're in a ZHR session
# If no .research/task_plan.md exists, this is NOT a ZHR session - allow exit
if (-not (Test-Path ".research/task_plan.md")) {
    # Not a ZHR session, allow normal exit
    exit 0
}

$stateFile = ".research/state.json"

# Check 1: Output contains completion signal
$output = $env:CLAUDE_OUTPUT
if ($output -match 'RALPH_DONE|PHASE_COMPLETE') {
    Write-Host "[OK] Research complete (RALPH_DONE detected), allowing exit"
    exit 0
}

# Check 2: state.json exists and contains verification data
if (-not (Test-Path $stateFile)) {
    # No state file yet, allow exit (not in Ralph loop)
    Write-Host "[OK] No state.json found, allowing exit"
    exit 0
}

try {
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json

    # Check if ralph_config exists
    if (-not $state.ralph_config) {
        # No Ralph config, not in Ralph mode
        Write-Host "[OK] No ralph_config in state.json, allowing exit"
        exit 0
    }

    # Extract values
    $passRate = if ($state.verify.pass_rate) { $state.verify.pass_rate } else { 0 }
    $iteration = if ($state.verify.iteration) { $state.verify.iteration } else { 0 }
    $maxIterations = if ($state.ralph_config.max_iterations) { $state.ralph_config.max_iterations } else { 15 }
    $exitSignal = if ($state.verify.exit_signal) { $state.verify.exit_signal } else { $false }

    # Decision logic (same as Agent Hook)

    # Condition 1: Exit signal set
    if ($exitSignal -eq $true) {
        Write-Host "[OK] exit_signal is true, allowing exit"
        exit 0
    }

    # Condition 2: Pass rate >= 0.95
    if ($passRate -ge 0.95) {
        Write-Host "[OK] pass_rate >= 0.95 ($([math]::Round($passRate * 100, 1))%), allowing exit"
        exit 0
    }

    # Condition 3: Reached max iterations
    if ($iteration -ge $maxIterations) {
        Write-Host "[WARN] Reached max iterations ($iteration/$maxIterations), allowing exit"
        exit 0
    }

    # Not ready to exit - continue Ralph loop
    $passRatePercent = [math]::Round($passRate * 100, 1)
    Write-Host ""
    Write-Host "======================================================================="
    Write-Host "[Ralph Wiggum] Verification not complete!"
    Write-Host "======================================================================="
    Write-Host "pass_rate: $passRatePercent% (threshold: 95%)"
    Write-Host "iteration: $iteration / $maxIterations"
    Write-Host ""
    Write-Host "Continue Ralph verification loop. Update state.json and output RALPH_DONE when complete."
    Write-Host "======================================================================="
    exit 2

} catch {
    # JSON parse error or other issue
    Write-Host "[WARN] Failed to parse state.json: $_"
    Write-Host "[OK] Allowing exit due to parse error"
    exit 0
}
