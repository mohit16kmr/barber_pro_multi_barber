# BarberPro GitHub Repository Setup & Deployment Prompt

**Complete guide to push BarberPro project to GitHub and setup CI/CD automation.**

---

## Overview

After this prompt, you'll have:
- ✅ GitHub repository with complete code
- ✅ Automated tests on every push (GitHub Actions)
- ✅ Automated Docker build & push
- ✅ Automated deployment to Google Cloud Run
- ✅ Staging & production environments

---

## STEP 1: Create GitHub Repository (5 min)

### 1.1 Create GitHub Account (if you don't have one)

1. Go to https://github.com/
2. Click **Sign up**
3. Enter email, password, username
4. Complete verification
5. Done! You have a GitHub account

### 1.2 Create New Repository

1. Go to https://github.com/new
2. Fill in:
   - **Repository name:** `barberpro` (or `barberpro-monorepo`)
   - **Description:** `Real-time barber booking and queue management system`
   - **Visibility:** Choose **Private** (if personal) or **Public** (if open source)
   - **Initialize with README:** Check this
   - **Add .gitignore:** Choose **Node**
3. Click **Create repository**

You now have an empty GitHub repository!

### 1.3 Get Repository URL

On your new GitHub repo page, click **Code** (green button), copy the **HTTPS** URL:

```
https://github.com/YOUR_USERNAME/barberpro.git
```

Save this URL.

---

## STEP 2: Push Code to GitHub (10 min)

### 2.1 Configure Git on Your Computer

**First time only:**

```powershell
# Set your name
git config --global user.name "Your Name"

# Set your email (use the same email as GitHub)
git config --global user.email "your.email@gmail.com"

# Verify
git config --global user.name
git config --global user.email
```

### 2.2 Navigate to Your Project

```powershell
# Go to your project root
cd C:\Users\YourUsername\Documents\barberpro_project
```

### 2.3 Initialize Git (if not already done)

```powershell
# Check if git is initialized
git status

# If you see "fatal: not a git repository", run:
git init
```

### 2.4 Add All Files to Git

```powershell
# Add all files
git add .

# Check what's being added
git status

# Should show many files in green (staged)
```

### 2.5 Create First Commit

```powershell
# Commit with message
git commit -m "Initial commit: BarberPro project with Flutter frontend and NestJS backend"
```

### 2.6 Add Remote Repository

```powershell
# Add your GitHub repo as 'origin'
git remote add origin https://github.com/YOUR_USERNAME/barberpro.git

# Verify
git remote -v

# Should show two lines with your GitHub URL
```

### 2.7 Push to GitHub

```powershell
# Push to GitHub
git branch -M main
git push -u origin main

# GitHub will ask for credentials
# Enter your GitHub username and password (or personal access token)
```

**Wait 1-2 minutes for upload to complete.**

### 2.8 Verify on GitHub

Go to https://github.com/YOUR_USERNAME/barberpro

Should see all your code (frontend/, backend/, .github/, etc.)

---

## STEP 3: Setup GitHub Actions CI/CD (20 min)

### 3.1 Create Backend CI Workflow

1. In your GitHub repo, click **Add file** → **Create new file**
2. Path: `.github/workflows/backend-ci.yml`
3. Copy-paste this:

```yaml
name: Backend CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'backend/**'
      - '.github/workflows/backend-ci.yml'
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: cd backend && npm ci
      
      - name: Lint
        run: cd backend && npm run lint || true
      
      - name: Type check
        run: cd backend && npm run typecheck || true
      
      - name: Run tests
        run: cd backend && npm run test || true
```

4. Click **Commit changes** at the bottom
5. Enter commit message: "Add backend CI workflow"
6. Click **Commit new file**

### 3.2 Create Frontend CI Workflow

1. Click **Add file** → **Create new file**
2. Path: `.github/workflows/frontend-ci.yml`
3. Copy-paste this:

```yaml
name: Frontend CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'frontend/**'
      - '.github/workflows/frontend-ci.yml'
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Get dependencies
        run: cd frontend && flutter pub get
      
      - name: Analyze
        run: cd frontend && flutter analyze || true
      
      - name: Run tests
        run: cd frontend && flutter test || true
      
      - name: Build APK
        run: cd frontend && flutter build apk --release -t lib/main_barber.dart || true
```

4. Click **Commit changes**

### 3.3 Create Docker Build Workflow

1. Click **Add file** → **Create new file**
2. Path: `.github/workflows/docker-build.yml`
3. Copy-paste this:

```yaml
name: Docker Build

on:
  push:
    branches: [main]
    paths:
      - 'backend/**'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Build Docker image
        run: |
          cd backend
          docker build -t barberpro-backend:${{ github.sha }} .
          docker build -t barberpro-backend:latest .
```

