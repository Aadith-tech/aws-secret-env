# Secret Manager — Infisical + GitHub Actions CI/CD

A production-ready demo that integrates **Infisical Secret Manager** into a **GitHub Actions** pipeline to securely inject secrets **before** a Docker image is built and pushed to **Docker Hub**.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                    GitHub Actions Pipeline                    │
│                                                              │
│  ┌──────────────┐    ┌───────────────────┐   ┌───────────┐  │
│  │   Checkout   │───▶│  Infisical CLI     │──▶│ .env File │  │
│  │    Code      │    │  fetch-infisical-  │   │ Generated │  │
│  └──────────────┘    │  env.sh            │   └─────┬─────┘  │
│                      └───────────────────┘         │        │
│                                              ┌──────▼──────┐ │
│                                              │   Docker    │ │
│                                              │    Build    │ │
│                                              └──────┬──────┘ │
│                                                     │        │
│                                              ┌──────▼──────┐ │
│                                              │  Docker Hub │ │
│                                              │    Push     │ │
│                                              └─────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

> Secrets are **fetched at pipeline runtime** — they are **never stored** in the repository, Dockerfile, or any config file.

---

## Repository Structure

```
fetch_secret-manager/
├── .github/
│   └── workflows/
│       ├── build-with-infisical.yml   ← GitHub Actions workflow
│       └── README.md                  ← Detailed workflow config guide
├── SM_Alternative/
│   └── updated_doc.md                 ← AWS SM vs Infisical comparison
├── Dockerfile                         ← Demo Docker image
├── server.js                          ← Demo Node.js app (reads .env)
├── package.json                       ← Node dependencies (dotenv)
├── fetch-env.sh                       ← Legacy: AWS Secrets Manager script
├── fetch-infisical-env.sh             ← Infisical CLI secret fetcher
├── .env.example                       ← Safe placeholder template
├── .gitignore                         ← Ensures .env is never committed
└── README.md
```

---

## Required GitHub Secrets

Go to your GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**

| Secret Name              | Description                             |
|--------------------------|-----------------------------------------|
| `INFISICAL_TOKEN`        | Machine Identity Universal Auth token   |
| `INFISICAL_PROJECT_ID`   | Your Infisical Project UUID             |
| `DOCKERHUB_USERNAME`     | Your Docker Hub username                |
| `DOCKERHUB_TOKEN`        | Docker Hub Access Token (read & write)  |

> Full setup guide: [`.github/workflows/README.md`](.github/workflows/README.md)

---

## GitHub Actions Workflow

**File:** `.github/workflows/build-with-infisical.yml`

### Triggers

| Event                | Behavior                                                    |
|----------------------|-------------------------------------------------------------|
| Push to `main`       | Fetch secrets → build → push to Docker Hub (`latest` tag)  |
| Push to `develop`    | Fetch secrets → build → push to Docker Hub (`develop` tag) |
| Pull Request         | Build only — **does NOT push**                              |
| `workflow_dispatch`  | Manual run — choose `dev` / `staging` / `prod`             |

### Pipeline Steps

```
1. Checkout Repository
2. Install Infisical CLI
3. Run fetch-infisical-env.sh  →  writes .env from Infisical
4. Verify .env keys loaded
5. Set up Docker Buildx
6. Log in to Docker Hub
7. Extract Docker metadata (tags & labels)
8. Build & Push image to Docker Hub
```

---


---

## fetch-infisical-env.sh — Usage

This script mirrors `fetch-env.sh` but targets **Infisical** instead of AWS Secrets Manager.

```bash
# Make executable
chmod +x fetch-infisical-env.sh

# Usage
INFISICAL_TOKEN=st.xxx ./fetch-infisical-env.sh <environment> <project_id> [output_file]

# Examples
INFISICAL_TOKEN=st.xxx ./fetch-infisical-env.sh dev    your-project-uuid  .env
INFISICAL_TOKEN=st.xxx ./fetch-infisical-env.sh staging your-project-uuid  .env.staging
INFISICAL_TOKEN=st.xxx ./fetch-infisical-env.sh prod   your-project-uuid  .env.production
```

| Argument       | Required | Description                             | Default |
|----------------|------|-----------------------------------------|---------|
| `environment`  | Yes | Infisical env slug (`dev/staging/prod`) | —       |
| `project_id`   | Yes | Infisical Project UUID                  | —       |
| `output_file`  | No   | Path for the generated `.env` file      | `.env`  |

---



