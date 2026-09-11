# Tool_Box v1.01

Tool_Box is a menu-driven Bash wrapper for common Linux, networking, reconnaissance, enumeration, analysis, and lab-security utilities. It is designed to organize repeatable workflows while still showing the command that will be run.

> **Authorized use only.** Use Tool_Box only on systems, networks, services, accounts, and data that you own or are explicitly authorized to test.

## Important project notice

Tool_Box has been developed with substantial AI assistance ("vibe coded"). AI-assisted code can contain mistakes, incomplete validation, unsafe assumptions, or unexpected behavior. Review the code, verify command previews, and test new functionality in an isolated lab before relying on it.

Tool_Box is provided **as-is** and without warranty. The project author(s) are not responsible for how another person chooses to use the project or, to the extent permitted by applicable law, for damage, data loss, outages, system instability, security incidents, financial loss, legal consequences, or other harm arising from use, misuse, or inability to use the software.

Tool_Box launches third-party programs. Those programs retain their own licenses, behavior, defaults, security considerations, and risks. Inclusion in Tool_Box does not imply endorsement, sponsorship, affiliation, or warranty by the third-party project's maintainers.

This project notice is not legal advice. See [LICENSE](LICENSE) and [TERMS.md](TERMS.md) for the project's license and authorized-use acknowledgement.

---

## Quick start

Keep the repository files together:

```text
Tool_Box/
├── ToolBox.sh
├── README.md
├── LICENSE
├── TERMS.md
├── Tool_Box_External_Module_Guide.pdf
├── Tool_Box_Functionality_Guide.pdf
├── Tool_Box_Quick_Guide.txt
└── Toolboxmodules/
    ├── Basic_curl.txt
    └── Basic_nmap.txt
```

Launch Tool_Box with:

```bash
bash ToolBox.sh
```

Or make it executable:

```bash
chmod +x ToolBox.sh
./ToolBox.sh
```

Tool_Box locates `Toolboxmodules` relative to the script itself, so it can be launched from a different working directory.

---

## v1.01 maintenance update

Version 1.01 is a readability and navigation maintenance release. It does not change the external-module format introduced in v1.0.

- Output-directory paths in the terminal header now use high-contrast bright cyan instead of dark ANSI blue.
- URLs on Useful Links pages now use bright cyan and underline so they remain readable on black terminal backgrounds and recognizable without color alone.
- The startup ASCII splash now appears only when Tool_Box is launched directly. Internal process restarts used by global navigation shortcuts such as **M - Main Menu** no longer replay the splash.
- Per-version terms acknowledgement remains unchanged: upgrading to v1.01 still asks the current Linux user to accept the notice once.

---

## v1.0 highlights

Version 1.0 formalizes the external-module format with **positioned option groups**. Modules can now place up to three independent groups of toggled arguments exactly where they belong in a command by using these reserved placeholders:

```text
<<OPTIONS>>
<<OPTIONS2>>
<<OPTIONS3>>
```

They correspond to:

```text
options:
options2:
options3:
```

Example:

```text
Name: Example
Description: Example with three option groups.
Category: Reconnaissance
Command: program <<OPTIONS>> subcommand <<OPTIONS2>> <<IP>> <<OPTIONS3>>

options:
    verbose: -v
    quiet: -q

options2:
    ports: -p <<PORT>>
    service detection: -sV

options3:
    output file: -oN <<OUTPUT_FILE>>
```

If `verbose`, `ports`, and `output file` are enabled, the command is assembled in the same locations as the three reserved markers.

### Option-group rules

- `<<OPTIONS>>` inserts enabled entries from `options:`.
- `<<OPTIONS2>>` inserts enabled entries from `options2:`.
- `<<OPTIONS3>>` inserts enabled entries from `options3:`.
- Reserved option markers must be standalone command tokens and can appear only once each.
- `options2:` requires `<<OPTIONS2>>` in `Command:`.
- `options3:` requires `<<OPTIONS3>>` in `Command:`.
- `options:`, `options2:`, and `options3:` must appear in that order after the four required fields.
- For backward compatibility, an `options:` section without `<<OPTIONS>>` keeps the older behavior and appends enabled options to the end of the base command.
- Reserved `OPTIONS` markers are structural and do not appear under **Custom Placeholder Values**.
- Normal placeholders inside option groups, such as `<<PORT>>`, `<<URL>>`, or `<<OUTPUT_FILE>>`, still work normally.

