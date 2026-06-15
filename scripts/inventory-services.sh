#!/usr/bin/env bash
# List services under a domain from an upstream celigo/cd branch.
#
# Usage:
#   ./scripts/inventory-services.sh [DOMAIN] [BRANCH]
#
# Examples:
#   ./scripts/inventory-services.sh io platform3-dev
#   ./scripts/inventory-services.sh core qa-prod
#   ./scripts/inventory-services.sh          # defaults: io, platform3-dev

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DOMAIN="${1:-io}"
BRANCH="${2:-platform3-dev}"
UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/celigo/cd.git}"

cd "${REPO_ROOT}"

if ! git remote get-url "${UPSTREAM_REMOTE}" &>/dev/null; then
  echo "Adding remote ${UPSTREAM_REMOTE} -> ${UPSTREAM_URL}"
  git remote add "${UPSTREAM_REMOTE}" "${UPSTREAM_URL}"
fi

git fetch "${UPSTREAM_REMOTE}" "${BRANCH}" --quiet

echo "Services in ${DOMAIN}/ on ${UPSTREAM_REMOTE}/${BRANCH}:"
echo "------------------------------------------------------------"

git ls-tree --name-only "${UPSTREAM_REMOTE}/${BRANCH}:${DOMAIN}/" 2>/dev/null \
  | sort \
  | while read -r service; do
      has_microservice=""
      has_env=""
      has_argo=""

      git cat-file -e "${UPSTREAM_REMOTE}/${BRANCH}:${DOMAIN}/${service}/microservice.yaml" 2>/dev/null \
        && has_microservice="microservice.yaml"
      git cat-file -e "${UPSTREAM_REMOTE}/${BRANCH}:${DOMAIN}/${service}/env.yaml" 2>/dev/null \
        && has_env="env.yaml"
      git cat-file -e "${UPSTREAM_REMOTE}/${BRANCH}:${DOMAIN}/${service}/argo_app_manifest.json" 2>/dev/null \
        && has_argo="argo_app_manifest.json"

      printf "  %-40s %s\n" "${DOMAIN}/${service}" "${has_microservice} ${has_env} ${has_argo}"
    done

echo ""
echo "Domains on ${UPSTREAM_REMOTE}/${BRANCH}:"
git ls-tree --name-only "${UPSTREAM_REMOTE}/${BRANCH}/" \
  | grep -E '^(io|core|ia|di|ui|internal|tools|testing)$' \
  | sort
