# Evaluation knowledge base: mobile

Additive, grounded documentation produced as PR #0. No existing code was modified beyond inserting
comment identifiers; everything else lives here under `.eval/`, apart from the files listed under
"Outside .eval/".

## Contents (47 file(s) added)

- [`CLAUDE.md`](CLAUDE.md): Repo-specific orientation for AI agents (build, identifiers, conventions).
- [`INDEX.md`](INDEX.md): This index: every file this pull request adds.
- [`architecture/Architecture.md`](architecture/Architecture.md): System overview, module table (with [AI] markers), dependency graph.
- [`architecture/guidelines.md`](architecture/guidelines.md): Coding conventions, each backed by ≥2 verbatim code examples.
- [`architecture/modules/design-system-figma-plugin.md`](architecture/modules/design-system-figma-plugin.md): Summary of the `design-system-figma-plugin` module, with the files it names.
- [`architecture/modules/lib-core.md`](architecture/modules/lib-core.md): Summary of the `lib-core` module, with the files it names.
- [`architecture/modules/lib-features-agent.md`](architecture/modules/lib-features-agent.md): Summary of the `lib-features-agent` module, with the files it names.
- [`architecture/modules/lib-features-app-config.md`](architecture/modules/lib-features-app-config.md): Summary of the `lib-features-app-config` module, with the files it names.
- [`architecture/modules/lib-features-auth.md`](architecture/modules/lib-features-auth.md): Summary of the `lib-features-auth` module, with the files it names.
- [`architecture/modules/lib-features-calendar.md`](architecture/modules/lib-features-calendar.md): Summary of the `lib-features-calendar` module, with the files it names.
- [`architecture/modules/lib-features-chat.md`](architecture/modules/lib-features-chat.md): Summary of the `lib-features-chat` module, with the files it names.
- [`architecture/modules/lib-features-featured-jobs.md`](architecture/modules/lib-features-featured-jobs.md): Summary of the `lib-features-featured-jobs` module, with the files it names.
- [`architecture/modules/lib-features-first-win.md`](architecture/modules/lib-features-first-win.md): Summary of the `lib-features-first-win` module, with the files it names.
- [`architecture/modules/lib-features-jobs.md`](architecture/modules/lib-features-jobs.md): Summary of the `lib-features-jobs` module, with the files it names.
- [`architecture/modules/lib-features-notifications.md`](architecture/modules/lib-features-notifications.md): Summary of the `lib-features-notifications` module, with the files it names.
- [`architecture/modules/lib-features-onboarding.md`](architecture/modules/lib-features-onboarding.md): Summary of the `lib-features-onboarding` module, with the files it names.
- [`architecture/modules/lib-features-profile.md`](architecture/modules/lib-features-profile.md): Summary of the `lib-features-profile` module, with the files it names.
- [`architecture/modules/lib-features-referrals.md`](architecture/modules/lib-features-referrals.md): Summary of the `lib-features-referrals` module, with the files it names.
- [`architecture/modules/lib-shared.md`](architecture/modules/lib-shared.md): Summary of the `lib-shared` module, with the files it names.
- [`architecture/modules/lib.md`](architecture/modules/lib.md): Summary of the `lib` module, with the files it names.
- [`architecture/modules/test-app.md`](architecture/modules/test-app.md): Summary of the `test-app` module, with the files it names.
- [`architecture/modules/test-core.md`](architecture/modules/test-core.md): Summary of the `test-core` module, with the files it names.
- [`architecture/modules/test-features-calendar.md`](architecture/modules/test-features-calendar.md): Summary of the `test-features-calendar` module, with the files it names.
- [`architecture/modules/test-features-first-win.md`](architecture/modules/test-features-first-win.md): Summary of the `test-features-first-win` module, with the files it names.
- [`architecture/modules/test-features-jobs.md`](architecture/modules/test-features-jobs.md): Summary of the `test-features-jobs` module, with the files it names.
- [`architecture/modules/test-features-notifications.md`](architecture/modules/test-features-notifications.md): Summary of the `test-features-notifications` module, with the files it names.
- [`architecture/modules/test-features-profile.md`](architecture/modules/test-features-profile.md): Summary of the `test-features-profile` module, with the files it names.
- [`architecture/modules/test-features-referrals.md`](architecture/modules/test-features-referrals.md): Summary of the `test-features-referrals` module, with the files it names.
- [`architecture/modules/test.md`](architecture/modules/test.md): Summary of the `test` module, with the files it names.
- [`architecture/modules/web.md`](architecture/modules/web.md): Summary of the `web` module, with the files it names.
- [`business/BusinessRules.md`](business/BusinessRules.md): Business rules, sourced, marked verifiable (yes/no), linked to @uxid.
- [`business/USPs.md`](business/USPs.md): Unique selling propositions, sourced to docs, mapped to @uxid.
- [`design-system/components.md`](design-system/components.md): The component inventory: every @uxid with its file, flow and type, coverage per flow, then each component’s variant axes, values and states.
- [`design-system/design.json`](design-system/design.json): The whole extracted design system as one record: theme sources, token groups, scales, component variants, composition, disagreements.
- [`design-system/kit.json`](design-system/kit.json)
- [`design-system/playbook.html`](design-system/playbook.html): The design system as one self-contained page. Open it from the checkout; nothing serves it.
- [`design-system/playbook.md`](design-system/playbook.md): The readable playbook: where the theme is declared, the palette and scales, the primitives, and where the app disagrees with itself.
- [`design-system/tokens.json`](design-system/tokens.json): Design tokens: role, family, light/dark pair, utility name, usage count, and every declaration site.
- [`design-system/tokens.md`](design-system/tokens.md): The token catalogue, grouped by the job each token does.
- [`design-system/typography.json`](design-system/typography.json): Fonts, @font-face rules and the type scale, as declared.
- [`knowledge/company.md`](knowledge/company.md): What the company is and sells, in its own sourced words.
- [`knowledge/customers.md`](knowledge/customers.md): Who uses the product, and the outcome each segment came for.
- [`knowledge/glossary.md`](knowledge/glossary.md): Terms the company uses in a specific way, as its material defines them.
- [`knowledge/goals.md`](knowledge/goals.md): What "good" means to this company, each goal with its source.
- [`pipeline.yaml`](pipeline.yaml): Detected stack, the install/build/analyze/test commands, and whether each was run.
- [`product-map.json`](product-map.json): The product in four floors: pages, API actions, the code doing the work, its data.
- [`trace-map.json`](trace-map.json): Every component, element and prompt the scan found, with its id and route.
