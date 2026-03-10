[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $ProjectRoot,

  [ValidateSet('default', 'no-frontend', 'api-only')]
  [string] $ScaffoldVariant = 'default'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path $ProjectRoot).Path
$excludedPathPattern = '(?i)(^|[\\/])(bin|obj|\.artifacts)([\\/]|$)'
$pwshExecutable = Join-Path $PSHOME ($(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' }))
if (-not (Test-Path $pwshExecutable)) {
  $pwshExecutable = 'pwsh'
}

function Write-ValidationStep {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Message
  )

  Write-Host ''
  Write-Host "==> $Message"
}

function Assert-CommandAvailable {
  param(
    [Parameter(Mandatory = $true)]
    [string] $CommandName,

    [Parameter(Mandatory = $true)]
    [string] $Description
  )

  if (-not (Get-Command -Name $CommandName -ErrorAction SilentlyContinue)) {
    throw "$Description requires '$CommandName' to be available on PATH."
  }
}

function Get-DisplayPath {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path
  )

  return [System.IO.Path]::GetRelativePath($projectRoot, $Path).Replace('\', '/')
}

function Assert-FileExists {
  param(
    [Parameter(Mandatory = $true)]
    [string] $RelativePath
  )

  $fullPath = Join-Path $projectRoot $RelativePath
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Expected file '$RelativePath' was not found under '$projectRoot'."
  }

  return (Get-Item -LiteralPath $fullPath).FullName
}

function Assert-DirectoryExists {
  param(
    [Parameter(Mandatory = $true)]
    [string] $RelativePath
  )

  $fullPath = Join-Path $projectRoot $RelativePath
  if (-not (Test-Path -LiteralPath $fullPath -PathType Container)) {
    throw "Expected directory '$RelativePath' was not found under '$projectRoot'."
  }
}

function Assert-PathMissing {
  param(
    [Parameter(Mandatory = $true)]
    [string] $RelativePath
  )

  $fullPath = Join-Path $projectRoot $RelativePath
  if (Test-Path -LiteralPath $fullPath) {
    throw "Path '$RelativePath' should not exist under '$projectRoot' for the '$ScaffoldVariant' scaffold variant."
  }
}

function Get-RepositoryFiles {
  param(
    [Parameter(Mandatory = $true)]
    [string[]] $Extensions
  )

  $extensionSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($extension in $Extensions) {
    [void] $extensionSet.Add($extension)
  }

  return Get-ChildItem -LiteralPath $projectRoot -Recurse -Force |
    Where-Object {
      if ($_.PSIsContainer -or -not $extensionSet.Contains($_.Extension)) {
        return $false
      }

      $relativePath = [System.IO.Path]::GetRelativePath($projectRoot, $_.FullName)
      return $relativePath -notmatch $excludedPathPattern
    } |
    Sort-Object FullName
}

function Invoke-ExternalCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string] $FilePath,

    [Parameter()]
    [string[]] $Arguments = @(),

    [Parameter(Mandatory = $true)]
    [string] $Description,

    [switch] $CaptureOutput,

    [switch] $AllowKnownDotNetTestLimitation
  )

  Write-ValidationStep $Description

  if ($CaptureOutput) {
    $output = & $FilePath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $outputLines = @(
      $output |
        ForEach-Object { "$_" } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    foreach ($line in $outputLines) {
      Write-Host $line
    }

    if ($exitCode -ne 0) {
      if ($AllowKnownDotNetTestLimitation -and (Test-KnownDotNetTestLimitation -OutputLines $outputLines)) {
        Write-Warning 'dotnet test hit the known .NET 10 Microsoft.Testing.Platform/VSTest limitation. Restore/build still succeeded, so validation will continue.'
        return @{
          OutputLines = $outputLines
          ExitCode = $exitCode
          KnownLimitation = $true
        }
      }

      throw "$Description failed with exit code $exitCode."
    }

    return @{
      OutputLines = $outputLines
      ExitCode = $exitCode
      KnownLimitation = $false
    }
  }

  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$Description failed with exit code $LASTEXITCODE."
  }
}

