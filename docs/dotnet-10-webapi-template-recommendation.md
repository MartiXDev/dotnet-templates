# .NET 10 Web API Template Recommendation

## Executive summary

My recommendation is a **hybrid approach**:

- Keep **stable, high-value engineering defaults** inside `MartiX.WebApi.Template`.
- Add only a **small number of important switches** as template options.
- Move **organization-specific, cloud-specific, secret-dependent, and repo-governance setup** to **post-scaffold documentation, scripts, and GitHub repository configuration**.

Companion implementation documents in this repository:

- [`docs\generated-repo-boundary.md`](generated-repo-boundary.md) - canonical ownership boundary and frozen golden-path defaults
- [`docs\scaffold-automation.md`](scaffold-automation.md) - current generated assets, intended automation architecture, rationale, and usage flows
- [`docs\template-validation.md`](template-validation.md) - maintainer validation workflow for pack/install/scaffold/build/test

In short: **do not try to bake literally everything into one template**. Put the repeatable product engineering baseline in the template, and keep environment/repository policy outside the generated codebase.

---

## Recommendation: what should live in the template vs outside it

## What should be scaffolded directly in `MartiX.WebApi.Template`

These items are broadly useful for almost every serious .NET 10 Web API project and should be available immediately after `dotnet new`.

### 1. Solution structure

Keep the current solution-style layout and continue using `.slnx`:

```text
MyProject.slnx
src/
  MyProject.Web/
  MyProject.ServiceDefaults/
  MyProject.AspireHost/
  MyProject.Blazor/           # optional
tests/
  MyProject.Web.Tests/
```

Recommended default projects:

- `Web` - the API host and application entry point
- `ServiceDefaults` - OpenTelemetry, resilience, service discovery, health defaults
- `AspireHost` - local orchestration for development
- `Web.Tests` - test baseline
- `Blazor` - only if you want this repo to stay opinionated toward full-stack demos

### 2. Engineering defaults

These should be built in by default:

- structured logging with Serilog
- OpenTelemetry tracing/metrics/logging hooks
- health endpoints and readiness/liveness patterns
- centralized package version management (`Directory.Packages.props`)
- nullable enabled, implicit usings enabled, analyzers enabled
- consistent formatting and style defaults (`.editorconfig`, `Directory.Build.props` if needed)
- test project with coverage support
- sample API endpoints that demonstrate the architecture
- configuration binding and options validation examples
- Problem Details based error responses
- container-friendly configuration
- local development settings that work out of the box

### 3. API baseline

The template should scaffold a production-shaped API baseline, not just a hello-world app.

Recommended defaults:

- API versioning strategy
- validation pipeline
- Problem Details / exception mapping
- request/response logging guidance
- authentication placeholder integration points
- authorization policy examples
- pagination/filtering/sorting patterns
- idempotent write guidance where relevant
- OpenAPI/Scalar or Swagger setup
- health checks
- sample background job or integration boundary if that is part of your standard architecture

### 4. Data baseline

A useful starter should include:

- one supported primary database path by default
- EF Core configuration and migrations workflow
- seed/sample data only when clearly marked as demo-only
- repository/specification/query-service examples only if they reflect your actual standard

My recommendation: keep **one default database provider** in the main template to reduce complexity. If SQL Server is your main standard, keep it. If not, switch to the provider you expect most users to run every day.

### 5. Documentation scaffold inside generated solution

Every generated solution should contain a minimal but high-quality `README.md` with:

- prerequisites
- first-time setup
- how to run locally
- how to run tests
- how to apply migrations
- how to use Aspire if present
- how configuration and secrets are expected to work

That documentation should be generated with the project name already substituted.

---

## What should not be hard-coded into the template

These areas are too environment-specific, organization-specific, or fast-changing to bake in as mandatory defaults.

### 1. Secrets and cloud provider setup

Do **not** hard-code:

- Azure/AWS/GCP resource names
- production endpoints
- real secrets
- organization-specific Key Vault / Secrets Manager / Vault conventions
- tenant IDs, subscription IDs, private registries, or private feeds

These should be documented and applied after scaffolding.

### 2. Repository governance settings