The external module screen displays the groups separately as **Options**, **Options 2**, and **Options 3**, while keeping one continuous option-number sequence.

---

## Startup and version acknowledgement

Tool_Box shows a short ASCII-art intro when it starts. On the first launch of **each Tool_Box version** for a Linux user, it also displays the Terms & Authorized-Use Notice and asks:

```text
Accept terms and continue? [Y/n]:
```

Press **Enter** or enter `Y`/`y` to accept. Enter `N`/`n` to exit without loading the main menu.

Acceptance is stored locally per Linux user in:

```text
~/.tool_box_terms.conf
```

The record contains the accepted terms version, Tool_Box version, and acceptance time. A new Tool_Box version requires acknowledgement again even when the terms text has not changed. Removing the file also causes the acknowledgement to appear again.

The acknowledgement is a project safety/usage notice; it does not replace the MIT License or professional legal advice.

---

## Main interface conventions

Tool_Box command pages use consistent sections such as:

- **Command Preview**
- **Options**
- **Customization**
- **Actions**
- **Documentation**

The primary execution key is:

```text
R) Run
```

Navigation is handled by the global footer:

```text
[0] Back   [M] Main Menu   [T] Set Target/Data   [W] Workspace   [H] Help
```

Because `[0] Back` is already in the footer, non-main menus do not repeat a separate `0) Back` item in the menu body.

---

## External modules

External modules let you add commands to Tool_Box with `.txt` definition files instead of editing the main Bash script.

The module manager is located at:

**System & Configuration -> Settings -> External Modules**

It can list, load, unload, and rescan modules. Loaded external modules appear in their configured menu category with selectors such as `E1`, `E2`, and so on.

### External-module controls

A loaded module can provide ON/OFF options across up to three groups plus the following controls:

- **`C` - Custom Placeholder Values**: temporarily override a normal module value such as URL, IP, port, username, wordlist, or a custom placeholder.
- **`A` - Custom Arguments**: append temporary validated arguments after the resolved module command.
- **`X` - Clear Customizations**: clear module-local overrides and custom arguments.
- **`R` - Run**: execute the resolved command through the normal Tool_Box confirmation/logging flow.
- **`D` - Module Help**: view help for option groups and external-module controls.

Module-local overrides do not change global Set Target/Data values or modify the module `.txt` file.

### Full module creation tutorial

The full module-writing tutorial is intentionally kept out of the README so the repository front page stays focused.

See **[Tool_Box External Module Guide](Tool_Box_External_Module_Guide.pdf)** for the complete tutorial, examples, option-group syntax, supported category hierarchy and aliases, loading/reloading, customization, troubleshooting, and reusable templates.

---

## External-module persistence

Selected module filenames are stored per Linux user in:

```text
~/.tool_box.modules.conf
```

This is separate from the normal Tool_Box configuration. Root and standard-user sessions can therefore have separate module selections.

Module files themselves remain in the `Toolboxmodules` directory beside the script.

---

## Ping

Ping is available under:

**Reconnaissance & Enumeration -> Reconnaissance -> Ping**

The page supports a temporary target override, request count, reply timeout, numeric output, reset to the global target, command preview, `R` to run, and documentation/help.

---

## Security and privacy guidance

Tool_Box makes commands visible and deliberate, but it cannot make every command or third-party utility safe.

Recommended practices:

