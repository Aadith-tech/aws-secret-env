#!/usr/bin/env bash

#  fetch-infisical-env.sh
#  Fetches secrets from Infisical using the Infisical CLI
#  and writes them to a .env file in dotenv format.

#  Usage:
#    ./fetch-infisical-env.sh <environment> <project_id> [output_file]
#
#  Arguments:
#    environment   Infisical environment slug (dev / staging / prod)
#    project_id    Infisical Project UUID
#    output_file   Output .env file path (default: .env)
#
#  Required env var (set by CI or exported locally):
#    INFISICAL_TOKEN   Universal Auth machine identity token
#
#  Example:
#    INFISICAL_TOKEN=st.xxx ./fetch-infisical-env.sh dev abc-123 .env

set -euo pipefail

# Arguments
APP_ENV="${1:-}"
PROJECT_ID="${2:-}"
OUTPUT_FILE="${3:-.env}"

# Validation
if [[ -z "$APP_ENV" || -z "$PROJECT_ID" ]]; then
  echo "Usage: $0 <environment> <project_id> [output_file]"
  echo "  environment   e.g. dev | staging | prod"
  echo "  project_id    Infisical Project UUID"
  echo "  output_file   (optional) default: .env"
  exit 1
fi

if [[ -z "${INFISICAL_TOKEN:-}" ]]; then
  echo "INFISICAL_TOKEN env var is not set."
  echo "   Export it or pass it before calling this script."
  exit 1
fi

echo "  Fetching secrets from Infisical"
echo "  Project  : $PROJECT_ID"
echo "  Env      : $APP_ENV"
echo "  Output   : $OUTPUT_FILE"

# Fetch & export secrets as dotenv format
SECRET_OUTPUT=$(infisical export \
  --projectId  "$PROJECT_ID" \
  --env        "$APP_ENV" \
  --path       "/" \
  --format     dotenv)

if [[ -z "$SECRET_OUTPUT" ]]; then
  echo "No secrets returned from Infisical (empty response)."
  exit 1
fi

# Write .env file
{
  echo "# Source  : Infisical (Project: $PROJECT_ID)"
  echo "# Env     : $APP_ENV"
  echo "# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "$SECRET_OUTPUT"
} > "$OUTPUT_FILE"


