#!/usr/bin/env bash
# Import all Celigo CD environments into environments/{name}/ from upstream repos.
#
# Usage:
#   ./scripts/import-all-environments.sh [--fetch-only]
#
# Sources:
#   celigo/cd branches: qa1, qa-prod, ia-qa, core, platform1-dev … platform5-dev, platform1-dev-dr
#   celigo/cd-staging:    staging
#   celigo/cd-prod:       production-na, production-eu
#   celigo/dev-environments: master-dev
#
# Shared at repo root (not duplicated per env): charts/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FETCH_ONLY="${1:-}"
DOMAINS=(io core ia di ui internal testing tools)

declare -a IMPORTS=(
  "upstream|qa1|qa1"
  "upstream|qa-prod|qa-prod"
  "upstream|ia-qa|ia-qa"
  "upstream|core|core"
  "upstream|platform1-dev|platform1-dev"
  "upstream|platform2-dev|platform2-dev"
  "upstream|platform3-dev|platform3-dev"
  "upstream|platform4-dev|platform4-dev"
  "upstream|platform5-dev|platform5-dev"
  "upstream|platform1-dev-dr|platform1-dev-dr"
  "upstream-staging|staging|staging"
  "upstream-prod|production-na|production-na"
  "upstream-prod|production-eu|production-eu"
  "upstream-dev-envs|master-dev|master-dev"
)

cd "${REPO_ROOT}"

ensure_remote() {
  local name="$1"
  local url="$2"
  if ! git remote get-url "${name}" &>/dev/null; then
    echo "Adding remote ${name} -> ${url}"
    git remote add "${name}" "${url}"
  fi
}

ensure_remote upstream "https://github.com/celigo/cd.git"
ensure_remote upstream-staging "https://github.com/celigo/cd-staging.git"
ensure_remote upstream-prod "https://github.com/celigo/cd-prod.git"
ensure_remote upstream-dev-envs "https://github.com/celigo/dev-environments.git"

echo "Fetching upstream branches (this may take a few minutes)..."
for entry in "${IMPORTS[@]}"; do
  IFS='|' read -r remote branch _ <<< "${entry}"
  git fetch "${remote}" "${branch}" --quiet || {
    echo "warning: failed to fetch ${remote}/${branch}" >&2
  }
done

if [[ "${FETCH_ONLY}" == "--fetch-only" ]]; then
  echo "Fetch complete."
  exit 0
fi

import_domain_tree() {
  local remote="$1"
  local branch="$2"
  local env_name="$3"
  local dest="${REPO_ROOT}/environments/${env_name}"

  mkdir -p "${dest}"

  for domain in "${DOMAINS[@]}"; do
    if git cat-file -e "${remote}/${branch}:${domain}" 2>/dev/null; then
      mkdir -p "${dest}/${domain}"
      git archive "${remote}/${branch}" "${domain}" | tar -x -C "${dest}"
      echo "  imported ${domain}/"
    fi
  done
}

import_charts() {
  local remote="$1"
  local branch="$2"
  echo "Importing shared charts/ from ${remote}/${branch}..."
  rm -rf "${REPO_ROOT}/charts"
  git archive "${remote}/${branch}" charts | tar -x -C "${REPO_ROOT}"
}

echo ""
import_charts upstream qa-prod

echo ""
for entry in "${IMPORTS[@]}"; do
  IFS='|' read -r remote branch env_name <<< "${entry}"
  ref="${remote}/${branch}"

  if ! git rev-parse --verify "${ref}" &>/dev/null; then
    echo "SKIP ${env_name}: ${ref} not available"
    continue
  fi

  echo "Importing environment: ${env_name} <- ${ref}"
  rm -rf "${REPO_ROOT}/environments/${env_name}"
  import_domain_tree "${remote}" "${branch}" "${env_name}"

  file_count="$(find "${REPO_ROOT}/environments/${env_name}" -type f 2>/dev/null | wc -l | tr -d ' ')"
  echo "  done (${file_count} files)"
done

echo ""
echo "Sanitizing known secret patterns for GitHub push protection..."
find "${REPO_ROOT}/environments" -type f \( -name '*.yaml' -o -name '*.yml' \) \
  -exec sed -i '' 's/Bearer xox[baprs]-[0-9A-Za-z-]*/Bearer {{ SLACK_BOT_TOKEN }}/g' {} +

echo ""
echo "Import complete. Environments:"
ls -1 "${REPO_ROOT}/environments"
