#!/usr/bin/env bash
# Generate ArgoCD Application manifests for all services in an environment domain.
#
# Usage:
#   ./scripts/generate-argo-apps-for-env.sh ENV [DOMAIN]
#
# Example:
#   ./scripts/generate-argo-apps-for-env.sh platform3-dev io
#   ./scripts/generate-argo-apps-for-env.sh platform3-dev        # all domains

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV="${1:?Usage: $0 ENV [DOMAIN]}"
DOMAIN_FILTER="${2:-}"

ENV_DIR="${REPO_ROOT}/environments/${ENV}"
OUT_ROOT="${REPO_ROOT}/argo/${ENV}"

if [[ ! -d "${ENV_DIR}" ]]; then
  echo "error: environment not found: ${ENV_DIR}" >&2
  exit 1
fi

count=0
skipped=0

generate_for_service() {
  local domain="$1"
  local service="$2"
  local service_path="${domain}/${service}"
  local service_dir="${ENV_DIR}/${service_path}"

  if [[ ! -f "${service_dir}/microservice.yaml" ]]; then
    echo "  skip ${service_path} (no microservice.yaml)"
    skipped=$((skipped + 1))
    return
  fi

  "${SCRIPT_DIR}/generate-argo-app.sh" "${ENV}" "${service_path}"
  count=$((count + 1))
}

if [[ -n "${DOMAIN_FILTER}" ]]; then
  domains="${DOMAIN_FILTER}"
else
  domains="$(find "${ENV_DIR}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | tr '\n' ' ')"
fi

for domain in ${domains}; do
  domain_dir="${ENV_DIR}/${domain}"
  [[ -d "${domain_dir}" ]] || continue

  echo "Domain: ${domain}"

  for service in $(find "${domain_dir}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort); do
    generate_for_service "${domain}" "${service}"
  done
done

manifest_index="${OUT_ROOT}/manifests.txt"
mkdir -p "${OUT_ROOT}"
find "${OUT_ROOT}" -name application.yaml | sort > "${manifest_index}"

echo ""
echo "Generated ${count} Application manifest(s), skipped ${skipped}"
echo "Manifest index: ${manifest_index}"
