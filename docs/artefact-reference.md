# Artefact reference

A field reference for the artefacts used in this case study. For each one, it covers **where it lives**, **what it can support**, and **what it can't tell you**. The last column matters most: knowing an artefact's limits keeps findings phrased as *supports* rather than *proves*.

> Paths are for Windows 10/11 and Microsoft 365. What exists in a given environment depends on configuration, audit policy and licensing, so confirm it before relying on an artefact being present, or on its absence meaning anything.

**Contents:** [Access and file activity](#1-file-and-folder-access) · [Web upload](#2-web-upload-and-application-network-use) · [Removable media and print](#3-removable-media-and-printing) · [Sessions and identity](#4-session-and-identity) · [Tampering](#5-deletion-tampering-and-anti-forensics) · [Microsoft 365](#6-microsoft-365-and-cloud) · [Memory](#7-memory) · [Timeline pitfalls](#8-timeline-and-interpretation-pitfalls) · [Tools](#9-tools-referenced)

---

## 1. File and folder access

| Artefact | Location | Can support | Limits |
|---|---|---|---|
| **LNK files** | `%APPDATA%\Microsoft\Windows\Recent\*.lnk` | A file was opened through the shell: target path, the target's timestamps, volume serial and type, drive letter, and the host's NetBIOS name | Created by the shell, not by every application. The LNK's own timestamps show first and last open, not every open. Users can delete them. |
| **Jump Lists** | `%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\` and `CustomDestinations\` | Recent files per application (identified by AppID), often with LNK-style metadata | AppIDs must be mapped to applications. Entries roll off. |
| **Shellbags** | `NTUSER.DAT\Software\Microsoft\Windows\Shell\BagMRU` and `UsrClass.dat\Local Settings\Software\Microsoft\Windows\Shell\BagMRU` | Folders the user browsed in Explorer, including on removable and network drives, even after the folder is gone | Folders, not files. Timestamps need careful interpretation. |
| **File-server auditing** | Security log on the file server: **4663** (object access), **5145** (detailed file share) | Which account accessed which file or share, and when | Needs SACLs plus the *File System* and *Detailed File Share* audit subcategories. Often off, and very noisy. |
| **Application audit trail** | Core banking or CRM | Which records were queried or exported, and by which user | Retention and level of detail vary by vendor. Export the trail with a hash. |

## 2. Web upload and application network use

| Artefact | Location | Can support | Limits |
|---|---|---|---|
| **Browser history** | Chromium: `%LOCALAPPDATA%\<vendor>\<browser>\User Data\<profile>\History` (SQLite). Firefox: `places.sqlite` | Visits to webmail and file-sharing sites, and downloads | Doesn't record uploads. Private or InPrivate browsing leaves little. |
| **OpenSavePidlMRU** | `NTUSER.DAT\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU` | Files chosen in an Open/Save dialog, grouped by extension, which is often how a file gets attached to an upload | Only the most recent entry per key can be tied to the key's last-write time. |
| **LastVisitedPidlMRU** | `...\ComDlg32\LastVisitedPidlMRU` | Which executable used the dialog, and the last folder it opened | Same timing limit as above. |
| **SRUM** | `C:\Windows\System32\sru\SRUDB.dat` (resolve names with the `SOFTWARE` hive) | Bytes sent and received per application per user, in roughly hourly buckets, usually kept for 30–60 days | Volume only, not content or destination. Hourly granularity. Data in memory may not yet be written to disk. |
| **Proxy, DLP and firewall** | Network infrastructure | Destination, volume and sometimes the file name or a content match | TLS inspection coverage varies. Must be exported with a hash. |

## 3. Removable media and printing

| Artefact | Location | Can support | Limits |
|---|---|---|---|
| **USBSTOR** | `SYSTEM\ControlSet00x\Enum\USBSTOR` | Device vendor, product and serial. The `Properties\{83da6326-…}` sub-keys `0064`, `0066` and `0067` give first install, last arrival and last removal times | Shows a device was connected, not that files were copied. |
| **MountedDevices** | `SYSTEM\MountedDevices` | Maps a device to a drive letter or volume GUID | Drive letters are reused. |
| **MountPoints2** | `NTUSER.DAT\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2` | Ties a volume GUID to a specific **user** | Per-user hive, so the user's profile must be loaded. |
| **setupapi.dev.log** | `C:\Windows\INF\setupapi.dev.log` | First-install time of the device | Only the first install. |
| **Partition/Diagnostic 1006** | `Microsoft-Windows-Partition%4Diagnostic.evtx` | Disk arrival with serial and partition data, often including the volume boot record | Exists on newer Windows 10/11 builds only. |
| **LNK volume serials** | Inside LNK files | Links an opened file to a specific volume, and so to the USB device | Needs the volume serial from the device or its VBR to match. |
| **PrintService 307** | `Microsoft-Windows-PrintService/Operational` | Document name, user, printer and page count | **Disabled by default.** |

## 4. Session and identity

| Artefact | Location | Can support | Limits |
|---|---|---|---|
| **4624 logon** | Security.evtx | Account logon. **Logon type** matters: 2 = interactive, 7 = unlock, 10 = RDP, 11 = cached | Identifies the account, not the person. |
| **4800 / 4801** | Security.evtx | Workstation locked / unlocked | Needs the *Other Logon/Logoff Events* audit subcategory. |
| **4634 / 4647** | Security.evtx | Logoff | Logoff events can be missing after a crash or forced shutdown. |
| **Entra ID sign-ins** | Entra admin centre or Graph | IP, location, device, client app and Conditional Access result | Usually kept for 30 days with P1/P2 licensing, less without. Export early. |
| **Remote-access traces** | Installed tools, services, Prefetch, EDR telemetry, `TerminalServices-*` logs | Whether someone else could have controlled the session | Absence must be checked across several sources, not assumed. |
| **Badge and CCTV** | Facilities | Physical presence | Shows presence, not who typed. Clock drift is common. |

## 5. Deletion, tampering and anti-forensics

| Artefact | Location | Can support | Limits |
|---|---|---|---|
| **1102** | Security.evtx | The Security log was cleared, and by which account | The clearing event itself survives. Earlier events don't. |
| **104** | System.evtx | Another event log was cleared | |
| **4616** | Security.evtx | The system time was changed | Normal time sync also creates these. Look at the size of the change. |
| **$MFT: $SI vs $FN** | `$MFT` | **$STANDARD_INFORMATION** times can be changed from user mode. **$FILE_NAME** times are updated by the kernel. $SI earlier than $FN, or sub-second values of zero, suggests timestomping | Some legitimate operations (copies, archive extraction) also produce differences. |
| **USN journal** | `$Extend\$UsnJrnl:$J` | File create, rename, write and delete, with reasons and timestamps. Supports archive creation and file history | Circular buffer that rolls over quickly on busy systems. |
| **Prefetch** | `C:\Windows\Prefetch\*.pf` | Program execution: run count, up to 8 last-run times, files referenced. Shows use of archivers or wiping tools | Can be disabled. Shows execution, not what the program did. |
| **Amcache** | `C:\Windows\AppCompat\Programs\Amcache.hve` | A program was present, with its SHA-1 | Presence alone doesn't prove execution. |

## 6. Microsoft 365 and cloud

| Source | Access | Can support | Limits |
|---|---|---|---|
| **Message trace** | Exchange admin centre, `Get-MessageTraceV2` | Sender, recipient, time, size and message ID for outbound mail | No content. Retention is limited, so export early. |
| **Unified audit log: mailbox** | Purview Audit, `Search-UnifiedAuditLog`, or Graph | `Send`, `SendAs`, `SendOnBehalf`, `SoftDelete`, `HardDelete`, `MoveToDeletedItems`, `MailItemsAccessed` | Which actions are logged depends on licensing (Audit Standard or Premium) and the mailbox audit configuration. Default retention is 180 days for Standard, longer for Premium. |
| **Unified audit log: rules** | as above | `New-InboxRule`, `Set-InboxRule`, `UpdateInboxRules`, `Set-Mailbox` (forwarding) | Rules created in Outlook may show as `UpdateInboxRules`. |
| **Recoverable Items** | eDiscovery, or a litigation or in-place hold | Recovers "permanently" deleted items | Only within the retention window. Put a hold in place **early**. |
| **Defender XDR advanced hunting** | `EmailEvents`, `EmailAttachmentInfo`, `DeviceFileEvents`, `DeviceEvents`, `CloudAppEvents` | Matches attachment SHA-256 to file creation on the device, and shows USB mounts and process activity | Advanced hunting keeps 30 days. Requires the relevant Defender licensing. |

Read-only collection examples are in [`../queries/`](../queries/).

## 7. Memory

| What to look for | Can support | Limits |
|---|---|---|
| Running processes, command lines, network connections | Live remote-control tools, active exfiltration, or unusual parent and child processes | One moment in time. Acquiring memory changes it slightly, so document the tool and version. |
| Encryption key material (e.g. the BitLocker FVEK) | Decrypting an image when no recovery key is available | Only while the volume is unlocked. |
| Clipboard, open documents, browser sessions | Context for what was in use at capture time | Fragile, and handling may touch personal data. |

## 8. Timeline and interpretation pitfalls

- **Time zones.** Registry, NTFS, SRUM and M365 audit data are in UTC. EVTX is stored in UTC and displayed in local time. CCTV, badge systems and many business applications use local time. Normalise everything to one zone (in this case study, WAT = UTC+1) and record each source's measured offset.
- **Clock drift.** Compare each device's clock against a trusted source at collection time and note the difference in the custody record.
- **Absence of evidence.** "No 4663 events" usually means auditing was off, not that nobody accessed the file. State the audit configuration in the report.
- **Account ≠ person.** Every Windows and M365 artefact records an *account*. Tie the account to a person only through independent evidence (physical presence, session control, ruling out remote access) and an interview.
- **The examiner's own footprint.** Live response creates processes, files and network traffic. Log every command so these can be told apart from the subject's activity.
- **One artefact, one claim.** Wording such as "the LNK file **supports** that the file was opened from volume X at 22:24" survives cross-examination. "The LNK proves the employee copied the file" does not.

## 9. Tools referenced

| Purpose | Examples |
|---|---|
| Disk imaging | FTK Imager, Guymager, `ewfacquire` |
| Memory acquisition | Magnet RAM Capture, WinPmem, EDR live response |
| Triage collection | KAPE, Velociraptor, EDR live response packages |
| Parsing | Eric Zimmerman's tools (MFTECmd, LECmd, JLECmd, SBECmd, PECmd, SrumECmd, RECmd, EvtxECmd, AmcacheParser), Hindsight |
| Event log triage | Hayabusa, Chainsaw |
| Memory analysis | Volatility 3 |
| Timelining | Timeline Explorer, Plaso / log2timeline |
| Hash verification | `Get-FileHash -Algorithm SHA256`, `sha256sum` |

Tools must be validated before use, and their versions recorded in the case notes.