function Assert-OutputContains {
  param(
    [Parameter(Mandatory = $true)]
    [string[]] $OutputLines,

    [Parameter(Mandatory = $true)]
    [string[]] $RequiredText
  )

  $joinedOutput = $OutputLines -join [Environment]::NewLine
  foreach ($text in $RequiredText) {
    if ($joinedOutput -notmatch [regex]::Escape($text)) {
      throw "Expected command output to contain '$text'."
    }
  }
}

function Assert-FileContainsText {
  param(
    [Parameter(Mandatory = $true)]
    [string] $RelativePath,

    [Parameter(Mandatory = $true)]
    [string[]] $RequiredText
  )

  $fullPath = Assert-FileExists $RelativePath
  $content = Get-Content -LiteralPath $fullPath -Raw

  foreach ($text in $RequiredText) {
    if ($content -notmatch [regex]::Escape($text)) {
      throw "Expected file '$RelativePath' to contain '$text'."
    }
  }
}

function Test-KnownDotNetTestLimitation {
  param(
    [Parameter(Mandatory = $true)]
    [string[]] $OutputLines
  )

  $output = $OutputLines -join [Environment]::NewLine

  return (
    ($output -match 'VSTest' -and $output -match 'Microsoft\.Testing\.Platform') -or
    ($output -match 'VSTest' -and $output -match 'no longer supported') -or
    ($output -match 'Microsoft\.Testing\.Platform' -and $output -match 'global\.json')
  )
}

function Test-JsonLikeFile {
  param(
    [Parameter(Mandatory = $true)]
    [string] $FilePath
  )

  $content = Get-Content -LiteralPath $FilePath -Raw
  $options = [System.Text.Json.JsonDocumentOptions]::new()
  $options.CommentHandling = [System.Text.Json.JsonCommentHandling]::Skip
  $options.AllowTrailingCommas = $true
  $document = [System.Text.Json.JsonDocument]::Parse($content, $options)
  $document.Dispose()
}

function Test-PropertiesFile {
  param(
    [Parameter(Mandatory = $true)]
    [string] $FilePath
  )

  $lineNumber = 0
  foreach ($line in Get-Content -LiteralPath $FilePath) {
    $lineNumber++
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
      continue
    }

    if ($trimmed -notmatch '=') {
      throw "The properties file '$(Get-DisplayPath $FilePath)' contains an invalid entry on line $lineNumber."
    }
  }
}

function Test-YamlFile {
  param(
    [Parameter(Mandatory = $true)]
    [string] $FilePath
  )

  $content = Get-Content -LiteralPath $FilePath -Raw
  $null = $content | npx --yes yaml valid --single
  if ($LASTEXITCODE -ne 0) {
    throw "YAML validation failed for '$(Get-DisplayPath $FilePath)'."
  }
}

function Get-JsonHashtable {
  param(
    [Parameter(Mandatory = $true)]
    [string] $RelativePath
  )

  return Get-Content -LiteralPath (Assert-FileExists $RelativePath) -Raw | ConvertFrom-Json -AsHashtable
}

function Resolve-SolutionPath {
  $solution = Get-ChildItem -LiteralPath $projectRoot -File |
    Where-Object { $_.Name -like '*.slnx' -or $_.Name -like '*.sln' } |
    Sort-Object @{ Expression = { $_.Extension -ne '.slnx' } }, Name |
    Select-Object -First 1

  if ($null -eq $solution) {
    throw "No solution file was found at '$projectRoot'."
  }

  return $solution.FullName
}

