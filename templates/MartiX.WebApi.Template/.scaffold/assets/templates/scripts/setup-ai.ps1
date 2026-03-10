<#
.SYNOPSIS
Lists and optionally installs opt-in MartiX AI recommendations for this repo.

.DESCRIPTION
Keeps generated repositories declaration-first. The script can list curated
MartiX marketplace plugins, register the MartiX marketplace with Copilot CLI,
install explicitly selected MartiX plugins, and print selected external
skills.sh install commands. Nothing runs unless you invoke it.

.PARAMETER ListRecommendations
Shows the curated MartiX plugin list and selected external recommendations.

.PARAMETER RegisterMarketplace
Registers the MartiX AI marketplace with the Copilot CLI.

.PARAMETER InstallRecommendedMartiX
Installs the curated MartiX plugin set for this repository.

.PARAMETER Plugins
Installs only the specified MartiX plugin names. Supports comma-separated input.

.PARAMETER PrintExternalSkillCommands
Prints selected npx skills add commands for external recommendations.

.PARAMETER MarketplaceSource
Overrides the source passed to copilot plugin marketplace add.

.PARAMETER MarketplaceName
Overrides the marketplace name used for copilot plugin install.

.PARAMETER DryRun
Prints commands without executing them.

.EXAMPLE
.\scripts\setup-ai.ps1

.EXAMPLE
.\scripts\setup-ai.ps1 -RegisterMarketplace -InstallRecommendedMartiX -DryRun

.EXAMPLE
.\scripts\setup-ai.ps1 -RegisterMarketplace -Plugins martix-webapi,martix-tunit
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [switch]$ListRecommendations,

    [Parameter()]
    [switch]$RegisterMarketplace,

    [Parameter()]
    [switch]$InstallRecommendedMartiX,

    [Parameter()]
    [string[]]$Plugins,

    [Parameter()]
    [switch]$PrintExternalSkillCommands,

    [Parameter()]
    [string]$MarketplaceSource = 'MartiXDev/ai-marketplace',

    [Parameter()]
    [string]$MarketplaceName = 'martix-ai-marketplace',

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$recommendedMartiXPlugins = @(
    [pscustomobject]@{
        Name = 'martix-webapi'
        Why  = 'Primary MartiX.WebApi planning and implementation guidance.'
    },
    [pscustomobject]@{
        Name = 'martix-dotnet-csharp'
        Why  = '.NET 10 and C# 14 baseline implementation and modernization help.'
    },
    [pscustomobject]@{
        Name = 'martix-fastendpoints'
        Why  = 'FastEndpoints endpoint design, contracts, and testing guidance.'
    },
    [pscustomobject]@{
        Name = 'martix-fluentvalidation'
        Why  = 'Validator authoring and ASP.NET Core integration guidance.'
    },
    [pscustomobject]@{
        Name = 'martix-tunit'
        Why  = 'TUnit authoring, migration, and test-structure guidance.'
    }
)

$externalRecommendations = @(
    [pscustomobject]@{
        Name    = 'modern-csharp-coding-standards'
        Source  = 'aaronontheweb/dotnet-skills'
        Why     = 'Useful baseline coding conventions for modern .NET repositories.'
        Command = 'npx skills add https://github.com/aaronontheweb/dotnet-skills --skill modern-csharp-coding-standards'
    },
    [pscustomobject]@{
        Name    = 'efcore-patterns'
        Source  = 'aaronontheweb/dotnet-skills'
        Why     = 'Helpful for EF Core modeling and query patterns.'
        Command = 'npx skills add https://github.com/aaronontheweb/dotnet-skills --skill efcore-patterns'
    },
    [pscustomobject]@{
        Name    = 'dotnet-project-structure'
        Source  = 'aaronontheweb/dotnet-skills'
        Why     = 'Useful for maintaining project and solution organization.'
        Command = 'npx skills add https://github.com/aaronontheweb/dotnet-skills --skill dotnet-project-structure'
    },
    [pscustomobject]@{
        Name    = 'frontend-design'
        Source  = 'anthropics/skills'
        Why     = 'Useful when iterating on the generated Blazor frontend.'
        Command = 'npx skills add https://github.com/anthropics/skills --skill frontend-design'
    },
    [pscustomobject]@{
        Name    = 'skill-creator'
        Source  = 'anthropics/skills'
        Why     = 'Useful when extracting repository-specific reusable skills later.'
        Command = 'npx skills add https://github.com/anthropics/skills --skill skill-creator'
    }
)

