# dotnet-templates

Custom .NET 10+ / C# 14+ dotnet templates for solution-style Web API projects, built on top of [MartiXDev/WebApi](https://github.com/MartiXDev/WebApi).

## Overview

This repository hosts custom `dotnet new` templates that scaffold opinionated Web API solutions targeting .NET 10+ and C# 14+.
The templates depend on the [MartiXDev/WebApi](https://github.com/MartiXDev/WebApi) library, which provides the core Web API infrastructure.

## Templates

| Short Name | Description |
|---|---|
| `martix-webapi` | Multi-project Web API solution template with Aspire host, Blazor frontend, service defaults, API, and tests |

## Requirements

- [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) or later
- C# 14 or later (included with .NET 10 SDK)

## Installation

Install the template pack from NuGet:

```bash
dotnet new install MartiX.Dotnet.Templates
```

Or install directly from this repository:

```bash
dotnet new install .
```

## Usage

Scaffold a new Web API solution:

```bash
dotnet new martix-webapi -n MyProject
```

Then materialize the scaffold-managed repository assets:

```bash
cd MyProject
./scripts/bootstrap.sh
```

PowerShell equivalent:

```powershell
Set-Location .\MyProject
.\scripts\bootstrap.ps1
```

The generated output is a solution-style template with renamed project and namespace placeholders based on the name you pass to `-n`.

```text
MyProject.slnx
src\
  MyProject.AspireHost\
  MyProject.Blazor\
  MyProject.ServiceDefaults\
  MyProject.Web\
tests\
  MyProject.Web.Tests\
```

## Documentation

Start with the [maintainer documentation hub](docs/README.md) for the current doc map and links to the detailed guides.

- [Maintainer documentation hub](docs/README.md) - primary entry point for template boundary, roadmap, scaffold automation, validation, bootstrapping, and generated repo release/AI guidance

## Maintainer helpers

The repository root also includes helper scripts for validating the generated bootstrap/update flow:

- `.\scripts\refresh-generated-assets.ps1` / `./scripts/refresh-generated-assets.sh`
- `.\scripts\verify-generated-assets.ps1` / `./scripts/verify-generated-assets.sh`

## Repository Structure

```
scripts/
  refresh-generated-assets.ps1
  refresh-generated-assets.sh
  verify-generated-assets.ps1
  verify-generated-assets.sh
templates/
  MartiX.WebApi.Template/       # Web API solution template source
    .template.config/
      template.json             # Template engine configuration
    MartiX.WebApi.Template.slnx # Generated solution entry point
    src/
      MartiX.WebApi.Template.AspireHost/
      MartiX.WebApi.Template.Blazor/
      MartiX.WebApi.Template.ServiceDefaults/
      MartiX.WebApi.Template.Web/
    tests/
      MartiX.WebApi.Template.Web.Tests/
MartiX.Dotnet.Templates.csproj  # NuGet template pack project
```

## Dependencies

- **[MartiXDev/WebApi](https://github.com/MartiXDev/WebApi)** - Core Web API library consumed by all templates in this repository.

## License

[MIT](LICENSE)
