#!/usr/bin/env bash
# Consumes the package this build just packed and checks its public runtime surface.
# usage: jetbrains/verify.sh <host>
#   "dotnet" uses the pinned SDK; another dotnet command may be supplied as the host.
# The smoke project targets net8.0 and can roll forward to the bootstrapped .NET 10 runtime.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=sdk.sh
source "$(dirname "$0")/sdk.sh"
fork=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$fork")
out="$root/artifacts/jetbrains"
host=${1:?usage: jetbrains/verify.sh <host>}

shopt -s nullglob
packages=("$out"/packages/JetBrains.Tomlyn.Signed.*.nupkg)
if [ "${#packages[@]}" -ne 1 ]; then
  echo "Expected exactly one JetBrains.Tomlyn.Signed package in $out/packages, found ${#packages[@]}." >&2
  exit 1
fi
package=${packages[0]##*/}
version=${package#JetBrains.Tomlyn.Signed.}
version=${version%.nupkg}

if [ "$host" = dotnet ]; then host=$dotnet; fi
export NUGET_PACKAGES="$(native "$out/verify-packages")"
export DOTNET_ROLL_FORWARD="${DOTNET_ROLL_FORWARD:-Major}"
rm -rf "$NUGET_PACKAGES/jetbrains.tomlyn.signed"
"$host" run --project "$(native "$fork/verify/Smoke/Smoke.csproj")" -c Release \
  -p:JbPackageVersion="$version" \
  -p:RestoreAdditionalProjectSources="$(native "$out/packages")" \
  -p:BaseIntermediateOutputPath="$(native "$out/verify-obj")/" \
  -p:BaseOutputPath="$(native "$out/verify-bin")/" \
  -p:NuGetAudit=false
