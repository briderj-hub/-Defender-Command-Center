Defender Command Center
The All-in-One Incident Response & Security Dashboard for Windows.

Defender Command Center is a standalone PowerShell GUI designed for SysAdmins, Blue Teams, and Power Users. It unifies Windows Defender, Firewall, and system hardening controls into a single pane of glass, eliminating the need to dig through nested Settings menus or memorize PowerShell commands during an incident.

🔥 Top-Level Features
No Installation Required: Runs as a standalone script or compiled EXE.

Sentinel Mode: Active background monitoring that alerts you via System Tray if malware is detected.

Panic Button: A "Nuclear Option" to instantly block all network traffic (Inbound/Outbound) to isolate a compromised machine.

Self-Healing: Built-in "Repair Services" tool to force-start crashed security services (WinDefend, MpsSvc, wuauserv).

👁️ Monitor & Detect
System Dashboard: Real-time view of Uptime, CPU/RAM usage, and connectivity status.

Live Network Monitor: View every active TCP connection linked to its specific Process ID and Name.

Actions: Kill Process, Block Remote IP (Firewall), Flush DNS, and Whois IP lookup.

Threat History: A parsed, readable view of Windows Defender event logs (Detections & Actions).

Sentinel: A background watcher that pops up a notification the moment Defender logs a threat (Event 1116/1118) or if Tamper Protection is disabled (Event 5001).

⚙️ Manage & Harden
ASR Rules Manager: Toggle Microsoft's Attack Surface Reduction rules (Block/Audit/Disable) without needing Group Policy.

Advanced Shields: One-click toggles for:

Ransomware Protection (Controlled Folder Access).

PUA Blocking (Potentially Unwanted Applications).

Network Protection (SmartScreen for the whole OS).

USB Storage Blocker (Disable USB drivers to prevent physical data theft).

Startup Inspector: Audit programs starting with Windows (Registry & Folder).

Actions: Delete Persistence or Check hash on VirusTotal.

Exclusion Manager: View hidden antivirus exclusions and remove them if they were added by malware.

🛠️ Tools & Utilities
Health Report Generator: Creates a timestamped .txt audit report on the Desktop (System Status, Patch Level, Security Config) for clients/management.

VirusTotal Scanner: Integrated hash scanner for suspicious files.

3rd Party Scanners: Quick-download links for "Second Opinion" tools (Malwarebytes, Kaspersky KVRT, Emsisoft).

Auto-Run Installer: One-click setup to make the tool launch silently (minimized) at boot via Task Scheduler.

🎨 User Experience
System Tray Integration: Minimizes to the tray instead of closing; keeps "Sentinel" active in the background.

Dark/Light Mode: Toggleable UI themes.

Tooltips: Hover over any feature to learn exactly what it does (e.g., explains what "Secure Boot" or "TPM" actually protects).
⚠️ Disclaimer
This tool makes changes to system security settings (Firewall, Defender preferences). Use with caution, especially in production environments. The "Panic Mode" will cut off all network access, including RDP sessions.

👨‍💻 Developer
Developed by: Johan Brider Copyright: © 2026 Johan Brider
