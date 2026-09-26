# Runbook: back up and restore secret zero

| Field | Value |
|---|---|
| Component | State encryption passphrase ([ADR 0026](../adr/0026-keep-a-single-secret-zero-in-the-os-keychain.md)) |
| Trigger | After `task secrets:init`; new machine; suspected exposure |
| Impact if ignored | Losing the passphrase makes every OpenTofu state unreadable |
| Risk of the procedure | High if mishandled: the value unlocks all state |

## Preconditions

- A password manager entry reserved for this value. Never store it in the repository,
  shell history, or chat tools.

## Steps

### Back up

1. `security find-generic-password -s platform-labs.kafka-financial-event-platform.tofu-state -w | pbcopy`
2. Paste into the password manager entry, then clear the clipboard.

### Restore on another machine

1. Copy the value from the password manager.
2. `security add-generic-password -a "$USER" -s platform-labs.kafka-financial-event-platform.tofu-state -w`
   (prompts for the value, so it does not appear in shell history).
3. `task foundation:plan` must show `No changes` against the restored state.

### Suspected exposure

1. Treat all state as exposed: rotate generated credentials
   (`task foundation:apply` after `-replace` of the credential resources) and cluster
   credentials (rebuild the cluster).
2. Rotate the passphrase using an OpenTofu encryption `fallback` block to re-encrypt state
   with the new key, then remove the fallback.

## Rollback

Keep the previous passphrase until every state file has been re-encrypted and verified.

## Verification

- `task foundation:plan` and `task tofu STACK=substrate-kind PROFILE=dev -- plan` both run
  and show `No changes`.
