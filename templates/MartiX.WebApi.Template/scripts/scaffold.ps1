[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('bootstrap', 'update', 'verify')]
  [string] $Command,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $Arguments
)

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$projectPath = Join-Path $repoRoot '.scaffold\src\MartiX.WebApi.Template.Scaffold\MartiX.WebApi.Template.Scaffold.csproj'

if (-not (Test-Path $projectPath)) {
  throw "Scaffold runner project was not found at '$projectPath'."
}

$normalizedArguments = foreach ($argument in $Arguments) {
  switch -Regex ($argument) {
    '^-DryRun$' { '--dry-run'; continue }
    '^-RepoRoot$' { '--repo-root'; continue }
    '^-Var$' { '--var'; continue }
    default { $argument }
  }
}

$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = 'dotnet'
$startInfo.WorkingDirectory = $repoRoot
$startInfo.UseShellExecute = $false
$startInfo.ArgumentList.Add('run')
$startInfo.ArgumentList.Add('--project')
$startInfo.ArgumentList.Add($projectPath)
$startInfo.ArgumentList.Add('--')
$startInfo.ArgumentList.Add($Command)
$startInfo.ArgumentList.Add('--repo-root')
$startInfo.ArgumentList.Add($repoRoot)

foreach ($argument in $normalizedArguments) {
  $startInfo.ArgumentList.Add($argument)
}

$process = [System.Diagnostics.Process]::Start($startInfo)
$process.WaitForExit()
exit $process.ExitCode
