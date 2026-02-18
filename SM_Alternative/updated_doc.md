# AWS Secrets Manager Alternatives Report

---

## Executive Summary

Based on the current workflow (fetching secrets from AWS Secrets Manager using a .sh script and converting them to .env files in GitHub Actions CI/CD), this report evaluates **cost-effective alternatives** that maintain compatibility with your existing pipeline architecture.

**Current AWS Secrets Manager Costs:**
- **$0.40 per secret per month**
- **$0.05 per 10,000 API calls**
- No free tier (except 30-day trial for new users)

**Key Workflow Requirement:**
All alternatives below **support CLI/script-based secret fetching** and can be used with your existing `.sh script → .env file` workflow pattern. No solutions requiring complete workflow rewrites are included.


### CLI Tool Availability (For .sh Script Integration)

| Alternative | CLI Available? | CLI Command Example | .env Export |
|---|---|---|---|
| **SSM Parameter Store** | AWS CLI | `aws ssm get-parameter --name /secret --with-decryption` | Manual script |
| **GitHub Secrets** | Env vars only | `echo "${{ secrets.KEY }}"` (in Actions) | Manual script |
| **Infisical** | Native CLI | `infisical export --format=dotenv > .env` | Built-in |
| **Doppler** | Native CLI | `doppler secrets download --format env > .env` | Built-in |
| **Vault** | Native CLI | `vault kv get -field=value secret/path` | Manual script |
| **Akeyless (Keyless Secrets)** | Native CLI | `akeyless get-secret-value --name <secret>` | Manual script |


---

## Alternative 1: AWS SSM Parameter Store (Standard & Advanced Tier)

### Overview
AWS Systems Manager Parameter Store is AWS's configuration management service that can store secrets as **SecureString** parameters encrypted with AWS KMS. The Standard tier is **completely free**, while the Advanced tier costs $0.05/secret/month and supports larger secrets (up to 8 KB) and parameter policies.

### Pricing
| Component | AWS Secrets Manager | SSM Parameter Store (Standard) | SSM Parameter Store (Advanced) |
|---|---|---|---|
| Storage cost per secret | $0.40/month | **$0.00 (FREE)** | $0.05/month |
| API calls (per 10K) | $0.05 | **$0.00 (FREE for <40 TPS)** | $0.05 |
| Maximum secret size | 64 KB | 4 KB | 8 KB |
| Cross-region replication | ($0.40/replica) | (manual setup needed) | (manual setup needed) |
| Encryption | KMS encrypted | KMS encrypted (SecureString) | KMS encrypted (SecureString) |
| Parameter policies | No | No | Yes (expiration, notifications) |


### Workflow Integration

Your existing .sh script only needs **minimal modification**:

```bash
# NEW (SSM Parameter Store) example fetch script:
aws ssm get-parameter \
  --name /my-app/production/db-password \
  --with-decryption \
  --query Parameter.Value \
  --output text >> .env
```

**Important:** The `--with-decryption` flag automatically decrypts the KMS-encrypted SecureString parameter. Without this flag, you'll get the encrypted value.

**GitHub Actions workflow remains identical** - just update your fetch script.

### Benefits
- **100% cost reduction** - Standard tier is completely free
- **Drop-in replacement** - minimal script changes required
- **Same IAM permission model** - similar access control
- **KMS encryption** - SecureString parameters are encrypted at rest
- **Native AWS integration** - works with existing AWS tooling
- **Audit trail** - AWS CloudTrail logs all access
- **Hierarchical naming** - organize secrets with path structure (e.g., `/app/env/secret`)

### Drawbacks
- **No automatic rotation** - must build custom rotation with Lambda + EventBridge
- **4 KB size limit (Standard)** - larger secrets need Advanced tier ($0.05/month per secret, still 87.5% cheaper than Secrets Manager)
- **No cross-account access** - all secrets must be in same AWS account
- **No cross-region replication** - manual setup required for DR scenarios
- **Manual versioning** - limited to 100 versions, no staging labels

