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

update_backend_bucket_name() {
  local name="$1"
  local tmp_file

  tmp_file="$(mktemp)"
  sed "s/bucket[[:space:]]*=.*/bucket         = \"${name}\"/" "${BACKEND_TF}" > "${tmp_file}"
  mv "${tmp_file}" "${BACKEND_TF}"
}

generate_bucket_name() {
  local account_id
  account_id="$(aws sts get-caller-identity --query Account --output text)"
  printf 'learn-terraform-state-%s-%09d' "${account_id}" "$((RANDOM * RANDOM % 900000000 + 100000000))"
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

create_bucket() {
  local name="$1"
  local region="$2"

  if [[ "${region}" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "${name}" \
      --region "${region}" \
      --output none
  else
    aws s3api create-bucket \
      --bucket "${name}" \
      --region "${region}" \
      --create-bucket-configuration "LocationConstraint=${region}" \
      --output none
  fi
}

select_profile

REGION="$(read_backend_value region)"
DYNAMODB_TABLE="$(read_backend_value dynamodb_table)"
STATE_KEY="$(read_backend_value key)"
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
echo "  Region:           ${REGION}"
echo "  State bucket:     ${BUCKET}"
echo "  DynamoDB table:   ${DYNAMODB_TABLE}"
echo "  State key:        ${STATE_KEY}"
echo

if ! bucket_exists "${BUCKET}"; then
  echo "Creating state bucket: ${BUCKET}"
  create_bucket "${BUCKET}" "${REGION}"
else
  echo "State bucket already exists: ${BUCKET}"
fi

aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --versioning-configuration Status=Enabled \
  --output none

aws s3api put-public-access-block \
  --bucket "${BUCKET}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
  --output none

aws s3api put-bucket-encryption \
  --bucket "${BUCKET}" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
  --output none

if ! aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${REGION}" >/dev/null 2>&1; then
  echo "Creating DynamoDB lock table: ${DYNAMODB_TABLE}"
  aws dynamodb create-table \
    --table-name "${DYNAMODB_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}" \
    --output none

  echo "Waiting for DynamoDB table to become active..."
  aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}" --region "${REGION}"
else
  echo "DynamoDB lock table already exists: ${DYNAMODB_TABLE}"
fi

echo
echo "Remote state backend is ready for Terraform."
echo "Next: terraform init && terraform apply"
