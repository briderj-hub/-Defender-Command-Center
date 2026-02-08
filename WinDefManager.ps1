<#
    Defender Command Center v21.1 - Linked Edition
    
    Copyright (c) 2026 Johan Brider
    LinkedIn: https://www.linkedin.com/in/johanbrider/
    
    Developed by: Johan Brider
    License: Proprietary / Internal Use Only
#>

# 0. Self-Elevation
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# 1. Load Frameworks
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")

# --- USER CONFIGURATION ---
$Developer = "Johan Brider" 
$Copyright = "© 2026 Johan Brider"
$LinkedIn  = "https://www.linkedin.com/in/johanbrider/"

# --- Global Logic & Logs ---
$LogEntries = New-Object System.Collections.ArrayList
$IsDarkMode = $false
$LogPath = "$env:TEMP\DefenderCenter_Log.txt"

# --- Theme Variables ---
$Theme = @{
    Bg         = [System.Drawing.Color]::FromArgb(236, 240, 241)
    Sidebar    = [System.Drawing.Color]::FromArgb(44, 62, 80)
    CardBg     = [System.Drawing.Color]::White
    Text       = [System.Drawing.Color]::FromArgb(44, 62, 80)
    TextLight  = [System.Drawing.Color]::White
    BtnText    = [System.Drawing.Color]::Black
    GridBg     = [System.Drawing.Color]::White
    GridText   = [System.Drawing.Color]::Black
}

# --- Fixed Colors ---
$Color_Green    = [System.Drawing.Color]::FromArgb(39, 174, 96)
$Color_Red      = [System.Drawing.Color]::FromArgb(192, 57, 43)
$Color_Active   = [System.Drawing.Color]::FromArgb(52, 152, 219)
$Color_Gold     = [System.Drawing.Color]::Gold

# --- Fonts ---
$GlobalFont     = New-Object System.Drawing.Font("Segoe UI", 10)
$HeaderFont     = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$StatusFont     = New-Object System.Drawing.Font("Segoe UI", 12)
$SectionFont    = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$CardFont       = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$SmallFont      = New-Object System.Drawing.Font("Segoe UI", 9)
$LogFont        = New-Object System.Drawing.Font("Consolas", 10)

# --- Tooltip Initializer ---
$Tip = New-Object System.Windows.Forms.ToolTip
$Tip.AutoPopDelay = 8000
$Tip.InitialDelay = 500
$Tip.ReshowDelay = 500
$Tip.ShowAlways = $true

# --- ASR Rule Database ---
$ASR_Db = @{
    "56a863a9-875e-4185-98a7-b882c64b5ce5" = @{Name="Block abuse of exploited vulnerable signed drivers"; Desc="Prevents malware from using known 'bad' drivers."}
    "7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c" = @{Name="Block Adobe Reader from creating child processes"; Desc="Stops Adobe Reader from launching other programs."}
    "D4F940AB-401B-4EFC-AADC-AD5F3C50688A" = @{Name="Block all Office applications from creating child processes"; Desc="Prevents Word/Excel from launching CMD/PowerShell."}
    "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2" = @{Name="Block credential stealing from LSASS.exe"; Desc="Protects passwords stored in memory."}
    "BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550" = @{Name="Block executable content from email client and webmail"; Desc="Stops .exe files from Outlook/Webmail."}
    "01443614-CD74-433A-B99E-2ECDC07BFC25" = @{Name="Block executable files (prevalence, age, or trusted list)"; Desc="Blocks new/unknown .exe files."}
    "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC" = @{Name="Block execution of potentially obfuscated scripts"; Desc="Stops 'scrambled' scripts."}
    "D3E037E1-3EB8-44C8-A917-57927947596D" = @{Name="Block JS/VBS from launching downloaded executable content"; Desc="Prevents downloaded Javascript from installing software."}
    "3B576869-A4EC-4529-8536-B80A7769E899" = @{Name="Block Office applications from creating executable content"; Desc="Stops malware saving .exe via Office."}
    "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84" = @{Name="Block Office applications from injecting code into other processes"; Desc="Prevents Office apps hijacking programs."}
    "26190899-1602-49E8-8B27-EB1D0A1CE869" = @{Name="Block Office communication app from creating child processes"; Desc="Stops Outlook launching background apps."}
    "e6db77e5-3df2-4cf1-b95a-636979351e5b" = @{Name="Block persistence through WMI event subscription"; Desc="Stops malware using WMI to survive reboot."}
    "D1E49AAC-8F56-4280-B9BA-993A6D77406C" = @{Name="Block process creations from PSExec and WMI commands"; Desc="Blocks remote execution tools."}
    "33ddedf1-c6e0-47cb-833e-de6133960387" = @{Name="Block rebooting machine in Safe Mode"; Desc="Prevents malware forcing Safe Mode."}
    "B2B3F03D-6A65-4F7B-A9C7-1C7EF74A9BA4" = @{Name="Block untrusted and unsigned processes that run from USB"; Desc="Stops unsigned programs from USB."}
    "c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb" = @{Name="Block use of copied or impersonated system tools"; Desc="Stops hackers renaming tools like PowerShell."}
    "a8f5898e-1dc8-49a9-9878-85004b8a61e6" = @{Name="Block Webshell creation for Servers"; Desc="Prevents web server shells."}
    "92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B" = @{Name="Block Win32 API calls from Office macros"; Desc="Stops Macros from advanced system calls."}
    "c1db55ab-c21a-4637-bb3f-a12568109d35" = @{Name="Use advanced protection against ransomware"; Desc="Heuristically blocks ransomware behavior."}
}

# --- Core Functions ---

function Add-Log($Message) {
    $Time = Get-Date -Format "HH:mm:ss"
    $LogMsg = "[$Time] $Message"
    [void]$LogEntries.Add($LogMsg)
    try { $LogMsg | Out-File -FilePath $LogPath -Append -Encoding utf8 } catch {}
    if ($ViewLog.Visible) { 
        $LogBox.Text = $LogEntries -join "`r`n"
        $LogBox.SelectionStart = $LogBox.Text.Length
        $LogBox.ScrollToCaret()
    }
}

function Switch-View($PanelName) {
    $ViewDashboard.Visible=$false; $ViewRules.Visible=$false; $ViewExcl.Visible=$false; $ViewVT.Visible=$false; $ViewScanners.Visible=$false; $ViewLog.Visible=$false; $ViewThreats.Visible=$false; $ViewQuarantine.Visible=$false
    switch ($PanelName) {
        "Dashboard" { $LblPageTitle.Text = "SYSTEM DASHBOARD"; $ViewDashboard.Visible = $true; Get-SystemHealth }
        "Rules"     { $LblPageTitle.Text = "ATTACK SURFACE RULES"; $ViewRules.Visible = $true; Refresh-List }
        "Excl"      { $LblPageTitle.Text = "EXCLUSION MANAGER"; $ViewExcl.Visible = $true; Get-Exclusions }
        "Quarantine"{ $LblPageTitle.Text = "QUARANTINE MANAGER"; $ViewQuarantine.Visible = $true; Get-Quarantine }
        "VT"        { $LblPageTitle.Text = "VIRUSTOTAL SCANNER"; $ViewVT.Visible = $true }
        "Scanners"  { $LblPageTitle.Text = "SECOND OPINION SCANNERS"; $ViewScanners.Visible = $true }
        "Threats"   { $LblPageTitle.Text = "THREAT HISTORY (EVENT LOG)"; $ViewThreats.Visible = $true; Get-ThreatHistory }
        "Log"       { $LblPageTitle.Text = "ACTIVITY LOG"; $ViewLog.Visible = $true; $LogBox.Text = $LogEntries -join "`r`n" }
    }
}

