# MartiX.WebApi.Template release and governance

This repository ships with a lightweight GitHub-native release baseline:

- pull request title validation using Conventional Commits
- Release Please for semantic versioning, changelog updates, release pull
  requests, and GitHub Releases
- token-gated Sonar and Qodana scaffolding that stays dormant until credentials
  are configured

## Conventional Commit quick reference

| Title pattern | Meaning | Default release impact |
| --- | --- | --- |
| `feat: add CSV export` | new user-visible capability | minor version bump |
| `fix: prevent duplicate invoices` | bug fix | patch version bump |
| `perf: speed up search` | performance improvement | patch version bump |
| `refactor!: simplify auth pipeline` | breaking change | major version bump |
| `docs:`, `test:`, `ci:`, `chore:`, `deps:` | supporting work tracked in the changelog | no version bump by themselves |

The pull request title is the most important input when the repository uses
**Squash and merge**, because the squash commit inherits that title by default.

## Release flow

1. Open a pull request with a Conventional Commit title.
2. Merge to `main` or `master`, preferably with **Squash and merge**.
3. `.github/workflows/release-please.yml` opens or updates a release pull
   request using `release-please-config.json`, `version.txt`,
   `.release-please-manifest.json`, and `CHANGELOG.md`.
4. Merge the release pull request to create the Git tag and GitHub Release.

## Recommended GitHub settings

- Enable **Squash merge** for the repository.
- Turn on **Default to PR title for squash merge commits**.
- If you want CI and other workflows to run on Release Please pull requests,
  create a `RELEASE_PLEASE_TOKEN` secret backed by a fine-grained personal
  access token. Otherwise the workflow falls back to the default
  `GITHUB_TOKEN`.
- If GitHub blocks action-created pull requests in your organization, allow
  GitHub Actions to create and approve pull requests in repository settings.

## Optional static analysis setup

The generated `quality-analysis.yml` workflow is safe by default:

- Sonar runs only when `SONAR_TOKEN` is present and `SONAR_HOST_URL` plus
  `SONAR_PROJECT_KEY` repository variables are configured. Add
  `SONAR_ORGANIZATION` when you are targeting SonarCloud.
- Qodana runs only when the `QODANA_TOKEN` secret exists.
- Pull requests from forks are skipped automatically because GitHub does not
  expose repository secrets to those runs.

The default non-secret analysis settings live in:

- `sonar-project.properties`
- `qodana.yaml`

Adjust those files after scaffolding if your repository layout or exclusions
diverge from the default `src/` + `tests/` structure.

## Files that evolve during releases

These files are created by the template but are intentionally **not**
scaffold-managed, because release automation updates them over time:

- `CHANGELOG.md`
- `version.txt`
- `.release-please-manifest.json`

That means `scripts/scaffold.* verify` continues to validate the static baseline
without fighting the repository's real release history.
