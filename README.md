# 🎵 Mini Spotify by HO3

A full stack music streaming application built as a hands-on DevOps learning project. Built by **Haneef Olajobi** as part of a junior DevOps engineering roadmap.

> "The best way to learn DevOps is to build real things, break them, and document what you learned." — HO3

---

## 🧠 Project Overview

Mini Spotify lets users upload, play and delete songs through a browser UI. Songs are stored in AWS S3, the app is containerised with Docker, infrastructure is provisioned with Terraform, deployments are automated with GitHub Actions, and the entire system is monitored with Prometheus and Grafana.

This project was built to mirror exactly what a DevOps engineer does in a real company — taking an application and building the full infrastructure around it.

---

## 🏆 What This Project Covers

| DevOps Skill | How It's Used |
|---|---|
| Docker | App containerised and pushed to DockerHub |
| Terraform | Provisions AWS S3 bucket as Infrastructure as Code |
| GitHub Actions | Automatically builds and pushes Docker image on every commit |
| AWS S3 (LocalStack) | Stores uploaded songs as objects |
| Prometheus | Scrapes custom metrics from the app |
| Grafana | Visualises metrics on a real-time dashboard |
| Python Flask | Backend REST API |
| Linux/Bash | Server setup and scripting |

---

## 🧩 Architecture

```
Browser (port 5000)
        ↓
Python Flask Backend
        ↓
AWS S3 Bucket — mini-spotify (LocalStack port 4566)
        ↓
Songs stored as objects in S3

Prometheus (port 9090)
        ↓
Scrapes /metrics endpoint every 15 seconds
        ↓
Grafana (port 3000)
        ↓
Visualises songs played, uploaded, upload duration
```

### CI/CD Flow
```
Push code to GitHub
        ↓
GitHub Actions wakes up
        ↓
Builds Docker image
        ↓
Pushes to DockerHub automatically
        ↓
Done in under 2 minutes
```

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| Python Flask | Backend REST API |
| HTML/CSS/JavaScript | Frontend browser UI |
| AWS S3 (LocalStack) | Song object storage |
| Terraform | Infrastructure as Code |
| Docker | Containerisation |
| DockerHub | Container registry |
| GitHub Actions | CI/CD pipeline |
| Prometheus | Metrics scraping and storage |
| Grafana | Metrics visualisation and dashboards |

---

## 📁 Project Structure

```
mini-spotify/
├── app/
│   └── app.py                    # Flask backend with Prometheus metrics
├── templates/
│   └── index.html                # Frontend UI — upload, play, delete songs
├── static/
│   └── songs/
│       └── .gitkeep              # Keeps empty folder tracked by Git
├── terraform/
│   └── main.tf                   # Provisions S3 bucket in LocalStack
├── .github/
│   └── workflows/
│       └── pipeline.yml          # CI/CD — builds and pushes Docker image
├── prometheus.yml                # Prometheus scrape config
├── Dockerfile                    # Container recipe
├── requirements.txt              # Python dependencies
└── README.md
```

---

## 🚀 How to Run Locally

### Prerequisites
- Python 3.12+
- Docker
- LocalStack
- Terraform
- pip

### Terminal 1 — Start LocalStack (fake AWS)
```bash
export PATH=$PATH:~/.local/bin
localstack start
```

### Terminal 2 — Provision S3 bucket with Terraform
```bash
cd ~/mini-spotify/terraform
terraform init
terraform apply
```
Type `yes` when prompted. This creates the `mini-spotify` S3 bucket automatically.

Verify bucket exists:
```bash
awslocal s3 ls
```

### Terminal 3 — Run the Flask app
```bash
cd ~/mini-spotify
python3 app/app.py
```

Visit `http://localhost:5000` in your browser.

### Terminal 4 — Start Prometheus
```bash
docker run -p 9090:9090 \
  -v ~/mini-spotify/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
```

Visit `http://localhost:9090` to query metrics.

### Terminal 5 — Start Grafana
```bash
docker run -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana
```

