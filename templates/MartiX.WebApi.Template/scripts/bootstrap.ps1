[CmdletBinding()]
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $Arguments
)

& (Join-Path $PSScriptRoot 'scaffold.ps1') bootstrap @Arguments
exit $LASTEXITCODE
