# Quick Overview of Recommended Resources

| **Resource** | **Focus** | **Why Read It** | **What to Take Away** |
| --- | ---: | --- | --- |
| **GitHub Docs - Building and testing .NET** | CI templates and `setup-dotnet` for GitHub Actions | Official guidance for .NET workflows in GitHub Actions. | How to structure build and test workflows and configure `setup-dotnet`. |
| **Microsoft Learn - GitHub Actions and .NET** | Actions concepts and workflow examples | Explains how GitHub Actions fits into the .NET development workflow. | Jobs, matrices, and common workflow stages such as build, test, and publish. |
| **EditorConfig (Microsoft Learn + community guides)** | `.editorconfig` for C# and Roslyn analyzers | Shows how to share and enforce coding style across IDEs and contributors. | Recommended rules, `root = true`, and analyzer severity configuration. |
| **dotnet format / dotnet CLI** | Formatting and automated fixes based on `.editorconfig` | Useful for CI formatting validation and automated style enforcement. | How to use `dotnet format --verify-no-changes` in CI and integrate it with problem matchers. |
| **Coverlet + ReportGenerator + Codecov** | .NET code coverage and Codecov upload | A modern, cross-platform approach to coverage reporting. | `dotnet test /p:CollectCoverage=true` plus report generation in Cobertura or OpenCover format. |

---

## Recommended Study Order

1. **GitHub Actions + .NET (GitHub Docs, Microsoft Learn)** - Learn how to run builds, tests, and artifact publishing. This is the operational foundation for the rest of the setup.
2. **EditorConfig + Roslyn analyzers** - Standardize formatting and rule enforcement across the team. Set severities such as `suggestion`, `warning`, and `error` so CI fails on violations that matter.
3. **`dotnet format` in CI** - Add automatic formatting validation before merge. Treat it as a linting gate.
4. **Test coverage (Coverlet + ReportGenerator + Codecov)** - Measure coverage, generate HTML reports, and upload results for visibility and trend tracking.
5. **Commit conventions + automated versioning (Conventional Commits + Release Please)** - Enable reliable version calculation and changelog generation directly from commit history.
6. **Static analysis (SonarCloud / SonarQube / Qodana)** - Add security, duplication, and complexity checks to pull request validation when the repository is ready to wire tokens and variables.

---

## Recommended Baseline Artifacts for Any .NET 10+ Repository

- **`.editorconfig`** at the repository root with C# style rules and analyzer severities aligned with team expectations.
- **`dotnet format` lint job** in GitHub Actions using verify mode.
- **Unit and integration test job** using `dotnet test` with coverage collection enabled.
- **Coverage report generation and upload** using ReportGenerator and Codecov.
- **Commit linting and Conventional Commits enforcement** using GitHub Actions plus a `CONTRIBUTING.md` file.
- **Automated releases / semantic versioning** using Release Please and a GitHub release workflow.
- **Static analysis** using token-gated SonarCloud/SonarQube or Qodana workflows for pull request gating.
- **IDE setup assets** such as `.editorconfig`, recommended Visual Studio or VS Code settings, and optionally a dev container.

---

## Configuration Patterns to Copy into `.github/workflows`

### 1) Lint / format validation (`dotnet format`)

```yaml
name: Lint C#
on: [push, pull_request]
jobs:
  format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'
      - name: Install dotnet-format
        run: dotnet tool update --global dotnet-format
      - name: Run dotnet format (verify)
        run: dotnet format --verify-no-changes
```

This step returns a non-zero exit code when the codebase does not match the `.editorconfig` rules.

### 2) Build + test + coverage (Coverlet + ReportGenerator)

```yaml
name: Build Test Coverage
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'
      - name: Restore
        run: dotnet restore
      - name: Build
        run: dotnet build --no-restore -c Release
      - name: Test with coverage
        run: dotnet test --no-build -c Release /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura
      - name: Generate coverage report
        run: reportgenerator -reports:"**/coverage.cobertura.xml" -targetdir:"coverage" -reporttypes:Html
      - name: Upload coverage artifact
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage
```

Coverlet integrates coverage collection through MSBuild parameters, and the generated results can then be uploaded to Codecov.

### 3) Automated versioning and releases (Conventional Commits + Release Please)

- Use **Conventional Commits** as the repository commit standard. Then let
  Release Please open release pull requests, update `CHANGELOG.md`, bump
  `version.txt`, and publish GitHub Releases from the default branch history.
  The commit convention documentation is the prerequisite.

---

## Recommended `.editorconfig` Starting Point

```ini
root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
trim_trailing_whitespace = true
indent_style = space
indent_size = 4

[*.cs]
dotnet_sort_system_directives_first = true
csharp_style_var_for_built_in_types = false:suggestion
csharp_style_namespace_declarations = file_scoped:warning
# analyzers severity example
dotnet_diagnostic.CA1822.severity = warning
```

Place this file at the repository root and keep `root = true` so the rules are inherited consistently and do not get overridden by parent folders.

---

## Recommendations for Commit Conventions, Versioning, and CI/CD Rules

- **Conventional Commits** - Use prefixes such as `feat:`, `fix:`, `chore:`, `perf:`, and `refactor:`. Use `BREAKING CHANGE:` or `!` when a change should trigger a major version bump.
- **Automated releases** - For .NET repositories, a strong default is: use
  Release Please to create release pull requests from Conventional Commits,
  publish a Git tag plus GitHub Release, and let repository-specific workflows
  attach build artifacts such as zip files or NuGet packages when needed.
- **Separate CI and CD** - Keep CI workflows for build, test, and linting separate from CD workflows for release and publishing. CD should typically run only on `main` or release branches and only after CI passes.
- **Pull request gating** - Require successful checks for build, test, format validation, and SonarCloud analysis if static analysis is enabled.

---

## Where to Find Ready-Made Templates and Reference Repositories

- **GitHub Actions .NET workflow template** - Available directly in the GitHub Actions UI as the `.NET` template.
- **Meziantou / CsharpProjectTemplate** - Good examples of `.editorconfig` usage and `dotnet format` in CI.
- **Coverlet + Codecov examples** - Many open-source .NET projects use `coverlet.collector` and the Codecov Action. Review established OSS workflow files for practical patterns.

---

## Common Pitfalls and How to Avoid Them

- **Inconsistent `.editorconfig` application** - Different contributors using different IDEs without `root = true` leads to inconsistent formatting and analyzer behavior.
- **`dotnet format` does not fix everything** - Some Roslyn analyzer findings are not automatically fixable. Plan for a combination of analyzers and `dotnet format`, not formatting alone.
- **Coverage false positives** - Exclude `obj/`, `bin/`, and generated code from coverage reports to avoid distorted metrics.
- **Automated releases without test guarantees** - Never allow the release workflow to run without a successful CI pass first.

---

## Immediate Next Decision

Choose one of these areas to implement first: EditorConfig + `dotnet format`, test coverage, or automated versioning. Once that priority is selected, the next step can be a copy-paste-ready workflow and supporting files for this repository.