Visit `http://localhost:3000` — login with `admin/admin`.

---

## 🐳 Docker

### Build the image
```bash
docker build -t mini-spotify .
```

### Run the container
```bash
docker run -p 5000:5000 mini-spotify
```

### Pull from DockerHub
```bash
docker run -p 5000:5000 olajobihaneef/mini-spotify
```

> ⚠️ Note: When running via Docker locally, the app cannot reach LocalStack due to WSL networking limitations. Run with `python3 app/app.py` for local development. Docker is used for the CI/CD pipeline and production deployments.

---

## 🏗️ Terraform

Instead of manually creating the S3 bucket by clicking in the AWS console, Terraform creates it automatically from code.

```bash
terraform init      # download AWS provider plugin
terraform plan      # preview what will be created
terraform apply     # create the infrastructure
terraform destroy   # delete everything
```

### main.tf explained
```hcl
provider "aws" {
  endpoints {
    s3 = "http://127.0.0.1:4566"   # redirect S3 calls to LocalStack
  }
}

resource "aws_s3_bucket" "mini_spotify" {
  bucket        = "mini-spotify"
  force_destroy = true             # delete bucket even if it has songs inside
}
```

---

## 📊 Prometheus Metrics

The app exposes custom metrics at `http://localhost:5000/metrics`:

| Metric | Type | Description |
|---|---|---|
| `songs_played_total` | Counter | Total number of songs played |
| `songs_uploaded_total` | Counter | Total number of songs uploaded |
| `upload_duration_seconds` | Histogram | Time taken to upload a song to S3 |

### Query examples in Prometheus
```
songs_played_total
rate(songs_uploaded_total[5m])
histogram_quantile(0.95, upload_duration_seconds_bucket)
```

---

## 🔄 CI/CD Pipeline

Every push to the `main` branch automatically triggers the pipeline:

```yaml
on:
  push:
    branches: [main]

jobs:
  build-and-push:
    steps:
      - Checkout code
      - Login to DockerHub using secrets
      - Build Docker image
      - Push to DockerHub
```

### Secrets required in GitHub
- `DOCKER_USERNAME` → your DockerHub username
- `DOCKER_TOKEN` → DockerHub access token (Read/Write/Delete)

---

## ⚠️ Errors Encountered & How I Fixed Them

---

### Error 1 — Docker container can't reach LocalStack

**The Problem:**
When running the Flask app inside Docker, it couldn't connect to LocalStack running on the laptop. Every S3 operation returned:
```
ConnectionRefusedError: [Errno 111] Connection refused
botocore.exceptions.EndpointConnectionError: Could not connect to http://127.0.0.1:4566
```

**Why It Happens:**
Inside a Docker container, `127.0.0.1` refers to the container itself — not your laptop. LocalStack is running on your laptop, not inside the container. The container has no idea LocalStack exists outside its network.

**What I Tried:**
- `127.0.0.1:4566` — points to the container itself, not the laptop
- `host.docker.internal:4566` — supposed to work but WSL has IPv6 issues
- `10.255.255.254:4566` — the WSL DNS nameserver IP, doesn't expose port 4566
- `172.18.0.1:4566` — Docker bridge gateway IP, LocalStack not listening there

**The Fix:**
For local development, run the app directly with Python — no Docker involved:
```bash
python3 app/app.py
```
The permanent fix for production is to run LocalStack as a container in Docker Compose so all services communicate container-to-container.

**Learned:** Docker containers live in their own network. `127.0.0.1` inside a container is not your laptop. Always think about where each service is running.

---

### Error 2 — S3 bucket disappears every time LocalStack restarts

**The Problem:**
Every time LocalStack was stopped and restarted, the `mini-spotify` bucket no longer existed and all S3 operations failed with:
```
NoSuchBucket: The specified bucket does not exist
```

**Why It Happens:**
LocalStack stores everything in memory by default. When the process stops, all data is wiped — just like closing a browser tab loses unsaved work. It is designed for local development and testing, not permanent storage.