### When to Use SSM Parameter Store
- You have **static secrets** that don't need frequent rotation
- Your secrets are **under 4 KB** each
- You're **cost-sensitive** and don't need enterprise rotation features
- You're already using AWS and want **zero additional cost**
- Your workflow is **single-region, single-account**

---

## Alternative 2: GitHub Actions Encrypted Secrets (Built-in)

### Overview
GitHub provides **native encrypted secret storage** at the repository, environment, and organization level. Secrets are encrypted using **libsodium sealed boxes** and injected as environment variables during workflow execution.

### Pricing
| Tier | Cost | Secret Limit | Notes |
|---|---|---|---|
| **Free/Public repos** | $0 | Unlimited | Free forever |
| **GitHub Team** | $4/user/month | Unlimited | Part of subscription |
| **GitHub Enterprise** | $21/user/month | Unlimited | Part of subscription |

**For most teams already on GitHub:** Secrets are included at **no additional cost**.

### Workflow Integration

**Option 1: Using .sh script (maintains your current pattern):**

```bash
#!/bin/bash
# fetch-secrets.sh

# GitHub automatically exposes secrets as environment variables
# Just write them to .env file
echo "DB_HOST=${DB_HOST}" >> .env
echo "DB_PASSWORD=${DB_PASSWORD}" >> .env
echo "API_KEY=${API_KEY}" >> .env

echo "Secrets fetched from GitHub and written to .env"
```

```yaml
# .github/workflows/deploy.yml
name: Deploy
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Fetch secrets using .sh script
        run: bash ./fetch-secrets.sh
        env:
          DB_HOST: ${{ secrets.DB_HOST }}
          DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
          API_KEY: ${{ secrets.API_KEY }}
      
      - name: Deploy
        run: ./deploy.sh
```

**Option 2: Direct inline (simplest, no separate .sh file needed):**
```yaml
- name: Create .env file
  run: |
    echo "DB_HOST=${{ secrets.DB_HOST }}" >> .env
    echo "DB_PASSWORD=${{ secrets.DB_PASSWORD }}" >> .env
    echo "API_KEY=${{ secrets.API_KEY }}" >> .env
```

### Benefits
- **Zero infrastructure cost** - no external service needed
- **Built into GitHub** - no additional accounts or services
- **Automatic masking** - secrets are masked in logs (show as ***)
- **Environment-based access** - separate secrets for dev/staging/prod
- **Approval workflows** - require manual approval before secret access
- **OIDC support** - short-lived tokens instead of long-lived credentials
- **Multi-level scope** - repository, environment, or organization-level secrets
- **Native integration** - zero latency, no external API calls

### Drawbacks
- **No external CLI tool** - can't fetch using `github-cli secrets get` (secrets only available in Actions context)
- **GitHub-only** - secrets locked to GitHub Actions (not usable outside CI/CD)
- **No rotation automation** - manual updates required
- **48 KB limit per secret** - workaround: GPG encrypt larger files
- **No centralized secret management** - harder to audit across many repos
- **Limited to CI/CD context** - can't be used by running applications/servers
- **Vendor lock-in** - switching to GitLab/Bitbucket requires migration
- **Not traditional CLI pattern** - secrets passed as env vars, not fetched via CLI commands

### When to Use GitHub Secrets
- Your secrets are **only needed in CI/CD** (not runtime applications)
- You want **zero infrastructure overhead** or external dependencies
- You're already paying for **GitHub Team/Enterprise**
- You don't need **cross-platform secret sharing** (e.g., also using AWS Lambda)
- You want **environment-based approval workflows**

---

## Alternative 3: Infisical (Open Source)

### Overview
Infisical is an **open-source, end-to-end encrypted** secrets management platform with both self-hosted and cloud options. It provides a developer-first experience with **native GitHub Actions integration**.

