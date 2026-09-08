# Tool_Box

Tool_Box is a Bash-based, menu-driven toolkit for Linux security labs, network troubleshooting, enumeration, reporting, and common command-line utilities. It is designed to keep frequently used tools and references in one interface while preserving a target/workspace context throughout a session.

> Use Tool_Box only on systems, networks, labs, and accounts you are authorized to test or administer.

## Highlights

- Six-category main menu with global navigation shortcuts
- Target IP, subnet, port, output, and workspace tracking
- Nmap builders, scan profiles, and Nmap result import
- Web, DNS, SMB/Windows, service, and vulnerability-enumeration menus
- Workspaces with notes, findings, service inventories, and archives
- Results search, command history, comparison, and Markdown reporting
- Traffic analysis with tcpdump and TShark
- Text/encoding, network/VPN, port-reference, and command-line utilities
- Categorized security reference links and custom bookmarks
- Software/dependency management for supported apt-based systems
- Diagnostics plus standard-user/root session handling

## Download

Download the current script directly from the repository:

```bash
wget -O ToolBox.sh https://raw.githubusercontent.com/NecromancerLich/tool_box/refs/heads/main/ToolBox.sh
chmod +x ToolBox.sh
./ToolBox.sh
```

Tool_Box is normally best started as your regular desktop user. Use its privilege menu or sudo prompts when an individual task requires elevated permissions.

## Navigation

Nested menus include a persistent footer:

```text
[0] Back   [M] Main Menu   [T] Set Target/Data   [W] Workspace   [H] Help
```

This makes it possible to jump between common areas without repeatedly backing out through multiple menu levels.

## Workspaces

A workspace can retain the current target and related project data, including:

- Target IP/subnet and ports
- Wordlist/thread/output settings
- Notes
- Findings/loot entries
- Imported Nmap service data
- Workspace archives

## Useful Links

Reference links are grouped into categories such as:

- Shell / Session Tools
- Linux / Windows Privilege References
- Data / Encoding / Analysis
- Web Security
- Recon / Vulnerability References
- Payloads / Wordlists / Cheat Sheets
- Training
- Custom Bookmarks

When Tool_Box is running as root, Firefox links can be launched as a selected non-root desktop user.

## Requirements

- Linux
- Bash
- Individual tools are optional and are detected by Tool_Box
- Software installation/repair features are primarily designed for apt-based systems

Run **System & Configuration -> Tool_Box Diagnostics** after installation to see which supported tools and desktop integrations are available.

## Documentation

The repository can include the full Functionality Guide for detailed menu descriptions, settings, workspaces, output paths, privilege handling, and troubleshooting.

## Project

Repository: https://github.com/NecromancerLich/tool_box