function Format-CommandLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter()]
        [string[]]$Arguments = @()
    )

    if (@($Arguments).Count -eq 0) {
        return $Command
    }

    $formattedArguments = foreach ($argument in $Arguments) {
        if ($argument -match '\s') {
            '"{0}"' -f $argument
        }
        else {
            $argument
        }
    }

    return '{0} {1}' -f $Command, ($formattedArguments -join ' ')
}

function Assert-CopilotCliAvailable {
    if ($DryRun) {
        return
    }

    if (-not (Get-Command -Name 'copilot' -ErrorAction SilentlyContinue)) {
        throw 'Copilot CLI was not found on PATH. Install it first or rerun with -DryRun.'
    }
}

function Invoke-ToolCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter()]
        [string[]]$Arguments = @(),

        [Parameter(Mandatory = $true)]
        [string]$ActionDescription
    )

    $commandLine = Format-CommandLine -Command $Command -Arguments $Arguments

    if ($DryRun) {
        Write-Host "[dry-run] $commandLine"
        return
    }

    if (-not $PSCmdlet.ShouldProcess($commandLine, $ActionDescription)) {
        return
    }

    & $Command @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $commandLine"
    }
}

function Show-Recommendations {
    Write-Host 'Curated MartiX marketplace plugins:'
    foreach ($plugin in $recommendedMartiXPlugins) {
        Write-Host ("- {0}: {1}" -f $plugin.Name, $plugin.Why)
    }

    Write-Host ''
    Write-Host 'Selected external skill recommendations:'
    foreach ($skill in $externalRecommendations) {
        Write-Host ("- {0} ({1}): {2}" -f $skill.Name, $skill.Source, $skill.Why)
    }

    Write-Host ''
    Write-Host 'References:'
    Write-Host '- docs\AI-SKILLS.md'
    Write-Host '- https://github.com/MartiXDev/ai-marketplace'
    Write-Host '- https://github.com/MartiXDev/ai-marketplace/blob/main/docs/recommended-skills.md'
}

$hasExplicitAction =
    $ListRecommendations -or
    $RegisterMarketplace -or
    $InstallRecommendedMartiX -or
    $PSBoundParameters.ContainsKey('Plugins') -or
    $PrintExternalSkillCommands

if (-not $hasExplicitAction) {
    $ListRecommendations = $true
    $PrintExternalSkillCommands = $true
}

if ($ListRecommendations) {
    Show-Recommendations
    Write-Host ''
    Write-Host 'Examples:'
    Write-Host '.\scripts\setup-ai.ps1 -RegisterMarketplace -InstallRecommendedMartiX -DryRun'
    Write-Host '.\scripts\setup-ai.ps1 -RegisterMarketplace -Plugins martix-webapi,martix-tunit'
}

if ($PrintExternalSkillCommands) {
    Write-Host ''
    Write-Host 'Selected external skill install commands:'
    foreach ($skill in $externalRecommendations) {
        Write-Host $skill.Command
    }
}

$requestedPlugins = @()
if ($InstallRecommendedMartiX) {
    $requestedPlugins += @($recommendedMartiXPlugins.Name)
}

if ($PSBoundParameters.ContainsKey('Plugins')) {
    $requestedPlugins += @(
        $Plugins |
            ForEach-Object { $_ -split ',' } |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

$deduplicatedPlugins = [System.Collections.Generic.List[string]]::new()
$seenPluginNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($pluginName in $requestedPlugins) {
    if ($seenPluginNames.Add($pluginName)) {
        $deduplicatedPlugins.Add($pluginName)
    }
}

$requestedPlugins = @($deduplicatedPlugins)

if ($RegisterMarketplace -or @($requestedPlugins).Count -gt 0) {
    Assert-CopilotCliAvailable
}

if ($RegisterMarketplace) {
    Invoke-ToolCommand `
        -Command 'copilot' `
        -Arguments @('plugin', 'marketplace', 'add', $MarketplaceSource) `
        -ActionDescription 'Register the MartiX Copilot marketplace'
}

if (@($requestedPlugins).Count -gt 0) {
    $curatedPluginNames = @($recommendedMartiXPlugins.Name)
    $nonCuratedPlugins = @($requestedPlugins | Where-Object { $_ -notin $curatedPluginNames })

    if ($nonCuratedPlugins.Count -gt 0) {
        $warningMessage = (
            "These plugin names are not in the curated default list: {0}. " +
            'The Copilot CLI will validate them at install time.'
        ) -f ($nonCuratedPlugins -join ', ')

        Write-Warning $warningMessage
    }

    foreach ($pluginName in $requestedPlugins) {
        Invoke-ToolCommand `
            -Command 'copilot' `
            -Arguments @('plugin', 'install', "$pluginName@$MarketplaceName") `
            -ActionDescription 'Install MartiX Copilot plugin'
    }
}
