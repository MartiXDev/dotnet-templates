# MartiX.WebApi.Template troubleshooting

## Docker or Aspire issues

### Aspire host fails before the app starts

- Skip this section if you scaffolded with `--orchestrator none`.
- Make sure Docker Desktop is running.
- Confirm that local ports `25`, `37408`, `57379`, and `57380` are available.
- If you only need the API stack, try the API-only Aspire host when it is present:

```powershell
dotnet run --project .\src\MartiX.WebApi.Template.AspireHost\MartiX.WebApi.Template.AspireHost.NoBlazor.csproj
```

```sh
dotnet run --project ./src/MartiX.WebApi.Template.AspireHost/MartiX.WebApi.Template.AspireHost.NoBlazor.csproj
```

## Database issues

### `AppDb connection string is required`

The Web project expects `ConnectionStrings__AppDb` to resolve. The easiest fix is to run through an Aspire host project instead of the Web project directly.

If you intentionally run the Web project directly, provide a valid SQL Server connection string through:

- `src\MartiX.WebApi.Template.Web\appsettings.json`
- `src\MartiX.WebApi.Template.Web\appsettings.Development.json`
- environment variables
- user secrets

### Development startup keeps deleting my database

`src\MartiX.WebApi.Template.Web\appsettings.Development.json` enables `DatabaseOptions:RecreateOnStartup`.

Set it to `false` when you want to preserve local data between runs.

### EF Core migration commands fail

- Make sure the .NET SDK is installed and available on `PATH`.
- Run migration commands from the repository root and point them at `src\MartiX.WebApi.Template.Web\MartiX.WebApi.Template.Web.csproj`.
- Confirm your SQL Server target is reachable before applying migrations manually.

## Build and test issues

### `dotnet test` fails after a fresh clone

Run the full baseline first:

PowerShell:

```powershell
dotnet restore
dotnet build
dotnet test --solution .\MartiX.WebApi.Template.slnx
```

Shell:

```sh
dotnet restore
dotnet build
dotnet test --solution ./MartiX.WebApi.Template.slnx
```

If `dotnet test` complains that the VSTest target is no longer supported on .NET 10 SDKs, make sure the generated `global.json` file is still present at the repository root so the CLI stays opted in to Microsoft.Testing.Platform.

### `dotnet format whitespace --verify-no-changes` fails

The generated CI workflow runs `dotnet format whitespace --verify-no-changes` before building.

Reproduce it locally from the repository root:

```powershell
dotnet format whitespace .\MartiX.WebApi.Template.slnx --verify-no-changes --no-restore
```

If that command fails, run `dotnet format whitespace .\MartiX.WebApi.Template.slnx` once to apply the scaffolded `.editorconfig` defaults, then rerun the verify command.

### `dotnet build` fails in CI because warnings are treated as errors

CI builds the Release configuration with `-p:TreatWarningsAsErrors=true` while keeping `CS1591`, `NU1902`, and `ASPIRE002` as non-fatal warnings for the starter baseline.

Reproduce the same gate locally:

```powershell
dotnet build .\MartiX.WebApi.Template.slnx --no-restore --configuration Release -p:TreatWarningsAsErrors=true
```

Fix the warning or suppress it intentionally in code or configuration before merging.

### Markdown lint fails or `markdownlint-cli2` is missing locally

CI installs Node.js automatically and runs:

```sh
npx --yes markdownlint-cli2 "README.md" "CONTRIBUTING.md" "docs/SETUP.md" "docs/RELEASE.md" "docs/TROUBLESHOOTING.md" "docs/SCAFFOLDING.md" ".github/pull_request_template.md"
```

If the command is missing locally, install Node.js 20 or later first. The scaffolded `.markdownlint-cli2.jsonc` file in the repository root stays the source of truth for the rules.

### CI reports a PowerShell script parse error

The workflow validates generated `.ps1` files under `scripts\` with the built-in PowerShell parser, so failures usually point to syntax issues rather than style-only issues.

Run the syntax validation snippet from [`docs\SETUP.md`](SETUP.md#powershell-script-syntax-validation) after editing scripts to reproduce the exact failure locally.

### Coverage artifacts are missing from CI

Raw coverage files should still land under `.artifacts\test-results` because the test step runs with `--coverage --coverage-output-format cobertura`.

The separate `coverage-report` artifact only appears when one or more `*.cobertura.xml` files are generated. If the report is missing, inspect the `test-results` artifact first and make sure the test step completed far enough to emit coverage output.

### The Blazor project is not needed right now

The template generates the Blazor project by default. For local API work, use the API-only Aspire host instead of removing projects immediately.

If you have not scaffolded the repository yet and already know you do not want the frontend, start with:

```powershell
dotnet new martix-webapi -n YourApp --frontend none
```

### The Aspire AppHost is not needed right now

The template keeps the AppHost on the golden path by default. If you do not want it for a new repository, scaffold with `--orchestrator none` and use the Web project as the primary entry point instead.

## Email and local service issues

### Emails are not visible during development

The default development setup expects Papercut on `localhost:25` with the UI on `http://localhost:37408`.

If you are not running Aspire, make sure you have a compatible SMTP test server running or update the mail settings in `src\MartiX.WebApi.Template.Web\appsettings.json`.

## Scaffold-managed docs

### `docs\SCAFFOLDING.md` is missing

That file is generated by the scaffold scripts, not copied directly with the template source.

Run:

PowerShell:

```powershell
.\scripts\bootstrap.ps1
```

Shell:

```sh
./scripts/bootstrap.sh
```
