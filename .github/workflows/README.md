# Workflow Configuration Guide

## `build-with-infisical.yml` — Build & Push Docker Image with Infisical Secrets

This document explains **step-by-step how to configure and run** the GitHub Actions workflow that:

1. Fetches secrets from **Infisical** using the CLI + a shell script
2. Generates a `.env` file from those secrets
3. Builds a **Docker image** with the `.env` baked in
4. Pushes the image to **Docker Hub**

---

## Prerequisites

Before configuring the workflow, make sure you have:

- [ ] A **GitHub** repository with this code
- [ ] An **Infisical** account at [app.infisical.com](https://app.infisical.com)
- [ ] A **Docker Hub** account at [hub.docker.com](https://hub.docker.com)

---

## Step 1 — Set Up Infisical

### 1.1 Create a Project

1. Log in to [app.infisical.com](https://app.infisical.com)
2. Click **New Project** → name it (e.g. `secret-management`)
3. Go to the **Development** environment
4. Click **+ Add Secret** and add your secrets:

   | Secret Name | Example Value        |
   |-------------|----------------------|
   | `APIkey`    | `sk_live_xxxx`       |
   | `password`  | `MySecurePassword!`  |

### 1.2 Note Your Project ID

Your Project ID is in the Infisical dashboard URL:

```
app.infisical.com/…/projects/secret-management/[THIS-IS-YOUR-PROJECT-ID]/overview
```

Copy that UUID — you will need it as `INFISICAL_PROJECT_ID`.

---

## Step 2 — Get Your Infisical Token

The workflow authenticates using a **Machine Identity Universal Auth Token**.

1. In Infisical, go to your project → **Access Control** (left sidebar)
2. Click **Machine Identities** → **Create Machine Identity**
3. Give it a name (e.g. `github-actions`) and assign role **Developer**
4. Click the created identity → go to **Universal Auth** tab
5. Click **Add Token**
6. Copy the token — it looks like `st.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.xxxxxxxx...`

> Copy it immediately — it is only shown once.

---

## Step 3 — Set Up Docker Hub Token

1. Log in to [hub.docker.com](https://hub.docker.com)
2. Go to **Account Settings → Security → New Access Token**
3. Give it a description (e.g. `github-actions`)
4. Set permissions to **Read & Write**
5. Click **Generate** and copy the token

> Copy it immediately — it is only shown once.

---

## Step 4 — Add GitHub Secrets

Go to your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

Add the following **4 secrets**:

| Secret Name             | Value                                   | Where to get it                                 |
|-------------------------|-----------------------------------------|-------------------------------------------------|
| `INFISICAL_TOKEN`       | `st.xxxxxxxxx...`                       | Step 2 above                                    |
| `INFISICAL_PROJECT_ID`  | `37478544-d03d-421c-ae93-...`           | Infisical dashboard URL                         |
| `DOCKERHUB_USERNAME`    | `yourdockerhubusername`                 | Your Docker Hub username                        |
| `DOCKERHUB_TOKEN`       | `dckr_pat_xxxxxxxxx`                    | Step 3 above                                    |

**Screenshot guide:**

```
GitHub Repo
  └── Settings
        └── Secrets and variables
              └── Actions
                    └── New repository secret
                          ├── INFISICAL_TOKEN       ← paste token here
                          ├── INFISICAL_PROJECT_ID  ← paste project UUID here
                          ├── DOCKERHUB_USERNAME    ← paste username here
                          └── DOCKERHUB_TOKEN       ← paste token here
```

---

## Step 5 — Configure GitHub Environments

The workflow uses GitHub Environments to map branches to Infisical environments.

Go to: **Settings → Environments → New environment**

Create these 3 environments:

| Environment Name | Used for branch | Infisical env slug |
|------------------|-----------------|--------------------|
| `dev`            | `develop`       | `dev`              |
| `staging`        | `develop`       | `staging`          |
| `prod`           | `main`          | `prod`             |

> You can leave environments without protection rules for a basic setup. Add **required reviewers** for `prod` if needed.

---

## Step 6 — Run the Workflow

### Automatic (on push)

Push to `main` or `develop` — the workflow triggers automatically:

```bash
git add .
git commit -m "your message"
git push origin main
```

### Manual (workflow_dispatch)

1. Go to your GitHub repo → **Actions** tab
2. Click **Build & Push Docker Image — Infisical Secrets**
3. Click **Run workflow**
4. Select the target environment: `dev` / `staging` / `prod`
5. Click **Run workflow**

---

## Workflow Triggers

| Trigger                    | What happens                                      |
|----------------------------|---------------------------------------------------|
| Push to `main`             | Fetches secrets → builds → pushes image to Docker Hub with `latest` tag |
| Push to `develop`          | Fetches secrets → builds → pushes image with `develop` tag |
| Pull Request to `main`     | Builds image only — **does NOT push** to Docker Hub |
| Manual (`workflow_dispatch`)| You choose the environment — full build + push   |

---

## Pipeline Steps Explained

```
Step 1 — Checkout Repository
         Clones the repo onto the GitHub Actions runner.

Step 2 — Install Infisical CLI
         Downloads and installs the Infisical CLI on the runner.
         Uses: https://artifacts-cli.infisical.com/setup.deb.sh

Step 3 — Fetch Secrets via fetch-infisical-env.sh
         Runs the shell script with 3 arguments:
           $1 = APP_ENV          (e.g. dev)
           $2 = INFISICAL_PROJECT_ID
           $3 = .env             (output file)
         The script authenticates via INFISICAL_TOKEN (env var)
         and runs: infisical export --format dotenv > .env

Step 4 — Verify .env File Generated
         Prints the key names (not values) to confirm secrets loaded.
         Values are automatically masked by GitHub Actions.

Step 5 — Set Up Docker Buildx
         Enables multi-platform Docker builds.

Step 6 — Log in to Docker Hub
         Uses DOCKERHUB_USERNAME + DOCKERHUB_TOKEN to authenticate.

Step 7 — Extract Docker Metadata
         Generates image tags based on branch name, commit SHA,
         and whether this is a push to main (adds "latest" tag).

Step 8 — Build & Push Docker Image
         Builds the image using the Dockerfile.
         The .env file generated in Step 3 is copied into the
         image via: COPY .env .env  (in the Dockerfile)
         Pushes to Docker Hub only if this is NOT a pull request.
```

---

## Docker Image Tags

Your image will be available on Docker Hub as:

| Tag format                    | When it's applied                        | Example                          |
|-------------------------------|------------------------------------------|----------------------------------|
| `latest`                      | Push to `main` only                      | `youruser/test-workflow-app:latest` |
| Branch name                   | Push to any branch                       | `youruser/test-workflow-app:main`   |
| `<env>-<short-sha>`           | Every push                               | `youruser/test-workflow-app:dev-abc1234` |

---


## Environment Variables Reference

| Variable              | Source              | Description                              |
|-----------------------|---------------------|------------------------------------------|
| `INFISICAL_TOKEN`     | GitHub Secret       | Authenticates the Infisical CLI          |
| `INFISICAL_PROJECT_ID`| GitHub Secret       | Infisical project to fetch secrets from  |
| `DOCKERHUB_USERNAME`  | GitHub Secret       | Docker Hub login username                |
| `DOCKERHUB_TOKEN`     | GitHub Secret       | Docker Hub access token for push         |
| `APP_ENV`             | Workflow input      | Target environment (`dev/staging/prod`)  |
| `GIT_SHA`             | `github.sha`        | Injected into image as build arg         |

