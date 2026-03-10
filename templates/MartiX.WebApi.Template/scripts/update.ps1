[CmdletBinding()]
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $Arguments
)

& (Join-Path $PSScriptRoot 'scaffold.ps1') update @Arguments
exit $LASTEXITCODE
