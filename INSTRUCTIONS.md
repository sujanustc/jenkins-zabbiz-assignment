# Step-by-Step Setup Guide & Execution Instructions

This guide provides the instructions needed to deploy the Jenkins CI/CD pipeline and configure the Zabbix monitoring system on a single AWS EC2 instance.

---

## Step 1: Launch and Configure AWS EC2 Instance

1. Log into your **AWS Management Console**.
2. Navigate to **EC2 Dashboard** and click **Launch Instance**.
3. Configure the instance details:
   * **Name:** `jenkins-zabbix-monitored-server`
   * **OS (AMI):** Ubuntu Server 22.04 LTS or 24.04 LTS (64-bit x86).
   * **Instance Type:** Select **t3.medium** (2 vCPUs, 4 GB RAM) to handle Jenkins and Zabbix concurrently.
   * **Key Pair:** Create a new key pair or select an existing one to access the instance over SSH.
4. **Configure Network Security Group:**
   Create a security group with the following inbound rules:

   | Protocol | Port | Source | Description |
   | :--- | :--- | :--- | :--- |
   | TCP | 22 | My IP | SSH access for administration |
   | TCP | 80 | Anywhere / My IP | HTTP access for Zabbix Web UI |
   | TCP | 8080 | Anywhere / My IP | HTTP access for Jenkins Web UI |
   | TCP | 3000 | Anywhere / My IP | HTTP access for the Node.js application |

5. Review and click **Launch**.

---

## Step 2: Access EC2 and Execute Setup Scripts

1. Connect to your instance via SSH:
   ```bash
   ssh -i "your-key.pem" ubuntu@<your-ec2-public-ip>
   ```
2. Copy the scripts folder from this repository onto your server (or clone your repository on the EC2 instance).
3. **Run the Jenkins Setup Script:**
   ```bash
   chmod +x scripts/install-jenkins.sh
   sudo ./scripts/install-jenkins.sh
   ```
   *Note: This installs Java 17, Jenkins, Docker, and Node.js. It also adds the `jenkins` user to the `docker` group.*

4. **Run the Zabbix Setup Script:**
   ```bash
   chmod +x scripts/install-zabbix.sh
   sudo ./scripts/install-zabbix.sh
   ```
   *Note: This installs MySQL, Zabbix Server, Apache, the Zabbix Web Frontend, and the Zabbix Agent.*

---

## Step 3: Complete Jenkins Setup & Add Credentials

1. Open your browser and go to `http://<your-ec2-public-ip>:8080`.
2. Retrieve the initial admin password from your EC2 terminal:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
3. Paste the password to unlock Jenkins, then select **Install suggested plugins**.
4. Create your admin user account and finish the setup.
5. **Add Docker Hub Credentials to Jenkins:**
   * In Jenkins, go to **Manage Jenkins** -> **Credentials** -> **System** -> **Global credentials (unrestricted)**.
   * Click **Add Credentials**.
   * Select **Kind:** `Username with password`.
   * **Scope:** Global (default).
   * **Username:** `dasujandb` (your Docker Hub username).
   * **Password:** *[Your Docker Hub Access Token or Password]*
   * **ID:** Enter **`docker-hub-credentials`** *(This exact ID is referenced in the Jenkinsfile)*.
   * Click **Create**.

---

## Step 4: Create and Run the Pipeline Job

1. On the Jenkins home page, click **New Item**.
2. Enter the name `node-express-pipeline`, select **Pipeline**, and click **OK**.
3. Scroll down to the **Pipeline** section:
   * **Definition:** Select `Pipeline script from SCM`.
   * **SCM:** Select `Git`.
   * **Repository URL:** Enter your GitHub Repository URL (containing the `Jenkinsfile` and `/app` folder).
   * **Branch Specifier:** E.g., `*/main` or `*/master`.
   * **Script Path:** `Jenkinsfile` (default).
4. Click **Save**.
5. Click **Build Now** to execute the pipeline.
6. Once completed, take your screenshots of:
   * **Pipeline Stage View** (the visual green timeline blocks).
   * **Successful Build** console output (or the build card marked green).
7. Verify the Node.js application is running by visiting: `http://<your-ec2-public-ip>:3000`.

---

## Step 5: Complete Zabbix Dashboard Configuration

1. In your browser, navigate to: `http://<your-ec2-public-ip>/zabbix`.
2. Proceed through the Zabbix installation wizard:
   * **Database type:** MySQL (default).
   * **Database name:** `zabbix` (default).
   * **User:** `zabbix`.
   * **Password:** `zabbix_password` (the password created by the script).
   * Complete the wizard steps.
3. Log in with the default administrator credentials:
   * **Username:** `Admin` (case sensitive)
   * **Password:** `zabbix`
4. **Add/Configure Host Monitoring:**
   * Go to **Monitoring** -> **Hosts** or **Data collection** -> **Hosts**.
   * By default, the `Zabbix server` host is automatically created and monitors `127.0.0.1` (the local EC2 host itself via Zabbix Agent).
   * Ensure that the host status is **Enabled** and the **Availability (ZBX)** indicator turns green.
5. Take your **Dashboard Screenshot** showing monitored metrics and CPU graphs.

---

## Step 6: Configure Trigger & Trigger Alert Simulation

1. **Verify Trigger Configuration:**
   * Zabbix's default template `Linux by Zabbix agent` already contains pre-configured triggers for high CPU load.
   * To view or create a custom trigger, go to **Data collection** -> **Hosts**.
   * Click on **Triggers** next to the `Zabbix server` host.
   * Look for the trigger name containing "CPU" (e.g., `Load average is too high` or `High CPU utilization`). Take a screenshot of the **Trigger Configuration** page.
2. **Simulate High CPU Load:**
   * Connect to your EC2 terminal.
   * Run a stress test to push CPU utilization above the trigger threshold:
     ```bash
     sudo apt-get install -y stress
     # Run stress test on 4 CPU workers for 2 minutes
     stress --cpu 4 --timeout 120
     ```
3. **Capture the Alert:**
   * Go to Zabbix **Monitoring** -> **Problems** in your browser.
   * Watch the dashboard. Within 1-2 minutes, you will see a high CPU utilization warning trigger and appear as an active red/orange problem.
   * Take a screenshot of the **Alert/Problem list** showing the active trigger.

---

## Step 7: Finalize the Report

1. Create a folder named `screenshots` in your local project repository root.
2. Save your screenshots into this folder with these exact names:
   * `jenkins-stages.png`
   * `jenkins-build-success.png`
   * `zabbix-dashboard.png`
   * `zabbix-trigger.png`
   * `zabbix-alert-problem.png`
3. Push your repository to GitHub. The relative links in the `REPORT.md` will display the images correctly!
4. You can convert the markdown `REPORT.md` into a Word document or PDF for final submission.
