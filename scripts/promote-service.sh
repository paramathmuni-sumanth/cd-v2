#!/usr/bin/env bash
# Copy env override files from one environment folder to another (scaffold / promote).
#
# Usage:
#   ./scripts/promote-service.sh DOMAIN/SERVICE SOURCE_ENV TARGET_ENV [--dry-run]
#
# Example:
#   ./scripts/promote-service.sh io/hello-world platform3-dev qa1
#   ./scripts/promote-service.sh io/hello-world qa1 qa-prod --dry-run
#
# Copies environments/SOURCE_ENV/DOMAIN/SERVICE/ -> environments/TARGET_ENV/DOMAIN/SERVICE/
# Does not modify base/. Review and edit env-specific values (S3 bucket, IAM ARN, etc.) after promote.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SERVICE_PATH="${1:?Usage: $0 DOMAIN/SERVICE SOURCE_ENV TARGET_ENV [--dry-run]}"
SOURCE_ENV="${2:?Missing SOURCE_ENV}"
TARGET_ENV="${3:?Missing TARGET_ENV}"
DRY_RUN="${4:-}"

SRC_DIR="${REPO_ROOT}/environments/${SOURCE_ENV}/${SERVICE_PATH}"
DST_DIR="${REPO_ROOT}/environments/${TARGET_ENV}/${SERVICE_PATH}"

if [[ ! -d "${SRC_DIR}" ]]; then
  echo "error: source not found: ${SRC_DIR}" >&2
  exit 1
fi

echo "Promote ${SERVICE_PATH}: ${SOURCE_ENV} -> ${TARGET_ENV}"
echo "  from: ${SRC_DIR}"
echo "  to:   ${DST_DIR}"

if [[ "${DRY_RUN}" == "--dry-run" ]]; then
  echo "[dry-run] would copy:"
  find "${SRC_DIR}" -type f | sed "s|^${REPO_ROOT}/||"
  exit 0
fi

mkdir -p "${DST_DIR}"
cp -R "${SRC_DIR}/." "${DST_DIR}/"

echo "Done. Review and update env-specific values in:"
find "${DST_DIR}" -type f | sed "s|^${REPO_ROOT}/||"
