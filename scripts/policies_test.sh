#!/usr/bin/env bash
# Render the platform policies chart and run the Kyverno CLI behavioural tests against it.
set -euo pipefail
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp gitops/platform/policies/tests/*.yaml "$work/"
helm template policies gitops/platform/policies/chart --namespace kyverno \
  --values gitops/platform/policies/values.yaml \
  | python3 -c 'import sys, yaml; print(yaml.safe_dump_all([d for d in yaml.safe_load_all(sys.stdin) if d and d.get("kind") == "ValidatingPolicy"]))' \
  > "$work/rendered-policies.yaml"
kyverno test "$work"
