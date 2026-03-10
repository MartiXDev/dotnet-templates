# Template maintainer documentation hub

Start here when you need to change the template pack, the generated repository contract, or the maintainer validation flow.

## Core maintainer guides

- [Generated repo boundary and default stack](generated-repo-boundary.md) - canonical split between template source, scaffold-managed assets, opt-in bootstrap automation, and external or org-specific setup.
- [Template recommendation and roadmap](dotnet-10-webapi-template-recommendation.md) - strategic guidance for what belongs in the template, what stays outside it, and the phased evolution plan.
- [Scaffold automation architecture](scaffold-automation.md) - current generated asset set, manifest-driven bootstrap or update model, and source references.
- [Template validation guide](template-validation.md) - pack, install, scaffold, bootstrap, build, and test checks for maintainers.
- [Bootstrapping tips](bootstrapping-tips.md) - supporting guidance for CI, formatting, coverage, release automation, and quality tooling.

## Generated repository baseline docs

These files live under the template source because they are scaffolded into generated repositories:

- [Generated repo README](../templates/MartiX.WebApi.Template/README.md) - first-run, local workflow, and quality baseline as users receive it.
- [Release and governance baseline](../templates/MartiX.WebApi.Template/docs/RELEASE.md) - Conventional Commits, Release Please, and token-gated quality tooling.
- [AI skills and Copilot bootstrap](../templates/MartiX.WebApi.Template/docs/AI-SKILLS.md) - declaration-first AI setup, marketplace guidance, and opt-in helper commands.
- [Generated repo scaffolding doc](../templates/MartiX.WebApi.Template/docs/SCAFFOLDING.md) - what bootstrap, update, and verify manage inside scaffolded repositories.
- [Generated repo setup](../templates/MartiX.WebApi.Template/docs/SETUP.md) and [troubleshooting](../templates/MartiX.WebApi.Template/docs/TROUBLESHOOTING.md) - operational docs to spot-check when scaffold-managed assets change.

## Fast path

1. Start with this hub.
2. Use the boundary doc for scope decisions.
3. Use the validation guide before and after docs, scaffold, release, governance, or AI-related changes.
