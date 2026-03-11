# Template validation guide

## Purpose

This guide documents how to validate the template repository as it
exists today and how to verify that scaffold automation documentation
matches actual generated output.

Use it when:

- changing template source files
- updating documentation about generated assets
- validating a release candidate locally
- validating generated bootstrap/update assets

## Validation scope

The repository currently validates through the template product flow itself:

1. build the template pack project
2. optionally pack the template into a `.nupkg`
3. install the template locally
4. scaffold a fresh sample repository
5. exercise the generated bootstrap, update, and verify entrypoints
6. validate generated Markdown, AI setup, JSON/JSONC/YAML/config files,
   and release/governance assets
7. build and test the scaffolded solution
8. optionally run the Aspire host or API host

Because scaffold-managed repo assets are now part of the generated
output, validation should also confirm that the generated docs,
governance files, and bootstrap/update entrypoints are present and
usable.

The GitHub Actions validation matrix exercises the default,
`--frontend none`, and `--orchestrator none` scaffolds on both Windows
and Linux.

## Prerequisites

Required:

- .NET 10 SDK or later

Recommended for full local smoke tests:

- container runtime for Aspire-host execution
- a clean temporary directory for sample scaffolds
- Node.js 20 or later for the generated Markdown and YAML validation helpers
- PowerShell 7 when you want the same maintainer validation flow on
  Linux/macOS that CI runs

## Repository baseline checks

From the repository root:

PowerShell:

```powershell
dotnet build .\MartiX.Dotnet.Templates.csproj -nologo
dotnet test .\MartiX.Dotnet.Templates.csproj -nologo
```

Shell:

```sh
dotnet build ./MartiX.Dotnet.Templates.csproj -nologo
dotnet test ./MartiX.Dotnet.Templates.csproj -nologo
```

Expected result today:

- `dotnet build` succeeds
- `dotnet test` succeeds without discovering template-repo tests,
  because the pack project itself is not a test project

That second point is still useful as a sanity check because it confirms
the repository-level project graph restores and evaluates correctly.

## Pack and install validation

### 1. Pack the template

PowerShell:

```powershell
dotnet pack .\MartiX.Dotnet.Templates.csproj -o .\bin\Release -nologo
```

Shell:

```sh
dotnet pack ./MartiX.Dotnet.Templates.csproj -o ./bin/Release -nologo
```

