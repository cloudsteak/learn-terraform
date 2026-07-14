#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_TF="${SCRIPT_DIR}/backend.tf"
DEFAULT_LOCATION="europe-north1"

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

update_backend_bucket_name() {
  local name="$1"
  local tmp_file

  tmp_file="$(mktemp)"
  sed "s/bucket[[:space:]]*=.*/bucket = \"${name}\"/" "${BACKEND_TF}" > "${tmp_file}"
  mv "${tmp_file}" "${BACKEND_TF}"
}

generate_bucket_name() {
  local project_id
  project_id="$(gcloud config get-value project 2>/dev/null)"
  printf 'learn-terraform-state-%s-%09d' "${project_id}" "$((RANDOM * RANDOM % 900000000 + 100000000))"
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

if bucket_exists "${BUCKET}"; then
  echo "Using existing state bucket from backend.tf: ${BUCKET}"
else
  BUCKET="$(generate_bucket_name)"
  update_backend_bucket_name "${BUCKET}"
  echo "Generated state bucket name: ${BUCKET}"
  echo "Updated bucket in ${BACKEND_TF}"
fi

echo "Terraform backend settings:"
echo "  Project:          ${PROJECT_ID}"
echo "  Location:         ${DEFAULT_LOCATION}"
echo "  State bucket:     ${BUCKET}"
echo "  State prefix:     ${STATE_PREFIX}"
echo

if ! bucket_exists "${BUCKET}"; then
  echo "Creating state bucket: ${BUCKET}"
  gcloud storage buckets create "gs://${BUCKET}" \
    --project="${PROJECT_ID}" \
    --location="${DEFAULT_LOCATION}" \
    --uniform-bucket-level-access \
    --public-access-prevention \
    --output-none
else
  echo "State bucket already exists: ${BUCKET}"
fi

gcloud storage buckets update "gs://${BUCKET}" --versioning --output-none

echo
echo "Remote state backend is ready for Terraform."
echo "Next: terraform init && terraform apply"
