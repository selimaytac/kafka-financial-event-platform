#!/usr/bin/env python3
"""Render every GitOps component for every profile and substrate, then validate the
manifests against Kubernetes and CRD schemas. Catches broken values before merge."""
import glob
import json
import os
import subprocess
import sys
import tempfile

import yaml

# PyYAML still implements the YAML 1.1 "value" type, which turns a plain "=" (used as an
# enum value in some CRDs) into an unknown tag; read it as the string it is.
yaml.SafeLoader.add_constructor("tag:yaml.org,2002:value", lambda loader, node: loader.construct_scalar(node))

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


def strict_schema(node):
    """Turn a CRD openAPIV3Schema into a strict JSON Schema (unknown fields rejected)."""
    if isinstance(node, dict):
        node = {k: strict_schema(v) for k, v in node.items()}
        if node.pop("x-kubernetes-int-or-string", False):
            node.pop("type", None)
            node["oneOf"] = [{"type": "string"}, {"type": "integer"}]
        if (node.get("type") == "object" and "properties" in node
                and "additionalProperties" not in node
                and not node.get("x-kubernetes-preserve-unknown-fields")):
            node["additionalProperties"] = False
        return node
    if isinstance(node, list):
        return [strict_schema(v) for v in node]
    return node


def write_crd_schemas(manifests: str, schema_dir: str) -> None:
    """Schemas for custom resources from the CRDs of the exact chart versions deployed."""
    for doc in yaml.safe_load_all(manifests):
        if not doc or doc.get("kind") != "CustomResourceDefinition":
            continue
        spec = doc["spec"]
        for version in spec.get("versions", []):
            schema = version.get("schema", {}).get("openAPIV3Schema")
            if not schema:
                continue
            schema = strict_schema(schema)
            schema.setdefault("properties", {}).update({
                "apiVersion": {"type": "string"}, "kind": {"type": "string"},
                "metadata": {"type": "object"},
            })
            target = os.path.join(schema_dir, spec["group"])
            os.makedirs(target, exist_ok=True)
            name = f"{spec['names']['kind'].lower()}_{version['name']}.json"
            with open(os.path.join(target, name), "w", encoding="utf-8") as fh:
                json.dump(schema, fh)


def kubeconform(manifests: str, label: str, schema_dir: str) -> bool:
    result = subprocess.run(
        ["kubeconform", "-strict", "-summary", "-output", "text",
         "-kubernetes-version", KUBERNETES_VERSION,
         # The schema repository publishes no schema for CRDs themselves; skip that one
         # kind explicitly instead of ignoring every missing schema.
         "-skip", "CustomResourceDefinition",
         # Order matters: schemas from the deployed CRDs first, then the pinned catalog.
         "-schema-location", "default",
         "-schema-location", schema_dir + "/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json",
         "-schema-location", CRD_SCHEMAS],
        input=manifests, capture_output=True, text=True,
    )
    status = "ok  " if result.returncode == 0 else "FAIL"
    summary = (result.stdout.strip().splitlines() or [""])[-1]
    print(f"{status} {label}: {summary}")
    if result.returncode != 0:
        print(result.stdout + result.stderr)
    return result.returncode == 0


def render_components(workdir: str) -> dict:
    """Render every component for every profile and substrate. Returns label -> manifests
    (None when rendering failed)."""
    renders = {}
    for config_path in sorted(glob.glob("gitops/platform/*/config.yaml")):
        component_dir = os.path.dirname(config_path)
        with open(config_path, encoding="utf-8") as fh:
            config = yaml.safe_load(fh)
        chart = config["chart"]
        if "path" in chart:  # local chart in this repository
            chart_dir = chart["path"]
        else:
            source = (["oci://" + chart["repoURL"] + "/" + chart["name"]] if chart.get("oci")
                      else [chart["name"], "--repo", chart["repoURL"]])
            target = os.path.join(workdir, config["component"])
            subprocess.run(
                ["helm", "pull", *source, "--version", chart["version"],
                 "--untar", "--untardir", target],
                check=True, capture_output=True,
            )
            chart_dir = os.path.join(target, chart["name"])
        for profile in PROFILES:
            for substrate in SUBSTRATES:
                values = [os.path.join(component_dir, "values.yaml"),
                          os.path.join(component_dir, f"values-{profile}.yaml"),
                          os.path.join(component_dir, f"values-substrate-{substrate}.yaml")]
                args = ["helm", "template", config["component"], chart_dir,
                        "--namespace", config["namespace"],
                        "--kube-version", KUBERNETES_VERSION, "--include-crds"]
                for value_file in values:
                    if os.path.exists(value_file):
                        args += ["--values", value_file]
                rendered = subprocess.run(args, capture_output=True, text=True)
                label = f"{config['component']} [{profile}/{substrate}]"
                if rendered.returncode != 0:
                    print(f"FAIL {label}: helm template\n{rendered.stderr}")
                    renders[label] = None
                else:
                    renders[label] = rendered.stdout
    return renders


def main() -> int:
    with tempfile.TemporaryDirectory() as workdir:
        schema_dir = os.path.join(workdir, "schemas")
        renders = render_components(workdir)
        for manifests in renders.values():
            if manifests:
                write_crd_schemas(manifests, schema_dir)
        root = subprocess.run(["kubectl", "kustomize", "gitops/root"],
                              capture_output=True, text=True, check=True)
        ok = kubeconform(root.stdout, "gitops/root", schema_dir)
        for label, manifests in renders.items():
            ok &= manifests is not None and kubeconform(manifests, label, schema_dir)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