Do **not** treat GitHub branch protections, required reviewers, environment approvals, or repository secrets as template code concerns.

They should be configured at the GitHub repository or organization level, because they are not reliably enforced by code generation alone.

### 3. Optional infrastructure that not every project needs

Avoid forcing all of these into the default template:

- Redis
- background workers
- message bus
- GraphQL
- search engine integration
- object storage
- feature flags platform
- external identity provider implementation
- deployment IaC for every cloud target

These are better handled through either:

- template switches
- separate sibling templates
- follow-up scripts
- add-on documentation/playbooks

---

## Best strategy for `MartiX.WebApi.Template`

## Preferred approach: keep one strong default template, then add limited options

I recommend this order of evolution:

### Phase 1 - Make the current template excellent

Keep `MartiX.WebApi.Template` as the **golden-path template** and improve it until a new repo can be productive immediately.

That means the current template should include:

- clean solution structure
- build/testable defaults
- observability
- docs
- CI examples
- a few high-value operational conventions

### Phase 2 - Add only a few meaningful template parameters

If you need variation, add only parameters that remove large chunks of complexity, for example:

- `--frontend none|blazor`
- `--orchestrator none|aspire`
- `--database sqlserver|postgres`
- `--auth none|jwt`
- `--container-support true|false`
- `--ci github|none`

Do **not** add dozens of knobs. Too many options make a template hard to maintain and hard to test.

### Phase 3 - Split into sibling templates if the variants diverge too much

If you later find that users want truly different starting points, prefer separate templates such as:

- `martix-webapi` - full recommended solution
- `martix-webapi-minimal` - API + tests only
- `martix-webapi-api-only` - no Blazor, no Aspire host
- `martix-webapi-enterprise` - more batteries included

This is usually better than turning one template into a giant conditional matrix.

## Final answer to your question

**Do not put absolutely everything into the current template.**

Best practice is:

- put the **stable, always-useful engineering baseline** into the template
- put **a few major optional choices** behind template switches
- put **repo policy, secrets, cloud setup, and organization-specific conventions** into scripts, GitHub configuration, and documentation

## Shared scaffold architecture for repo assets

To keep repo-asset automation cross-platform from day one, generated repositories should carry a small internal scaffold layer:

```text
.scaffold/
  scaffold.settings.json
  assets/
    asset-manifest.json
    templates/
  src/
    <Project>.Scaffold/
scripts/
  scaffold.ps1
  scaffold.sh
  bootstrap.ps1
  bootstrap.sh
  update.ps1
  update.sh
```

Recommended responsibilities:

- `.scaffold/assets/asset-manifest.json` is the single source of truth for which non-code assets are materialized during bootstrap/update.
- `.scaffold/assets/templates/` holds reusable content templates for generated repo files such as README, docs, `.github` files, or config files.
- `.scaffold/src/<Project>.Scaffold/` contains the shared .NET runner that reads the manifest and writes assets.
- `scripts/*.ps1` and `scripts/*.sh` stay intentionally thin and only delegate to the shared runner so PowerShell and shell flows do not duplicate asset logic.

This keeps stable assets inside the template while still allowing repeatable bootstrap/update flows for generated repositories.

---

## Recommended “perfect documentation” structure

For new projects, the generated repo should document exactly what to run and in what order.

I recommend a documentation structure like this:

### In the generated project README

1. Prerequisites
   - .NET SDK version
   - container runtime requirements
   - local database requirements
   - optional tooling

2. First-time setup
   - restore packages
   - trust HTTPS certificate if needed
   - set local secrets
   - start local dependencies

3. Run locally
   - run with Aspire
   - run API only
   - run tests
   - run coverage

4. Database workflow
   - create/update database
   - run migrations
   - seed data
   - reset local database

5. Quality workflow
   - build
   - test
   - formatting/linting/analyzers
   - security scanning if configured

6. Deployment/configuration overview
   - environment variables
   - secrets strategy
   - observability endpoints
   - container/deployment notes

7. Troubleshooting
   - common local setup issues
   - missing ports
   - certificate issues
   - stale migrations
   - failed package restore

### In this template repository

I also recommend dedicated docs for:

