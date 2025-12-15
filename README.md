# 🖥️ Server Health Audit – DevOps Mini Project

A production-ready **Server Health Monitoring & Audit Script** written in **Bash**.

This project simulates real-world DevOps responsibilities such as:
- System monitoring
- Log analysis
- Security auditing
- Alerting
- Prometheus metrics generation
- Automation using systemd

---

## 🚀 Features

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

---

## 📂 Project Structure

```text
server_health_audit/
├── server_health_audit.sh       # Main script
├── configs/
│   └── server_audit.conf        # Configuration file
├── prom_files/                  # Prometheus metrics
├── reports/                     # Generated reports
└── README.md
````
-----
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

## 🛠️ Future Enhancements

Slack / webhook alerts
Grafana dashboard integration

## 💻 Author

Muhammad Talha Abbas
DevOps | Linux | Automation | Monitoring