### Pricing
| Tier | Cost | Features |
|---|---|---|
| **Open Source (Self-Hosted)** | **$0** | Unlimited secrets, unlimited users |
| **Cloud Free Tier** | **$0** | Up to 5 users, unlimited secrets |
| **Cloud Team** | $8/user/month | Advanced features, support |

### Workflow Integration

**Option 1: Using Infisical CLI in .sh script (maintains your pattern):**

```bash
#!/bin/bash
# fetch-secrets.sh - Updated for Infisical CLI

# Install Infisical CLI (one-time in workflow)
# curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
# sudo apt-get update && sudo apt-get install -y infisical

# Fetch secrets and export to .env
infisical export --env=production --path=/app --format=dotenv > .env

echo "Secrets fetched from Infisical and written to .env"
```

```yaml
name: Deploy
on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Install Infisical CLI
        run: |
          curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
          sudo apt-get update && sudo apt-get install -y infisical
      
      - name: Fetch secrets using .sh script
        run: bash ./fetch-secrets.sh
        env:
          INFISICAL_TOKEN: ${{ secrets.INFISICAL_TOKEN }}
      
      - name: Deploy
        run: ./deploy.sh
```

**Option 2: Using GitHub Action (simpler, no CLI installation):**
```yaml
- name: Fetch secrets from Infisical
  uses: Infisical/secrets-action@v1
  with:
    client-id: ${{ secrets.INFISICAL_CLIENT_ID }}
    client-secret: ${{ secrets.INFISICAL_CLIENT_SECRET }}
    project-id: your-project-id
    environment: production
    secret-path: /app

- name: Create .env file
  run: |
    echo "DB_HOST=$DB_HOST" >> .env
    echo "DB_PASSWORD=$DB_PASSWORD" >> .env
```

### Benefits
- **Free self-hosted option** - unlimited secrets at zero cost
- **Auto-rotation** - supports automatic secret rotation for databases
- **Secret scanning** - detects leaks in Git commits (150+ types)
- **Versioned secrets** - full version control and rollback
- **CLI + SDK** - use secrets in local dev, CI/CD, and production
- **Multi-platform** - works with GitHub Actions, GitLab CI, Jenkins, etc.
- **Point-in-time recovery** - restore secrets to any previous state
- **Approval workflows** - require peer review for secret changes
- **Audit logs** - complete access history with user attribution

### Drawbacks
- **Self-hosting overhead** - need to maintain Infisical server (if self-hosted)
- **Learning curve** - new tool to learn vs. native AWS/GitHub
- **Extra dependency** - adds another service to your stack
- **Internet dependency** - cloud version requires external API calls
- **Migration effort** - need to migrate existing secrets from AWS

### Cost Comparison
| Scenario | AWS Secrets Manager | Infisical (Self-Hosted) | Infisical (Cloud Free) |
|---|---|---|---|
| 10 secrets, 5 users | $4/month | **$0** | **$0** |
| 50 secrets, 5 users | $20/month | **$0** | **$0** |
| 100 secrets, 10 users | $40/month + API | **$0** | $40/month (5 paid users) |

### When to Use Infisical
- You want **free, unlimited secret storage** without vendor lock-in
- You need **automatic rotation + secret scanning**
- You want **multi-platform support** (GitHub + GitLab + Jenkins + local dev)
- You're comfortable **self-hosting** or using their managed cloud
- You need **developer-friendly workflows** (approval flows, CLI, SDK)

---

## Alternative 4: Doppler (SaaS)

### Overview
Doppler is a **fully managed, developer-first** secrets platform designed for simplicity. It syncs secrets across all environments (local dev, CI/CD, production) with zero infrastructure overhead.

### Pricing
| Tier | Cost | Features |
|---|---|---|
| **Free** | $0 | Up to 5 users, unlimited secrets, basic features |
| **Team** | ~$6/user/month | Advanced features, audit logs |
| **Enterprise** | Custom | SSO, SLA, advanced compliance |

