# Copilot instructions for dotnet-templates

## Build, test, and validation commands

Run from the repository root unless noted otherwise.

### Template pack and maintainer flow

```powershell
dotnet build .\MartiX.Dotnet.Templates.csproj -nologo
dotnet test .\MartiX.Dotnet.Templates.csproj -nologo
dotnet pack .\MartiX.Dotnet.Templates.csproj -o .\bin\Release -nologo
.\scripts\refresh-generated-assets.ps1
.\scripts\verify-generated-assets.ps1
.\scripts\validate-generated-repo.ps1 -ProjectRoot <path> -ScaffoldVariant default
```

Use `ScaffoldVariant` values `default`, `no-frontend`, or `api-only` to match the scaffold you generated.
The root `dotnet test` command is a pack-project sanity check; the heavier end-to-end validation is in `refresh-generated-assets.ps1` and `verify-generated-assets.ps1`.

### Template source checks (`templates\MartiX.WebApi.Template`)

```powershell
dotnet restore .\MartiX.WebApi.Template.slnx
dotnet format .\MartiX.WebApi.Template.slnx --verify-no-changes --no-restore
dotnet build .\MartiX.WebApi.Template.slnx --no-restore --configuration Release -p:TreatWarningsAsErrors=true
dotnet test --solution .\MartiX.WebApi.Template.slnx --no-build --configuration Release --results-directory .\.artifacts\test-results --coverage --coverage-output-format cobertura --report-trx
dotnet test --project .\tests\MartiX.WebApi.Template.Web.Tests\MartiX.WebApi.Template.Web.Tests.csproj -- --treenode-filter "/*/*/GuestUserDomainTests/UpdateEmail_WhenCalled_UpdatesEmail"
```

The template test project uses TUnit with Microsoft.Testing.Platform, so use `--solution` for the `.slnx` file and pass targeted test filters after `--`. If the lint check fails on import-order diagnostics, run `dotnet format .\MartiX.WebApi.Template.slnx --no-restore` to apply the scaffolded formatting baseline before re-running the verify command.

## High-level architecture

- `MartiX.Dotnet.Templates.csproj` is a NuGet template pack project. It ships everything under `templates\**\*`, so the actual product lives under `templates\MartiX.WebApi.Template\`.
- `templates\MartiX.WebApi.Template\.template.config\template.json` defines the public template surface. The supported matrix is intentionally small: `Framework=net10.0`, `--frontend blazor|none`, and `--orchestrator aspire|none`.
- `templates\MartiX.WebApi.Template\.scaffold\` is the source of truth for scaffold-managed repository assets. `asset-manifest.json` defines the asset set, `.scaffold\assets\templates\` contains the `.tmpl` sources, and `.scaffold\src\MartiX.WebApi.Template.Scaffold\Program.cs` is the manifest-driven runner behind `scripts\bootstrap.*`, `scripts\update.*`, and `scripts\scaffold.*`.
- The checked-in files like `templates\MartiX.WebApi.Template\README.md`, `CONTRIBUTING.md`, `docs\*`, `.github\*`, `.copilot\mcp-config.json`, and `scripts\setup-ai.ps1` are materialized scaffold outputs. They show what generated repositories receive after `bootstrap` or `update`.
- The generated solution itself is multi-project: `Web` is the API host, `ServiceDefaults` provides health, resilience, service discovery, and OpenTelemetry defaults, `AspireHost` provisions SQL Server plus Papercut for the default local experience, `Blazor` is the default frontend slice, and `Web.Tests` is the TUnit test project.
- Inside `src\MartiX.WebApi.Template.Web`, the project is organized around `Configurations\`, `Feature\`, `Domain\`, and `Infrastructure\`. Tests mirror those slices under `tests\MartiX.WebApi.Template.Web.Tests\`.

## Key repository conventions

- When changing scaffold-managed docs, workflows, config files, or Copilot assets inside `templates\MartiX.WebApi.Template`, edit the matching source under `.scaffold\assets\templates\...` first, then refresh or verify the materialized copy with `.\scripts\bootstrap.ps1`, `.\scripts\update.ps1`, or `.\scripts\scaffold.ps1 verify`.
- `CHANGELOG.md`, `version.txt`, and `.release-please-manifest.json` are intentionally not scaffold-managed because Release Please updates them over time.
- Root-level validation is product-oriented. After template, scaffold, or generated-asset changes, use `.\scripts\refresh-generated-assets.ps1` or `.\scripts\verify-generated-assets.ps1`; a root `dotnet build` alone does not prove the generated repository contract still works.
- `.tmpl` files under `.scaffold\assets\templates\` use the scaffold runner's `{{ProjectName}}` and `{{Framework}}` placeholders, not `dotnet new` symbol syntax. `asset-manifest.json` also controls whether each asset is rendered as a template or copied verbatim, plus its expected line endings.
- `config.nsdepcop` turns domain-to-infrastructure and feature-to-infrastructure dependencies into build errors. Preserve the `Feature` / `Domain` / `Infrastructure` boundaries instead of shortcutting through infrastructure types.
- AI bootstrap assets are declaration-first and opt-in. `.copilot\mcp-config.json`, `docs\AI-SKILLS.md`, and `scripts\setup-ai.ps1` should guide or dry-run setup, not auto-install plugins or mutate the repository implicitly.
- If MCP servers are available in the working environment, a NuGet/package metadata server is the most useful companion to the generated GitHub MCP config. Use it when changing `MartiX.Dotnet.Templates.csproj` or `templates\MartiX.WebApi.Template\Directory.Packages.props`, especially for package version lookups, metadata checks, and vulnerability follow-up such as the current `NU1902` MimeKit warning surfaced during template validation.
- If you change template switches, solution composition, or scaffold-managed assets, keep the maintainer contract docs in sync: `docs\generated-repo-boundary.md`, `docs\scaffold-automation.md`, and `docs\template-validation.md`.
