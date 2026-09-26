#!/usr/bin/env bash
# Host-level operations for the lab (ADR 0034, runbook host-operations).
# Only objects that belong to this lab are touched: kind clusters named kfep-*, containers
# labelled platform-labs.component, and cloud-provider-kind load balancers (kindccm-*).
#
#   scripts/lab.sh status | start | stop
#   scripts/lab.sh backup [dir] | restore-state <archive>
#   scripts/lab.sh drill-docker-reset | purge
set -euo pipefail

readonly PROJECT="kafka-financial-event-platform"
readonly DATA_DIR="${PLATFORM_DATA_DIR:-$HOME/platform-labs-data/$PROJECT}"
readonly STORE_DATA="$DATA_DIR/seaweedfs"
readonly BACKUP_DIR_DEFAULT="$HOME/platform-labs-backups/$PROJECT"
readonly KEYCHAIN_SERVICE="platform-labs.$PROJECT.tofu-state"
readonly FOUNDATION_STATES=(infra/stacks/foundation/store/terraform.tfstate infra/stacks/foundation/bucket/terraform.tfstate)

kind_nodes() { docker ps -a --filter "label=io.x-k8s.kind.cluster" --format '{{.Names}} {{.Label "io.x-k8s.kind.cluster"}} {{.Label "io.x-k8s.kind.role"}}' | awk '$2 ~ /^kfep-/'; }
lab_containers() { docker ps -a --filter "label=platform-labs.component" --format '{{.Names}}'; }
lb_containers() { docker ps -a --format '{{.Names}}' | grep '^kindccm-' || true; }

status() {
  echo "== lab containers"
  { kind_nodes | awk '{print $1}'; lab_containers; lb_containers; } | sort -u | while read -r name; do
    [[ -n "$name" ]] && docker ps -a --filter "name=^${name}$" --format '{{.Names}}\t{{.Status}}'
  done
  echo "== memory"
  docker stats --no-stream --format '{{.Name}}\t{{.MemUsage}}' | grep -E '^(kfep-|platform-state-store|cloud-provider-kind|kindccm-)' || echo "(nothing running)"
}

stop() {
  # Reverse of start: workers, control planes, load balancers, then the state store.
  local workers cps
  workers=$(kind_nodes | awk '$3=="worker"{print $1}')
  cps=$(kind_nodes | awk '$3=="control-plane"{print $1}')
  # Generous grace periods: the default 10 s ends in SIGKILL. The kube-apiserver alone needs
  # ~90 s to drain long-lived watches (measured), so nodes get 120 s.
  [[ -n "$workers" ]] && docker stop --time 120 $workers >/dev/null
  [[ -n "$cps" ]] && docker stop --time 120 $cps >/dev/null
  local lbs; lbs=$(lb_containers); [[ -n "$lbs" ]] && docker stop $lbs >/dev/null
  docker stop cloud-provider-kind >/dev/null 2>&1 || true
  docker stop --time 30 platform-state-store >/dev/null 2>&1 || true
  echo "lab stopped"
}

start() {
  docker start platform-state-store cloud-provider-kind >/dev/null
  local cps workers
  cps=$(kind_nodes | awk '$3=="control-plane"{print $1}')
  workers=$(kind_nodes | awk '$3=="worker"{print $1}')
  [[ -n "$cps" ]] && docker start $cps >/dev/null
  [[ -n "$workers" ]] && docker start $workers >/dev/null
  local lbs; lbs=$(lb_containers); [[ -n "$lbs" ]] && docker start $lbs >/dev/null
  for cluster in $(kind_nodes | awk '{print $2}' | sort -u); do
    local kubeconfig="$HOME/.kube/${cluster}.yaml"
    echo "waiting for $cluster API server..."
    # The API server answers before its RBAC bootstrap is loaded; wait for /readyz first.
    local tries=0
    until KUBECONFIG="$kubeconfig" kubectl get --raw /readyz >/dev/null 2>&1; do
      (( ++tries > 90 )) && { echo "API server not ready after 180 s" >&2; exit 1; }
      sleep 2
    done
    KUBECONFIG="$kubeconfig" kubectl wait --for=condition=Ready nodes --all --timeout=180s >/dev/null
    KUBECONFIG="$kubeconfig" kubectl get nodes --no-headers | awk '{print "  " $1, $2}'
  done
  echo "lab started"
}

