# Kubernetes Backup with Velero & AWS S3

![Velero Logo](https://upload.wikimedia.org/wikipedia/commons/5/5e/Velero-logo.svg)

## Overview
This repository contains a **Bash script** to automate the setup of **Velero** for backing up and restoring Kubernetes clusters using **AWS S3**. The script installs and configures all necessary tools, ensuring a smooth deployment of Velero.

## Features
✅ Installs **AWS CLI** and **Velero CLI** automatically  
✅ Configures AWS credentials for Velero  
✅ Creates an **S3 bucket** for storing backups  
✅ Installs **Velero with the AWS plugin** on a Kubernetes cluster  
✅ Verifies installation and performs a **cluster backup**  
✅ Cleans up temporary credentials for security  

## Why Back Up Your Kubernetes Cluster?
- **Disaster Recovery** – Protect against accidental deletions, misconfigurations, or cloud failures.  
- **Security** – Restore from a clean backup in case of ransomware or security breaches.  
- **Migration** – Easily move workloads between clusters or environments.  
- **Compliance** – Meet data retention and backup requirements.

## Prerequisites
- A running **Kubernetes cluster**
- AWS account with necessary permissions
- **kubectl** and **helm** installed

## Installation & Usage
### 1️⃣ Clone the Repository
```bash
 git clone https://github.com/ahmedd-mahmoudd/K8s-backup-with-velero.git
 cd K8s-backup-with-velero
```

### 2️⃣ Run the Script
```bash
 chmod +x velero-script.sh
 ./velero-script.sh
```

The script will prompt for AWS credentials, create an S3 bucket, install Velero, and perform a backup.

### 3️⃣ Verify Velero Installation
```bash
 kubectl get pods -n velero
 velero backup get
```

### 4️⃣ Restore a Backup (Example)
```bash
 velero restore create --from-backup <backup-name>
```

## Customization
- To change the **Velero version**, modify the `VELERO_VERSION` variable in the script.
- The default AWS region is **us-east-1**, but you can specify a different one during execution.

## Troubleshooting
- **S3 Bucket Already Exists?** Choose a unique bucket name.
- **Velero Pod Not Running?** Check logs with:
  ```bash
  kubectl logs -n velero deployment/velero
  ```

## Contributions
Feel free to fork, open issues, or submit PRs! 🚀

## Author
**Ahmed Mahmoud**  
LinkedIn: [Ahmed Mahmoud](https://www.linkedin.com/in/ahmedd-mahmoud/)  

---
🌟 **If you find this project useful, don't forget to star the repo!** 🌟

