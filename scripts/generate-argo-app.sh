#!/usr/bin/env bash
# Generate an ArgoCD Application manifest for the v2 folder layout.
#
# Usage:
#   ./scripts/generate-argo-app.sh ENV DOMAIN/SERVICE [APP_NAME]
#
# Example:
#   ./scripts/generate-argo-app.sh platform3-dev io/hello-world
#   ./scripts/generate-argo-app.sh production-na io/integrator-workers integrator-workers-na

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV="${1:?Usage: $0 ENV DOMAIN/SERVICE [APP_NAME]}"
SERVICE_PATH="${2:?Missing DOMAIN/SERVICE}"
APP_NAME="${3:-$(basename "${SERVICE_PATH}")}"

SERVICE_DIR="${REPO_ROOT}/environments/${ENV}/${SERVICE_PATH}"
OUT_DIR="${REPO_ROOT}/argo/${ENV}/${SERVICE_PATH}"
OUT_FILE="${OUT_DIR}/application.yaml"

if [[ ! -d "${SERVICE_DIR}" ]]; then
  echo "error: service not found at ${SERVICE_DIR}" >&2
  exit 1
fi

DOMAIN="${SERVICE_PATH%%/*}"
NAMESPACE="${DOMAIN}"

VALUE_FILES=(
  "\"../../../environments/${ENV}/${SERVICE_PATH}/microservice.yaml\""
)
if [[ -f "${SERVICE_DIR}/env.yaml" ]]; then
  VALUE_FILES+=("\"../../../environments/${ENV}/${SERVICE_PATH}/env.yaml\"")
fi

VALUE_FILES_JSON="$(IFS=,; echo "${VALUE_FILES[*]}")"

mkdir -p "${OUT_DIR}"

cat > "${OUT_FILE}" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  labels:
    cd-layout: v2
    environment: ${ENV}
    service: $(basename "${SERVICE_PATH}")
spec:
  project: ${NAMESPACE}
  source:
    helm:
      valueFiles:
        - ../../../environments/${ENV}/${SERVICE_PATH}/microservice.yaml
EOF

if [[ -f "${SERVICE_DIR}/env.yaml" ]]; then
  cat >> "${OUT_FILE}" <<EOF
        - ../../../environments/${ENV}/${SERVICE_PATH}/env.yaml
EOF
fi

cat >> "${OUT_FILE}" <<EOF
    path: charts/microservice
    repoURL: https://github.com/paramathmuni-sumanth/cd-v2.git
    targetRevision: main
  destination:
    namespace: ${NAMESPACE}
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

echo "Wrote ${OUT_FILE}"
