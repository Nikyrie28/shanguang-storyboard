$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $scriptDir

$gitExe = "C:\Program Files\Git\cmd\git.exe"
if (-not (Test-Path -LiteralPath $gitExe)) {
    Write-Host "未找到 Git: $gitExe" -ForegroundColor Red
    exit 1
}

$insideRepo = & $gitExe rev-parse --is-inside-work-tree 2>$null
if ($insideRepo -ne "true") {
    Write-Host "当前目录不是 Git 仓库: $scriptDir" -ForegroundColor Red
    exit 1
}

$branch = (& $gitExe branch --show-current).Trim()
if ([string]::IsNullOrWhiteSpace($branch)) {
    Write-Host "无法识别当前分支，请先切回正常分支后再同步。" -ForegroundColor Red
    exit 1
}

# 只拦截已跟踪文件的改动，未跟踪文件通常不会阻止拉取。
$trackedChanges = & $gitExe status --porcelain --untracked-files=no
if ($trackedChanges) {
    Write-Host "检测到你本地还有未提交的已跟踪修改，已停止同步以免覆盖冲突。" -ForegroundColor Yellow
    Write-Host ""
    & $gitExe status --short
    Write-Host ""
    Write-Host "请先提交、暂存，或手动处理这些改动后再运行脚本。" -ForegroundColor Yellow
    exit 1
}

Write-Host "正在从 GitHub 拉取最新内容..." -ForegroundColor Cyan
& $gitExe pull origin $branch

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "同步失败，请检查上面的 Git 输出。" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "同步完成，当前分支: $branch" -ForegroundColor Green
& $gitExe rev-parse --short HEAD
