# dotnet-templates

Custom .NET 10+ / C# 14+ dotnet template(s) for Web API projects, built on top of [MartiXDev/WebApi](https://github.com/MartiXDev/WebApi).

## Overview

This repository hosts custom `dotnet new` templates that scaffold opinionated Web API projects targeting .NET 10+ and C# 14+.
The templates depend on the [MartiXDev/WebApi](https://github.com/MartiXDev/WebApi) library, which provides the core Web API infrastructure.

## Templates

| Short Name | Description |
|---|---|
| `martixdev-webapi` | Minimal Web API project for .NET 10+ / C# 14+ using MartiXDev/WebApi |

## Requirements

- [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) or later
- C# 14 or later (included with .NET 10 SDK)

## Installation

Install the template pack from NuGet:

```bash
dotnet new install MartiXDev.WebApiTemplate
```

Or install directly from this repository:

```bash
dotnet new install ./templatepack.csproj
```

## Usage

Scaffold a new Web API project:

```bash
dotnet new martixdev-webapi -n MyProject
```

## Repository Structure

```
templates/
  WebApi/                       # Web API project template source
    .template.config/
      template.json             # Template engine configuration
    Program.cs
    WebApiTemplate.csproj
templatepack.csproj             # NuGet template pack project
```

## Dependencies

- **[MartiXDev/WebApi](https://github.com/MartiXDev/WebApi)** – Core Web API library consumed by all templates in this repository.

## License

[MIT](LICENSE)