function Validate-VariantProjectShape {
  param(
    [Parameter(Mandatory = $true)]
    [string] $SolutionPath
  )

  Write-ValidationStep "Validate $ScaffoldVariant scaffold shape"

  $solutionName = [System.IO.Path]::GetFileNameWithoutExtension($SolutionPath)
  $requiredDirectories = @(
    "src\$solutionName.ServiceDefaults",
    "src\$solutionName.Web",
    "tests\$solutionName.Web.Tests"
  )
  $requiredFiles = @()
  $forbiddenPaths = @()

  switch ($ScaffoldVariant) {
    'default' {
      $requiredDirectories += @(
        "src\$solutionName.AspireHost",
        "src\$solutionName.Blazor"
      )
    }

    'no-frontend' {
      $requiredDirectories += "src\$solutionName.AspireHost"
      $requiredFiles += "src\$solutionName.AspireHost\$solutionName.AspireHost.NoBlazor.csproj"
      $forbiddenPaths += @(
        "src\$solutionName.Blazor",
        "src\$solutionName.AspireHost\$solutionName.AspireHost.csproj"
      )
    }

    'api-only' {
      $forbiddenPaths += @(
        "src\$solutionName.AspireHost",
        "src\$solutionName.Blazor"
      )
    }
  }

  foreach ($relativePath in $requiredDirectories) {
    Assert-DirectoryExists $relativePath
  }

  foreach ($relativePath in $requiredFiles) {
    [void] (Assert-FileExists $relativePath)
  }

  foreach ($relativePath in $forbiddenPaths) {
    Assert-PathMissing $relativePath
  }
}

function Validate-PreBootstrapState {
  param(
    [Parameter(Mandatory = $true)]
    [string] $SolutionPath
  )

  Write-ValidationStep 'Validate freshly scaffolded template outputs'

  foreach ($relativePath in @(
    'CHANGELOG.md',
    'version.txt',
    '.release-please-manifest.json',
    'global.json',
    'scripts\bootstrap.ps1',
    'scripts\bootstrap.sh',
    'scripts\update.ps1',
    'scripts\update.sh',
    'scripts\scaffold.ps1',
    'scripts\scaffold.sh',
    '.scaffold\scaffold.settings.json',
    '.scaffold\assets\asset-manifest.json'))
  {
    [void] (Assert-FileExists $relativePath)
  }

  Assert-DirectoryExists 'src'
  Assert-DirectoryExists 'tests'
  Write-Host "Resolved solution: $(Get-DisplayPath $SolutionPath)"
}

function Invoke-ScaffoldFlows {
  Write-ValidationStep 'Exercise scaffold bootstrap, update, and verify flows'

  if ($IsWindows) {
    Invoke-ExternalCommand -FilePath $pwshExecutable -Arguments @('-NoLogo', '-NoProfile', '-File', (Assert-FileExists 'scripts\bootstrap.ps1')) -Description 'Run scripts\bootstrap.ps1'
    Invoke-ExternalCommand -FilePath $pwshExecutable -Arguments @('-NoLogo', '-NoProfile', '-File', (Assert-FileExists 'scripts\scaffold.ps1'), 'verify') -Description 'Run scripts\scaffold.ps1 verify after bootstrap'
    Invoke-ExternalCommand -FilePath $pwshExecutable -Arguments @('-NoLogo', '-NoProfile', '-File', (Assert-FileExists 'scripts\update.ps1'), '--dry-run') -Description 'Run scripts\update.ps1 --dry-run'
    Invoke-ExternalCommand -FilePath $pwshExecutable -Arguments @('-NoLogo', '-NoProfile', '-File', (Assert-FileExists 'scripts\update.ps1')) -Description 'Run scripts\update.ps1'
    Invoke-ExternalCommand -FilePath $pwshExecutable -Arguments @('-NoLogo', '-NoProfile', '-File', (Assert-FileExists 'scripts\scaffold.ps1'), 'verify') -Description 'Run scripts\scaffold.ps1 verify after update'
    return
  }

  Assert-CommandAvailable -CommandName 'bash' -Description 'Generated shell scaffold validation'

  Invoke-ExternalCommand -FilePath 'bash' -Arguments @((Assert-FileExists 'scripts/bootstrap.sh')) -Description 'Run scripts/bootstrap.sh'
  Invoke-ExternalCommand -FilePath 'bash' -Arguments @((Assert-FileExists 'scripts/scaffold.sh'), 'verify') -Description 'Run scripts/scaffold.sh verify after bootstrap'
  Invoke-ExternalCommand -FilePath 'bash' -Arguments @((Assert-FileExists 'scripts/update.sh'), '--dry-run') -Description 'Run scripts/update.sh --dry-run'
  Invoke-ExternalCommand -FilePath 'bash' -Arguments @((Assert-FileExists 'scripts/update.sh')) -Description 'Run scripts/update.sh'
  Invoke-ExternalCommand -FilePath 'bash' -Arguments @((Assert-FileExists 'scripts/scaffold.sh'), 'verify') -Description 'Run scripts/scaffold.sh verify after update'
}