- template usage and installation
- template parameters and examples
- local template validation workflow
- release/publishing workflow
- generated-repo GitHub setup checklist
- generated-repo first-day setup checklist

This repository now includes dedicated companion documents for the current scaffold automation model and local validation flow:

- [`docs\generated-repo-boundary.md`](generated-repo-boundary.md)
- [`docs\scaffold-automation.md`](scaffold-automation.md)
- [`docs\template-validation.md`](template-validation.md)

---

## Recommended GitHub repository best practices

You asked specifically about GitHub Actions and overall GitHub setup. This should be treated as a first-class part of the repository design.

## For this template repository (`dotnet-templates`)

### Recommended GitHub Actions workflows

#### 1. PR validation workflow
Run on pull requests and pushes to main branches.

Should do at least:

- restore
- build the template pack
- pack the template
- install the produced template package locally in CI
- scaffold a sample project from the packed template
- build the scaffolded solution
- run scaffolded tests

This is the most important workflow because it validates the template as a product, not just as source files.

#### 2. Smoke matrix workflow
Run the template under important variants if you introduce parameters.

Examples:

- with/without Blazor
- with/without Aspire
- different database option
- different auth option

Only add this once you actually have template variants.

#### 3. Release workflow
On tag or release trigger:

- build and pack
- run smoke validation
- publish the template package
- create GitHub release notes

#### 4. Security workflow
Recommended:

- CodeQL for C#
- dependency review on PRs
- NuGet vulnerability monitoring
- secret scanning enabled in GitHub settings

#### 5. Dependency automation
Use Dependabot or Renovate for:

- NuGet package updates
- GitHub Actions updates

### Recommended GitHub repo configuration

For the template repo itself:

- branch protection on main
- required PR checks
- squash merge or rebase merge policy
- CODEOWNERS
- PR template
- issue templates for bug report / template request / improvement request
- release drafter or structured release notes workflow
- labels for `template`, `docs`, `ci`, `breaking-change`, `enhancement`

---

## For generated project repositories

If the generated project is intended to be used in real delivery teams, I recommend scaffolding a `.github` baseline too.

### Recommended generated-repo workflows

#### 1. CI workflow
- restore
- build
- run tests
- publish test results
- collect coverage

#### 2. Container/build artifact workflow
If containers are part of your delivery model:

- build image
- optionally scan image
- publish image on tags or release branches

#### 3. Security workflow
- CodeQL
- dependency review
- secret scanning enabled

#### 4. Optional deployment workflow
Only scaffold this if you know the target platform. Otherwise document it instead.

### Recommended generated-repo files

- `.github/workflows/ci.yml`
- `.github/dependabot.yml`
- `.github/CODEOWNERS`
- `.github/pull_request_template.md`
- issue templates

---

## Prioritized implementation roadmap

This is the order I recommend for actually evolving the repository.

## Guiding rule

Always improve the repository in this sequence:

1. **make the current golden path reliable**
2. **make the generated project understandable**
3. **make the repository automation trustworthy**
4. **only then add variation**

That order prevents the template from growing faster than it can be validated.

### Phase 0 - stabilize the current golden path

Goal: make `MartiX.WebApi.Template` the clearly supported default and remove friction from day-one usage.

Deliverables:

- confirm the default shape stays `Web + ServiceDefaults + AspireHost + Web.Tests`
- decide whether `Blazor` remains default or becomes optional later
- add `.editorconfig`
- add `Directory.Build.props` for shared defaults
- keep `Directory.Packages.props` as the single package version source
- make the generated solution build and test cleanly with one documented command sequence
- ensure the generated repo has a useful top-level `README.md`

Why this is first:

- without a stable baseline, every later option multiplies maintenance cost
- generated repositories must be predictable before you add more features

Success criteria:

- `dotnet new martix-webapi -n SampleApp` works
- the generated solution restores, builds, and tests successfully
- a new user can understand how to run the solution from the generated README alone

### Phase 1 - document the generated developer experience

Goal: make setup and operation explicit, repeatable, and reviewable.

Deliverables:

