
# Toolbox Module Guide

Kali Linux • 57 module definitions • Source snapshot: 14 September 2026

A practical reference for the module files currently supplied from your Toolboxmodules folder. It documents their existing commands and toggles, including limits and prerequisites; it does not change the definitions or run them.


## Start here

- Keep module .txt files directly inside Toolboxmodules beside ToolBox.sh. Nested folders and symbolic-link modules are not loaded.
- Open System & Configuration > Settings > External Modules. Rescan, then load the modules you want. Open the category listed on each module card.
- Set target values with T / Set Target/Data. Use C / Custom Placeholder Values for module-local values, then toggle only the options you need.
- Enable Dry-Run in Settings and use R to inspect the resolved command without executing it. Review targets, required files, output locations and option placement.
- When ready to perform the operation, disable Dry-Run and run again. Use only targets and captures within the scope you are allowed to test.

| Control | Meaning |
| --- | --- |
| C | Set module-local placeholder overrides; they take precedence over global values. |
| A | Append temporary arguments after the built command; no shell evaluation. |
| X | Clear module-local overrides and appended arguments. |
| R | Build and run the command, or preview it when Dry-Run is enabled. |
| D | Module help. |
| T / W | Target/data or workspace selection. |
| 0 / M | Back or main menu. |

Options and module-local overrides reset when you reopen a module. A placeholder used only by a disabled option is not required for that run. An empty required value prompts at run time; blank input cancels. Quotes in a definition group arguments, and Toolbox substitutes values afterwards, so a supplied value containing spaces remains in its intended argument.

OPTIONS, OPTIONS2 and OPTIONS3 are structural placement markers, not values you enter. The guide preserves every option group and its menu numbering. Pipelines, redirects, environment expansion, and command substitution are not supported by the module format.


## Important differences in this collection

- John the Ripper: enable Wordlist to select the dictionary workflow. The default command does not explicitly select it.
- Hashcat: select the matching hash mode and use attack mode 0 for this file-and-wordlist layout.
- Hydra_HTTPS: supply a Hydra service URI such as https-get://host/path. A normal https:// URL or arbitrary HTML login form is not enough.
- NetExec.txt appears as NXC_SMB_Enumeration in the menu. Choose at most one authentication toggle.
- Four modules depend on security_pack.py: SharpHound_DC_Collection_Windows, Mimikatz_Identity_Windows, Rubeus_Ticket_List_Windows, and Scapy_Offline_PCAP_Summary.
- Impacket_README.md is supporting documentation, not a 58th runnable module. The four Impacket .txt definitions are included below.


## Windows helper setup

The three Windows modules execute already-installed Windows binaries through SSH. Kali runs Python and the local helper; Windows runs SharpHound, Mimikatz or Rubeus. Supply PACK_HELPER as an absolute Kali path. The source definitions currently retain this placeholder.

- Provide a Windows host with configured OpenSSH and Windows PowerShell, an existing login, and the required executable already installed.
- WINDOWS_EXE is an absolute Windows path ending in SharpHound.exe, mimikatz.exe or Rubeus.exe as appropriate. WINDOWS_HOST is the SSH destination, and SSH_USER is its login.
- Establish and verify the Windows SSH host key with a normal SSH login first. The pack helper requires known-host trust. Toolbox PASSWORD is not automatically supplied as the SSH password.
- Use Preview remote invocation only to see the decoded command without connecting. Toolbox Dry-Run itself shows the helper invocation.
- SharpHound also needs DOMAIN, a writable existing WINDOWS_OUTPUT directory, and Windows-session access to AD. SSH access alone does not guarantee usable domain credentials.
- The Mimikatz module reports identity only. Rubeus lists ticket metadata for its execution session; it may be empty. SharpHound output remains on Windows.


## Sessions, wireless hardware and results

Disable Auto-Save for interactive consoles. Use exit in Evil-WinRM and Metasploit, quit in Bettercap, and exit() in Scapy. Ctrl+C normally stops foreground captures or listeners; it does not automatically undo separately configured routes or stop services started by a launcher. Stop the BloodHound service separately with bloodhound-stop.

Live wireless modules need supported hardware, drivers, interface state and privileges. Airodump, wash, Reaver and Bully use an existing monitor-mode interface. The definitions do not prepare that interface or stop conflicting services. Wifite_Check_Capture is an offline check. Aircrack_Offline_WPA also reads a local capture. Bully uses test mode; Reaver_Known_PIN_Check sends a bounded PIN test.

Use fresh output names and create parent directories. OUTPUT_PREFIX is not necessarily a complete filename. Many tools also write their own logs, potfiles or session data. Toolbox protects PASSWORD in its own preview/history, but tool output and custom values such as COOKIE are not automatically protected by that placeholder mechanism.

Ligolo requires separate agent/proxy roles plus TUN and route configuration. Chisel needs a running server and matching client settings. The Chisel and Socat forwarding definitions bind their local forwarding ports to 127.0.0.1. ProxyChains needs a prepared configuration and supports the TCP behavior of its wrapped application.


## Troubleshooting

| Symptom | Check |
| --- | --- |
| Module missing | Confirm .txt is directly in Toolboxmodules, rescan and load it, then open its declared category. |
| Executable unavailable | Check the first command token in Kali PATH. Impacket may use impacket- names; Certipy uses certipy-ad. |
| Prompts keep returning | Custom values reset when reopening. Prepare the needed values in C or set appropriate globals. |
| Option has no effect | Ensure it is ON, check its group and command preview, and confirm the installed tool supports the flag. |
| Console has no usable input | Disable Auto-Save; if still unsuitable, use a separate terminal with the resolved command. |
| Windows helper fails | Check PACK_HELPER, Python, SSH host-key trust/login, Windows executable path, and remote permissions. |
| Scan returns nothing | Check target type, credentials, wildcard/response filters, permissions and any required local data. A successful process is not proof of full coverage. |
| Output is not where expected | Check current working directory, output prefixes, tool configuration, or the remote Windows directory. |
| Changed file looks unchanged | Use Rescan / reload selected modules, then reopen the module. |


## Module directory

Use the HTML search box to filter by name, filename, category, input, option or command. Each card records the exact source filename and Name field, so menu labels can be matched even when they differ.

| Category | Modules |
| --- | --- |
| Command-Line Utilities | 1 |
| Exploit | 2 |
| Network / DNS | 2 |
| Pass/Hash Cracking | 6 |
| Payloads / Wordlists / Cheatsheets | 4 |
| Recon / Vulnerabilities | 1 |
| Results / Reporting | 1 |
| SMB / Windows | 11 |
| Service Enumeration | 3 |
| Shell / Session Tools | 7 |
| Traffic Analysis | 8 |
| Vulnerability Assessment | 5 |
| Web Enumeration | 6 |

