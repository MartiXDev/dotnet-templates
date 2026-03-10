## Summary

- describe the template or documentation change
- link the relevant recommendation or validation guidance when applicable

## Validation

- [ ] `dotnet build .\MartiX.Dotnet.Templates.csproj -nologo`
- [ ] `dotnet pack .\MartiX.Dotnet.Templates.csproj -o .\bin\Release -nologo`
- [ ] `.\scripts\verify-generated-assets.ps1 -SampleName SampleApp -OutputRoot bin\generated-assets`

## Checklist

- [ ] docs updated when generated behavior changed
- [ ] `templates\MartiX.WebApi.Template\.scaffold\assets\asset-manifest.json` updated when scaffold-managed assets changed
- [ ] scaffold-managed assets refreshed when source templates changed
- [ ] no unrelated template content was modified
