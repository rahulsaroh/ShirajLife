# Cloudflare Architecture & Deployment Guide

## 1. Cloudflare Project Overview
- **Pages Project Name**: `shirajlife`
- **Default Production URL**: [https://shirajlife.pages.dev](https://shirajlife.pages.dev)
- **Account ID**: `5a23c2da5e843a41089292b7d78f4545`
- **DNS Zone ID**: `363c865bf7ab3e624db8433e7118ec3c` (`shirajlife.com`)

---

## 2. Active Domains & Routing
- **Main Domain**: `https://shirajlife.com` $\rightarrow$ Points to Cloudflare Pages (`shirajlife.pages.dev`).
- **Ritu Designer Subdomain**: `https://ritudesigner.shirajlife.com` $\rightarrow$ Handled by `_worker.js`, serving `ritu-designer.html` while keeping the clean subdomain URL.
- **Legacy Path Redirect**: `https://shirajlife.com/ritu-designer` $\rightarrow$ 301 Permanent Redirect to `https://ritudesigner.shirajlife.com/`.

---

## 3. Secret Credentials Location
All sensitive keys and tokens are securely stored in the local [`.env`](file:///f:/My%20Drive/Apps/Website/.env) file:
- `CLOUDFLARE_ACCOUNT_ID`: Account identifier
- `CLOUDFLARE_API_TOKEN`: Cloudflare Account API Token
- `R2_ACCESS_KEY_ID`: Cloudflare R2 S3 Object Storage Key ID
- `R2_SECRET_ACCESS_KEY`: Cloudflare R2 S3 Secret Access Key
- `R2_ENDPOINT`: `https://5a23c2da5e843a41089292b7d78f4545.r2.cloudflarestorage.com`

> **Note**: `.env` is listed in `.gitignore` to guarantee your credentials are never pushed to public GitHub repositories.

---

## 4. Key Configuration Files in This Folder
- **[`.env`](file:///f:/My%20Drive/Apps/Website/.env)**: Holds your live tokens and secret keys.
- **[`.env.example`](file:///f:/My%20Drive/Apps/Website/.env.example)**: Example environment file template for setup on other machines.
- **[`_worker.js`](file:///f:/My%20Drive/Apps/Website/_worker.js)**: Edge router handling domain rewriting for `ritudesigner.shirajlife.com`.
- **[`wrangler.toml`](file:///f:/My%20Drive/Apps/Website/wrangler.toml)**: Cloudflare Pages build and compatibility settings.
- **[`cf-tools.ps1`](file:///f:/My%20Drive/Apps/Website/cf-tools.ps1)**: PowerShell management script to verify tokens, list zones, and deploy.
- **[`r2_manager.py`](file:///f:/My%20Drive/Apps/Website/r2_manager.py)**: Python utility for interacting with Cloudflare R2 object storage.

---

## 5. How to Deploy Updates in the Future
Whenever you make changes to HTML/CSS/JS and want to push to live Cloudflare Pages:

```powershell
# 1. Sync updated files into dist/
Copy-Item *.html, *.css, *.js, *.png, *.jpg, *.svg, *.webmanifest .\dist\ -Force
Copy-Item .\_worker.js .\dist\_worker.js -Force

# 2. Deploy directly to Cloudflare Pages
npx wrangler pages deploy dist --project-name shirajlife --branch main --commit-dirty=true
```
Or run:
```powershell
.\cf-tools.ps1 deploy
```
