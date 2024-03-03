#!/bin/bash
set -eux

SCRIPT_DIR=$(cd $(dirname $0); pwd)

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# apply argo-cd projects.
kubectl apply -f ${SCRIPT_DIR}/manifests/project.yaml
kubectl apply -f ${SCRIPT_DIR}/manifests/application.yaml
