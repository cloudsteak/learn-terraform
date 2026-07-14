#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_TF="${SCRIPT_DIR}/backend.tf"
LOCATION="Sweden Central"

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

update_backend_storage_name() {
  local name="$1"
  local tmp_file

  tmp_file="$(mktemp)"
  sed "s/storage_account_name[[:space:]]*=.*/storage_account_name = \"${name}\"/" "${BACKEND_TF}" > "${tmp_file}"
  mv "${tmp_file}" "${BACKEND_TF}"
}

generate_storage_account_name() {
  printf 'terraform%09d' "$((RANDOM * RANDOM % 900000000 + 100000000))"
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
STATE_KEY="$(read_backend_value state_key)"
STORAGE_ACCOUNT="$(read_backend_value storage_account_name)"

if az storage account show --name "${STORAGE_ACCOUNT}" --resource-group "${RESOURCE_GROUP}" >/dev/null 2>&1; then
  echo "Using existing storage account from backend.tf: ${STORAGE_ACCOUNT}"
else
  STORAGE_ACCOUNT="$(generate_storage_account_name)"
  update_backend_storage_name "${STORAGE_ACCOUNT}"
  echo "Generated storage account name: ${STORAGE_ACCOUNT}"
  echo "Updated storage_account_name in ${BACKEND_TF}"
fi

echo "Terraform backend settings:"
echo "  Resource group:   ${RESOURCE_GROUP}"
echo "  Storage account:  ${STORAGE_ACCOUNT}"
echo "  Container:        ${CONTAINER_NAME}"
echo "  State key:        ${STATE_KEY}"
echo

if ! az group show --name "${RESOURCE_GROUP}" >/dev/null 2>&1; then
  echo "Creating resource group: ${RESOURCE_GROUP}"
  az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}" --output none
else
  echo "Resource group already exists: ${RESOURCE_GROUP}"
fi

if ! az storage account show --name "${STORAGE_ACCOUNT}" --resource-group "${RESOURCE_GROUP}" >/dev/null 2>&1; then
  echo "Creating storage account: ${STORAGE_ACCOUNT}"
  az storage account create \
    --name "${STORAGE_ACCOUNT}" \
    --resource-group "${RESOURCE_GROUP}" \
    --location "${LOCATION}" \
    --sku Standard_LRS \
    --min-tls-version TLS1_2 \
    --output none
else
  echo "Storage account already exists: ${STORAGE_ACCOUNT}"
fi

ACCOUNT_KEY="$(az storage account keys list \
  --resource-group "${RESOURCE_GROUP}" \
  --account-name "${STORAGE_ACCOUNT}" \
  --query '[0].value' \
  --output tsv)"

if ! az storage container show \
  --name "${CONTAINER_NAME}" \
  --account-name "${STORAGE_ACCOUNT}" \
  --account-key "${ACCOUNT_KEY}" >/dev/null 2>&1; then
  echo "Creating blob container: ${CONTAINER_NAME}"
  az storage container create \
    --name "${CONTAINER_NAME}" \
    --account-name "${STORAGE_ACCOUNT}" \
    --account-key "${ACCOUNT_KEY}" \
    --output none
else
  echo "Blob container already exists: ${CONTAINER_NAME}"
fi

echo
echo "Remote state backend is ready for Terraform."
echo "Next: terraform init && terraform apply"
