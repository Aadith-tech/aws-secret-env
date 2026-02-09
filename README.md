# Fetch Secret Manager

A lightweight bash script to fetch secrets from AWS Secrets Manager and convert them to `.env` format.

## Overview

This utility script retrieves JSON secrets stored in AWS Secrets Manager and automatically converts them into environment variable format (`.env`) for use in your application. It parses JSON key-value pairs and generates a properly formatted environment file.

## Requirements
- **AWS CLI** (version 2.0+) installed and configured
- **AWS Credentials** configured with appropriate IAM permissions

### AWS Permissions Required

Your AWS credentials need the following permission to access secrets:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:*:*:secret:*"
    }
  ]
}
```

## Installation

1. Clone or download the repository:
   ```bash
   git clone <repository-url>
   cd fetch_secret-manager
   ```

2. Make the script executable:
   ```bash
   chmod +x fetch-env.sh
   ```

## Usage

### Basic Usage

```bash
./fetch-env.sh <secret_name> <region> [output_file]
```

### Parameters

| Parameter | Required | Description | Default |
|-----------|----------|-------------|---------|
| `secret_name` | Yes | The name or ARN of the secret in AWS Secrets Manager | - |
| `region` | Yes | AWS region where the secret is stored (e.g., `us-east-1`) | - |
| `output_file` | No | Output file path for the generated `.env` file | `.env` |

### Examples

**Fetch a secret and save to the default `.env` file:**
```bash
./fetch-env.sh my-app-config us-east-1
```

**Fetch a secret and save to a custom file:**
```bash
./fetch-env.sh prod/database/credentials eu-west-1 config.env
```

**Fetch a secret in a different AWS region:**
```bash
./fetch-env.sh api-keys ap-southeast-1 .env.production
```

## How It Works

1. Validates that both `secret_name` and `region` parameters are provided
2. Fetches the secret value from AWS Secrets Manager using the AWS CLI
3. Extracts the JSON secret value from the API response
4. Parses the JSON and converts key-value pairs to environment variable format:
   - Removes curly braces `{}`
   - Removes double quotes `"`
   - Converts colons `:` to equals signs `=`
   - Splits entries by newlines
5. Creates the output `.env` file with a header comment referencing the source secret
6. Displays confirmation message with the output file path

## Output Format

The generated `.env` file will look like:

```env
# Generated from secret: my-app-config (region: us-east-1)
DB_HOST=localhost
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=secretpassword
API_KEY=your-api-key
```

