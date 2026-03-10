# AI skills and Copilot bootstrap for MartiX.WebApi.Template

This repository ships with GitHub and Copilot-friendly AI bootstrap assets, but
it does not install plugins, skills, or marketplace sources automatically.
Everything here is declaration-first and opt-in.

## Included repository assets

- `.github\copilot-instructions.md` - repository-specific Copilot guidance for
  build, test, architecture, and AI asset usage
- `.copilot\mcp-config.json` - repository-level GitHub MCP declaration that uses
  `GITHUB_TOKEN`
- `scripts\setup-ai.ps1` - opt-in helper that lists recommendations, supports
  dry-run marketplace setup, and can explicitly install selected MartiX plugins

## Recommended MartiX marketplace plugins

Register the marketplace once:

```powershell
copilot plugin marketplace add MartiXDev/ai-marketplace
copilot plugin marketplace browse martix-ai-marketplace
```

Recommended packages for this template:

- `martix-webapi` - primary MartiX.WebApi planning and implementation guidance
- `martix-dotnet-csharp` - .NET 10 and C# 14 baseline implementation help
- `martix-fastendpoints` - FastEndpoints endpoint, contract, and testing guidance
- `martix-fluentvalidation` - validator authoring and ASP.NET Core integration
- `martix-tunit` - TUnit test authoring and migration guidance

Use the helper script to review or install them explicitly:

```powershell
.\scripts\setup-ai.ps1
.\scripts\setup-ai.ps1 -RegisterMarketplace -InstallRecommendedMartiX -DryRun
.\scripts\setup-ai.ps1 -RegisterMarketplace -Plugins martix-webapi,martix-tunit
```

The helper script supports both `-DryRun` and PowerShell `-WhatIf`.

## Selected external skill recommendations

These stay external on purpose. Install only the packs that match your workflow:

```text
npx skills add https://github.com/aaronontheweb/dotnet-skills --skill modern-csharp-coding-standards
npx skills add https://github.com/aaronontheweb/dotnet-skills --skill efcore-patterns
npx skills add https://github.com/aaronontheweb/dotnet-skills --skill dotnet-project-structure
npx skills add https://github.com/anthropics/skills --skill frontend-design
npx skills add https://github.com/anthropics/skills --skill skill-creator
```

You can print the same curated command list at any time with:

```powershell
.\scripts\setup-ai.ps1 -PrintExternalSkillCommands
```

## Reference sources

- MartiX AI marketplace:
  <https://github.com/MartiXDev/ai-marketplace>
- MartiX recommended skills shortlist:
  <https://github.com/MartiXDev/ai-marketplace/blob/main/docs/recommended-skills.md>
- GitHub Copilot CLI plugin docs:
  <https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-finding-installing>
- skills.sh docs:
  <https://skills.sh/docs>
