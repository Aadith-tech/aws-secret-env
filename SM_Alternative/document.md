# AWS Secrets Manager Alternatives

> A comprehensive guide to cheaper and open-source alternatives for secrets management

---

## What is AWS Secrets Manager?

AWS Secrets Manager is a scalable secrets management service priced on a **per-secret, per-API-call** model (~$0.40/secret/month + $0.05 per 10,000 API calls). While it excels within the AWS ecosystem, it has notable limitations:

- **Vendor lock-in** — integrations are largely limited to other AWS services
- **Cost at scale** — expenses grow significantly with a large number of secrets or API calls
- **No self-hosting** — you cannot run it on your own infrastructure
- **Limited secret scanning and rotation** — only supports custom rotation workflows
- **Enterprise support costs extra** — quality support requires an expensive premium plan

---

## Alternatives to Secrets Manager
| Tool | Type | Cost | Open Source | Best For |
|---|---|---|---|---|
| HashiCorp Vault | OSS / Enterprise | Free | Yes | Complex, multi-cloud setups |
| Infisical | OSS / Cloud SaaS | Free tier + paid | Yes | Developer-first teams |
| Doppler | SaaS | Free tier + paid | No | Simplicity & integrations |
| Azure Key Vault | Cloud SaaS | Pay-per-use | No | Azure-native teams |
| CyberArk Conjur | OSS / Enterprise | Free | Yes | Enterprise & compliance |
| GCP Secret Manager | Cloud SaaS | Pay-per-use | No | GCP-native teams |


---

## 1. HashiCorp Vault

**Type:** Open Source / Enterprise
**Cost:** Free (Community Edition), Vault Enterprise requires sales quote

HashiCorp Vault is the most widely adopted open-source secrets management solution. It provides a unified interface for managing secrets, with tight access control and a detailed audit log. It integrates deeply with virtually every major infrastructure tool.

### Key Features
- Dynamic secrets — generates credentials on-demand for databases, cloud providers, and more
- Secret leasing and renewal with automatic revocation
- Encryption as a service (transit secrets engine)
- Fine-grained RBAC with many auth backends (LDAP, GitHub, Kubernetes, AWS IAM, etc.)
- High-availability (HA) setup for both self-hosted and cloud-managed
- Strong community with 29,000+ GitHub stars

### When to Choose Vault
Best for organizations with complex, multi-cloud or hybrid infrastructure that need advanced secret lifecycle management and are comfortable with self-hosting and operational overhead.


---

## 2. Infisical

**Type:** Open Source / Cloud SaaS
**Cost:** Free tier (unlimited secrets for small teams), paid plans from ~$8/user/month


Infisical is a modern, end-to-end encrypted secrets management platform. It covers the full secret lifecycle — from versioned storage to rotation, scanning, sharing, and infrastructure integrations.

### Key Features
- End-to-end encrypted secret storage with version control
- Secret rotation for databases and third-party services
- Secret scanning — detects and prevents leaks to Git (150+ secret types)
- Certificate lifecycle management (Private CA + X.509 certificates)
- Developer-friendly UI with approval workflows and access requests
- SDKs for Node.js, Python, Go, Java, and more
- Native integrations with GitHub Actions, GitLab CI, Kubernetes, Docker, Vercel, Heroku, and more

### When to Choose Infisical
Best for developer-centric teams that want a managed cloud experience or the ability to self-host, with richer features than AWS Secrets Manager out of the box.

---

## 3. Doppler

**Type:** SaaS (Closed Source)
**Cost:** Free tier available; Team plan at ~$6/user/month

Doppler is a developer-first secrets management platform focused on simplicity and speed of adoption. It does not require self-hosting, making it easy to set up in minutes.

### Key Features
- Centralized secrets synced automatically across environments (dev, staging, prod)
- CLI-first workflow with intuitive dashboard
- Native integrations with Vercel, Netlify, GitHub Actions, AWS, Kubernetes, and 100+ more
- Secrets immutability and audit logging
- Role-based access control

### When to Choose Doppler
Best for teams that want a simple, fully managed tool without operational overhead, and don't need to self-host due to compliance requirements.


---

## 4. Azure Key Vault

**Type:** Cloud SaaS (Microsoft)
**Cost:** ~$0.03/10,000 operations for Standard tier (generally cheaper than AWS Secrets Manager for high-volume workloads)

Azure Key Vault is Microsoft's native secrets management service, comparable in scope to AWS Secrets Manager but tailored for the Azure ecosystem.

### Key Features
- Stores secrets, certificates, and cryptographic keys
- Native integration with Azure Active Directory for access control
- Hardware Security Module (HSM) backed storage (Premium tier)
- Audit logging via Azure Monitor

### When to Choose Azure Key Vault
Best for organizations already invested in the Microsoft Azure ecosystem who want a lower-friction, native option.


---

## 5. CyberArk Conjur

**Type:** Open Source / Enterprise
**Cost:** Free (OSS Community Edition), Enterprise pricing on request

CyberArk Conjur is an enterprise-grade secrets manager originally from CyberArk, purpose-built for machine identity and DevOps workflows.

### Key Features
- Strong RBAC policies with fine-grained secret scoping
- Native Kubernetes integration (via Secrets Provider)
- REST API and SDKs for major languages
- Extensive audit logging and compliance reporting
- Integrates with Ansible, Jenkins, GitHub Actions, Azure DevOps, and more

### When to Choose CyberArk Conjur
Best for enterprises with strict compliance requirements (PCI DSS, HIPAA, SOC 2) that need a self-hostable, auditable, enterprise-hardened solution.


---

## 6. GCP Secret Manager

**Type:** Cloud SaaS (Google)
**Cost:** ~$0.06/active secret version/month + $0.03/10,000 access operations (generally cheaper than AWS)

Google Cloud Secret Manager is GCP's native equivalent to AWS Secrets Manager, with competitive pricing for high-volume workloads.

### Key Features
- Automatic replication and versioning
- IAM-based access control
- Audit logging via Cloud Audit Logs
- Integration with GCP services (Cloud Functions, Compute Engine, GKE, etc.)

### When to Choose GCP Secret Manager
Best for teams already using Google Cloud Platform who want a native, lower-cost alternative to AWS Secrets Manager.

---