Verify that a package such as
`MartiX.Dotnet.Templates.<version>.nupkg` is created in `bin\Release\`.
Use the version emitted by the root pack project; do not infer it from
`templates\MartiX.WebApi.Template\version.txt`, which belongs to the
generated-repository Release Please baseline.

### 2. Install from repository root or package

PowerShell:

```powershell
dotnet new install .
```

Shell:

```sh
dotnet new install .
```

Use the shell path when `dotnet` is available in the target shell
environment.

Alternative package install:

PowerShell:

```powershell
dotnet new install .\bin\Release\MartiX.Dotnet.Templates.<version>.nupkg
```

Shell:

```sh
dotnet new install ./bin/Release/MartiX.Dotnet.Templates.<version>.nupkg
```

### 3. Confirm the template is visible

PowerShell:

```powershell
dotnet new list martix-webapi
dotnet new martix-webapi --help
```

Shell:

```sh
dotnet new list martix-webapi
dotnet new martix-webapi --help
```

Verify that:

- the short name is `martix-webapi`
- the template is identified as `MartiX Web API Template`
- the documented `Framework`, `frontend`, and `orchestrator` options are exposed
- the defaults remain aligned to the golden path (`frontend=blazor`, `orchestrator=aspire`)

## Root package release process

This section covers publishing the repository-root
`MartiX.Dotnet.Templates` package. Do not confuse it with the generated
repository Release Please baseline under `templates\MartiX.WebApi.Template\`;
those files seed each scaffolded repository's own release history and are
validated later in this guide.

### Root release metadata and workflow

The repository-root release state for the template pack is:

- `release-please-config.json` - Release Please configuration for the root
  package. It uses the `simple` release strategy and points at the root
  `version.txt` and `CHANGELOG.md`.
- `.release-please-manifest.json` - Release Please state file that tracks the
  last released root package version.
- `version.txt` - the source of truth for the package version. The root
  `MartiX.Dotnet.Templates.csproj` reads this file into `Version` and
  `PackageVersion` during build and pack.
- `CHANGELOG.md` - the root package changelog that Release Please updates when
  it prepares a release.
- `.github\workflows\release.yml` - the root release workflow. Its
  `release-please` job creates or updates the release pull request and, when a
  release is created, the `prepare-package` job restores, builds, tests, packs,
  uploads the `.nupkg`, exchanges GitHub OIDC for a short-lived NuGet API key,
  and pushes the package to nuget.org.

### Required GitHub and nuget.org configuration

The publish job in `.github\workflows\release.yml` depends on these settings:

- GitHub Actions environment: `release`
  - The `prepare-package` job runs in this environment.
  - Use it for any optional approval gates or environment-scoped variables.
- GitHub variable: `NUGET_USER`
  - Set this either on the `release` environment or at repository scope.
  - Use the nuget.org profile name that owns or publishes
    `MartiX.Dotnet.Templates`; do not use an email address.
- nuget.org Trusted Publishing policy for `MartiXDev/dotnet-templates`
  - Repository Owner: `MartiXDev`
  - Repository: `dotnet-templates`
  - Workflow File: `release.yml` (file name only, not the
    `.github/workflows/` path)
  - Environment: `release`

Keep the GitHub variable, release environment, and trusted publishing policy in
sync. If any of those values change, update the workflow and documentation
together before attempting another publish.

### Release Please maintainer flow

The intended root-package release flow is:

1. Merge Conventional Commit-formatted changes into `main` or `master`.
2. The `release-please` job in `.github\workflows\release.yml` opens or updates
   a release pull request using the root `release-please-config.json`.
3. Review that release pull request. Release Please should update the root
   `version.txt`, `CHANGELOG.md`, and `.release-please-manifest.json`.
4. Merge the release pull request. Release Please creates the release tag and
   GitHub Release for the root package version.
5. The `prepare-package` job runs only when
   `needs.release-please.outputs.release_created == 'true'`, checks out the
   release tag, and publishes `MartiX.Dotnet.Templates` to nuget.org through
   trusted publishing.

Manual `workflow_dispatch` runs are supported only from `main` or `master`. The
workflow explicitly rejects manual runs from other branches.

Before merging a release-triggering change, run the repository-root baseline
checks from this guide plus the pack command from
[Pack and install validation](#pack-and-install-validation). If the same change
also affects the generated repository contract, additionally run
`.\scripts\verify-generated-assets.ps1` or `./scripts/verify-generated-assets.sh`.

## Scaffold validation

From the repository root, scaffold the default plus the supported
reduced variants into a clean temporary directory, then run the
maintainer validator with the matching scaffold variant:

PowerShell:

```powershell
$validationRoot = Join-Path $env:TEMP 'martix-template-validation'
New-Item -ItemType Directory -Path $validationRoot -Force | Out-Null
dotnet new martix-webapi -n SampleApp -o (Join-Path $validationRoot 'SampleApp')
dotnet new martix-webapi -n SampleAppNoFrontend `
  --frontend none `
  -o (Join-Path $validationRoot 'SampleAppNoFrontend')
dotnet new martix-webapi -n SampleAppApiOnly `
  --orchestrator none `
  -o (Join-Path $validationRoot 'SampleAppApiOnly')
.\scripts\validate-generated-repo.ps1 `
  -ProjectRoot (Join-Path $validationRoot 'SampleApp') `
  -ScaffoldVariant default
.\scripts\validate-generated-repo.ps1 `
  -ProjectRoot (Join-Path $validationRoot 'SampleAppNoFrontend') `
  -ScaffoldVariant no-frontend
.\scripts\validate-generated-repo.ps1 `
  -ProjectRoot (Join-Path $validationRoot 'SampleAppApiOnly') `
  -ScaffoldVariant api-only
```

Shell:

```sh
validation_root="$(mktemp -d)"
dotnet new martix-webapi -n SampleApp -o "$validation_root/SampleApp"
dotnet new martix-webapi -n SampleAppNoFrontend \
  --frontend none \
  -o "$validation_root/SampleAppNoFrontend"
dotnet new martix-webapi -n SampleAppApiOnly \
  --orchestrator none \
  -o "$validation_root/SampleAppApiOnly"
./scripts/validate-generated-repo.sh \
  --project-root "$validation_root/SampleApp" \
  --variant default
./scripts/validate-generated-repo.sh \
  --project-root "$validation_root/SampleAppNoFrontend" \
  --variant no-frontend
./scripts/validate-generated-repo.sh \
  --project-root "$validation_root/SampleAppApiOnly" \
  --variant api-only
