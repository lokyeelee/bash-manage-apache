<h1>Automated Apache Deployment and Monitoring with Bash</h1>

<h2>Introduction</h2>
<b>I wrote four Bash scripts to automate the setup and monitoring of Apache web servers across multiple virtual machines. </b> This project is designed to simulate enterprise server operations and administration in a controlled lab environment.
<br />
<br />
It provisions three RHEL 9 VMs via Vagrant on VirtualBox:
<ol>
  <li>admin — one central management server</li>
  <li>webserver2 — Apache web server</li>
  <li>webserver3 — Apache web server</li>
</ol>
<img width="800" height="450" alt="Screenshot 2026-01-21 120415" src="https://github.com/user-attachments/assets/f3978744-0637-4a24-8a49-2da81ecc8b05" />


<h2>Technologies Used</h2>

- **Language:** Bash
- **Utilities:** Vagrant (for VM provisioning), VirtualBox (hypervisor), Telegram Bot APIs
- **Environment:** RHEL 9


<h2>Scripts Overview </h2>

| Script                  | Purpose                                                                 | Execution location               |
|-------------------------|-------------------------------------------------------------------------|--------------------------------|
| 1-remote-install-apache.sh | Remotely installs and configures Apache                                | Runs on admin                  |
| 2-backup-file.sh        | Remotely backs up /var/www/html and other important files                | Runs on admin                  |
| 3-run-cmd-remotely.sh   | Executes any command remotely on target web server                       | Runs on admin                  |
| 4-monitor-service.sh    | Checks and records Apache status in a log file. Sends Telegram alert if down           | Runs locally on each web server |

- The admin server remotely installs Apache, backs up web files, and runs remote commands on target web servers.
- Each web server runs its own local monitoring script that checks the Apache service status every few minutes and sends Telegram notifications on downtime.


<h2>Requirements/Prerequisite </h2>
To successfully execute the script, ensure the following conditions are met:

- All three servers must be able to communicate with each other.
- The user running the script must have SSH keys properly configured on both the admin and web servers.
- The web server must have internet access to connect to Telegram's API endpoints.
- The user executing the script must have the necessary permissions, such as access to system files and the ability to perform installations.
- Open access for SSH and HTTP in the firewall on the web servers.


<h2>Program walk-through:</h2>
<h3>Script 1: 1-remote-install-apache.sh</h3>
<img width="600" height="249" alt="1" src="https://github.com/user-attachments/assets/75315173-f6c1-4864-900f-46d09c6c5871" />
<img width="600" height="211" alt="2" src="https://github.com/user-attachments/assets/0d8c6464-073a-44e4-9507-171def6eeb98" />
<br />
<ul>
  <li>Remotely install Apache on webserver2 and 3</li>
  <li>Create a simple index.html file in /var/www/html</li>
  <li>Ping and curl the web server to test if the server is responsive</li>
</ul>

<h3>Script 2: 2-backup-file.sh</h3>
<img width="645" height="21" alt="3" src="https://github.com/user-attachments/assets/c2ec1a06-02d9-4164-b309-b58a68fbc35a" />
<img width="854" height="193" alt="4" src="https://github.com/user-attachments/assets/7e31179f-14ed-462c-928d-13b1c3624e5b" />
<br />
<ul>
  <li>Back up files from the web servers to the local admin server</li>
</ul>
<img width="665" height="28" alt="5" src="https://github.com/user-attachments/assets/15b2346e-bbc9-4e49-bff0-060093fe0702" />
<ul>
  <li>Schedule it to run every day with <code>cron</code></li>
</ul>

<h3>Script 3: 3-run-cmd-remotely.sh </h3>
<img width="500" height="392" alt="6" src="https://github.com/user-attachments/assets/cb7e0aa0-5bee-4a41-8070-cece5a91c078" />
<ul>
  <li>Execute any commands remotely on the web servers</li>
  <li>Provide four options to run the script
    <ul>
      <li><code>-f</code>: Overrides the default server by specifying a file that lists the servers</li>
      <li><code>-n</code>: 'Dry run' the command. Display the command instead of executed.</li>
      <li><code>-s</code>: Run the script with root privileges</li>
      <li><code>-v</code>: Verbose mode</li>
    </ul>
  </li>
</ul>

<h3>Script 4: 4-monitor-service.sh</h3>
<img width="600" height="305" alt="7" src="https://github.com/user-attachments/assets/10121537-6d52-4061-9bed-b6309f9ddac6" />
<br />
<ul>
  <li>Check if Apache is running on the web servers</li>
  <li>Record the up/down status in a log file</li>
</ul>

<img width="711" height="22" alt="9" src="https://github.com/user-attachments/assets/9cea036b-e1bb-429d-86fc-1928d4e813a4" />
<ul>
  <li>Schedule it to run every 5 minutes with <code>cron</code></li>
</ul>

<img width="623" height="92" alt="Screenshot 2026-01-21 161127" src="https://github.com/user-attachments/assets/304a359f-f664-40f4-b709-92f914164906" />
<ul>
  <li>If Apache is down, restart the service and send alert to Telegram client</li>
</ul>


<br />
