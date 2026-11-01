# autodeploy-web — Static Site with Dockerized Nginx Deploy Pipeline

A small static website served by Nginx and shipped through an automated CI/CD pipeline.
The project combines a hand-built static frontend with a Jenkins pipeline that builds a Docker image,
pushes it to Docker Hub, and updates a GitOps repository so downstream deployment can pick up the new image.

---

## ✨ What's in this repo

- A static website (`index.html` + `style.css`) served by Nginx
- A production-ready `Dockerfile` based on `nginx:alpine`
- A Jenkins `Jenkinsfile` that validates, builds, pushes, and triggers a GitOps update on every run
- A GitOps-flavored deploy model: the app repo builds the image, a separate gitops repo holds the deployment config

---

## 📂 Project Structure

```
.
├── index.html          # Static site entry point
├── style.css           # Site styles
├── Dockerfile          # Nginx-based image for serving the static site
├── Jenkinsfile         # CI/CD pipeline (build → push → GitOps update)
└── README.md           # This file
```

---

## 🚀 Quick Start

### Run locally with Docker

```bash
docker build -t autodeploy-web .
docker run --rm -p 8080:80 autodeploy-web
```

Then open <http://localhost:8080>.

### Run locally without Docker

Any static server works:

```bash
python3 -m http.server 8080
# or
npx serve .
```

---

## 🔁 CI/CD Pipeline Overview

The `Jenkinsfile` implements the following flow:

1. **Checkout App** — pull the app repository source
2. **Set Image Tag** — derive a short Git-based image tag (`git rev-parse --short=12 HEAD`)
3. **Validate Files** — confirm `index.html`, `style.css`, and `Dockerfile` are present
4. **Docker Build** — build the image as `soumyadeep7872/autodeploy-web:<tag>`
5. **Push to Docker Hub** — login using Jenkins credentials and push the image
6. **Update GitOps Repo** — clone the gitops repository, patch `deployment.yml` with the new image, commit, and push

Expected outcome on success:

- Docker image pushed to Docker Hub
- GitOps repository updated with the new image reference

Expected outcome on failure:

- Pipeline stops and reports failure in the Jenkins console output
- The post block still attempts to clean up the built image

---

## 🗂️ Pipeline Configuration

Key environment settings in the `Jenkinsfile`:

| Variable | Purpose |
|----------|--------|
| `DOCKERHUB_USER` | Docker Hub username used for the image |
| `IMAGE_NAME` | Image name pushed to Docker Hub |
| `GITOPS_REPO` | GitOps repository URL updated after push |
| `GITOPS_BRANCH` | Branch updated in the GitOps repo |
| `DEPLOY_FILE` | Deployment file patched inside the GitOps repo |

You will need these Jenkins credentials configured:

- `dockerhub-credentials` — Docker Hub username/password
- `github-gitops-credentials` — GitHub credentials for the GitOps repo

---

## 🐛 Validation Stage

Before building, the pipeline asserts that the required source files exist:

- `index.html`
- `style.css`
- `Dockerfile`

If any are missing, the build fails early.

---

## 🎨 Customization

### Site content

Edit `index.html` and `style.css` directly for content and styling changes.

### Docker image destination

Update these in the `Jenkinsfile` if you want a different registry or image name:

- `DOCKERHUB_USER`
- `IMAGE_NAME`

### GitOps target

Update these in the `Jenkinsfile` if the deploy config lives elsewhere:

- `GITOPS_REPO`
- `GITOPS_BRANCH`
- `DEPLOY_FILE`

---

## 🛠️ Tech Notes

- Static site built with plain HTML/CSS
- Container image based on `nginx:alpine`
- CI/CD implemented as a Jenkins declarative pipeline
- Image tags are derived from Git commit history
- Deploy configuration is updated through a GitOps repository rather than a direct deploy step

---

## 📄 License

Use this project according to your own licensing needs.

**Built as an autodeploy-web demo project.**
