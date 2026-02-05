# PRD Approval Check Hook - Windows PowerShell
# Check if PRD is approved before allowing research tools

if (Test-Path ".research/state.json") {
    $content = Get-Content ".research/state.json" -Raw -ErrorAction SilentlyContinue
    if ($content -match '"approved":\s*true') {
        Write-Host "[zero-hallucination] PRD approved, allowing execution"
        exit 0
    } else {
        Write-Host ""
        Write-Host "[BLOCKED] PRD not approved! Cannot execute research tools!"
        Write-Host "Please use AskUserQuestion tool to get user approval first"
        exit 2
    }
} elseif (Test-Path ".research/task_plan.md") {
    Write-Host ""
    Write-Host "[BLOCKED] PRD found but no state.json! Need user approval!"
    Write-Host "Please use AskUserQuestion tool to get user approval first"
    exit 2
} else {
    Write-Host "[zero-hallucination] Reminder: All information must include source"
    exit 0
}
