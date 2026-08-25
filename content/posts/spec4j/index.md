+++
title = "spec4j: Centralizing API Contracts with TypeSpec"
date = 2026-08-19
+++

## The problem

Every team that has run more than a handful of services ends up with the same drift: the API contract lives in three places at once — a hand-written OpenAPI file nobody updates, the actual Spring controller, and whatever the consumer's client code assumes it looks like. They fall out of sync quietly. Someone renames a field on the server, forgets the doc, and a consumer finds out at runtime instead of at compile time.

The fix I keep coming back to isn't "write better docs," it's removing the place where drift can happen: define the contract once, generate everything else from it, and make the generated code the only way to implement or consume the API.

## Spec-first, centralized

This is usually called contract-first (or spec-first) API development — you write the contract before any implementation exists, and code is generated from it or validated against it, rather than the contract being reverse-engineered from whatever the code happens to do.

The specific shape I wanted is a dedicated, version-controlled repo that holds nothing but contracts — one folder per API domain — acting as the single source of truth every other repo depends on. This is the same idea as a schema registry: Buf's Schema Registry does it for Protobuf, Confluent's does it for Avro. I wanted the equivalent for a Spring/Java shop using OpenAPI-shaped contracts, so I built [spec4j](https://github.com/marketplace/actions/spec4j).

## TypeSpec, briefly

Hand-written OpenAPI YAML is verbose and easy to get subtly wrong — no types, no imports, lots of copy-pasted schema fragments. [TypeSpec](https://typespec.io/) is a TypeScript-like language for describing APIs that compiles down to OpenAPI (or other formats) instead of being hand-written directly. A model looks like this:

```tsp
@tag("Users")
@route("/users")
interface UsersApi {
  @get list(@query role?: Role, @query cursor?: string): UserList | ApiError;
  @get read(@path id: string): User | ApiError;
  @post create(@body user: User): User | ApiError;
}

model User {
  id: string;
  firstName: string;
  lastName: string;
  roles: Role[];
}
```

That's real types, real optionality (`?`), real enums, real unions for error responses — checked by the TypeSpec compiler before it ever becomes OpenAPI. `tsp compile` turns this into an `openapi.yaml`, which is the intermediate artifact the rest of the pipeline consumes.

## How spec4j works

spec4j is a GitHub Action that takes a `.tsp` file and turns it into a versioned Java library:

1. Compile the spec with `tsp compile` → OpenAPI 3 document.
2. Run `openapi-generator` against it with the Spring generator → interface + DTO source, no controller bodies, just the contract as Java types.
3. Package it as a Maven jar, named after the domain folder.
4. Deploy that jar to a Maven registry, at exactly the version given.

The trigger is a tag, not a merge to main — `<domain>/vX.Y.Z`:

```yaml
on:
  push:
    tags: ['*/v*']

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - id: release
        run: |
          echo "domain=${GITHUB_REF_NAME%%/*}" >> "$GITHUB_OUTPUT"
          echo "version=${GITHUB_REF_NAME#*/v}" >> "$GITHUB_OUTPUT"
      - uses: enismustafaj/spec4j@1.0.3
        with:
          spec-path: ${{ steps.release.outputs.domain }}/main.tsp
          version: ${{ steps.release.outputs.version }}
          registry-id: gitlab-maven
          registry-url: https://gitlab.com/api/v4/projects/<id>/packages/maven
          registry-token: ${{ secrets.GITLAB_TOKEN }}
```

`git tag users/v1.2.0 && git push origin users/v1.2.0` and a few minutes later `com.spec4j:users:1.2.0` exists in the registry — a real jar with a real `UsersApi` interface and real `User`/`Role` classes, generated straight from the spec, nothing hand-written. No floating SNAPSHOT, no version drift between what a service implements and what the contract says: whatever version a service depends on is exactly, mechanically, the contract at that tag.

The problem I set out to solve was never really "generate some Java classes" — `openapi-generator` already does that. It was making the contract the thing everyone is forced to depend on, instead of the thing everyone quietly reimplements.

To check out the full source code, go to [Github](https://github.com/enismustafaj/spec4j), or see [spec4j-specs](https://github.com/enismustafaj/spec4j-specs) for a real multi-domain example repo using it.