function Toggle-Theme {
    $Global:IsDarkMode = -not $Global:IsDarkMode
    if ($Global:IsDarkMode) {
        $Theme.Bg = [System.Drawing.Color]::FromArgb(45, 45, 48)
        $Theme.CardBg = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $Theme.Text = [System.Drawing.Color]::White
        $Theme.BtnText = [System.Drawing.Color]::White
        $Theme.GridBg = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $Theme.GridText = [System.Drawing.Color]::White
        $BtnTheme.Text = "☀️"
        $Tip.SetToolTip($BtnTheme, "Switch to Light Mode")
    } else {
        $Theme.Bg = [System.Drawing.Color]::FromArgb(236, 240, 241)
        $Theme.CardBg = [System.Drawing.Color]::White
        $Theme.Text = [System.Drawing.Color]::FromArgb(44, 62, 80)
        $Theme.BtnText = [System.Drawing.Color]::Black
        $Theme.GridBg = [System.Drawing.Color]::White
        $Theme.GridText = [System.Drawing.Color]::Black
        $BtnTheme.Text = "🌙"
        $Tip.SetToolTip($BtnTheme, "Switch to Dark Mode")
    }
    
    $Form.BackColor = $Theme.Bg
    $LblPageTitle.ForeColor = $Theme.Text
    $LblDefHeader.ForeColor = $Theme.Text
    $LblFWHeader.ForeColor = $Theme.Text
    $LblHardHeader.ForeColor = $Theme.Text
    $LblSysStatus.ForeColor = $Theme.Text
    
    $Cards = @($CardDef, $CardAdv, $CardPanic, $CardFWDom, $CardFWPri, $CardFWPub, $CardHard, $CardPatch)
    foreach ($C in $Cards) { $C.BackColor = $Theme.CardBg; $C.Controls[0].ForeColor = $Theme.Text }
    
    $Grids = @($Grid, $ExclGrid, $ThreatGrid, $QuarantineGrid)
    foreach ($G in $Grids) {
        $G.BackgroundColor = $Theme.GridBg
        $G.DefaultCellStyle.BackColor = $Theme.GridBg
        $G.DefaultCellStyle.ForeColor = $Theme.GridText
    }
    
    Add-Log "Theme toggled."
    Switch-View "Dashboard"
}

# --- System Health Functions ---
function Get-SystemHealth {
    $Form.Cursor = "WaitCursor"
    
    # Connectivity
    $NetStatus = "Unknown"; $NetColor = $Color_Red
    try { if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) { $NetStatus = "Connected"; $NetColor = if ($Global:IsDarkMode) { "LightGreen" } else { "Green" } } else { $NetStatus = "Disconnected"; $NetColor = "Red" } } catch { $NetStatus = "Error" }

    # Uptime
    $Uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $Days = $Uptime.Days
    $Pending = $false
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") { $Pending = $true }
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") { $Pending = $true }
    
    if ($Pending) { $LblSysStatus.Text = "⚠️ Uptime: $Days days | Net: $NetStatus | PENDING REBOOT"; $LblSysStatus.ForeColor = $Color_Red }
    else { $LblSysStatus.Text = "✓ Uptime: $Days days | Net: $NetStatus | System Healthy"; $LblSysStatus.ForeColor = $NetColor }
    
    # Defender
    try { $MpStatus = Get-MpComputerStatus -ErrorAction Stop; if ($MpStatus.RealTimeProtectionEnabled) { $CardDef.BackColor = $Color_Green; $LblDefStat.Text = "ACTIVE"; $LblDefStat.ForeColor = "White" } else { $CardDef.BackColor = $Color_Red; $LblDefStat.Text = "INACTIVE"; $LblDefStat.ForeColor = "White" }; $LblDefUpdate.Text = "Sig: " + $MpStatus.AntivirusSignatureLastUpdated.ToString("yyyy-MM-dd HH:mm"); $LblDefUpdate.ForeColor = "White" } catch { $LblDefStat.Text = "ERROR" }

    # Advanced Shields
    try { $Prefs = Get-MpPreference
        if ($Prefs.EnableControlledFolderAccess -eq 1) { $LblRanStat.Text = "Ransomware: ON"; $LblRanStat.ForeColor = $Color_Green; $BtnRansom.Text = "Disable"; $BtnRansom.BackColor = "White" } else { $LblRanStat.Text = "Ransomware: OFF"; $LblRanStat.ForeColor = $Color_Red; $BtnRansom.Text = "Enable"; $BtnRansom.BackColor = "LightPink" }
        if ($Prefs.PUAProtection -eq 1) { $LblPUAStat.Text = "PUA Block: ON"; $LblPUAStat.ForeColor = $Color_Green; $BtnPUA.Text = "Disable"; $BtnPUA.BackColor = "White" } else { $LblPUAStat.Text = "PUA Block: OFF"; $LblPUAStat.ForeColor = $Color_Red; $BtnPUA.Text = "Enable"; $BtnPUA.BackColor = "LightPink" }
        if ($Prefs.EnableControlledFolderAccess -eq 1 -and $Prefs.PUAProtection -eq 1) { $CardAdv.BackColor = $Color_Green; $LblAdvHeader.ForeColor = "White" } else { $CardAdv.BackColor = "White"; $LblAdvHeader.ForeColor = "Black" }
    } catch {}

    # Panic
    $AllBlocked = $true; try { $Profiles = Get-NetFirewallProfile; foreach ($P in $Profiles) { if ($P.DefaultOutboundAction -ne "Block") { $AllBlocked = $false } }; if ($AllBlocked) { $CardPanic.BackColor = $Color_Red; $LblPanicStat.Text = "ISOLATED"; $BtnPanic.Visible = $false; $BtnRestore.Visible = $true } else { $CardPanic.BackColor = $Color_White; $LblPanicStat.Text = "ONLINE"; $BtnPanic.Visible = $true; $BtnRestore.Visible = $false } } catch {}

    # Hardening
    $SecureBoot = try { Confirm-SecureBootUEFI } catch { "Unknown" }; $TPM = try { (Get-Tpm).TpmPresent } catch { $false }; $Tamper = (Get-MpComputerStatus).IsTamperProtected; $BitLocker = try { $BL = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue; if ($BL.ProtectionStatus -eq "On") { $true } else { $false } } catch { $false }
    Update-Hard-Label $LblSecure "Secure Boot" $SecureBoot; Update-Hard-Label $LblTPM "TPM Chip" $TPM; Update-Hard-Label $LblTamper "Tamper Prot" $Tamper; Update-Hard-Label $LblBitLocker "BitLocker (C:)" $BitLocker

    # Firewall & Patch
    try { $Profiles = Get-NetFirewallProfile; Update-FW-Card $CardFWDom $LblFWDomStat $BtnFWDom ($Profiles | Where-Object Name -eq "Domain").Enabled; Update-FW-Card $CardFWPri $LblFWPriStat $BtnFWPri ($Profiles | Where-Object Name -eq "Private").Enabled; Update-FW-Card $CardFWPub $LblFWPubStat $BtnFWPub ($Profiles | Where-Object Name -eq "Public").Enabled } catch {}
    try { $LastUpdate = Get-CimInstance Win32_QuickFixEngineering | Sort-Object InstalledOn -Descending | Select-Object -First 1; if ($LastUpdate.InstalledOn) { $LblPatchLast.Text = "Last Patch: " + [DateTime]$LastUpdate.InstalledOn | Get-Date -Format "yyyy-MM-dd" } else { $LblPatchLast.Text = "Last Patch: Unknown" } } catch { $LblPatchLast.Text = "Last Patch: Unknown" }
    $Form.Cursor = "Default"
}