### Workflow Integration

**Option 1: Using .sh script with Doppler CLI (maintains your pattern):**

```bash
#!/bin/bash
# fetch-secrets.sh - Updated for Doppler CLI

# Doppler CLI exports secrets directly to .env format
doppler secrets download --no-file --format env > .env

echo "Secrets fetched from Doppler and written to .env"
```

```yaml
name: Deploy
on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Install Doppler CLI
        uses: dopplerhq/cli-action@v3
      
      - name: Fetch secrets using .sh script
        run: bash ./fetch-secrets.sh
        env:
          DOPPLER_TOKEN: ${{ secrets.DOPPLER_TOKEN }}
      
      - name: Deploy
        run: ./deploy.sh
```

**Option 2: Direct CLI command (no separate .sh file):**
```yaml
- name: Create .env from Doppler
  run: doppler secrets download --no-file --format env > .env
  env:
    DOPPLER_TOKEN: ${{ secrets.DOPPLER_TOKEN }}
```

**Option 3: Doppler run (injects without .env file):**
```yaml
- name: Run deploy with Doppler
  run: doppler run -- ./deploy.sh
  env:
    DOPPLER_TOKEN: ${{ secrets.DOPPLER_TOKEN }}
```

### Benefits
- **Zero infrastructure** - fully managed SaaS, no servers to maintain
- **Instant setup** - 5 minutes from signup to first secret injected
- **Auto-sync** - changes propagate instantly to all environments
- **100+ integrations** - GitHub, Vercel, AWS, Docker, Kubernetes, etc.
- **Branch-based configs** - separate secrets per Git branch automatically
- **Generous free tier** - up to 5 users unlimited secrets
- **Rollback support** - revert to previous secret versions instantly
- **Secret references** - reuse secrets across projects

### Drawbacks
- **Closed source** - cannot audit or self-host
- **External dependency** - requires internet connectivity
- **Cost scales with users** - $6/user/month after 5 users
- **Vendor lock-in** - proprietary platform

### Cost Comparison
| Scenario | AWS Secrets Manager | Doppler |
|---|---|---|
| 10 secrets, 3 users | $4/month | **$0 (Free tier)** |
| 50 secrets, 5 users | $20/month | **$0 (Free tier)** |
| 100 secrets, 10 users | $40/month | $30/month (5 paid users) |
| 100 secrets, 25 users | $40/month | $120/month (20 paid users) |

### When to Use Doppler
- You want **zero infrastructure management**
- Your team is **≤5 users** (free forever) or budget allows user-based pricing
- You need **instant setup** without DevOps overhead
- You want **branch-based configuration** (dev/staging/prod auto-switching)
- You value **developer experience** over cost optimization

---

## Alternative 5: HashiCorp Vault (Open Source)

### Overview
HashiCorp Vault is the **industry-standard** open-source secrets management platform with advanced features like dynamic secrets, encryption-as-a-service, and extensive plugin ecosystem.

### Pricing
| Edition | Cost | Features |
|---|---|---|
| **Open Source** | **$0** | Core features, self-hosted |
| **Enterprise** | Contact sales | HA, DR, namespaces, FIPS 140-2 |

### Workflow Integration

**Option 1: Using Vault CLI in .sh script (maintains your pattern):**

```bash
#!/bin/bash
# fetch-secrets.sh - Updated for Vault CLI

# Set Vault address and authenticate
export VAULT_ADDR="https://vault.yourcompany.com"
export VAULT_TOKEN="${VAULT_TOKEN}"  # From GitHub secret

# Fetch secrets and write to .env
echo "DB_HOST=$(vault kv get -field=value secret/myapp/production/db-host)" >> .env
echo "DB_PASSWORD=$(vault kv get -field=value secret/myapp/production/db-password)" >> .env
echo "API_KEY=$(vault kv get -field=value secret/myapp/production/api-key)" >> .env

echo "Secrets fetched from Vault and written to .env"
```