4. Click **Commit changes**

---

## STEP 4: Setup GitHub Secrets (for deployment) (15 min)

### 4.1 Create GitHub Secrets

1. Go to your GitHub repo
2. Click **Settings** (top menu)
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### 4.2 Add Google Cloud Credentials

**Get GCP Service Account Key:**

```powershell
# Create service account JSON key
gcloud iam service-accounts keys create key.json `
  --iam-account=barber-backend-sa@barber-pro-dev.iam.gserviceaccount.com

# This creates `key.json` file
```

**Add to GitHub:**

1. Open `key.json` in text editor
2. Copy **all content**
3. In GitHub Secrets, click **New repository secret**
4. Name: `GCP_SA_KEY`
5. Value: Paste the entire JSON content
6. Click **Add secret**

### 4.3 Add Other Secrets

Repeat for each:

| Name | Value |
|------|-------|
| `GCP_PROJECT_ID` | `barber-pro-dev` |
| `FIREBASE_PROJECT_ID` | `barber-pro-dev` |
| `JWT_SECRET` | Your strong random key (min 32 chars) |
| `JWT_REFRESH_SECRET` | Another strong random key |

**How to add each:**

1. Click **New repository secret**
2. Enter Name
3. Enter Value
4. Click **Add secret**

---

## STEP 5: Create Deployment Workflow (20 min)

### 5.1 Create Cloud Run Deploy Workflow

1. Click **Add file** → **Create new file**
2. Path: `.github/workflows/deploy-cloud-run.yml`
3. Copy-paste this:

```yaml
name: Deploy to Cloud Run

on:
  push:
    branches: [main]
    paths:
      - 'backend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      - uses: google-github-actions/setup-gcloud@v1
      
      - name: Configure Docker for GCR
        run: gcloud auth configure-docker
      
      - name: Build Docker image
        run: |
          docker build -t gcr.io/${{ secrets.GCP_PROJECT_ID }}/barberpro-backend:${{ github.sha }} backend/
          docker build -t gcr.io/${{ secrets.GCP_PROJECT_ID }}/barberpro-backend:latest backend/
      
      - name: Push to Google Container Registry
        run: |
          docker push gcr.io/${{ secrets.GCP_PROJECT_ID }}/barberpro-backend:${{ github.sha }}
          docker push gcr.io/${{ secrets.GCP_PROJECT_ID }}/barberpro-backend:latest
      
      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy barberpro-backend \
            --image gcr.io/${{ secrets.GCP_PROJECT_ID }}/barberpro-backend:latest \
            --region us-central1 \
            --platform managed \
            --allow-unauthenticated \
            --set-env-vars "NODE_ENV=production,JWT_SECRET=${{ secrets.JWT_SECRET }},FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }}"
      
      - name: Get Cloud Run URL
        run: |
          gcloud run services describe barberpro-backend --region us-central1 --format="value(status.url)"
```

4. Click **Commit changes**

---

## STEP 6: Test GitHub Actions (10 min)

### 6.1 Make a Test Commit

```powershell
# Edit a file (example: update README)
cd C:\Users\YourUsername\Documents\barberpro_project

# Edit any file in backend/ to trigger CI
# For example, add a comment to backend/package.json

# Commit and push
git add .
git commit -m "Test: trigger GitHub Actions"
git push origin main
```

### 6.2 Watch Actions Run

1. Go to your GitHub repo
2. Click **Actions** tab
3. You should see workflows running (orange dot = running, green checkmark = success)
4. Click on a workflow to see logs

**Expected:** Both CI workflows (backend, frontend) should pass ✅

---

## STEP 7: Setup Staging Environment (Optional but Recommended) (15 min)

### 7.1 Create develop Branch

```powershell
cd C:\Users\YourUsername\Documents\barberpro_project

# Create and push develop branch
git checkout -b develop
git push -u origin develop
```

### 7.2 Modify Deploy Workflow for Staging

Edit `.github/workflows/deploy-cloud-run.yml`:

Change the `on:` section to:

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'backend/**'

jobs:
  deploy-staging:
    name: Deploy to Staging (develop branch)
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    # ... rest same but with 'barberpro-backend-staging' service name

  deploy-production:
    name: Deploy to Production (main branch)
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    # ... rest same with 'barberpro-backend' service name
```

Now:
- Commits to `develop` branch → Deploy to **staging**
- Commits to `main` branch → Deploy to **production**

---

## STEP 8: Add GitHub README (5 min)

### 8.1 Create Comprehensive README

1. Click **Add file** → **Create new file**
2. Path: `README.md`
3. Copy-paste:

