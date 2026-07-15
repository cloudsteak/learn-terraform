#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_TF="${SCRIPT_DIR}/backend.tf"

if [[ ! -f "${BACKEND_TF}" ]]; then
  echo "Error: ${BACKEND_TF} not found." >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Error: not logged in to Azure. Run 'az login' first." >&2
  exit 1
fi

read_backend_value() {
  local key="$1"
  local value

  value="$(grep "${key}" "${BACKEND_TF}" | head -1 | sed -E 's/.*=[[:space:]]*"([^"]+)".*/\1/')"
  if [[ -z "${value}" ]]; then
    echo "Error: could not read '${key}' from ${BACKEND_TF}." >&2
    exit 1
  fi

  printf '%s' "${value}"
}

select_subscription() {
  local subscriptions
  local count
  local choice
  local index
  local subscription_id

  mapfile -t subscriptions < <(az account list --query '[].{name:name, id:id}' -o tsv)

  if [[ "${#subscriptions[@]}" -eq 0 ]]; then
    echo "Error: no Azure subscriptions found." >&2
    exit 1
  fi

  echo "Available Azure subscriptions:"
  echo

  for index in "${!subscriptions[@]}"; do
    IFS=$'\t' read -r name id <<< "${subscriptions[$index]}"
    printf '  %d) %s\n     %s\n\n' "$((index + 1))" "${name}" "${id}"
  done

  count="${#subscriptions[@]}"

  while true; do
    read -rp "Select subscription [1-${count}]: " choice
    if [[ "${choice}" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= count)); then
      index=$((choice - 1))
      IFS=$'\t' read -r _ subscription_id <<< "${subscriptions[$index]}"
      az account set --subscription "${subscription_id}"
      echo
      echo "Using subscription: $(az account show --query name -o tsv)"
      echo
      return
    fi

    echo "Invalid selection. Enter a number between 1 and ${count}." >&2
  done
}

select_subscription

RESOURCE_GROUP="$(read_backend_value resource_group_name)"
CONTAINER_NAME="$(read_backend_value container_name)"
STATE_KEY="$(read_backend_value key)"
STORAGE_ACCOUNT="$(read_backend_value storage_account_name)"

echo "This will permanently delete the Terraform remote state backend:"
echo "  Resource group:   ${RESOURCE_GROUP}"
echo "  Storage account:  ${STORAGE_ACCOUNT}"
echo "  Container:        ${CONTAINER_NAME}"
echo "  State key:        ${STATE_KEY}"
echo
echo "Run 'terraform destroy' in this directory before cleanup when possible."
echo "The entire resource group is removed, including the storage account and all state blobs."
echo

read -rp "Type 'yes' to permanently delete these resources: " confirm
if [[ "${confirm}" != "yes" ]]; then
  echo "Cleanup cancelled."
  exit 0
fi

echo

if az group show --name "${RESOURCE_GROUP}" >/dev/null 2>&1; then
  echo "Deleting resource group: ${RESOURCE_GROUP}"
  az group delete --name "${RESOURCE_GROUP}" --yes --no-wait
  echo "Resource group deletion started."
else
  echo "Resource group not found (already deleted): ${RESOURCE_GROUP}"
fi

echo
echo "Remote state backend cleanup complete."