```yaml
name: Deploy
on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Install Vault CLI
        run: |
          wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
          echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
          sudo apt update && sudo apt install vault
      
      - name: Fetch secrets using .sh script
        run: bash ./fetch-secrets.sh
        env:
          VAULT_TOKEN: ${{ secrets.VAULT_TOKEN }}
      
      - name: Deploy
        run: ./deploy.sh
```

**Option 2: Using GitHub Action (simpler, no CLI installation):**
```yaml
- name: Import Secrets from Vault
  uses: hashicorp/vault-action@v2
  with:
    url: https://vault.yourcompany.com
    token: ${{ secrets.VAULT_TOKEN }}
    secrets: |
      secret/data/myapp/production DB_PASSWORD | DB_PASSWORD;
      secret/data/myapp/production API_KEY | API_KEY

- name: Create .env
  run: |
    echo "DB_PASSWORD=$DB_PASSWORD" >> .env
    echo "API_KEY=$API_KEY" >> .env
```

### Benefits
- **Free and open source** - unlimited secrets, no licensing costs
- **Dynamic secrets** - generate DB credentials on-demand with auto-expiry
- **Encryption-as-a-service** - encrypt/decrypt data without key management
- **Multi-cloud support** - AWS, Azure, GCP, on-prem
- **Fine-grained RBAC** - advanced policy-based access control
- **Plugin ecosystem** - 100+ integrations and auth backends
- **Mature and battle-tested** - used by Fortune 500 companies
- **Audit logging** - comprehensive access logs

### Drawbacks
- **Complex setup** - requires Vault server deployment and configuration
- **High operational overhead** - need dedicated team to manage HA, backups, upgrades
- **Steep learning curve** - HCL policies, token management, unsealing process
- **Infrastructure costs** - compute/storage for Vault servers (EC2, RDS, etc.)
- **Not cost-effective for small teams** - overhead doesn't justify savings

### Cost Comparison
| Component | AWS Secrets Manager | Vault (Self-Hosted) |
|---|---|---|
| Storage (100 secrets) | $40/month | $0 (license) + infrastructure |
| Infrastructure | $0 | ~$50-200/month (EC2 + storage + load balancer) |
| **Total** | **$40/month** | **$50-200/month** |

- **Vault becomes cost-effective at scale** (~500+ secrets) when advanced features justify infrastructure costs.

### When to Use Vault
- You need **dynamic secrets** (on-demand credential generation)
- You're managing **multi-cloud** infrastructure (AWS + Azure + GCP)
- You have **dedicated DevOps/SRE team** to operate Vault
- You need **advanced features** like encryption-as-a-service
- You're **scaling to enterprise** and want full control
- **Not recommended for small teams** (<10 people) due to operational complexity

---

## Alternative 6: Akeyless (SaaS Platform)

### Overview
Akeyless is a **unified secrets management platform** with a **SaaS-first architecture** (no agents or vault to manage). It offers **zero-knowledge encryption** and dynamic secrets generation with a generous free tier.

### Pricing
| Tier | Cost | Features |
|---|---|---|
| **Community (Free)** | **$0** | Up to 5 clients, unlimited secrets, basic features |
| **Professional** | Starting ~$0.50/client/month | Advanced features, integrations |
| **Enterprise** | Custom pricing | HA, compliance, dedicated support |

### Workflow Integration

**Using Akeyless CLI in .sh script:**

