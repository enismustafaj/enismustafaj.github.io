+++
title = "Dependency Upgrades with Codemods and AI"
date = 2026-10-18
+++

 Lately, I have spent too many hours to upgrade dependencies my services use and updating each one of them and the dependencies they rely on, just to figure out the whole underlying framework has to be migrated to the new major version so that the new packages would not have "critical" vulnerabilities. Developers have to update dependencies to patch vulnerabilities, adopt new APIs or replace deprecated ones, and when organizations require "zero-vulnerability" versions, that work takes time away from building features for customers.

## Existing tools

There are a few tools in the market, usually integrated into the codebase hosting platform, such as Dependabot and Renovate, that provide developers with new available and vulnerability-free versions. They would either send you a daily/weekly report with all the necessary changes and even raise a Code Changes for you. However, this approach doe not really solve the whole problem, as a few challenges persist.

## Existing challenges

The existing tools that try to assist developers in keeping their dependencies up to date bring challenges such as:

1. **Version upgrades don’t indicate code changes.**  Knowing only the version to which you need to upgrade does not make your life easier.  Every week I get the report from Dependabot in Github with the new version of my vulnerable packages I use, but as a engineer, usually I have no idea what would the implication be for my codebase.  You will have to go through change logs and release notes to understand the changes, not neccessarily the latest ones if you are updating multiple major versions. So the developers need to make themselves familiar with the new API and its implications to their code base.  

2. **Version Upgrades need to be performed for each codebase you own.** The same vulnerable/deprecated packages are usually used in every codebase that a team has ownership over. My team owns multiple services and codebases, and we spend quite some time going over each one of them and updating the packages over and over and sometimes asking AI to do it for each one of them results in context overflow and compacting it will result in information loss. Even though the developers get some familiarity on each upgrade, each codebase has its own uniqueness in terms of business domain implementation and the usage of the package itself. 

3. **Libraries do not operate alone**. Libraries usually are built on top of other packages, and they require their dependencies to be pre-installed. Upgrading the version of one library in your codebase could break the constraints that were set regarding its peer dependencies, as it is called in Javascript/Typescript world.

4. **The latest change logs do not tell the whole story**. The more major versions you upgrade, the more challenging it gets to adjust you codebase. Usually, the major version upgrades introduce breaking changes in the library APIs and jumping more than one means that you need to review all the versions in between.

## Codemod to the rescue

#### What is a Codemod?

Codemod (short for “code modification”) is a package of code transformation. It works with the Abstract Syntax Tree (AST) of the codebase by parsing, transforming, and generating the new version of the code. It makes precise code modifications without breaking unrelated code to the rules defined in the Codemod. More about Codemod [here](https://codemod.com/blog/what-are-codemods).

#### Codemod, Dependencies and AI

The API changes that the new version of the packages introduces are syntactically the same across codebases. This is what makes the codemod approach very useful. To apply the new version's API change, you need to know how the current version is used in the codebase, like what api surface is used. In addition, you need to note down all the breaking changes on the change logs and release notes of those libraries. Regarding the former, static code analysis tools can be used to parse the code in "Abstract Syntax Tree" structure and finding all the usages of the dependency you want to upgrade. Regrading the latter, AI can be utilized to make this process faster, since LLM models are quite good in gathering and summarizing information. Having all this information at hand as context for the LLM, AI agents harnesses, specialized in crafting codemods, can be used create the codemod package. Some of the benefits of this approach are:

1. **Deterministic and repeatable**. The same input always produces the same output. Run it again after a rebase, on a new branch, or after a teammate added code that uses the old API, and you get a consistent result. Asking an agent twice can give you two different answers.

2. **Tested before it touches your code**. A codemod comes with before/after test fixtures, so the transformation is checked on its own, independently of whether your project's test suite happens to cover the changed code.

3. **Reusable across projects**. A codemod produced by an agent helps one repo, once. A codemod for "lib X, 5 → 6" works for every project making that jump. Codemods can be shared in private, internal to an organization, or public registries, so that they be can accessible by agents.

4. **It gets cheaper over time**. The LLM cost is paid once, when the codemod is written. Every later run is a fast, local AST transformation with no tokens, no rate limits, and no timeouts.

5. **Precise on large codebases**. An agent working file by file can run out of context, miss files, or drift partway through. A codemod applies the same rule to every file, whether the repo has 10 files or 10,000.

6. **Narrow scope, less collateral damage**. A codemod only touches the code patterns it targets. An agent asked to "upgrade X" tends to also reformat, refactor, or "improve" unrelated code, which makes PRs noisy and harder to review.

7. **Auditable**. The codemod is stored and versioned, so you can see later exactly what transformation was applied to your code and why.

8. **A clear split between judgment and execution**. The AI does the part that needs judgment: reading changelogs and deciding what has to change. Deterministic code does the part that needs reliability: applying the change. Each one does what it's good at.

9. **Codemod packages are extendible**. A codemod is just a starting point, not the complete upgrade. New cases can be added when a codebase has a usage pattern the original didn't cover, such as a new import style or an edge case in one project. It's added to the existing codemod as a new rule and test, instead of starting from scratch.


I am building [Apiweiser](https://apiweiser-cli-fe.vercel.app/) to validate this idea and make dependency upgrades as easy as possible. It only support node projects in Typescript for now. You could run it in your codebases locally and using the model and the coding harness of your choice. I would appreciate any feedback so that this tool becomes more useful and easier to use and reduces as much pain as possible. You can check it out [here](https://apiweiser-cli-fe.vercel.app/).