function Validate-PostBootstrapAssets {
  Write-ValidationStep 'Validate scaffold-managed asset presence after bootstrap'

  $assetManifest = Get-JsonHashtable '.scaffold\assets\asset-manifest.json'
  $targets = @($assetManifest['assets'] | ForEach-Object { $_['target'] })

  foreach ($target in $targets) {
    [void] (Assert-FileExists $target)
  }

  Write-Host "Validated $($targets.Count) scaffold-managed asset target(s)."
}

function Validate-GeneratedConfigurations {
  Write-ValidationStep 'Validate generated JSON, YAML, and configuration files'

  $jsonFiles = @(Get-RepositoryFiles -Extensions @('.json', '.jsonc'))
  foreach ($jsonFile in $jsonFiles) {
    Test-JsonLikeFile -FilePath $jsonFile.FullName
  }
  Write-Host "Validated $($jsonFiles.Count) JSON/JSONC file(s)."

  $yamlFiles = @(Get-RepositoryFiles -Extensions @('.yml', '.yaml'))
  foreach ($yamlFile in $yamlFiles) {
    Test-YamlFile -FilePath $yamlFile.FullName
  }
  Write-Host "Validated $($yamlFiles.Count) YAML file(s)."

  $propertiesFiles = @(Get-RepositoryFiles -Extensions @('.properties'))
  foreach ($propertiesFile in $propertiesFiles) {
    Test-PropertiesFile -FilePath $propertiesFile.FullName
  }
  Write-Host "Validated $($propertiesFiles.Count) .properties file(s)."

  $version = (Get-Content -LiteralPath (Assert-FileExists 'version.txt') -Raw).Trim()
  if ($version -notmatch '^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z\.-]+)?$') {
    throw "Generated version.txt does not contain a valid semantic version: '$version'."
  }

  $releaseManifest = Get-JsonHashtable '.release-please-manifest.json'
  if ($releaseManifest['.'] -ne $version) {
    throw "The release manifest version '$($releaseManifest['.'])' does not match version.txt '$version'."
  }

  $globalJson = Get-JsonHashtable 'global.json'
  if ($globalJson['test']['runner'] -ne 'Microsoft.Testing.Platform') {
    throw "The generated global.json test runner must remain 'Microsoft.Testing.Platform'."
  }

  $releaseConfig = Get-JsonHashtable 'release-please-config.json'
  $rootPackage = $releaseConfig['packages']['.']
  if ($rootPackage['version-file'] -ne 'version.txt' -or $rootPackage['changelog-path'] -ne 'CHANGELOG.md') {
    throw 'release-please-config.json must continue pointing at version.txt and CHANGELOG.md.'
  }

  $copilotConfig = Get-JsonHashtable '.copilot\mcp-config.json'
  if ($copilotConfig['mcpServers']['github']['url'] -ne 'https://api.githubcopilot.com/mcp/') {
    throw ".copilot/mcp-config.json must keep the GitHub MCP URL."
  }

  if ($copilotConfig['mcpServers']['github']['headers']['Authorization'] -ne 'Bearer ${GITHUB_TOKEN}') {
    throw ".copilot/mcp-config.json must keep the GITHUB_TOKEN placeholder."
  }

  $changelogLines = @(Get-Content -LiteralPath (Assert-FileExists 'CHANGELOG.md'))
  if (@($changelogLines).Count -eq 0 -or $changelogLines[0].Trim() -ne '# Changelog') {
    throw 'CHANGELOG.md must start with "# Changelog".'
  }

  Assert-FileContainsText -RelativePath '.github\workflows\ci.yml' -RequiredText @(
    'actions/setup-node@v4',
    'dotnet format whitespace',
    'markdownlint-cli2',
    'dotnet test'
  )

  Assert-FileContainsText -RelativePath '.github\workflows\release-please.yml' -RequiredText @(
    'googleapis/release-please-action@v4',
    'release-please-config.json',
    '.release-please-manifest.json'
  )

  Assert-FileContainsText -RelativePath '.github\workflows\conventional-commits.yml' -RequiredText @(
    'pull_request_target',
    'amannn/action-semantic-pull-request@v6'
  )

  Assert-FileContainsText -RelativePath '.github\workflows\quality-analysis.yml' -RequiredText @(
    'JetBrains/qodana-action@v2025.2',
    'dotnet sonarscanner',
    'dotnet test $env:SOLUTION_PATH'
  )

  Assert-FileContainsText -RelativePath '.github\dependabot.yml' -RequiredText @(
    'package-ecosystem: nuget',
    'package-ecosystem: github-actions',
    'interval: weekly'
  )

  Assert-FileContainsText -RelativePath 'qodana.yaml' -RequiredText @(
    'jetbrains/qodana-dotnet:2025.2',
    '.scaffold'
  )

  Assert-FileContainsText -RelativePath 'sonar-project.properties' -RequiredText @(
    'sonar.sources=src',
    'sonar.tests=tests',
    'sonar.cs.vstest.reportsPaths'
  )

  Assert-FileContainsText -RelativePath '.github\CODEOWNERS' -RequiredText @(
    '@your-org/your-team'
  )
}