- generated-project `README.md` template
- exact first-run command list
- exact local development command list
- migration/database workflow documentation
- troubleshooting section for common failures
- explanation of when to run API-only vs Aspire orchestration
- explanation of how local secrets and environment variables should be handled

Recommended output files:

- generated repo `README.md`
- `docs/template-validation.md`
- `docs/generated-project-setup-checklist.md`

Why this is second:

- documentation is part of the product
- once commands and workflows are written down clearly, CI is much easier to codify

Success criteria:

- a reviewer can scaffold a repo and follow the docs without tribal knowledge
- all required commands appear in the documented order

### Phase 2 - add repository automation for this template repo

Goal: treat the template repository like a product that must validate itself end-to-end.

Deliverables:

- `.github/workflows/pr-validation.yml`
- `.github/workflows/release.yml`
- `.github/workflows/codeql.yml`
- `.github/dependabot.yml`
- `.github/CODEOWNERS`
- pull request template
- issue templates

PR validation workflow should:

- restore the template repo
- build the template pack
- pack the template
- install the produced package in CI
- scaffold a fresh sample solution
- build the scaffolded solution
- run scaffolded tests

Why this is third:

- this proves the template works as shipped, not just as source
- GitHub automation becomes the safety net for every future change

Success criteria:

- every PR verifies the template can produce a working repo
- releases are reproducible
- package and workflow updates are managed continuously

### Phase 3 - add generated-repo GitHub baseline

Goal: help teams start with sane repository practices immediately.

Deliverables:

- sample `.github/workflows/ci.yml` in the generated repo
- sample `.github/dependabot.yml`
- sample `CODEOWNERS`
- sample PR template
- optional issue templates if you want project repos standardized

Keep generated-repo automation focused on:

- restore/build/test
- coverage publishing
- dependency updates
- code scanning

Why this comes after template-repo automation:

- you should validate your own template pipeline first
- generated-repo automation is easier to design once this repository has proven patterns

Success criteria:

- new repos start with a minimal but professional GitHub baseline
- teams can adopt the defaults without immediately redesigning CI

### Phase 4 - improve the production-shaped API baseline

Goal: make the generated API closer to what real teams need on day one.

Recommended additions:

- Problem Details standardization
- API versioning
- authentication placeholder or optional JWT mode
- authorization policy examples
- consistent validation and exception mapping
- pagination/filtering/sorting conventions
- container support
- clearer health check and readiness patterns

Why this is not first:

- these improvements matter, but only after the developer experience and validation baseline are solid

Success criteria:

- the template demonstrates opinionated API practices instead of only architectural layout
- teams can keep or remove these defaults without fighting the generated code

### Phase 5 - introduce carefully chosen template options

Goal: allow meaningful variation without turning the template into an unmaintainable matrix.

Recommended first options:

- `--frontend none|blazor`
- `--orchestrator none|aspire`
- `--database sqlserver|postgres`
- `--auth none|jwt`
- `--ci github|none`

Rule for adding an option:

- only add it if there is a recurring, high-value need
- only add it if CI can validate every supported combination
- if too many options interact, split into sibling templates instead

Success criteria:

- the option set stays small
- each supported variant is clearly documented and tested

## Practical priority order

If you want a single concrete backlog, I would do it in this order:

1. generated repo `README.md`
2. `.editorconfig`
3. `Directory.Build.props`
4. template repo PR validation workflow
5. template repo security/dependency automation
6. generated repo GitHub baseline
7. migration/local-run documentation
8. Problem Details + API baseline improvements
9. template options for Blazor/Aspire
10. template options for database/auth

## Keep these outside the template for now

- cloud deployment specifics
- organization branch rules
- repository secrets
- production environment wiring
- provider-specific IaC beyond your main target
- advanced optional subsystems unless they are truly standard for every project

## Consider adding later as template options

- Blazor on/off
- Aspire on/off
- auth mode
- database provider
- caching support

---

## Best long-term model

If your goal is a professional starter for serious teams, the best model is:

1. **one excellent golden-path template**
2. **small number of meaningful template switches**
3. **well-written docs and setup checklists**
4. **GitHub automation that validates the template end-to-end**
5. **later split into sibling templates only if the variants become materially different**

That gives you high quality without creating an unmaintainable template monster.