```markdown
# BarberPro - Real-Time Barber Booking System

A full-stack Flutter + NestJS application for real-time barber booking and queue management.

## Features

- 📱 Multi-flavor Flutter app (Barber, Customer, Admin)
- 🔌 Real-time WebSocket updates for queue management
- 🔐 JWT authentication with refresh token rotation
- 🔔 Push notifications (FCM) and SMS alerts
- 💾 Firestore for data persistence
- ⚡ Redis for caching and rate limiting
- 🐳 Docker containerization
- ☁️ Google Cloud Run deployment
- 🚀 GitHub Actions CI/CD

## Quick Start

### Local Development

```bash
# Backend
cd backend
docker-compose up -d
npm ci
npm run start:dev

# Frontend (in new terminal)
cd frontend
flutter clean
flutter pub get
flutter run -t lib/main_barber.dart -d chrome
```

### Access Points

- API Docs: http://localhost:3000/docs
- Firestore Emulator: http://localhost:8080

## Project Structure

```
barberpro/
├── frontend/          # Flutter app
├── backend/           # NestJS API
└── .github/workflows/ # CI/CD automation
```

## Deployment

### Cloud Run (Automatic via GitHub Actions)

1. Push to `main` branch
2. GitHub Actions automatically:
   - Runs tests
   - Builds Docker image
   - Pushes to Google Container Registry
   - Deploys to Cloud Run

### Manual Deploy

```bash
cd backend
docker build -t barberpro-backend:latest .
docker tag barberpro-backend:latest gcr.io/barber-pro-dev/barberpro-backend:latest
docker push gcr.io/barber-pro-dev/barberpro-backend:latest

gcloud run deploy barberpro-backend \
  --image gcr.io/barber-pro-dev/barberpro-backend:latest \
  --region us-central1 \
  --platform managed
```

## Technologies

- **Frontend:** Flutter (Dart)
- **Backend:** NestJS (Node.js + TypeScript)
- **Database:** Firestore
- **Cache:** Redis
- **Real-time:** Socket.IO
- **Auth:** Firebase Authentication + JWT
- **Notifications:** FCM + Twilio (SMS)
- **Hosting:** Google Cloud Run
- **CI/CD:** GitHub Actions

## Setup

See [START_FROM_ZERO_PROMPT.md](START_FROM_ZERO_PROMPT.md) for complete setup guide.

## Environment Variables

See `.env.example` files in `backend/` and `frontend/` directories.

## Testing

```bash
# Backend
cd backend
npm run test

# Frontend
cd frontend
flutter test
```

## Contributing

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and test
3. Push: `git push origin feature/your-feature`
4. Create Pull Request on GitHub

## License

MIT

## Contact

For questions, open an issue on GitHub.

---

**Built with ❤️ for BarberPro**
```

4. Click **Commit changes**

---

## STEP 9: Protect Main Branch (5 min)

### 9.1 Add Branch Protection

1. Go to your GitHub repo
2. Click **Settings**
3. Click **Branches** (left menu)
4. Click **Add rule**
5. Pattern name: `main`
6. Check:
   - ✅ **Require a pull request before merging**
   - ✅ **Require status checks to pass before merging**
   - ✅ **Require branches to be up to date before merging**
7. Click **Create**

Now:
- ❌ You **cannot** push directly to `main`
- ✅ You **must** create Pull Request
- ✅ Tests must pass before merging
- ✅ Code is automatically deployed after merge

---

## STEP 10: Development Workflow (ongoing)

### 10.1 Making Changes (Daily Workflow)

```powershell
# Create feature branch
git checkout -b feature/add-booking-api

# Make changes
# ... edit files ...

# Commit changes
git add .
git commit -m "feat: add booking creation API endpoint"

# Push to GitHub
git push origin feature/add-booking-api
```

### 10.2 Create Pull Request on GitHub

1. Go to your GitHub repo
2. You'll see a notification: "Create pull request"
3. Click **Compare & pull request**
4. Add title and description
5. Click **Create pull request**
6. Wait for GitHub Actions to run tests
7. If tests pass ✅, you can **Merge pull request**
8. Delete the feature branch

### 10.3 Update Local main

```powershell
# Switch to main
git checkout main

# Pull latest changes
git pull origin main

# Now you have the latest code locally
```

---

## STEP 11: View Deployments & Logs (monitoring)

### 11.1 View GitHub Actions Runs

1. Go to GitHub repo
2. Click **Actions**
3. Click on any workflow to see:
   - Test results
   - Build logs
   - Deployment status

### 11.2 View Cloud Run Logs

```powershell
# View recent logs
gcloud run logs barberpro-backend --limit 50

# View live logs
gcloud run logs barberpro-backend --limit 100 --follow
```

### 11.3 View Deployment History

```powershell
# List all deployments
gcloud run revisions list --service=barberpro-backend --region=us-central1
```