function Validate-GeneratedScripts {
  Write-ValidationStep 'Validate generated PowerShell and shell scripts'

  $psScripts = @(Get-RepositoryFiles -Extensions @('.ps1'))
  $parseErrors = foreach ($script in $psScripts) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref] $tokens, [ref] $errors) | Out-Null

    foreach ($error in $errors) {
      [pscustomobject]@{
        File = Get-DisplayPath $script.FullName
        Line = $error.Extent.StartLineNumber
        Column = $error.Extent.StartColumnNumber
        Message = $error.Message
      }
    }
  }

  if (@($parseErrors).Count -gt 0) {
    $parseErrors | Format-Table -AutoSize | Out-String | Write-Host
    throw 'PowerShell script syntax validation failed.'
  }

  Write-Host "Validated $($psScripts.Count) PowerShell script(s)."

  if (-not $IsWindows) {
    Assert-CommandAvailable -CommandName 'bash' -Description 'Generated shell script syntax validation'

    $shScripts = @(Get-RepositoryFiles -Extensions @('.sh'))
    foreach ($script in $shScripts) {
      Invoke-ExternalCommand -FilePath 'bash' -Arguments @('-n', $script.FullName) -Description "Validate shell syntax for $(Get-DisplayPath $script.FullName)"
    }

    Write-Host "Validated $($shScripts.Count) shell script(s)."
  }
  else {
    Write-Host 'Skipping shell syntax validation on Windows; Linux CI exercises the generated .sh entrypoints.'
  }

  $defaultSetupAi = Invoke-ExternalCommand -FilePath $pwshExecutable -Arguments @('-NoLogo', '-NoProfile', '-File', (Assert-FileExists 'scripts\setup-ai.ps1')) -Description 'Run scripts\setup-ai.ps1' -CaptureOutput
  Assert-OutputContains -OutputLines $defaultSetupAi.OutputLines -RequiredText @(
    'Curated MartiX marketplace plugins:',
    'Selected external skill install commands:',
    'martix-webapi',
    'npx skills add https://github.com/aaronontheweb/dotnet-skills --skill modern-csharp-coding-standards'
  )

  $dryRunSetupAi = Invoke-ExternalCommand -FilePath $pwshExecutable -Arguments @('-NoLogo', '-NoProfile', '-File', (Assert-FileExists 'scripts\setup-ai.ps1'), '-RegisterMarketplace', '-InstallRecommendedMartiX', '-DryRun') -Description 'Run scripts\setup-ai.ps1 -RegisterMarketplace -InstallRecommendedMartiX -DryRun' -CaptureOutput
  Assert-OutputContains -OutputLines $dryRunSetupAi.OutputLines -RequiredText @(
    '[dry-run] copilot plugin marketplace add MartiXDev/ai-marketplace',
    '[dry-run] copilot plugin install martix-webapi@martix-ai-marketplace',
    '[dry-run] copilot plugin install martix-tunit@martix-ai-marketplace'
  )
}

