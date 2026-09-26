#!/usr/bin/env bash
# Run OpenTofu against a remote-state stack with the right backend key and profile.
#
#   scripts/tofu.sh <stack> <profile|-> <tofu command> [args...]
#
# Stacks with a profiles/ directory require a profile; state key <stack>/<profile>.
# Stacks without one take "-" as profile; state key <stack>.
# Secret zero comes from TOFU_STATE_PASSPHRASE or the OS keychain (ADR 0026);
# state-store credentials come from the foundation/store stack outputs.
set -euo pipefail

readonly KEYCHAIN_SERVICE="platform-labs.kafka-financial-event-platform.tofu-state"
readonly STORE_DIR="infra/stacks/foundation/store"

usage() { echo "usage: $0 <stack> <profile|-> <tofu command> [args...]" >&2; exit 2; }
[[ $# -ge 3 ]] || usage

stack=$1 profile=$2
shift 2
stack_dir="infra/stacks/${stack}"

[[ "$stack" =~ ^[a-z0-9-]+$ ]] || { echo "invalid stack name: $stack" >&2; exit 2; }
[[ -f "${stack_dir}/versions.tf" ]] || { echo "unknown stack: $stack" >&2; exit 2; }
[[ "$stack" != foundation* ]] || { echo "foundation stacks use local state; use 'task foundation:*'" >&2; exit 2; }

var_args=()
if [[ -d "${stack_dir}/profiles" ]]; then
  [[ "$profile" != "-" ]] || { echo "stack '$stack' requires a profile" >&2; exit 2; }
  [[ "$profile" =~ ^[a-z0-9-]+$ && -f "${stack_dir}/profiles/${profile}.tfvars" ]] \
    || { echo "unknown profile '$profile' for stack '$stack'" >&2; exit 2; }
  state_key="${stack}/${profile}/terraform.tfstate"
  data_dir="${stack_dir}/.terraform-${profile}"
  var_args=(-var-file="profiles/${profile}.tfvars" -var="profile=${profile}")
else
  [[ "$profile" == "-" ]] || { echo "stack '$stack' has no profiles; pass '-'" >&2; exit 2; }
  state_key="${stack}/terraform.tfstate"
  data_dir="${stack_dir}/.terraform"
fi

TF_VAR_state_passphrase="${TOFU_STATE_PASSPHRASE:-$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w)}"
export TF_VAR_state_passphrase
endpoint=$(tofu -chdir="$STORE_DIR" output -raw endpoint)
AWS_ACCESS_KEY_ID=$(tofu -chdir="$STORE_DIR" output -raw access_key)
AWS_SECRET_ACCESS_KEY=$(tofu -chdir="$STORE_DIR" output -raw secret_key)
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
export TF_DATA_DIR="$PWD/${data_dir}"
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$HOME/.terraform.d/plugin-cache}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

command=$1
shift
case "$command" in
  init)
    exec tofu -chdir="$stack_dir" init -input=false \
      -backend-config="$PWD/infra/backend.s3.hcl" \
      -backend-config="key=${state_key}" \
      -backend-config="endpoints={s3=\"${endpoint}\"}" "$@" ;;
  plan|apply|destroy|import|refresh)
    exec tofu -chdir="$stack_dir" "$command" ${var_args[@]+"${var_args[@]}"} "$@" ;;
  *)
    exec tofu -chdir="$stack_dir" "$command" "$@" ;;
esac
