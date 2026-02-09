#!/usr/bin/env bash
set -euo pipefail

SECRET_NAME="${1:-}"
AWS_REGION="${2:-}"
OUTPUT_FILE="${3:-.env}"


if [[ -z "$SECRET_NAME" || -z "$AWS_REGION" ]]; then
  echo "Usage: $0 <secret_name> <region> [output_file]"
  exit 1
fi

echo "Fetching secret: $SECRET_NAME from region: $AWS_REGION"

SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region "$AWS_REGION" \
  --query SecretString \
  --output text)

if [[ -z "$SECRET_JSON" ]]; then
  echo "Failed to retrieve secret (empty or invalid)"
  exit 1
fi

ENV_CONTENT=$(echo "$SECRET_JSON" \
  | tr -d '{}' \
  | tr -d '"' \
  | tr ',' '\n' \
  | sed 's/:/=/g')

echo "# Generated from secret: $SECRET_NAME (region: $AWS_REGION)" > "$OUTPUT_FILE"
echo "$ENV_CONTENT" >> "$OUTPUT_FILE"

echo " .env file created at: $OUTPUT_FILE"
