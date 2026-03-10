[CmdletBinding()]
param(
  [string] $SampleName = 'SampleApp',
  [string] $OutputRoot = 'bin\generated-assets',
  [string] $OutputPath,
  [switch] $KeepExisting
)

$resolvedOutputPath = if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  Join-Path $OutputRoot $SampleName
}
else {
  $OutputPath
}

& (Join-Path $PSScriptRoot 'generated-assets.ps1') refresh -SampleName $SampleName -OutputPath $resolvedOutputPath -KeepExisting:$KeepExisting
exit $LASTEXITCODE
