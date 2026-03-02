# OpenReplay (Overview & Setup Guide)

---


## 1. What is OpenReplay?

**OpenReplay** is an open-source, self-hostable **session replay and product analytics platform** designed to help engineering, product, and support teams understand exactly how users interact with their web applications. Rather than relying on vague reports or disconnected metrics, OpenReplay lets teams replay real user sessions with network activity, console logs, JavaScript errors, application state, and performance data all in one unified interface.

Unlike traditional analytics tools that only capture *what* happened, OpenReplay provides the *why* by delivering full visual and technical context for every user interaction. It is purpose-built for developers and product teams who need to reproduce issues quickly, improve user experience, and ship better products with confidence.

---

## 2. Core Features

| Feature | Description |
|---|--|
| **Session Replay** | Record and replay complete user sessions, capturing interactions such as clicks, scrolling behavior, form inputs, and navigation paths. |
| **DevTools Integration** | Inspect network requests, console logs, and JavaScript errors directly within a session replay. |
| **Product Analytics** | Trends (time-series), Funnels, Journeys (path analysis), and Heatmaps to understand engagement, drop-offs, and feature usage. |
| **Co-browsing / Assist** | Join a live user session in real time, see exactly what they see, and provide guided support via WebRTC call without any third-party software. |
| **Performance Monitoring** | Capture CPU/memory usage, page speed metrics, web vitals, and failing network requests alongside session replays. |
| **Error Tracking** | Surface JS errors, unhandled promise rejections, and failed requests tied directly to the session in which they occurred. |
| **Heatmaps** | Visualise where users click, move, and scroll across pages to identify UX friction points. |
| **Feature Flags** | Enable or disable features, perform gradual rollouts, and run A/B tests without redeploying the application. |
| **Plugins / State Capture** | Monitor application state via plugins for Redux, Pinia, NgRx, and more. |
| **Privacy Controls** | Fine-grained controls to mask, obscure, or exclude sensitive user data before it ever leaves the browser. |

---

## 3. Architecture & Deployment Options

OpenReplay is designed to be **self-hosted**, meaning all captured data remains within your own infrastructure. This eliminates third-party data processing concerns and simplifies compliance with regulations such as GDPR and CCPA.

### Deployment Targets

- **AWS** (EC2 / EKS)
- **Google Cloud Platform** (GKE / Compute Engine)
- **Microsoft Azure**
- **DigitalOcean**
- **Any Kubernetes cluster** or bare-metal server

### Cloud Option

For teams who prefer a managed experience, OpenReplay also offers a **cloud-hosted SaaS** option at [app.openreplay.com](https://app.openreplay.com), which includes a free tier and requires no infrastructure management.

---

## 4. Self-Hosted Setup with Docker Compose

OpenReplay can be deployed on your own server using **Docker Compose**. This is the recommended approach for teams who want complete data ownership, GDPR/CCPA compliance, or simply do not want their session data leaving their own infrastructure.

> **Important:** OpenReplay **cannot run purely on a local machine** (i.e., `localhost`). It requires a publicly reachable server with a domain name and a valid SSL certificate. For local development purposes only, Docker Compose can be used on a VM or cloud instance.

---

### Step 1 – Provision a Server

Spin up a fresh cloud server (VM) with the following **minimum specifications**:

| Requirement | Minimum Value |
|---|---|
| **OS** | Ubuntu 20.04 LTS (64-bit / x86) |
| **CPU** | 2 vCPUs |
| **RAM** | 8 GB |
| **Storage** | 50 GB SSD |
| **Network** | Public IP address |
| **Architecture** | x86 (ARM is not supported) |

Recommended cloud instances that meet these specs:

- **AWS:** `t3.large`
- **GCP:** `e2-standard-2`
- **DigitalOcean:** `General Purpose – 8 GB`
- **Azure:** `Standard_B2ms`

> For moderate-to-high traffic volumes, scale up the instance accordingly.

---

### Step 2 – Point a Domain to Your Server

OpenReplay requires a **Fully Qualified Domain Name (FQDN)** with SSL — it will not work over a raw IP address.

1. Purchase or use an existing domain (e.g., `openreplay.yourcompany.com`).
2. Create an **A record** in your DNS provider pointing the subdomain to your server's public IP address.
3. Wait for DNS propagation (typically 5–30 minutes).

Example DNS record:

```
Type:  A
Name:  openreplay
Value: <YOUR_SERVER_PUBLIC_IP>
TTL:   300
```

> The Docker Compose installer will automatically provision an SSL certificate via **Let's Encrypt**, so no manual certificate setup is required.

---

### Step 3 – SSH into Your Server

From your local terminal, connect to the server using your SSH key:

```bash
SSH_KEY=~/Downloads/openreplay-key.pem    # Path to your SSH private key
INSTANCE_IP=REPLACE_WITH_INSTANCE_PUBLIC_IP

chmod 400 $SSH_KEY
ssh -i $SSH_KEY ubuntu@$INSTANCE_IP
```

If your cloud provider uses a different default user (e.g., `ec2-user` on Amazon Linux), adjust accordingly.

---

### Step 4 – Run the Docker Compose Installer

Once logged in to your server, run the official OpenReplay Docker Compose installation script. The installer will prompt you for your domain name and automatically configure Docker, all required services, SSL, and Nginx.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/openreplay/openreplay/main/scripts/docker-compose/docker-install.sh)"
```

When prompted, enter your domain (e.g., `openreplay.yourcompany.com`).

The script will handle:

- Installing Docker and Docker Compose on the server
- Pulling all required OpenReplay service images
- Generating and applying an SSL certificate via Let's Encrypt
- Configuring Nginx as a reverse proxy
- Starting all OpenReplay containers in the background

> This process may take **5–10 minutes** depending on your server's internet speed.

---

### Step 5 – Create Your Account

Once the installation completes, navigate to your domain in a browser and register an admin account:

```
https://openreplay.yourcompany.com/signup
```

Fill in your name, email address, and a strong password. This becomes the primary administrator account for your OpenReplay instance.

---

### Step 6 – Retrieve Your Project Key

After signing in, create a project and get your unique **Project Key** — this is required to connect your web application to your self-hosted instance.

1. Go to `Preferences → Projects` in the OpenReplay dashboard.
2. Click **New Project** (or select an existing one).
3. Copy the **Project Key** displayed.
4. Note your **Ingest Endpoint**: `https://openreplay.yourcompany.com/ingest` — you will need this when configuring the tracker.