# --- Management Logic ---
function Get-Quarantine {
    $QuarantineGrid.Rows.Clear(); $Form.Cursor = "WaitCursor"
    try { $Threats = Get-MpThreat -ErrorAction SilentlyContinue; if ($Threats) { foreach ($T in $Threats) { [void]$QuarantineGrid.Rows.Add($T.ThreatName, $T.Resources[0], $T.ThreatID) } } else { [void]$QuarantineGrid.Rows.Add("No quarantined items found", "", "") } } catch { [void]$QuarantineGrid.Rows.Add("Error fetching quarantine", "", "") }
    $Form.Cursor = "Default"
}
function Restore-Quarantine { if ($QuarantineGrid.SelectedRows.Count -eq 0) { return }; $Name = $QuarantineGrid.SelectedRows[0].Cells[0].Value; if (Confirm-Action "RESTORE" "Restore '$Name'?") { try { Restore-MpThreat -ThreatName $Name; Add-Log "Restored: $Name"; Get-Quarantine } catch {} } }
function Remove-Quarantine { if ($QuarantineGrid.SelectedRows.Count -eq 0) { return }; $Name = $QuarantineGrid.SelectedRows[0].Cells[0].Value; if (Confirm-Action "DELETE" "Permanently delete '$Name'?") { try { Remove-MpThreat -ThreatName $Name; Add-Log "Deleted: $Name"; Get-Quarantine } catch {} } }

function Add-Exclusion { $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; if ($FBD.ShowDialog() -eq "OK") { $Path = $FBD.SelectedPath; if (Confirm-Action "EXCLUSION" "Add '$Path'?") { try { Add-MpPreference -ExclusionPath $Path; Add-Log "Excluded: $Path"; Get-Exclusions } catch {} } } }
function Remove-Exclusion { if ($ExclGrid.SelectedRows.Count -eq 0) { return }; $Type = $ExclGrid.SelectedRows[0].Cells[0].Value; $Value = $ExclGrid.SelectedRows[0].Cells[1].Value; if (Confirm-Action "REMOVE EXCLUSION" "Remove '$Value'?") { try { if ($Type -eq "Path") { Remove-MpPreference -ExclusionPath $Value } else { Remove-MpPreference -ExclusionExtension $Value }; Add-Log "Removed Excl: $Value"; Get-Exclusions } catch {} } }

function Get-ThreatHistory { $ThreatGrid.Rows.Clear(); $Form.Cursor = "WaitCursor"; try { $Events = Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 50 -FilterXPath "*[System[(EventID=1116 or EventID=1117)]]" -ErrorAction SilentlyContinue; if ($Events) { foreach ($E in $Events) { $Time = $E.TimeCreated.ToString("yyyy-MM-dd HH:mm"); $Msg = $E.Message -replace "`n", " "; $Threat="Unknown"; if ($Msg -match "Threat Name: (.+?)\s") { $Threat = $Matches[1] }; [void]$ThreatGrid.Rows.Add($Time, $E.Id, $Threat, $Msg) } } else { [void]$ThreatGrid.Rows.Add("", "", "No recent threats", "") } } catch {}; $Form.Cursor = "Default" }