backup() {
  local dir="${1:-$BACKUP_DIR_DEFAULT}" ts archive was_running
  ts=$(date -u +%Y%m%dT%H%M%SZ); archive="$dir/kfep-state-$ts.tar.gz"
  mkdir -p "$dir"; chmod 700 "$dir"
  was_running=$(docker inspect -f '{{.State.Running}}' platform-state-store 2>/dev/null || echo false)
  # Stop the store so files are copied in a consistent state.
  [[ "$was_running" == "true" ]] && docker stop --time 30 platform-state-store >/dev/null
  tar -czf "$archive" -C "$DATA_DIR" seaweedfs -C "$PWD" "${FOUNDATION_STATES[@]}"
  chmod 600 "$archive"
  [[ "$was_running" == "true" ]] && docker start platform-state-store >/dev/null
  echo "backup written: $archive ($(du -h "$archive" | cut -f1))"
  echo "state objects are encrypted; the archive is useless without secret zero, which is NOT in it."
}

restore_state() {
  local archive="${1:?usage: restore-state <archive>}" ts
  [[ -f "$archive" ]] || { echo "no such archive: $archive" >&2; exit 2; }
  ts=$(date -u +%Y%m%dT%H%M%SZ)
  docker stop --time 30 platform-state-store >/dev/null 2>&1 || true
  [[ -d "$STORE_DATA" ]] && mv "$STORE_DATA" "$STORE_DATA.before-restore-$ts"
  for f in "${FOUNDATION_STATES[@]}"; do [[ -f "$f" ]] && mv "$f" "$f.before-restore-$ts"; done
  mkdir -p "$DATA_DIR"
  tar -xzf "$archive" -C "$DATA_DIR" seaweedfs
  tar -xzf "$archive" -C "$PWD" "${FOUNDATION_STATES[@]}"
  echo "restored from $archive; previous data kept with suffix .before-restore-$ts"
  echo "next: task foundation:apply (recreates the container if needed) and verify with task foundation:plan"
}

drill_docker_reset() {
  # Simulates what a Docker reset does to THIS lab only: containers, networks
  # and images disappear; the host bind mount with state data survives.
  echo "removing kind clusters kfep-*, lab containers and lab images (other Docker objects untouched)"
  for cluster in $(kind_nodes | awk '{print $2}' | sort -u); do kind delete cluster --name "$cluster" >/dev/null 2>&1; done
  local objs; objs=$( { lab_containers; lb_containers; } | sort -u); [[ -n "$objs" ]] && docker rm -f $objs >/dev/null
  docker images --format '{{.Repository}}:{{.Tag}}@{{.ID}}' | grep -E '^(chrislusf/seaweedfs|registry.k8s.io/cloud-provider-kind|kindest/node|envoyproxy/envoy)' \
    | cut -d@ -f2 | xargs -r docker rmi -f >/dev/null 2>&1 || true
  echo "done; recover with: task lab:restore PROFILE=dev"
}

purge() {
  cat <<INFO
This removes EVERYTHING this lab placed on the machine (level L4):
  - kind clusters kfep-*, lab containers, lab images
  - $DATA_DIR  (state store data, provider cache)
  - ~/.kube/kfep-*.yaml
  - foundation local state and .terraform directories in this repository
  - OS keychain entry $KEYCHAIN_SERVICE (secret zero)
Backups in $BACKUP_DIR_DEFAULT are kept. Without secret zero they cannot be decrypted.
INFO
  read -r -p "Type '$PROJECT' to confirm: " answer
  [[ "$answer" == "$PROJECT" ]] || { echo "aborted"; exit 1; }
  drill_docker_reset
  # Remove the shared kind network only if no other kind cluster still uses it.
  [[ -z "$(docker ps -a --filter label=io.x-k8s.kind.cluster -q)" ]] && docker network rm kind >/dev/null 2>&1 || true
  rm -rf "$DATA_DIR"
  rm -f "$HOME"/.kube/kfep-*.yaml
  rm -f "${FOUNDATION_STATES[@]}" infra/stacks/foundation/*/terraform.tfstate.*
  find infra/stacks -type d \( -name .terraform -o -name '.terraform-*' \) -prune -exec rm -rf {} +
  security delete-generic-password -s "$KEYCHAIN_SERVICE" >/dev/null 2>&1 || true
  echo "purged. CLI tools used by this lab are listed in docs/operations/host-footprint.md."
}

case "${1:-}" in
  status) status ;;
  start) start ;;
  stop) stop ;;
  backup) backup "${2:-}" ;;
  restore-state) restore_state "${2:-}" ;;
  drill-docker-reset) drill_docker_reset ;;
  purge) purge ;;
  *) echo "usage: $0 status|start|stop|backup [dir]|restore-state <archive>|drill-docker-reset|purge" >&2; exit 2 ;;
esac