---

## 5. Integrating the Tracker into Your App

With your self-hosted OpenReplay instance running, the next step is to embed the tracker into your web application. There are three integration methods — choose the one that fits your stack.

> **Self-hosted users:** Always set the `ingestPoint` option to your own domain's ingest URL (see examples below). Without this, data will be routed to OpenReplay's cloud instead of your server.

---

### Option A – JavaScript Snippet

This is the quickest method and is suitable for any website or web application without a build step. Copy the tracking script from your OpenReplay dashboard (`Preferences → Projects`) and paste it inside the `<head>` tag of your HTML.

```html
<!-- OpenReplay Tracking Code -->
<script>
  var initOpts = {
    projectKey: "YOUR_PROJECT_KEY",
    ingestPoint: "https://openreplay.yourcompany.com/ingest" // Self-hosted endpoint
  };
  var startOpts = { userID: "" };
  (function(A,s,a,y,e,r){
    r=window.OpenReplay=[e,r,y,[s-1, e]];
    s=document.createElement('script');
    s.src=A;
    s.async=!a;
    document.getElementsByTagName('head')[0].appendChild(s);
    r.l=1*new Date();
    r.uni=typeof k==='undefined';
    var t=0,R=window.setInterval(function(){
      if(r.handlers&&!t){
        t=1;
        window.OpenReplay.push([0]);
        clearInterval(R);
      }
    },1);
  })("//static.openreplay.com/latest/openreplay.js", 1, 0, initOpts, startOpts);
</script>
```

> **Note:** Replace `openreplay.yourcompany.com` with the actual domain of your self-hosted instance. If using OpenReplay Cloud, omit the `ingestPoint` field entirely.

---

### Option B – NPM Package (SPA)

This is the recommended method for Single Page Applications (SPAs) built with frameworks such as React, Vue, or Angular.

**Step 1 – Install the tracker package**

```bash
npm install @openreplay/tracker
```

**Step 2 – Initialise the tracker**

Import and configure OpenReplay from your application's entry point (e.g., `index.js`, `main.ts`, or `App.jsx`).

```javascript
import OpenReplay from '@openreplay/tracker';

const tracker = new OpenReplay({
  projectKey: 'YOUR_PROJECT_KEY',
  ingestPoint: 'https://openreplay.yourcompany.com/ingest', // Self-hosted endpoint
});

tracker.start({
  userID: 'user@example.com',       // optional: associate sessions with a user
  metadata: {
    plan: 'premium',                // optional: attach custom metadata
    version: '2.4.1',
  },
}).then(({ sessionID, success }) => {
  if (success) {
    console.log('OpenReplay session started:', sessionID);
  }
});
```

> **Self-hosted:** Set `ingestPoint` to your own domain's ingest URL. **Cloud users:** This option can be omitted entirely.

---

### Option C – Server-Side Rendered Apps (SSR)

For applications using **Next.js**, **Nuxt.js**, or any other SSR framework, the tracker must be initialised only in the browser environment. Use a lifecycle hook such as `useEffect` (React) or `onMounted` (Vue) to ensure the tracker does not execute on the server.

**Next.js / React Example**