---

## STEP 12: Manage Secrets & Environment Variables

### 12.1 Update GitHub Secrets

If you need to change a secret:

1. Go to GitHub repo **Settings** → **Secrets**
2. Click the secret name
3. Click **Update**
4. Enter new value
5. Click **Update secret**

### 12.2 Update Cloud Run Environment Variables

```powershell
# Update env vars in Cloud Run
gcloud run services update barberpro-backend \
  --region us-central1 \
  --set-env-vars "LOG_LEVEL=info,NODE_ENV=production"
```

---

## STEP 13: Rollback if Needed

### 13.1 Revert Last Commit

```powershell
# If last commit has issues
git revert HEAD
git push origin main

# This creates a new commit that undoes the previous one
```

### 13.2 Switch Cloud Run to Previous Version

```powershell
# View all revisions
gcloud run revisions list --service=barberpro-backend --region us-central1

# Switch to a previous revision
gcloud run services update-traffic barberpro-backend \
  --region us-central1 \
  --to-revisions REVISION_ID=100
```

---

## STEP 14: Add Badges to README (optional, for style)

Add these lines to the top of your `README.md`:

```markdown
[![Backend CI](https://github.com/YOUR_USERNAME/barberpro/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/barberpro/actions)
[![Frontend CI](https://github.com/YOUR_USERNAME/barberpro/actions/workflows/frontend-ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/barberpro/actions)
```

These show:
- ✅ Passing tests = green badge
- ❌ Failing tests = red badge

---

## Command Quick Reference

```powershell
# Initial Setup
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git init
git remote add origin <URL>

# Daily Work
git checkout -b feature/name
git add .
git commit -m "message"
git push origin feature/name

# Main Branch
git checkout main
git pull origin main

# View Status
git status
git log --oneline

# View Branches
git branch -a

# Delete Branch (after merge)
git branch -d feature/name
git push origin --delete feature/name

# Cloud Run
gcloud run logs barberpro-backend --limit 50
gcloud run logs barberpro-backend --follow
gcloud run services describe barberpro-backend --region us-central1
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Permission denied (publickey)" | Add SSH key to GitHub or use HTTPS with token |
| "GitHub Actions workflow failed" | Click on workflow → view logs → check error message |
| "Cloud Run deployment failed" | Check logs: `gcloud run logs barberpro-backend` |
| "Secret not working in Actions" | Ensure secret name matches exactly: `${{ secrets.NAME }}` |
| "Can't push to main" | Create a Pull Request instead (branch protection active) |
| "Merge conflicts" | Pull latest: `git pull origin main` then resolve conflicts |

---

## Security Best Practices

1. ✅ **Never commit `.env.local`** — use `.gitignore`
2. ✅ **Never commit `firebase-credentials.json`** — use GitHub Secrets
3. ✅ **Protect main branch** — require pull requests
4. ✅ **Use strong JWT secrets** — minimum 32 random characters
5. ✅ **Rotate secrets regularly** — update GitHub secrets monthly
6. ✅ **Review PRs before merge** — at least one approval
7. ✅ **Run tests automatically** — GitHub Actions must pass

---

## Next Steps After Setup

1. ✅ Invite team members to repository
2. ✅ Create issues for new features
3. ✅ Use Pull Requests for all changes
4. ✅ Monitor GitHub Actions for failures
5. ✅ Check Cloud Run logs regularly
6. ✅ Update README as project grows
7. ✅ Add more tests and coverage
8. ✅ Setup monitoring & alerts

---

## Summary Checklist

- [ ] GitHub account created
- [ ] Repository created on GitHub
- [ ] Code pushed to GitHub (main branch)
- [ ] GitHub Secrets added (GCP_SA_KEY, PROJECT_ID, etc.)
- [ ] Backend CI workflow created and passing
- [ ] Frontend CI workflow created and passing
- [ ] Docker Build workflow created
- [ ] Cloud Run Deploy workflow created
- [ ] README.md with badges added
- [ ] Branch protection enabled on main
- [ ] Tested: Make a change → Push → Verify auto-deployment
- [ ] Cloud Run service accessible via URL

---

## You're Done! 🎉

Your project is now:
- ✅ On GitHub (version control)
- ✅ Automatically tested (GitHub Actions)
- ✅ Automatically deployed (to Cloud Run)
- ✅ Fully monitored (logs & alerts)

Every time you push to `main`:
1. Tests run automatically ✅
2. Docker image builds ✅
3. Image pushes to registry ✅
4. Deploys to Cloud Run ✅
5. Live in production ✅

---

**Document:** BarberPro GitHub & Deployment Setup  
**Version:** 1.0  
**Date:** December 2025  
**Status:** Complete & Ready
