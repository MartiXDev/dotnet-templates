[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('refresh', 'verify')]
  [string] $Command,

  [string] $SampleName = 'SampleApp',
  [string] $OutputPath,
  [switch] $KeepOutput,
  [switch] $KeepExisting
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$hiveRoot = Join-Path $env:TEMP ('martix-template-hive-' + [Guid]::NewGuid().ToString('N'))
$defaultRefreshPath = Join-Path $repoRoot (Join-Path 'bin' (Join-Path 'generated-assets' $SampleName))
$sampleRoot = if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  if ($Command -eq 'refresh') { $defaultRefreshPath } else { Join-Path $env:TEMP ('martix-generated-assets-' + [Guid]::NewGuid().ToString('N')) }
}
else {
  if ([System.IO.Path]::IsPathRooted($OutputPath)) { $OutputPath } else { Join-Path $repoRoot $OutputPath }
}

try {
  if ($Command -eq 'refresh' -and -not $KeepExisting -and (Test-Path $sampleRoot)) {
    Remove-Item $sampleRoot -Recurse -Force
  }

  New-Item -ItemType Directory -Path $hiveRoot -Force | Out-Null

  & dotnet new install $repoRoot --debug:custom-hive $hiveRoot
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to install the local template into the isolated hive."
  }

  & dotnet new martix-webapi -n $SampleName -o $sampleRoot --force --debug:custom-hive $hiveRoot
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to scaffold sample repository '$SampleName'."
  }

  & (Join-Path $PSScriptRoot 'validate-generated-repo.ps1') -ProjectRoot $sampleRoot

  Write-Host "$Command completed for generated sample: $sampleRoot"
}
finally {
  if (Test-Path $hiveRoot) {
    Remove-Item $hiveRoot -Recurse -Force
  }

  if ($Command -eq 'verify' -and -not $KeepOutput -and (Test-Path $sampleRoot)) {
    Remove-Item $sampleRoot -Recurse -Force
  }
}
