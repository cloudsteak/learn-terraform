#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_TF="${SCRIPT_DIR}/backend.tf"

if [[ ! -f "${BACKEND_TF}" ]]; then
  echo "Error: ${BACKEND_TF} not found." >&2
  exit 1
fi

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Error: AWS credentials not configured. Run 'aws configure' first." >&2
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

select_profile() {
  local profiles
  local count
  local choice
  local index
  local profile

  mapfile -t profiles < <(aws configure list-profiles)

  if [[ "${#profiles[@]}" -eq 0 ]]; then
    echo "Using default AWS credential chain (no named profiles found)."
    echo
    return
  fi

  if [[ "${#profiles[@]}" -eq 1 ]]; then
    export AWS_PROFILE="${profiles[0]}"
    echo "Using AWS profile: ${AWS_PROFILE}"
    echo
    return
  fi

  echo "Available AWS profiles:"
  echo

  for index in "${!profiles[@]}"; do
    printf '  %d) %s\n' "$((index + 1))" "${profiles[$index]}"
  done

  echo
  count="${#profiles[@]}"

  while true; do
    read -rp "Select profile [1-${count}]: " choice
    if [[ "${choice}" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= count)); then
      index=$((choice - 1))
      profile="${profiles[$index]}"
      export AWS_PROFILE="${profile}"
      echo
      echo "Using AWS profile: ${AWS_PROFILE}"
      echo
      return
    fi

    echo "Invalid selection. Enter a number between 1 and ${count}." >&2
  done
}

bucket_exists() {
  local name="$1"
  aws s3api head-bucket --bucket "${name}" >/dev/null 2>&1
}

select_profile

REGION="$(read_backend_value region)"
STATE_KEY="$(read_backend_value key)"
BUCKET="$(read_backend_value bucket)"

echo "This will permanently delete the Terraform remote state backend:"
echo "  Region:           ${REGION}"
echo "  State bucket:     ${BUCKET}"
echo "  State key:        ${STATE_KEY}"
echo "  Locking:          S3 lockfile (use_lockfile = true)"
echo
echo "Run 'terraform destroy' in this directory before cleanup when possible."
echo "The entire state bucket is removed, including state files and lock files."
echo

read -rp "Type 'yes' to permanently delete these resources: " confirm
if [[ "${confirm}" != "yes" ]]; then
  echo "Cleanup cancelled."
  exit 0
fi

echo

if bucket_exists "${BUCKET}"; then
  echo "Deleting state bucket: ${BUCKET}"
  aws s3 rb "s3://${BUCKET}" --force
else
  echo "State bucket not found (already deleted): ${BUCKET}"
fi

echo
echo "Remote state backend cleanup complete."