**The Fix:**
Run Terraform every time LocalStack starts to recreate the bucket:
```bash
cd terraform
terraform apply
```
Takes 3 seconds and the bucket is back. In production, real AWS S3 persists forever — this is purely a LocalStack limitation.

**Learned:** LocalStack resets on restart. Always run `terraform apply` before starting the app. Real AWS doesn't have this problem.

---

### Error 3 — GitHub Actions pipeline failed — static folder not found

**The Problem:**
The CI/CD pipeline failed with:
```
ERROR: failed to calculate checksum: "/static": not found
```

**Why It Happens:**
Git does not track empty folders. The `static/songs/` folder existed on the laptop but had no files in it, so Git never pushed it to GitHub. When GitHub Actions tried to build the Docker image, the `COPY static/ ./static/` line in the Dockerfile failed because the folder didn't exist in the repository.

**The Fix:**
Add a `.gitkeep` file to the empty folder to force Git to track it:
```bash
touch static/songs/.gitkeep
git add .
git commit -m "added gitkeep to track static folder"
git push
```

**Learned:** Git ignores empty folders. Always add a `.gitkeep` file to empty folders you need tracked.

---

### Error 4 — prometheus-client module not found

**The Problem:**
Running the app directly with Python failed with:
```
ModuleNotFoundError: No module named 'prometheus_client'
```

**Why It Happens:**
The `prometheus-client` library was listed in `requirements.txt` for Docker builds but was not installed in the local Python environment.

**The Fix:**
```bash
pip install prometheus-client --break-system-packages
```

**Learned:** Dependencies installed inside Docker don't affect your local Python environment. Always install locally too when running outside Docker.

---

### Error 5 — Old Docker Compose version causing traceback

**The Problem:**
Running `docker-compose up` failed with a Python traceback:
```
File "/usr/bin/docker-compose", line 33
sys.exit(load_entry_point('docker-compose==1.29.2'))
```

**Why It Happens:**
The system had Docker Compose v1.29.2 installed via apt. This version is outdated and incompatible with modern `docker-compose.yml` syntax.

**The Fix:**
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

**Learned:** Always check your Docker Compose version with `docker-compose --version`. Use v2.x for modern projects.

---

## 💡 My Thinking Process

### Why LocalStack?
AWS costs money and free tier expires. LocalStack runs the same AWS services locally for free. The commands are identical to real AWS so every skill transfers directly to production.

### Why Terraform instead of AWS CLI?
Running `awslocal s3 mb s3://mini-spotify` works but it's manual. Terraform codifies the infrastructure so it can be recreated identically every time with one command. In a team environment this means every developer gets the exact same setup.

### Why Prometheus and Grafana?
Logging tells you what happened. Metrics tell you what is happening right now. Prometheus tracks how many songs are being played and uploaded over time. Grafana turns those numbers into visual dashboards that make trends immediately obvious. Every production system needs this.

### Why document the errors?
Because the errors are where the real learning happens. Reading documentation tells you how things are supposed to work. Hitting errors and fixing them tells you how things actually work.

---

## 📈 What's Next

- [ ] Deploy to real AWS EC2 with real S3
- [ ] Add Kubernetes deployment
- [ ] Configure Grafana dashboards for songs played and uploaded
- [ ] Add alert rules in Prometheus
- [ ] Add pytest tests to CI/CD pipeline

---

## 🐳 DockerHub

Image available at: `olajobihaneef/mini-spotify`

```bash
docker run -p 5000:5000 olajobihaneef/mini-spotify
```

---

## 👨‍💻 Author

**Haneef Olajobi** — Junior DevOps Engineer

- GitHub: [haneeo3](https://github.com/haneeo3)
- DockerHub: [olajobihaneef](https://hub.docker.com/r/olajobihaneef/mini-spotify)
- Project: Part of a hands-on DevOps learning roadmap covering Linux, Docker, Terraform, CI/CD, AWS, Prometheus and Grafana
