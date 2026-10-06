#!/usr/bin/env python3
"""Check every platform workload against the enforced admission policies (ADR 0038).

Renders all components for every profile and substrate, including Helm hook Jobs that run
only on install or upgrade (live policy reports never see them), and applies the policies in
Deny mode with the Kyverno CLI. A failure here is a pod the cluster would reject."""
import os
import subprocess
import sys
import tempfile

import yaml

import gitops_check

# The Kyverno webhooks skip these namespaces, so the engine and the CNI can always start.
EXCLUDED_NAMESPACES = {"kube-system", "kyverno"}
WORKLOAD_KINDS = {"Pod", "Deployment", "StatefulSet", "DaemonSet", "ReplicaSet", "Job", "CronJob"}
POD_SECURITY = "gitops/platform/pod-security"
POLICIES = "gitops/platform/policies"


def helm_template(args: list) -> list:
    out = subprocess.run(["helm", "template", *args], capture_output=True, text=True, check=True)
    return [d for d in yaml.safe_load_all(out.stdout) if d]


def enforced_policies(substrate: str) -> tuple:
    with open(f"{POD_SECURITY}/config.yaml", encoding="utf-8") as fh:
        chart = yaml.safe_load(fh)["chart"]
    docs = helm_template(["pod-security", chart["name"], "--repo", chart["repoURL"],
                          "--version", chart["version"], "--namespace", "kyverno",
                          "--values", f"{POD_SECURITY}/values.yaml"])
    values = ["--values", f"{POLICIES}/values.yaml"]
    if os.path.exists(f"{POLICIES}/values-substrate-{substrate}.yaml"):
        values += ["--values", f"{POLICIES}/values-substrate-{substrate}.yaml"]
    docs += helm_template(["policies", f"{POLICIES}/chart", "--namespace", "kyverno", *values])
    policies = [d for d in docs if d["kind"] == "ValidatingPolicy"
                and "Deny" in d["spec"].get("validationActions", [])]
    exceptions = [d for d in docs if d["kind"] == "PolicyException"]
    return policies, exceptions


def main() -> int:
    ok = True
    with tempfile.TemporaryDirectory() as workdir:
        renders = gitops_check.render_components(workdir)
        for substrate in gitops_check.SUBSTRATES:
            policies, exceptions = enforced_policies(substrate)
            policy_file = os.path.join(workdir, f"policies-{substrate}.yaml")
            exception_file = os.path.join(workdir, f"exceptions-{substrate}.yaml")
            with open(policy_file, "w", encoding="utf-8") as fh:
                yaml.safe_dump_all(policies, fh)
            with open(exception_file, "w", encoding="utf-8") as fh:
                yaml.safe_dump_all(exceptions, fh)
            for label, manifests in renders.items():
                if f"/{substrate}]" not in label or manifests is None:
                    continue
                component = label.split()[0]
                with open(f"gitops/platform/{component}/config.yaml", encoding="utf-8") as fh:
                    namespace = yaml.safe_load(fh)["namespace"]
                workloads = []
                for doc in yaml.safe_load_all(manifests):
                    if not doc or doc.get("kind") not in WORKLOAD_KINDS:
                        continue
                    doc["metadata"].setdefault("namespace", namespace)  # helm template omits it
                    if doc["metadata"]["namespace"] not in EXCLUDED_NAMESPACES:
                        workloads.append(doc)
                if not workloads:
                    continue
                resource_file = os.path.join(workdir, "workloads.yaml")
                with open(resource_file, "w", encoding="utf-8") as fh:
                    yaml.safe_dump_all(workloads, fh)
                result = subprocess.run(
                    ["kyverno", "apply", policy_file, "--resource", resource_file,
                     "--exceptions", exception_file, "--policy-report=false"],
                    capture_output=True, text=True)
                failed = [line for line in result.stdout.splitlines() if " failed" in line]
                summary = next((line for line in result.stdout.splitlines()
                                if line.startswith("pass:")), "no summary")
                if failed or "error: 0" not in summary:
                    ok = False
                    print(f"FAIL {label}: {summary}")
                    print("\n".join(failed) or result.stdout + result.stderr)
                else:
                    print(f"ok   {label}: {summary}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
