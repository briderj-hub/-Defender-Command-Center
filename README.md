# -Defender-Command-Center
A "Single Pane of Glass" PowerShell GUI for managing Windows Defender, Firewall, and System Hardening. 
Key Features:

🖥️ System Dashboard
Visual Health Status: Instantly see the status of Real-time Protection, Ransomware Shields, and Firewall Profiles (Domain, Private, Public).

Hardware Security: One-glance verification of Secure Boot, TPM 2.0, Tamper Protection, and BitLocker encryption status.

System Monitor: Real-time Internet Connectivity checks and Uptime/Reboot Pending detection to ensure security patches are applied.

🚨 Incident Response
Panic Mode: A "Nuclear Option" that instantly blocks ALL inbound and outbound network traffic to isolate a compromised machine.

Offline Scan: Reboot directly into the Windows Defender Offline recovery environment to remove persistent rootkits.

Threat History: Parse Windows Event Logs to view a detailed timeline of past malware detections and actions taken.

🛠️ Advanced Management
ASR Rules Manager: Easily toggle Attack Surface Reduction rules (Block / Audit / Disable) with human-readable descriptions instead of GUIDs.

Quarantine Manager: View, Restore, or Permanently Delete quarantined threats.

Exclusion Editor: Add or remove folders from Defender exclusions interactively.

Patch Management: Query the Windows Update API to identify missing Security Updates in real-time.

🔍 Threat Intelligence & Tools
VirusTotal Integration: Calculate file hashes and scan them against VirusTotal with a single click.

Second Opinion: Quick access to download tools like Malwarebytes, Kaspersky KVRT, and Emsisoft Emergency Kit.

Audit Trail: Persistent logging of all actions taken within the tool (saved to disk).

📸 Screenshots
(Add your screenshots here, e.g., Dashboard view, ASR Rules tab, Panic Mode active)

⚙️ Requirements
OS: Windows 10 or Windows 11

PowerShell: Version 5.1 or later

Permissions: Must be run as Administrator (The script handles self-elevation automatically).

📥 Installation & Usage
Download the latest DefenderCommandCenter.ps1 release.

Right-click the file and select Run with PowerShell.

Accept the UAC prompt to allow Administrator access.

Note: You may need to set your execution policy to allow scripts: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

⚠️ Disclaimer
This tool makes changes to system security settings (Firewall, Defender preferences). Use with caution, especially in production environments. The "Panic Mode" will cut off all network access, including RDP sessions.

👨‍💻 Developer
Developed by: Johan Brider Copyright: © 2026 Johan Brider
