#!/usr/bin/env python3
"""Render every GitOps component for every profile and substrate, then validate the
manifests against Kubernetes and CRD schemas. Catches broken values before merge."""
import glob
import os
import subprocess
import sys
import tempfile

import yaml

KUBERNETES_VERSION = "1.35.0"  # ADR 0029
# CRD schemas from datreeio/CRDs-catalog, pinned by commit (content-addressed, ADR 0024).
CRD_SCHEMAS = (
    "https://raw.githubusercontent.com/datreeio/CRDs-catalog/"
    "ad3b08c5045129d7bb1eeffd8e61719b2c8dd1e2/"
    "{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"
)
PROFILES = sorted(
    os.path.basename(p)[: -len(".tfvars")]
    for p in glob.glob("infra/stacks/substrate-kind/profiles/*.tfvars")
)
SUBSTRATES = ["kind", "talos"]


def kubeconform(manifests: str, label: str) -> bool:
    result = subprocess.run(
        ["kubeconform", "-strict", "-summary", "-output", "text",
         "-kubernetes-version", KUBERNETES_VERSION,
         # The schema repository publishes no schema for CRDs themselves; skip that one
         # kind explicitly instead of ignoring every missing schema.
         "-skip", "CustomResourceDefinition",
         "-schema-location", "default", "-schema-location", CRD_SCHEMAS],
        input=manifests, capture_output=True, text=True,
    )
    status = "ok  " if result.returncode == 0 else "FAIL"
    summary = (result.stdout.strip().splitlines() or [""])[-1]
    print(f"{status} {label}: {summary}")
    if result.returncode != 0:
        print(result.stdout + result.stderr)
    return result.returncode == 0


def render_components(workdir: str) -> bool:
    ok = True
    for config_path in sorted(glob.glob("gitops/platform/*/config.yaml")):
        component_dir = os.path.dirname(config_path)
        with open(config_path, encoding="utf-8") as fh:
            config = yaml.safe_load(fh)
        chart = config["chart"]
        subprocess.run(
            ["helm", "pull", chart["name"], "--repo", chart["repoURL"],
             "--version", chart["version"], "--untar", "--untardir", workdir],
            check=True, capture_output=True,
        )
        chart_dir = os.path.join(workdir, chart["name"])
        for profile in PROFILES:
            for substrate in SUBSTRATES:
                values = [os.path.join(component_dir, "values.yaml"),
                          os.path.join(component_dir, f"values-{profile}.yaml"),
                          os.path.join(component_dir, f"values-substrate-{substrate}.yaml")]
                args = ["helm", "template", config["component"], chart_dir,
                        "--namespace", config["namespace"],
                        "--kube-version", KUBERNETES_VERSION]
                for value_file in values:
                    if os.path.exists(value_file):
                        args += ["--values", value_file]
                rendered = subprocess.run(args, capture_output=True, text=True)
                label = f"{config['component']} [{profile}/{substrate}]"
                if rendered.returncode != 0:
                    print(f"FAIL {label}: helm template\n{rendered.stderr}")
                    ok = False
                    continue
                ok &= kubeconform(rendered.stdout, label)
    return ok


def render_root() -> bool:
    rendered = subprocess.run(["kubectl", "kustomize", "gitops/root"],
                              capture_output=True, text=True, check=True)
    return kubeconform(rendered.stdout, "gitops/root")


def main() -> int:
    with tempfile.TemporaryDirectory() as workdir:
        ok = render_root()
        ok &= render_components(workdir)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
