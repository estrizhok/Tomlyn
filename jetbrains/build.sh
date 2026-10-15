#!/usr/bin/env bash
# Builds and packs the signed JetBrains fork flavor of Tomlyn.
# usage: jetbrains/build.sh <step> [extra dotnet args...]
#   build   builds the source generator and signed library, leaving assemblies in artifacts/jetbrains/bin
#   pack    packs those assemblies without rebuilding into artifacts/jetbrains/packages
#   all     builds and packs in one go
#   restore restores the signed library (also used to refresh the package-lock subset)
# The lock is jetbrains/lock/MainSolutionPackageVersions.subset.xml; JB_PACKAGE_LOCK names another lock file.
# Runs under Git Bash on Windows too, and bootstraps the pinned SDK unless JB_DOTNET names one.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=sdk.sh
source "$(dirname "$0")/sdk.sh"
step=$1; shift
fork=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$fork")
lock=$(realpath "${JB_PACKAGE_LOCK:-$fork/lock/MainSolutionPackageVersions.subset.xml}")
out="$root/artifacts/jetbrains"
sourcegen="$root/src/Tomlyn.SourceGeneration/Tomlyn.SourceGeneration.csproj"
signed="$root/src/Tomlyn.Signed/Tomlyn.Signed.csproj"
case "$step" in
  all|build|pack|restore) ;;
  *)       echo "Unknown step '$step'; expected build, pack, all or restore." >&2; exit 2 ;;
esac
args=(
  -p:TargetFrameworks=netstandard2.0
  -p:CustomAfterMicrosoftCommonTargets="$(native "$fork/JetBrains.Fork.targets")"
  -p:CustomAfterMicrosoftCommonCrossTargetingTargets="$(native "$fork/JetBrains.Fork.targets")"
  -p:JbPackageLockFile="$(native "$lock")"
  -p:BaseIntermediateOutputPath="$(native "$out/obj")/"
  -p:BaseOutputPath="$(native "$out/bin")/"
)
if [ "$step" != restore ]; then args+=(-c Release); fi
if [ "$step" = restore ]; then
  "$dotnet" restore "$(native "$signed")" "${args[@]}" "$@"
  exit
fi

# Tomlyn.Signed includes the generated analyzer DLL as a package asset rather than a project reference.
# Build it first, copy it into the signing directory, and package that exact (possibly signed) copy.
if [ "$step" = build ] || [ "$step" = all ]; then
  rm -rf "$out/obj" "$out/bin"
  "$dotnet" build "$(native "$sourcegen")" -c Release -p:TargetFrameworks=netstandard2.0 "$@"
  mkdir -p "$out/bin"
  cp "$root/src/Tomlyn.SourceGeneration/bin/Release/netstandard2.0/Tomlyn.SourceGeneration.dll" "$out/bin/Tomlyn.SourceGeneration.dll"
  args+=("-p:TomlynSourceGenAssembly=$(native "$out/bin/Tomlyn.SourceGeneration.dll")")
  "$dotnet" build "$(native "$signed")" "${args[@]}" "$@"
else
  args+=("-p:TomlynSourceGenAssembly=$(native "$out/bin/Tomlyn.SourceGeneration.dll")")
fi
if [ "$step" = pack ] || [ "$step" = all ]; then
  rm -rf "$out/packages"
  mkdir -p "$out/packages"
  pack_args=("${args[@]}" -o "$(native "$out/packages")" --no-build)
  "$dotnet" pack "$(native "$signed")" "${pack_args[@]}" "$@"
fi
