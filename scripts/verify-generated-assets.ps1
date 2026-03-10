[CmdletBinding()]
param(
  [string] $SampleName = 'SampleApp',
  [string] $OutputRoot = 'bin\generated-assets',
  [string] $OutputPath,
  [switch] $KeepOutput,
  [switch] $KeepProject
)

$resolvedKeepOutput = $KeepOutput -or $KeepProject
$resolvedOutputPath = if ([string]::IsNullOrWhiteSpace($OutputPath) -and $resolvedKeepOutput) {
  Join-Path $OutputRoot $SampleName
}
else {
  $OutputPath
}

& (Join-Path $PSScriptRoot 'generated-assets.ps1') verify -SampleName $SampleName -OutputPath $resolvedOutputPath -KeepOutput:$resolvedKeepOutput
exit $LASTEXITCODE
