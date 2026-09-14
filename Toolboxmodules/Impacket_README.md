# Impacket modules for Toolbox

Four independent module definitions, based on the official Fortra Impacket examples and the supplied Toolbox v1.0 guide.

| Module | Menu | Purpose |
| --- | --- | --- |
| Impacket_AD_Users | SMB / Windows | User directory information |
| Impacket_AD_Computers | SMB / Windows | Computer inventory and optional DNS resolution |
| Impacket_RPC_Endpoints | Service Enumeration | RPC endpoint mapper discovery |
| Impacket_SID_Lookup | SMB / Windows | Account and group names through RID lookup |

## Setup

1. Ensure Impacket is installed in the Linux environment running Toolbox.
2. These definitions use upstream executable names: `GetADUsers.py`, `GetADComputers.py`, `rpcdump.py`, and `lookupsid.py`. Some distributions use `impacket-GetADUsers`, `impacket-GetADComputers`, `impacket-rpcdump`, and `impacket-lookupsid`. Check which name is installed and replace only the first token of the corresponding `Command:` line if necessary. The executable must be in PATH.
3. Copy the four `.txt` files directly into `Toolboxmodules` beside `ToolBox.sh`. Nested directories are not scanned. Keep this README outside that directory.
4. Open System & Configuration > Settings > External Modules, rescan, and load the desired files.
5. Set the target values, open the module, select options, and inspect Dry-Run. After file edits, rescan/reload selected modules.

## Inputs

- For both AD modules, `IP` is one domain controller IP address and `DOMAIN` is the AD DNS domain, such as `lab.example`. Supply `USERNAME` and `PASSWORD` for that domain.
- RPC endpoints needs only one target `IP` or hostname. It defaults to TCP 135; the alternate transport is port 593.
- SID lookup needs one target `IP` or hostname, plus `DOMAIN`, `USERNAME`, and `PASSWORD`. For a local account, use the target computer name as `DOMAIN`.
- Custom placeholders such as `DC_HOST`, `ACCOUNT_NAME`, and `MAX_RID` are prompted only when their option is enabled. Module-local values can be set with C.
- Targets must be single hosts, not CIDR networks, port ranges, or target-list files.
- Passwords use `<<PASSWORD>>` for Toolbox redaction. They are embedded in Impacket's single identity argument; do not hard-code credentials into these definitions.
- All toggles start OFF. The base AD and SID commands still perform authenticated queries when run.

## Validation and compatibility

Command flags were checked against the official source. Module fields, option placement, and quoting were checked locally. No live network queries were run, and these files have not been loaded in your running Toolbox installation. Check each installed executable with `-h`, then use Toolbox Dry-Run before a live run.

Sources:
- https://github.com/fortra/impacket/blob/master/examples/GetADUsers.py
- https://github.com/fortra/impacket/blob/master/examples/GetADComputers.py
- https://github.com/fortra/impacket/blob/master/examples/rpcdump.py
- https://github.com/fortra/impacket/blob/master/examples/lookupsid.py
