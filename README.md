# 🔐 Secret Manager — Infisical + GitHub Actions CI/CD

A professional, production-ready demo that integrates **Infisical Secret Manager** into a **GitHub Actions** pipeline to securely inject secrets **before** a Docker image build.

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions Pipeline                  │
│                                                             │
│  ┌──────────────┐     ┌──────────────┐    ┌─────────────┐  │
│  │   Checkout   │────▶│   Infisical  │───▶│  .env File  │  │
│  │     Code     │     │ Secret Fetch │    │  Generated  │  │
│  └──────────────┘     └──────────────┘    └──────┬──────┘  │
│                                                  │         │
│                                           ┌──────▼──────┐  │
│                                           │   Docker    │  │
│                                           │    Build    │  │
│                                           └──────┬──────┘  │
│                                                  │         │
│                                           ┌──────▼──────┐  │
│                                           │   Push to   │  │
│                                           │    GHCR     │  │
│                                           └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

> Secrets are **fetched at pipeline runtime** — they are **never stored** in the repository, Dockerfile, or any config file.

---

## 🗂 Repository Structure

```
fetch_secret-manager/
├── .github/
│   └── workflows/
│       └── build-with-infisical.yml   ← GitHub Actions workflow
├── SM_Alternative/
│   └── updated_doc.md                 ← Comparison: AWS SM alternatives
├── Dockerfile                         ← Demo Docker image
├── fetch-env.sh                       ← Legacy: AWS Secrets Manager helper
├── fetch-infisical-env.sh             ← Infisical CLI secret fetcher (.sh)
└── README.md
```

---

## 🔑 Infisical Setup (One-Time)

