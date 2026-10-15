# JetBrains fork overlay

Builds the signed `Tomlyn.Signed` library from upstream tag `2.10.1` for `netstandard2.0`, with its runtime package dependencies resolved to the exact versions pinned in the JetBrains main-solution package lock. It packages the result as `JetBrains.Tomlyn.Signed` (`2.10.2.<TeamCity build counter>`); the assembly identity remains the upstream one.

All fork-specific files live in this folder. Upstream source and project files are not edited, so merges remain separate from the overlay. The TeamCity build signs the library and the bundled source generator before packaging.

## Build

```sh
jetbrains/build.sh build [-p:JbForkRevision=N]
# Sign artifacts/jetbrains/bin/**/*.dll (TeamCity does this)
jetbrains/build.sh pack [-p:JbForkRevision=N]
jetbrains/verify.sh dotnet [fork-revision]
```

`build.sh` uses the bootstrapped .NET 10 SDK unless `JB_DOTNET` names a dotnet executable. The version starts at 2.10.2 because upstream is 2.10.1; the fourth component increments with every TeamCity build counter. The source generator is built with upstream dependencies and its DLL is copied into the signing output before the signed library is built and packed.

## The lock

`lock/MainSolutionPackageVersions.subset.xml` contains only the packages in the signed library's restore graph, copied verbatim from `DevKit/Config/MainSolutionPackageVersions.xml`. Each build pins direct and transitive dependencies to those versions and enables transitive pinning. `snapshot-lock.sh <full-lock>` refreshes the subset after the main-solution lock moves. The build keeps failing if a newer upstream dependency cannot be built against the pinned versions; it does not silently drift to newer package versions.

The source generator remains on its upstream dependency versions because it is bundled as a build-time analyzer, not used at runtime by the main solution.
