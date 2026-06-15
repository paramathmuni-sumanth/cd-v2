#!/usr/bin/env bash
# Scaffold base/ and environments/<env>/ directories for a service from an upstream branch.
#
# Usage:
#   ./scripts/scaffold-service.sh DOMAIN/SERVICE ENV [UPSTREAM_BRANCH]
#
# Example:
#   ./scripts/scaffold-service.sh io/hello-world platform3-dev platform3-dev
#
# Creates:
#   base/DOMAIN/SERVICE/microservice.yaml          (from upstream, env block stripped if present)
#   environments/ENV/DOMAIN/SERVICE/env.yaml       (placeholder — fill from diff)
#
# This is a starting point. Run diff-env-branches.sh and manually refine the split.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SERVICE_PATH="${1:?Usage: $0 DOMAIN/SERVICE ENV [UPSTREAM_BRANCH]}"
ENV="${2:?Missing ENV}"
BRANCH="${3:-${ENV}}"
UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/celigo/cd.git}"

cd "${REPO_ROOT}"

if ! git remote get-url "${UPSTREAM_REMOTE}" &>/dev/null; then
  git remote add "${UPSTREAM_REMOTE}" "${UPSTREAM_URL}"
fi

git fetch "${UPSTREAM_REMOTE}" "${BRANCH}" --quiet

BASE_DIR="${REPO_ROOT}/base/${SERVICE_PATH}"
ENV_DIR="${REPO_ROOT}/environments/${ENV}/${SERVICE_PATH}"
MICROSERVICE_PATH="${SERVICE_PATH}/microservice.yaml"
ENV_YAML_PATH="${SERVICE_PATH}/env.yaml"

mkdir -p "${BASE_DIR}" "${ENV_DIR}"

if git cat-file -e "${UPSTREAM_REMOTE}/${BRANCH}:${MICROSERVICE_PATH}" 2>/dev/null; then
  git show "${UPSTREAM_REMOTE}/${BRANCH}:${MICROSERVICE_PATH}" > "${BASE_DIR}/microservice.yaml"
  echo "Wrote ${BASE_DIR}/microservice.yaml (from upstream — review and split env-specific keys)"
else
  echo "warning: ${MICROSERVICE_PATH} not found on ${UPSTREAM_REMOTE}/${BRANCH}" >&2
fi

if git cat-file -e "${UPSTREAM_REMOTE}/${BRANCH}:${ENV_YAML_PATH}" 2>/dev/null; then
  git show "${UPSTREAM_REMOTE}/${BRANCH}:${ENV_YAML_PATH}" > "${ENV_DIR}/env.yaml"
  echo "Wrote ${ENV_DIR}/env.yaml"
else
  cat > "${ENV_DIR}/env.yaml" <<EOF
# TODO: extract env-specific overrides from base/microservice.yaml or diff-env-branches.sh
microservice:
  env: {}
EOF
  echo "Wrote ${ENV_DIR}/env.yaml (placeholder — fill from upstream diff)"
fi

echo ""
echo "Next steps:"
echo "  1. ./scripts/diff-env-branches.sh ${SERVICE_PATH} ${BRANCH} qa-prod"
echo "  2. Move env-specific keys from base/ to environments/${ENV}/"
echo "  3. Add argo/${ENV}/${SERVICE_PATH}.yaml"
