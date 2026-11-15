+++
title = "\"Trust-me-bro\" Codemod Benchmarks"
date = 2026-11-16
+++

In the previous [post](https://enismustafaj.github.io/posts/codemod-dependency-upgrades/) I talked about the "pain" that the dependency upgrade process brings into developers' lives and
how codemods and the tool I am building, [Apiweiser](https://apiweiser-cli-fe.vercel.app/), can significantly improve the process. This time I want to present some metrics I gathered based on some evaluations I ran on my machine, to verify the claims I made there.


## Apiweiser Evaluation Setup

### Machine specs

| | |
|---|---|
| **Machine** | MacBook Pro (Mac17,2) |
| **Chip** | Apple M5, 10 cores (4 performance, 6 efficiency) |
| **Memory** | 24 GB |
| **OS** | macOS 26.0 |
| **Docker** | Docker Desktop, Docker Engine 29.0.1, VM with 10 CPUs and ~7.7 GB memory (linux/arm64) |
| **Container image** | `node:22-bookworm` (arm64); Prisma task also runs `postgres:16-alpine` |
| **Container limits** | 2 CPUs, 4 GB memory per run |


### Evaluation Framework
I used the [Harbor](https://www.harborframework.com/) framework to run my evaluation scenarios. I chose Harbor because of how simple it is to configure the evaluation environments and scenarios. This evaluation consisted of 3 scenarios, as follows:

| Scenario | What the agent gets | Codemod |
|---|---|---|
| **A: Plain agent** | Codex with the task instruction only. No skills. | None |
| **B: Apiweiser Skill, no codemod** | Codex plus the `upgrade-dependency` and `codemod` skills and `apiweiser-cli` (`scan`, `plan`, `changelog`, `codemod`). | None published; the agent writes its own codemod wherever the CLI finds call sites. |
| **C: Apiweiser Skill + published codemod** | Same as B. | The task's codemod is published under `@apiweiser`, so `apiweiser-cli codemod` finds it and the agent runs it instead of writing one. Built for 4 of the 6 tasks (openai, @reduxjs/toolkit, zod, NestJS). |

**Task Description:**

The evaluation has six tasks. In each one the agent works on a real open-source repo, pinned to a fixed commit with its dependencies installed, and has to upgrade one library by a major version.

The same rules apply to every task:

- The target library ends up on the new major version and is installed.
- `npm install` succeeds without peer-dependency errors and without `--force` or `--legacy-peer-deps`.
- Any other dependency that has to move along is upgraded, and nothing else is.
- Tests and test config stay as they are.
- Errors aren't hidden with `eslint-disable` or, where the task says so, with `@ts-ignore` or `as any`.
- The agent works without asking questions.

1. lot-redux-toolkit-1-to-2

- **Starting point:** `mocca-dev/lot`, a JavaScript app on Redux Toolkit 1.
- **What to do:** upgrade `@reduxjs/toolkit` to 2.x and update the code for it.
- **Done when:** `npm run lint`, `npm run build` and `npm test` pass, and every slice gives the same state for the same actions as before. That includes the pending, fulfilled and rejected actions of each async thunk, which a hidden test checks. The vitest config must stay as it is.

2. nest-starter-nestjs-7-to-8

- **Starting point:** `nestjs/typescript-starter`, the official NestJS starter, on NestJS 7.
- **What to do:** upgrade NestJS to 8 (`@nestjs/core` on 8.x).
- **Done when:** `npm run build`, `npx tsc --noEmit`, `npm test` and `npm run test:e2e` all pass. The unit and e2e tests and the jest config stay as they are.

3. node-express-realworld-prisma-4-to-7

- **Starting point:** `gothinkster/node-express-realworld-example-app`, an Express API built with Nx, on Prisma 4. Upstream, six tests fail because of the order a mock is imported in. The task starts from a one-line fix for that, so the tests pass before the upgrade.
- **What to do:** upgrade `prisma` and `@prisma/client` to 7.x, crossing three major versions, and update both the code and the Prisma config.
- **Done when:** `npx nx build` and `npx nx test` pass, and the app still works against a real PostgreSQL database, whose URL is in `DATABASE_URL`. A hidden test checks the database part.

4. node-typescript-boilerplate-eslint-8-to-9

- **Starting point:** `jsynowiec/node-typescript-boilerplate`, a TypeScript template on ESLint 8 with the old config format.
- **What to do:** upgrade ESLint to 9, which mainly means moving the config to the new flat-config format.
- **Done when:** `npm run lint`, `npm run build` and `npm test` pass, and linting enforces exactly what it did before: the same rule sets, overrides, test-file rules and ignored paths. A hidden test checks that, and the agent must not add a vitest config.

5. openai-quickstart-openai-3-to-4

- **Starting point:** `openai/openai-quickstart-node`, OpenAI's small Next.js sample app, on `openai` 3.
- **What to do:** upgrade `openai` to 4.x, which moves from the old `Configuration`/`OpenAIApi` setup to the new `OpenAI` client.
- **Done when:** `npm run build` passes, and `pages/api/generate.js` behaves exactly as before: same model, prompt and responses. That includes the error responses for a missing API key, an empty animal name, and an error from the OpenAI API. A hidden test checks this against a fake OpenAI API.

6. ynab-mcp-zod-3-to-4

- **Starting point:** `auzroz/ynab-mcp`, an MCP server for YNAB written in TypeScript, on zod 3.
- **What to do:** upgrade `zod` to 4.x using zod 4's own API. Importing from `zod/v3` isn't allowed.
- **Done when:** `npm run build`, `typecheck`, `lint` and `test` pass, and every tool accepts and rejects the same input as it did under zod 3. A hidden test checks that, and the test, lint and TypeScript config, including the `package.json` scripts, must stay as they are.

## Evaluation Results

The following table shows the metrics collected from all the runs, combined per task and scenario.

| Scenario | Task                                      | Passed  | Cost per run (mean) | Agent time (mean) | Turns (mean) |
| -------- | ----------------------------------------- | ------- | ------------------- | ----------------- | ------------ |
| A        | lot-redux-toolkit-1-to-2                  | **5/5** | $0.0068             | 44s               | 12           |
| A        | nest-starter-nestjs-7-to-8                | **0/5** | $0.0060             | 88s               | 18           |
| A        | node-express-realworld-prisma-4-to-7      | **5/5** | $0.0179             | 124s              | 37           |
| A        | node-typescript-boilerplate-eslint-8-to-9 | **4/5** | $0.0146             | 118s              | 28           |
| A        | openai-quickstart-openai-3-to-4           | **4/5** | $0.0047             | 37s               | 13           |
| A        | ynab-mcp-zod-3-to-4                       | **5/5** | $0.0086             | 108s              | 13           |
| B        | lot-redux-toolkit-1-to-2                  | **5/5** | $0.0299             | 187s              | 37           |
| B        | nest-starter-nestjs-7-to-8                | **5/5** | $0.0173             | 147s              | 25           |
| B        | node-express-realworld-prisma-4-to-7      | **5/5** | $0.0264             | 246s              | 34           |
| B        | node-typescript-boilerplate-eslint-8-to-9 | **5/5** | $0.0206             | 202s              | 30           |
| B        | openai-quickstart-openai-3-to-4           | **4/5** | $0.0249             | 181s              | 41           |
| B        | ynab-mcp-zod-3-to-4                       | **5/5** | $0.0407             | 297s              | 44           |
| C        | lot-redux-toolkit-1-to-2                  | **5/5** | $0.0083             | 61s               | 13           |
| C        | nest-starter-nestjs-7-to-8                | **5/5** | $0.0064             | 92s               | 10           |
| C        | openai-quickstart-openai-3-to-4           | **5/5** | $0.0091             | 71s               | 18           |
| C        | ynab-mcp-zod-3-to-4                       | **5/5** | $0.0170             | 148s              | 23           |


### Observations

1. **The published codemod was the only setup that passed every run.** Scenario C passed 20 out of 20 runs, B passed 29 out of 30 and the plain agent passed 23 out of 30. If we compare only the four tasks that have a published codemod, the plain agent passed 14 out of 20, the skill without a codemod 19 out of 20 and the skill with a codemod 20 out of 20. As a developer you usually run the agent once, so I care more about "does it work every time" than "does it work most of the time".

2. **The plain agent does not know when to stop upgrading.** NestJS was the biggest gap: the plain agent failed all 5 runs, while B and C passed all of them. The agent did get NestJS 8 working, but every time it also bumped `@nestjs/cli`, `@nestjs/schematics` and `typescript`, which the task did not need. This is exactly the noisy PR I talked about in the previous post. With Apiweiser, the `plan` step tells the agent which versions actually have to move, so B and C changed only the packages that needed to change.

3. **Peer dependencies are where the plain agent struggles.** npm reported a peer-dependency conflict (`ERESOLVE`) in 13 of the 30 plain agent runs, in 9 of the 30 B runs and in none of the C runs. NestJS shows it best: the plain agent hit the conflict in 4 of 5 runs, while B and C did not hit it at all. The one ESLint failure of the plain agent is a good example: it installed ESLint 9, but kept a `typescript-eslint` version that does not support it, so linting crashed with `Error while loading rule '@typescript-eslint/no-unused-expressions'`. B passed all 5 ESLint runs.

4. **Using the skill without a codemod is the most expensive option.** On average B cost about 2.7 times more than the plain agent and took about 2.4 times longer. Most of that time goes to writing a new codemod: the agent created one in 19 of the 30 runs and decided it was not worth it in the other 11. It paid off on NestJS and ESLint, but on Prisma, where the plain agent already passed 5 out of 5, it doubled the time (124s → 246s) without passing more runs.

5. **A published codemod makes the agent cheaper and faster.** Once the codemod exists, the agent does not need to figure out the API changes, it just runs the codemod and fixes what is left. On the same four tasks, C cost about $0.010 per run compared to $0.028 for B, and took 93s instead of 203s. Compared to the plain agent it costs a bit more per run ($0.010 vs $0.0065), but since the plain agent failed 6 of those 20 runs, the cost per successful run ends up almost the same ($0.0102 vs $0.0093). On NestJS, C even needed fewer turns than the plain agent (10 vs 18).

6. **The codemod makes the result repeatable.** For Redux Toolkit, all 5 C runs produced the exact same diff, while the plain agent produced three different diffs over 5 runs. NestJS was identical in all C runs and OpenAI in 4 out of 5. For zod the C diffs still differ, since the codemod covers only part of the upgrade and the agent does the rest. This is the deterministic part of the codemod approach showing up in the numbers.

7. **"It builds" does not mean "it works".** The plain agent and B each failed one OpenAI run even though the build passed. In OpenAI v4 the client throws an error as soon as it is created without an API key, so the app's own "API key is missing" response was never returned. Only a hidden test that checks the behaviour caught it. C passed all 5 runs here because the codemod keeps that check in place.

8. **No agent cheated.** None of the 80 runs changed, skipped or deleted a test file. All the passes come from actual upgrades, not from editing the tests until they pass.


## What could skew these numbers

These numbers come from my own machine and my own setup, so before you trust them (hence the "trust-me-bro" in the title), here are the things that can make them look better or worse than they really are:

1. **The docs do not list all the API changes.** Apiweiser builds its context from the changelogs and release notes of the library. If a breaking change is missing there, the agent does not know about it, even when it uses the skill, and the codemod it writes will not cover it. The upgrade then only works if the tests happen to catch the problem.

2. **The agent does not use the skill.** A skill is only a suggestion, and the agent decides whether to use it. In this evaluation every B and C run used `apiweiser-cli`, but in 11 of the 30 B runs the agent decided not to write a codemod. With another model or harness, the agent could skip the skill completely and behave like the plain agent.

3. **The model is already trained on these upgrades.** Popular upgrades like Prisma, zod or Redux Toolkit are most likely in the model's training data, together with lots of blog posts and migration guides about them. This makes the plain agent look better than it would on a less known library or on a version released after the model was trained, which is exactly where Apiweiser should help the most.

4. **Five runs per task is a small sample.** One failed run changes the pass rate of a task by 20%. The big differences, like NestJS, are clear, but the small ones, like the single OpenAI or ESLint failures, could easily change with more runs.

5. **One model and one harness.** All the runs used Codex with the same model. Other agents, models or reasoning effort settings could give different results, both for the plain agent and with the skill.

6. **I wrote the tasks and the graders.** The hidden tests check what I think matters in each upgrade, like the async thunk actions or the lint rules. A different person could write stricter or looser checks and get different pass rates.