- Review **Command Preview** before important runs.
- Use **Dry-Run** when testing new functionality or modules.
- Verify the target before executing a scan or administrative command.
- Avoid running the entire program as `root` unless necessary.
- Do not hard-code real passwords, API tokens, private keys, or other secrets into modules.
- Remember that third-party programs may display or log credentials even when Tool_Box redacts its own preview/history.
- Keep important data backed up.
- Test new modules and intrusive tools in isolated lab environments first.
- Review external module files before loading them.
- Check saved results before publishing or committing them to GitHub.

`<<PASSWORD>>` receives additional protection in Tool_Box previews and history, but Tool_Box cannot control what a third-party program does with a supplied password.

---

## Configuration and generated files

Common Tool_Box user files include:

```text
~/.tool_box.conf
~/.tool_box.modules.conf
~/.tool_box_terms.conf
~/.tool_box_profiles/
```

The default results directory is:

```text
./results
```

The included `.gitignore` excludes the local `results/` directory and common local Tool_Box state filenames so scan output or local state is less likely to be committed accidentally. Always review staged files before pushing a repository.

---

## License: MIT

Tool_Box is packaged with the **MIT License**. MIT is a permissive license that allows people to study, use, modify, redistribute, and build on the code while retaining the copyright/license notice and the license's as-is warranty disclaimer.

The included `LICENSE` uses the repository owner name/handle `NecromancerLich`. Change that line before publishing if you prefer a different copyright holder.

Keep the file named exactly `LICENSE` in the root of the GitHub repository so GitHub can detect and display the license on the repository page.

---

## GitHub repository filenames

Repository files use stable names without release numbers in their filenames:

```text
.gitignore
LICENSE
README.md
TERMS.md
ToolBox.sh
Tool_Box_External_Module_Guide.pdf
Toolboxmodules/
```

Use Git tags and GitHub Releases for release numbers. Downloadable release archives may still use a versioned name such as `Tool_Box_v1.01.zip`.

---

## Known limitations

- Tool_Box depends on installed third-party utilities and cannot guarantee their behavior.
- External modules wrap one executable command template rather than arbitrary shell scripts.
- External-module pipelines, redirection, command substitution, environment-variable expansion, and glob expansion are intentionally restricted.
- The external-module format currently supports a maximum of three positioned option groups.
- Module-local customizations are temporary and reset when the module is reopened.
- A command can be syntactically valid but still be inappropriate for a particular target or incompatible with the installed version of a third-party tool.
- Auto-Save cannot perfectly capture every interactive terminal application's behavior.
- The per-version acknowledgement is stored locally and can be removed by the user; it is an acknowledgement mechanism, not a technical security boundary.

---

## v1.0 changes

- Promoted the project to **version 1.0**.
- Added reserved `<<OPTIONS>>`, `<<OPTIONS2>>`, and `<<OPTIONS3>>` command-placement markers for external modules.
- Added `options2:` and `options3:` sections.
- Added strict validation for option-group ordering, marker placement, duplicate markers, and unsupported `<<OPTIONS#>>` markers.
- Kept legacy `options:` append-at-end behavior when `<<OPTIONS>>` is not used.
- Updated the module UI to show **Options**, **Options 2**, and **Options 3** as separate sections with continuous numbering.
- Updated module help and Custom Placeholder Values handling so reserved option markers are treated as structural, not editable values.
- Updated sample modules and the standalone External Module Guide.
- Kept the per-version `[Y/n]` terms acknowledgement, stable GitHub filenames, menu conventions, password redaction, and existing external-module customization behavior.

---

## v1.01 changes

- Improved terminal contrast for the output directory shown in headers.
- Improved Useful Links URL contrast and added underlining.
- Prevented the startup splash from replaying during internal Main Menu/global-navigation restarts.
- Kept the v1.0 module format, menus, and command behavior unchanged.

---

## Final reminder

Tool_Box is a convenience layer, not a substitute for understanding the commands being run.

Before pressing **`R`**:

- Confirm the target.
- Confirm you are authorized.
- Review the command preview.
- Check whether elevated privileges are necessary.
- Consider Dry-Run first.
- Understand what the third-party tool is expected to do.

Use Tool_Box responsibly and keep security testing inside environments where you have permission.