1. [Aircrack_Offline_WPA](#module-01) - Pass/Hash Cracking
2. [Airodump_Channel_Capture](#module-02) - Traffic Analysis
3. [Bettercap_Network_Recon](#module-03) - Traffic Analysis
4. [BloodHound_CE_DC_Collection](#module-04) - SMB / Windows
5. [BloodHound_CE_Start](#module-05) - Results / Reporting
6. [Bully_WPS_Test_Mode](#module-06) - Vulnerability Assessment
7. [Certipy_ADCS_Inventory](#module-07) - SMB / Windows
8. [CeWL_Site_Wordlist](#module-08) - Payloads / Wordlists / Cheatsheets
9. [Chisel_Server](#module-09) - Shell / Session Tools
10. [Chisel_TCP_Client](#module-10) - Shell / Session Tools
11. [Crunch_Character_Wordlist](#module-11) - Payloads / Wordlists / Cheatsheets
12. [Dirsearch_Content](#module-12) - Web Enumeration
13. [EvilWinRM_Password_Session](#module-13) - Shell / Session Tools
14. [Feroxbuster_Content](#module-14) - Web Enumeration
15. [FFUF_URL_Fuzzing](#module-15) - Web Enumeration
16. [FFUF_Virtual_Hosts](#module-16) - Web Enumeration
17. [Gobuster_Directories](#module-17) - Web Enumeration
18. [Gobuster_DNS](#module-18) - Network / DNS
19. [Hashcat Dictionary Attack](#module-19) - Pass/Hash Cracking
20. [Hydra_HTTPS](#module-20) - Pass/Hash Cracking
21. [Hydra_SSH](#module-21) - Pass/Hash Cracking
22. [Impacket_AD_Computers](#module-22) - SMB / Windows
23. [Impacket_AD_Users](#module-23) - SMB / Windows
24. [Impacket_RPC_Endpoints](#module-24) - Service Enumeration
25. [Impacket_SID_Lookup](#module-25) - SMB / Windows
26. [John Show Cracked](#module-26) - Pass/Hash Cracking
27. [John the Ripper](#module-27) - Pass/Hash Cracking
28. [Kerbrute_User_Enumeration](#module-28) - SMB / Windows
29. [Kismet_Wireless_Capture](#module-29) - Traffic Analysis
30. [Ligolo_Agent](#module-30) - Shell / Session Tools
31. [Ligolo_Proxy](#module-31) - Shell / Session Tools
32. [Medusa_Single_Credential](#module-32) - Service Enumeration
33. [Mimikatz_Identity_Windows](#module-33) - SMB / Windows
34. [msfconsole](#module-34) - Exploit
35. [Ncrack_Single_Credential](#module-35) - Service Enumeration
36. [NXC_SMB_Enumeration](#module-36) - SMB / Windows
37. [Nikto_Web_Audit](#module-37) - Vulnerability Assessment
38. [Nuclei_Selected_Templates](#module-38) - Vulnerability Assessment
39. [Nuclei_Validate_Templates](#module-39) - Command-Line Utilities
40. [ProxyChains_HTTP_Check](#module-40) - Network / DNS
41. [Reaver_Known_PIN_Check](#module-41) - Vulnerability Assessment
42. [Reaver_Wash_Survey](#module-42) - Traffic Analysis
43. [Responder_Analyze](#module-43) - Traffic Analysis
44. [Rubeus_Ticket_List_Windows](#module-44) - SMB / Windows
45. [Scapy_Console](#module-45) - Traffic Analysis
46. [Scapy_Offline_PCAP_Summary](#module-46) - Traffic Analysis
47. [SearchSploit_Local_Search](#module-47) - Recon / Vulnerabilities
48. [SecLists_Find_Wordlists](#module-48) - Payloads / Wordlists / Cheatsheets
49. [SecLists_Preview_Wordlist](#module-49) - Payloads / Wordlists / Cheatsheets
50. [SharpHound_DC_Collection_Windows](#module-50) - SMB / Windows
51. [SMBMap_Share_Inventory](#module-51) - SMB / Windows
52. [Socat_Local_TCP_Forward](#module-52) - Shell / Session Tools
53. [Socat_TCP_Client](#module-53) - Shell / Session Tools
54. [SQLMap](#module-54) - Exploit
55. [Wfuzz_URL_Fuzzing](#module-55) - Web Enumeration
56. [Wifite_Check_Capture](#module-56) - Traffic Analysis
57. [WPScan_WordPress_Inventory](#module-57) - Vulnerability Assessment

<a id="module-01"></a>

## 01 / Aircrack_Offline_WPA

File: Aircrack_Offline_WPA.txt | Category: Pass/Hash Cracking | Mode: Local / offline

Test a local WPA/WPA2 capture against a wordlist for one BSSID; no radio traffic is sent.


### Before use

Executable in Kali PATH: aircrack-ng.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| BSSID | Access point MAC address | 02:00:00:00:00:01 |
| CAPTURE_FILE | Existing packet capture on Kali | /home/kali/lab/capture.pcap |
| WORDLIST | Local password-candidate file | /home/kali/lab/passwords.txt |


### Command template

```text
aircrack-ng -a 2 -b "<<BSSID>>" -w "<<WORDLIST>>" "<<CAPTURE_FILE>>" <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Specify hidden network ESSID | -e "<<ESSID>>" | ESSID |


### Using this module

Set BSSID, CAPTURE_FILE, WORDLIST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- CAPTURE_FILE must contain a suitable handshake. BSSID is an AP MAC address.
- Tool output may display a recovered key.


### Results and completion

Processes local data and prints results. Any enabled output option determines an additional output file.

[Tool documentation / source](https://www.aircrack-ng.org/doku.php?id=aircrack-ng)

<a id="module-02"></a>

## 02 / Airodump_Channel_Capture

File: Airodump_Channel_Capture.txt | Category: Traffic Analysis | Mode: Ongoing capture / connection

Capture wireless traffic on one channel using an existing monitor-mode interface; Ctrl+C stops capture.


### Before use

Executable in Kali PATH: airodump-ng.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| CHANNEL | Wireless channel for the selected access point | 6 |
| INTERFACE | Local network interface; wireless capture may need monitor mode | eth0 or wlan0mon, as appropriate |
| OUTPUT_PREFIX | Output filename prefix; the tool may add suffixes | lab-run |


### Command template

```text
airodump-ng -c <<CHANNEL>> -w "<<OUTPUT_PREFIX>>" <<OPTIONS>> "<<INTERFACE>>"
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Restrict to one BSSID | --bssid "<<BSSID>>" | BSSID |


### Using this module

Set CHANNEL, INTERFACE, OUTPUT_PREFIX. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires capture privileges and an existing monitor-mode interface.
- Writes capture files using OUTPUT_PREFIX; does not enable monitor mode or send deauthentication packets.


### Results and completion

Writes capture files with OUTPUT_PREFIX and tool-added suffixes. Stop with Ctrl+C.

[Tool documentation / source](https://www.kali.org/tools/aircrack-ng/)

<a id="module-03"></a>

## 03 / Bettercap_Network_Recon

File: Bettercap_Network_Recon.txt | Category: Traffic Analysis | Mode: Interactive terminal

Open Bettercap with network-table reconnaissance enabled; enter net.show to view discovered hosts.


### Before use

Executable in Kali PATH: bettercap. Disable Toolbox Auto-Save for direct terminal input.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| INTERFACE | Local network interface; wireless capture may need monitor mode | eth0 or wlan0mon, as appropriate |


### Command template

```text
bettercap -iface "<<INTERFACE>>" -autostart events.stream,net.recon -no-colors
```


### Options

No option toggles are defined.


### Using this module

Set INTERFACE. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires privileges. Disable Toolbox Auto-Save for the interactive console.
- Type net.show to inspect hosts and quit to exit.


### Results and completion

The command opens a terminal session. Review output there and exit the tool when finished.

[Tool documentation / source](https://www.bettercap.org/modules/ethernet/netrecon/)

<a id="module-04"></a>

## 04 / BloodHound_CE_DC_Collection

File: BloodHound_CE_DC_Collection.txt | Category: SMB / Windows | Mode: Network operation

Collect domain-controller data for BloodHound CE and create a ZIP in the current directory.


### Before use

Executable in Kali PATH: bloodhound-ce-python.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| DOMAIN | AD DNS domain, DNS search domain, or authentication domain as specified by the module | lab.example |
| IP | AD DNS server IP address | 192.0.2.53 |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| USERNAME | One account name; check domain qualification requirements | labuser |


### Command template

```text
bloodhound-ce-python -u "<<USERNAME>>" -p "<<PASSWORD>>" -d "<<DOMAIN>>" -ns <<IP>> -c DCOnly --zip <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Specify DC hostname | -dc "<<DC_HOST>>" | DC_HOST |
| 2 | Use TCP DNS | --dns-tcp | None |
| 3 | Use LDAPS | --use-ldaps | None |
| 4 | Output filename prefix | -op "<<OUTPUT_PREFIX>>" | OUTPUT_PREFIX |


### Using this module

Set DOMAIN, IP, PASSWORD, USERNAME. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- IP is the AD DNS server; DC_HOST is a hostname, not an IP. DOMAIN is the AD DNS domain.
- CE collector output is for BloodHound CE, not legacy BloodHound.


### Results and completion

Creates BloodHound CE JSON collection data and a ZIP in the working directory; import into a compatible CE instance.

[Tool documentation / source](https://www.kali.org/tools/bloodhound-ce-python/)

<a id="module-05"></a>

## 05 / BloodHound_CE_Start

File: BloodHound_CE_Start.txt | Category: Results / Reporting | Mode: Local service startup

Start the locally installed Kali BloodHound CE analysis service after its initial setup.


### Before use

Executable in Kali PATH: bloodhound-start.

No base placeholders to fill. Running this module starts its fixed command.


### Command template

```text
bloodhound-start
```


### Options

No option toggles are defined.


### Using this module

Review the fixed command and any selected options in Dry-Run before launching it.

- Requires completed bloodhound-setup and configured database services.
- This starts local services. Use bloodhound-stop separately when finished.


### Results and completion

Starts configured local services. It does not collect AD data; use the collection module separately.

[Tool documentation / source](https://www.kali.org/tools/bloodhound/)

<a id="module-06"></a>

## 06 / Bully_WPS_Test_Mode

File: Bully_WPS_Test_Mode.txt | Category: Vulnerability Assessment | Mode: Wireless test mode

Run Bully test mode for one BSSID without packet injection.


### Before use

Executable in Kali PATH: bully.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| BSSID | Access point MAC address | 02:00:00:00:00:01 |
| INTERFACE | Local network interface; wireless capture may need monitor mode | eth0 or wlan0mon, as appropriate |


### Command template

```text
bully -T -b "<<BSSID>>" <<OPTIONS>> "<<INTERFACE>>"
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Target channel | -c <<CHANNEL>> | CHANNEL |
| 2 | Write diagnostic log | -o "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set BSSID, INTERFACE. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires monitor-mode interface and root. Test mode is fixed in the command.
- This module exercises test mode; it does not perform WPS PIN recovery.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://www.kali.org/tools/bully/)

<a id="module-07"></a>

## 07 / Certipy_ADCS_Inventory

File: Certipy_ADCS_Inventory.txt | Category: SMB / Windows | Mode: Network operation

Enumerate AD certificate services and templates using DC-only queries; print findings to the terminal.


### Before use

Executable in Kali PATH: certipy-ad.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| DOMAIN | AD DNS domain, DNS search domain, or authentication domain as specified by the module | lab.example |
| IP | Domain controller IP address | 192.0.2.10 |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| USERNAME | One account name; check domain qualification requirements | labuser |


### Command template

```text
certipy-ad find -u "<<USERNAME>>@<<DOMAIN>>" -p "<<PASSWORD>>" -dc-ip <<IP>> -dc-only -stdout <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Only enabled templates | -enabled | None |
| 2 | Only potentially vulnerable templates | -vulnerable | None |


### Using this module

Set DOMAIN, IP, PASSWORD, USERNAME. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires Kali certipy-ad, not the unrelated certipy package.
- USERNAME is the account name without an @domain suffix. DC-only excludes CA host detail queries.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/ly4k/Certipy/blob/main/certipy/commands/parsers/find.py)

<a id="module-08"></a>

## 08 / CeWL_Site_Wordlist

File: CeWL_Site_Wordlist.txt | Category: Payloads / Wordlists / Cheatsheets | Mode: Network operation

Build a wordlist from one website using crawl depth two and words of at least five characters.


### Before use

Executable in Kali PATH: cewl.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| OUTPUT_FILE | Writable output filename; create its parent directory first | /home/kali/lab/results.txt |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/ |


### Command template

```text
cewl -d 2 -m 5 -w "<<OUTPUT_FILE>>" <<OPTIONS>> "<<URL>>"
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Lowercase words | --lowercase | None |
| 2 | Include words containing numbers | --with-numbers | None |


### Using this module

Set OUTPUT_FILE, URL. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- The offsite crawling option is not enabled. OUTPUT_FILE is the generated wordlist.


### Results and completion

Writes the collected wordlist to OUTPUT_FILE.

[Tool documentation / source](https://www.kali.org/tools/cewl/)

<a id="module-09"></a>

## 09 / Chisel_Server

File: Chisel_Server.txt | Category: Shell / Session Tools | Mode: Ongoing capture / connection

Start an authenticated Chisel listener on an explicit address for forward TCP tunnels.


### Before use

Executable in Kali PATH: chisel.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| LISTEN_HOST | Local interface address to bind a listener | The intended local interface address |
| LISTEN_PORT | Single listener port | 8081 |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| USERNAME | One account name; check domain qualification requirements | labuser |


### Command template

```text
chisel server --host "<<LISTEN_HOST>>" --port <<LISTEN_PORT>> --auth "<<USERNAME>>:<<PASSWORD>>" <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Enable SOCKS5 service | --socks5 | None |
| 2 | Verbose output | -v | None |


### Using this module

Set LISTEN_HOST, LISTEN_PORT, PASSWORD, USERNAME. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Ongoing listener. Use the printed server fingerprint in the client.
- Authentication values use username:password syntax; choose a username without colons.


### Results and completion

Runs in the foreground until stopped. Review its console output and any configured output files; Ctrl+C normally stops it.

[Tool documentation / source](https://github.com/jpillora/chisel)

<a id="module-10"></a>

## 10 / Chisel_TCP_Client

File: Chisel_TCP_Client.txt | Category: Shell / Session Tools | Mode: Ongoing capture / connection

Forward one localhost TCP port through an authenticated Chisel server with fingerprint verification.


### Before use

Executable in Kali PATH: chisel.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| DEST_HOST | Destination reached by the forwarding endpoint | 192.0.2.20 |
| DEST_PORT | Single destination TCP port | 8080 |
| LOCAL_PORT | Local TCP port for the forwarder | 18080 |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| SERVER_FINGERPRINT | Chisel server fingerprint; different from Ligolo certificate fingerprint | Copy the verified Chisel server fingerprint |
| SERVER_URL | URL of an already running Chisel server | http://192.0.2.30:8081 |
| USERNAME | One account name; check domain qualification requirements | labuser |


### Command template

```text
chisel client --auth "<<USERNAME>>:<<PASSWORD>>" --fingerprint "<<SERVER_FINGERPRINT>>" <<OPTIONS>> "<<SERVER_URL>>" "127.0.0.1:<<LOCAL_PORT>>:<<DEST_HOST>>:<<DEST_PORT>>"
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Verbose output | -v | None |


### Using this module

Set DEST_HOST, DEST_PORT, LOCAL_PORT, PASSWORD, SERVER_FINGERPRINT, SERVER_URL, USERNAME. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- SERVER_URL points to an existing Chisel server. DEST_HOST is resolved/reached from that server.
- LOCAL_PORT binds only to 127.0.0.1. IPv4/hostnames only in the composed forwarding address.


### Results and completion

Runs in the foreground until stopped. Review its console output and any configured output files; Ctrl+C normally stops it.

[Tool documentation / source](https://github.com/jpillora/chisel)

<a id="module-11"></a>

## 11 / Crunch_Character_Wordlist

File: Crunch_Character_Wordlist.txt | Category: Payloads / Wordlists / Cheatsheets | Mode: Local / offline

Generate combinations from an explicit character set and length bounds into a local file.


### Before use

Executable in Kali PATH: crunch.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| CHARSET | Characters Crunch may combine | abc |
| MAX_LENGTH | Maximum Crunch output word length | 3 |
| MIN_LENGTH | Minimum Crunch output word length | 2 |
| OUTPUT_FILE | Writable output filename; create its parent directory first | /home/kali/lab/results.txt |


### Command template

```text
crunch <<MIN_LENGTH>> <<MAX_LENGTH>> "<<CHARSET>>" -o "<<OUTPUT_FILE>>"
```


### Options

No option toggles are defined.


### Using this module

Set CHARSET, MAX_LENGTH, MIN_LENGTH, OUTPUT_FILE. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Use small lengths first; output grows exponentially. Example: min 2, max 3, charset abc.
- MIN_LENGTH and MAX_LENGTH are positive integers, with minimum no greater than maximum.


### Results and completion

Writes generated combinations to OUTPUT_FILE; output size grows exponentially.

[Tool documentation / source](https://www.kali.org/tools/crunch/)

<a id="module-12"></a>

## 12 / Dirsearch_Content

File: Dirsearch_Content.txt | Category: Web Enumeration | Mode: Network operation

Discover paths under one URL with five threads and a ten-request-per-second limit.


### Before use

Executable in Kali PATH: dirsearch.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/ |
| WORDLIST | Local list appropriate to the action: paths, labels, or password candidates | /home/kali/lab/wordlist.txt |


### Command template

```text
dirsearch -u "<<URL>>" -w "<<WORDLIST>>" -t 5 --max-rate 10 <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Try extensions on every word | -e "<<EXTENSIONS>>" -f | EXTENSIONS |
| 2 | Recurse two levels | -r -R 2 | None |
| 3 | Exclude status codes | -x "<<HIDE_CODES>>" | HIDE_CODES |
| 4 | Write JSON report | --format json -o "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set URL, WORDLIST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- EXTENSIONS and HIDE_CODES are comma-separated. Existing dirsearch config may also affect behavior.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://www.kali.org/tools/dirsearch/)

<a id="module-13"></a>

## 13 / EvilWinRM_Password_Session

File: EvilWinRM_Password_Session.txt | Category: Shell / Session Tools | Mode: Interactive terminal

Open an interactive WinRM session with supplied credentials; defaults to HTTP port 5985.


### Before use

Executable in Kali PATH: evil-winrm. Disable Toolbox Auto-Save for direct terminal input.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| IP | Target host; BloodHound uses it for AD DNS and Certipy/AD Impacket for the DC | 192.0.2.10 |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| USERNAME | One account name; check domain qualification requirements | labuser |


### Command template

```text
evil-winrm -i "<<IP>>" -u "<<USERNAME>>" -p "<<PASSWORD>>" <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Use HTTPS on port 5986 | -S -P 5986 | None |


### Using this module

Set IP, PASSWORD, USERNAME. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Disable Toolbox Auto-Save for terminal interaction. Type exit to disconnect.
- USERNAME may be domain-qualified when needed.


### Results and completion

The command opens a terminal session. Review output there and exit the tool when finished.

[Tool documentation / source](https://github.com/Hackplayers/evil-winrm)

<a id="module-14"></a>

## 14 / Feroxbuster_Content

File: Feroxbuster_Content.txt | Category: Web Enumeration | Mode: Network operation

Discover content with recursion depth two, five workers, one active scan, and ten requests per second per directory.


### Before use

Executable in Kali PATH: feroxbuster.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/ |
| WORDLIST | Local list appropriate to the action: paths, labels, or password candidates | /home/kali/lab/wordlist.txt |


### Command template

```text
feroxbuster -u "<<URL>>" -w "<<WORDLIST>>" -t 5 --scan-limit 1 --rate-limit 10 -d 2 <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Disable recursion | --no-recursion | None |
| 2 | Try extensions | -x "<<EXTENSIONS>>" | EXTENSIONS |
| 3 | Write JSON report | --json -o "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set URL, WORDLIST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- EXTENSIONS is comma-separated. Confirm extracted links and recursion stay in your desired URL scope.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://www.kali.org/tools/feroxbuster/)

<a id="module-15"></a>

## 15 / FFUF_URL_Fuzzing

File: FFUF_URL_Fuzzing.txt | Category: Web Enumeration | Mode: Network operation

Discover URL paths or parameter values using a wordlist and one literal FUZZ position in URL.


### Before use

Executable in Kali PATH: ffuf.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/FUZZ |
| WORDLIST | Local list appropriate to the action: paths, labels, or password candidates | /home/kali/lab/wordlist.txt |


### Command template

```text
ffuf -u "<<URL>>" -w "<<WORDLIST>>" -t 5 -rate 10 -noninteractive <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Calibrate response filters | -ac | None |
| 2 | Hide status codes | -fc "<<HIDE_CODES>>" | HIDE_CODES |
| 3 | Hide response sizes | -fs "<<HIDE_SIZES>>" | HIDE_SIZES |
| 4 | Write JSON report | -of json -o "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set URL, WORDLIST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Set URL to a template such as https://host.example/FUZZ. FUZZ is an ffuf keyword, not a Toolbox placeholder.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/ffuf/ffuf)

<a id="module-16"></a>

## 16 / FFUF_Virtual_Hosts

File: FFUF_Virtual_Hosts.txt | Category: Web Enumeration | Mode: Network operation

Test subdomain labels in HTTP Host headers against one URL; review wildcard responses.


### Before use

Executable in Kali PATH: ffuf.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| DOMAIN | AD DNS domain, DNS search domain, or authentication domain as specified by the module | lab.example |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/ |
| WORDLIST | Local file of subdomain labels, one per line | /home/kali/lab/subdomains.txt |


### Command template

```text
ffuf -u "<<URL>>" -H "Host: FUZZ.<<DOMAIN>>" -w "<<WORDLIST>>" -t 5 -rate 10 -noninteractive <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Calibrate response filters | -ac | None |
| 2 | Hide response sizes | -fs "<<HIDE_SIZES>>" | HIDE_SIZES |
| 3 | Write JSON report | -of json -o "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set DOMAIN, URL, WORDLIST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- WORDLIST contains labels, such as dev, not complete domain names.
- URL selects the server and HTTPS SNI; changing Host does not change SNI.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/ffuf/ffuf)

<a id="module-17"></a>

## 17 / Gobuster_Directories

File: Gobuster_Directories.txt | Category: Web Enumeration | Mode: Network operation

Discover directories and files under one URL with five threads and a per-thread request delay.


### Before use

Executable in Kali PATH: gobuster.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/ |
| WORDLIST | Local list appropriate to the action: paths, labels, or password candidates | /home/kali/lab/wordlist.txt |


### Command template

```text
gobuster dir -u "<<URL>>" -w "<<WORDLIST>>" -t 5 --delay 500ms <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Try file extensions | -x "<<EXTENSIONS>>" | EXTENSIONS |
| 2 | Include response length | -l | None |
| 3 | Write results | -o "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set URL, WORDLIST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- EXTENSIONS is comma-separated, such as php,html,txt.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/OJ/gobuster)

<a id="module-18"></a>

## 18 / Gobuster_DNS

File: Gobuster_DNS.txt | Category: Network / DNS | Mode: Network operation

Resolve wordlist subdomains within one domain using five workers.


### Before use

Executable in Kali PATH: gobuster.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| DOMAIN | AD DNS domain, DNS search domain, or authentication domain as specified by the module | lab.example |
| WORDLIST | Local file of subdomain labels, one per line | /home/kali/lab/subdomains.txt |


### Command template

```text
gobuster dns --domain "<<DOMAIN>>" -w "<<WORDLIST>>" -t 5 <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Custom resolver host and port | -r "<<DNS_RESOLVER>>" | DNS_RESOLVER |
| 2 | Write results | -o "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set DOMAIN, WORDLIST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- WORDLIST contains subdomain labels. DNS_RESOLVER example: 192.0.2.53:53.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/OJ/gobuster)

<a id="module-19"></a>

## 19 / Hashcat Dictionary Attack

File: Hashcat.txt | Category: Pass/Hash Cracking | Mode: Local / offline

Run a configurable Hashcat dictionary attack against a local hash file.


### Before use

Executable in Kali PATH: hashcat.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| HASH_FILE | Existing local hash file | /home/kali/lab/hashes.txt |
| WORDLIST | Local password-candidate file | /home/kali/lab/passwords.txt |


### Command template

```text
hashcat <<OPTIONS>> <<HASH_FILE>> <<WORDLIST>> <<OPTIONS2>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Hash Mode | -m <<HASH_MODE>> | HASH_MODE |
| 2 | Attack Mode | -a <<ATTACK_MODE>> | ATTACK_MODE |
| 3 | Username Field Present | --username | None |
| 4 | Workload Profile | -w <<WORKLOAD_PROFILE>> | WORKLOAD_PROFILE |

options2 (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 5 | Show Status | --status | None |
| 6 | Status Timer | --status-timer=<<STATUS_TIMER>> | STATUS_TIMER |
| 7 | Output Cracked Passwords | -o <<OUTPUT_FILE>> | OUTPUT_FILE |
| 8 | Use Rule File | -r <<RULE_FILE>> | RULE_FILE |


### Using this module

Set HASH_FILE and WORDLIST. Enable Hash Mode with the matching identifier and Attack Mode with value 0, then inspect Dry-Run.

- Enable Hash Mode and choose the identifier for your hash file. Enable Attack Mode with value 0 to explicitly select a straight dictionary attack; the fixed hash-file/wordlist layout is not a general interface to every Hashcat attack mode.
- All toggles are off initially, including mode selection. Defaults and hash autodetection vary by installed version. Enable Show Status if you also enable Status Timer. Rule File is intended for a compatible wordlist attack.
- Requires Hashcat and a working supported compute backend. It reads local hashes; an enabled output option can write recovered passwords.


### Results and completion

Processes local data and prints results. Any enabled output option determines an additional output file.

[Tool documentation / source](https://www.kali.org/tools/hashcat/)

<a id="module-20"></a>

## 20 / Hydra_HTTPS

File: Hydra_HTTPS.txt | Category: Pass/Hash Cracking | Mode: Network operation

Hydra is a powerful tool used for performing brute-force attacks on various network services, including HTTPS.


### Before use

Executable in Kali PATH: hydra.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| URL | Hydra service URI for the specific HTTP authentication mechanism | https-get://web.lab.example/protected/ |
| USERNAME | One account name; check domain qualification requirements | labuser |
| WORDLIST | Local password-candidate file | /home/kali/lab/passwords.txt |


### Command template

```text
hydra -l <<USERNAME>> -P <<WORDLIST>> <<OPTIONS>> <<URL>> <<OPTIONS2>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Port | -s <<PORT>> | PORT |

options2 (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 2 | Stop on success | -f | None |


### Using this module

Set USERNAME and a password WORDLIST. Use a module-local URL override with the required Hydra service URI; select Stop on success if desired, then inspect Dry-Run.

- The URL field must use Hydra service syntax, such as https-get://web.lab.example/protected/. An ordinary https:// URL does not identify the Hydra authentication module.
- This definition does not configure HTML form fields or a success/failure condition. A website login form needs a separate form-specific definition; do not treat this as a universal HTTPS login checker.
- WORDLIST is a password-candidate file for one USERNAME. Stop on success is initially off. This sends repeated authentication requests and uses Hydra concurrency defaults.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/vanhauser-thc/thc-hydra#how-to-use)

<a id="module-21"></a>

## 21 / Hydra_SSH

File: Hydra_SSH.txt | Category: Pass/Hash Cracking | Mode: Network operation

Hydra is a powerful tool used for performing brute-force attacks on various network services, including SSH (Secure Shell).


### Before use

Executable in Kali PATH: hydra.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| IP | Target host; BloodHound uses it for AD DNS and Certipy/AD Impacket for the DC | 192.0.2.10 |
| USERNAME | One account name; check domain qualification requirements | labuser |
| WORDLIST | Local password-candidate file | /home/kali/lab/passwords.txt |


### Command template

```text
hydra -l <<USERNAME>> -P <<WORDLIST>> <<OPTIONS>> <<IP>> ssh <<OPTIONS2>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Port | -s <<PORT>> | PORT |

options2 (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 2 | Stop on success | -f | None |


### Using this module

Set IP, USERNAME, WORDLIST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- WORDLIST is a password-candidate file for one USERNAME, not a username list. The base service is SSH; use the Port toggle for a nonstandard port.
- Stop on success is initially off. This sends repeated authentication attempts; the module does not set a worker limit or an overall time limit.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/vanhauser-thc/thc-hydra#how-to-use)

<a id="module-22"></a>

## 22 / Impacket_AD_Computers

File: Impacket_AD_Computers.txt | Category: SMB / Windows | Mode: Network operation

List AD computer accounts, DNS hostnames, and operating system details, with optional DNS resolution.


### Before use

Executable in Kali PATH: GetADComputers.py. Kali may instead expose an impacket- prefixed executable; verify the actual installed name.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| DOMAIN | AD DNS domain, DNS search domain, or authentication domain as specified by the module | lab.example |
| IP | Domain controller IP address | 192.0.2.10 |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| USERNAME | One account name; check domain qualification requirements | labuser |


### Command template

```text
GetADComputers.py "<<DOMAIN>>/<<USERNAME>>:<<PASSWORD>>" -dc-ip <<IP>> <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Resolve computer IP addresses through DC DNS | -resolveIP | None |
| 2 | Specify domain controller hostname | -dc-host "<<DC_HOST>>" | DC_HOST |
| 3 | Timestamp log messages | -ts | None |


### Using this module

Set DOMAIN, IP, PASSWORD, USERNAME. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Dependency: GetADComputers.py in PATH (Kali commonly uses impacket-GetADComputers).
- If needed, change only the executable at the start of Command.
- IP must be a single domain controller IP; DOMAIN must be the AD DNS domain.
- Resolve IP addresses queries DNS on that domain controller.
- Verify with Dry-Run and GetADComputers.py -h before use.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/fortra/impacket/blob/master/examples/GetADComputers.py)

<a id="module-23"></a>

## 23 / Impacket_AD_Users

File: Impacket_AD_Users.txt | Category: SMB / Windows | Mode: Network operation

Query AD user names, email addresses, last logon, and password-set times using supplied domain credentials.


### Before use

Executable in Kali PATH: GetADUsers.py. Kali may instead expose an impacket- prefixed executable; verify the actual installed name.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| DOMAIN | AD DNS domain, DNS search domain, or authentication domain as specified by the module | lab.example |
| IP | Domain controller IP address | 192.0.2.10 |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| USERNAME | One account name; check domain qualification requirements | labuser |


### Command template

```text
GetADUsers.py "<<DOMAIN>>/<<USERNAME>>:<<PASSWORD>>" -dc-ip <<IP>> <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Include disabled users and users without email | -all | None |
| 2 | Filter by account name | -user "<<ACCOUNT_NAME>>" | ACCOUNT_NAME |
| 3 | Specify domain controller hostname | -dc-host "<<DC_HOST>>" | DC_HOST |
| 4 | Timestamp log messages | -ts | None |


### Using this module

Set DOMAIN, IP, PASSWORD, USERNAME. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Dependency: GetADUsers.py in PATH (Kali commonly uses impacket-GetADUsers).
- If needed, change only the executable at the start of Command.
- IP must be a single domain controller IP; DOMAIN must be the AD DNS domain.
- Use a single username. PASSWORD uses Toolbox's protected placeholder.
- With toggles OFF, lists enabled users with email addresses.
- Verify with Dry-Run and GetADUsers.py -h before use.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/fortra/impacket/blob/master/examples/GetADUsers.py)

<a id="module-24"></a>

## 24 / Impacket_RPC_Endpoints

File: Impacket_RPC_Endpoints.txt | Category: Service Enumeration | Mode: Network operation

List RPC endpoint UUIDs, bindings, and known providers on one host through the TCP endpoint mapper.


### Before use

Executable in Kali PATH: rpcdump.py. Kali may instead expose an impacket- prefixed executable; verify the actual installed name.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| IP | Target host; BloodHound uses it for AD DNS and Certipy/AD Impacket for the DC | 192.0.2.10 |


### Command template

```text
rpcdump.py <<IP>> <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Use RPC over HTTP port 593 | -port 593 | None |
| 2 | Timestamp log messages | -ts | None |


### Using this module

Set IP. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Dependency: rpcdump.py in PATH (Kali commonly uses impacket-rpcdump).
- IP must be one host, not a CIDR range. Default transport is TCP 135.
- This module uses the unauthenticated TCP endpoint mapper transport.
- Verify with Dry-Run and rpcdump.py -h before use.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/fortra/impacket/blob/master/examples/rpcdump.py)

<a id="module-25"></a>

## 25 / Impacket_SID_Lookup

File: Impacket_SID_Lookup.txt | Category: SMB / Windows | Mode: Network operation

Resolve account and group names by enumerating RIDs over SMB using supplied credentials; defaults to RIDs below 4000.


### Before use

Executable in Kali PATH: lookupsid.py. Kali may instead expose an impacket- prefixed executable; verify the actual installed name.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| DOMAIN | AD DNS domain, DNS search domain, or authentication domain as specified by the module | lab.example |
| IP | Target host; BloodHound uses it for AD DNS and Certipy/AD Impacket for the DC | 192.0.2.10 |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| USERNAME | One account name; check domain qualification requirements | labuser |


### Command template

```text
lookupsid.py "<<DOMAIN>>/<<USERNAME>>:<<PASSWORD>>@<<IP>>" <<OPTIONS>> <<OPTIONS2>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Custom RID upper bound | <<MAX_RID>> | MAX_RID |

options2 (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 2 | Query primary domain SID | -domain-sids | None |
| 3 | Use SMB port 139 instead of 445 | -port 139 | None |
| 4 | Timestamp log messages | -ts | None |


### Using this module

Set DOMAIN, IP, PASSWORD, USERNAME. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Dependency: lookupsid.py in PATH (Kali commonly uses impacket-lookupsid).
- IP must be one host. DOMAIN is the authentication domain or local computer name.
- Default RID upper bound is 4000 (exclusive); custom MAX_RID must be positive.
- This enumerates account identifiers through RPC; it does not guess passwords.
- Domain SID mode may forward lookup requests to a domain controller.
- Verify with Dry-Run and lookupsid.py -h before use.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/fortra/impacket/blob/master/examples/lookupsid.py)

<a id="module-26"></a>

## 26 / John Show Cracked

File: John Show Cracked.txt | Category: Pass/Hash Cracking | Mode: Local / offline

Display passwords already recovered by John for a local hash file.


### Before use

Executable in Kali PATH: john.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| HASH_FILE | Existing local hash file | /home/kali/lab/hashes.txt |


### Command template

```text
john --show <<OPTIONS>> <<HASH_FILE>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Hash Format | --format=<<FORMAT>> | FORMAT |


### Using this module

Set HASH_FILE. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- This displays results already recorded in John's potfile for the supplied hash file; it does not launch a new cracking run.
- Run under the same Kali account and configuration as the recovery session so it uses the expected potfile. The output contains recovered passwords.


### Results and completion

Prints already-recovered credentials associated with the hash file.

[Tool documentation / source](https://www.kali.org/tools/john/)

<a id="module-27"></a>

## 27 / John the Ripper

File: John the Ripper.txt | Category: Pass/Hash Cracking | Mode: Local / offline

Run John the Ripper against a local hash file using a wordlist.


### Before use

Executable in Kali PATH: john.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| HASH_FILE | Existing local hash file | /home/kali/lab/hashes.txt |


### Command template

```text
john <<OPTIONS>> <<HASH_FILE>> <<OPTIONS2>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Wordlist | --wordlist=<<WORDLIST>> | WORDLIST |
| 2 | Hash Format | --format=<<FORMAT>> | FORMAT |
| 3 | Rules | --rules=<<RULESET>> | RULESET |

options2 (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 4 | Session Name | --session=<<SESSION_NAME>> | SESSION_NAME |
| 5 | Fork Processes | --fork=<<FORK_COUNT>> | FORK_COUNT |


### Using this module

Set HASH_FILE, enable Wordlist and set WORDLIST. Select Hash Format if needed, then inspect Dry-Run.

- Enable the Wordlist toggle for the dictionary workflow described by the module. With all toggles off, the command is just john HASH_FILE and does not explicitly select a wordlist.
- Hash Format must match the file if autodetection is ambiguous. Rules names refer to installed John configuration. Enable Session Name to identify a run; this definition does not provide a restore toggle.
- Use John Show Cracked afterwards with the same hash file and matching format. Fork Processes increases local resource use.


### Results and completion

Processes local data and prints results. Any enabled output option determines an additional output file.

[Tool documentation / source](https://www.kali.org/tools/john/)

<a id="module-28"></a>

## 28 / Kerbrute_User_Enumeration

File: Kerbrute_User_Enumeration.txt | Category: SMB / Windows | Mode: Network operation

Check domain usernames through Kerberos using a 500ms delay and stop-on-lockout mode.


### Before use

Executable in Kali PATH: kerbrute.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| DOMAIN | AD DNS domain, DNS search domain, or authentication domain as specified by the module | lab.example |
| IP | Domain controller IP address | 192.0.2.10 |
| USERLIST | Existing list of account names, one per line | /home/kali/lab/users.txt |


### Command template

```text
kerbrute userenum -d "<<DOMAIN>>" --dc <<IP>> --delay 500 --safe "<<USERLIST>>" <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Write results | -o "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set DOMAIN, IP, USERLIST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires ropnop Kerbrute Go binary named kerbrute in PATH.
- USERLIST contains account names. This is user enumeration, not password spraying.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/ropnop/kerbrute)

<a id="module-29"></a>

## 29 / Kismet_Wireless_Capture

File: Kismet_Wireless_Capture.txt | Category: Traffic Analysis | Mode: Ongoing capture / connection

Start Kismet with one capture interface; use its configured web interface to inspect devices.


### Before use

Executable in Kali PATH: kismet.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| INTERFACE | Local network interface; wireless capture may need monitor mode | eth0 or wlan0mon, as appropriate |


### Command template

```text
kismet -c "<<INTERFACE>>"
```


### Options

No option toggles are defined.


### Using this module

Set INTERFACE. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires Kismet capture permissions and supported hardware.
- Reads installed Kismet configuration, starts its configured web listener, and writes configured logs. Ctrl+C stops it.


### Results and completion

Runs in the foreground until stopped. Review its console output and any configured output files; Ctrl+C normally stops it.

[Tool documentation / source](https://www.kali.org/tools/kismet/)

<a id="module-30"></a>

## 30 / Ligolo_Agent

File: Ligolo_Agent.txt | Category: Shell / Session Tools | Mode: Ongoing capture / connection

Connect the local Ligolo agent to a proxy and verify its supplied certificate fingerprint.


### Before use

Executable in Kali PATH: ligolo-agent.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| CERT_FINGERPRINT | Ligolo proxy certificate SHA256 hex fingerprint | Copy the verified proxy fingerprint |
| PROXY_HOST | Ligolo proxy hostname or IP | 192.0.2.30 |
| PROXY_PORT | Ligolo proxy listener port | 11601 |


### Command template

```text
ligolo-agent -connect "<<PROXY_HOST>>:<<PROXY_PORT>>" -accept-fingerprint "<<CERT_FINGERPRINT>>" <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Verbose output | -v | None |


### Using this module

Set CERT_FINGERPRINT, PROXY_HOST, PROXY_PORT. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Runs on this Kali host; copy/use on a different host only if that is where the agent should execute.
- CERT_FINGERPRINT is the proxy certificate SHA256 hex fingerprint. Connection does not configure routes.


### Results and completion

Runs in the foreground until stopped. Review its console output and any configured output files; Ctrl+C normally stops it.

[Tool documentation / source](https://www.kali.org/tools/ligolo-ng/)

<a id="module-31"></a>

## 31 / Ligolo_Proxy

File: Ligolo_Proxy.txt | Category: Shell / Session Tools | Mode: Interactive terminal

Start the Ligolo proxy console on an explicit listening address with a generated self-signed certificate.


### Before use

Executable in Kali PATH: ligolo-proxy. Disable Toolbox Auto-Save for direct terminal input.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| LISTEN_HOST | Local interface address to bind a listener | The intended local interface address |
| LISTEN_PORT | Single listener port | 8081 |


### Command template

```text
ligolo-proxy -laddr "<<LISTEN_HOST>>:<<LISTEN_PORT>>" -selfcert <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Verbose output | -v | None |


### Using this module

Set LISTEN_HOST, LISTEN_PORT. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Ongoing listener. Disable Auto-Save for console use. Select a reachable LISTEN_HOST explicitly.
- Agent connection, TUN interface and route configuration are separate prerequisites/console steps; see Ligolo docs.


### Results and completion

The command opens a terminal session. Review output there and exit the tool when finished.

[Tool documentation / source](https://www.kali.org/tools/ligolo-ng/)

<a id="module-32"></a>

## 32 / Medusa_Single_Credential

File: Medusa_Single_Credential.txt | Category: Service Enumeration | Mode: Network operation

Test one supplied username/password against one selected service with one worker and no connection retries.


### Before use

Executable in Kali PATH: medusa.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| IP | Target host; BloodHound uses it for AD DNS and Certipy/AD Impacket for the DC | 192.0.2.10 |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| SERVICE_MODULE | Installed Medusa service module name | ssh |
| USERNAME | One account name; check domain qualification requirements | labuser |


### Command template

```text
medusa -h "<<IP>>" -u "<<USERNAME>>" -p "<<PASSWORD>>" -M "<<SERVICE_MODULE>>" -t 1 -T 1 -R 0 -f <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Custom service port | -n <<PORT>> | PORT |
| 2 | Enable service SSL | -s | None |


### Using this module

Set IP, PASSWORD, SERVICE_MODULE, USERNAME. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- SERVICE_MODULE is an installed Medusa module, such as ssh or ftp; medusa -d lists modules.
- One credential pair is supplied. Authentication affects account lockout counters and may be logged by the service.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://www.kali.org/tools/medusa/)

<a id="module-33"></a>

## 33 / Mimikatz_Identity_Windows

File: Mimikatz_Identity_Windows.txt | Category: SMB / Windows | Mode: Windows through SSH

Run Mimikatz version and current-token identity commands on a Windows SSH host, then exit.


### Before use

Python 3 and helpers/security_pack.py. The installed module still contains PACK_HELPER, so supply its absolute Kali path or use the pack installer.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| PACK_HELPER | Absolute Linux path to security_pack.py | /home/kali/tool_box/ToolBoxhelpers/kali_module_pack/security_pack.py |
| SSH_USER | Login on the Windows SSH host; separate from Toolbox target credentials | laboperator |
| WINDOWS_EXE | Absolute executable path on Windows, not Kali | C:\LabTools\mimikatz.exe |
| WINDOWS_HOST | Existing Windows SSH host | win01.lab.example |


### Command template

```text
python3 "<<PACK_HELPER>>" windows --host "<<WINDOWS_HOST>>" --user "<<SSH_USER>>" --exe "<<WINDOWS_EXE>>" --tool mimikatz <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Preview remote invocation only | --preview | None |


### Using this module

Set PACK_HELPER, SSH_USER, WINDOWS_EXE, WINDOWS_HOST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires the included helper, a Windows SSH host, and the named executable installed on Windows.
- WINDOWS_EXE is an absolute Windows path. No binaries are installed or uploaded.
- SSH uses normal host-key checks and SSH authentication; see README for prerequisites.
- This module reports identity; it does not dump credentials.


### Results and completion

Prints version and identity information from the Windows execution context, then exits.

[Tool documentation / source](https://github.com/gentilkiwi/mimikatz/tree/master/mimikatz/modules)

<a id="module-34"></a>

## 34 / msfconsole

File: msfconsole.txt | Category: Exploit | Mode: Interactive terminal

Metasploit’s interactive command-line interface for searching, configuring, and running authorized security-testing modules.


### Before use

Executable in Kali PATH: msfconsole. Disable Toolbox Auto-Save for direct terminal input.

No base placeholders to fill. Running this module starts its fixed command.


### Command template

```text
msfconsole <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Quiet | -q | None |


### Using this module

Review the fixed command and any selected options in Dry-Run before launching it.

- This launches the Metasploit console; it does not automatically select or run an exploit. Quiet suppresses the startup banner.
- Disable Toolbox Auto-Save for terminal interaction. Use help inside the console and exit to close it.


### Results and completion

The command opens a terminal session. Review output there and exit the tool when finished.

[Tool documentation / source](https://www.kali.org/tools/metasploit-framework/)

<a id="module-35"></a>

## 35 / Ncrack_Single_Credential

File: Ncrack_Single_Credential.txt | Category: Service Enumeration | Mode: Network operation

Test one credential pair against one service endpoint with one connection and a 30-second limit.


### Before use

Executable in Kali PATH: ncrack.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| IP | Target host; BloodHound uses it for AD DNS and Certipy/AD Impacket for the DC | 192.0.2.10 |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| PORT | One port number for these modules; not a port list/range | 22 when SERVICE is ssh |
| SERVICE | Ncrack service identifier | ssh |
| USERNAME | One account name; check domain qualification requirements | labuser |


### Command template

```text
ncrack --user "<<USERNAME>>" --pass "<<PASSWORD>>" --connection-limit 1 -g cl=1,CL=1,at=1,cr=0,to=30s -f "<<SERVICE>>://<<IP>>:<<PORT>>" <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | List endpoint without authentication | -sL | None |


### Using this module

Set IP, PASSWORD, PORT, SERVICE, USERNAME. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- SERVICE example: ssh. IP is one host; PORT is one integer.
- Ncrack treats commas as credential-list separators; this module cannot represent a single username/password containing a comma.
- The service may record authentication failures or successes.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://www.kali.org/tools/ncrack/)

<a id="module-36"></a>

## 36 / NXC_SMB_Enumeration

File: NetExec.txt | Category: SMB / Windows | Mode: Network operation

Discover SMB host details and optionally enumerate shares, accounts, groups, sessions, and password policy. Choose only one authentication toggle; enumeration may require credentials.


### Before use

Executable in Kali PATH: nxc.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| IP | Target host; BloodHound uses it for AD DNS and Certipy/AD Impacket for the DC | 192.0.2.10 |


### Command template

```text
nxc smb <<IP>> <<OPTIONS>> <<OPTIONS2>> <<OPTIONS3>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Username and password | -u "<<USERNAME>>" -p "<<PASSWORD>>" | PASSWORD, USERNAME |
| 2 | Domain username and password | -u "<<USERNAME>>" -p "<<PASSWORD>>" -d "<<DOMAIN>>" | DOMAIN, PASSWORD, USERNAME |
| 3 | Local username and password | -u "<<USERNAME>>" -p "<<PASSWORD>>" --local-auth | PASSWORD, USERNAME |

options2 (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 4 | List shares | --shares | None |
| 5 | List domain users | --users | None |
| 6 | List domain groups | --groups | None |
| 7 | List local groups | --local-groups | None |
| 8 | List computer accounts | --computers | None |
| 9 | Show password policy | --pass-pol | None |
| 10 | List SMB sessions | --smb-sessions | None |
| 11 | List disks | --disks | None |
| 12 | List network interfaces | --interfaces | None |
| 13 | List logged-on users | --loggedon-users | None |

options3 (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 14 | Custom SMB port (single number) | --port <<PORT>> | PORT |
| 15 | SMB timeout in seconds | --smb-timeout <<SMB_TIMEOUT>> | SMB_TIMEOUT |
| 16 | Export domain users to file | --users-export "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set IP. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires NetExec (nxc) in PATH. Check installed flags with: nxc smb --help
- With all toggles OFF, reports basic SMB host information.
- Choose at most ONE authentication option in options:.
- Use single account values for USERNAME and PASSWORD, not credential files.
- Set IP to a host/IP or CIDR target; use C for a module-local override.
- Enumeration permissions depend on the target and supplied account.
- PORT must be one integer for this module, not a list or range.
- Test the resolved command with Toolbox Dry-Run before running.
- The file is NetExec.txt, but the Toolbox menu name is NXC_SMB_Enumeration. With every toggle off, the base command requests SMB host information without a supplied login.
- Choose at most one of the three authentication toggles. Enumeration options are independent and may need different permissions; selecting a toggle does not grant them.
- Its IP input can accept a NetExec target expression, including CIDR. Its Port option still accepts only one numeric SMB port.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

<a id="module-37"></a>

## 37 / Nikto_Web_Audit

File: Nikto_Web_Audit.txt | Category: Vulnerability Assessment | Mode: Network operation

Run a web-server audit with a one-second pause and ten-minute maximum runtime.


### Before use

Executable in Kali PATH: nikto.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/ |


### Command template

```text
nikto -host "<<URL>>" -Pause 1 -maxtime 10m -ask no -nointeractive <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Write HTML report | -Format htm -output "<<OUTPUT_FILE>>" | OUTPUT_FILE |
| 2 | Choose tuning categories | -Tuning "<<TUNING>>" | TUNING |


### Using this module

Set URL. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- TUNING uses Nikto category codes; inspect nikto -Help. Report parent directory must exist.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://www.kali.org/tools/nikto/)

<a id="module-38"></a>

## 38 / Nuclei_Selected_Templates

File: Nuclei_Selected_Templates.txt | Category: Vulnerability Assessment | Mode: Network operation

Scan one URL using an explicitly selected local template file or directory; 10 requests per second.


### Before use

Executable in Kali PATH: nuclei.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| TEMPLATE_PATH | Local Nuclei template file or directory | /home/kali/lab/templates/check.yaml |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/ |


### Command template

```text
nuclei -u "<<URL>>" -t "<<TEMPLATE_PATH>>" -rl 10 -c 2 -ni <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Filter severity | -severity "<<SEVERITY>>" | SEVERITY |
| 2 | Write JSONL findings | -jsonl-export "<<OUTPUT_FILE>>" | OUTPUT_FILE |
| 3 | Show scan statistics | -stats | None |


### Using this module

Set TEMPLATE_PATH, URL. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- TEMPLATE_PATH must select reviewed installed templates. Severity is a comma-separated list.
- Out-of-band Interactsh tests are disabled by -ni. Templates determine scan behavior.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://github.com/projectdiscovery/nuclei#command-line-flags)

<a id="module-39"></a>

## 39 / Nuclei_Validate_Templates

File: Nuclei_Validate_Templates.txt | Category: Command-Line Utilities | Mode: Local / offline

Validate a local Nuclei template file or directory without scanning a target.


### Before use

Executable in Kali PATH: nuclei.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| TEMPLATE_PATH | Local Nuclei template file or directory | /home/kali/lab/templates/check.yaml |


### Command template

```text
nuclei -validate -t "<<TEMPLATE_PATH>>"
```


### Options

No option toggles are defined.


### Using this module

Set TEMPLATE_PATH. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.


### Results and completion

Processes local data and prints results. Any enabled output option determines an additional output file.

[Tool documentation / source](https://github.com/projectdiscovery/nuclei#command-line-flags)

<a id="module-40"></a>

## 40 / ProxyChains_HTTP_Check

File: ProxyChains_HTTP_Check.txt | Category: Network / DNS | Mode: Network operation

Request HTTP response headers through a supplied ProxyChains configuration.


### Before use

Executable in Kali PATH: proxychains4. Also requires curl and an existing proxy configuration.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| PROXYCHAINS_CONFIG | Existing ProxyChains configuration file | /home/kali/lab/proxychains.conf |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/ |


### Command template

```text
proxychains4 -f "<<PROXYCHAINS_CONFIG>>" <<OPTIONS>> curl --head --max-time 30 "<<URL>>"
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Quiet ProxyChains diagnostics | -q | None |


### Using this module

Set PROXYCHAINS_CONFIG, URL. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires proxychains4 and a dynamically linked curl executable.
- Configure proxy_dns and your actual proxy chain in PROXYCHAINS_CONFIG; TCP only.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://www.kali.org/tools/proxychains-ng/)

<a id="module-41"></a>

## 41 / Reaver_Known_PIN_Check

File: Reaver_Known_PIN_Check.txt | Category: Vulnerability Assessment | Mode: Network operation

Test one supplied WPS PIN against one BSSID, with at most one PIN attempt.


### Before use

Executable in Kali PATH: reaver.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| BSSID | Access point MAC address | 02:00:00:00:00:01 |
| INTERFACE | Local network interface; wireless capture may need monitor mode | eth0 or wlan0mon, as appropriate |
| PASSWORD | Known WPS PIN, entered as a module-local PASSWORD override | Your known WPS PIN |


### Command template

```text
reaver -i "<<INTERFACE>>" -b "<<BSSID>>" -p "<<PASSWORD>>" -g 1 <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Target channel | -c <<CHANNEL>> | CHANNEL |
| 2 | Verbose output | -v | None |


### Using this module

Set BSSID, INTERFACE, PASSWORD. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Use a module-local PASSWORD override for the WPS PIN. Requires monitor-mode hardware and privileges.
- This sends WPS authentication traffic and can return the Wi-Fi key. Protocol retransmissions are possible.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://www.kali.org/tools/reaver/)

<a id="module-42"></a>

## 42 / Reaver_Wash_Survey

File: Reaver_Wash_Survey.txt | Category: Traffic Analysis | Mode: Ongoing capture / connection

Survey WPS advertisements with the wash utility bundled with Reaver.


### Before use

Executable in Kali PATH: wash.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| INTERFACE | Local network interface; wireless capture may need monitor mode | eth0 or wlan0mon, as appropriate |


### Command template

```text
wash -i "<<INTERFACE>>" -u <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Lock to channel | -c <<CHANNEL>> | CHANNEL |
| 2 | Write packet capture | -O "<<OUTPUT_FILE>>" | OUTPUT_FILE |
| 3 | JSON output | -j | None |


### Using this module

Set INTERFACE. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires capture privileges and a monitor-mode interface; survey mode is explicit.
- Ctrl+C stops observation.


### Results and completion

Runs in the foreground until stopped. Review its console output and any configured output files; Ctrl+C normally stops it.

[Tool documentation / source](https://www.kali.org/tools/reaver/)

<a id="module-43"></a>

## 43 / Responder_Analyze

File: Responder_Analyze.txt | Category: Traffic Analysis | Mode: Ongoing capture / connection

Observe name-resolution requests in analyze mode without enabling poisoning; runs until stopped.


### Before use

Executable in Kali PATH: responder.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| INTERFACE | Local network interface; wireless capture may need monitor mode | eth0 or wlan0mon, as appropriate |


### Command template

```text
responder -I "<<INTERFACE>>" -A <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Verbose observations | -v | None |


### Using this module

Set INTERFACE. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires capture/listener privileges and an appropriate interface.
- Analyze mode is fixed in the base command. Ctrl+C stops observation.


### Results and completion

Runs in the foreground until stopped. Review its console output and any configured output files; Ctrl+C normally stops it.

[Tool documentation / source](https://www.kali.org/tools/responder/)

<a id="module-44"></a>

## 44 / Rubeus_Ticket_List_Windows

File: Rubeus_Ticket_List_Windows.txt | Category: SMB / Windows | Mode: Windows through SSH

List Kerberos ticket metadata with Rubeus klist on a Windows SSH host.


### Before use

Python 3 and helpers/security_pack.py. The installed module still contains PACK_HELPER, so supply its absolute Kali path or use the pack installer.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| PACK_HELPER | Absolute Linux path to security_pack.py | /home/kali/tool_box/ToolBoxhelpers/kali_module_pack/security_pack.py |
| SSH_USER | Login on the Windows SSH host; separate from Toolbox target credentials | laboperator |
| WINDOWS_EXE | Absolute executable path on Windows, not Kali | C:\LabTools\Rubeus.exe |
| WINDOWS_HOST | Existing Windows SSH host | win01.lab.example |


### Command template

```text
python3 "<<PACK_HELPER>>" windows --host "<<WINDOWS_HOST>>" --user "<<SSH_USER>>" --exe "<<WINDOWS_EXE>>" --tool rubeus <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Preview remote invocation only | --preview | None |


### Using this module

Set PACK_HELPER, SSH_USER, WINDOWS_EXE, WINDOWS_HOST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires the included helper, a Windows SSH host, and the named executable installed on Windows.
- WINDOWS_EXE is an absolute Windows path. No binaries are installed or uploaded.
- SSH uses normal host-key checks and SSH authentication; see README for prerequisites.
- Lists the execution session tickets; it may be empty for an SSH-created session.


### Results and completion

Prints ticket metadata for the Windows execution session; an SSH session may have no tickets.

[Tool documentation / source](https://github.com/GhostPack/Rubeus#klist)

<a id="module-45"></a>

## 45 / Scapy_Console

File: Scapy_Console.txt | Category: Traffic Analysis | Mode: Interactive terminal

Open the Scapy Python console without loading user startup files.


### Before use

Executable in Kali PATH: scapy. Disable Toolbox Auto-Save for direct terminal input.

No base placeholders to fill. Running this module starts its fixed command.


### Command template

```text
scapy -C -P
```


### Options

No option toggles are defined.


### Using this module

Review the fixed command and any selected options in Dry-Run before launching it.

- Interactive Python console. Disable Toolbox Auto-Save. Exit with exit().
- Packet capture/transmission requires the relevant privileges.


### Results and completion

The command opens a terminal session. Review output there and exit the tool when finished.

[Tool documentation / source](https://www.kali.org/tools/scapy/)

<a id="module-46"></a>

## 46 / Scapy_Offline_PCAP_Summary

File: Scapy_Offline_PCAP_Summary.txt | Category: Traffic Analysis | Mode: Local / offline

Summarize packet types from a local capture using Scapy, reading at most 10000 packets by default.


### Before use

Python 3 and helpers/security_pack.py. The installed module still contains PACK_HELPER, so supply its absolute Kali path or use the pack installer.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| CAPTURE_FILE | Existing packet capture on Kali | /home/kali/lab/capture.pcap |
| PACK_HELPER | Absolute Linux path to security_pack.py | /home/kali/tool_box/ToolBoxhelpers/kali_module_pack/security_pack.py |


### Command template

```text
python3 "<<PACK_HELPER>>" pcap "<<CAPTURE_FILE>>" <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Custom packet limit | --limit <<PACKET_LIMIT>> | PACKET_LIMIT |
| 2 | Show individual packet summaries | --details | None |


### Using this module

Set CAPTURE_FILE, PACK_HELPER. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires the included helper and Kali python3-scapy. No network packets are sent.
- PACKET_LIMIT must be positive. Output reports whether the capture was truncated at the limit.


### Results and completion

Prints counts as JSON. The helper reports truncation at PACKET_LIMIT and optionally individual packet summaries.

[Tool documentation / source](https://scapy.readthedocs.io/en/latest/api/scapy.utils.html)

<a id="module-47"></a>

## 47 / SearchSploit_Local_Search

File: SearchSploit_Local_Search.txt | Category: Recon / Vulnerabilities | Mode: Local / offline

Search the local Exploit-DB index for one phrase without executing a result.


### Before use

Executable in Kali PATH: searchsploit.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| SEARCH_TERM | Phrase for the local Exploit-DB index | example product version |


### Command template

```text
searchsploit "<<SEARCH_TERM>>" <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Match exact title phrase | --exact | None |
| 2 | Search titles only | --title | None |
| 3 | JSON output | --json | None |
| 4 | Show web links | --www | None |


### Using this module

Set SEARCH_TERM. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- SEARCH_TERM is one phrase. Do not enable exact and title together; choose the desired search style.


### Results and completion

Processes local data and prints results. Any enabled output option determines an additional output file.

[Tool documentation / source](https://www.exploit-db.com/searchsploit)

<a id="module-48"></a>

## 48 / SecLists_Find_Wordlists

File: SecLists_Find_Wordlists.txt | Category: Payloads / Wordlists / Cheatsheets | Mode: Local / offline

Find installed SecLists wordlist files by a case-insensitive filename pattern.


### Before use

Executable in Kali PATH: find. Install the SecLists data collection separately.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| FILENAME_PATTERN | Pattern evaluated by find, not by a shell | *common* |


### Command template

```text
find /usr/share/seclists -type f -iname "<<FILENAME_PATTERN>>"
```


### Options

No option toggles are defined.


### Using this module

Set FILENAME_PATTERN. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires the Kali seclists data package. Example FILENAME_PATTERN: *common*.
- Matching is performed by find; no shell glob expansion is needed.


### Results and completion

Processes local data and prints results. Any enabled output option determines an additional output file.

[Tool documentation / source](https://www.kali.org/tools/seclists/)

<a id="module-49"></a>

## 49 / SecLists_Preview_Wordlist

File: SecLists_Preview_Wordlist.txt | Category: Payloads / Wordlists / Cheatsheets | Mode: Local / offline

Preview the first 40 lines of the chosen local wordlist.


### Before use

Executable in Kali PATH: head. Install the SecLists data collection separately.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| WORDLIST | Local list appropriate to the action: paths, labels, or password candidates | /home/kali/lab/wordlist.txt |


### Command template

```text
head -n 40 -- "<<WORDLIST>>"
```


### Options

No option toggles are defined.


### Using this module

Set WORDLIST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Set WORDLIST to a file found under /usr/share/seclists. This does not change Toolbox defaults.


### Results and completion

Processes local data and prints results. Any enabled output option determines an additional output file.

[Tool documentation / source](https://www.kali.org/tools/seclists/)

<a id="module-50"></a>

## 50 / SharpHound_DC_Collection_Windows

File: SharpHound_DC_Collection_Windows.txt | Category: SMB / Windows | Mode: Windows through SSH

Run SharpHound DCOnly collection on a Windows SSH host; results remain in WINDOWS_OUTPUT on that host.


### Before use

Python 3 and helpers/security_pack.py. The installed module still contains PACK_HELPER, so supply its absolute Kali path or use the pack installer.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| DOMAIN | AD DNS domain, DNS search domain, or authentication domain as specified by the module | lab.example |
| PACK_HELPER | Absolute Linux path to security_pack.py | /home/kali/tool_box/ToolBoxhelpers/kali_module_pack/security_pack.py |
| SSH_USER | Login on the Windows SSH host; separate from Toolbox target credentials | laboperator |
| WINDOWS_EXE | Absolute executable path on Windows, not Kali | C:\LabTools\SharpHound.exe |
| WINDOWS_HOST | Existing Windows SSH host | win01.lab.example |
| WINDOWS_OUTPUT | Existing writable directory on Windows | C:\LabResults |


### Command template

```text
python3 "<<PACK_HELPER>>" windows --host "<<WINDOWS_HOST>>" --user "<<SSH_USER>>" --exe "<<WINDOWS_EXE>>" --tool sharphound --domain "<<DOMAIN>>" --output "<<WINDOWS_OUTPUT>>" <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Preview remote invocation only | --preview | None |


### Using this module

Set DOMAIN, PACK_HELPER, SSH_USER, WINDOWS_EXE, WINDOWS_HOST, WINDOWS_OUTPUT. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Requires the included helper, a Windows SSH host, and the named executable installed on Windows.
- WINDOWS_EXE is an absolute Windows path. No binaries are installed or uploaded.
- SSH uses normal host-key checks and SSH authentication; see README for prerequisites.
- Windows session must have AD access. SSH login alone does not guarantee network credentials.


### Results and completion

Collection results remain in WINDOWS_OUTPUT on Windows. Retrieve them separately for BloodHound import.

[Tool documentation / source](https://bloodhound.specterops.io/collect-data/ce-collection/sharphound-flags)

<a id="module-51"></a>

## 51 / SMBMap_Share_Inventory

File: SMBMap_Share_Inventory.txt | Category: SMB / Windows | Mode: Network operation

List SMB shares with supplied credentials while disabling write-access test files.


### Before use

Executable in Kali PATH: smbmap.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| IP | Target host; BloodHound uses it for AD DNS and Certipy/AD Impacket for the DC | 192.0.2.10 |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| USERNAME | One account name; check domain qualification requirements | labuser |


### Command template

```text
smbmap -H "<<IP>>" -u "<<USERNAME>>" -p "<<PASSWORD>>" --no-write-check <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Authentication domain | -d "<<DOMAIN>>" | DOMAIN |
| 2 | Custom SMB port | -P <<PORT>> | PORT |
| 3 | Write CSV report | --csv "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set IP, PASSWORD, USERNAME. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- IP is one host; PORT is one integer. Write-access checking stays disabled.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://www.kali.org/tools/smbmap/)

<a id="module-52"></a>

## 52 / Socat_Local_TCP_Forward

File: Socat_Local_TCP_Forward.txt | Category: Shell / Session Tools | Mode: Ongoing capture / connection

Forward a TCP port bound to localhost to one destination; remains active until stopped.


### Before use

Executable in Kali PATH: socat.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| DEST_HOST | Destination reached by the forwarding endpoint | 192.0.2.20 |
| DEST_PORT | Single destination TCP port | 8080 |
| LOCAL_PORT | Local TCP port for the forwarder | 18080 |


### Command template

```text
socat <<OPTIONS>> "TCP-LISTEN:<<LOCAL_PORT>>,bind=127.0.0.1,reuseaddr,fork" "TCP:<<DEST_HOST>>:<<DEST_PORT>>"
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Connection diagnostics | -d -d | None |


### Using this module

Set DEST_HOST, DEST_PORT, LOCAL_PORT. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Local-only listener. DEST_HOST and port are reached from this Kali host.
- Use hostnames or IPv4 values without commas; composed socat addresses interpret commas as options.


### Results and completion

Runs in the foreground until stopped. Review its console output and any configured output files; Ctrl+C normally stops it.

[Tool documentation / source](https://www.kali.org/tools/socat/)

<a id="module-53"></a>

## 53 / Socat_TCP_Client

File: Socat_TCP_Client.txt | Category: Shell / Session Tools | Mode: Interactive terminal

Connect the terminal to one TCP service with a 30-second inactivity timeout.


### Before use

Executable in Kali PATH: socat. Disable Toolbox Auto-Save for direct terminal input.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| IP | Target host; BloodHound uses it for AD DNS and Certipy/AD Impacket for the DC | 192.0.2.10 |
| PORT | One port number for these modules; not a port list/range | 8080 |


### Command template

```text
socat -T 30 <<OPTIONS>> STDIO "TCP:<<IP>>:<<PORT>>"
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Connection diagnostics | -d -d | None |


### Using this module

Set IP, PORT. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Use one host and numeric port. Disable Toolbox Auto-Save for interactive input.


### Results and completion

The command opens a terminal session. Review output there and exit the tool when finished.

[Tool documentation / source](https://www.kali.org/tools/socat/)

<a id="module-54"></a>

## 54 / SQLMap

File: SQLMap.txt | Category: Exploit | Mode: Network operation

Test a web application parameter for SQL injection using sqlmap.


### Before use

Executable in Kali PATH: sqlmap.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/item?id=1 |


### Command template

```text
sqlmap <<OPTIONS>> -u <<URL>> <<OPTIONS2>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Test Parameter | -p <<PARAMETER>> | PARAMETER |
| 2 | POST Data | --data=<<POST_DATA>> | POST_DATA |
| 3 | Cookie | --cookie=<<COOKIE>> | COOKIE |
| 4 | HTTP Method | --method=<<HTTP_METHOD>> | HTTP_METHOD |

options2 (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 5 | Detection Level | --level=<<LEVEL>> | LEVEL |
| 6 | Risk Level | --risk=<<RISK>> | RISK |
| 7 | Threads | --threads=<<THREADS>> | THREADS |
| 8 | DBMS Hint | --dbms=<<DBMS>> | DBMS |
| 9 | Random User Agent | --random-agent | None |
| 10 | Batch Mode | --batch | None |


### Using this module

Set URL. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- This definition configures injection testing; it has no database-dump or operating-system-command toggle. A parameterized URL, such as https://web.lab.example/item?id=1, makes the intended input clear.
- Test Parameter selects which input is tested. POST Data, Cookie, and HTTP Method must match the application request. Cookie values are custom placeholders, not the protected PASSWORD placeholder.
- Start with level 1, risk 1 and one thread when explicitly setting these options. Higher levels/risks broaden or intensify tests. Batch Mode automatically chooses default answers to prompts.


### Results and completion

Prints detection results and uses sqlmap's configured session/output storage.

[Tool documentation / source](https://www.kali.org/tools/sqlmap/)

<a id="module-55"></a>

## 55 / Wfuzz_URL_Fuzzing

File: Wfuzz_URL_Fuzzing.txt | Category: Web Enumeration | Mode: Network operation

Fuzz one URL position from a wordlist with two workers and a half-second request delay.


### Before use

Executable in Kali PATH: wfuzz.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/FUZZ |
| WORDLIST | Local list appropriate to the action: paths, labels, or password candidates | /home/kali/lab/wordlist.txt |


### Command template

```text
wfuzz -w "<<WORDLIST>>" -t 2 -s 0.5 <<OPTIONS>> "<<URL>>"
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Hide HTTP status codes | --hc "<<HIDE_CODES>>" | HIDE_CODES |
| 2 | Hide response character counts | --hh "<<HIDE_SIZES>>" | HIDE_SIZES |
| 3 | Preview requests without sending | --dry-run | None |
| 4 | Save reusable results | --oF "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set URL, WORDLIST. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- URL must contain a literal FUZZ token, for example https://host.example/FUZZ.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://www.kali.org/tools/wfuzz/)

<a id="module-56"></a>

## 56 / Wifite_Check_Capture

File: Wifite_Check_Capture.txt | Category: Traffic Analysis | Mode: Local / offline

Check an existing wireless capture for WPA handshakes using Wifite validation tools.


### Before use

Executable in Kali PATH: wifite.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| CAPTURE_FILE | Existing packet capture on Kali | /home/kali/lab/capture.pcap |


### Command template

```text
wifite --check "<<CAPTURE_FILE>>"
```


### Options

No option toggles are defined.


### Using this module

Set CAPTURE_FILE. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Offline capture check; no radio interface is required.
- Wifite may require root and installed validation dependencies even in check mode.


### Results and completion

Processes local data and prints results. Any enabled output option determines an additional output file.

[Tool documentation / source](https://www.kali.org/tools/wifite/)

<a id="module-57"></a>

## 57 / WPScan_WordPress_Inventory

File: WPScan_WordPress_Inventory.txt | Category: Vulnerability Assessment | Mode: Network operation

Inspect WordPress with passive detection and 500ms request throttling.


### Before use

Executable in Kali PATH: wpscan.

| Required base input | Meaning | Example / format |
| --- | --- | --- |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/ |


### Command template

```text
wpscan --url "<<URL>>" --detection-mode passive --plugins-detection passive --throttle 500 <<OPTIONS>>
```


### Options

options (all options initially OFF)

| # | Toggle | Arguments inserted | Additional inputs |
| --- | --- | --- | --- |
| 1 | Enumerate popular plugins and themes | --enumerate p,t | None |
| 2 | Write JSON report | --format json --output "<<OUTPUT_FILE>>" | OUTPUT_FILE |


### Using this module

Set URL. Enable the desired toggles and provide their additional inputs. Inspect Dry-Run before performing the operation.

- Passive detection still requests web pages. Vulnerability data needs a configured WPScan API token; do not hard-code it here.


### Results and completion

Review the tool's console results and any enabled report output. Interpret failures and empty results in light of credentials, scope and filters.

[Tool documentation / source](https://www.kali.org/tools/wpscan/)


## Input glossary

These examples show expected formats, not targets to execute. Reuse global values only when their meaning matches the selected module. Documentation IP addresses and example domains are illustrative.

| Placeholder | Meaning | Example / format |
| --- | --- | --- |
| ACCOUNT_NAME | Account to filter in an AD query | labuser |
| ATTACK_MODE | Hashcat attack mode; use 0 for this dictionary layout | 0 |
| BSSID | Access point MAC address | 02:00:00:00:00:01 |
| CAPTURE_FILE | Existing packet capture on Kali | /home/kali/lab/capture.pcap |
| CERT_FINGERPRINT | Ligolo proxy certificate SHA256 hex fingerprint | Copy the verified proxy fingerprint |
| CHANNEL | Wireless channel for the selected access point | 6 |
| CHARSET | Characters Crunch may combine | abc |
| COOKIE | HTTP cookie header content; not automatically secret-redacted | session=your-session-value |
| DBMS | Known database engine hint for SQLMap | MySQL |
| DC_HOST | Domain controller hostname | dc01.lab.example |
| DEST_HOST | Destination reached by the forwarding endpoint | 192.0.2.20 |
| DEST_PORT | Single destination TCP port | 8080 |
| DNS_RESOLVER | Resolver host and port | 192.0.2.53:53 |
| DOMAIN | AD DNS domain, DNS search domain, or authentication domain as specified by the module | lab.example |
| ESSID | Wireless network name | LabWiFi |
| EXTENSIONS | Comma-separated filename extensions | php,html,txt |
| FILENAME_PATTERN | Pattern evaluated by find, not by a shell | *common* |
| FORK_COUNT | Number of John worker processes | 2 |
| FORMAT | John format identifier matching the hash file | Use the matching installed John format |
| HASH_FILE | Existing local hash file | /home/kali/lab/hashes.txt |
| HASH_MODE | Hashcat numeric identifier matching the hash type | Choose from installed hashcat help |
| HIDE_CODES | HTTP status codes to filter | 404 |
| HIDE_SIZES | Known unwanted response sizes; ffuf bytes or Wfuzz character count | Use the observed baseline size |
| HTTP_METHOD | HTTP method for the request | POST |
| INTERFACE | Local network interface; wireless capture may need monitor mode | eth0 or wlan0mon, as appropriate |
| IP | Target host; BloodHound uses it for AD DNS and Certipy/AD Impacket for the DC | 192.0.2.10 |
| LEVEL | SQLMap test level, from 1 through 5 | 1 |
| LISTEN_HOST | Local interface address to bind a listener | The intended local interface address |
| LISTEN_PORT | Single listener port | 8081 |
| LOCAL_PORT | Local TCP port for the forwarder | 18080 |
| MAX_LENGTH | Maximum Crunch output word length | 3 |
| MAX_RID | Exclusive RID upper bound for Impacket SID lookup | 4000 |
| MIN_LENGTH | Minimum Crunch output word length | 2 |
| OUTPUT_FILE | Writable output filename; create its parent directory first | /home/kali/lab/results.txt |
| OUTPUT_PREFIX | Output filename prefix; the tool may add suffixes | lab-run |
| PACKET_LIMIT | Positive maximum packet count for the Scapy helper | 10000 |
| PACK_HELPER | Absolute Linux path to security_pack.py | /home/kali/tool_box/ToolBoxhelpers/kali_module_pack/security_pack.py |
| PARAMETER | SQLMap request parameter to test | id |
| PASSWORD | Password, or a WPS PIN for Reaver; uses Toolbox password redaction | Enter your value through Toolbox |
| PORT | One port number for these modules; not a port list/range | 22 for SSH, 445 for SMB |
| POST_DATA | Request body data; inserted as one argument | id=1 |
| PROXYCHAINS_CONFIG | Existing ProxyChains configuration file | /home/kali/lab/proxychains.conf |
| PROXY_HOST | Ligolo proxy hostname or IP | 192.0.2.30 |
| PROXY_PORT | Ligolo proxy listener port | 11601 |
| RISK | SQLMap risk level, from 1 through 3 | 1 |
| RULESET | Installed John rule section name | Use a section from your John configuration |
| RULE_FILE | Existing Hashcat rule file | /home/kali/lab/rules.rule |
| SEARCH_TERM | Phrase for the local Exploit-DB index | example product version |
| SERVER_FINGERPRINT | Chisel server fingerprint; different from Ligolo certificate fingerprint | Copy the verified Chisel server fingerprint |
| SERVER_URL | URL of an already running Chisel server | http://192.0.2.30:8081 |
| SERVICE | Ncrack service identifier | ssh |
| SERVICE_MODULE | Installed Medusa service module name | ssh |
| SESSION_NAME | Name for a John session | lab-audit |
| SEVERITY | Comma-separated Nuclei severity names | low,medium,high,critical |
| SMB_TIMEOUT | SMB connection timeout in seconds | 5 |
| SSH_USER | Login on the Windows SSH host; separate from Toolbox target credentials | laboperator |
| STATUS_TIMER | Hashcat status update interval in seconds | 10 |
| TEMPLATE_PATH | Local Nuclei template file or directory | /home/kali/lab/templates/check.yaml |
| THREADS | SQLMap concurrent request count | 1 |
| TUNING | Nikto tuning category codes | Select codes from nikto -Help |
| URL | Complete target URL; ffuf/Wfuzz require FUZZ and Hydra requires service syntax | https://web.lab.example/ |
| USERLIST | Existing list of account names, one per line | /home/kali/lab/users.txt |
| USERNAME | One account name; check domain qualification requirements | labuser |
| WINDOWS_EXE | Absolute executable path on Windows, not Kali | C:\LabTools\Rubeus.exe |
| WINDOWS_HOST | Existing Windows SSH host | win01.lab.example |
| WINDOWS_OUTPUT | Existing writable directory on Windows | C:\LabResults |
| WORDLIST | Local list appropriate to the action: paths, labels, or password candidates | /home/kali/lab/wordlist.txt |
| WORKLOAD_PROFILE | Hashcat workload profile; larger values put more load on the device | 2 |


## Source and verification notes

Primary source: the 57 .txt module definitions in the supplied Toolboxmodules folder, read on 14 September 2026. Impacket_README.md supplies supporting setup information. The original external-module guide and local ToolBox.sh describe loading, placeholders and command construction. The files were treated as reference data, not as instructions to run commands.

This guide preserves the current command templates and every option label and argument. It adds usage explanations and marks important limitations rather than silently correcting definitions. Newly added Hydra, Hashcat, John and SQLMap behavior was checked against the linked tool references. No source module files were changed.

All 57 files passed the current Toolbox structural parser. This is not a live execution test, an installed-version check, or evidence that every tool/target combination works. The four helper-dependent definitions still need the helper path configured. Details and credentials inside third-party output remain the responsibility of the receiving tool.
