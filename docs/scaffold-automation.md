# Scaffold automation architecture

## Purpose and status

This repository uses a **hybrid scaffold automation model**:

- **Today**: the `dotnet new` template generates both the solution source tree and a scaffold-management layer.
- **Current direction**: the shared scaffold runner now owns the first cross-platform bootstrap, update, and verification asset set.

That split follows the recommendation in [`docs/dotnet-10-webapi-template-recommendation.md`](dotnet-10-webapi-template-recommendation.md): keep stable engineering defaults in the template, and keep repository-specific or fast-changing concerns in documentation and automation wrappers.
Use [`docs/generated-repo-boundary.md`](generated-repo-boundary.md) as the canonical contract for which concerns belong in template source, scaffold-managed assets, post-bootstrap opt-in automation, and external setup.

This document intentionally distinguishes between:

- **Current implementation**: what a maintainer or consumer gets from the repository today.
- **Intended automation model**: the documented target architecture for future scaffold/bootstrap automation.

## Current implementation: what the template generates today

Running `dotnet new martix-webapi -n MyProject` currently generates a solution-style repository with these root assets:

| Generated asset | Purpose | Source |
| --- | --- | --- |
| `MyProject.slnx` | Solution entry point for the generated multi-project solution. | `templates\MartiX.WebApi.Template\MartiX.WebApi.Template.slnx` |
| `Directory.Packages.props` | Central package version management across all generated projects. | `templates\MartiX.WebApi.Template\Directory.Packages.props` |
| `README.md` | First-run, local development, and governance overview for the generated repository. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\README.md.tmpl` via `scripts\bootstrap.*` |
| `CONTRIBUTING.md` | Pull request title conventions, merge guidance, and local validation reminders. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\CONTRIBUTING.md.tmpl` via `scripts\bootstrap.*` |
| `CHANGELOG.md` | Release history file that Release Please updates over time. | `templates\MartiX.WebApi.Template\CHANGELOG.md` |
| `.release-please-manifest.json` | Release Please state file that tracks the last released version. | `templates\MartiX.WebApi.Template\.release-please-manifest.json` |
| `version.txt` | Repository version file used by Release Please's `simple` strategy. | `templates\MartiX.WebApi.Template\version.txt` |
| `.editorconfig` | Shared formatting, analyzer severities, and editor conventions for the generated repository. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.editorconfig.tmpl` via `scripts\bootstrap.*` |
| `Directory.Build.props` | Shared MSBuild defaults such as nullable, analyzers, and build-time code-style enforcement. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\Directory.Build.props.tmpl` via `scripts\bootstrap.*` |
| `.markdownlint-cli2.jsonc` | Shared Markdown lint defaults for generated repository docs. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.markdownlint-cli2.jsonc.tmpl` via `scripts\bootstrap.*` |
| `docs\SETUP.md` | Exact setup and day-to-day run commands for the generated repository. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\docs\SETUP.md.tmpl` via `scripts\bootstrap.*` |
| `docs\RELEASE.md` | Documents the Conventional Commit, semantic versioning, and release workflow baseline. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\docs\RELEASE.md.tmpl` via `scripts\bootstrap.*` |
| `docs\TROUBLESHOOTING.md` | Troubleshooting guidance for common local issues. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\docs\TROUBLESHOOTING.md.tmpl` via `scripts\bootstrap.*` |
| `docs\SCAFFOLDING.md` | Explains the scaffold-managed asset model inside the generated repository. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\docs\SCAFFOLDING.md.tmpl` via `scripts\bootstrap.*` |
| `docs\AI-SKILLS.md` | Declares the opt-in MartiX and external AI recommendations for the generated repository. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\docs\AI-SKILLS.md.tmpl` via `scripts\bootstrap.*` |
| `.copilot\mcp-config.json` | Repository-level GitHub MCP configuration for Copilot-aware tooling. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.copilot\mcp-config.json` via `scripts\bootstrap.*` |
| `.github\copilot-instructions.md` | Repository-specific Copilot guidance for build, test, architecture, and AI usage. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.github\copilot-instructions.md.tmpl` via `scripts\bootstrap.*` |
| `scripts\setup-ai.ps1` | Opt-in helper that lists and dry-runs MartiX AI marketplace setup commands. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\scripts\setup-ai.ps1` via `scripts\bootstrap.*` |
| `release-please-config.json` | Shared Release Please configuration for semantic versioning and changelog generation. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\release-please-config.json.tmpl` via `scripts\bootstrap.*` |
| `qodana.yaml` | Optional Qodana defaults for token-gated static analysis. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\qodana.yaml.tmpl` via `scripts\bootstrap.*` |
| `sonar-project.properties` | Optional Sonar defaults consumed by the token-gated quality-analysis workflow. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\sonar-project.properties.tmpl` via `scripts\bootstrap.*` |
| `.github\workflows\ci.yml` | Starter CI workflow for generated repositories. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.github\workflows\ci.yml.tmpl` via `scripts\bootstrap.*` |
| `.github\workflows\release-please.yml` | Starter semantic-versioning and changelog workflow for generated repositories. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.github\workflows\release-please.yml.tmpl` via `scripts\bootstrap.*` |
| `.github\workflows\conventional-commits.yml` | Pull request title enforcement for Conventional Commits. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.github\workflows\conventional-commits.yml.tmpl` via `scripts\bootstrap.*` |
| `.github\workflows\quality-analysis.yml` | Token-gated Sonar and Qodana workflow for optional static analysis. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.github\workflows\quality-analysis.yml.tmpl` via `scripts\bootstrap.*` |
| `.github\dependabot.yml` | Starter dependency update baseline for generated repositories. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.github\dependabot.yml.tmpl` via `scripts\bootstrap.*` |
| `.github\CODEOWNERS` | CODEOWNERS placeholder for generated repositories. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.github\CODEOWNERS.tmpl` via `scripts\bootstrap.*` |
| `.github\pull_request_template.md` | Starter pull request review checklist. | `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.github\pull_request_template.md.tmpl` via `scripts\bootstrap.*` |
| `src\MyProject.Web\` | Main API host and application code. | `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.Web\` |
| `src\MyProject.ServiceDefaults\` | Shared Aspire-style defaults for telemetry, health checks, resilience, and service discovery. | `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.ServiceDefaults\` |
| `src\MyProject.AspireHost\` | Local orchestration project for containers and service wiring. | `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.AspireHost\` |
| `src\MyProject.Blazor\` | Optional-in-practice frontend project that is currently generated by default. | `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.Blazor\` |
| `tests\MyProject.Web.Tests\` | Test baseline for the API solution. | `templates\MartiX.WebApi.Template\tests\MartiX.WebApi.Template.Web.Tests\` |
| `scripts\` | Cross-platform bootstrap and update entrypoints included in generated repositories. | `templates\MartiX.WebApi.Template\scripts\` |
| `.scaffold\` | Shared scaffold configuration, manifest, source templates, and the runner project. | `templates\MartiX.WebApi.Template\.scaffold\` |

### Repository-level defaults and remaining gaps

The remaining intentional gaps are now the environment-specific concerns that should stay outside the template:

- organization-specific branch protection rules
- repository secrets and environments
- cloud deployment specifics
- provider-specific infrastructure-as-code
- optional subsystems that are not universally useful

That split is intentional: stable repo defaults are scaffolded, while environment-specific governance stays outside the template.

## Generated solution architecture

### 1. Template engine layer

The first automation layer is the .NET template engine configuration in [`templates\MartiX.WebApi.Template\.template.config\template.json`](../templates/MartiX.WebApi.Template/.template.config/template.json).

Important details:

- `shortName` is `martix-webapi`
- `sourceName` is `MartiX.WebApi.Template`, which drives project, namespace, and file-name substitution
- `preferNameDirectory` is `true`, so `dotnet new` creates a dedicated target directory
- the only current template symbol is `Framework`, and it only allows `net10.0`

### 2. Scaffold-management layer

The generated repository includes a scaffold-management system so repository assets can be materialized and refreshed after `dotnet new`.

#### `scripts\`

The `scripts\` directory contains platform-specific entrypoints:

- `scripts\bootstrap.ps1`
- `scripts\bootstrap.sh`
- `scripts\update.ps1`
- `scripts\update.sh`
- `scripts\scaffold.ps1`
- `scripts\scaffold.sh`

The behavior is intentionally symmetrical:

- `bootstrap.*` delegates to `scaffold.* bootstrap`
- `update.*` delegates to `scaffold.* update`
- both PowerShell and shell variants call the same `.NET` runner project under `.scaffold\src\`

Source references:

- `templates\MartiX.WebApi.Template\scripts\bootstrap.ps1`
- `templates\MartiX.WebApi.Template\scripts\bootstrap.sh`
- `templates\MartiX.WebApi.Template\scripts\scaffold.ps1`
- `templates\MartiX.WebApi.Template\scripts\scaffold.sh`
- `templates\MartiX.WebApi.Template\scripts\update.ps1`
- `templates\MartiX.WebApi.Template\scripts\update.sh`

#### `.scaffold\`

The `.scaffold\` directory is the shared source of truth for scaffold-managed assets.

Today it contains:

- `scaffold.settings.json` for template-scoped values such as project name and framework
- `assets\asset-manifest.json` for command-to-asset mapping
- `assets\templates\` for scaffold-managed repository asset templates such as `README.md`, `CONTRIBUTING.md`, `.editorconfig`, `Directory.Build.props`, `.markdownlint-cli2.jsonc`, `docs\SCAFFOLDING.md`, `docs\RELEASE.md`, `docs\AI-SKILLS.md`, `release-please-config.json`, `qodana.yaml`, `sonar-project.properties`, `.copilot\mcp-config.json`, and the generated `.github\workflows\*.yml` baseline
- `src\MartiX.WebApi.Template.Scaffold\Program.cs` for the manifest-driven runner

Important implementation details:

- the runner supports `bootstrap`, `update`, and `verify`
- the runner supports `--dry-run`
- the runner supports `--var Name=Value`
- asset rendering is path-safe and placeholder-driven
- both entrypoint families call the same runner, so PowerShell and shell stay aligned

Source references:

- `templates\MartiX.WebApi.Template\.scaffold\scaffold.settings.json`
- `templates\MartiX.WebApi.Template\.scaffold\assets\asset-manifest.json`
- `templates\MartiX.WebApi.Template\.scaffold\assets\templates\docs\SCAFFOLDING.md.tmpl`
- `templates\MartiX.WebApi.Template\.scaffold\src\MartiX.WebApi.Template.Scaffold\Program.cs`

#### What bootstrap and update generate today

Both `bootstrap` and `update` currently include the same manifest-driven asset set:

- `README.md`
- `CONTRIBUTING.md`
- `.editorconfig`
- `Directory.Build.props`
- `.markdownlint-cli2.jsonc`
- `docs\SCAFFOLDING.md`
- `docs\SETUP.md`
- `docs\RELEASE.md`
- `docs\TROUBLESHOOTING.md`
- `docs\AI-SKILLS.md`
- `.copilot\mcp-config.json`
- `.github\copilot-instructions.md`
- `scripts\setup-ai.ps1`
- `release-please-config.json`
- `qodana.yaml`
- `sonar-project.properties`
- `.github\workflows\ci.yml`
- `.github\workflows\release-please.yml`
- `.github\workflows\conventional-commits.yml`
- `.github\workflows\quality-analysis.yml`
- `.github\dependabot.yml`
- `.github\CODEOWNERS`
- `.github\pull_request_template.md`

Those files provide first-run guidance, repository defaults, scaffold
automation documentation, release governance defaults, token-gated static
analysis templates, and opt-in AI bootstrap guidance inside the scaffolded
repository itself.

### 3. Generated project layer

The template produces a multi-project solution whose responsibilities are intentionally separated.

#### `src\MyProject.Web`

The Web project is the main API host.

Key characteristics:

- uses `Microsoft.NET.Sdk.Web`
- references `FastEndpoints`, `FastEndpoints.Swagger`, `Scalar.AspNetCore`, `Serilog.AspNetCore`, `Serilog.Sinks.OpenTelemetry`, EF Core packages, `Mediator`, `Vogen`, `MailKit`, and `MartiX.WebApi`
- explicitly treats `NSDEPCOP01` as an error to enforce namespace dependency rules
- calls `builder.AddServiceDefaults()` and `app.MapDefaultEndpoints()` in `Program.cs`
- seeds the database during startup via `UseAppMiddlewareAndSeedDatabase()`

Source references:

- `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.Web\MartiX.WebApi.Template.Web.csproj`
- `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.Web\Program.cs`

The internal structure is opinionated:

- `Feature\` for vertical-slice application behavior
- `Domain\` for aggregates and value objects
- `Infrastructure\` for EF Core, queries, repositories, email, and wiring
- `Configurations\` for startup and dependency registration

That organization is important to document because it explains why the template is more than a hello-world scaffold.

#### `src\MyProject.ServiceDefaults`

The ServiceDefaults project centralizes the shared runtime defaults that every host should opt into.

It provides:

- OpenTelemetry logging, metrics, and tracing
- default health checks
- service discovery
- standard HTTP client resilience
- OTLP exporter activation when `OTEL_EXPORTER_OTLP_ENDPOINT` is configured

Source reference:

- `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.ServiceDefaults\Extensions.cs`

#### `src\MyProject.AspireHost`

The Aspire host is the current local orchestration entry point.

Today it wires:

- a SQL Server container resource
- an `AppDb` database
- a Papercut SMTP container for local email testing
- the Web project
- the Blazor project

Source references:

- `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.AspireHost\AppHost.cs`
- `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.AspireHost\MartiX.WebApi.Template.AspireHost.csproj`

Operational consequence:

- the full orchestrated developer experience depends on a working container runtime
- the API can still be run directly when a developer wants to bypass Aspire orchestration

#### `src\MyProject.Blazor`

The Blazor project is present in the generated solution by default.

Important caveat:

- the recommendation document treats frontend support as a candidate future option
- the current template does **not** expose a switch to disable Blazor generation

That means docs should describe Blazor as **generated by default today**, not as an optional template parameter that already exists.

#### `tests\MyProject.Web.Tests`

The test project provides the default test harness.

It currently:

- targets `net10.0`
- uses `TUnit`
- enables `TestingPlatformDotnetTestSupport`
- references `coverlet.collector`, `NSubstitute`, `Microsoft.NET.Test.Sdk`, the Web project, and the ServiceDefaults project

Source reference:

- `templates\MartiX.WebApi.Template\tests\MartiX.WebApi.Template.Web.Tests\MartiX.WebApi.Template.Web.Tests.csproj`

## Why the current generated assets are configured this way

### Stable defaults belong in the template

The current template already bakes in the parts that are expected to be stable across most generated solutions:

- solution layout
- project separation
- centralized package management
- API host defaults
- observability hooks
- local orchestration baseline
- test project baseline

That aligns with the recommendation to keep "stable, high-value engineering defaults" inside the template rather than forcing every new repository to reconstruct them manually.

### Secret-backed integrations remain optional even when scaffolded

The current template now ships practical GitHub-native repo automation such as
CI, Conventional Commit title checks, Release Please, and token-gated quality
analysis defaults because those patterns are broadly reusable across generated
repositories.

The environment-specific concerns still stay outside the template:

- repository and environment secrets
- branch protection and reviewer policy
- deployment targets and release approvals
- organization-specific infrastructure and compliance settings

That preserves the two-layer model: stable repo defaults are scaffolded, while
environment-specific governance stays explicit and opt-in.

## Intended automation model

The plan and recommendation converge on a three-part automation architecture.

### 1. Template-baked defaults

The template should continue to own the stable default source tree and generated project code.

That includes:

- solution and project structure
- shared engineering defaults
- generated documentation that is safe to personalize with template substitution

### 2. Shared scaffold asset source

This layer already exists today as `.scaffold\`, and the planned evolution is to expand it with more generated non-code assets.

The intent is to avoid duplicating logic between:

- PowerShell automation
- shell automation
- generated asset refresh flows

### 3. Cross-platform entrypoints

Cross-platform support is a hard requirement for the planned automation model.

The design already present in the template is:

- `scripts\bootstrap.ps1` for PowerShell and Windows-friendly workflows
- `scripts\bootstrap.sh` for shell-based workflows
- both wrappers delegating to the same shared content model so the generated results stay identical

That design goal matters because the repository should not evolve into a Windows-only or Bash-only experience.

## Usage flows

### Current maintainer workflow

The repository root also includes helper scripts that scaffold a fresh sample repository and exercise the generated entrypoints:

- `scripts\refresh-generated-assets.ps1`
- `scripts\refresh-generated-assets.sh`
- `scripts\verify-generated-assets.ps1`
- `scripts\verify-generated-assets.sh`

### Pack the template

PowerShell:

```powershell
dotnet pack .\MartiX.Dotnet.Templates.csproj -o .\bin\Release
```

Shell:

```sh
dotnet pack ./MartiX.Dotnet.Templates.csproj -o ./bin/Release
```

### Install the template from source

PowerShell:

```powershell
dotnet new install .
```

Shell:

```sh
dotnet new install .
```

Use the shell path when `dotnet` is available in the target shell environment.

### Scaffold a sample repository

PowerShell:

```powershell
dotnet new martix-webapi -n SampleApp
```

Shell:

```sh
dotnet new martix-webapi -n SampleApp
```

### Build and test the scaffolded solution

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

### Materialize scaffold-managed repository assets

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

- `bootstrap` writes the full manifest-managed asset set, including `README.md`, `CONTRIBUTING.md`, `.editorconfig`, `Directory.Build.props`, `.markdownlint-cli2.jsonc`, the generated docs, release/quality configs, and the expanded `.github\` baseline
- `update` refreshes the same manifest-managed asset set
- `scaffold verify` confirms the scaffold-managed assets are still current
- the helper scripts also confirm that `CHANGELOG.md`, `version.txt`, and `.release-please-manifest.json` exist in a fresh scaffold
- both entrypoint families route through the same `.NET` scaffold runner
- shell execution requires `dotnet` to be available on the shell `PATH`

### Run with Aspire orchestration

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

### Run the API directly

PowerShell:

```powershell
Set-Location .\src\SampleApp.Web
dotnet run
```

Shell:

```sh
cd ./src/SampleApp.Web
dotnet run
```

## Validation guidance

Documentation about scaffold automation should be validated against real output, not only against source assumptions.

At minimum, validate that:

1. the template pack builds
2. `dotnet new install` works from source or package output
3. a fresh scaffold succeeds
4. the generated solution restores, builds, and tests successfully
5. the generated file layout matches the documented asset list

Use [`docs/template-validation.md`](template-validation.md) as the operational checklist.

## Current caveats to call out clearly

- Bootstrap and update scripts exist, but the manifest currently materializes a focused asset set rather than every possible repo concern.
- The generated `.github\` baseline is still intended to be understandable and tailorable per repository, even though it now includes CI, release governance, and optional quality-analysis workflows.
- The generated AI bootstrap assets are declaration-first. `scripts\setup-ai.ps1`
  only lists or runs commands when a user explicitly invokes it.
- Blazor is generated by default; it is not yet controlled by a template switch.
- SQL Server is the only current database path baked into the scaffold.
- `README.md`, `CONTRIBUTING.md`, `.editorconfig`, `Directory.Build.props`, `.markdownlint-cli2.jsonc`, `docs\SCAFFOLDING.md`, `docs\SETUP.md`, `docs\RELEASE.md`, `docs\TROUBLESHOOTING.md`, `docs\AI-SKILLS.md`, `.copilot\mcp-config.json`, `.github\copilot-instructions.md`, `scripts\setup-ai.ps1`, `release-please-config.json`, `qodana.yaml`, `sonar-project.properties`, and the generated `.github\` workflow baseline are scaffold-managed today.
- `CHANGELOG.md`, `version.txt`, and `.release-please-manifest.json` are intentionally template-initialized rather than scaffold-managed, because Release Please mutates them over time.
- `Directory.Build.props` intentionally enables build-time code style enforcement without carrying over the full `WebApi` `AnalysisMode=All` profile, so fresh repositories do not start with a large analyzer backlog.
- `.vscode\settings.json` remains intentionally opt-in because editor-specific settings are more likely to vary by team than repo-wide MSBuild, EditorConfig, or Markdown lint defaults.
- The full Aspire path assumes a container runtime because the AppHost provisions SQL Server and Papercut.

These are not documentation bugs. They are current-product realities that should stay explicit until the next automation track is implemented.

## Information-source references

### Primary repository sources

- Recommendation and roadmap: `docs\dotnet-10-webapi-template-recommendation.md`
- Template engine configuration: `templates\MartiX.WebApi.Template\.template.config\template.json`
- Template pack project: `MartiX.Dotnet.Templates.csproj`
- Generated solution definition: `templates\MartiX.WebApi.Template\MartiX.WebApi.Template.slnx`
- Central package versions: `templates\MartiX.WebApi.Template\Directory.Packages.props`
- Scaffold settings: `templates\MartiX.WebApi.Template\.scaffold\scaffold.settings.json`
- Asset manifest: `templates\MartiX.WebApi.Template\.scaffold\assets\asset-manifest.json`
- Generated README template: `templates\MartiX.WebApi.Template\.scaffold\assets\templates\README.md.tmpl`
- Generated editorconfig template: `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.editorconfig.tmpl`
- Generated Directory.Build.props template: `templates\MartiX.WebApi.Template\.scaffold\assets\templates\Directory.Build.props.tmpl`
- Generated markdownlint template: `templates\MartiX.WebApi.Template\.scaffold\assets\templates\.markdownlint-cli2.jsonc.tmpl`
- Scaffold asset template: `templates\MartiX.WebApi.Template\.scaffold\assets\templates\docs\SCAFFOLDING.md.tmpl`
- Scaffold runner: `templates\MartiX.WebApi.Template\.scaffold\src\MartiX.WebApi.Template.Scaffold\Program.cs`
- PowerShell bootstrap entrypoint: `templates\MartiX.WebApi.Template\scripts\bootstrap.ps1`
- Shell bootstrap entrypoint: `templates\MartiX.WebApi.Template\scripts\bootstrap.sh`
- Maintainer refresh helper: `scripts\refresh-generated-assets.ps1`
- Maintainer verify helper: `scripts\verify-generated-assets.ps1`
- API host entry point: `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.Web\Program.cs`
- API host project definition: `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.Web\MartiX.WebApi.Template.Web.csproj`
- Service defaults implementation: `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.ServiceDefaults\Extensions.cs`
- Aspire host entry point: `templates\MartiX.WebApi.Template\src\MartiX.WebApi.Template.AspireHost\AppHost.cs`
- Test project definition: `templates\MartiX.WebApi.Template\tests\MartiX.WebApi.Template.Web.Tests\MartiX.WebApi.Template.Web.Tests.csproj`

### External references

- .NET custom templates: <https://learn.microsoft.com/dotnet/core/tools/custom-templates>
- .NET Aspire service defaults guidance: <https://aka.ms/dotnet/aspire/service-defaults>
- Central Package Management: <https://learn.microsoft.com/nuget/consume-packages/central-package-management>
- FastEndpoints: <https://fast-endpoints.com/>
- TUnit: <https://tunit.dev/>