```

## Expected generated assets

After scaffolding the default path, verify that the following exist:

- `SampleApp.slnx`
- `Directory.Packages.props`
- `src\SampleApp.Web\`
- `src\SampleApp.ServiceDefaults\`
- `src\SampleApp.AspireHost\`
- `src\SampleApp.Blazor\`
- `tests\SampleApp.Web.Tests\`
- `scripts\bootstrap.ps1`
- `scripts\bootstrap.sh`
- `scripts\setup-ai.ps1`
- `scripts\update.ps1`
- `scripts\update.sh`
- `scripts\scaffold.ps1`
- `scripts\scaffold.sh`
- `.scaffold\scaffold.settings.json`
- `.scaffold\assets\asset-manifest.json`

For the reduced variants, verify the targeted differences:

- `SampleAppNoFrontend` keeps
  `src\SampleAppNoFrontend.ServiceDefaults\`,
  `src\SampleAppNoFrontend.Web\`,
  `tests\SampleAppNoFrontend.Web.Tests\`, and
  `src\SampleAppNoFrontend.AspireHost\SampleAppNoFrontend.AspireHost.NoBlazor.csproj`,
  but omits `src\SampleAppNoFrontend.Blazor\`
- `SampleAppApiOnly` keeps
  `src\SampleAppApiOnly.ServiceDefaults\`,
  `src\SampleAppApiOnly.Web\`, and
  `tests\SampleAppApiOnly.Web.Tests\`, but omits both
  `src\SampleAppApiOnly.AspireHost\` and
  `src\SampleAppApiOnly.Blazor\`

Also verify that the following generated repo-baseline files exist:

- `README.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `.editorconfig`
- `.release-please-manifest.json`
- `Directory.Build.props`
- `.markdownlint-cli2.jsonc`
- `version.txt`
- `docs\SETUP.md`
- `docs\RELEASE.md`
- `docs\TROUBLESHOOTING.md`
- `docs\SCAFFOLDING.md`
- `docs\AI-SKILLS.md`
- `release-please-config.json`
- `qodana.yaml`
- `sonar-project.properties`
- `.copilot\mcp-config.json`
- `.github\copilot-instructions.md`
- `.github\workflows\ci.yml`
- `.github\workflows\release-please.yml`
- `.github\workflows\conventional-commits.yml`
- `.github\workflows\quality-analysis.yml`
- `.github\dependabot.yml`
- `.github\CODEOWNERS`
- `.github\pull_request_template.md`

When repo-baseline defaults change, also inspect the scaffolded copies
of `.editorconfig`, `Directory.Build.props`, and
`.markdownlint-cli2.jsonc` to confirm the expected analyzer, build, and
Markdown lint settings were materialized.

If the AI bootstrap defaults change, also inspect `docs\AI-SKILLS.md`,
`.copilot\mcp-config.json`, `.github\copilot-instructions.md`, and
`scripts\setup-ai.ps1` to confirm the generated repo still declares opt-in AI
setup without auto-installing anything.

If the release/governance defaults change, also inspect `CONTRIBUTING.md`,
`docs\RELEASE.md`, `release-please-config.json`, `qodana.yaml`,
`sonar-project.properties`, `.github\workflows\release-please.yml`,
`.github\workflows\conventional-commits.yml`,
`.github\workflows\quality-analysis.yml`, `CHANGELOG.md`, `version.txt`, and
`.release-please-manifest.json`. The last three files are intentionally not
scaffold-managed, because release automation updates them over time. Treat
these checks as generated-repository contract validation only; they do not
validate or replace any root repository release-state files or publish
workflow for `MartiX.Dotnet.Templates`.

## Bootstrap and update validation

From the generated sample root:

PowerShell:

```powershell
Set-Location .\SampleApp
.\scripts\bootstrap.ps1
.\scripts\update.ps1 --dry-run
```

Shell:

```sh
cd ./SampleApp
./scripts/bootstrap.sh
./scripts/update.sh --dry-run
```

Expected result today:

- `bootstrap` writes or refreshes the full manifest-managed asset set
- `update --dry-run` reports the same manifest-managed asset set without failing
- `update` can rewrite the scaffold-managed asset set without breaking later verification
- the generated sample still contains `CHANGELOG.md`, `version.txt`,
  and `.release-please-manifest.json`
- both script families route through the
  `.scaffold\src\MartiX.WebApi.Template.Scaffold\Program.cs` runner
- shell execution requires `dotnet` to be available on the shell `PATH`
- the richer maintainer helper also validates generated Markdown
  lintability, JSON/JSONC/YAML/properties parseability, and
  release/governance workflow/config shape after bootstrap completes

## AI bootstrap validation

From the generated sample root:

PowerShell:

```powershell
Set-Location .\SampleApp
.\scripts\setup-ai.ps1
.\scripts\setup-ai.ps1 -RegisterMarketplace -InstallRecommendedMartiX -DryRun
```

Expected result today:

- the helper lists the curated MartiX plugin set and selected external skill
  commands
- dry-run prints the marketplace registration and plugin install commands without
  executing them
- no plugin or skill is installed unless the operator reruns the script without
  `-DryRun` or `-WhatIf`