```bash
#!/bin/bash
# fetch-secrets.sh - Using Akeyless CLI

# Login to Akeyless (using access key stored in GitHub secret)
akeyless auth --access-id $AKEYLESS_ACCESS_ID --access-key $AKEYLESS_ACCESS_KEY

# Fetch secrets and write to .env
echo "DB_HOST=$(akeyless get-secret-value -n /myapp/db-host)" >> .env
echo "DB_PASSWORD=$(akeyless get-secret-value -n /myapp/db-password)" >> .env
echo "API_KEY=$(akeyless get-secret-value -n /myapp/api-key)" >> .env

echo "✅ Secrets fetched from Akeyless and written to .env"
```

```yaml
name: Deploy
on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Install Akeyless CLI
        run: |
          curl -o akeyless https://akeyless-cli.s3.us-east-2.amazonaws.com/cli/latest/production/cli-linux-amd64
          chmod +x akeyless
          sudo mv akeyless /usr/local/bin/
      
      - name: Fetch secrets using Akeyless
        run: bash ./fetch-secrets.sh
        env:
          AKEYLESS_ACCESS_ID: ${{ secrets.AKEYLESS_ACCESS_ID }}
          AKEYLESS_ACCESS_KEY: ${{ secrets.AKEYLESS_ACCESS_KEY }}
      
      - name: Deploy
        run: ./deploy.sh
```

### Benefits
- **Generous free tier** - up to 5 clients with unlimited secrets
- **Zero infrastructure** - fully managed SaaS, no vault servers to run
- **Dynamic secrets** - on-demand credential generation with auto-expiry
- **Just-in-time access** - temporary secrets that expire automatically
- **Multi-cloud support** - works with AWS, Azure, GCP, Kubernetes
- **Zero-knowledge architecture** - secrets encrypted with customer-controlled keys
- **Native integrations** - Jenkins, GitHub Actions, Kubernetes, Terraform, etc.
- **Certificate management** - PKI and SSH certificate automation

### Drawbacks
- **SaaS only** - no self-hosting option (security teams may object)
- **Free tier limits** - only 5 clients (scales by client count, not secrets)
- **Closed source** - cannot audit code
- **Smaller community** - less community support compared to Vault/Infisical
- **Learning curve** - different architecture than traditional vaults

### Cost Comparison
| Scenario | AWS Secrets Manager | Akeyless (Free) | Akeyless (Paid) |
|---|---|---|---|
| 10 secrets, 3 clients | $4/month | **$0** | **$0** |
| 50 secrets, 5 clients | $20/month | **$0** | **$0** |
| 100 secrets, 10 clients | $40/month | **$0** (over limit) | ~$5/month (5 paid clients) |
| 100 secrets, 50 clients | $40/month | **$0** (over limit) | ~$25/month |

### When to Use Akeyless
- Your team is **≤5 clients** (free forever)
- You want **dynamic secrets** without managing Vault infrastructure
- You need **zero-knowledge encryption** for compliance
- You want **SaaS simplicity** with enterprise features
- You're **multi-cloud** and don't want vendor lock-in

---

## Cost Comparison Matrix

| Solution | 10 Secrets | 50 Secrets | 100 Secrets | 500 Secrets |
|---|---|---|---|---|
| **AWS Secrets Manager** | $4/mo | $20/mo | $40/mo | $200/mo |
| **SSM Parameter Store** | **$0** | **$0** | **$0** | **$0** |
| **GitHub Secrets** | **$0** | **$0** | **$0** | **$0** |
| **Infisical (Self-Host)** | **$0** | **$0** | **$0** | **$0** |
| **Infisical (Cloud)** | **$0** | **$0** | $40/mo* | $40/mo* |
| **Doppler** | **$0** | **$0** | $30/mo** | $30/mo** |
| **Akeyless (Free)** | **$0** | **$0** | $2.50/mo*** | $22.50/mo*** |
| **Vault (Self-Host)** | $50-200/mo | $50-200/mo | $50-200/mo | $50-200/mo |

*Assumes 5 free users + 5 paid users  
**Assumes 5 free users + 5 paid users ($6/user/month)  

***Assumes 5 free clients, $0.50/client/month for additional clients

---

