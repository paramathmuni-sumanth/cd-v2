#!/usr/bin/env bash
# Diff a service's deployment YAML between two upstream celigo/cd branches.
#
# Usage:
#   ./scripts/diff-env-branches.sh DOMAIN/SERVICE BRANCH_A BRANCH_B
#
# Example:
#   ./scripts/diff-env-branches.sh io/hello-world platform3-dev qa-prod

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SERVICE_PATH="${1:?Usage: $0 DOMAIN/SERVICE BRANCH_A BRANCH_B}"
BRANCH_A="${2:?Missing BRANCH_A}"
BRANCH_B="${3:?Missing BRANCH_B}"
UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/celigo/cd.git}"

cd "${REPO_ROOT}"

if ! git remote get-url "${UPSTREAM_REMOTE}" &>/dev/null; then
  git remote add "${UPSTREAM_REMOTE}" "${UPSTREAM_URL}"
fi

git fetch "${UPSTREAM_REMOTE}" "${BRANCH_A}" "${BRANCH_B}" --quiet

echo "Diff: ${SERVICE_PATH}"
echo "  ${UPSTREAM_REMOTE}/${BRANCH_A}  vs  ${UPSTREAM_REMOTE}/${BRANCH_B}"
echo "============================================================"

for file in microservice.yaml env.yaml testing.yaml rollout.yaml argo_app_manifest.json; do
  path="${SERVICE_PATH}/${file}"
  if git cat-file -e "${UPSTREAM_REMOTE}/${BRANCH_A}:${path}" 2>/dev/null \
     || git cat-file -e "${UPSTREAM_REMOTE}/${BRANCH_B}:${path}" 2>/dev/null; then
    echo ""
    echo "--- ${file} ---"
    git diff --no-index \
      <(git show "${UPSTREAM_REMOTE}/${BRANCH_A}:${path}" 2>/dev/null || echo "# missing on ${BRANCH_A}") \
      <(git show "${UPSTREAM_REMOTE}/${BRANCH_B}:${path}" 2>/dev/null || echo "# missing on ${BRANCH_B}") \
      || true
  fi
done
