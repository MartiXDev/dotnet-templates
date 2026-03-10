# Scaffold-managed repository assets

This repository keeps scaffold-managed non-code assets under `.scaffold/` so PowerShell and shell entrypoints can reuse the same generation model.

## Source of truth

- Manifest: `.scaffold/assets/asset-manifest.json`
- Asset templates: `.scaffold/assets/templates/`
- Generator: `.scaffold/src/MartiX.WebApi.Template.Scaffold/`
- Entrypoints: `scripts/bootstrap.ps1`, `scripts/bootstrap.sh`, `scripts/update.ps1`, `scripts/update.sh`, `scripts/scaffold.ps1`, `scripts/scaffold.sh`

## Current context

- Project name: `MartiX.WebApi.Template`
- Target framework: `net10.0`

## Usage

Run one of the platform entrypoints from the repository root:

```powershell
./scripts/bootstrap.ps1
./scripts/update.ps1
./scripts/scaffold.ps1 verify
```

```sh
./scripts/bootstrap.sh
./scripts/update.sh
./scripts/scaffold.sh verify
```

## Current scaffold-managed asset set

- `README.md`
- `CONTRIBUTING.md`
- `.editorconfig`
- `Directory.Build.props`
- `.markdownlint-cli2.jsonc`
- `docs/SCAFFOLDING.md`
- `docs/SETUP.md`
- `docs/RELEASE.md`
- `docs/TROUBLESHOOTING.md`
- `docs/AI-SKILLS.md`
- `.copilot/mcp-config.json`
- `.github/copilot-instructions.md`
- `scripts/setup-ai.ps1`
- `release-please-config.json`
- `qodana.yaml`
- `sonar-project.properties`
- `.github/workflows/ci.yml`
- `.github/workflows/release-please.yml`
- `.github/workflows/conventional-commits.yml`
- `.github/workflows/quality-analysis.yml`
- `.github/dependabot.yml`
- `.github/CODEOWNERS`
- `.github/pull_request_template.md`

Both script families delegate to the same `.NET` scaffold runner, so future
generated assets only need to be added once in the manifest/templates under
`.scaffold/`. The AI bootstrap files remain declaration-first and opt-in: they
document or assist setup, but they do not auto-install plugins or skills.

## Release automation note

`CHANGELOG.md`, `version.txt`, and `.release-please-manifest.json` are created
by `dotnet new`, but they are intentionally not scaffold-managed because
Release Please updates them over time. That keeps `scripts/scaffold.* verify`
focused on the static shared baseline instead of the repository's evolving
release history.
