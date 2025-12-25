# 🛠 Server Health Audit – CI/CD Pipeline (GitHub Actions)

This project demonstrates a **production-style CI/CD pipeline** built around a Linux server health audit script.

The goal is to showcase how real-world infrastructure scripts are validated, tested, packaged, and deployed using **GitHub Actions** — following DevOps best practices.

---

## 📌 Project Overview

The repository contains a Bash-based server health audit script that checks system-level information such as:

✔ CPU, Memory, Disk usage monitoring
✔ System load monitoring
✔ Top running processes
✔ Failed SSH login detection
✔ Brute-force login detection
✔ Critical port monitoring
✔ Configurable alert thresholds
✔ Email alerts for critical events
✔ Prometheus `.prom` metrics output
✔ Log rotation for reports

The CI/CD pipeline ensures:
- Code quality via linting
- Script sanity validation
- Dependency verification
- Artifact packaging
- Controlled deployment with approvals

---

## 📂 Repository Structure

├── server_health_audit.sh
├── config/
│ └── server_audit.conf.example
├── tests/
│ └── sanity_test.sh
├── .github/
│ └── workflows/
│ └── ci-cd.yml
└── README.md


---

## ⚙️ Configuration

configs/server_audit.conf
Example :
CPU_THRESHOLD=90
MEM_THRESHOLD=90
DISK_THRESHOLD=90
LOAD_THRESHOLD=10
EMAIL="your_email@example.com"

##  📂 Reports + Prom files

Reports will be saved under :
reports/
Prometheus metrics under :
prom_files/

## 🔐 Security Monitoring

SSH brute-force detection
Authentication failures
Critical system log errors
------------------------

## 🔁 CI/CD Pipeline Overview

### Pipeline Flow

Push / PR
↓
Build & Permission Check
↓
ShellCheck (Linting)
↓
Dependency Validation
↓
Sanity Tests
↓
Artifact Packaging
↓
Upload Artifact
↓
Manual Approval → Production Deployment


---

## 🧪 What Each Stage Does

### 🔹 Build
Ensures scripts exist and have correct execution permissions.

### 🔹 Lint
Runs ShellCheck to catch scripting issues early (non-blocking).

### 🔹 Dependency Check
Validates required system utilities without installing anything.

### 🔹 Sanity Test
Verifies:
- Script exists
- Script is executable
- Script starts correctly

### 🔹 Packaging
Creates a versioned `.tar.gz` artifact containing:
- `server_health_audit.sh`
- `config/server_audit.conf.example`

### 🔹 Deployment
Uses GitHub Environments with **manual approval** to simulate real production deployment control.

---

## 🔐 Why This Matters

This pipeline follows **real-world DevOps practices**:
- Immutable builds
- No blind auto-installs
- Explicit environment approvals
- Separation of validation and deployment
- Reproducible artifacts

---

## 🚀 How to Use

1. Clone the repository
2. Push changes to `main`
3. Watch CI pipeline execute
4. Approve production deployment when prompted
5. Download the artifact from GitHub Actions

---

## 🧠 Key Learnings

- CI jobs are isolated environments
- Artifacts are not the same as releases
- Environment approvals enforce governance
- Sanity checks prevent broken deployments
- Shell scripting can be production-grade when structured correctly

---

## 📌 Technologies Used

- Bash
- GitHub Actions
- Linux
- ShellCheck
- CI/CD best practices

---

## 🛠️ Future Enhancements

Slack / webhook alerts
Grafana dashboard integration

## 💻 Author

Muhammad Talha Abbas
DevOps | Linux | Automation | Monitoring


