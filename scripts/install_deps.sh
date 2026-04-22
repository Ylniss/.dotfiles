#!/usr/bin/env bash
# Detect distro and dispatch to the matching install_deps_*.sh script.

set -euo pipefail

if [[ ! -f /etc/os-release ]]; then
  echo "error: /etc/os-release missing; cannot detect distro" >&2
  exit 1
fi

. /etc/os-release

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$ID" in
  ubuntu) exec bash "$script_dir/install_deps_ubuntu.sh" ;;
  arch)   exec bash "$script_dir/install_deps_arch.sh"   ;;
  *)
    echo "error: unsupported distro '$ID' — add scripts/install_deps_${ID}.sh and a case here" >&2
    exit 1
    ;;
esac