- `refresh-generated-assets.*` and `verify-generated-assets.*` now exercise this
  behavior automatically as part of the generated-repo contract validation

## Build and test the scaffolded solution

From the generated sample root:

PowerShell:

```powershell
Set-Location .\SampleApp
dotnet restore
dotnet build
dotnet test
```

Shell:

```sh
cd ./SampleApp
dotnet restore
dotnet build
dotnet test
```

Expected result:

- restore succeeds
- the generated projects build successfully
- tests run through `dotnet test` using TUnit support

If `dotnet test` still hits the pre-existing .NET 10 SDK
Microsoft.Testing.Platform/VSTest compatibility issue, treat that as a known
limitation. The maintainer helper scripts now surface it explicitly after a
successful restore/build so the rest of the generated-repo contract can still be
validated.

## Optional runtime smoke tests

### Aspire path

Use this when you want to validate the full local orchestration path:

PowerShell:

```powershell
Set-Location .\src\SampleApp.AspireHost
dotnet run
```

Shell:

```sh
cd ./src/SampleApp.AspireHost
dotnet run
```

Use this path to validate:

- SQL Server container wiring
- Papercut SMTP container wiring
- service references between AppHost, Web, and Blazor

### API-only Aspire path

Use this when you want to validate the reduced Aspire path produced by
`--frontend none`:

PowerShell:

```powershell
Set-Location .\src\SampleAppApiOnly.AspireHost
dotnet run --project .\SampleAppApiOnly.AspireHost.NoBlazor.csproj
```

Shell:

```sh
cd ./src/SampleAppApiOnly.AspireHost
dotnet run --project ./SampleAppApiOnly.AspireHost.NoBlazor.csproj
```

Use this path to validate:

- SQL Server container wiring without the frontend
- Papercut SMTP container wiring
- service references between AppHost and Web

### API-only path

Use this when you want to validate the application host without the Aspire orchestrator:

PowerShell:

```powershell
Set-Location .\src\SampleAppStandalone.Web
dotnet run
```

Shell:

```sh
cd ./src/SampleAppStandalone.Web
dotnet run
```

Use this path to validate:

- API startup wiring
- FastEndpoints registration
- ServiceDefaults integration
- startup-time seeding behavior

Note that API-only execution may still require configuration that the
Aspire host would normally supply during orchestrated development.

## Documentation consistency checks

When updating docs, confirm that the written guidance matches repository reality:

1. `docs\generated-repo-boundary.md` must stay consistent with the
   actual template, scaffold-managed, opt-in, and external boundary.
2. `docs\scaffold-automation.md` must clearly separate
   **current behavior** from **planned behavior**.
3. `docs\dotnet-10-webapi-template-recommendation.md` should remain the
   strategic source for future automation scope.
4. Any documented generated file must be confirmed by a fresh scaffold.
5. Any documented script or workflow must already exist, or be labeled as planned.
6. Generated-repo Release Please files and workflows must stay clearly
   separate from any repository-root release or publish flow for
   `MartiX.Dotnet.Templates`.
7. Root package release docs must stay consistent with
   `MartiX.Dotnet.Templates.csproj`, `release-please-config.json`,
   `.release-please-manifest.json`, `version.txt`, `CHANGELOG.md`, and
   `.github\workflows\release.yml`, including the `release` environment and
   `NUGET_USER` trusted-publishing prerequisite.

## Maintainer helper scripts

From the template repository root:

PowerShell:

```powershell
.\scripts\refresh-generated-assets.ps1
.\scripts\verify-generated-assets.ps1
```

Shell:

```sh
./scripts/refresh-generated-assets.sh
./scripts/verify-generated-assets.sh
```

Expected result:

- `refresh-generated-assets` scaffolds a fresh sample under
  `bin\generated-assets\SampleApp` by default, runs the generated
  bootstrap/update/verify flows, validates the generated
  AI/release/governance/config assets, and leaves that sample in place
  as the current golden contract repo
- `verify-generated-assets` performs the same end-to-end generated-repo
  validation on a fresh temporary scaffold and cleans up by default
  unless you pass `-KeepProject` / `--keep-project`
- both helpers now lint generated Markdown, validate
  JSON/JSONC/YAML/properties files, run
  `scripts\setup-ai.ps1 -RegisterMarketplace -InstallRecommendedMartiX -DryRun`,
  and restore/build/test the generated solution
- `.github\workflows\template-validation.yml` mirrors that richer flow
  on both Windows and Linux runners

## Suggested validation checklist for future automation work

The recommendation and plan already point toward a broader validation
model. Extend validation further as new scaffold-managed assets are
added, especially for:

- repeated re-run safety for generated non-code assets
- generated `.github\` baseline consistency
- CI execution of pack, install, scaffold, build, and test
