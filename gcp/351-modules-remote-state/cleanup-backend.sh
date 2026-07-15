#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_TF="${SCRIPT_DIR}/backend.tf"

if [[ ! -f "${BACKEND_TF}" ]]; then
  echo "Error: ${BACKEND_TF} not found." >&2
  exit 1
fi

if ! gcloud auth list --filter=status:ACTIVE --format='value(account)' | grep -q .; then
  echo "Error: not logged in to Google Cloud. Run 'gcloud auth login' first." >&2
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

bucket_exists() {
  local name="$1"
  gcloud storage buckets describe "gs://${name}" >/dev/null 2>&1
}

select_project() {
  local projects
  local count
  local choice
  local index
  local project_id
  local project_name

  mapfile -t projects < <(gcloud projects list --format='value(projectId,name)')

  if [[ "${#projects[@]}" -eq 0 ]]; then
    echo "Error: no GCP projects found." >&2
    exit 1
  fi

  echo "Available GCP projects:"
  echo

  for index in "${!projects[@]}"; do
    IFS=$'\t' read -r project_id project_name <<< "${projects[$index]}"
    printf '  %d) %s\n     %s\n\n' "$((index + 1))" "${project_id}" "${project_name}"
  done

  count="${#projects[@]}"

  while true; do
    read -rp "Select project [1-${count}]: " choice
    if [[ "${choice}" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= count)); then
      index=$((choice - 1))
      IFS=$'\t' read -r project_id _ <<< "${projects[$index]}"
      gcloud config set project "${project_id}" >/dev/null
      echo
      echo "Using project: ${project_id}"
      echo
      return
    fi

    echo "Invalid selection. Enter a number between 1 and ${count}." >&2
  done
}

select_project

PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
STATE_PREFIX="$(read_backend_value prefix)"
BUCKET="$(read_backend_value bucket)"

echo "This will permanently delete the Terraform remote state backend:"
echo "  Project:          ${PROJECT_ID}"
echo "  State bucket:     ${BUCKET}"
echo "  State prefix:     ${STATE_PREFIX}"
echo
echo "Run 'terraform destroy' in this directory before cleanup when possible."
echo "The entire state bucket is removed, including all objects and versions."
echo

read -rp "Type 'yes' to permanently delete these resources: " confirm
if [[ "${confirm}" != "yes" ]]; then
  echo "Cleanup cancelled."
  exit 0
fi

echo

if bucket_exists "${BUCKET}"; then
  echo "Deleting all objects in state bucket: ${BUCKET}"
  gcloud storage rm -r "gs://${BUCKET}/**" --all-versions --quiet 2>/dev/null || true

  echo "Deleting state bucket: ${BUCKET}"
  gcloud storage buckets delete "gs://${BUCKET}" --quiet
else
  echo "State bucket not found (already deleted): ${BUCKET}"
fi

echo
echo "Remote state backend cleanup complete."