### 1. Create an Infisical Account & Project
1. Sign up at [app.infisical.com](https://app.infisical.com)
2. Create an **Organization** → **New Project** → name it `secret-management`
3. Under **Development** environment, add your secrets:

   | Secret Name | Example Value    |
   |-------------|------------------|
   | `APIKEY`    | `my-api-key-123` |
   | `PASSWORD`  | `supersecret`    |

### 2. Create a Machine Identity & Token
1. Go to **Project Settings → Access Control → Machine Identities**
2. Click **Create Machine Identity**
3. Assign role: **`Developer`** (or `Reader` for least-privilege)
4. After creation, click the identity → **Universal Auth → Create Token**
5. Copy the **token** (starts with `st.`) — this becomes `INFISICAL_TOKEN`

### 3. Find Your Project ID
The Project ID is visible in the Infisical dashboard URL:
```
app.infisical.com/…/projects/secret-management/[PROJECT_ID]/overview
                                                     ↑
                              Copy this UUID (e.g. 37478544-d03d-421c-ae93-873d9ebcebbb)
```

---

## ⚙️ GitHub Repository Secrets Configuration

Go to your GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**

| Secret Name               | Value                                          |
|---------------------------|------------------------------------------------|
| `INFISICAL_TOKEN`         | Universal Auth token from Machine Identity     |
| `INFISICAL_PROJECT_ID`    | Your Infisical Project UUID                    |

> ⚠️ **Never** hardcode these values in any file or workflow YAML.

---

## 🚀 GitHub Actions Workflow

**File:** `.github/workflows/build-with-infisical.yml`

### Triggers

| Event               | Behavior                                   |
|---------------------|--------------------------------------------|
| Push to `main`      | Full build → push to GHCR (production)     |
| Push to `develop`   | Full build → push to GHCR (dev tag)        |
| Pull Request        | Build only — **no push**                   |
| `workflow_dispatch` | Manual trigger with environment selection  |

### Pipeline Jobs

```
Job 1: fetch-secrets-and-build
  ├── 📥 Checkout code
  ├── 📦 Install Infisical CLI
  ├── 🔐 Run fetch-infisical-env.sh  ← .env written here
  ├── ✅ Verify .env file generated
  ├── 🛠  Set up Docker Buildx
  ├── 🔑 Log in to GHCR
  ├── 🏷  Extract Docker metadata (tags)
  ├── 🐳 Build & Push Docker image
  └── 📋 Print build summary

Job 2: security-scan (runs after Job 1)
  └── 🛡 Trivy vulnerability scan
```

### Manual Trigger (Workflow Dispatch)

You can manually run the pipeline from **GitHub → Actions → Build & Push Docker Image** and select the target environment:

```
Environment options:
  • dev      → fetches from Development secrets
  • staging  → fetches from Staging secrets
  • prod     → fetches from Production secrets
```

---

## 🐳 Docker Image

The image is published to **GitHub Container Registry (GHCR)**:

```
ghcr.io/<your-github-username>/test-workflow-app:latest
ghcr.io/<your-github-username>/test-workflow-app:dev-<sha>
ghcr.io/<your-github-username>/test-workflow-app:main
```

### Build Arguments

| Argument  | Description                   | Default |
|-----------|-------------------------------|---------|
| `APP_ENV` | Target environment name       | `dev`   |
| `GIT_SHA` | Git commit SHA (traceability) | `local` |

---

## 🔄 Secret Injection Flow (Step-by-Step)

```
1. GitHub Actions runner starts
2. Infisical CLI is installed on the runner (apt package)
3. fetch-infisical-env.sh is called with env + project_id args
   └── Authenticates via: INFISICAL_TOKEN (env var)
4. CLI runs: infisical export --projectId ... --env ... --format dotenv
   └── Returns all secrets as KEY=VALUE lines
5. .env file is written with a header + all secret key=value pairs
   └── Written to: .env (workspace root)
6. Docker build picks up the .env file via COPY .env .env
7. Image is pushed to GHCR
```

---

## 🛡 Security Best Practices

| Practice                       | How It's Implemented                              |
|--------------------------------|---------------------------------------------------|
| No secrets in repo             | All secrets live exclusively in Infisical         |
| Masked in logs                 | GitHub Actions auto-masks secret values           |
| Least-privilege access         | Machine Identity scoped to read-only              |
| Short-lived credentials        | Machine Identity tokens expire automatically      |
| Vulnerability scanning         | Trivy scans the final image post-build            |
| No push on PRs                 | `push: github.event_name != 'pull_request'`       |
| Secrets not in build args      | Secrets injected via env, not `--build-arg`       |

---

## 📦 Local Development (Legacy — AWS Secrets Manager)

The `fetch-env.sh` script in this repo still supports fetching from **AWS Secrets Manager** for local use:

```bash
chmod +x fetch-env.sh
./fetch-env.sh <secret_name> <aws_region> [output_file]

# Example
./fetch-env.sh my-app-config us-east-1 .env.local
```

> For the full comparison of AWS SM vs Infisical vs other alternatives, see [`SM_Alternative/updated_doc.md`](SM_Alternative/updated_doc.md).

---

## 🔧 Shell Script — fetch-infisical-env.sh

This script mirrors `fetch-env.sh` but targets **Infisical** instead of AWS Secrets Manager.

```bash
# Usage
chmod +x fetch-infisical-env.sh
INFISICAL_TOKEN=st.xxx ./fetch-infisical-env.sh <environment> <project_id> [output_file]

# Examples
INFISICAL_TOKEN=st.xxx ./fetch-infisical-env.sh dev   abc-123-uuid  .env
INFISICAL_TOKEN=st.xxx ./fetch-infisical-env.sh staging abc-123-uuid .env.staging
INFISICAL_TOKEN=st.xxx ./fetch-infisical-env.sh prod  abc-123-uuid  .env.production
```

| Argument       | Required | Description                              | Default |
|----------------|----------|------------------------------------------|---------|
| `environment`  | Yes      | Infisical env slug (`dev/staging/prod`)  | —       |
| `project_id`   | Yes      | Infisical Project UUID                   | —       |
| `output_file`  | No       | Path for the generated `.env` file       | `.env`  |

---

## 📋 Environment Summary

| Environment | Infisical Slug | GitHub Branch |
|-------------|----------------|---------------|
| Development | `dev`          | `develop`     |
| Staging     | `staging`      | `develop`     |
| Production  | `prod`         | `main`        |

---

## 📎 References

- [Infisical Documentation](https://infisical.com/docs)
- [Infisical GitHub Action](https://github.com/Infisical/secrets-action)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [GitHub Container Registry (GHCR)](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Trivy Vulnerability Scanner](https://github.com/aquasecurity/trivy-action)
