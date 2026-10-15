#!/usr/bin/env bash
# Consumes the package this build just packed and checks its public runtime surface.
# usage: jetbrains/verify.sh <host> [fork-revision]
#   "dotnet" uses the pinned SDK; another dotnet command may be supplied as the host.
# The smoke project targets net8.0 and can roll forward to the bootstrapped .NET 10 runtime.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=sdk.sh
source "$(dirname "$0")/sdk.sh"
fork=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$fork")
out="$root/artifacts/jetbrains"
host=${1:?usage: jetbrains/verify.sh <host> [fork-revision]}
revision=${2:-1}
version="2.10.2.$revision"

if [ "$host" = dotnet ]; then host=$dotnet; fi
export NUGET_PACKAGES="$(native "$out/verify-packages")"
export DOTNET_ROLL_FORWARD="${DOTNET_ROLL_FORWARD:-Major}"
"$host" run --project "$(native "$fork/verify/Smoke/Smoke.csproj")" -c Release \
  -p:JbPackageVersion="$version" \
  -p:RestoreAdditionalProjectSources="$(native "$out/packages")" \
  -p:BaseIntermediateOutputPath="$(native "$out/verify-obj")/" \
  -p:BaseOutputPath="$(native "$out/verify-bin")/" \
  -p:NuGetAudit=false