```javascript
import OpenReplay from '@openreplay/tracker/cjs';
import { useEffect } from 'react';

const tracker = new OpenReplay({
  projectKey: 'YOUR_PROJECT_KEY',
});

function MyApp({ Component, pageProps }) {
  useEffect(() => {
    tracker.start();
  }, []);

  return <Component {...pageProps} />;
}

export default MyApp;
```

**Nuxt.js / Vue Example**

```javascript
import OpenReplay from '@openreplay/tracker/cjs';

const tracker = new OpenReplay({
  projectKey: 'YOUR_PROJECT_KEY',
});

export default {
  mounted() {
    tracker.start();
  },
};
```

---

## 6. Advanced Tracker Configuration

The `OpenReplay` constructor accepts a configuration object to fine-tune tracker behaviour. Below are the most commonly used options.

```javascript
const tracker = new OpenReplay({
  projectKey: 'YOUR_PROJECT_KEY',

  // For self-hosted deployments, point to your own ingest endpoint
  ingestPoint: 'https://openreplay.yourdomain.com/ingest',

  // Privacy options
  obscureTextEmails: true,        // Mask emails in text elements (default: true)
  obscureTextNumbers: false,      // Mask numbers in text elements (default: false)
  obscureInputEmails: true,       // Mask emails in input fields (default: true)
  obscureInputNumbers: true,      // Mask numbers in input fields (default: true)
  obscureInputDates: false,       // Mask dates in input fields (default: false)

  // Behaviour
  respectDoNotTrack: false,       // Honour browser Do Not Track flag (default: false)
  __DISABLE_SECURE_MODE: false,   // Allow tracking on HTTP (dev only, default: false)
});
```

> **Self-Hosted Note:** Always set `ingestPoint` to your own domain when running a self-hosted instance. Without this, data will be sent to OpenReplay's cloud infrastructure.

---

## 7. Plugins & Integrations

OpenReplay supports a rich plugin ecosystem to extend tracking capabilities. Each plugin is installed separately and loaded via `tracker.use()`.

### Redux State Tracking

```bash
npm install @openreplay/tracker-redux
```

```javascript
import trackerRedux from '@openreplay/tracker-redux';

const openReplayMiddleware = tracker.use(trackerRedux());
const store = createStore(reducer, applyMiddleware(openReplayMiddleware));
```

### Live Co-browsing / Assist (WebRTC)

```bash
npm install @openreplay/tracker-assist
```

```javascript
import trackerAssist from '@openreplay/tracker-assist';

tracker.use(trackerAssist());
tracker.start();
```

### GraphQL Query Tracking

```bash
npm install @openreplay/tracker-graphql
```

```javascript
import { createGraphqlMiddleware } from '@openreplay/tracker-graphql';

const recordGraphQL = tracker.use(createGraphqlMiddleware());
```

### Additional Supported Plugins

- `@openreplay/tracker-pinia` — Vue/Pinia state management
- `@openreplay/tracker-ngrx` — Angular/NgRx state management
- `@openreplay/tracker-fetch` — Fetch API request monitoring
- `@openreplay/tracker-axios` — Axios request monitoring

---

## 8. Privacy & Data Controls

OpenReplay is designed with privacy-first principles. Because it is self-hosted, **no user data ever leaves your own infrastructure**.

Additional privacy controls include:

- **Input masking** — Sensitive form fields (passwords, credit cards) are masked by default.
- **Element exclusion** — Specific DOM elements can be excluded from recording using the `data-openreplay-obscured` or `data-openreplay-hidden` HTML attributes.
- **Conditional recording** — (Enterprise) Capture only sessions that meet defined conditions (e.g., only record errors, only record specific user segments).
- **GDPR / CCPA compliance** — All data remains on your servers, with configurable retention periods.
- **Do Not Track** — Optionally honour the browser's Do Not Track signal via the `respectDoNotTrack` configuration option.

---

## 9. Troubleshooting

### Tracker Not Recording

1. **Verify the project key** — Ensure it matches exactly what's in `Preferences → Projects`.
2. **Check the ingest endpoint** — For self-hosted, confirm `ingestPoint` points to your domain (e.g., `https://openreplay.yourcompany.com/ingest`).
3. **Open browser DevTools → Console** — Look for errors or warnings from OpenReplay.
4. **Check Network tab** — Verify requests are going to your ingest endpoint (not `openreplay.com`).

### SSL / HTTPS Issues

- Ensure your domain's **A record** points to the correct server IP.
- Wait at least **30 minutes** for DNS propagation.
- Check that port **443** is open in your server's firewall.

### Cannot Access the Dashboard

- Verify the server is running: `docker ps`
- Check logs: `docker logs openreplay-nginx`
- Ensure your domain resolves correctly: `nslookup openreplay.yourcompany.com`

### Sessions Not Appearing

- Clear browser cache and reload.
- Ensure you're not blocking the tracker in browser extensions (uBlock, Privacy Badger, etc.).
- Verify `respectDoNotTrack` is not set to `true` if DNT is enabled in your browser.

---


