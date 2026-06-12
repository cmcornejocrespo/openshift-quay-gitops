#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== OpenShift GitOps Bootstrap ==="
echo ""

# --- Step 1: Install OpenShift GitOps Operator ---
echo "[1/4] Applying OpenShift GitOps operator subscription..."
oc apply -k "$REPO_ROOT/clusters/openshift-gitops/base"

echo "[2/4] Waiting for GitOps operator InstallPlan..."
echo "       Run: oc -n openshift-operators get installplan"
echo ""

ALREADY_APPROVED=$(oc -n openshift-operators get installplan \
  -l operators.coreos.com/openshift-gitops-operator.openshift-operators= \
  -o jsonpath='{.items[?(@.spec.approved==true)].metadata.name}' 2>/dev/null || true)

if [[ -n "$ALREADY_APPROVED" ]]; then
  echo "       InstallPlan already approved: $ALREADY_APPROVED"
else
  INSTALL_PLAN=""
  RETRIES=0
  MAX_RETRIES=30
  while [[ -z "$INSTALL_PLAN" && $RETRIES -lt $MAX_RETRIES ]]; do
    INSTALL_PLAN=$(oc -n openshift-operators get installplan \
      -o jsonpath='{.items[?(@.spec.approved==false)].metadata.name}' 2>/dev/null || true)
    if [[ -z "$INSTALL_PLAN" ]]; then
      echo "       Waiting for InstallPlan to appear... ($((RETRIES+1))/$MAX_RETRIES)"
      sleep 10
      RETRIES=$((RETRIES + 1))
    fi
  done

  if [[ -z "$INSTALL_PLAN" ]]; then
    echo "ERROR: InstallPlan not found after $MAX_RETRIES attempts"
    exit 1
  fi

  echo "       Approving InstallPlan: $INSTALL_PLAN"
  oc -n openshift-operators patch installplan "$INSTALL_PLAN" \
    --type merge --patch '{"spec":{"approved":true}}'
fi

echo "[3/4] Waiting for openshift-gitops namespace and ArgoCD to be ready..."
until oc get namespace openshift-gitops &>/dev/null; do
  echo "       Waiting for openshift-gitops namespace..."
  sleep 5
done
oc wait --for=condition=Available deployment/openshift-gitops-server \
  -n openshift-gitops --timeout=300s

# --- Step 2: Deploy ArgoCD Applications ---
echo "[4/4] Applying ArgoCD Applications..."
oc apply -f "$REPO_ROOT/argocd/applications/"

echo ""
echo "=== Bootstrap complete ==="
echo "ArgoCD will now manage:"
echo "  - OpenShift GitOps operator (self-managed)"
echo "  - Quay Registry"
echo ""
echo "Monitor sync status:"
echo "  oc -n openshift-gitops get applications"
