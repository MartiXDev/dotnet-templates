# Generated repository boundary and frozen default stack

## Purpose

This document is the canonical contract for the current `martix-webapi` golden path.
Use it to decide whether a change belongs in template source, scaffold-managed assets, post-bootstrap opt-in automation, or outside the generated repository entirely.

Keep this file short and stable.
Use the companion documents for implementation detail:

- [Scaffold automation architecture](scaffold-automation.md)
- [Template validation guide](template-validation.md)
- [Bootstrapping tips](bootstrapping-tips.md)
- [Template recommendation](dotnet-10-webapi-template-recommendation.md)

## Repository role split

- `dotnet-templates` owns the generated repository contract and its implementation.
- `WebApi` is the reference source for runtime, developer-experience, and quality defaults that may later be promoted into the template or scaffold layer.
- `ai-marketplace` is the reference source for AI skill/plugin catalogs and install flows; generated repositories should consume it through declaration-first, opt-in bootstrap guidance rather than auto-installation.

## Canonical boundary

| Layer | Put it here when... | Current contract | Primary references |
| --- | --- | --- | --- |
| Template source | the generated repo must compile, run, and express the default architecture immediately after `dotnet new` | Keep the multi-project solution, `Directory.Packages.props`, `.template.config\template.json`, `src\*.Web`, `src\*.ServiceDefaults`, `src\*.AspireHost`, `src\*.Blazor`, `tests\*.Web.Tests`, and template-initialized release-state files such as `CHANGELOG.md`, `.release-please-manifest.json`, and `version.txt` in `templates\MartiX.WebApi.Template\`. Stable runtime defaults from `MartiX.WebApi` belong here once adopted. | `templates\MartiX.WebApi.Template\`, `templates\MartiX.WebApi.Template\.template.config\template.json`, `templates\MartiX.WebApi.Template\src\`, `templates\MartiX.WebApi.Template\tests\` |
| Scaffold-managed assets | the file is repo-level, non-code, and should be safely re-materialized by `bootstrap` or `update` | Keep manifest-owned repo assets in `.scaffold\assets\templates\` and materialize them via `scripts\bootstrap.*` and `scripts\update.*`. Today this includes `README.md`, `CONTRIBUTING.md`, `.editorconfig`, `Directory.Build.props`, `.markdownlint-cli2.jsonc`, `docs\SETUP.md`, `docs\RELEASE.md`, `docs\TROUBLESHOOTING.md`, `docs\SCAFFOLDING.md`, `docs\AI-SKILLS.md`, `release-please-config.json`, `qodana.yaml`, `sonar-project.properties`, `.copilot\mcp-config.json`, `.github\copilot-instructions.md`, `scripts\setup-ai.ps1`, `.github\workflows\ci.yml`, `.github\workflows\release-please.yml`, `.github\workflows\conventional-commits.yml`, `.github\workflows\quality-analysis.yml`, `.github\dependabot.yml`, `.github\CODEOWNERS`, and `.github\pull_request_template.md`. | `docs\scaffold-automation.md`, `templates\MartiX.WebApi.Template\.scaffold\assets\asset-manifest.json` |
| Post-bootstrap opt-in automation and docs | the capability is useful and repeatable, but should not auto-install, auto-provision, or silently mutate the repo during `dotnet new` | Keep declaration-first extras here. Generated repos may ship `docs\AI-SKILLS.md`, `.copilot\mcp-config.json`, `.github\copilot-instructions.md`, and `scripts\setup-ai.ps1` as discoverability and setup aids, and they may also ship token-gated quality/release workflows. Marketplace registration, skill/plugin installation, and enabling external services still require explicit user action. Optional editor-specific settings such as `.vscode\settings.json`, optional `.github\skills`, optional hook/setup helpers, and org-specific policy overlays stay in this lane. No automatic install in this workstream. | `docs\bootstrapping-tips.md`, `..\ai-marketplace\docs\recommended-skills.md`, `..\ai-marketplace\scripts\install-plugins.ps1` |
| External or org-specific setup | the concern depends on secrets, licenses, tenant data, governance policy, or deployment environment | Do not bake in repository secrets, branch protections, required reviewers, environment approvals, private feeds, tenant or subscription identifiers, production cloud resources, org-specific infrastructure, or licensed scanners and services. Document them separately and apply them outside the template. | `docs\dotnet-10-webapi-template-recommendation.md` |

## Frozen default stack

Treat this stack as frozen until a later document update explicitly expands the supported matrix.

| Area | Frozen default today | Notes |
| --- | --- | --- |
| Framework | `.NET 10` / `net10.0` | `Framework` plus the limited `frontend` / `orchestrator` switches are the only exposed template parameters today. |
| Application baseline | `MartiX.WebApi`-based multi-project solution | The golden path includes `Web`, `ServiceDefaults`, `AspireHost`, `Blazor`, and `Web.Tests`; the current reduced switches only trim the frontend and/or AppHost from that baseline. |
| Test baseline | `TUnit` | Keep `TestingPlatformDotnetTestSupport` in the default test project. |
| Source control and CI | GitHub-hosted repository with a GitHub Actions baseline | The scaffolded baseline now includes CI, Conventional Commit pull request title enforcement, Release Please, optional token-gated static-analysis workflows, Dependabot, CODEOWNERS, and a pull request template. |
| AI and Copilot posture | GitHub and Copilot-friendly, declaration-first | Generated repos ship `docs\AI-SKILLS.md`, `.copilot\mcp-config.json`, `.github\copilot-instructions.md`, and `scripts\setup-ai.ps1` as opt-in helpers; MartiX and external skill/plugin installation remains explicit rather than automatic. |
| Database default | SQL Server | SQL Server is the only baked-in database path today. |
| Local orchestration | Aspire AppHost by default | AppHost wires SQL Server and Blazor on the golden path. `--orchestrator none` is the only reduced orchestrator option supported today. |
| Frontend default | Blazor generated by default | `--frontend none` is the only reduced frontend option supported today. In this first slice, `--orchestrator none` also omits the frontend. |

## Explicit non-goals for this workstream

- No deployment automation, org-specific release branching, or secret provisioning baked into the template.
- No automatic AI asset generation or automatic skill/plugin installation.
- No broad template matrix beyond the limited `--frontend` / `--orchestrator` first slice, and no alternate database or auth stacks yet.
- No org-specific policy, secret, or deployment automation baked into the template.

This gives later implementation work a clear contract: stable code defaults in the template, repeatable repo assets in scaffold automation, opt-in AI and bootstrap extras after explicit user action, and org-specific setup outside the generated repository.