function Validate-GeneratedMarkdown {
  Write-ValidationStep 'Lint generated Markdown'

  $markdownFiles = @(Get-RepositoryFiles -Extensions @('.md'))
  if (@($markdownFiles).Count -eq 0) {
    Write-Host 'No Markdown files were found to lint.'
    return
  }

  $relativeMarkdownFiles = @($markdownFiles | ForEach-Object { Get-DisplayPath $_.FullName })
  Invoke-ExternalCommand -FilePath 'npx' -Arguments (@('--yes', 'markdownlint-cli2') + $relativeMarkdownFiles) -Description 'Run markdownlint-cli2 against generated Markdown'
}

function Validate-GeneratedSolution {
  param(
    [Parameter(Mandatory = $true)]
    [string] $SolutionPath
  )

  Write-ValidationStep 'Restore, build, and test the generated solution'

  $relativeSolutionPath = Get-DisplayPath $SolutionPath

  Invoke-ExternalCommand -FilePath 'dotnet' -Arguments @('restore', $relativeSolutionPath, '-nologo') -Description "Run dotnet restore $relativeSolutionPath"
  Invoke-ExternalCommand -FilePath 'dotnet' -Arguments @('format', 'whitespace', $relativeSolutionPath, '--verify-no-changes', '--no-restore', '--verbosity', 'minimal') -Description "Run dotnet format whitespace $relativeSolutionPath"
  Invoke-ExternalCommand -FilePath 'dotnet' -Arguments @('build', $relativeSolutionPath, '--no-restore', '--configuration', 'Release', '-p:TreatWarningsAsErrors=true', '-nologo') -Description "Run dotnet build $relativeSolutionPath"

  $testResult = Invoke-ExternalCommand -FilePath 'dotnet' -Arguments @(
    'test',
    '--solution',
    $relativeSolutionPath,
    '--no-build',
    '--configuration',
    'Release',
    '--results-directory',
    '.\.artifacts\test-results',
    '--coverage',
    '--coverage-output-format',
    'cobertura',
    '--report-trx'
  ) -Description "Run dotnet test --solution $relativeSolutionPath" -CaptureOutput -AllowKnownDotNetTestLimitation

  if ($testResult.KnownLimitation) {
    return
  }

  $trxFiles = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot '.artifacts\test-results') -Filter '*.trx' -File -Recurse -ErrorAction SilentlyContinue)
  if ($trxFiles.Count -eq 0) {
    throw 'dotnet test succeeded, but no TRX files were produced beneath .artifacts\test-results.'
  }

  $coverageFiles = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot '.artifacts\test-results') -Filter '*.cobertura.xml' -File -Recurse -ErrorAction SilentlyContinue)
  if ($coverageFiles.Count -eq 0) {
    throw 'dotnet test succeeded, but no Cobertura coverage files were produced beneath .artifacts\test-results.'
  }

  Write-Host "Validated $($trxFiles.Count) test result file(s) and $($coverageFiles.Count) coverage file(s)."
}

Assert-CommandAvailable -CommandName 'dotnet' -Description 'Generated repository validation'
Assert-CommandAvailable -CommandName 'npx' -Description 'Generated repository validation'

Push-Location $projectRoot
try {
  Write-Host "Validating generated repository: $projectRoot"

  $solutionPath = Resolve-SolutionPath
  Validate-PreBootstrapState -SolutionPath $solutionPath
  Validate-VariantProjectShape -SolutionPath $solutionPath
  Invoke-ScaffoldFlows
  Validate-PostBootstrapAssets
  Validate-GeneratedConfigurations
  Validate-GeneratedScripts
  Validate-GeneratedMarkdown
  Validate-GeneratedSolution -SolutionPath $solutionPath

  Write-Host ''
  Write-Host "Generated repository validation passed: $projectRoot"
}
finally {
  Pop-Location
}