function Start-OfflineScan { if (Confirm-Action "DEFENDER OFFLINE SCAN" "REBOOT and perform a deep boot-time scan? (15 min).") { Add-Log "Starting Offline Scan..."; Start-MpWDOScan } }
function Check-OnlineUpdates { $Form.Cursor = "WaitCursor"; $LblPatchCount.Text = "Checking MS..."; [System.Windows.Forms.Application]::DoEvents(); try { $S = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0 and Type='Software' and IsHidden=0"); $Count = 0; foreach ($U in $S.Updates) { if ($U.Title -match "Security" -or $U.MsrcSeverity -ne $null) { $Count++ } }; if ($Count -eq 0) { $LblPatchCount.Text = "No Missing Security Updates"; $LblPatchCount.ForeColor = $Color_Green } else { $LblPatchCount.Text = "MISSING: $Count Security Updates!"; $LblPatchCount.ForeColor = $Color_Red } } catch { $LblPatchCount.Text = "Check Failed" } finally { $Form.Cursor = "Default" } }
function Update-Hard-Label($Label, $Name, $Status) { if ($Status -eq $true -or $Status -eq "True") { $Label.Text = "✔ $Name"; $Label.ForeColor = $Color_Green } else { $Label.Text = "✖ $Name"; $Label.ForeColor = $Color_Red } }
function Update-Sigs { try { $Form.Cursor="WaitCursor"; Update-MpSignature -ErrorAction Stop; Add-Log "Signatures Updated."; Get-SystemHealth } catch { Add-Log "Update Failed: $_" } finally { $Form.Cursor="Default" } }
function Start-QuickScan { try { $Form.Cursor="WaitCursor"; Start-MpScan -ScanType QuickScan; Add-Log "Quick Scan started."; [System.Windows.Forms.MessageBox]::Show("Scan started in background.") } catch { Add-Log "Scan Failed: $_" } finally { $Form.Cursor="Default" } }
function Update-FW-Card($Card, $Label, $Button, $State) { if ($State -eq "True") { $Card.BackColor = $Color_Green; $Label.Text = "ON"; $Label.ForeColor = "White"; $Button.Text = "OFF"; $Tip.SetToolTip($Button, "Turn OFF Firewall") } else { $Card.BackColor = $Color_Red; $Label.Text = "OFF"; $Label.ForeColor = "White"; $Button.Text = "ON"; $Tip.SetToolTip($Button, "Turn ON Firewall") } }
function Confirm-Action($Title, $Message) { return ([System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning) -eq "Yes") }
function Exec-Reboot { if (Confirm-Action "REBOOT SYSTEM" "RESTART computer immediately?") { Add-Log "Rebooting..."; Restart-Computer -Force } }
function Toggle-Firewall($ProfileName) { try { $Current = (Get-NetFirewallProfile -Name $ProfileName).Enabled; if ($Current -eq $True -and -not (Confirm-Action "Disable Firewall" "Disable $ProfileName Firewall?")) { return }; $NewState = if ($Current -eq $True) { "False" } else { "True" }; Set-NetFirewallProfile -Name $ProfileName -Enabled $NewState; Add-Log "Firewall $ProfileName toggled."; Get-SystemHealth } catch {} }
function Toggle-Ransomware { try { $Prefs = Get-MpPreference; $NewState = if ($Prefs.EnableControlledFolderAccess -eq 1) { 0 } else { 1 }; Set-MpPreference -EnableControlledFolderAccess $NewState; Add-Log "Ransomware toggled."; Get-SystemHealth } catch {} }
function Toggle-PUA { try { $Prefs = Get-MpPreference; $NewState = if ($Prefs.PUAProtection -eq 1) { 0 } else { 1 }; Set-MpPreference -PUAProtection $NewState; Add-Log "PUA toggled."; Get-SystemHealth } catch {} }
function Exec-Panic { if (Confirm-Action "PANIC MODE" "BLOCK ALL traffic?") { Set-NetFirewallProfile -All -DefaultInboundAction Block -DefaultOutboundAction Block; Add-Log "PANIC ON."; Get-SystemHealth } }
function Exec-Restore { Set-NetFirewallProfile -All -DefaultInboundAction Block -DefaultOutboundAction Allow; Add-Log "Restored."; Get-SystemHealth }
function Get-Exclusions { $ExclGrid.Rows.Clear(); try { $P=Get-MpPreference; foreach($e in $P.ExclusionPath){[void]$ExclGrid.Rows.Add("Path",$e)}; foreach($ex in $P.ExclusionExtension){[void]$ExclGrid.Rows.Add("Ext",$ex)} } catch{} }
function Export-Exclusions-CSV { $SavePath = "$env:USERPROFILE\Desktop\Defender_Exclusions.csv"; try { $List=@(); foreach($R in $ExclGrid.Rows){$List+=[PSCustomObject]@{Type=$R.Cells[0].Value;Value=$R.Cells[1].Value}}; $List|Export-Csv $SavePath -NoType; [System.Windows.Forms.MessageBox]::Show("Exported to $SavePath") } catch {} }
function Refresh-List { $Grid.Rows.Clear(); $L=Get-ASRState; foreach($I in $L){ $X=$Grid.Rows.Add($I.Name,$I.Status,$I.GUID); $Grid.Rows[$X].Cells[0].ToolTipText=$I.Desc; if($I.Status -eq "Block"){$Grid.Rows[$X].Cells[1].Style.BackColor="LightGreen"}elseif($I.Status -eq "Audit"){$Grid.Rows[$X].Cells[1].Style.BackColor="Gold"}else{$Grid.Rows[$X].Cells[1].Style.BackColor="LightPink"} } }
function Get-ASRState { $C=Get-MpPreference; $R=@(); foreach($K in $ASR_Db.Keys){ $S="Disabled"; if($C.AttackSurfaceReductionRules_Ids -contains $K){ $I=[array]::IndexOf($C.AttackSurfaceReductionRules_Ids,$K); $A=$C.AttackSurfaceReductionRules_Actions[$I]; switch($A){0{$S="Disabled"}1{$S="Block"}2{$S="Audit"}} }; $R+=[PSCustomObject]@{Name=$ASR_Db[$K].Name;Status=$S;GUID=$K;Desc=$ASR_Db[$K].Desc} }; return $R|Sort Name }
function Set-RuleState($State) { if ($Grid.SelectedRows.Count -eq 0) { return }; $Row = $Grid.SelectedRows[0]; $Guid = $Row.Cells[2].Value; $Form.Cursor = "WaitCursor"; try { Add-MpPreference -AttackSurfaceReductionRules_Ids $Guid -AttackSurfaceReductionRules_Actions $State; Add-Log "ASR Updated."; Refresh-List } catch { [System.Windows.Forms.MessageBox]::Show("Error") }; $Form.Cursor = "Default" }
function Select-And-Scan-File { $D = New-Object System.Windows.Forms.OpenFileDialog; if ($D.ShowDialog() -eq "OK") { $Form.Cursor="Wait"; try { $H = Get-FileHash $D.FileName -Algorithm SHA256; Open-Link "https://www.virustotal.com/gui/file/$($H.Hash)" } catch {}; $Form.Cursor="Default" } }
function Open-Link($Url) { try { Start-Process $Url } catch {} }

function New-SideBtn($Text, $Top, $TipText) { $Btn=New-Object System.Windows.Forms.Button; $Btn.Text=$Text; $Btn.Font=$GlobalFont; $Btn.ForeColor="White"; $Btn.BackColor=$Theme.Sidebar; $Btn.FlatStyle="Flat"; $Btn.FlatAppearance.BorderSize=0; $Btn.Size="200, 50"; $Btn.Location="0, $Top"; $Btn.TextAlign="MiddleLeft"; $Btn.Padding="20,0,0,0"; $Btn.Cursor="Hand"; $Tip.SetToolTip($Btn, $TipText); return $Btn }
function New-Card($Title, $X, $Y) { $P=New-Object System.Windows.Forms.Panel; $P.Size="280, 165"; $P.Location="$X, $Y"; $P.BackColor=$Theme.CardBg; $L=New-Object System.Windows.Forms.Label; $L.Text=$Title; $L.Font=$SmallFont; $L.Location="12,15"; $L.AutoSize=$true; $L.ForeColor=$Theme.Text; $P.Controls.Add($L); $Bar=New-Object System.Windows.Forms.Panel; $Bar.Size="280, 5"; $Bar.Dock="Top"; $Bar.BackColor="Gray"; $P.Controls.Add($Bar); return $P }

# --- Form Construction ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Defender Command Center v21.1 - Dev: $Developer"; $Form.Size = "1180, 950"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = $Theme.Bg

$Sidebar = New-Object System.Windows.Forms.Panel; $Sidebar.Dock = "Left"; $Sidebar.Width = 200; $Sidebar.BackColor = $Theme.Sidebar
$LblHeader = New-Object System.Windows.Forms.Label; $LblHeader.Text = "DEFENDER COMMAND"; $LblHeader.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $LblHeader.ForeColor = "White"; $LblHeader.Location = "0, 20"; $LblHeader.Size = "200, 50"; $LblHeader.TextAlign = "MiddleCenter"; $Sidebar.Controls.Add($LblHeader)
$BtnDash=New-SideBtn "Dashboard" 80 "View System Health & Controls"; $BtnDash.Add_Click({Switch-View "Dashboard"}); $Sidebar.Controls.Add($BtnDash)
$BtnRules=New-SideBtn "ASR Rules" 130 "Manage Attack Surface Reduction Rules"; $BtnRules.Add_Click({Switch-View "Rules"}); $Sidebar.Controls.Add($BtnRules)
$BtnExcl=New-SideBtn "Exclusions" 180 "Manage Antivirus Exclusions"; $BtnExcl.Add_Click({Switch-View "Excl"}); $Sidebar.Controls.Add($BtnExcl)
$BtnQuarantine=New-SideBtn "Quarantine" 230 "Manage Quarantined Threats"; $BtnQuarantine.Add_Click({Switch-View "Quarantine"}); $Sidebar.Controls.Add($BtnQuarantine)
$BtnThreats=New-SideBtn "Threat History" 280 "View Defender Event Logs for Threats"; $BtnThreats.Add_Click({Switch-View "Threats"}); $Sidebar.Controls.Add($BtnThreats)
$BtnVT=New-SideBtn "VirusTotal" 330 "Scan files or URLs using VirusTotal"; $BtnVT.Add_Click({Switch-View "VT"}); $Sidebar.Controls.Add($BtnVT)
$BtnScan=New-SideBtn "Scanners & Tools" 380 "Download 3rd-party scanners"; $BtnScan.Add_Click({Switch-View "Scanners"}); $Sidebar.Controls.Add($BtnScan)
$BtnLog=New-SideBtn "Activity Log" 430 "View script execution logs"; $BtnLog.Add_Click({Switch-View "Log"}); $Sidebar.Controls.Add($BtnLog)
$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Text = "🌙"; $BtnTheme.Font = $GlobalFont; $BtnTheme.Size = "50,50"; $BtnTheme.Location = "10, 830"; $BtnTheme.FlatStyle = "Flat"; $BtnTheme.ForeColor = "White"; $BtnTheme.FlatAppearance.BorderSize = 0; $BtnTheme.Add_Click({ Toggle-Theme }); $Sidebar.Controls.Add($BtnTheme); $Tip.SetToolTip($BtnTheme, "Toggle Dark/Light Mode");

# Dev Label (UPDATED TO LINKLABEL)
$LblDev = New-Object System.Windows.Forms.LinkLabel
$LblDev.Text = $Copyright
$LblDev.Font = $SmallFont
$LblDev.LinkColor = [System.Drawing.Color]::SkyBlue
$LblDev.ActiveLinkColor = [System.Drawing.Color]::White
$LblDev.Location = "10, 880"
$LblDev.AutoSize = $true
$LblDev.LinkArea = New-Object System.Windows.Forms.LinkArea(0, $LblDev.Text.Length)
$LblDev.Add_LinkClicked({ Open-Link $LinkedIn })
$Sidebar.Controls.Add($LblDev)

$Form.Controls.Add($Sidebar)

$LblPageTitle = New-Object System.Windows.Forms.Label; $LblPageTitle.Text = "SYSTEM DASHBOARD"; $LblPageTitle.Font = $HeaderFont; $LblPageTitle.Location = "230, 15"; $LblPageTitle.AutoSize = $true; $Form.Controls.Add($LblPageTitle)
$LblSysStatus = New-Object System.Windows.Forms.Label; $LblSysStatus.Text = "Checking..."; $LblSysStatus.Font = $StatusFont; $LblSysStatus.Location = "230, 55"; $LblSysStatus.AutoSize = $true; $Form.Controls.Add($LblSysStatus)
$BtnReboot = New-Object System.Windows.Forms.Button; $BtnReboot.Text = "REBOOT SYSTEM"; $BtnReboot.Location = "750, 50"; $BtnReboot.Size = "150, 30"; $BtnReboot.BackColor = $Color_Red; $BtnReboot.ForeColor = "White"; $BtnReboot.FlatStyle = "Flat"; $BtnReboot.Add_Click({ Exec-Reboot }); $Form.Controls.Add($BtnReboot); $Tip.SetToolTip($BtnReboot, "Restart computer immediately.")

$ViewPanel = New-Object System.Windows.Forms.Panel; $ViewPanel.Size = "920, 800"; $ViewPanel.Location = "230, 90"; $Form.Controls.Add($ViewPanel)

# --- DASHBOARD ---
$ViewDashboard = New-Object System.Windows.Forms.Panel; $ViewDashboard.Dock = "Fill"; $ViewPanel.Controls.Add($ViewDashboard)
$LblDefHeader = New-Object System.Windows.Forms.Label; $LblDefHeader.Text = "WINDOWS DEFENDER"; $LblDefHeader.Font = $SectionFont; $LblDefHeader.Location = "0, 10"; $LblDefHeader.AutoSize=$true; $ViewDashboard.Controls.Add($LblDefHeader)

$CardDef=New-Card "REAL-TIME PROTECTION" 0 40; 
$LblDefStat=New-Object System.Windows.Forms.Label; $LblDefStat.Font=$CardFont; $LblDefStat.Location="12,45"; $LblDefStat.AutoSize=$true; $CardDef.Controls.Add($LblDefStat)
$LblDefUpdate=New-Object System.Windows.Forms.Label; $LblDefUpdate.Location="12,85"; $LblDefUpdate.Size="140,40"; $LblDefUpdate.Font=$SmallFont; $CardDef.Controls.Add($LblDefUpdate)
$BtnDefUpdate=New-Object System.Windows.Forms.Button; $BtnDefUpdate.Text="Update Sig"; $BtnDefUpdate.Location="170,40"; $BtnDefUpdate.Size="100,28"; $BtnDefUpdate.BackColor="White"; $BtnDefUpdate.FlatStyle="Flat"; $BtnDefUpdate.Add_Click({ Update-Sigs }); $CardDef.Controls.Add($BtnDefUpdate)
$BtnDefScan=New-Object System.Windows.Forms.Button; $BtnDefScan.Text="Quick Scan"; $BtnDefScan.Location="170,75"; $BtnDefScan.Size="100,28"; $BtnDefScan.BackColor="White"; $BtnDefScan.FlatStyle="Flat"; $BtnDefScan.Add_Click({ Start-QuickScan }); $CardDef.Controls.Add($BtnDefScan)
$BtnOffline=New-Object System.Windows.Forms.Button; $BtnOffline.Text="Offline Scan"; $BtnOffline.Location="170,110"; $BtnOffline.Size="100,28"; $BtnOffline.BackColor="Gold"; $BtnOffline.FlatStyle="Flat"; $BtnOffline.Add_Click({ Start-OfflineScan }); $CardDef.Controls.Add($BtnOffline); $Tip.SetToolTip($BtnOffline, "Reboots into Recovery Environment to scan for rootkits.")
$ViewDashboard.Controls.Add($CardDef)

$CardAdv=New-Card "ADVANCED SHIELDS" 300 40; $LblAdvHeader=$CardAdv.Controls[0];
$LblRanStat=New-Object System.Windows.Forms.Label; $LblRanStat.Font=$SmallFont; $LblRanStat.Location="12,45"; $LblRanStat.Size="150,20"; $CardAdv.Controls.Add($LblRanStat); 
$BtnRansom=New-Object System.Windows.Forms.Button; $BtnRansom.Location="170,40"; $BtnRansom.Size="90,25"; $BtnRansom.FlatStyle="Flat"; $BtnRansom.Add_Click({Toggle-Ransomware}); $CardAdv.Controls.Add($BtnRansom);
$LblPUAStat=New-Object System.Windows.Forms.Label; $LblPUAStat.Font=$SmallFont; $LblPUAStat.Location="12,85"; $LblPUAStat.Size="150,20"; $CardAdv.Controls.Add($LblPUAStat);
$BtnPUA=New-Object System.Windows.Forms.Button; $BtnPUA.Location="170,80"; $BtnPUA.Size="90,25"; $BtnPUA.FlatStyle="Flat"; $BtnPUA.Add_Click({Toggle-PUA}); $CardAdv.Controls.Add($BtnPUA)
$ViewDashboard.Controls.Add($CardAdv)

$CardPanic=New-Card "EMERGENCY ISOLATION" 600 40; 
$LblPanicStat=New-Object System.Windows.Forms.Label; $LblPanicStat.Text="ONLINE"; $LblPanicStat.Font=$CardFont; $LblPanicStat.Location="12,50"; $CardPanic.Controls.Add($LblPanicStat); 
$BtnPanic=New-Object System.Windows.Forms.Button; $BtnPanic.Text="PANIC"; $BtnPanic.BackColor=$Color_Red; $BtnPanic.ForeColor="White"; $BtnPanic.FlatStyle="Flat"; $BtnPanic.Location="170,90"; $BtnPanic.Size="90,32"; $BtnPanic.Add_Click({Exec-Panic}); $CardPanic.Controls.Add($BtnPanic); $Tip.SetToolTip($BtnPanic, "EMERGENCY: Blocks all network traffic immediately.") 
$BtnRestore=New-Object System.Windows.Forms.Button; $BtnRestore.Text="RESTORE"; $BtnRestore.BackColor=$Color_Green; $BtnRestore.ForeColor="White"; $BtnRestore.FlatStyle="Flat"; $BtnRestore.Location="170,90"; $BtnRestore.Size="90,32"; $BtnRestore.Visible=$false; $BtnRestore.Add_Click({Exec-Restore}); $CardPanic.Controls.Add($BtnRestore); $ViewDashboard.Controls.Add($CardPanic)

$LblFWHeader = New-Object System.Windows.Forms.Label; $LblFWHeader.Text = "WINDOWS FIREWALL"; $LblFWHeader.Font = $SectionFont; $LblFWHeader.Location = "0, 220"; $LblFWHeader.AutoSize=$true; $ViewDashboard.Controls.Add($LblFWHeader)
$CardFWDom=New-Card "FW: DOMAIN" 0 250; $LblFWDomStat=New-Object System.Windows.Forms.Label; $LblFWDomStat.Font=$CardFont; $LblFWDomStat.Location="12,50"; $CardFWDom.Controls.Add($LblFWDomStat); $BtnFWDom=New-Object System.Windows.Forms.Button; $BtnFWDom.Location="170,90"; $BtnFWDom.Size="90,32"; $BtnFWDom.Add_Click({Toggle-Firewall "Domain"}); $CardFWDom.Controls.Add($BtnFWDom); $ViewDashboard.Controls.Add($CardFWDom)
$CardFWPri=New-Card "FW: PRIVATE" 300 250; $LblFWPriStat=New-Object System.Windows.Forms.Label; $LblFWPriStat.Font=$CardFont; $LblFWPriStat.Location="12,50"; $CardFWPri.Controls.Add($LblFWPriStat); $BtnFWPri=New-Object System.Windows.Forms.Button; $BtnFWPri.Location="170,90"; $BtnFWPri.Size="90,32"; $BtnFWPri.Add_Click({Toggle-Firewall "Private"}); $CardFWPri.Controls.Add($BtnFWPri); $ViewDashboard.Controls.Add($CardFWPri)
$CardFWPub=New-Card "FW: PUBLIC" 600 250; $LblFWPubStat=New-Object System.Windows.Forms.Label; $LblFWPubStat.Font=$CardFont; $LblFWPubStat.Location="12,50"; $CardFWPub.Controls.Add($LblFWPubStat); $BtnFWPub=New-Object System.Windows.Forms.Button; $BtnFWPub.Location="170,90"; $BtnFWPub.Size="90,32"; $BtnFWPub.Add_Click({Toggle-Firewall "Public"}); $CardFWPub.Controls.Add($BtnFWPub); $ViewDashboard.Controls.Add($CardFWPub)

$LblHardHeader = New-Object System.Windows.Forms.Label; $LblHardHeader.Text = "HARDWARE SECURITY"; $LblHardHeader.Font = $SectionFont; $LblHardHeader.Location = "0, 430"; $LblHardHeader.AutoSize=$true; $ViewDashboard.Controls.Add($LblHardHeader)
$CardHard=New-Card "SYSTEM HARDENING" 0 460; $CardHard.Size="580, 100" 
$LblSecure=New-Object System.Windows.Forms.Label; $LblSecure.Location="20, 50"; $LblSecure.AutoSize=$true; $LblSecure.Font=$GlobalFont; $CardHard.Controls.Add($LblSecure)
$LblTPM=New-Object System.Windows.Forms.Label; $LblTPM.Location="180, 50"; $LblTPM.AutoSize=$true; $LblTPM.Font=$GlobalFont; $CardHard.Controls.Add($LblTPM)
$LblTamper=New-Object System.Windows.Forms.Label; $LblTamper.Location="320, 50"; $LblTamper.AutoSize=$true; $LblTamper.Font=$GlobalFont; $CardHard.Controls.Add($LblTamper)
$LblBitLocker=New-Object System.Windows.Forms.Label; $LblBitLocker.Location="450, 50"; $LblBitLocker.AutoSize=$true; $LblBitLocker.Font=$GlobalFont; $CardHard.Controls.Add($LblBitLocker)
$ViewDashboard.Controls.Add($CardHard)

$CardPatch=New-Card "PATCH MANAGEMENT" 600 460; $CardPatch.Size="280, 100"
$LblPatchLast=New-Object System.Windows.Forms.Label; $LblPatchLast.Location="12,45"; $LblPatchLast.AutoSize=$true; $LblPatchLast.Font=$SmallFont; $CardPatch.Controls.Add($LblPatchLast)
$LblPatchCount=New-Object System.Windows.Forms.Label; $LblPatchCount.Location="12,65"; $LblPatchCount.AutoSize=$true; $LblPatchCount.Font=$SmallFont; $LblPatchCount.Text="Pending: Unknown"; $CardPatch.Controls.Add($LblPatchCount)
$BtnPatchCheck=New-Object System.Windows.Forms.Button; $BtnPatchCheck.Text="Check Online"; $BtnPatchCheck.Location="165,55"; $BtnPatchCheck.Size="100,28"; $BtnPatchCheck.BackColor="White"; $BtnPatchCheck.FlatStyle="Flat"; $BtnPatchCheck.Add_Click({ Check-OnlineUpdates }); $CardPatch.Controls.Add($BtnPatchCheck)
$ViewDashboard.Controls.Add($CardPatch)

# --- THREAT HISTORY ---
$ViewThreats = New-Object System.Windows.Forms.Panel; $ViewThreats.Dock = "Fill"; $ViewThreats.Visible = $false; $ViewPanel.Controls.Add($ViewThreats)
$ThreatGrid = New-Object System.Windows.Forms.DataGridView; $ThreatGrid.Size="880, 600"; $ThreatGrid.ColumnCount=4; $ThreatGrid.Columns[0].Name="Time"; $ThreatGrid.Columns[0].Width=150; $ThreatGrid.Columns[1].Name="EventID"; $ThreatGrid.Columns[1].Width=80; $ThreatGrid.Columns[2].Name="Threat"; $ThreatGrid.Columns[2].Width=200; $ThreatGrid.Columns[3].Name="Details"; $ThreatGrid.Columns[3].Width=400; $ThreatGrid.BackgroundColor=$Theme.GridBg; $ThreatGrid.RowHeadersVisible=$false; $ThreatGrid.ReadOnly=$true; $ViewThreats.Controls.Add($ThreatGrid)
$BtnRefreshThreats = New-Object System.Windows.Forms.Button; $BtnRefreshThreats.Text = "Refresh Log"; $BtnRefreshThreats.Location = "20, 620"; $BtnRefreshThreats.Size = "150, 40"; $BtnRefreshThreats.BackColor = $Color_Active; $BtnRefreshThreats.ForeColor = "White"; $BtnRefreshThreats.FlatStyle = "Flat"; $BtnRefreshThreats.Add_Click({ Get-ThreatHistory }); $ViewThreats.Controls.Add($BtnRefreshThreats)

# --- QUARANTINE MANAGER ---
$ViewQuarantine = New-Object System.Windows.Forms.Panel; $ViewQuarantine.Dock = "Fill"; $ViewQuarantine.Visible = $false; $ViewPanel.Controls.Add($ViewQuarantine)
$QuarantineGrid = New-Object System.Windows.Forms.DataGridView; $QuarantineGrid.Size="880, 550"; $QuarantineGrid.ColumnCount=3; $QuarantineGrid.Columns[0].Name="Threat Name"; $QuarantineGrid.Columns[0].Width=250; $QuarantineGrid.Columns[1].Name="Original Path"; $QuarantineGrid.Columns[1].Width=400; $QuarantineGrid.Columns[2].Name="ID"; $QuarantineGrid.Columns[2].Visible=$false; $QuarantineGrid.BackgroundColor=$Theme.GridBg; $QuarantineGrid.RowHeadersVisible=$false; $QuarantineGrid.SelectionMode="FullRowSelect"; $QuarantineGrid.ReadOnly=$true; $ViewQuarantine.Controls.Add($QuarantineGrid)
$BtnQRestore = New-Object System.Windows.Forms.Button; $BtnQRestore.Text = "RESTORE ITEM"; $BtnQRestore.Location = "20, 570"; $BtnQRestore.Size = "150, 40"; $BtnQRestore.BackColor = $Color_Green; $BtnQRestore.ForeColor = "White"; $BtnQRestore.FlatStyle = "Flat"; $BtnQRestore.Add_Click({ Restore-Quarantine }); $ViewQuarantine.Controls.Add($BtnQRestore)
$BtnQRemove = New-Object System.Windows.Forms.Button; $BtnQRemove.Text = "DELETE FOREVER"; $BtnQRemove.Location = "180, 570"; $BtnQRemove.Size = "150, 40"; $BtnQRemove.BackColor = $Color_Red; $BtnQRemove.ForeColor = "White"; $BtnQRemove.FlatStyle = "Flat"; $BtnQRemove.Add_Click({ Remove-Quarantine }); $ViewQuarantine.Controls.Add($BtnQRemove)
$BtnQRefresh = New-Object System.Windows.Forms.Button; $BtnQRefresh.Text = "Refresh"; $BtnQRefresh.Location = "340, 570"; $BtnQRefresh.Size = "100, 40"; $BtnQRefresh.FlatStyle = "Flat"; $BtnQRefresh.Add_Click({ Get-Quarantine }); $ViewQuarantine.Controls.Add($BtnQRefresh)

# --- ASR RULES VIEW ---
$ViewRules = New-Object System.Windows.Forms.Panel; $ViewRules.Dock = "Fill"; $ViewRules.Visible = $false; $ViewPanel.Controls.Add($ViewRules)
$Grid=New-Object System.Windows.Forms.DataGridView; $Grid.Size="880, 480"; $Grid.ColumnCount=3; $Grid.Columns[0].Name="Rule"; $Grid.Columns[0].Width=500; $Grid.Columns[1].Name="Status"; $Grid.Columns[1].Width=100; $Grid.Columns[2].Visible=$false; $Grid.BackgroundColor=$Theme.GridBg; $Grid.RowHeadersVisible=$false; $Grid.SelectionMode="FullRowSelect"; $Grid.ReadOnly=$true; $ViewRules.Controls.Add($Grid)
$BtnRuleBlock = New-Object System.Windows.Forms.Button; $BtnRuleBlock.Text = "BLOCK"; $BtnRuleBlock.Location = "0, 500"; $BtnRuleBlock.Size = "150, 40"; $BtnRuleBlock.BackColor = $Color_Green; $BtnRuleBlock.ForeColor = "White"; $BtnRuleBlock.FlatStyle = "Flat"; $BtnRuleBlock.Add_Click({ Set-RuleState 1 }); $ViewRules.Controls.Add($BtnRuleBlock)
$BtnRuleAudit = New-Object System.Windows.Forms.Button; $BtnRuleAudit.Text = "AUDIT MODE"; $BtnRuleAudit.Location = "160, 500"; $BtnRuleAudit.Size = "150, 40"; $BtnRuleAudit.BackColor = "Gold"; $BtnRuleAudit.FlatStyle = "Flat"; $BtnRuleAudit.Add_Click({ Set-RuleState 2 }); $ViewRules.Controls.Add($BtnRuleAudit)
$BtnRuleDisable = New-Object System.Windows.Forms.Button; $BtnRuleDisable.Text = "DISABLE"; $BtnRuleDisable.Location = "320, 500"; $BtnRuleDisable.Size = "150, 40"; $BtnRuleDisable.BackColor = $Color_Red; $BtnRuleDisable.ForeColor = "White"; $BtnRuleDisable.FlatStyle = "Flat"; $BtnRuleDisable.Add_Click({ Set-RuleState 0 }); $ViewRules.Controls.Add($BtnRuleDisable)

# --- EXCLUSIONS VIEW ---
$ViewExcl = New-Object System.Windows.Forms.Panel; $ViewExcl.Dock = "Fill"; $ViewExcl.Visible = $false; $ViewPanel.Controls.Add($ViewExcl)
$ExclGrid = New-Object System.Windows.Forms.DataGridView; $ExclGrid.Size="880, 500"; $ExclGrid.ColumnCount=2; $ExclGrid.Columns[0].Name="Type"; $ExclGrid.Columns[0].Width=100; $ExclGrid.Columns[1].Name="Value"; $ExclGrid.Columns[1].Width=700; $ExclGrid.BackgroundColor=$Theme.GridBg; $ExclGrid.RowHeadersVisible=$false; $ExclGrid.SelectionMode="FullRowSelect"; $ExclGrid.ReadOnly=$true; $ViewExcl.Controls.Add($ExclGrid)
$BtnAddExcl = New-Object System.Windows.Forms.Button; $BtnAddExcl.Text = "Add Folder"; $BtnAddExcl.Location = "20, 520"; $BtnAddExcl.Size = "150, 40"; $BtnAddExcl.BackColor = $Color_Green; $BtnAddExcl.ForeColor = "White"; $BtnAddExcl.FlatStyle = "Flat"; $BtnAddExcl.Add_Click({ Add-Exclusion }); $ViewExcl.Controls.Add($BtnAddExcl)
$BtnRemExcl = New-Object System.Windows.Forms.Button; $BtnRemExcl.Text = "Remove Selected"; $BtnRemExcl.Location = "180, 520"; $BtnRemExcl.Size = "150, 40"; $BtnRemExcl.BackColor = $Color_Red; $BtnRemExcl.ForeColor = "White"; $BtnRemExcl.FlatStyle = "Flat"; $BtnRemExcl.Add_Click({ Remove-Exclusion }); $ViewExcl.Controls.Add($BtnRemExcl)
$BtnExport = New-Object System.Windows.Forms.Button; $BtnExport.Text = "Export to CSV"; $BtnExport.Location = "340, 520"; $BtnExport.Size = "150, 40"; $BtnExport.BackColor = $Color_Active; $BtnExport.ForeColor = "White"; $BtnExport.FlatStyle = "Flat"; $BtnExport.Add_Click({ Export-Exclusions-CSV }); $ViewExcl.Controls.Add($BtnExport)

# --- LOG VIEW ---
$ViewLog = New-Object System.Windows.Forms.Panel; $ViewLog.Dock = "Fill"; $ViewLog.Visible = $false; $ViewPanel.Controls.Add($ViewLog)
$LogBox = New-Object System.Windows.Forms.TextBox; $LogBox.Multiline = $true; $LogBox.ScrollBars = "Vertical"; $LogBox.ReadOnly = $true
$LogBox.Font = $LogFont; $LogBox.BackColor = "Black"; $LogBox.ForeColor = "LimeGreen"; $LogBox.Dock = "Fill"; $ViewLog.Controls.Add($LogBox)

# --- VIRUSTOTAL VIEW ---
$ViewVT = New-Object System.Windows.Forms.Panel; $ViewVT.Dock = "Fill"; $ViewVT.Visible = $false; $ViewPanel.Controls.Add($ViewVT)
$LblVT = New-Object System.Windows.Forms.Label; $LblVT.Text = "Enter File Hash or URL to Scan:"; $LblVT.Location = "20, 20"; $LblVT.AutoSize = $true; $LblVT.Font = $SectionFont; $ViewVT.Controls.Add($LblVT)
$TxtVT = New-Object System.Windows.Forms.TextBox; $TxtVT.Location = "20, 60"; $TxtVT.Size = "600, 30"; $TxtVT.Font = $GlobalFont; $ViewVT.Controls.Add($TxtVT)
$BtnVTScan = New-Object System.Windows.Forms.Button; $BtnVTScan.Text = "Check on VirusTotal"; $BtnVTScan.Location = "640, 58"; $BtnVTScan.Size = "180, 32"; $BtnVTScan.BackColor = $Color_Active; $BtnVTScan.ForeColor = "White"; $BtnVTScan.FlatStyle = "Flat"; $BtnVTScan.Add_Click({ if ($TxtVT.Text.Length -gt 0) { Open-Link "https://www.virustotal.com/gui/search/$($TxtVT.Text)" } else { [System.Windows.Forms.MessageBox]::Show("Please enter a Hash or URL.") } }); $ViewVT.Controls.Add($BtnVTScan)
$BtnVTFile = New-Object System.Windows.Forms.Button; $BtnVTFile.Text = "SELECT FILE TO SCAN"; $BtnVTFile.Location = "20, 110"; $BtnVTFile.Size = "200, 40"; $BtnVTFile.BackColor = $Theme.Sidebar; $BtnVTFile.ForeColor = "White"; $BtnVTFile.FlatStyle = "Flat"; $BtnVTFile.Add_Click({ Select-And-Scan-File }); $ViewVT.Controls.Add($BtnVTFile)

# --- SCANNERS VIEW ---
$ViewScanners = New-Object System.Windows.Forms.Panel; $ViewScanners.Dock="Fill"; $ViewScanners.Visible=$false; $ViewPanel.Controls.Add($ViewScanners)
$Scanners = @(@{Name="Malwarebytes ADWCleaner"; Url="https://www.malwarebytes.com/adwcleaner"}, @{Name="Kaspersky Removal Tool"; Url="https://www.kaspersky.com/downloads/free-virus-removal-tool"}, @{Name="Emsisoft Emergency Kit"; Url="https://www.emsisoft.com/en/home/emergencykit/"})
$SY=10; foreach($S in $Scanners){ $P=New-Object System.Windows.Forms.Panel; $P.Size="800, 75"; $P.Location="0, $SY"; $P.BackColor=$Theme.CardBg; $L=New-Object System.Windows.Forms.Label; $L.Text=$S.Name; $L.Location="20,28"; $L.AutoSize=$true; $L.Font=$SectionFont; $P.Controls.Add($L); $B=New-Object System.Windows.Forms.Button; $B.Text="Download"; $B.Location="650,22"; $B.Width=120; $B.Height=35; $B.FlatStyle="Flat"; $B.Add_Click({Open-Link $S.Url}); $P.Controls.Add($B); $ViewScanners.Controls.Add($P); $SY+=90 }

$Form.Add_Load({ Get-SystemHealth; 
    # Welcome Notification
    $Notify = New-Object System.Windows.Forms.NotifyIcon
    $Notify.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSCommandPath)
    $Notify.Visible = $True
    $Notify.ShowBalloonTip(3000, "Defender Center v21.1", "Welcome back, $Developer", [System.Windows.Forms.ToolTipIcon]::Info)
    Add-Log "Defender Command Center Started." 
})
$Form.ShowDialog()