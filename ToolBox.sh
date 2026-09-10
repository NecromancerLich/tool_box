#!/bin/bash

# ==========================================================
# Tool_Box
# A menu-driven wrapper for common Linux/network lab tools.
# ==========================================================

# -------------------------
# Global configuration
# -------------------------
ver="0.32"
ip="127.0.0.1"
subnet=32
port="4444"
output_folder="./results"
config_file="$HOME/.tool_box.conf"

# Distribution/repository information is detected at runtime. Tool_Box only
# enables repositories that belong to the detected operating system; it never
# mixes Kali repositories into Ubuntu/Debian or vice versa.
distro_id="unknown"
distro_id_like=""
distro_pretty="Linux"
distro_codename=""

# Defaults used by web enumeration tools.
default_threads="10"
if [[ -f "/usr/share/seclists/Discovery/Web-Content/common.txt" ]]; then
    default_wordlist="/usr/share/seclists/Discovery/Web-Content/common.txt"
else
    default_wordlist="/usr/share/wordlists/dirb/common.txt"
fi

auto_save_output=false
verbose_mode=false
dry_run_mode=false
color_enabled=true

# Terminal styling. ANSI sequences are activated only for an interactive
# terminal and are suppressed when NO_COLOR is set or TERM=dumb.
color_active=false
C_RESET=""
C_BOLD=""
C_DIM=""
C_RED=""
C_GREEN=""
C_YELLOW=""
C_BLUE=""
C_MAGENTA=""
C_CYAN=""

# In-memory command history for the current session.
command_history=()

# Tracks the current screen so menu_prompt() can render context-aware navigation shortcuts.
current_menu_title=""

# Workspace / project state. Workspaces keep target metadata, notes, findings,
# and imported service inventories together while normal Tool_Box result files
# continue to use the configured output directory.
workspace_name=""
workspace_dir=""
workspace_loaded=false
config_profiles_dir="$HOME/.tool_box_profiles"
toolbox_repo_url="https://github.com/NecromancerLich/tool_box"
toolbox_raw_url="https://raw.githubusercontent.com/NecromancerLich/tool_box/refs/heads/main/ToolBox.sh"
toolbox_docs_pdf_name="Tool_Box_Functionality_Guide.pdf"
toolbox_docs_txt_name="Tool_Box_Quick_Guide.txt"
toolbox_docs_pdf_url="https://raw.githubusercontent.com/NecromancerLich/tool_box/refs/heads/main/${toolbox_docs_pdf_name}"
toolbox_docs_txt_url="https://raw.githubusercontent.com/NecromancerLich/tool_box/refs/heads/main/${toolbox_docs_txt_name}"
documentation_download_dir="$PWD"

# Set by run_privileged_command() so elevated actions receive an extra warning.
command_requires_privilege=false

# When a standard-user Tool_Box session starts a nested root session, these
# values identify the parent session and allow the root instance to return to it.
toolbox_parent_user="${TOOLBOX_PARENT_USER:-}"
toolbox_elevated_session="${TOOLBOX_ELEVATED_SESSION:-false}"
toolbox_nav_restart="${TOOLBOX_NAV_RESTART:-false}"

# Command currently being previewed.
command=()

# v0.32: module definitions are data, never sourced or evaluated.
toolbox_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
external_modules_dir="$toolbox_script_dir/Toolboxmodules"
external_modules_config="${config_file%.conf}.modules.conf"
toolbox_domain=""
toolbox_url=""
toolbox_username=""
toolbox_password=""
declare -a external_selected=() external_files=() external_loaded=()
declare -A external_name=() external_description=() external_category=() external_command=() external_options=()
declare -A external_categories=()
external_categories["target & scanning"]="target & scanning"
external_categories["reconnaissance & enumeration"]="reconnaissance & enumeration"
external_categories["access & exploitation"]="access & exploitation"
external_categories["analysis & reporting"]="analysis & reporting"
external_categories["utilities & resources"]="utilities & resources"
external_categories["system & configuration"]="system & configuration"
external_categories["reconnaissance"]="reconnaissance"
external_categories["web enumeration"]="web enumeration"
external_categories["network / dns"]="network / dns"
external_categories["smb / windows"]="smb / windows"
external_categories["service enumeration"]="service enumeration"
external_categories["vulnerability assessment"]="vulnerability assessment"
external_categories["traffic analysis"]="traffic analysis"
external_categories["results / reporting"]="results / reporting"
external_categories["command-line utilities"]="command-line utilities"
external_categories["network information"]="network information"
external_categories["text / encoding tools"]="text / encoding tools"
external_categories["useful links"]="useful links"
external_categories["shell / session tools"]="shell / session tools"
external_categories["data / encoding / analysis"]="data / encoding / analysis"
external_categories["privilege references"]="privilege references"
external_categories["web security"]="web security"
external_categories["recon / vulnerabilities"]="recon / vulnerabilities"
external_categories["payloads / wordlists / cheatsheets"]="payloads / wordlists / cheatsheets"
external_categories["training"]="training"
external_categories["pass/hash cracking"]="pass/hash cracking"
external_categories["exploit"]="exploit"
external_categories["scan profiles"]="scan profiles"
external_categories["workspace / project"]="workspace / project"
external_categories["settings"]="settings"
external_categories["documentation"]="documentation"
external_categories["recon & enumeration"]="reconnaissance & enumeration"
external_categories["utilities"]="command-line utilities"
external_categories["network information / vpn status"]="network information"
external_categories["linux / windows privilege references"]="privilege references"
external_categories["recon / vulnerability references"]="recon / vulnerabilities"
external_categories["payloads / wordlists / cheat sheets"]="payloads / wordlists / cheatsheets"
external_categories["pass / hash cracking"]="pass/hash cracking"


external_trim() {
    external_trimmed="$1"
    external_trimmed="${external_trimmed#"${external_trimmed%%[![:space:]]*}"}"
    external_trimmed="${external_trimmed%"${external_trimmed##*[![:space:]]}"}"
}

# Tokenize a program and arguments without Bash evaluation. Quotes group words;
# escapes quote the following character. Substitution happens AFTER tokenizing.
external_tokenize() {
    local text="$1" ch quote="" token="" started=false escaped=false i
    external_tokens=()
    for ((i=0; i<${#text}; i++)); do
        ch="${text:i:1}"
        if [[ "$escaped" == true ]]; then
            if [[ "$quote" == '"' && "$ch" != '$' && "$ch" != '`' && "$ch" != '"' && "$ch" != '\' ]]; then token+='\'; fi
            token+="$ch"; escaped=false; started=true; continue
        fi
        if [[ "$quote" == "'" ]]; then
            if [[ "$ch" == "'" ]]; then quote=""; else token+="$ch"; fi
        elif [[ "$ch" == '\' ]]; then
            escaped=true; started=true
        elif [[ -n "$quote" ]]; then
            if [[ "$ch" == '"' ]]; then quote=""; else token+="$ch"; fi
        else
            case "$ch" in
                "'"|'"') quote="$ch"; started=true ;;
                ' '|$'\t')
                    if [[ "$started" == true ]]; then external_tokens+=("$token"); fi
                    token=""; started=false ;;
                '|'|'&'|';'|'`'|'$') return 1 ;;
                *) token+="$ch"; started=true ;;
            esac
        fi
    done
    [[ -z "$quote" && "$escaped" == false ]] || return 1
    [[ "$started" == true ]] && external_tokens+=("$token")
    ((${#external_tokens[@]} > 0)) || return 1
    # Angle brackets are reserved exclusively for placeholders.
    local item residue pattern='<<[A-Z_][A-Z0-9_]*>>'
    for item in "${external_tokens[@]}"; do
        residue="$item"
        while [[ "$residue" =~ $pattern ]]; do residue="${residue/"${BASH_REMATCH[0]}"/}"; done
        [[ "$residue" != *'<'* && "$residue" != *'>'* ]] || return 1
    done
}

external_parse() {
    local file="$1" line key value in_options=false number=0 label
    local -A fields=() labels=()
    parsed_name=""; parsed_description=""; parsed_category=""; parsed_command=""; parsed_options=""
    [[ -f "$file" && -r "$file" && ! -L "$file" ]] || { msg_warn "Unreadable or linked module: $file"; return 1; }
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((number+=1)); line="${line%$'\r'}"
        [[ $number == 1 ]] && line="${line#$'\xef\xbb\xbf'}"
        external_trim "$line"; line="$external_trimmed"
        [[ -z "$line" || "$line" == \#* ]] && continue
        if [[ "$line" != *:* ]]; then msg_warn "$file:$number: expected Field: value"; return 1; fi
        external_trim "${line%%:*}"; key="$external_trimmed"
        external_trim "${line#*:}"; value="$external_trimmed"
        [[ -n "$key" && "$key" != *$'\t'* ]] || { msg_warn "$file:$number: invalid field or option name"; return 1; }
        if [[ "$in_options" == true ]]; then
            label="${key,,}"
            [[ -n "$key" && -n "$value" && -z "${labels[$label]+x}" ]] || { msg_warn "$file:$number: empty or duplicate option"; return 1; }
            external_tokenize "$value" || { msg_warn "$file:$number: invalid option arguments"; return 1; }
            labels["$label"]=1
            parsed_options+="$key"$'\t'"$value"$'\n'
            continue
        fi
        key="${key,,}"
        [[ -z "${fields[$key]+x}" ]] || { msg_warn "$file:$number: duplicate field $key"; return 1; }
        fields["$key"]=1
        case "$key" in
            name) parsed_name="$value" ;;
            description) parsed_description="$value" ;;
            category) parsed_category="${value,,}" ;;
            command) parsed_command="$value" ;;
            options) [[ -z "$value" ]] || { msg_warn "$file:$number: options must be a section"; return 1; }; in_options=true ;;
            *) msg_warn "$file:$number: unknown field '$key' (use Category, not Catagory)"; return 1 ;;
        esac
    done < "$file"
    [[ -n "$parsed_name" && -n "$parsed_description" && -n "$parsed_category" && -n "$parsed_command" ]] || { msg_warn "$file: Name, Description, Category and Command are required"; return 1; }
    [[ -n "${external_categories[$parsed_category]:-}" ]] || { msg_warn "$file: unknown category '$parsed_category'"; return 1; }
    parsed_category="${external_categories[$parsed_category]}"
    external_tokenize "$parsed_command" || { msg_warn "$file: invalid Command (use a program and arguments)"; return 1; }
    [[ "${external_tokens[0]}" != *'<<'* ]] || { msg_warn "$file: the executable cannot be a placeholder"; return 1; }
}

external_scan() {
    external_files=()
    local file
    [[ -d "$external_modules_dir" ]] || return 0
    for file in "$external_modules_dir"/*; do
        [[ -f "$file" && ! -L "$file" && "${file,,}" == *.txt ]] && external_files+=("${file##*/}")
    done
    return 0
}

external_load() {
    local file="$1" existing key
    [[ -n "$file" && "$file" != */* && "$file" != *\\* && "$file" != *$'\n'* && "${file,,}" == *.txt ]] || { msg_warn "Invalid module filename: $file"; return 1; }
    external_parse "$external_modules_dir/$file" || return 1
    for existing in "${external_loaded[@]}"; do
        [[ "$existing" == "$file" ]] && { msg_warn "Already loaded: $file"; return 1; }
        [[ "${external_name[$existing],,}" == "${parsed_name,,}" ]] && { msg_warn "Duplicate module name rejected: $parsed_name"; return 1; }
    done
    for key in "${software_keys[@]}"; do
        [[ "${key,,}" == "${parsed_name,,}" || "${software_display[$key],,}" == "${parsed_name,,}" ]] && { msg_warn "Name conflicts with a built-in tool: $parsed_name"; return 1; }
    done
    external_loaded+=("$file")
    external_name["$file"]="$parsed_name"
    external_description["$file"]="$parsed_description"
    external_category["$file"]="$parsed_category"
    external_command["$file"]="$parsed_command"
    external_options["$file"]="$parsed_options"
}

external_save_selection() {
    local temp
    temp=$(mktemp "${external_modules_config}.XXXXXX") || { msg_warn "Cannot save module selection"; return 1; }
    if { for external_saved_file in "${external_selected[@]}"; do printf '%s\n' "$external_saved_file"; done; } > "$temp" && mv -- "$temp" "$external_modules_config"; then
        return 0
    fi
    rm -f -- "$temp"
    msg_warn "Cannot save module selection; restart may restore the previous selection."
    return 1
}

external_reload() {
    local file failed=false
    external_loaded=(); external_name=(); external_description=(); external_category=(); external_command=(); external_options=()
    for file in "${external_selected[@]}"; do external_load "$file" || failed=true; done
    [[ "$failed" == false ]]
}

external_restore() {
    external_selected=()
    local file
    if [[ -r "$external_modules_config" ]]; then
        while IFS= read -r file || [[ -n "$file" ]]; do
            file="${file%$'\r'}"; [[ -n "$file" ]] && external_selected+=("$file")
        done < "$external_modules_config"
    fi
    external_scan
    external_reload
}

external_render() {
    local category="$1" file index=0
    for file in "${external_loaded[@]}"; do
        ((index+=1))
        [[ "${external_category[$file]}" == "$category" ]] && printf ' E%d) %s [external]\n' "$index" "${external_name[$file]}"
    done
    return 0
}

external_dispatch() {
    local choice="$1" category="$2" file index=0
    for file in "${external_loaded[@]}"; do
        ((index+=1))
        if [[ "${choice^^}" == "E$index" && "${external_category[$file]}" == "$category" ]]; then
            external_module_menu "$file"
            return 0
        fi
    done
    return 1
}

external_resolve_value() {
    local name="$1"
    case "$name" in
        IP) external_value="$ip" ;;
        PORT) external_value="$port" ;;
        SUBNET) external_value="$subnet" ;;
        DOMAIN) external_value="$toolbox_domain" ;;
        URL) external_value="$toolbox_url" ;;
        WORDLIST) external_value="$default_wordlist" ;;
        USERNAME) external_value="$toolbox_username" ;;
        PASSWORD) external_value="$toolbox_password" ;;
        WORKSPACE) external_value="$workspace_name" ;;
        *) external_value="" ;;
    esac
}

external_build_command() {
    local template="$1" mode="$2" token remaining part name value pattern='<<([A-Z_][A-Z0-9_]*)>>'
    local -A answers=()
    external_tokenize "$template" || return 1
    local -a tokens=("${external_tokens[@]}")
    command=(); command_display=()
    for token in "${tokens[@]}"; do
        remaining="$token"; part=""
        while [[ "$remaining" =~ $pattern ]]; do
            name="${BASH_REMATCH[1]}"
            part+="${remaining%%"<<$name>>"*}"
            remaining="${remaining#*"<<$name>>"}"
            if [[ -n "${answers[$name]+x}" ]]; then
                value="${answers[$name]}"
            else
                external_resolve_value "$name"; value="$external_value"
                if [[ "$mode" == preview && ( -z "$value" || "$name" == PASSWORD ) ]]; then
                    value="<<$name>>"
                elif [[ -z "$value" ]]; then
                    if [[ "$name" == PASSWORD ]]; then
                        IFS= read -r -s -p "Value for $name (blank cancels): " value || return 1; echo
                    else
                        IFS= read -r -p "Value for $name (blank cancels): " value || return 1
                    fi
                    [[ -n "$value" ]] || return 1
                fi
                answers["$name"]="$value"
            fi
            part+="$value"
        done
        command+=("$part$remaining")
        if [[ "$token" == *'<<PASSWORD>>'* ]]; then command_display+=('[REDACTED]'); else command_display+=("$part$remaining"); fi
    done
}

external_module_menu() {
    local file="$1" choice label args line template i selected_index log_name
    local -a labels=() fragments=() enabled=()
    local -a command_display=()
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        labels+=("${line%%$'\t'*}"); fragments+=("${line#*$'\t'}"); enabled+=(false)
    done <<< "${external_options[$file]}"
    while true; do
        header "Tool_Box - ${external_name[$file]}"
        printf 'Description: %s\n' "${external_description[$file]}"
        template="${external_command[$file]}"
        for ((i=0; i<${#labels[@]}; i++)); do
            printf ' %d) %s: %s\n' "$((i+1))" "${labels[i]}" "$(toggle_status "${enabled[i]}")"
            [[ "${enabled[i]}" == true ]] && template+=" ${fragments[i]}"
        done
        external_build_command "$template" preview && show_command
        echo ' R) Run'
        echo ' 0) Back'
        menu_prompt choice || return
        case "$choice" in
            0) return ;;
            r|R)
                if external_build_command "$template" run; then
                    if command -v -- "${command[0]}" >/dev/null 2>&1; then
                        log_name="${external_name[$file]//[^a-zA-Z0-9_-]/_}"
                        run_command_logged external "$log_name"
                    else msg_warn "Executable unavailable: ${command[0]}"; pause; fi
                else msg_warn 'Command cancelled: a value was missing.'; pause; fi ;;
            *)
                selected_index=-1
                for ((i=0; i<${#labels[@]}; i++)); do [[ "$choice" == "$((i+1))" ]] && selected_index=$i; done
                if ((selected_index >= 0)); then enabled[selected_index]=$(toggle_bool "${enabled[selected_index]}"); else msg_warn 'Invalid option'; pause; fi ;;
        esac
    done
}

external_management_menu() {
    local choice file number selected found i
    while true; do
        header 'Tool_Box - External Modules'
        printf 'Folder: %s\nLoaded: %s   Selected: %s\n' "$external_modules_dir" "${#external_loaded[@]}" "${#external_selected[@]}"
        echo ' 1) List discovered and selected modules'
        echo ' 2) Load one'
        echo ' 3) Load all'
        echo ' 4) Unload one'
        echo ' 5) Unload all'
        echo ' 6) Rescan / reload selected modules'
        echo ' 0) Back'
        menu_prompt choice || return
        case "$choice" in
            0) return ;;
            1)
                external_scan
                for file in "${external_files[@]}"; do
                    printf '\nFile: %s\n' "$file"
                    if external_parse "$external_modules_dir/$file"; then printf '  %s | %s\n  %s\n' "$parsed_name" "$parsed_category" "$parsed_description"; fi
                done
                printf '\nSelected for restart:\n'; for file in "${external_selected[@]}"; do
                    if [[ -n "${external_name[$file]+x}" ]]; then printf '  %s [loaded]\n' "$file"; else printf '  %s [unavailable/invalid]\n' "$file"; fi
                done
                [[ -d "$external_modules_dir" ]] || printf 'Create this folder and add .txt files: %s\n' "$external_modules_dir"
                pause ;;
            2|3)
                external_scan
                local -a candidates=("${external_files[@]}")
                if [[ "$choice" == 2 ]]; then
                    number=0; for file in "${candidates[@]}"; do ((number+=1)); printf ' %d) %s\n' "$number" "$file"; done
                    IFS= read -r -p 'File number (0 cancels): ' selected || return
                    found=""; number=0
                    for file in "${candidates[@]}"; do ((number+=1)); [[ "$selected" == "$number" ]] && found="$file"; done
                    [[ -n "$found" ]] || continue
                    candidates=("$found")
                fi
                for file in "${candidates[@]}"; do
                    [[ -n "${external_name[$file]+x}" ]] && continue
                    if external_load "$file"; then
                        found=false; for selected in "${external_selected[@]}"; do [[ "$selected" == "$file" ]] && found=true; done
                        [[ "$found" == true ]] || external_selected+=("$file")
                        printf 'Loaded: %s\n' "$file"
                    fi
                done
                external_save_selection; pause ;;
            4)
                number=0; for file in "${external_selected[@]}"; do ((number+=1)); printf ' %d) %s\n' "$number" "$file"; done
                IFS= read -r -p 'Selection number (0 cancels): ' selected || return
                local -a retained=()
                number=0; for file in "${external_selected[@]}"; do ((number+=1)); [[ "$selected" == "$number" ]] || retained+=("$file"); done
                external_selected=("${retained[@]}"); external_reload; external_save_selection; pause ;;
            5) external_selected=(); external_reload; external_save_selection; pause ;;
            6) external_scan; external_reload; pause ;;
            *) msg_warn 'Invalid option'; pause ;;
        esac
    done
}

ping_menu() {
    local choice ping_target="" ping_count=4 ping_timeout=2 ping_numeric=false value
    while true; do
        header 'Tool_Box - Ping'
        show_software_description ping
        command=(ping -c "$ping_count" -W "$ping_timeout")
        [[ "$ping_numeric" == true ]] && command+=(-n)
        command+=(-- "${ping_target:-$ip}")
        printf ' 1) IP / Domain: %s\n 2) Requests: %s\n 3) Reply timeout (seconds): %s\n 4) Numeric output: %s\n' "${ping_target:-$ip}" "$ping_count" "$ping_timeout" "$(toggle_status "$ping_numeric")"
        echo ' 5) Reset to global target'
        echo ' 6) Run Ping'
        echo ' 7) Help / Man Page'
        echo ' 0) Back'
        show_command
        menu_prompt choice || return
        case "$choice" in
            0) return ;;
            1) IFS= read -r -p 'IP or domain (blank uses global target): ' ping_target ;;
            2|3)
                IFS= read -r -p 'Whole number from 1 to 3600: ' value
                if [[ "$value" =~ ^[1-9][0-9]{0,3}$ ]] && ((value <= 3600)); then
                    if [[ "$choice" == 2 ]]; then ping_count="$value"; else ping_timeout="$value"; fi
                else msg_warn 'Enter a whole number from 1 to 3600.'; pause; fi ;;
            4) ping_numeric=$(toggle_bool "$ping_numeric") ;;
            5) ping_target="" ;;
            6) require_program ping && run_command_logged recon ping || pause ;;
            7) view_man_page ping ;;
            *) msg_warn 'Invalid option'; pause ;;
        esac
    done
}

# -------------------------
# Software database
# -------------------------
# Tools that have menus/documentation support. Some are also available through
# Tool_Box's apt-based installer; the rest remain menu/documentation-only.
software_keys=(
    ping
    nmap gobuster curl wget nc dig whois traceroute jq openssl
    tcpdump tshark ffuf feroxbuster whatweb nikto smbclient
    enum4linux-ng arp-scan metasploit ipcmd ssh snmpwalk
    ldapsearch showmount rpcinfo
)

# Software Tool_Box can install automatically on apt-based systems.
# Each major section keeps a focused list so it can expose its own
# software-management page without duplicating installer logic.
recon_software_keys=(nmap dig whois traceroute ping)
web_software_keys=(gobuster ffuf feroxbuster whatweb nikto curl openssl)
network_software_keys=(dig whois traceroute arp-scan nc ipcmd)
smb_software_keys=(enum4linux-ng smbclient nmap)
traffic_software_keys=(tcpdump tshark)
utilities_software_keys=(curl wget nc jq openssl)
profile_software_keys=(nmap whatweb curl gobuster smbclient)
service_software_keys=(nmap ssh nc snmpwalk ldapsearch showmount rpcinfo)
vulnerability_software_keys=(nmap)
installable_software_keys=(
    ping
    nmap dig whois traceroute
    gobuster ffuf feroxbuster whatweb nikto curl openssl
    arp-scan nc ipcmd
    enum4linux-ng smbclient
    tcpdump tshark
    wget jq
    ssh snmpwalk ldapsearch showmount rpcinfo
)

declare -A software_display software_command software_package software_status software_man software_repo_status software_description

software_display[ping]="Ping"
software_command[ping]="ping"
software_package[ping]="iputils-ping"
software_man[ping]="ping"
software_description[ping]="Send ICMP echo requests to check host reachability and round-trip time."

software_display[nmap]="Nmap"
software_command[nmap]="nmap"
software_package[nmap]="nmap"
software_man[nmap]="nmap"

software_display[gobuster]="Gobuster"
software_command[gobuster]="gobuster"
software_package[gobuster]="gobuster"
software_man[gobuster]="gobuster"

software_display[curl]="Curl"
software_command[curl]="curl"
software_package[curl]="curl"
software_man[curl]="curl"

software_display[wget]="Wget"
software_command[wget]="wget"
software_package[wget]="wget"
software_man[wget]="wget"

software_display[nc]="Netcat"
software_command[nc]="nc"
software_package[nc]="netcat-openbsd"
software_man[nc]="nc"

software_display[dig]="Dig"
software_command[dig]="dig"
software_package[dig]="dnsutils"
software_man[dig]="dig"

software_display[whois]="Whois"
software_command[whois]="whois"
software_package[whois]="whois"
software_man[whois]="whois"

software_display[traceroute]="Traceroute"
software_command[traceroute]="traceroute"
software_package[traceroute]="traceroute"
software_man[traceroute]="traceroute"

software_display[jq]="JQ"
software_command[jq]="jq"
software_package[jq]="jq"
software_man[jq]="jq"

software_display[openssl]="OpenSSL"
software_command[openssl]="openssl"
software_package[openssl]="openssl"
software_man[openssl]="openssl"

software_display[tcpdump]="tcpdump"
software_command[tcpdump]="tcpdump"
software_package[tcpdump]="tcpdump"
software_man[tcpdump]="tcpdump"

software_display[tshark]="TShark"
software_command[tshark]="tshark"
software_package[tshark]="tshark"
software_man[tshark]="tshark"

software_display[ffuf]="FFUF"
software_command[ffuf]="ffuf"
software_package[ffuf]="ffuf"
software_man[ffuf]="ffuf"

software_display[feroxbuster]="Feroxbuster"
software_command[feroxbuster]="feroxbuster"
software_package[feroxbuster]="feroxbuster"
software_man[feroxbuster]="feroxbuster"

software_display[whatweb]="WhatWeb"
software_command[whatweb]="whatweb"
software_package[whatweb]="whatweb"
software_man[whatweb]="whatweb"

software_display[nikto]="Nikto"
software_command[nikto]="nikto"
software_package[nikto]="nikto"
software_man[nikto]="nikto"

software_display[smbclient]="SMBClient"
software_command[smbclient]="smbclient"
software_package[smbclient]="smbclient"
software_man[smbclient]="smbclient"

software_display[enum4linux-ng]="enum4linux-ng"
software_command[enum4linux-ng]="enum4linux-ng"
software_package[enum4linux-ng]="enum4linux-ng"
software_man[enum4linux-ng]="enum4linux-ng"

software_display[arp-scan]="arp-scan"
software_command[arp-scan]="arp-scan"
software_package[arp-scan]="arp-scan"
software_man[arp-scan]="arp-scan"

software_display[metasploit]="Metasploit"
software_command[metasploit]="msfconsole"
software_package[metasploit]=""
software_man[metasploit]="msfconsole"

software_display[ipcmd]="ip"
software_command[ipcmd]="ip"
software_package[ipcmd]="iproute2"
software_man[ipcmd]="ip"

software_display[ssh]="OpenSSH Client"
software_command[ssh]="ssh"
software_package[ssh]="openssh-client"
software_man[ssh]="ssh"

software_display[snmpwalk]="SNMPWalk"
software_command[snmpwalk]="snmpwalk"
software_package[snmpwalk]="snmp"
software_man[snmpwalk]="snmpwalk"

software_display[ldapsearch]="LDAPSearch"
software_command[ldapsearch]="ldapsearch"
software_package[ldapsearch]="ldap-utils"
software_man[ldapsearch]="ldapsearch"

software_display[showmount]="Showmount"
software_command[showmount]="showmount"
software_package[showmount]="nfs-common"
software_man[showmount]="showmount"

software_display[rpcinfo]="RPCInfo"
software_command[rpcinfo]="rpcinfo"
software_package[rpcinfo]="rpcbind"
software_man[rpcinfo]="rpcinfo"

# Short descriptions shown throughout Tool_Box so every supported external
# tool has a consistent explanation wherever it appears.
software_description[nmap]="Network mapper for host discovery, port scanning, service/version detection, and NSE-based enumeration."
software_description[gobuster]="Content discovery tool that brute-forces web paths, virtual hosts, and DNS names from a wordlist."
software_description[curl]="Command-line data-transfer client commonly used to inspect HTTP/HTTPS requests, responses, headers, and APIs."
software_description[wget]="Command-line downloader for retrieving files and web content over protocols such as HTTP, HTTPS, and FTP."
software_description[nc]="Netcat is a general-purpose TCP/UDP client and listener useful for connectivity tests, banners, and basic network I/O."
software_description[dig]="DNS query utility for inspecting records such as A, AAAA, MX, NS, TXT, and PTR responses."
software_description[whois]="Queries registration and ownership information published by WHOIS/RDAP-compatible registry services."
software_description[traceroute]="Shows the network path toward a destination by reporting the intermediate hops that respond along the route."
software_description[jq]="Command-line JSON processor for formatting, filtering, selecting, and transforming structured JSON data."
software_description[openssl]="Cryptography and TLS toolkit used here for certificate inspection, hashing, and OpenSSL version information."
software_description[tcpdump]="Command-line packet capture and analysis tool for viewing or recording network traffic."
software_description[tshark]="Command-line Wireshark analyzer for reading packet captures and applying protocol/display filters."
software_description[ffuf]="Fast web fuzzer used for content, parameter, virtual-host, and other wordlist-driven HTTP discovery."
software_description[feroxbuster]="Recursive web content discovery tool that searches for hidden files and directories using wordlists."
software_description[whatweb]="Web technology fingerprinting tool that identifies servers, frameworks, CMS platforms, libraries, and related technologies."
software_description[nikto]="Web server scanner that checks for common security issues, risky files, outdated components, and server misconfigurations."
software_description[smbclient]="SMB/CIFS client for listing shares and interactively accessing authorized Windows or Samba file shares."
software_description[enum4linux-ng]="SMB/Windows enumeration utility for collecting information such as shares, users, groups, policies, and host details."
software_description[arp-scan]="Local-network discovery utility that identifies responding hosts by sending ARP requests on a selected interface."
software_description[metasploit]="Metasploit Framework console for authorized security testing, module research, validation, and lab exploitation workflows."
software_description[ipcmd]="Linux iproute2 utility for viewing and managing interfaces, addresses, routes, neighbors, and other network state."
software_description[ssh]="OpenSSH client for secure remote terminal sessions and SSH connectivity or host-key inspection."
software_description[snmpwalk]="Queries an SNMP service recursively to enumerate accessible management information and OID values."
software_description[ldapsearch]="LDAP command-line query client used to inspect directory naming contexts, objects, and attributes."
software_description[showmount]="Queries an NFS server for exported file systems that it reports through the mount service."
software_description[rpcinfo]="Queries RPC port-mapper information to identify registered RPC programs, versions, protocols, and ports."

for software_key in "${software_keys[@]}"; do
    software_status["$software_key"]="Unknown"
    software_repo_status["$software_key"]="Unknown"
done
unset software_key

# -------------------------
# Helpers
# -------------------------
refresh_colors() {
    color_active=false
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_BLUE=""
    C_MAGENTA=""
    C_CYAN=""

    if [[ "$color_enabled" == true && -t 1 && "${TERM:-dumb}" != "dumb" && -z "${NO_COLOR:-}" ]]; then
        color_active=true
        C_RESET=$'\033[0m'
        C_BOLD=$'\033[1m'
        C_DIM=$'\033[2m'
        C_RED=$'\033[31m'
        C_GREEN=$'\033[32m'
        C_YELLOW=$'\033[33m'
        C_BLUE=$'\033[34m'
        C_MAGENTA=$'\033[35m'
        C_CYAN=$'\033[36m'
    fi
}

status_text() {
    local value="$1"
    case "$value" in
        Installed|ON|OK|PASS|true)
            printf '%b' "${C_GREEN}${value}${C_RESET}"
            ;;
        Missing|OFF|FAILED|FAIL|false)
            printf '%b' "${C_RED}${value}${C_RESET}"
            ;;
        Unknown|INFO)
            printf '%b' "${C_DIM}${value}${C_RESET}"
            ;;
        WARN|WARNING|DRY-RUN)
            printf '%b' "${C_YELLOW}${value}${C_RESET}"
            ;;
        *)
            printf '%s' "$value"
            ;;
    esac
}

software_status_text() {
    local key="$1"
    status_text "${software_status[$key]}"
}

show_software_description() {
    local key="$1"
    local description="${software_description[$key]:-}"

    if [[ -z "$description" ]]; then
        description="External command supported by Tool_Box. Use its local man page/help for detailed syntax and options."
    fi

    printf '%b\n' "${C_DIM}Description:${C_RESET} $description"
}

show_module_description() {
    local description="$1"
    printf '%b\n' "${C_DIM}Description:${C_RESET} $description"
}

msg_success() {
    printf '%b\n' "${C_GREEN}[+]${C_RESET} $*"
}

msg_info() {
    printf '%b\n' "${C_BLUE}[*]${C_RESET} $*"
}

msg_warn() {
    printf '%b\n' "${C_YELLOW}[!]${C_RESET} $*"
}

msg_error() {
    printf '%b\n' "${C_RED}[-]${C_RESET} $*"
}

menu_footer() {
    # Global navigation shortcuts are intentionally available from every menu.
    # 0 remains the normal local Back action; M/T/W jump directly to common
    # destinations without requiring the user to climb back through menus.
    if [[ "$current_menu_title" == "Tool_Box" ]]; then
        printf '%b\n' "${C_DIM}[T] Set Target/Data   [W] Workspace   [H] Help${C_RESET}"
    else
        printf '%b\n' "${C_DIM}[0] Back   [M] Main Menu   [T] Set Target/Data   [W] Workspace   [H] Help${C_RESET}"
    fi
}

menu_prompt() {
    local variable_name="$1" input
    echo ""
    menu_footer
    printf '%b' "${C_CYAN}${C_BOLD} # ${C_RESET}"
    IFS= read -r input || exit 0

    case "$input" in
        m|M) restart_main_menu ;;
        t|T)
            set_data_menu
            restart_main_menu
            ;;
        w|W)
            workspace_menu
            restart_main_menu
            ;;
        h|H)
            toolbox_quick_help
            restart_main_menu
            ;;
    esac

    printf -v "$variable_name" '%s' "$input"
}

header() {
    local title="$1"
    current_menu_title="$title"
    refresh_colors
    clear 2>/dev/null || true
    printf '%b\n' "${C_CYAN}${C_BOLD}========================================${C_RESET}"
    printf '%b\n' "  ${C_BOLD}${title}${C_RESET}  ${C_DIM}v${ver}${C_RESET}"
    printf '%b\n' "${C_CYAN}${C_BOLD}========================================${C_RESET}"
    printf '%b\n' "Target : ${C_YELLOW}${ip}/${subnet}${C_RESET}   Ports: ${C_YELLOW}${port}${C_RESET}"
    printf '%b\n' "Output : ${C_BLUE}${output_folder}${C_RESET}"
    if [[ "$workspace_loaded" == true ]]; then
        printf '%b\n' "Project: ${C_MAGENTA}${workspace_name}${C_RESET}"
    else
        printf '%b\n' "Project: ${C_DIM}None${C_RESET}"
    fi
    printf '%b\n' "Modes  : Save $(toggle_status "$auto_save_output")  Verbose $(toggle_status "$verbose_mode")  Dry-Run $(toggle_status "$dry_run_mode")"
    if (( EUID == 0 )); then
        printf '%b\n' "User   : ${C_RED}${C_BOLD}$(id -un) [ROOT]${C_RESET}"
    else
        printf '%b\n' "User   : ${C_GREEN}$(id -un) [standard]${C_RESET}"
    fi
    echo ""
}

pause() {
    printf '%b' "${C_DIM}Press Enter to continue...${C_RESET}"
    IFS= read -r
}

toggle_bool() {
    if [[ "$1" == true ]]; then
        echo false
    else
        echo true
    fi
}

toggle_status() {
    if [[ "$1" == true ]]; then
        printf '%b' "${C_GREEN}ON${C_RESET}"
    else
        printf '%b' "${C_RED}OFF${C_RESET}"
    fi
}

get_first_port() {
    local first="${port%%,*}"
    first="${first%%-*}"
    printf '%s' "$first"
}

validate_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= 1 && $1 <= 65535 ))
}

safe_target_name() {
    local safe="$ip"
    safe="${safe//:/_}"
    safe="${safe//\//_}"
    safe="${safe// /_}"
    printf '%s' "$safe"
}

ensure_output_folder() {
    if [[ -z "$output_folder" ]]; then
        echo "Output folder is not set."
        return 1
    fi

    mkdir -p -- "$output_folder" 2>/dev/null || {
        echo "Unable to create output folder: $output_folder"
        return 1
    }

    if [[ ! -w "$output_folder" ]]; then
        echo "Output folder is not writable: $output_folder"
        return 1
    fi

    return 0
}

ensure_category_folder() {
    local category="$1"
    local target_dir

    ensure_output_folder || return 1
    target_dir="${output_folder%/}/$(safe_target_name)/$category"
    mkdir -p -- "$target_dir" || return 1
    printf '%s' "$target_dir"
}

build_output_file() {
    local category="$1"
    local tool_name="$2"
    local extension="${3:-txt}"
    local timestamp folder

    timestamp=$(date +%Y-%m-%d_%H-%M-%S)
    folder=$(ensure_category_folder "$category") || return 1
    printf '%s/%s-%s-%s.%s' "$folder" "$(safe_target_name)" "$timestamp" "$tool_name" "$extension"
}

show_command() {
    printf '%b' "${C_DIM}Command:${C_RESET} ${C_MAGENTA}"
    printf '%s' "$(format_command_string)"
    printf '%b\n' "${C_RESET}"
}

is_installable_key() {
    local wanted="$1" key
    for key in "${installable_software_keys[@]}"; do
        [[ "$key" == "$wanted" ]] && return 0
    done
    return 1
}

refresh_software_status() {
    local key="$1"
    if is_software_installed "$key"; then
        software_status["$key"]="Installed"
    else
        software_status["$key"]="Missing"
    fi
}

require_program() {
    local key="$1"

    if is_software_installed "$key"; then
        return 0
    fi

    msg_error "${software_display[$key]} is not installed or is not in PATH."
    if is_installable_key "$key"; then
        msg_info "Use Install Software from the main menu to install it."
    else
        msg_info "Tool_Box only provides this tool's menu; it does not install this software."
    fi
    return 1
}

format_command_string() {
    local rendered i redact_next=false
    local -a safe_command=()
    if [[ "${command_display[0]+x}" == x ]]; then
        printf -v rendered '%q ' "${command_display[@]}"
        printf '%s' "${rendered% }"
        return
    fi

    # Keep history useful without persisting supplied SNMP community strings.
    for ((i=0; i<${#command[@]}; i++)); do
        if [[ "$redact_next" == true ]]; then
            safe_command+=("[REDACTED]")
            redact_next=false
            continue
        fi
        safe_command+=("${command[$i]}")
        if [[ "${command[0]##*/}" == "snmpwalk" && "${command[$i]}" == "-c" ]]; then
            redact_next=true
        fi
    done

    printf -v rendered '%q ' "${safe_command[@]}"
    printf '%s' "${rendered% }"
}

record_command_history() {
    local mode="${1:-RUN}" rendered history_file
    rendered="$(format_command_string)"
    command_history+=("$(date '+%Y-%m-%d %H:%M:%S') [$mode] $rendered")

    # Persist history when the output root is available. Failure is non-fatal.
    if ensure_output_folder >/dev/null 2>&1; then
        history_file="${output_folder%/}/tool_box_command_history.log"
        printf '%s
' "${command_history[-1]}" >> "$history_file" 2>/dev/null || true
    fi
}


record_command_result() {
    local status="$1" logfile="${2:-}" history_file entry
    entry="$(date '+%Y-%m-%d %H:%M:%S') [RESULT] target=$ip/$subnet exit=$status"
    [[ -n "$logfile" ]] && entry+=" output=$logfile"
    command_history+=("$entry")
    if ensure_output_folder >/dev/null 2>&1; then
        history_file="${output_folder%/}/tool_box_command_history.log"
        printf '%s\n' "$entry" >> "$history_file" 2>/dev/null || true
    fi
}

confirm_elevated_command() {
    local confirm
    if [[ "$command_requires_privilege" != true ]]; then
        return 0
    fi

    msg_warn "This command requires elevated privileges."
    read -r -p "Continue with the elevated command? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]]
}

handle_dry_run() {
    if [[ "$dry_run_mode" != true ]]; then
        return 1
    fi

    echo ""
    msg_warn "DRY-RUN mode is ON. The command was previewed but NOT executed."
    record_command_history "DRY-RUN"
    command_requires_privilege=false
    pause
    return 0
}

run_command() {
    local confirm status

    echo ""
    echo "----------------------------"
    printf '%b\n' "${C_BOLD}Ready to run:${C_RESET}"
    printf '%b' "  ${C_MAGENTA}"
    printf '%q ' "${command[@]}"
    printf '%b\n' "${C_RESET}"
    [[ "$command_requires_privilege" == true ]] && printf '%b\n' "Privilege: ${C_YELLOW}elevated${C_RESET}"
    [[ "$dry_run_mode" == true ]] && printf '%b\n' "Mode: $(status_text DRY-RUN) (no execution)"
    echo "----------------------------"
    echo ""

    if handle_dry_run; then
        return 0
    fi

    if ! confirm_elevated_command; then
        msg_warn "Elevated command cancelled."
        command_requires_privilege=false
        pause
        return 1
    fi

    read -r -p "Run this command? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        msg_warn "Command cancelled."
        command_requires_privilege=false
        pause
        return 1
    fi

    record_command_history "RUN"
    echo ""
    "${command[@]}"
    status=$?
    record_command_result "$status"
    command_requires_privilege=false
    echo ""
    if (( status == 0 )); then
        msg_success "Command finished with exit status: $status"
    else
        msg_error "Command finished with exit status: $status"
    fi
    pause
    return "$status"
}

run_command_logged() {
    local category="$1"
    local tool_name="$2"
    local confirm status logfile

    echo ""
    echo "----------------------------"
    printf '%b\n' "${C_BOLD}Ready to run:${C_RESET}"
    printf '%b' "  ${C_MAGENTA}"
    printf '%s' "$(format_command_string)"
    printf '%b\n' "${C_RESET}"
    [[ "$command_requires_privilege" == true ]] && printf '%b\n' "Privilege: ${C_YELLOW}elevated${C_RESET}"
    [[ "$dry_run_mode" == true ]] && printf '%b\n' "Mode: $(status_text DRY-RUN) (no execution)"
    echo "----------------------------"

    if [[ "$auto_save_output" == true ]]; then
        logfile=$(build_output_file "$category" "$tool_name") || {
            echo "Unable to create output file."
            command_requires_privilege=false
            pause
            return 1
        }
        echo "Output will also be saved to: $logfile"
    fi
    echo ""

    if handle_dry_run; then
        return 0
    fi

    if ! confirm_elevated_command; then
        msg_warn "Elevated command cancelled."
        command_requires_privilege=false
        pause
        return 1
    fi

    read -r -p "Run this command? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        msg_warn "Command cancelled."
        command_requires_privilege=false
        pause
        return 1
    fi

    record_command_history "RUN"
    echo ""
    if [[ "$auto_save_output" == true ]]; then
        "${command[@]}" 2>&1 | tee "$logfile"
        status=${PIPESTATUS[0]}
        record_command_result "$status" "$logfile"
    else
        "${command[@]}"
        status=$?
        record_command_result "$status"
    fi
    command_requires_privilege=false

    echo ""
    if (( status == 0 )); then
        msg_success "Command finished with exit status: $status"
    else
        msg_error "Command finished with exit status: $status"
    fi
    [[ "$auto_save_output" == true ]] && msg_success "Saved: $logfile"
    pause
    return "$status"
}

run_command_logged_stdin_null() {
    local category="$1"
    local tool_name="$2"
    local confirm status logfile

    echo ""
    echo "----------------------------"
    printf '%b\n' "${C_BOLD}Ready to run:${C_RESET}"
    printf '%b' "  ${C_MAGENTA}"
    printf '%q ' "${command[@]}"
    printf '%b\n' " < /dev/null${C_RESET}"
    [[ "$command_requires_privilege" == true ]] && printf '%b\n' "Privilege: ${C_YELLOW}elevated${C_RESET}"
    [[ "$dry_run_mode" == true ]] && printf '%b\n' "Mode: $(status_text DRY-RUN) (no execution)"
    echo "----------------------------"

    if [[ "$auto_save_output" == true ]]; then
        logfile=$(build_output_file "$category" "$tool_name") || {
            echo "Unable to create output file."
            command_requires_privilege=false
            pause
            return 1
        }
        echo "Output will also be saved to: $logfile"
    fi
    echo ""

    if handle_dry_run; then
        return 0
    fi

    if ! confirm_elevated_command; then
        msg_warn "Elevated command cancelled."
        command_requires_privilege=false
        pause
        return 1
    fi

    read -r -p "Run this command? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        msg_warn "Command cancelled."
        command_requires_privilege=false
        pause
        return 1
    fi

    record_command_history "RUN"
    echo ""
    if [[ "$auto_save_output" == true ]]; then
        "${command[@]}" </dev/null 2>&1 | tee "$logfile"
        status=${PIPESTATUS[0]}
        record_command_result "$status" "$logfile"
    else
        "${command[@]}" </dev/null
        status=$?
        record_command_result "$status"
    fi
    command_requires_privilege=false

    echo ""
    if (( status == 0 )); then
        msg_success "Command finished with exit status: $status"
    else
        msg_error "Command finished with exit status: $status"
    fi
    [[ "$auto_save_output" == true ]] && msg_success "Saved: $logfile"
    pause
    return "$status"
}

run_command_interactive_logged() {
    local category="$1"
    local tool_name="$2"
    local confirm status logfile rendered

    echo ""
    echo "----------------------------"
    printf '%b\n' "${C_BOLD}Ready to run interactive command:${C_RESET}"
    printf '%b' "  ${C_MAGENTA}"
    printf '%q ' "${command[@]}"
    printf '%b\n' "${C_RESET}"
    [[ "$command_requires_privilege" == true ]] && printf '%b\n' "Privilege: ${C_YELLOW}elevated${C_RESET}"
    [[ "$dry_run_mode" == true ]] && printf '%b\n' "Mode: $(status_text DRY-RUN) (no execution)"
    echo "----------------------------"

    if [[ "$auto_save_output" == true ]]; then
        logfile=$(build_output_file "$category" "$tool_name") || {
            echo "Unable to create output file."
            command_requires_privilege=false
            pause
            return 1
        }
        echo "Interactive transcript will be saved to: $logfile"
        if ! command -v script >/dev/null 2>&1; then
            msg_warn "The 'script' utility is unavailable; this interactive session cannot be auto-saved without disrupting its TTY."
        fi
    fi
    echo ""

    if handle_dry_run; then
        return 0
    fi

    if ! confirm_elevated_command; then
        msg_warn "Elevated command cancelled."
        command_requires_privilege=false
        pause
        return 1
    fi

    read -r -p "Run this command? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        msg_warn "Command cancelled."
        command_requires_privilege=false
        pause
        return 1
    fi

    record_command_history "RUN"
    echo ""
    if [[ "$auto_save_output" == true ]] && command -v script >/dev/null 2>&1; then
        printf -v rendered '%q ' "${command[@]}"
        script -q -e -f -c "${rendered% }" "$logfile"
        status=$?
        record_command_result "$status" "$logfile"
    else
        "${command[@]}"
        status=$?
        record_command_result "$status"
    fi
    command_requires_privilege=false

    echo ""
    if (( status == 0 )); then
        msg_success "Command finished with exit status: $status"
    else
        msg_error "Command finished with exit status: $status"
    fi
    [[ "$auto_save_output" == true && -n "${logfile:-}" && -f "$logfile" ]] && msg_success "Saved transcript: $logfile"
    pause
    return "$status"
}

run_privileged_command() {
    command_requires_privilege=true
    if (( EUID == 0 )); then
        command=("$@")
    elif command -v sudo >/dev/null 2>&1; then
        command=(sudo "$@")
    else
        command=("$@")
    fi
}

# -------------------------
# Software detection / docs
# -------------------------
is_software_installed() {
    local key="$1"
    local cmd="${software_command[$key]}"

    [[ -n "$cmd" ]] && command -v "$cmd" >/dev/null 2>&1
}

# Detect the current distribution without sourcing /etc/os-release into the
# script's shell environment.
detect_distribution() {
    distro_id="unknown"
    distro_id_like=""
    distro_pretty="Linux"
    distro_codename=""

    if [[ -r /etc/os-release ]]; then
        local line key value
        while IFS='=' read -r key value; do
            value="${value%\"}"
            value="${value#\"}"
            case "$key" in
                ID) distro_id="$value" ;;
                ID_LIKE) distro_id_like="$value" ;;
                PRETTY_NAME) distro_pretty="$value" ;;
                VERSION_CODENAME) distro_codename="$value" ;;
            esac
        done < /etc/os-release
    fi
}

apt_package_available() {
    local package="$1"
    local candidate

    [[ -n "$package" ]] || return 1
    command -v apt-cache >/dev/null 2>&1 || return 1

    candidate="$(apt-cache policy "$package" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
    [[ -n "$candidate" && "$candidate" != "(none)" ]]
}

refresh_repository_status() {
    local key="$1"
    local package="${software_package[$key]}"

    if is_software_installed "$key"; then
        software_repo_status["$key"]="Installed"
    elif [[ -z "$package" ]] || ! command -v apt-get >/dev/null 2>&1; then
        software_repo_status["$key"]="N/A"
    elif apt_package_available "$package"; then
        software_repo_status["$key"]="Available"
    else
        software_repo_status["$key"]="Unavailable"
    fi
}

repository_status_text() {
    local key="$1"
    local value="${software_repo_status[$key]:-Unknown}"

    case "$value" in
        Installed) printf '%b' "${C_GREEN}Installed${C_RESET}" ;;
        Available) printf '%b' "${C_GREEN}Available${C_RESET}" ;;
        Unavailable) printf '%b' "${C_YELLOW}Unavailable${C_RESET}" ;;
        N/A) printf '%b' "${C_DIM}N/A${C_RESET}" ;;
        *) printf '%s' "$value" ;;
    esac
}

probe_software() {
    local key="$1"

    # Use a harmless version/help invocation for the scan. The executable
    # lookup remains the final status check because some help commands return
    # a non-zero exit code even when the program is installed.
    case "$key" in
        nmap) nmap --version >/dev/null 2>&1 ;;
        gobuster) gobuster version >/dev/null 2>&1 ;;
        curl) curl --version >/dev/null 2>&1 ;;
        wget) wget --version >/dev/null 2>&1 ;;
        nc) nc -h >/dev/null 2>&1 ;;
        dig) dig -v >/dev/null 2>&1 ;;
        whois) whois --version >/dev/null 2>&1 ;;
        traceroute) traceroute --version >/dev/null 2>&1 ;;
        jq) jq --version >/dev/null 2>&1 ;;
        openssl) openssl version >/dev/null 2>&1 ;;
        tcpdump) tcpdump --version >/dev/null 2>&1 ;;
        tshark) tshark --version >/dev/null 2>&1 ;;
        ffuf) ffuf -V >/dev/null 2>&1 ;;
        feroxbuster) feroxbuster --version >/dev/null 2>&1 ;;
        whatweb) whatweb --version >/dev/null 2>&1 ;;
        nikto) nikto -Version >/dev/null 2>&1 ;;
        smbclient) smbclient --version >/dev/null 2>&1 ;;
        enum4linux-ng) enum4linux-ng --version >/dev/null 2>&1 ;;
        arp-scan) arp-scan --version >/dev/null 2>&1 ;;
        metasploit) msfconsole --version >/dev/null 2>&1 ;;
        ipcmd) ip -V >/dev/null 2>&1 ;;
        ssh) ssh -V >/dev/null 2>&1 ;;
        snmpwalk) snmpwalk --version >/dev/null 2>&1 ;;
        ldapsearch) ldapsearch -VV >/dev/null 2>&1 ;;
        showmount) showmount --version >/dev/null 2>&1 ;;
        rpcinfo) rpcinfo --version >/dev/null 2>&1 ;;
    esac
}

scan_software_statuses() {
    local key

    for key in "${installable_software_keys[@]}"; do
        probe_software "$key" || true
        refresh_software_status "$key"
        refresh_repository_status "$key"
    done
}

scan_for_installed_software() {
    local key

    header "Tool_Box - Scan for Installed"
    echo "Checking the software Tool_Box is allowed to install automatically..."
    echo ""

    detect_distribution
    scan_software_statuses

    printf '%-4s %-18s %-12s %s\n' "#" "Software" "Status" "APT Repository"
    echo "--------------------------------------------------------------"
    local i=1
    for key in "${installable_software_keys[@]}"; do
        printf '%-4s %-18s ' "$i" "${software_display[$key]}"
        if [[ "${software_status[$key]}" == "Installed" ]]; then
            printf '%-12b %b\n' "${C_GREEN}Installed${C_RESET}" "$(repository_status_text "$key")"
        else
            printf '%-12b %b\n' "${C_RED}Missing${C_RESET}" "$(repository_status_text "$key")"
        fi
        ((i++))
    done
    echo ""
    printf 'OS: %s\n' "$distro_pretty"
    if command -v apt-get >/dev/null 2>&1; then
        msg_info "Missing + Available means APT can install it now."
        msg_warn "Missing + Unavailable means the configured repositories do not provide the package."
    fi
    echo ""
    pause
}

software_version_output() {
    local key="$1"

    if ! is_software_installed "$key"; then
        echo "${software_display[$key]} is not installed."
        return 1
    fi

    case "$key" in
        nmap) nmap --version | head -n 3 ;;
        gobuster) gobuster version | head -n 3 ;;
        curl) curl --version | head -n 3 ;;
        wget) wget --version | head -n 3 ;;
        nc) nc -h 2>&1 | head -n 3 ;;
        dig) dig -v | head -n 3 ;;
        whois) whois --version 2>&1 | head -n 3 ;;
        traceroute) traceroute --version 2>&1 | head -n 3 ;;
        jq) jq --version | head -n 3 ;;
        openssl) openssl version | head -n 3 ;;
        tcpdump) tcpdump --version 2>&1 | head -n 3 ;;
        tshark) tshark --version 2>&1 | head -n 3 ;;
        ffuf) ffuf -V 2>&1 | head -n 3 ;;
        feroxbuster) feroxbuster --version 2>&1 | head -n 3 ;;
        whatweb) whatweb --version 2>&1 | head -n 3 ;;
        nikto) nikto -Version 2>&1 | head -n 3 ;;
        smbclient) smbclient --version 2>&1 | head -n 3 ;;
        enum4linux-ng) enum4linux-ng --version 2>&1 | head -n 3 ;;
        arp-scan) arp-scan --version 2>&1 | head -n 3 ;;
        metasploit) msfconsole --version 2>&1 | head -n 3 ;;
        ipcmd) ip -V 2>&1 | head -n 3 ;;
        ssh) ssh -V 2>&1 | head -n 3 ;;
        snmpwalk) snmpwalk --version 2>&1 | head -n 3 ;;
        ldapsearch) ldapsearch -VV 2>&1 | head -n 3 ;;
        showmount) showmount --version 2>&1 | head -n 3 ;;
        rpcinfo) rpcinfo --version 2>&1 | head -n 3 ;;
    esac
}

fallback_help() {
    local key="$1"

    case "$key" in
        nmap) nmap --help ;;
        gobuster) gobuster help ;;
        curl) curl --help all ;;
        wget) wget --help ;;
        nc) nc -h ;;
        dig) dig -h ;;
        whois) whois --help ;;
        traceroute) traceroute --help ;;
        jq) jq --help ;;
        openssl) openssl help ;;
        tcpdump) tcpdump -h ;;
        tshark) tshark -h ;;
        ffuf) ffuf -h ;;
        feroxbuster) feroxbuster --help ;;
        whatweb) whatweb --help ;;
        nikto) nikto -Help ;;
        smbclient) smbclient --help ;;
        enum4linux-ng) enum4linux-ng -h ;;
        arp-scan) arp-scan --help ;;
        metasploit) msfconsole -h ;;
        ipcmd) ip -h ;;
        ssh) ssh -h ;;
        snmpwalk) snmpwalk -h ;;
        ldapsearch) ldapsearch -? ;;
        showmount) showmount --help ;;
        rpcinfo) rpcinfo --help ;;
    esac
}

view_man_page() {
    local key="$1"
    local topic="${software_man[$key]}"

    header "Tool_Box - ${software_display[$key]} Documentation"

    if ! is_software_installed "$key"; then
        echo "${software_display[$key]} is not installed or is not in PATH."
        if is_installable_key "$key"; then
            echo "Use Install Software from the main menu to install it."
        else
            echo "This page is available, but Tool_Box does not install this software."
        fi
        pause
        return 1
    fi

    if [[ -n "$topic" ]] && command -v man >/dev/null 2>&1 && man -w "$topic" >/dev/null 2>&1; then
        man "$topic"
    else
        echo "No local man page was found. Showing the program's built-in help instead."
        echo ""
        if command -v less >/dev/null 2>&1; then
            fallback_help "$key" 2>&1 | less
        else
            fallback_help "$key"
            echo ""
            pause
        fi
    fi
}

# -------------------------
# Package installation
# -------------------------
run_root() {
    if (( EUID == 0 )); then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        msg_error "This action requires root privileges, but sudo was not found."
        return 1
    fi
}

run_apt() {
    run_root env DEBIAN_FRONTEND=noninteractive apt-get "$@"
}

ubuntu_component_enabled() {
    local component="$1"

    grep -HsEq "^[[:space:]]*deb[[:space:]].*[[:space:]]${component}([[:space:]]|$)" \
        /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null && return 0

    grep -HsEq "^[[:space:]]*Components:.*[[:space:]]${component}([[:space:]]|$)" \
        /etc/apt/sources.list.d/*.sources 2>/dev/null
}

kali_network_repository_present() {
    grep -HsEq '^[[:space:]]*deb[[:space:]].*http\.kali\.org/kali.*kali-(rolling|last-snapshot)' \
        /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null && return 0

    local file
    for file in /etc/apt/sources.list.d/*.sources; do
        [[ -r "$file" ]] || continue
        if grep -Eq '^[[:space:]]*URIs:[[:space:]]+http://http\.kali\.org/kali/?' "$file" 2>/dev/null && \
           grep -Eq '^[[:space:]]*Suites:[[:space:]]+kali-(rolling|last-snapshot)' "$file" 2>/dev/null; then
            return 0
        fi
    done
    return 1
}

show_active_repositories() {
    header "Tool_Box - Repository Status"
    detect_distribution

    echo "Operating System : $distro_pretty"
    echo "Distribution ID  : $distro_id"
    [[ -n "$distro_codename" ]] && echo "Codename         : $distro_codename"
    echo "APT              : $(command -v apt-get >/dev/null 2>&1 && echo Available || echo Missing)"
    echo ""

    case "$distro_id" in
        ubuntu)
            echo "Ubuntu repository components:"
            if ubuntu_component_enabled universe; then
                printf '  Universe   : %b\n' "${C_GREEN}Enabled${C_RESET}"
            else
                printf '  Universe   : %b\n' "${C_YELLOW}Disabled / not detected${C_RESET}"
            fi
            if ubuntu_component_enabled multiverse; then
                printf '  Multiverse : %b\n' "${C_GREEN}Enabled${C_RESET}"
            else
                printf '  Multiverse : %b\n' "${C_YELLOW}Disabled / not detected${C_RESET}"
            fi
            ;;
        kali)
            if kali_network_repository_present; then
                printf 'Kali network repository: %b\n' "${C_GREEN}Detected${C_RESET}"
            else
                printf 'Kali network repository: %b\n' "${C_YELLOW}Not detected${C_RESET}"
            fi
            ;;
        *)
            msg_info "Tool_Box will inspect this system but will not automatically add foreign distribution repositories."
            ;;
    esac

    echo ""
    echo "Active APT source entries:"
    grep -HsE '^[[:space:]]*(deb[[:space:]]|Types:|URIs:|Suites:|Components:|Signed-By:)' \
        /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources \
        2>/dev/null || echo "  No readable active source entries were found."
    echo ""
    pause
}

enable_standard_repositories() {
    local confirm changed=false suite backup_file

    header "Tool_Box - Enable Standard Repositories"
    detect_distribution
    echo "Detected OS: $distro_pretty"
    echo ""

    if ! command -v apt-get >/dev/null 2>&1; then
        msg_error "APT is not available on this system."
        pause
        return 1
    fi

    case "$distro_id" in
        ubuntu)
            echo "Tool_Box can enable Ubuntu's official Universe and Multiverse components."
            echo "This does NOT add Kali or other foreign repositories."
            echo ""
            read -r -p "Enable missing official Ubuntu components? [y/N]: " confirm
            [[ "$confirm" =~ ^[Yy]$ ]] || { msg_warn "Cancelled."; pause; return 1; }

            if ! command -v add-apt-repository >/dev/null 2>&1; then
                msg_info "Installing software-properties-common for add-apt-repository..."
                run_apt update || { msg_error "apt-get update failed."; pause; return 1; }
                run_apt install -y software-properties-common || { msg_error "Could not install software-properties-common."; pause; return 1; }
            fi

            if ! ubuntu_component_enabled universe; then
                msg_info "Enabling Ubuntu Universe..."
                run_root add-apt-repository -y -c universe && changed=true
            else
                msg_success "Ubuntu Universe is already enabled."
            fi

            if ! ubuntu_component_enabled multiverse; then
                msg_info "Enabling Ubuntu Multiverse..."
                run_root add-apt-repository -y -c multiverse && changed=true
            else
                msg_success "Ubuntu Multiverse is already enabled."
            fi

            if [[ "$changed" == true ]]; then
                run_apt update || msg_warn "Repository changes were made, but apt-get update reported an error."
            else
                msg_info "No repository changes were necessary."
            fi
            ;;

        kali)
            if kali_network_repository_present; then
                msg_success "An official Kali network repository is already configured."
                msg_info "No repository changes were made."
                pause
                return 0
            fi

            if [[ ! -r /usr/share/keyrings/kali-archive-keyring.gpg ]]; then
                msg_error "Kali archive keyring was not found."
                msg_warn "Tool_Box will not create an unsigned or unverified Kali source."
                pause
                return 1
            fi

            suite="kali-rolling"
            [[ "$distro_codename" == "kali-last-snapshot" ]] && suite="kali-last-snapshot"

            echo "The normal Kali network repository is missing."
            echo "Tool_Box can restore the official $suite repository in:"
            echo "  /etc/apt/sources.list.d/kali.sources"
            echo ""
            read -r -p "Restore the official Kali repository? [y/N]: " confirm
            [[ "$confirm" =~ ^[Yy]$ ]] || { msg_warn "Cancelled."; pause; return 1; }

            if [[ -e /etc/apt/sources.list.d/kali.sources ]]; then
                backup_file="/etc/apt/sources.list.d/kali.sources.tool_box.$(date '+%Y%m%d-%H%M%S').bak"
                run_root cp -a /etc/apt/sources.list.d/kali.sources "$backup_file" || {
                    msg_error "Could not back up the existing Kali source file."
                    pause
                    return 1
                }
                msg_info "Backup created: $backup_file"
            fi

            printf 'Types: deb\nURIs: http://http.kali.org/kali/\nSuites: %s\nComponents: main contrib non-free non-free-firmware\nSigned-By: /usr/share/keyrings/kali-archive-keyring.gpg\n' "$suite" | \
                run_root tee /etc/apt/sources.list.d/kali.sources >/dev/null || {
                    msg_error "Could not write the Kali repository file."
                    pause
                    return 1
                }

            msg_success "Official Kali repository restored."
            run_apt update || msg_warn "Repository was written, but apt-get update reported an error."
            ;;

        debian)
            msg_warn "Tool_Box will not automatically add Debian testing/unstable or Kali repositories to Debian."
            msg_info "Use Show Active Repositories and Package Availability to diagnose the current Debian sources."
            ;;

        *)
            msg_warn "Automatic repository changes are not supported for '$distro_id'."
            msg_info "Tool_Box will not add a repository intended for another distribution."
            ;;
    esac

    echo ""
    pause
}

show_package_availability() {
    local key package i=1

    header "Tool_Box - Package Availability"
    detect_distribution
    echo "OS: $distro_pretty"
    echo ""

    if ! command -v apt-cache >/dev/null 2>&1; then
        msg_error "apt-cache is not available."
        pause
        return 1
    fi

    printf '%-4s %-18s %-22s %s\n' "#" "Software" "APT Package" "Repository"
    echo "---------------------------------------------------------------------"
    for key in "${installable_software_keys[@]}"; do
        package="${software_package[$key]}"
        refresh_repository_status "$key"
        printf '%-4s %-18s %-22s %b\n' "$i" "${software_display[$key]}" "$package" "$(repository_status_text "$key")"
        ((i++))
    done

    echo ""
    if [[ "$distro_id" == "ubuntu" ]]; then
        msg_info "On Ubuntu, many security/network utilities are in the Universe component."
        msg_warn "Feroxbuster and enum4linux-ng are not standard Ubuntu APT packages; Tool_Box will not add Kali repositories to Ubuntu."
    elif [[ "$distro_id" == "kali" ]]; then
        msg_info "Kali packages should normally be available when the official Kali network repository is configured and current."
    fi
    echo ""
    pause
}

apt_repository_diagnostics() {
    header "Tool_Box - APT Diagnostics"
    detect_distribution

    echo "Operating System: $distro_pretty"
    echo ""

    if ! command -v apt-get >/dev/null 2>&1; then
        msg_error "apt-get is not available."
        pause
        return 1
    fi

    echo "Running apt-get check..."
    if apt-get check; then
        echo ""
        msg_success "APT dependency check passed."
    else
        echo ""
        msg_error "APT reported dependency/package-state problems."
    fi

    if command -v dpkg >/dev/null 2>&1; then
        echo ""
        echo "dpkg audit:"
        if ! dpkg --audit; then
            msg_warn "dpkg audit reported an issue."
        fi
    fi

    echo ""
    pause
}

repository_manager_menu() {
    local choice

    while true; do
        header "Tool_Box - Repository Troubleshooter"
        detect_distribution
        echo "OS: $distro_pretty"
        echo ""
        echo " 1) Show OS / Active Repositories"
        echo " 2) Enable Standard Repositories for This OS"
        echo " 3) Update Package Lists"
        echo " 4) Check Tool Package Availability"
        echo " 5) Run APT Diagnostics"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) show_active_repositories ;;
            2) enable_standard_repositories ;;
            3) update_package_lists ;;
            4) show_package_availability ;;
            5) apt_repository_diagnostics ;;
            0) return ;;
            *) msg_error "Invalid option."; pause ;;
        esac
    done
}

package_unavailable_hint() {
    local key="$1"
    detect_distribution

    if [[ "$distro_id" == "ubuntu" ]]; then
        case "$key" in
            feroxbuster|enum4linux-ng)
                msg_warn "${software_display[$key]} is not provided by Ubuntu's standard repositories."
                msg_warn "Tool_Box will not add Kali repositories to Ubuntu because mixing distributions can break APT."
                ;;
            *)
                msg_info "On Ubuntu, use Repository Troubleshooter to verify/enable Universe and refresh APT."
                ;;
        esac
    elif [[ "$distro_id" == "kali" ]]; then
        msg_info "Use Repository Troubleshooter to verify the official Kali network repository."
    else
        msg_info "Use Repository Troubleshooter to inspect the configured repositories for this system."
    fi
}

install_software_by_key() {
    local key="$1"
    local package="${software_package[$key]}"
    local display="${software_display[$key]}"
    local confirm

    if ! is_installable_key "$key"; then
        header "Tool_Box - $display"
        echo "Automatic installation is not enabled for $display."
        pause
        return 1
    fi

    if [[ -z "$package" ]]; then
        header "Tool_Box - $display"
        echo "No apt package is configured for $display."
        pause
        return 1
    fi

    header "Tool_Box - Install $display"

    if is_software_installed "$key"; then
        software_status["$key"]="Installed"
        echo "$display is already installed."
        software_version_output "$key"
        pause
        return 0
    fi

    if ! command -v apt-get >/dev/null 2>&1; then
        echo "Automatic installation currently supports apt-based systems"
        echo "such as Debian, Ubuntu, and Kali Linux."
        pause
        return 1
    fi

    echo "Package: $package"
    echo "Tool_Box will refresh APT and verify that the package has a candidate"
    echo "before attempting installation."
    echo ""
    read -r -p "Install $display? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || {
        echo "Installation cancelled."
        pause
        return 1
    }

    run_apt update || {
        msg_error "apt-get update failed."
        msg_info "Open Repository Troubleshooter from Install Software to inspect the configured sources."
        pause
        return 1
    }

    if ! apt_package_available "$package"; then
        software_repo_status["$key"]="Unavailable"
        msg_error "APT cannot find an installation candidate for '$package'."
        package_unavailable_hint "$key"
        echo ""
        read -r -p "Open Repository Troubleshooter now? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            repository_manager_menu
        else
            pause
        fi
        return 1
    fi

    software_repo_status["$key"]="Available"
    if ! run_apt install -y "$package"; then
        msg_error "apt-get install failed for $package."
        msg_info "Repository/package diagnostics are available from Install Software."
        pause
        return 1
    fi

    hash -r 2>/dev/null || true

    if is_software_installed "$key"; then
        software_status["$key"]="Installed"
        software_repo_status["$key"]="Installed"
        echo ""
        msg_success "$display installed successfully."
    else
        software_status["$key"]="Missing"
        echo ""
        msg_error "APT installed '$package', but $display was not detected in PATH."
        msg_info "Try opening a new shell or use the software page to inspect its version/help."
    fi
    pause
}

build_missing_install_plan() {
    available_install_packages=()
    unavailable_install_keys=()
    local key package
    declare -A seen_packages=()

    scan_software_statuses
    for key in "${installable_software_keys[@]}"; do
        [[ "${software_status[$key]}" == "Installed" ]] && continue
        package="${software_package[$key]}"
        [[ -n "$package" ]] || continue

        if apt_package_available "$package"; then
            software_repo_status["$key"]="Available"
            if [[ -z "${seen_packages[$package]:-}" ]]; then
                available_install_packages+=("$package")
                seen_packages["$package"]=1
            fi
        else
            software_repo_status["$key"]="Unavailable"
            unavailable_install_keys+=("$key")
        fi
    done
}

install_missing_software() {
    local key confirm
    local -a available_install_packages=()
    local -a unavailable_install_keys=()

    header "Tool_Box - Install Missing"

    if ! command -v apt-get >/dev/null 2>&1; then
        echo "Automatic installation currently supports apt-based systems."
        pause
        return 1
    fi

    echo "Refreshing package lists before building the install plan..."
    if ! run_apt update; then
        msg_error "apt-get update failed."
        msg_info "Open Repository Troubleshooter to inspect the configured sources."
        pause
        return 1
    fi

    build_missing_install_plan

    if (( ${#available_install_packages[@]} == 0 && ${#unavailable_install_keys[@]} == 0 )); then
        msg_success "All supported software is already installed."
        pause
        return 0
    fi

    echo ""
    if (( ${#available_install_packages[@]} > 0 )); then
        printf '%b\n' "${C_BOLD}Available to install now:${C_RESET}"
        printf '  %s\n' "${available_install_packages[@]}"
    else
        msg_warn "No missing packages currently have an APT installation candidate."
    fi

    if (( ${#unavailable_install_keys[@]} > 0 )); then
        echo ""
        printf '%b\n' "${C_BOLD}Unavailable in current repositories:${C_RESET}"
        for key in "${unavailable_install_keys[@]}"; do
            printf '  %-18s (%s)\n' "${software_display[$key]}" "${software_package[$key]}"
        done
        echo ""
        msg_warn "Unavailable packages will be skipped instead of causing the entire APT install to fail."
        detect_distribution
        if [[ "$distro_id" == "ubuntu" ]]; then
            msg_info "If Universe is disabled, Repository Troubleshooter can enable it."
            msg_warn "Tool_Box will not add Kali repositories to Ubuntu for Kali-only packages."
        fi
    fi

    if (( ${#available_install_packages[@]} > 0 )); then
        echo ""
        read -r -p "Install all currently available missing packages? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            if run_apt install -y "${available_install_packages[@]}"; then
                msg_success "APT installation completed."
            else
                msg_error "APT reported an error while installing the available package set."
            fi
            hash -r 2>/dev/null || true
        else
            msg_warn "Installation skipped."
        fi
    fi

    scan_software_statuses

    if (( ${#unavailable_install_keys[@]} > 0 )); then
        echo ""
        read -r -p "Open Repository Troubleshooter for unavailable packages? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            repository_manager_menu
        fi
    fi

    echo ""
    msg_info "Rescan complete."
    pause
}

update_package_lists() {
    header "Tool_Box - Update Package Lists"
    if ! command -v apt-get >/dev/null 2>&1; then
        echo "apt-get is not available on this system."
        pause
        return
    fi

    local confirm
    read -r -p "Run apt-get update? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        run_apt update
    else
        echo "Cancelled."
    fi
    pause
}

show_all_versions() {
    local key

    header "Tool_Box - Software Versions"
    scan_software_statuses
    for key in "${installable_software_keys[@]}"; do
        echo "----------------------------"
        echo "${software_display[$key]}: ${software_status[$key]}"
        if [[ "${software_status[$key]}" == "Installed" ]]; then
            software_version_output "$key"
        fi
        echo ""
    done
    pause
}

show_missing_software() {
    local key count=0

    header "Tool_Box - Missing Software"
    scan_software_statuses
    for key in "${installable_software_keys[@]}"; do
        if [[ "${software_status[$key]}" != "Installed" ]]; then
            printf ' - %-18s (%-20s) APT: %b\n' "${software_display[$key]}" "${software_package[$key]}" "$(repository_status_text "$key")"
            ((count++))
        fi
    done

    (( count == 0 )) && echo "All supported software is installed."
    echo ""
    pause
}

software_details_menu() {
    local key="$1"
    local choice

    while true; do
        if is_software_installed "$key"; then
            software_status["$key"]="Installed"
        else
            software_status["$key"]="Missing"
        fi

        refresh_repository_status "$key"
        header "Tool_Box - ${software_display[$key]}"
        echo "Status : ${software_status[$key]}"
        echo "Package: ${software_package[$key]}"
        printf 'APT    : %b\n' "$(repository_status_text "$key")"
        show_software_description "$key"
        echo ""
        echo " 1) Install / Repair"
        echo " 2) Show Version"
        echo " 3) View Man Page / Help"
        echo " 4) Repository Troubleshooter"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) install_software_by_key "$key" ;;
            2)
                header "Tool_Box - ${software_display[$key]} Version"
                software_version_output "$key"
                echo ""
                pause
                ;;
            3) view_man_page "$key" ;;
            4) repository_manager_menu ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

install_individual_menu() {
    local choice key i

    while true; do
        scan_software_statuses
        header "Tool_Box - Install / Manage Software"
        echo "Software supported by the Tool_Box apt installer:"
        echo ""
        i=1
        for key in "${installable_software_keys[@]}"; do
            printf '%2d) %-18s : %s\n' "$i" "${software_display[$key]}" "$(software_status_text "$key")"
            ((i++))
        done
        echo " 0) Back"
        echo ""
        menu_prompt choice

        if [[ "$choice" == "0" ]]; then
            return
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#installable_software_keys[@]} )); then
            key="${installable_software_keys[$((choice - 1))]}"
            software_details_menu "$key"
        else
            echo "Invalid option."
            pause
        fi
    done
}

software_dependencies_menu() {
    local choice

    while true; do
        header "Tool_Box - Install Software"
        echo " 1) Scan for Installed"
        echo " 2) Install / Manage Supported Software"
        echo " 3) Install Missing"
        echo " 4) Repository Troubleshooter"
        echo " 5) Update Package Lists"
        echo " 6) Show Supported Software Versions"
        echo " 7) Show Missing Supported Software"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) scan_for_installed_software ;;
            2) install_individual_menu ;;
            3) install_missing_software ;;
            4) repository_manager_menu ;;
            5) update_package_lists ;;
            6) show_all_versions ;;
            7) show_missing_software ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

# -------------------------
# Set Data Menu
# -------------------------
set_data_menu() {
    local choice

    while true; do
        header "Tool_Box - Set Data"
        echo " 1) Set IP"
        echo " 2) Set Subnet"
        echo " 3) Set Port(s)"
        echo " 4) Set Output Folder"
        echo " 5) Domain: $toolbox_domain"
        echo " 6) URL: $toolbox_url"
        echo " 7) Username: $toolbox_username"
        echo " 8) Password: ${toolbox_password:+[set]}"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) set_ip ;;
            2) set_subnet ;;
            3) set_ports ;;
            4) set_output_folder ;;
            5) IFS= read -r -p "Domain: " toolbox_domain ;;
            6) IFS= read -r -p "URL: " toolbox_url ;;
            7) IFS= read -r -p "Username: " toolbox_username ;;
            8) IFS= read -r -s -p "Password (blank clears): " toolbox_password; echo ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

set_ip() {
    local iptemp a b c d

    while true; do
        header "Tool_Box - Set IP"
        read -r -p " Enter an IPv4 address: " iptemp
        IFS='.' read -r a b c d <<< "$iptemp"

        if [[ "$iptemp" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] &&
           (( a >= 0 && a <= 255 )) &&
           (( b >= 0 && b <= 255 )) &&
           (( c >= 0 && c <= 255 )) &&
           (( d >= 0 && d <= 255 )); then
            ip="$iptemp"
            [[ "$workspace_loaded" == true ]] && workspace_save_state >/dev/null 2>&1 || true
            echo "Valid IP: $ip"
            pause
            return
        fi

        echo "Invalid IPv4 address."
        pause
    done
}

set_subnet() {
    local subnettemp

    while true; do
        header "Tool_Box - Set Subnet"
        read -r -p " Enter subnet (1-32): " subnettemp

        if [[ "$subnettemp" =~ ^[0-9]+$ ]] && (( subnettemp >= 1 && subnettemp <= 32 )); then
            subnet="$subnettemp"
            [[ "$workspace_loaded" == true ]] && workspace_save_state >/dev/null 2>&1 || true
            echo "Valid subnet: /$subnet"
            pause
            return
        fi

        echo "Invalid subnet."
        pause
    done
}

set_ports() {
    local porttemp normalized current_port start end valid
    local -a port_parts

    while true; do
        header "Tool_Box - Set Port(s)"
        read -r -p " Enter Port(s) (443, 21-23, 80 443): " porttemp
        normalized="${porttemp//,/ }"
        valid=true

        for current_port in $normalized; do
            if [[ "$current_port" =~ ^[0-9]+$ ]]; then
                if (( current_port < 1 || current_port > 65535 )); then
                    valid=false
                    break
                fi
            elif [[ "$current_port" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                start="${BASH_REMATCH[1]}"
                end="${BASH_REMATCH[2]}"
                if (( start < 1 || start > 65535 || end < 1 || end > 65535 || start > end )); then
                    valid=false
                    break
                fi
            else
                valid=false
                break
            fi
        done

        read -r -a port_parts <<< "$normalized"
        if [[ "$valid" == true && ${#port_parts[@]} -gt 0 ]]; then
            port=$(IFS=,; echo "${port_parts[*]}")
            [[ "$workspace_loaded" == true ]] && workspace_save_state >/dev/null 2>&1 || true
            echo "Valid ports: $port"
            pause
            return
        fi

        echo "Invalid port format."
        pause
    done
}

set_output_folder() {
    local foldertemp create_choice

    while true; do
        header "Tool_Box - Set Output Folder"
        echo "Current output folder: $output_folder"
        echo ""
        read -r -p " Enter output folder path: " foldertemp

        [[ -n "$foldertemp" ]] || {
            echo "Output folder cannot be empty."
            pause
            continue
        }

        if [[ "$foldertemp" == "~" ]]; then
            foldertemp="$HOME"
        elif [[ "$foldertemp" == "~/"* ]]; then
            foldertemp="$HOME/${foldertemp#\~/}"
        fi

        if [[ ! -d "$foldertemp" ]]; then
            read -r -p "Folder does not exist. Create it? [Y/n]: " create_choice
            if [[ "$create_choice" =~ ^[Nn]$ ]]; then
                return
            fi
            mkdir -p -- "$foldertemp" || {
                echo "Unable to create folder."
                pause
                continue
            }
        fi

        [[ -w "$foldertemp" ]] || {
            echo "Folder is not writable."
            pause
            continue
        }

        output_folder="$foldertemp"
        [[ "$workspace_loaded" == true ]] && workspace_save_state >/dev/null 2>&1 || true
        echo "Output folder set to: $output_folder"
        pause
        return
    done
}

# -------------------------
# Nmap
# -------------------------
set_nmap() {
    local choice
    nmap_scan_type=""
    nmap_version=false
    nmap_os=false
    nmap_scripts=false
    nmap_pn=false
    nmap_t4=false
    nmap_aggressive=false
    nmap_custom=""

    nmap_render

    while true; do
        refresh_software_status nmap
        header "Tool_Box - Nmap"
        echo "Status: $(software_status_text nmap)"
        show_software_description nmap
        echo "----------------------------"
        show_command
        echo "----------------------------"
        echo ""
        echo "Scan Type: ${nmap_scan_type:-Default}"
        echo " 1) SYN Scan       [-sS]"
        echo " 2) Connect Scan   [-sT]"
        echo " 3) UDP Scan       [-sU]"
        echo ""
        echo " 4) Version Detection [-sV] : $(toggle_status "$nmap_version")"
        echo " 5) OS Detection      [-O]  : $(toggle_status "$nmap_os")"
        echo " 6) Default Scripts   [-sC] : $(toggle_status "$nmap_scripts")"
        echo " 7) Skip Ping         [-Pn] : $(toggle_status "$nmap_pn")"
        echo " 8) Fast Timing       [-T4] : $(toggle_status "$nmap_t4")"
        echo " 9) Aggressive Scan   [-A]  : $(toggle_status "$nmap_aggressive")"
        echo "10) Custom Options          : $nmap_custom"
        echo "11) Auto-Save Output (Global): $(toggle_status "$auto_save_output")"
        [[ "$auto_save_output" == true ]] && echo "    Output Directory         : $output_folder"
        echo "12) Run Command"
        echo "13) View Nmap Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) nmap_scan_type="-sS" ;;
            2) nmap_scan_type="-sT" ;;
            3) nmap_scan_type="-sU" ;;
            4) nmap_version=$(toggle_bool "$nmap_version") ;;
            5) nmap_os=$(toggle_bool "$nmap_os") ;;
            6) nmap_scripts=$(toggle_bool "$nmap_scripts") ;;
            7) nmap_pn=$(toggle_bool "$nmap_pn") ;;
            8) nmap_t4=$(toggle_bool "$nmap_t4") ;;
            9) nmap_aggressive=$(toggle_bool "$nmap_aggressive") ;;
            10) read -r -p "Enter custom Nmap options: " nmap_custom ;;
            11) auto_save_output=$(toggle_bool "$auto_save_output") ;;
            12)
                require_program nmap || { pause; continue; }
                nmap_render
                run_command_logged "nmap" "nmap"
                ;;
            13) view_man_page nmap ;;
            0) return ;;
            *) echo "Invalid option."; pause; continue ;;
        esac
        nmap_render
    done
}

nmap_render() {
    local -a custom_args

    command=(nmap)

    [[ -n "$nmap_scan_type" ]] && command+=("$nmap_scan_type")
    [[ "$nmap_version" == true ]] && command+=("-sV")
    [[ "$nmap_os" == true ]] && command+=("-O")
    [[ "$nmap_scripts" == true ]] && command+=("-sC")
    [[ "$nmap_pn" == true ]] && command+=("-Pn")
    [[ "$nmap_t4" == true ]] && command+=("-T4")
    [[ "$nmap_aggressive" == true ]] && command+=("-A")

    if [[ -n "$nmap_custom" ]]; then
        read -r -a custom_args <<< "$nmap_custom"
        command+=("${custom_args[@]}")
    fi

    command+=("-p" "$port")

    command+=("$ip/$subnet")
}

# -------------------------
# Gobuster
# -------------------------
set_gobuster() {
    local choice
    gobuster_mode="dir"
    gobuster_https=false
    gobuster_follow=false
    gobuster_expanded=false
    gobuster_insecure=false
    gobuster_quiet=false
    gobuster_threads="$default_threads"
    gobuster_extensions=""
    gobuster_wordlist="$default_wordlist"
    gobuster_custom=""
    gobuster_port="$(get_first_port)"

    gobuster_render

    while true; do
        refresh_software_status gobuster
        header "Tool_Box - Gobuster"
        echo "Status:   $(software_status_text gobuster)"
        show_software_description gobuster
        echo "Mode:     $gobuster_mode"
        echo "Wordlist: $gobuster_wordlist"
        echo "Port:     $gobuster_port"
        echo "----------------------------"
        show_command
        echo "----------------------------"
        echo ""
        echo " 1) HTTPS              : $(toggle_status "$gobuster_https")"
        echo " 2) Follow Redirects   : $(toggle_status "$gobuster_follow")"
        echo " 3) Expanded URLs      : $(toggle_status "$gobuster_expanded")"
        echo " 4) Ignore TLS Cert    : $(toggle_status "$gobuster_insecure")"
        echo " 5) Quiet Mode         : $(toggle_status "$gobuster_quiet")"
        echo " 6) Threads            : $gobuster_threads"
        echo " 7) Extensions         : $gobuster_extensions"
        echo " 8) Wordlist           : $gobuster_wordlist"
        echo " 9) Custom Options     : $gobuster_custom"
        echo "10) Port               : $gobuster_port"
        echo "11) Auto-Save Output (Global): $(toggle_status "$auto_save_output")"
        [[ "$auto_save_output" == true ]] && echo "    Output Directory   : $output_folder"
        echo "12) Run Command"
        echo "13) View Gobuster Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) gobuster_https=$(toggle_bool "$gobuster_https") ;;
            2) gobuster_follow=$(toggle_bool "$gobuster_follow") ;;
            3) gobuster_expanded=$(toggle_bool "$gobuster_expanded") ;;
            4) gobuster_insecure=$(toggle_bool "$gobuster_insecure") ;;
            5) gobuster_quiet=$(toggle_bool "$gobuster_quiet") ;;
            6) read -r -p "Enter number of threads: " gobuster_threads ;;
            7) read -r -p "Enter extensions (php,html,txt): " gobuster_extensions ;;
            8) read -r -p "Enter wordlist path: " gobuster_wordlist ;;
            9) read -r -p "Enter custom Gobuster options: " gobuster_custom ;;
            10)
                read -r -p "Enter Gobuster port: " gobuster_port
                validate_port "$gobuster_port" || { echo "Invalid port."; pause; gobuster_port="$(get_first_port)"; }
                ;;
            11) auto_save_output=$(toggle_bool "$auto_save_output") ;;
            12)
                require_program gobuster || { pause; continue; }
                gobuster_render
                run_command_logged "web" "gobuster"
                ;;
            13) view_man_page gobuster ;;
            0) return ;;
            *) echo "Invalid option."; pause; continue ;;
        esac
        gobuster_render
    done
}

gobuster_render() {
    local protocol url
    local -a custom_args

    command=(gobuster "$gobuster_mode")

    [[ "$gobuster_https" == true ]] && protocol="https" || protocol="http"
    url="$protocol://$ip:$gobuster_port"

    command+=("-u" "$url" "-w" "$gobuster_wordlist" "-t" "$gobuster_threads")
    [[ "$gobuster_follow" == true ]] && command+=("-r")
    [[ "$gobuster_expanded" == true ]] && command+=("-e")
    [[ "$gobuster_insecure" == true ]] && command+=("-k")
    [[ "$gobuster_quiet" == true ]] && command+=("-q")
    [[ -n "$gobuster_extensions" ]] && command+=("-x" "$gobuster_extensions")

    if [[ -n "$gobuster_custom" ]]; then
        read -r -a custom_args <<< "$gobuster_custom"
        command+=("${custom_args[@]}")
    fi
}

# -------------------------
# FFUF
# -------------------------
ffuf_menu() {
    local choice protocol="http" web_port wordlist threads extensions="" custom=""
    local -a custom_args
    web_port="$(get_first_port)"
    wordlist="$default_wordlist"
    threads="$default_threads"

    while true; do
        command=(ffuf -u "$protocol://$ip:$web_port/FUZZ" -w "$wordlist" -t "$threads")
        [[ -n "$extensions" ]] && command+=("-e" "$extensions")
        if [[ -n "$custom" ]]; then
            read -r -a custom_args <<< "$custom"
            command+=("${custom_args[@]}")
        fi

        refresh_software_status ffuf
        header "Tool_Box - FFUF"
        echo "FFUF Status: $(software_status_text ffuf)"
        show_software_description ffuf
        show_command
        echo ""
        echo " 1) Protocol      : $protocol"
        echo " 2) Port          : $web_port"
        echo " 3) Wordlist      : $wordlist"
        echo " 4) Threads       : $threads"
        echo " 5) Extensions    : $extensions"
        echo " 6) Custom Options: $custom"
        echo " 7) Run Command"
        echo " 8) View FFUF Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) [[ "$protocol" == http ]] && protocol=https || protocol=http ;;
            2) read -r -p "Enter port: " web_port; validate_port "$web_port" || web_port="$(get_first_port)" ;;
            3) read -r -p "Enter wordlist: " wordlist ;;
            4) read -r -p "Enter threads: " threads ;;
            5) read -r -p "Enter extensions (example .php,.html): " extensions ;;
            6) read -r -p "Enter custom FFUF options: " custom ;;
            7) require_program ffuf && run_command_logged "web" "ffuf" || pause ;;
            8) view_man_page ffuf ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

# -------------------------
# Feroxbuster
# -------------------------
feroxbuster_menu() {
    local choice protocol="http" web_port wordlist threads extensions="" custom=""
    local -a custom_args
    web_port="$(get_first_port)"
    wordlist="$default_wordlist"
    threads="$default_threads"

    while true; do
        command=(feroxbuster -u "$protocol://$ip:$web_port" -w "$wordlist" -t "$threads")
        [[ -n "$extensions" ]] && command+=("-x" "$extensions")
        if [[ -n "$custom" ]]; then
            read -r -a custom_args <<< "$custom"
            command+=("${custom_args[@]}")
        fi

        refresh_software_status feroxbuster
        header "Tool_Box - Feroxbuster"
        echo "Feroxbuster Status: $(software_status_text feroxbuster)"
        show_software_description feroxbuster
        show_command
        echo ""
        echo " 1) Protocol      : $protocol"
        echo " 2) Port          : $web_port"
        echo " 3) Wordlist      : $wordlist"
        echo " 4) Threads       : $threads"
        echo " 5) Extensions    : $extensions"
        echo " 6) Custom Options: $custom"
        echo " 7) Run Command"
        echo " 8) View Feroxbuster Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) [[ "$protocol" == http ]] && protocol=https || protocol=http ;;
            2) read -r -p "Enter port: " web_port; validate_port "$web_port" || web_port="$(get_first_port)" ;;
            3) read -r -p "Enter wordlist: " wordlist ;;
            4) read -r -p "Enter threads: " threads ;;
            5) read -r -p "Enter extensions (example php html): " extensions ;;
            6) read -r -p "Enter custom Feroxbuster options: " custom ;;
            7) require_program feroxbuster && run_command_logged "web" "feroxbuster" || pause ;;
            8) view_man_page feroxbuster ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

# -------------------------
# Web helper pages
# -------------------------
whatweb_menu() {
    local choice protocol="http" web_port
    web_port="$(get_first_port)"

    while true; do
        command=(whatweb "$protocol://$ip:$web_port")
        refresh_software_status whatweb
        header "Tool_Box - WhatWeb"
        echo "WhatWeb Status: $(software_status_text whatweb)"
        show_software_description whatweb
        show_command
        echo ""
        echo " 1) Protocol: $protocol"
        echo " 2) Port    : $web_port"
        echo " 3) Run WhatWeb"
        echo " 4) View WhatWeb Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) [[ "$protocol" == http ]] && protocol=https || protocol=http ;;
            2) read -r -p "Enter port: " web_port; validate_port "$web_port" || web_port="$(get_first_port)" ;;
            3) require_program whatweb && run_command_logged "web" "whatweb" || pause ;;
            4) view_man_page whatweb ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

nikto_menu() {
    local choice protocol="http" web_port
    web_port="$(get_first_port)"

    while true; do
        command=(nikto -h "$protocol://$ip:$web_port")
        refresh_software_status nikto
        header "Tool_Box - Nikto"
        echo "Nikto Status: $(software_status_text nikto)"
        show_software_description nikto
        show_command
        echo ""
        echo " 1) Protocol: $protocol"
        echo " 2) Port    : $web_port"
        echo " 3) Run Nikto"
        echo " 4) View Nikto Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) [[ "$protocol" == http ]] && protocol=https || protocol=http ;;
            2) read -r -p "Enter port: " web_port; validate_port "$web_port" || web_port="$(get_first_port)" ;;
            3) require_program nikto && run_command_logged "web" "nikto" || pause ;;
            4) view_man_page nikto ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

http_headers_menu() {
    local choice protocol="http" web_port
    web_port="$(get_first_port)"

    while true; do
        command=(curl -I "$protocol://$ip:$web_port")
        refresh_software_status curl
        header "Tool_Box - HTTP Headers (Curl)"
        echo "Curl Status: $(software_status_text curl)"
        show_software_description curl
        show_command
        echo ""
        echo " 1) Protocol: $protocol"
        echo " 2) Port    : $web_port"
        echo " 3) Run Header Request"
        echo " 4) View Curl Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) [[ "$protocol" == http ]] && protocol=https || protocol=http ;;
            2) read -r -p "Enter port: " web_port; validate_port "$web_port" || web_port="$(get_first_port)" ;;
            3) require_program curl && run_command_logged "web" "http-headers" || pause ;;
            4) view_man_page curl ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

tls_certificate_menu() {
    local choice web_port server_name
    web_port="$(get_first_port)"
    server_name="$ip"

    while true; do
        command=(openssl s_client -connect "$ip:$web_port" -servername "$server_name" -showcerts)
        refresh_software_status openssl
        header "Tool_Box - TLS Certificate (OpenSSL)"
        echo "OpenSSL Status: $(software_status_text openssl)"
        show_software_description openssl
        show_command
        echo ""
        echo " 1) Port       : $web_port"
        echo " 2) Server Name: $server_name"
        echo " 3) Run TLS Inspection"
        echo " 4) View OpenSSL Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter TLS port: " web_port; validate_port "$web_port" || web_port="$(get_first_port)" ;;
            2) read -r -p "Enter SNI/server name: " server_name ;;
            3) require_program openssl && run_command_logged_stdin_null "web" "tls-certificate" || pause ;;
            4) view_man_page openssl ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

test_http_menu() {
    local choice protocol="http" web_port
    web_port="$(get_first_port)"

    while true; do
        command=(curl -v --max-time 15 "$protocol://$ip:$web_port/")
        refresh_software_status curl
        header "Tool_Box - Test HTTP/HTTPS"
        echo "Curl Status: $(software_status_text curl)"
        show_software_description curl
        show_command
        echo ""
        echo " 1) Protocol: $protocol"
        echo " 2) Port    : $web_port"
        echo " 3) Run Test"
        echo " 4) View Curl Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) [[ "$protocol" == http ]] && protocol=https || protocol=http ;;
            2) read -r -p "Enter port: " web_port; validate_port "$web_port" || web_port="$(get_first_port)" ;;
            3) require_program curl && run_command_logged "web" "curl-test" || pause ;;
            4) view_man_page curl ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

web_enumeration_software_menu() {
    local choice key i

    while true; do
        scan_software_statuses
        header "Tool_Box - Web Enumeration Software"
        echo "Web Enumeration tools supported by the apt installer:"
        echo ""
        i=1
        for key in "${web_software_keys[@]}"; do
            printf '%2d) %-18s : %-9s  Package: %s\n' \
                "$i" "${software_display[$key]}" "${software_status[$key]}" "${software_package[$key]}"
            ((i++))
        done
        echo " 0) Back"
        echo ""
        menu_prompt choice

        if [[ "$choice" == "0" ]]; then
            return
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#web_software_keys[@]} )); then
            key="${web_software_keys[$((choice - 1))]}"
            software_details_menu "$key"
        else
            echo "Invalid option."
            pause
        fi
    done
}

web_enumeration_menu() {
    local choice
    while true; do
        header "Tool_Box - Web Enumeration"
        echo " 1) Gobuster"
        echo " 2) FFUF"
        echo " 3) Feroxbuster"
        echo " 4) WhatWeb"
        echo " 5) Nikto"
        echo " 6) HTTP Headers (Curl)"
        echo " 7) TLS Certificate (OpenSSL)"
        echo " 8) Test HTTP/HTTPS"
        echo " 9) Web Enumeration Software"
        external_render "web enumeration"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) set_gobuster ;;
            2) ffuf_menu ;;
            3) feroxbuster_menu ;;
            4) whatweb_menu ;;
            5) nikto_menu ;;
            6) http_headers_menu ;;
            7) tls_certificate_menu ;;
            8) test_http_menu ;;
            9) web_enumeration_software_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "web enumeration" || { echo "Invalid option."; pause; } ;;
        esac
    done
}


# -------------------------
# Workspaces / Projects
# -------------------------
workspace_root_path() {
    printf '%s/workspaces' "${output_folder%/}"
}

sanitize_workspace_name() {
    local value="$1"
    value="${value// /_}"
    value="${value//[^A-Za-z0-9._-]/_}"
    value="${value##_}"
    value="${value%%_}"
    printf '%s' "$value"
}

require_workspace() {
    if [[ "$workspace_loaded" != true || -z "$workspace_dir" || ! -d "$workspace_dir" ]]; then
        msg_error "No workspace is currently loaded."
        msg_info "Open Target & Scanning -> Workspace / Project first."
        pause
        return 1
    fi
    return 0
}

workspace_save_state() {
    local state_file
    [[ "$workspace_loaded" == true && -n "$workspace_dir" ]] || return 1
    mkdir -p -- "$workspace_dir" || return 1
    state_file="$workspace_dir/workspace.conf"
    {
        printf 'workspace_name=%s\n' "$workspace_name"
        printf 'ip=%s\n' "$ip"
        printf 'subnet=%s\n' "$subnet"
        printf 'port=%s\n' "$port"
        printf 'default_wordlist=%s\n' "$default_wordlist"
        printf 'default_threads=%s\n' "$default_threads"
        printf 'output_folder=%s\n' "$output_folder"
        printf 'updated=%s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    } > "$state_file" || return 1
    chmod 600 "$state_file" 2>/dev/null || true
    return 0
}

create_workspace() {
    local root requested safe confirm
    header "Tool_Box - Create Workspace"
    root="$(workspace_root_path)"
    mkdir -p -- "$root" || { msg_error "Unable to create workspace root: $root"; pause; return 1; }
    read -r -p "Workspace name: " requested
    safe="$(sanitize_workspace_name "$requested")"
    [[ -n "$safe" ]] || { msg_error "Workspace name cannot be empty."; pause; return 1; }

    if [[ -e "$root/$safe" ]]; then
        msg_warn "Workspace already exists: $safe"
        read -r -p "Load the existing workspace instead? [y/N]: " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || { pause; return 0; }
        workspace_name="$safe"
        workspace_dir="$root/$safe"
        workspace_loaded=true
        load_workspace_state_file "$workspace_dir/workspace.conf"
        msg_success "Loaded workspace: $workspace_name"
        pause
        return 0
    fi

    workspace_name="$safe"
    workspace_dir="$root/$safe"
    workspace_loaded=true
    mkdir -p -- "$workspace_dir" || { msg_error "Unable to create workspace."; workspace_loaded=false; pause; return 1; }
    : > "$workspace_dir/notes.md"
    : > "$workspace_dir/findings.tsv"
    : > "$workspace_dir/services.tsv"
    chmod 600 "$workspace_dir/findings.tsv" "$workspace_dir/workspace.conf" 2>/dev/null || true
    workspace_save_state
    msg_success "Created workspace: $workspace_name"
    echo "Workspace directory: $workspace_dir"
    pause
}

load_workspace_state_file() {
    local state_file="$1" line key value
    [[ -f "$state_file" ]] || return 0
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == *=* ]] || continue
        key="${line%%=*}"
        value="${line#*=}"
        case "$key" in
            workspace_name) [[ -n "$value" ]] && workspace_name="$value" ;;
            ip) [[ -n "$value" ]] && ip="$value" ;;
            subnet) [[ "$value" =~ ^[0-9]+$ ]] && subnet="$value" ;;
            port) [[ -n "$value" ]] && port="$value" ;;
            default_wordlist) [[ -n "$value" ]] && default_wordlist="$value" ;;
            default_threads) [[ "$value" =~ ^[0-9]+$ ]] && default_threads="$value" ;;
            output_folder) [[ -n "$value" ]] && output_folder="$value" ;;
        esac
    done < "$state_file"
}

select_workspace() {
    local root choice i
    local -a dirs=()
    root="$(workspace_root_path)"
    mkdir -p -- "$root" 2>/dev/null || true
    mapfile -t dirs < <(find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort)
    header "Tool_Box - Load Workspace"
    if ((${#dirs[@]} == 0)); then
        echo "No workspaces exist under: $root"
        pause
        return 1
    fi
    for ((i=0; i<${#dirs[@]}; i++)); do
        printf ' %2d) %s\n' "$((i+1))" "${dirs[$i]}"
    done
    echo "  0) Cancel"
    echo ""
    menu_prompt choice
    [[ "$choice" == 0 ]] && return 1
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#dirs[@]} )); then
        workspace_name="${dirs[$((choice-1))]}"
        workspace_dir="$root/$workspace_name"
        workspace_loaded=true
        load_workspace_state_file "$workspace_dir/workspace.conf"
        workspace_save_state
        msg_success "Loaded workspace: $workspace_name"
        pause
        return 0
    fi
    msg_error "Invalid workspace selection."
    pause
    return 1
}

list_workspaces() {
    local root dir
    header "Tool_Box - Workspaces"
    root="$(workspace_root_path)"
    if [[ ! -d "$root" ]]; then
        echo "No workspaces have been created yet."
    else
        while IFS= read -r dir; do
            printf ' - %s\n' "$(basename "$dir")"
        done < <(find "$root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
    fi
    echo ""
    echo "Workspace root: $root"
    pause
}

unload_workspace() {
    header "Tool_Box - Unload Workspace"
    if [[ "$workspace_loaded" != true ]]; then
        msg_info "No workspace is loaded."
        pause
        return 0
    fi
    workspace_save_state
    msg_success "Unloaded workspace: $workspace_name"
    workspace_name=""
    workspace_dir=""
    workspace_loaded=false
    pause
}

archive_workspace() {
    local archive_root archive_file confirm
    require_workspace || return 1
    header "Tool_Box - Archive Workspace"
    archive_root="${output_folder%/}/workspace_archives"
    mkdir -p -- "$archive_root" || { msg_error "Unable to create archive directory."; pause; return 1; }
    archive_file="$archive_root/${workspace_name}-$(date +%Y-%m-%d_%H-%M-%S).tar.gz"
    echo "Workspace: $workspace_dir"
    echo "Archive  : $archive_file"
    read -r -p "Create archive? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { msg_warn "Cancelled."; pause; return 0; }
    tar -czf "$archive_file" -C "$(dirname "$workspace_dir")" "$(basename "$workspace_dir")" && \
        msg_success "Created: $archive_file"
    pause
}


delete_workspace() {
    local root resolved_root resolved_dir typed
    require_workspace || return 1
    header "Tool_Box - Delete Workspace"
    root="$(workspace_root_path)"
    resolved_root="$(realpath -m -- "$root" 2>/dev/null)"
    resolved_dir="$(realpath -m -- "$workspace_dir" 2>/dev/null)"
    if [[ -z "$resolved_root" || -z "$resolved_dir" || "$resolved_dir" != "$resolved_root"/* ]]; then
        msg_error "Refusing to delete a directory outside the workspace root."
        pause
        return 1
    fi
    msg_warn "This permanently deletes workspace metadata, notes, findings, and imported services."
    echo "Workspace: $workspace_name"
    echo "Path     : $resolved_dir"
    echo ""
    read -r -p "Type the workspace name to confirm deletion: " typed
    [[ "$typed" == "$workspace_name" ]] || { msg_warn "Confirmation did not match. Cancelled."; pause; return 0; }
    rm -rf -- "$resolved_dir" && {
        msg_success "Workspace deleted."
        workspace_name=""
        workspace_dir=""
        workspace_loaded=false
    }
    pause
}

workspace_notes_menu() {
    local choice note category editor notes_file
    require_workspace || return 1
    notes_file="$workspace_dir/notes.md"
    touch "$notes_file"
    while true; do
        header "Tool_Box - Workspace Notes"
        echo "Workspace: $workspace_name"
        echo "Notes    : $notes_file"
        echo ""
        echo " 1) Add Note"
        echo " 2) View Notes"
        echo " 3) Edit Notes in Editor"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Category (General/To-Do/Credentials/Host/etc.): " category
                [[ -n "$category" ]] || category="General"
                read -r -p "Note: " note
                [[ -n "$note" ]] || { msg_warn "Nothing added."; pause; continue; }
                {
                    printf '\n### %s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$category"
                    printf '%s\n' "$note"
                } >> "$notes_file"
                workspace_save_state
                msg_success "Note added."
                pause
                ;;
            2)
                header "Tool_Box - Workspace Notes - $workspace_name"
                if [[ -s "$notes_file" ]]; then
                    if command -v less >/dev/null 2>&1; then less "$notes_file"; else cat "$notes_file"; pause; fi
                else
                    echo "No notes yet."
                    pause
                fi
                ;;
            3)
                editor="${EDITOR:-}"
                if [[ -z "$editor" ]]; then
                    if command -v nano >/dev/null 2>&1; then editor="nano"; elif command -v vi >/dev/null 2>&1; then editor="vi"; fi
                fi
                if [[ -n "$editor" ]]; then
                    "$editor" "$notes_file"
                    workspace_save_state
                else
                    msg_error "No editor was found. Set EDITOR or install nano/vi."
                    pause
                fi
                ;;
            0) return ;;
            *) msg_error "Invalid option."; pause ;;
        esac
    done
}

workspace_findings_menu() {
    local choice category value search findings_file
    require_workspace || return 1
    findings_file="$workspace_dir/findings.tsv"
    touch "$findings_file"
    chmod 600 "$findings_file" 2>/dev/null || true
    while true; do
        header "Tool_Box - Findings / Loot Tracker"
        echo "Workspace: $workspace_name"
        echo ""
        msg_warn "Findings are stored locally in plaintext. Protect the workspace directory."
        echo ""
        echo " 1) Add Finding"
        echo " 2) View Findings"
        echo " 3) Search Findings"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1)
                echo "Categories: host, service, username, credential, url, file, hash, other"
                read -r -p "Category: " category
                [[ -n "$category" ]] || category="other"
                read -r -p "Finding: " value
                [[ -n "$value" ]] || { msg_warn "Nothing added."; pause; continue; }
                value="${value//$'\t'/ }"
                printf '%s\t%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$category" "$value" >> "$findings_file"
                workspace_save_state
                msg_success "Finding saved."
                pause
                ;;
            2)
                header "Tool_Box - Findings - $workspace_name"
                if [[ -s "$findings_file" ]]; then
                    printf '%-20s %-14s %s\n' "Timestamp" "Category" "Finding"
                    echo "--------------------------------------------------------------------------"
                    awk -F '\t' '{printf "%-20s %-14s %s\\n", $1, $2, $3}' "$findings_file"
                else
                    echo "No findings yet."
                fi
                echo ""
                pause
                ;;
            3)
                read -r -p "Search term: " search
                header "Tool_Box - Search Findings"
                if [[ -n "$search" ]]; then
                    grep -in -- "$search" "$findings_file" || echo "No matches."
                fi
                echo ""
                pause
                ;;
            0) return ;;
            *) msg_error "Invalid option."; pause ;;
        esac
    done
}

workspace_services_file() {
    [[ "$workspace_loaded" == true ]] && printf '%s/services.tsv' "$workspace_dir"
}

import_nmap_results() {
    local scan_file services_file temp_file parser_output first_host imported_ports count rc
    require_workspace || return 1
    header "Tool_Box - Import Nmap Results"
    echo "Supported: Nmap XML, grepable (.gnmap), and normal text output."
    echo ""
    read -r -p "Nmap result file: " scan_file
    [[ -f "$scan_file" ]] || { msg_error "File not found."; pause; return 1; }
    command -v python3 >/dev/null 2>&1 || { msg_error "python3 is required for Nmap import."; pause; return 1; }

    services_file="$(workspace_services_file)"
    temp_file="${services_file}.tmp"
    parser_output=$(python3 - "$scan_file" "$temp_file" <<'PYCODE'
import sys, re, xml.etree.ElementTree as ET
src, out = sys.argv[1], sys.argv[2]
rows=[]
first_host=""
text=open(src,'r',errors='replace').read()

def add(host, proto, port, service="", product="", version=""):
    global first_host
    if not first_host and host:
        first_host=host
    row=(host or "", proto or "", str(port or ""), service or "", product or "", version or "")
    if row not in rows:
        rows.append(row)

is_xml = src.lower().endswith('.xml') or text.lstrip().startswith('<?xml') or '<nmaprun' in text[:500]
if is_xml:
    try:
        root=ET.fromstring(text)
        for host in root.findall('host'):
            addr=''
            for a in host.findall('address'):
                if a.get('addrtype') in ('ipv4','ipv6'):
                    addr=a.get('addr',''); break
            for p in host.findall('./ports/port'):
                state=p.find('state')
                if state is None or state.get('state')!='open':
                    continue
                svc=p.find('service')
                add(addr,p.get('protocol',''),p.get('portid',''),
                    svc.get('name','') if svc is not None else '',
                    svc.get('product','') if svc is not None else '',
                    svc.get('version','') if svc is not None else '')
    except Exception as e:
        print(f'ERROR={e}')
        sys.exit(2)
elif 'Ports:' in text:
    for line in text.splitlines():
        m=re.search(r'^Host:\s+(\S+).*?Ports:\s+(.*?)(?:\s+Ignored State:|$)', line)
        if not m: continue
        host=m.group(1)
        for item in m.group(2).split(','):
            parts=item.strip().split('/')
            if len(parts)>=5 and parts[1]=='open':
                add(host, parts[2], parts[0], parts[4])
else:
    current=''
    for line in text.splitlines():
        m=re.search(r'Nmap scan report for (?:.*?\()?((?:\d{1,3}\.){3}\d{1,3})\)?$', line)
        if m: current=m.group(1)
        m=re.match(r'^(\d+)/(tcp|udp)\s+open\s+(\S+)(?:\s+(.*))?$', line.strip())
        if m:
            extra=(m.group(4) or '').strip()
            add(current, m.group(2), m.group(1), m.group(3), extra, '')

rows.sort(key=lambda r:(r[0],r[1],int(r[2]) if str(r[2]).isdigit() else 0))
with open(out,'w') as f:
    for r in rows:
        f.write('\t'.join(x.replace('\t',' ') for x in r)+'\n')
ports=sorted({int(r[2]) for r in rows if str(r[2]).isdigit()})
print('HOST='+first_host)
print('PORTS='+','.join(map(str,ports)))
print('COUNT='+str(len(rows)))
PYCODE
)
    rc=$?
    if (( rc != 0 )); then
        rm -f "$temp_file"
        msg_error "Unable to parse Nmap results."
        echo "$parser_output"
        pause
        return "$rc"
    fi
    mv -- "$temp_file" "$services_file"
    first_host="$(printf '%s\n' "$parser_output" | sed -n 's/^HOST=//p' | head -n1)"
    imported_ports="$(printf '%s\n' "$parser_output" | sed -n 's/^PORTS=//p' | head -n1)"
    count="$(printf '%s\n' "$parser_output" | sed -n 's/^COUNT=//p' | head -n1)"

    if [[ "$first_host" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        ip="$first_host"
    fi
    [[ -n "$imported_ports" ]] && port="$imported_ports"
    workspace_save_state
    msg_success "Imported ${count:-0} open service entries."
    echo "Service inventory: $services_file"
    [[ -n "$first_host" ]] && echo "Current target updated to first imported host: $ip"
    [[ -n "$imported_ports" ]] && echo "Selected ports updated to: $port"
    echo ""
    pause
}

service_recommendation() {
    local service="${1,,}" p="$2"
    case "$p" in
        21) echo "FTP -> Service Enumeration" ;;
        22) echo "SSH -> Service Enumeration" ;;
        23) echo "Telnet -> Service Enumeration" ;;
        25|465|587) echo "SMTP -> Service Enumeration" ;;
        53) echo "DNS -> Network / DNS" ;;
        80|443|8000|8008|8080|8081|8443|8888) echo "HTTP(S) -> Web Enumeration" ;;
        111) echo "RPC -> Service Enumeration" ;;
        139|445) echo "SMB -> SMB / Windows" ;;
        161|162) echo "SNMP -> Service Enumeration" ;;
        389|636) echo "LDAP -> Service Enumeration" ;;
        2049) echo "NFS -> Service Enumeration" ;;
        3306) echo "MySQL -> Service Enumeration" ;;
        3389) echo "RDP -> SMB / Windows / Service Enumeration" ;;
        5432) echo "PostgreSQL -> Service Enumeration" ;;
        *)
            case "$service" in
                http*|ssl/http*) echo "Web service -> Web Enumeration" ;;
                microsoft-ds|netbios*) echo "SMB -> SMB / Windows" ;;
                domain) echo "DNS -> Network / DNS" ;;
                ssh|ftp|smtp|snmp|ldap|rpcbind|nfs) echo "$service -> Service Enumeration" ;;
                *) echo "General service -> Reconnaissance / Service Enumeration" ;;
            esac
            ;;
    esac
}

service_recommendations_page() {
    local services_file host proto p service product version recommendation
    header "Tool_Box - Service-Aware Recommendations"
    if [[ "$workspace_loaded" == true ]]; then
        services_file="$(workspace_services_file)"
    else
        services_file=""
    fi

    if [[ -n "$services_file" && -s "$services_file" ]]; then
        printf '%-15s %-5s %-6s %-18s %s\n' "Host" "Proto" "Port" "Service" "Recommended Tool_Box Area"
        echo "------------------------------------------------------------------------------------------"
        while IFS=$'\t' read -r host proto p service product version; do
            recommendation="$(service_recommendation "$service" "$p")"
            printf '%-15s %-5s %-6s %-18s %s\n' "$host" "$proto" "$p" "${service:-unknown}" "$recommendation"
        done < "$services_file"
    else
        msg_info "No imported service inventory is available. Recommendations based on selected ports:"
        echo ""
        IFS=',' read -ra selected_ports <<< "$port"
        for p in "${selected_ports[@]}"; do
            p="${p%%-*}"
            [[ "$p" =~ ^[0-9]+$ ]] || continue
            printf ' Port %-6s %s\n' "$p" "$(service_recommendation "" "$p")"
        done
    fi
    echo ""
    echo "Recommendations do not automatically run scans; they point you to the relevant existing menu."
    pause
}

workspace_dashboard() {
    local notes findings services result_dir files=0 notes_count=0 findings_count=0 services_count=0 size="0"
    require_workspace || return 1
    notes="$workspace_dir/notes.md"
    findings="$workspace_dir/findings.tsv"
    services="$workspace_dir/services.tsv"
    result_dir="${output_folder%/}/$(safe_target_name)"
    [[ -d "$result_dir" ]] && files="$(find "$result_dir" -type f 2>/dev/null | wc -l)"
    [[ -d "$result_dir" ]] && size="$(du -sh "$result_dir" 2>/dev/null | awk '{print $1}')"
    [[ -f "$notes" ]] && notes_count="$(grep -c '^### ' "$notes" 2>/dev/null || true)"
    [[ -f "$findings" ]] && findings_count="$(grep -cve '^$' "$findings" 2>/dev/null || true)"
    [[ -f "$services" ]] && services_count="$(grep -cve '^$' "$services" 2>/dev/null || true)"

    header "Tool_Box - Workspace Dashboard"
    echo "Workspace       : $workspace_name"
    echo "Workspace path  : $workspace_dir"
    echo "Target          : $ip/$subnet"
    echo "Selected ports  : $port"
    echo "Result directory: $result_dir"
    echo ""
    printf ' Result files    : %s\n' "$files"
    printf ' Result size     : %s\n' "${size:-0}"
    printf ' Imported services: %s\n' "$services_count"
    printf ' Notes           : %s\n' "$notes_count"
    printf ' Findings        : %s\n' "$findings_count"
    echo ""
    pause
}

workspace_menu() {
    local choice
    while true; do
        header "Tool_Box - Workspace / Project"
        if [[ "$workspace_loaded" == true ]]; then
            echo "Active workspace: $workspace_name"
            echo "Path            : $workspace_dir"
        else
            echo "Active workspace: None"
        fi
        echo ""
        echo " 1) Create Workspace"
        echo " 2) Load Workspace"
        echo " 3) Save Current Workspace State"
        echo " 4) Workspace Dashboard"
        echo " 5) Notes"
        echo " 6) Findings / Loot Tracker"
        echo " 7) Import Nmap Results"
        echo " 8) Service-Aware Recommendations"
        echo " 9) List Workspaces"
        echo "10) Archive Current Workspace"
        echo "11) Unload Workspace"
        echo "12) Delete Current Workspace"
        external_render "workspace / project"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) create_workspace ;;
            2) select_workspace ;;
            3) require_workspace && workspace_save_state && msg_success "Workspace state saved."; pause ;;
            4) workspace_dashboard ;;
            5) workspace_notes_menu ;;
            6) workspace_findings_menu ;;
            7) import_nmap_results ;;
            8) service_recommendations_page ;;
            9) list_workspaces ;;
            10) archive_workspace ;;
            11) unload_workspace ;;
            12) delete_workspace ;;
            0) return ;;
            *) external_dispatch "$choice" "workspace / project" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

# -------------------------
# Reconnaissance
# -------------------------
host_discovery_menu() {
    local choice
    while true; do
        command=(nmap -sn "$ip/$subnet")
        refresh_software_status nmap
        header "Tool_Box - Host Discovery"
        echo "Nmap Status: $(software_status_text nmap)"
        show_software_description nmap
        show_command
        echo ""
        echo " 1) Run Host Discovery"
        echo " 2) View Nmap Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program nmap && run_command_logged "recon" "host-discovery" || pause ;;
            2) view_man_page nmap ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

port_discovery_menu() {
    local choice
    while true; do
        command=(nmap -sT -p "$port" "$ip/$subnet")
        refresh_software_status nmap
        header "Tool_Box - Port Discovery"
        echo "Nmap Status: $(software_status_text nmap)"
        show_software_description nmap
        show_command
        echo ""
        echo " 1) Run Port Discovery"
        echo " 2) View Nmap Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program nmap && run_command_logged "recon" "port-discovery" || pause ;;
            2) view_man_page nmap ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

service_detection_menu() {
    local choice
    while true; do
        command=(nmap -sV -p "$port" "$ip/$subnet")
        refresh_software_status nmap
        header "Tool_Box - Service Detection"
        echo "Nmap Status: $(software_status_text nmap)"
        show_software_description nmap
        show_command
        echo ""
        echo " 1) Run Service Detection"
        echo " 2) View Nmap Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program nmap && run_command_logged "recon" "service-detection" || pause ;;
            2) view_man_page nmap ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

recon_software_menu() {
    local choice key i

    while true; do
        scan_software_statuses
        header "Tool_Box - Reconnaissance Software"
        echo "Reconnaissance tools supported by the apt installer:"
        echo ""
        i=1
        for key in "${recon_software_keys[@]}"; do
            printf '%2d) %-18s : %-9s  Package: %s\n' \
                "$i" "${software_display[$key]}" "${software_status[$key]}" "${software_package[$key]}"
            ((i++))
        done
        echo " 0) Back"
        echo ""
        menu_prompt choice

        if [[ "$choice" == "0" ]]; then
            return
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#recon_software_keys[@]} )); then
            key="${recon_software_keys[$((choice - 1))]}"
            software_details_menu "$key"
        else
            echo "Invalid option."
            pause
        fi
    done
}

reconnaissance_menu() {
    local choice
    while true; do
        header "Tool_Box - Reconnaissance"
        echo " 1) Nmap - Custom Builder"
        echo " 2) Host Discovery"
        echo " 3) Port Discovery"
        echo " 4) Service Detection"
        echo " 5) DNS Enumeration"
        echo " 6) WHOIS"
        echo " 7) Traceroute"
        echo " 8) Reconnaissance Software"
        echo " 9) Ping"
        external_render "reconnaissance"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) set_nmap ;;
            2) host_discovery_menu ;;
            3) port_discovery_menu ;;
            4) service_detection_menu ;;
            5) dns_lookup_menu ;;
            6) whois_menu ;;
            7) traceroute_menu ;;
            8) recon_software_menu ;;
            9) ping_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "reconnaissance" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

# -------------------------
# Network / DNS
# -------------------------
dns_lookup_menu() {
    local choice query="$ip"
    while true; do
        command=(dig "$query")
        refresh_software_status dig
        header "Tool_Box - DNS Lookup (Dig)"
        echo "Status: $(software_status_text dig)"
        show_software_description dig
        show_command
        echo ""
        echo " 1) Query: $query"
        echo " 2) Run DNS Lookup"
        echo " 3) View Dig Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter hostname or DNS name: " query ;;
            2) require_program dig && run_command_logged "dns" "dig" || pause ;;
            3) view_man_page dig ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

reverse_dns_menu() {
    local choice query="$ip"
    while true; do
        command=(dig -x "$query")
        refresh_software_status dig
        header "Tool_Box - Reverse DNS"
        echo "Dig Status: $(software_status_text dig)"
        show_software_description dig
        show_command
        echo ""
        echo " 1) IP Address: $query  [custom allowed]"
        echo " 2) Run Reverse DNS"
        echo " 3) View Dig Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Enter IP address: " query
                [[ -n "$query" ]] || query="$ip"
                ;;
            2) require_program dig && run_command_logged "dns" "reverse-dns" || pause ;;
            3) view_man_page dig ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

whois_menu() {
    local choice query="$ip"
    while true; do
        command=(whois "$query")
        refresh_software_status whois
        header "Tool_Box - WHOIS"
        echo "Status: $(software_status_text whois)"
        show_software_description whois
        show_command
        echo ""
        echo " 1) IP / Domain: $query  [custom allowed]"
        echo " 2) Run WHOIS"
        echo " 3) Reset to Global Target ($ip)"
        echo " 4) View WHOIS Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Enter IP or domain: " query
                [[ -n "$query" ]] || query="$ip"
                ;;
            2) require_program whois && run_command_logged "recon" "whois" || pause ;;
            3) query="$ip" ;;
            4) view_man_page whois ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

traceroute_menu() {
    local choice target="$ip"
    while true; do
        command=(traceroute "$target")
        refresh_software_status traceroute
        header "Tool_Box - Traceroute"
        echo "Status: $(software_status_text traceroute)"
        show_software_description traceroute
        show_command
        echo ""
        echo " 1) Target: $target  [custom IP/domain allowed]"
        echo " 2) Run Traceroute"
        echo " 3) Reset to Global Target ($ip)"
        echo " 4) View Traceroute Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Enter IP or domain: " target
                [[ -n "$target" ]] || target="$ip"
                ;;
            2) require_program traceroute && run_command_logged "network" "traceroute" || pause ;;
            3) target="$ip" ;;
            4) view_man_page traceroute ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

arp_scan_menu() {
    local choice
    while true; do
        run_privileged_command arp-scan --localnet
        refresh_software_status arp-scan
        header "Tool_Box - ARP Scan"
        echo "arp-scan Status: $(software_status_text arp-scan)"
        show_software_description arp-scan
        show_command
        echo ""
        echo " 1) Run Local Network ARP Scan"
        echo " 2) View arp-scan Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program arp-scan && run_command_logged "network" "arp-scan" || pause ;;
            2) view_man_page arp-scan ;;
            0) command_requires_privilege=false; return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

netcat_test_menu() {
    local choice nc_port target="$ip"
    nc_port="$(get_first_port)"
    while true; do
        command=(nc -vz -w 3 "$target" "$nc_port")
        refresh_software_status nc
        header "Tool_Box - Netcat TCP Test"
        echo "Netcat Status: $(software_status_text nc)"
        show_software_description nc
        show_command
        echo ""
        echo " 1) Target: $target  [custom IP/domain allowed]"
        echo " 2) Port: $nc_port"
        echo " 3) Run TCP Connection Test"
        echo " 4) Reset to Global Target ($ip)"
        echo " 5) View Netcat Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Enter IP or domain: " target
                [[ -n "$target" ]] || target="$ip"
                ;;
            2) read -r -p "Enter port: " nc_port; validate_port "$nc_port" || nc_port="$(get_first_port)" ;;
            3) require_program nc && run_command_logged "network" "netcat-test" || pause ;;
            4) target="$ip" ;;
            5) view_man_page nc ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

local_interfaces_page() {
    local choice
    while true; do
        command=(ip addr)
        refresh_software_status ipcmd
        header "Tool_Box - Local Interfaces (ip)"
        echo "ip Status: $(software_status_text ipcmd)"
        show_software_description ipcmd
        show_command
        echo ""
        echo " 1) Show Local Interfaces"
        echo " 2) View ip Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) require_program ipcmd && run_command_logged "network" "ip" || pause ;;
            2) view_man_page ipcmd ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

routing_table_page() {
    local choice
    while true; do
        command=(ip route)
        refresh_software_status ipcmd
        header "Tool_Box - Routing Table (ip)"
        echo "ip Status: $(software_status_text ipcmd)"
        show_software_description ipcmd
        show_command
        echo ""
        echo " 1) Show Routing Table"
        echo " 2) View ip Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) require_program ipcmd && run_command_logged "network" "ip" || pause ;;
            2) view_man_page ipcmd ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

network_dns_software_menu() {
    local choice key i

    while true; do
        scan_software_statuses
        header "Tool_Box - Network / DNS Software"
        echo "Network / DNS tools supported by the apt installer:"
        echo ""
        i=1
        for key in "${network_software_keys[@]}"; do
            printf '%2d) %-18s : %-9s  Package: %s\n' \
                "$i" "${software_display[$key]}" "${software_status[$key]}" "${software_package[$key]}"
            ((i++))
        done
        echo " 0) Back"
        echo ""
        menu_prompt choice

        if [[ "$choice" == "0" ]]; then
            return
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#network_software_keys[@]} )); then
            key="${network_software_keys[$((choice - 1))]}"
            software_details_menu "$key"
        else
            echo "Invalid option."
            pause
        fi
    done
}

network_dns_menu() {
    local choice
    while true; do
        header "Tool_Box - Network / DNS"
        echo " 1) DNS Lookup"
        echo " 2) Reverse DNS"
        echo " 3) WHOIS"
        echo " 4) Traceroute"
        echo " 5) ARP Scan"
        echo " 6) Test TCP Port (Netcat)"
        echo " 7) Local Interfaces"
        echo " 8) Routing Table"
        echo " 9) Network / DNS Software"
        external_render "network / dns"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) dns_lookup_menu ;;
            2) reverse_dns_menu ;;
            3) whois_menu ;;
            4) traceroute_menu ;;
            5) arp_scan_menu ;;
            6) netcat_test_menu ;;
            7) local_interfaces_page ;;
            8) routing_table_page ;;
            9) network_dns_software_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "network / dns" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

# -------------------------
# SMB / Windows
# -------------------------
enum4linux_menu() {
    local choice
    while true; do
        command=(enum4linux-ng -A "$ip")
        refresh_software_status enum4linux-ng
        header "Tool_Box - enum4linux-ng"
        echo "enum4linux-ng Status: $(software_status_text enum4linux-ng)"
        show_software_description enum4linux-ng
        show_command
        echo ""
        echo " 1) Run SMB Enumeration"
        echo " 2) View enum4linux-ng Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program enum4linux-ng && run_command_logged "smb" "enum4linux-ng" || pause ;;
            2) view_man_page enum4linux-ng ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

smb_list_shares_menu() {
    local choice
    while true; do
        command=(smbclient -L "//$ip" -N)
        refresh_software_status smbclient
        header "Tool_Box - List SMB Shares"
        echo "SMBClient Status: $(software_status_text smbclient)"
        show_software_description smbclient
        show_command
        echo ""
        echo " 1) List Anonymous Shares"
        echo " 2) View SMBClient Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program smbclient && run_command_logged "smb" "smb-shares" || pause ;;
            2) view_man_page smbclient ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

smb_client_menu() {
    local choice share="" username=""
    while true; do
        if [[ -n "$share" ]]; then
            command=(smbclient "//$ip/$share")
            if [[ -n "$username" ]]; then
                command+=( -U "$username" )
            else
                command+=( -N )
            fi
        else
            command=(smbclient "//$ip/SHARE")
        fi

        refresh_software_status smbclient
        header "Tool_Box - SMB Client"
        echo "SMBClient Status: $(software_status_text smbclient)"
        show_software_description smbclient
        show_command
        echo ""
        echo " 1) Share   : ${share:-Not set}"
        echo " 2) Username: ${username:-Anonymous}"
        echo " 3) Connect"
        echo " 4) View SMBClient Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter share name: " share ;;
            2) read -r -p "Enter username (blank for anonymous): " username ;;
            3)
                [[ -n "$share" ]] || { echo "Set a share first."; pause; continue; }
                require_program smbclient && run_command_interactive_logged "smb" "smbclient-session" || pause
                ;;
            4) view_man_page smbclient ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

nmap_smb_scripts_menu() {
    local choice
    while true; do
        command=(nmap -p 445 --script smb-os-discovery,smb2-security-mode,smb2-time "$ip")
        refresh_software_status nmap
        header "Tool_Box - Nmap SMB Information"
        echo "Nmap Status: $(software_status_text nmap)"
        show_software_description nmap
        show_command
        echo ""
        echo " 1) Run SMB Information Scripts"
        echo " 2) View Nmap Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program nmap && run_command_logged "smb" "nmap-smb-info" || pause ;;
            2) view_man_page nmap ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

netbios_info_menu() {
    local choice
    while true; do
        command=(nmap -sU -p 137 --script nbstat "$ip")
        refresh_software_status nmap
        header "Tool_Box - NetBIOS Information"
        echo "Nmap Status: $(software_status_text nmap)"
        show_software_description nmap
        show_command
        echo ""
        echo " 1) Run NetBIOS Information Scan"
        echo " 2) View Nmap Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program nmap && run_command_logged "smb" "netbios-info" || pause ;;
            2) view_man_page nmap ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

smb_windows_software_menu() {
    local choice key i

    while true; do
        scan_software_statuses
        header "Tool_Box - SMB / Windows Software"
        echo "SMB / Windows tools supported by the apt installer:"
        echo ""
        i=1
        for key in "${smb_software_keys[@]}"; do
            printf '%2d) %-18s : %-9s  Package: %s\n' \
                "$i" "${software_display[$key]}" "${software_status[$key]}" "${software_package[$key]}"
            ((i++))
        done
        echo " 0) Back"
        echo ""
        menu_prompt choice

        if [[ "$choice" == "0" ]]; then
            return
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#smb_software_keys[@]} )); then
            key="${smb_software_keys[$((choice - 1))]}"
            software_details_menu "$key"
        else
            echo "Invalid option."
            pause
        fi
    done
}

smb_windows_menu() {
    local choice
    while true; do
        header "Tool_Box - SMB / Windows"
        echo " 1) SMB Enumeration (enum4linux-ng)"
        echo " 2) List SMB Shares"
        echo " 3) SMB Client"
        echo " 4) Nmap SMB Information Scripts"
        echo " 5) NetBIOS Information"
        echo " 6) SMB / Windows Software"
        external_render "smb / windows"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) enum4linux_menu ;;
            2) smb_list_shares_menu ;;
            3) smb_client_menu ;;
            4) nmap_smb_scripts_menu ;;
            5) netbios_info_menu ;;
            6) smb_windows_software_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "smb / windows" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

# -------------------------
# Service Enumeration
# -------------------------
ssh_enumeration_menu() {
    local choice svc_port="22"
    while true; do
        refresh_software_status ssh
        refresh_software_status nmap
        header "Tool_Box - SSH Enumeration"
        echo "OpenSSH Client: $(software_status_text ssh)"
        echo "Nmap          : $(software_status_text nmap)"
        show_software_description ssh
        show_software_description nmap
        echo "Port          : $svc_port"
        echo ""
        echo " 1) Set SSH Port"
        echo " 2) Nmap SSH Version Detection"
        echo " 3) SSH Host-Key Scan"
        echo " 4) Nmap SSH Algorithms / Host Keys"
        echo " 5) View SSH Man Page / Help"
        echo " 6) View Nmap Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Enter SSH port: " svc_port
                validate_port "$svc_port" || { svc_port="22"; echo "Invalid port; reset to 22."; pause; }
                ;;
            2)
                command=(nmap -sV -p "$svc_port" "$ip")
                require_program nmap && run_command_logged "services" "ssh-version" || pause
                ;;
            3)
                if ! command -v ssh-keyscan >/dev/null 2>&1; then
                    echo "ssh-keyscan is missing. Install/repair OpenSSH Client from Service Enumeration Software."
                    pause
                    continue
                fi
                command=(ssh-keyscan -T 5 -p "$svc_port" "$ip")
                run_command_logged "services" "ssh-hostkeys"
                ;;
            4)
                command=(nmap -p "$svc_port" --script ssh2-enum-algos,ssh-hostkey "$ip")
                require_program nmap && run_command_logged "services" "ssh-info" || pause
                ;;
            5) view_man_page ssh ;;
            6) view_man_page nmap ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

ftp_enumeration_menu() {
    local choice svc_port="21"
    while true; do
        refresh_software_status nmap
        refresh_software_status nc
        header "Tool_Box - FTP Enumeration"
        show_module_description "Uses banner checks and Nmap service scripts to collect basic information from an authorized FTP service."
        echo "Nmap   : $(software_status_text nmap)"
        echo "Netcat : $(software_status_text nc)"
        echo "Port   : $svc_port"
        echo ""
        echo " 1) Set FTP Port"
        echo " 2) FTP Banner / Version Detection"
        echo " 3) Check Anonymous FTP + System Info (Nmap)"
        echo " 4) View Nmap Man Page / Help"
        echo " 5) View Netcat Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Enter FTP port: " svc_port
                validate_port "$svc_port" || { svc_port="21"; echo "Invalid port; reset to 21."; pause; }
                ;;
            2)
                command=(nmap -sV -p "$svc_port" --script banner "$ip")
                require_program nmap && run_command_logged "services" "ftp-banner" || pause
                ;;
            3)
                command=(nmap -p "$svc_port" --script ftp-anon,ftp-syst "$ip")
                require_program nmap && run_command_logged "services" "ftp-info" || pause
                ;;
            4) view_man_page nmap ;;
            5) view_man_page nc ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

smtp_enumeration_menu() {
    local choice svc_port="25"
    while true; do
        refresh_software_status nmap
        refresh_software_status nc
        header "Tool_Box - SMTP Enumeration"
        show_module_description "Uses banner checks and Nmap SMTP scripts to inspect commands and service details exposed by an authorized SMTP server."
        echo "Nmap   : $(software_status_text nmap)"
        echo "Netcat : $(software_status_text nc)"
        echo "Port   : $svc_port"
        echo ""
        echo " 1) Set SMTP Port"
        echo " 2) Read SMTP Banner"
        echo " 3) Enumerate SMTP Commands (Nmap)"
        echo " 4) SMTP Version Detection"
        echo " 5) View Netcat Man Page / Help"
        echo " 6) View Nmap Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Enter SMTP port: " svc_port
                validate_port "$svc_port" || { svc_port="25"; echo "Invalid port; reset to 25."; pause; }
                ;;
            2)
                command=(nc -w 4 "$ip" "$svc_port")
                require_program nc && run_command_logged_stdin_null "services" "smtp-banner" || pause
                ;;
            3)
                command=(nmap -p "$svc_port" --script smtp-commands "$ip")
                require_program nmap && run_command_logged "services" "smtp-commands" || pause
                ;;
            4)
                command=(nmap -sV -p "$svc_port" "$ip")
                require_program nmap && run_command_logged "services" "smtp-version" || pause
                ;;
            5) view_man_page nc ;;
            6) view_man_page nmap ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

snmp_enumeration_menu() {
    local choice svc_port="161" community="public" oid="1.3.6.1.2.1.1"
    while true; do
        refresh_software_status snmpwalk
        header "Tool_Box - SNMP Enumeration"
        echo "SNMPWalk : $(software_status_text snmpwalk)"
        show_software_description snmpwalk
        echo "Port     : $svc_port"
        echo "Community: $community"
        echo "OID      : $oid"
        echo ""
        echo " 1) Set SNMP Port"
        echo " 2) Set Community String"
        echo " 3) Set OID"
        echo " 4) Run SNMPWalk (supplied community only)"
        echo " 5) View SNMPWalk Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Enter SNMP port: " svc_port
                validate_port "$svc_port" || { svc_port="161"; echo "Invalid port; reset to 161."; pause; }
                ;;
            2) read -r -p "Enter community string: " community ;;
            3) read -r -p "Enter OID: " oid ;;
            4)
                [[ -n "$community" && -n "$oid" ]] || { echo "Community and OID are required."; pause; continue; }
                command=(snmpwalk -v2c -c "$community" "udp:$ip:$svc_port" "$oid")
                require_program snmpwalk && run_command_logged "services" "snmpwalk" || pause
                ;;
            5) view_man_page snmpwalk ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

ldap_enumeration_menu() {
    local choice svc_port="389" base_dn=""
    while true; do
        refresh_software_status ldapsearch
        header "Tool_Box - LDAP Enumeration"
        echo "LDAPSearch: $(software_status_text ldapsearch)"
        show_software_description ldapsearch
        echo "Port      : $svc_port"
        echo "Base DN   : ${base_dn:-Not set}"
        echo ""
        echo " 1) Set LDAP Port"
        echo " 2) Set Base DN"
        echo " 3) Query RootDSE"
        echo " 4) Query Selected Base DN (base object only)"
        echo " 5) View LDAPSearch Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Enter LDAP port: " svc_port
                validate_port "$svc_port" || { svc_port="389"; echo "Invalid port; reset to 389."; pause; }
                ;;
            2) read -r -p "Enter Base DN (example: dc=example,dc=com): " base_dn ;;
            3)
                command=(ldapsearch -x -H "ldap://$ip:$svc_port" -s base -b "" namingContexts supportedLDAPVersion vendorName vendorVersion)
                require_program ldapsearch && run_command_logged "services" "ldap-rootdse" || pause
                ;;
            4)
                [[ -n "$base_dn" ]] || { echo "Set a Base DN first."; pause; continue; }
                command=(ldapsearch -x -H "ldap://$ip:$svc_port" -s base -b "$base_dn" '(objectClass=*)' dn objectClass)
                require_program ldapsearch && run_command_logged "services" "ldap-base" || pause
                ;;
            5) view_man_page ldapsearch ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

nfs_enumeration_menu() {
    local choice
    while true; do
        refresh_software_status showmount
        refresh_software_status rpcinfo
        header "Tool_Box - NFS Enumeration"
        echo "Showmount: $(software_status_text showmount)"
        echo "RPCInfo  : $(software_status_text rpcinfo)"
        show_software_description showmount
        show_software_description rpcinfo
        echo ""
        echo " 1) List Exported NFS Shares"
        echo " 2) Show RPC Services"
        echo " 3) View Showmount Man Page / Help"
        echo " 4) View RPCInfo Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1)
                command=(showmount -e "$ip")
                require_program showmount && run_command_logged "services" "nfs-exports" || pause
                ;;
            2)
                command=(rpcinfo -p "$ip")
                require_program rpcinfo && run_command_logged "services" "rpc-services" || pause
                ;;
            3) view_man_page showmount ;;
            4) view_man_page rpcinfo ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

rpc_enumeration_menu() {
    local choice
    while true; do
        refresh_software_status rpcinfo
        header "Tool_Box - RPC Enumeration"
        echo "RPCInfo: $(software_status_text rpcinfo)"
        show_software_description rpcinfo
        echo ""
        echo " 1) List Registered RPC Programs"
        echo " 2) View RPCInfo Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1)
                command=(rpcinfo -p "$ip")
                require_program rpcinfo && run_command_logged "services" "rpcinfo" || pause
                ;;
            2) view_man_page rpcinfo ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

database_services_menu() {
    local choice db_ports="1433,3306,5432,6379,27017"
    while true; do
        refresh_software_status nmap
        header "Tool_Box - Database Service Detection"
        show_module_description "Uses Nmap service detection against common database ports to identify database services exposed by the target."
        echo "Nmap : $(software_status_text nmap)"
        echo "Ports: $db_ports"
        echo ""
        echo "This page performs version/service detection only; it does not attempt authentication."
        echo ""
        echo " 1) Set Database Ports"
        echo " 2) Detect Common Database Services"
        echo " 3) View Nmap Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter comma-separated ports: " db_ports ;;
            2)
                [[ "$db_ports" =~ ^[0-9,-]+$ ]] || { echo "Invalid port list."; pause; continue; }
                command=(nmap -sV -p "$db_ports" "$ip")
                require_program nmap && run_command_logged "services" "database-detection" || pause
                ;;
            3) view_man_page nmap ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

service_enumeration_software_menu() {
    local choice key i
    while true; do
        scan_software_statuses
        header "Tool_Box - Service Enumeration Software"
        echo "Software used by the Service Enumeration section:"
        echo ""
        i=1
        for key in "${service_software_keys[@]}"; do
            printf '%2d) %-18s : %-9s  Package: %s
'                 "$i" "${software_display[$key]}" "${software_status[$key]}" "${software_package[$key]}"
            ((i++))
        done
        echo " 0) Back"
        echo ""
        menu_prompt choice
        if [[ "$choice" == "0" ]]; then
            return
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#service_software_keys[@]} )); then
            key="${service_software_keys[$((choice - 1))]}"
            software_details_menu "$key"
        else
            echo "Invalid option."
            pause
        fi
    done
}

service_enumeration_menu() {
    local choice
    while true; do
        header "Tool_Box - Service Enumeration"
        echo " 1) SSH"
        echo " 2) FTP"
        echo " 3) SMTP"
        echo " 4) SNMP"
        echo " 5) LDAP"
        echo " 6) NFS"
        echo " 7) RPC"
        echo " 8) Database Services"
        echo " 9) Service Enumeration Software"
        external_render "service enumeration"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) ssh_enumeration_menu ;;
            2) ftp_enumeration_menu ;;
            3) smtp_enumeration_menu ;;
            4) snmp_enumeration_menu ;;
            5) ldap_enumeration_menu ;;
            6) nfs_enumeration_menu ;;
            7) rpc_enumeration_menu ;;
            8) database_services_menu ;;
            9) service_enumeration_software_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "service enumeration" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

# -------------------------
# Vulnerability Assessment
# -------------------------
vulnerability_software_menu() {
    local choice key i
    while true; do
        scan_software_statuses
        header "Tool_Box - Vulnerability Assessment Software"
        echo "Software used by the Vulnerability Assessment section:"
        echo ""
        i=1
        for key in "${vulnerability_software_keys[@]}"; do
            printf '%2d) %-18s : %-9s  Package: %s
'                 "$i" "${software_display[$key]}" "${software_status[$key]}" "${software_package[$key]}"
            ((i++))
        done
        echo " 0) Back"
        echo ""
        menu_prompt choice
        if [[ "$choice" == "0" ]]; then
            return
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#vulnerability_software_keys[@]} )); then
            key="${vulnerability_software_keys[$((choice - 1))]}"
            software_details_menu "$key"
        else
            echo "Invalid option."
            pause
        fi
    done
}

vulnerability_assessment_menu() {
    local choice assess_port
    assess_port="$(get_first_port)"
    while true; do
        refresh_software_status nmap
        header "Tool_Box - Vulnerability Assessment"
        show_module_description "Runs selected Nmap/NSE assessment checks for common configuration and exposure issues on systems you are authorized to test."
        echo "Nmap Status: $(software_status_text nmap)"
        show_software_description nmap
        echo "Port       : $assess_port"
        echo ""
        echo "Low-impact assessment helpers for systems you are authorized to test."
        echo ""
        echo " 1) Set Assessment Port"
        echo " 2) Safe NSE Script Scan"
        echo " 3) TLS Cipher Assessment"
        echo " 4) HTTP Security Headers"
        echo " 5) SMB Security Configuration"
        echo " 6) Service Detection + Default Scripts"
        echo " 7) Vulnerability Assessment Software"
        echo " 8) View Nmap Man Page / Help"
        external_render "vulnerability assessment"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Enter assessment port: " assess_port
                validate_port "$assess_port" || { assess_port="$(get_first_port)"; echo "Invalid port."; pause; }
                ;;
            2)
                command=(nmap -sV -p "$assess_port" --script safe "$ip")
                require_program nmap && run_command_logged "assessment" "nmap-safe" || pause
                ;;
            3)
                command=(nmap -p "$assess_port" --script ssl-enum-ciphers "$ip")
                require_program nmap && run_command_logged "assessment" "tls-ciphers" || pause
                ;;
            4)
                command=(nmap -p "$assess_port" --script http-security-headers "$ip")
                require_program nmap && run_command_logged "assessment" "http-security-headers" || pause
                ;;
            5)
                command=(nmap -p 445 --script smb2-security-mode,smb2-capabilities,smb2-time "$ip")
                require_program nmap && run_command_logged "assessment" "smb-security" || pause
                ;;
            6)
                command=(nmap -sV -sC -p "$assess_port" "$ip")
                require_program nmap && run_command_logged "assessment" "default-scripts" || pause
                ;;
            7) vulnerability_software_menu ;;
            8) view_man_page nmap ;;
            0) return ;;
            *) external_dispatch "$choice" "vulnerability assessment" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

# -------------------------
# Traffic Analysis
# -------------------------
tcpdump_capture_menu() {
    local capture_type="$1"
    local choice iface="any" count="100" capture_port filter_desc pcap_file
    capture_port="$(get_first_port)"

    while true; do
        pcap_file=$(build_output_file "traffic" "tcpdump-capture" "pcap")
        case "$capture_type" in
            all) run_privileged_command tcpdump -i "$iface" -nn -c "$count" -w "$pcap_file" ;;
            host) run_privileged_command tcpdump -i "$iface" -nn -c "$count" -w "$pcap_file" host "$ip" ;;
            port) run_privileged_command tcpdump -i "$iface" -nn -c "$count" -w "$pcap_file" port "$capture_port" ;;
        esac

        case "$capture_type" in
            all) filter_desc="All traffic" ;;
            host) filter_desc="Host $ip" ;;
            port) filter_desc="Port $capture_port" ;;
        esac

        refresh_software_status tcpdump
        header "Tool_Box - tcpdump Capture"
        echo "tcpdump Status: $(software_status_text tcpdump)"
        show_software_description tcpdump
        echo "Filter    : $filter_desc"
        echo "Interface : $iface"
        echo "Packet max: $count"
        echo "PCAP      : $pcap_file"
        show_command
        echo ""
        echo " 1) Interface"
        echo " 2) Packet Count"
        [[ "$capture_type" == port ]] && echo " 3) Port: $capture_port"
        echo " 4) Start Capture"
        echo " 5) View tcpdump Man Page / Help"
        echo " 0) Back"
        menu_prompt choice

        case "$choice" in
            1) read -r -p "Enter interface (example any, eth0): " iface ;;
            2) read -r -p "Enter maximum packet count: " count; [[ "$count" =~ ^[0-9]+$ ]] || count=100 ;;
            3)
                if [[ "$capture_type" == port ]]; then
                    read -r -p "Enter port: " capture_port
                    validate_port "$capture_port" || capture_port="$(get_first_port)"
                else
                    echo "Invalid option."
                    pause
                fi
                ;;
            4)
                require_program tcpdump || { pause; continue; }
                run_command_logged "traffic" "tcpdump-capture"
                ;;
            5) view_man_page tcpdump ;;
            0) command_requires_privilege=false; return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

tcpdump_read_menu() {
    local choice pcap_file=""
    while true; do
        command=(tcpdump -nn -r "$pcap_file")
        refresh_software_status tcpdump
        header "Tool_Box - Read PCAP with tcpdump"
        echo "tcpdump Status: $(software_status_text tcpdump)"
        show_software_description tcpdump
        echo "PCAP: ${pcap_file:-Not set}"
        [[ -n "$pcap_file" ]] && show_command
        echo ""
        echo " 1) Set PCAP File"
        echo " 2) Read PCAP"
        echo " 3) View tcpdump Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter PCAP path: " pcap_file ;;
            2)
                [[ -f "$pcap_file" ]] || { echo "PCAP file not found."; pause; continue; }
                require_program tcpdump && run_command_logged "traffic" "tcpdump-read" || pause
                ;;
            3) view_man_page tcpdump ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

tcpdump_interfaces_menu() {
    local choice
    while true; do
        command=(tcpdump -D)
        refresh_software_status tcpdump
        header "Tool_Box - Capture Interfaces"
        echo "tcpdump Status: $(software_status_text tcpdump)"
        show_software_description tcpdump
        show_command
        echo ""
        echo " 1) List Interfaces"
        echo " 2) View tcpdump Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program tcpdump && run_command_logged "traffic" "tcpdump" || pause ;;
            2) view_man_page tcpdump ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

tshark_analysis_menu() {
    local choice pcap_file="" display_filter=""
    while true; do
        command=(tshark -r "$pcap_file")
        [[ -n "$display_filter" ]] && command+=( -Y "$display_filter" )
        refresh_software_status tshark
        header "Tool_Box - TShark Analysis"
        echo "TShark Status: $(software_status_text tshark)"
        show_software_description tshark
        echo "PCAP  : ${pcap_file:-Not set}"
        echo "Filter: ${display_filter:-None}"
        [[ -n "$pcap_file" ]] && show_command
        echo ""
        echo " 1) Set PCAP File"
        echo " 2) Set Display Filter"
        echo " 3) Analyze"
        echo " 4) View TShark Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter PCAP path: " pcap_file ;;
            2) read -r -p "Enter Wireshark display filter: " display_filter ;;
            3)
                [[ -f "$pcap_file" ]] || { echo "PCAP file not found."; pause; continue; }
                require_program tshark && run_command_logged "traffic" "tshark" || pause
                ;;
            4) view_man_page tshark ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

traffic_analysis_software_menu() {
    local choice key i

    while true; do
        scan_software_statuses
        header "Tool_Box - Traffic Analysis Software"
        echo "Traffic Analysis tools supported by the apt installer:"
        echo ""
        i=1
        for key in "${traffic_software_keys[@]}"; do
            printf '%2d) %-18s : %-9s  Package: %s\n' \
                "$i" "${software_display[$key]}" "${software_status[$key]}" "${software_package[$key]}"
            ((i++))
        done
        echo " 0) Back"
        echo ""
        menu_prompt choice

        if [[ "$choice" == "0" ]]; then
            return
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#traffic_software_keys[@]} )); then
            key="${traffic_software_keys[$((choice - 1))]}"
            software_details_menu "$key"
        else
            echo "Invalid option."
            pause
        fi
    done
}

traffic_analysis_menu() {
    local choice
    while true; do
        header "Tool_Box - Traffic Analysis"
        echo " 1) Start tcpdump Capture"
        echo " 2) Read Capture"
        echo " 3) List Capture Interfaces"
        echo " 4) Capture by Host"
        echo " 5) Capture by Port"
        echo " 6) TShark Analysis"
        echo " 7) Traffic Analysis Software"
        external_render "traffic analysis"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) tcpdump_capture_menu all ;;
            2) tcpdump_read_menu ;;
            3) tcpdump_interfaces_menu ;;
            4) tcpdump_capture_menu host ;;
            5) tcpdump_capture_menu port ;;
            6) tshark_analysis_menu ;;
            7) traffic_analysis_software_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "traffic analysis" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

# -------------------------
# Utilities
# -------------------------
curl_utility_menu() {
    local choice protocol="http" web_port url
    web_port="$(get_first_port)"
    url="http://$ip:$web_port/"

    while true; do
        command=(curl "$url")
        header "Tool_Box - Curl"
        refresh_software_status curl
        echo "Software: $(software_status_text curl)"
        show_software_description curl
        echo "URL: $url"
        show_command
        echo ""
        echo " 1) Set URL"
        echo " 2) GET URL"
        echo " 3) Show Headers Only"
        echo " 4) View Curl Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter URL: " url ;;
            2) command=(curl "$url"); require_program curl && run_command_logged "utilities" "curl" || pause ;;
            3) command=(curl -I "$url"); require_program curl && run_command_logged "utilities" "curl-headers" || pause ;;
            4) view_man_page curl ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

wget_utility_menu() {
    local choice url="http://$ip:$(get_first_port)/"
    while true; do
        command=(wget "$url")
        header "Tool_Box - Wget"
        refresh_software_status wget
        echo "Software: $(software_status_text wget)"
        show_software_description wget
        echo "URL: $url"
        show_command
        echo ""
        echo " 1) Set URL"
        echo " 2) Download"
        echo " 3) View Wget Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter URL: " url ;;
            2) require_program wget && run_command_logged "utilities" "wget" || pause ;;
            3) view_man_page wget ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

jq_utility_menu() {
    local choice json_file=""
    while true; do
        command=(jq . "$json_file")
        header "Tool_Box - JQ"
        refresh_software_status jq
        echo "Software: $(software_status_text jq)"
        show_software_description jq
        echo "JSON File: ${json_file:-Not set}"
        [[ -n "$json_file" ]] && show_command
        echo ""
        echo " 1) Set JSON File"
        echo " 2) Pretty Print JSON"
        echo " 3) View JQ Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter JSON file path: " json_file ;;
            2)
                [[ -f "$json_file" ]] || { echo "File not found."; pause; continue; }
                require_program jq && run_command_logged "utilities" "jq" || pause
                ;;
            3) view_man_page jq ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

openssl_utility_menu() {
    local choice file_path=""
    while true; do
        header "Tool_Box - OpenSSL"
        refresh_software_status openssl
        echo "Software: $(software_status_text openssl)"
        show_software_description openssl
        echo ""
        echo " 1) Show OpenSSL Version"
        echo " 2) SHA-256 Hash a File"
        echo " 3) TLS Certificate Viewer"
        echo " 4) View OpenSSL Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1)
                command=(openssl version -a)
                require_program openssl && run_command_logged "utilities" "openssl-version" || pause
                ;;
            2)
                read -r -p "Enter file path: " file_path
                [[ -f "$file_path" ]] || { echo "File not found."; pause; continue; }
                command=(openssl dgst -sha256 "$file_path")
                require_program openssl && run_command_logged "utilities" "openssl-sha256" || pause
                ;;
            3) tls_certificate_menu ;;
            4) view_man_page openssl ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

results_list_targets() {
    header "Tool_Box - Targets with Results"
    if [[ -d "$output_folder" ]]; then
        find "$output_folder" -mindepth 1 -maxdepth 1 -type d ! -name archives -printf '%f\n' 2>/dev/null | sort
    else
        echo "No results directory exists yet."
    fi
    echo ""
    pause
}

results_recent_files() {
    header "Tool_Box - Recent Results"
    if [[ -d "$output_folder" ]]; then
        find "$output_folder" -type f -printf '%TY-%Tm-%Td %TH:%TM  %p
' 2>/dev/null | sort -r | head -n 50
    else
        echo "No results directory exists yet."
    fi
    echo ""
    pause
}

results_view_file() {
    local result_file
    read -r -p "Enter result file path: " result_file
    header "Tool_Box - View Result"
    if [[ -f "$result_file" ]]; then
        if command -v less >/dev/null 2>&1; then
            less "$result_file"
        else
            cat "$result_file"
            pause
        fi
    else
        echo "File not found."
        pause
    fi
}

results_compare_files() {
    local first second
    header "Tool_Box - Compare Results"
    read -r -p "First text result: " first
    read -r -p "Second text result: " second
    if [[ ! -f "$first" || ! -f "$second" ]]; then
        echo "Both files must exist."
        pause
        return
    fi
    if command -v less >/dev/null 2>&1; then
        diff -u -- "$first" "$second" | less
    else
        diff -u -- "$first" "$second"
        pause
    fi
}

generate_markdown_report() {
    local target_dir report_file rel file_count=0
    target_dir="${output_folder%/}/$(safe_target_name)"
    if [[ ! -d "$target_dir" ]]; then
        echo "No result directory exists for the current target: $target_dir"
        pause
        return 1
    fi

    report_file="${target_dir}/report-$(date +%Y-%m-%d_%H-%M-%S).md"
    {
        echo "# Tool_Box Report"
        echo ""
        echo "- Target: $ip/$subnet"
        echo "- Selected ports: $port"
        echo "- Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "- Tool_Box version: $ver"
        if [[ "$workspace_loaded" == true ]]; then
            echo "- Workspace: $workspace_name"
            echo "- Workspace path: $workspace_dir"
        fi
        echo ""

        if [[ "$workspace_loaded" == true && -s "$workspace_dir/services.tsv" ]]; then
            echo "## Imported Services"
            echo ""
            echo '| Host | Protocol | Port | Service | Product | Version |'
            echo '|---|---|---:|---|---|---|'
            while IFS=$'\t' read -r whost wproto wport wservice wproduct wversion; do
                printf '| %s | %s | %s | %s | %s | %s |\n' "$whost" "$wproto" "$wport" "$wservice" "$wproduct" "$wversion"
            done < "$workspace_dir/services.tsv"
            echo ""
        fi

        if [[ "$workspace_loaded" == true && -s "$workspace_dir/findings.tsv" ]]; then
            echo "## Findings"
            echo ""
            while IFS=$'\t' read -r wtime wcategory wvalue; do
                printf -- '- **%s** [%s] %s\n' "$wtime" "$wcategory" "$wvalue"
            done < "$workspace_dir/findings.tsv"
            echo ""
        fi

        if [[ "$workspace_loaded" == true && -s "$workspace_dir/notes.md" ]]; then
            echo "## Workspace Notes"
            echo ""
            cat "$workspace_dir/notes.md"
            echo ""
        fi

        echo "## Result Files"
        echo ""

        while IFS= read -r file; do
            [[ "$file" == "$report_file" ]] && continue
            rel="${file#$target_dir/}"
            ((file_count++))
            echo "### $rel"
            echo ""
            echo "Path: \`$file\`"
            echo ""
            case "$file" in
                *.pcap|*.pcapng|*.gz|*.zip|*.tar|*.tgz)
                    echo "Binary/archive content omitted from inline preview."
                    echo ""
                    ;;
                *)
                    echo '```text'
                    sed -n '1,40p' "$file" 2>/dev/null
                    echo '```'
                    echo ""
                    ;;
            esac
        done < <(find "$target_dir" -type f 2>/dev/null | sort)

        if (( file_count == 0 )); then
            echo "No result files were found."
        fi
    } > "$report_file"

    echo "Markdown report created: $report_file"
    pause
}

archive_target_results() {
    local target_dir archive_dir archive_file confirm
    target_dir="${output_folder%/}/$(safe_target_name)"
    if [[ ! -d "$target_dir" ]]; then
        echo "No result directory exists for the current target."
        pause
        return 1
    fi

    archive_dir="${output_folder%/}/archives"
    mkdir -p -- "$archive_dir" || { echo "Unable to create archive directory."; pause; return 1; }
    archive_file="$archive_dir/$(safe_target_name)-$(date +%Y-%m-%d_%H-%M-%S).tar.gz"
    echo "Archive target: $target_dir"
    echo "Archive file  : $archive_file"
    read -r -p "Create this archive? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Cancelled."; pause; return; }
    tar -czf "$archive_file" -C "$(dirname "$target_dir")" "$(basename "$target_dir")"
    echo "Created: $archive_file"
    pause
}

delete_result_file() {
    local result_file confirm resolved_file resolved_root
    header "Tool_Box - Delete Result"
    read -r -p "Enter exact result file path: " result_file
    [[ -f "$result_file" ]] || { echo "File not found."; pause; return; }

    resolved_file="$(realpath -m -- "$result_file" 2>/dev/null)"
    resolved_root="$(realpath -m -- "$output_folder" 2>/dev/null)"
    if [[ -z "$resolved_file" || -z "$resolved_root" || "$resolved_file" != "$resolved_root"/* ]]; then
        echo "Refusing to delete a file outside the configured output folder."
        pause
        return
    fi

    echo "File: $resolved_file"
    read -r -p "Permanently delete this result? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -- "$resolved_file" && echo "Deleted."
    else
        echo "Cancelled."
    fi
    pause
}

command_history_menu() {
    local history_file
    header "Tool_Box - Command History"
    history_file="${output_folder%/}/tool_box_command_history.log"
    if ((${#command_history[@]} > 0)); then
        printf '%s\n' "${command_history[@]}"
    elif [[ -f "$history_file" ]]; then
        tail -n 100 "$history_file"
    else
        echo "No Tool_Box commands have been recorded yet."
    fi
    echo ""
    pause
}

search_command_history() {
    local history_file term
    history_file="${output_folder%/}/tool_box_command_history.log"
    header "Tool_Box - Search Command History"
    read -r -p "Search term: " term
    echo ""
    if [[ -z "$term" ]]; then
        msg_warn "No search term entered."
    elif [[ -f "$history_file" ]]; then
        grep -in -- "$term" "$history_file" | tail -n 100 || echo "No matches."
    else
        printf '%s\n' "${command_history[@]}" | grep -in -- "$term" || echo "No matches."
    fi
    echo ""
    pause
}

search_target_results() {
    local target_dir term
    target_dir="${output_folder%/}/$(safe_target_name)"
    header "Tool_Box - Search Target Results"
    echo "Directory: $target_dir"
    echo ""
    [[ -d "$target_dir" ]] || { msg_warn "No current target result directory exists."; pause; return 0; }
    read -r -p "Search text: " term
    [[ -n "$term" ]] || { msg_warn "No search term entered."; pause; return 0; }
    echo ""
    grep -RInI --exclude='*.pcap' --exclude='*.pcapng' -- "$term" "$target_dir" 2>/dev/null | head -n 200 || true
    if [[ "$workspace_loaded" == true ]]; then
        [[ -f "$workspace_dir/notes.md" ]] && grep -Hni -- "$term" "$workspace_dir/notes.md" 2>/dev/null || true
        [[ -f "$workspace_dir/findings.tsv" ]] && grep -Hni -- "$term" "$workspace_dir/findings.tsv" 2>/dev/null || true
    fi
    echo ""
    pause
}

results_dashboard() {
    local target_dir files=0 size="0" categories=0 history_count=0
    target_dir="${output_folder%/}/$(safe_target_name)"
    [[ -d "$target_dir" ]] && files="$(find "$target_dir" -type f 2>/dev/null | wc -l)"
    [[ -d "$target_dir" ]] && categories="$(find "$target_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
    [[ -d "$target_dir" ]] && size="$(du -sh "$target_dir" 2>/dev/null | awk '{print $1}')"
    [[ -f "${output_folder%/}/tool_box_command_history.log" ]] && history_count="$(wc -l < "${output_folder%/}/tool_box_command_history.log")"
    header "Tool_Box - Results Dashboard"
    echo "Target          : $ip/$subnet"
    echo "Selected ports  : $port"
    echo "Result directory: $target_dir"
    echo ""
    echo "Result files    : $files"
    echo "Result categories: $categories"
    echo "Result size     : ${size:-0}"
    echo "History entries : $history_count"
    if [[ "$workspace_loaded" == true ]]; then
        echo "Workspace       : $workspace_name"
        echo "Imported services: $(grep -cve '^$' "$workspace_dir/services.tsv" 2>/dev/null || true)"
        echo "Findings        : $(grep -cve '^$' "$workspace_dir/findings.tsv" 2>/dev/null || true)"
        echo "Notes           : $(grep -c '^### ' "$workspace_dir/notes.md" 2>/dev/null || true)"
    fi
    echo ""
    pause
}

results_menu() {
    local choice
    while true; do
        header "Tool_Box - Results / Reporting"
        echo "Root: $output_folder"
        echo "Target directory: ${output_folder%/}/$(safe_target_name)"
        echo ""
        echo " 1) Results Dashboard"
        echo " 2) List Targets with Results"
        echo " 3) List Recent Result Files"
        echo " 4) View a Text Result"
        echo " 5) Show Current Target Result Directory"
        echo " 6) Search Current Target Results"
        echo " 7) Compare Two Text Results"
        echo " 8) Generate Markdown Target Report"
        echo " 9) Archive Current Target Results"
        echo "10) Delete a Result File"
        echo "11) View Tool_Box Command History"
        echo "12) Search Tool_Box Command History"
        external_render "results / reporting"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) results_dashboard ;;
            2) results_list_targets ;;
            3) results_recent_files ;;
            4) results_view_file ;;
            5)
                header "Tool_Box - Target Result Directory"
                echo "${output_folder%/}/$(safe_target_name)"
                echo ""
                pause
                ;;
            6) search_target_results ;;
            7) results_compare_files ;;
            8) generate_markdown_report ;;
            9) archive_target_results ;;
            10) delete_result_file ;;
            11) command_history_menu ;;
            12) search_command_history ;;
            0) return ;;
            *) external_dispatch "$choice" "results / reporting" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

utilities_software_menu() {
    local choice key i

    while true; do
        header "Tool_Box - Utilities Software"
        echo "Software used by the Utilities section:"
        echo ""

        i=1
        for key in "${utilities_software_keys[@]}"; do
            refresh_software_status "$key"
            printf ' %d) %-12s : %-9s Package: %s\n' \
                "$i" "${software_display[$key]}" "${software_status[$key]}" "${software_package[$key]}"
            ((i++))
        done

        echo " 0) Back"
        echo ""
        menu_prompt choice

        if [[ "$choice" == "0" ]]; then
            return
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#utilities_software_keys[@]} )); then
            key="${utilities_software_keys[$((choice - 1))]}"
            software_details_menu "$key"
        else
            echo "Invalid option."
            pause
        fi
    done
}

utilities_menu() {
    local choice
    while true; do
        header "Tool_Box - Utilities"
        echo " 1) Curl"
        echo " 2) Wget"
        echo " 3) Netcat TCP Test"
        echo " 4) JQ"
        echo " 5) OpenSSL"
        echo " 6) Utilities Software"
        external_render "command-line utilities"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) curl_utility_menu ;;
            2) wget_utility_menu ;;
            3) netcat_test_menu ;;
            4) jq_utility_menu ;;
            5) openssl_utility_menu ;;
            6) utilities_software_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "command-line utilities" || { echo "Invalid option."; pause; } ;;
        esac
    done
}


# -------------------------
# Workflow / utility helpers
# -------------------------
copy_to_clipboard() {
    local text="$1"
    if command -v wl-copy >/dev/null 2>&1; then
        printf '%s' "$text" | wl-copy && return 0
    fi
    if command -v xclip >/dev/null 2>&1; then
        printf '%s' "$text" | xclip -selection clipboard && return 0
    fi
    if command -v xsel >/dev/null 2>&1; then
        printf '%s' "$text" | xsel --clipboard --input && return 0
    fi
    return 1
}

network_information_page() {
    header "Tool_Box - Network Information"
    echo "Interfaces:"
    if command -v ip >/dev/null 2>&1; then
        ip -br addr 2>/dev/null || ip addr
        echo ""
        echo "Default route / routes:"
        ip route 2>/dev/null || true
        echo ""
        echo "Neighbors:"
        ip neigh 2>/dev/null || true
    else
        echo "The ip command is not installed."
    fi
    echo ""
    echo "DNS:"
    if command -v resolvectl >/dev/null 2>&1; then
        resolvectl status 2>/dev/null | sed -n '1,80p'
    elif [[ -r /etc/resolv.conf ]]; then
        cat /etc/resolv.conf
    else
        echo "DNS configuration unavailable."
    fi
    echo ""
    pause
}

vpn_status_page() {
    local found=0 iface
    header "Tool_Box - VPN / Tunnel Status"
    if command -v ip >/dev/null 2>&1; then
        while IFS= read -r iface; do
            [[ -n "$iface" ]] || continue
            found=1
            echo "Interface: $iface"
            ip -br addr show dev "$iface" 2>/dev/null || true
            ip route show dev "$iface" 2>/dev/null || true
            echo ""
        done < <(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | sed 's/@.*//' | grep -E '^(tun|tap|wg|tailscale|zt|vpn)' || true)
    fi
    if (( found == 0 )); then
        msg_warn "No common VPN/tunnel interface was detected."
        echo "TryHackMe OpenVPN connections commonly appear as tun0."
    fi
    echo ""
    pause
}

public_ip_page() {
    local confirm result
    header "Tool_Box - Public IP"
    echo "This makes a request to an external IP-check service."
    read -r -p "Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { msg_warn "Cancelled."; pause; return 0; }
    if ! command -v curl >/dev/null 2>&1; then
        msg_error "curl is required."
        pause
        return 1
    fi
    result="$(curl -fsS --max-time 8 https://api.ipify.org 2>/dev/null)"
    if [[ -n "$result" ]]; then
        echo "Public IP: $result"
    else
        msg_error "Unable to retrieve the public IP."
    fi
    echo ""
    pause
}

network_info_menu() {
    local choice
    while true; do
        header "Tool_Box - Network Information"
        echo " 1) Local Interfaces / Routes / DNS"
        echo " 2) VPN / Tunnel Status"
        echo " 3) Public IP (external request)"
        external_render "network information"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) network_information_page ;;
            2) vpn_status_page ;;
            3) public_ip_page ;;
            0) return ;;
            *) external_dispatch "$choice" "network information" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

show_conversion_result() {
    local label="$1" value="$2" copy_choice
    echo ""
    printf '%s: %s\n' "$label" "$value"
    echo ""
    read -r -p "Copy result to clipboard? [y/N]: " copy_choice
    if [[ "$copy_choice" =~ ^[Yy]$ ]]; then
        if copy_to_clipboard "$value"; then
            msg_success "Copied to clipboard."
        else
            msg_warn "No usable clipboard helper was detected (wl-copy, xclip, or xsel)."
        fi
    fi
    pause
}

identify_hash_format() {
    local value="$1" guess="Unknown / unsupported pattern"
    case "$value" in
        '$2a$'*|'$2b$'*|'$2y$'*) guess="bcrypt" ;;
        '$1$'*) guess="md5crypt" ;;
        '$5$'*) guess="sha256crypt" ;;
        '$6$'*) guess="sha512crypt" ;;
        '$y$'*) guess="yescrypt" ;;
        '$argon2i$'*|'$argon2d$'*|'$argon2id$'*) guess="Argon2" ;;
        '$P$'*|'$H$'*) guess="phpass / portable PHP password hash" ;;
        *)
            if [[ "$value" =~ ^[A-Fa-f0-9]{32}$ ]]; then
                guess="32 hex characters: commonly MD5 or NTLM (ambiguous without context)"
            elif [[ "$value" =~ ^[A-Fa-f0-9]{40}$ ]]; then
                guess="40 hex characters: commonly SHA-1"
            elif [[ "$value" =~ ^[A-Fa-f0-9]{56}$ ]]; then
                guess="56 hex characters: commonly SHA-224"
            elif [[ "$value" =~ ^[A-Fa-f0-9]{64}$ ]]; then
                guess="64 hex characters: commonly SHA-256"
            elif [[ "$value" =~ ^[A-Fa-f0-9]{96}$ ]]; then
                guess="96 hex characters: commonly SHA-384"
            elif [[ "$value" =~ ^[A-Fa-f0-9]{128}$ ]]; then
                guess="128 hex characters: commonly SHA-512"
            fi
            ;;
    esac
    printf '%s' "$guess"
}

hash_identifier_menu() {
    local value guess
    header "Tool_Box - Hash Identification Helper"
    read -r -p "Hash: " value
    [[ -n "$value" ]] || { msg_warn "No hash entered."; pause; return 0; }
    guess="$(identify_hash_format "$value")"
    echo ""
    echo "Likely format: $guess"
    echo ""
    msg_info "This is pattern-based identification, not proof of the hash algorithm."
    pause
}

text_encoding_menu() {
    local choice text result
    while true; do
        header "Tool_Box - Text / Encoding Tools"
        echo " 1) Base64 Encode"
        echo " 2) Base64 Decode"
        echo " 3) Hex Encode"
        echo " 4) Hex Decode"
        echo " 5) URL Encode"
        echo " 6) URL Decode"
        echo " 7) SHA-256 Text Hash"
        echo " 8) Hash Identification Helper"
        external_render "text / encoding tools"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1)
                read -r -p "Text: " text
                result="$(printf '%s' "$text" | base64 | tr -d '\n')"
                show_conversion_result "Base64" "$result"
                ;;
            2)
                read -r -p "Base64: " text
                if result="$(printf '%s' "$text" | base64 -d 2>/dev/null)"; then
                    show_conversion_result "Decoded" "$result"
                else
                    msg_error "Invalid Base64 input."
                    pause
                fi
                ;;
            3)
                read -r -p "Text: " text
                result="$(printf '%s' "$text" | od -An -tx1 | tr -d ' \n')"
                show_conversion_result "Hex" "$result"
                ;;
            4)
                read -r -p "Hex: " text
                if command -v xxd >/dev/null 2>&1; then
                    result="$(printf '%s' "$text" | xxd -r -p 2>/dev/null)"
                    show_conversion_result "Decoded" "$result"
                elif command -v python3 >/dev/null 2>&1; then
                    if result="$(python3 -c 'import sys; print(bytes.fromhex(sys.argv[1]).decode("utf-8",errors="replace"),end="")' "$text" 2>/dev/null)"; then
                        show_conversion_result "Decoded" "$result"
                    else
                        msg_error "Invalid hex input."
                        pause
                    fi
                else
                    msg_error "Hex decode requires xxd or python3."
                    pause
                fi
                ;;
            5)
                read -r -p "Text: " text
                if command -v python3 >/dev/null 2>&1; then
                    result="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$text")"
                    show_conversion_result "URL encoded" "$result"
                else
                    msg_error "python3 is required for URL encoding."
                    pause
                fi
                ;;
            6)
                read -r -p "URL encoded text: " text
                if command -v python3 >/dev/null 2>&1; then
                    result="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.unquote(sys.argv[1]))' "$text")"
                    show_conversion_result "URL decoded" "$result"
                else
                    msg_error "python3 is required for URL decoding."
                    pause
                fi
                ;;
            7)
                read -r -p "Text: " text
                if command -v sha256sum >/dev/null 2>&1; then
                    result="$(printf '%s' "$text" | sha256sum | awk '{print $1}')"
                elif command -v openssl >/dev/null 2>&1; then
                    result="$(printf '%s' "$text" | openssl dgst -sha256 | awk '{print $NF}')"
                else
                    msg_error "sha256sum or openssl is required."
                    pause
                    continue
                fi
                show_conversion_result "SHA-256" "$result"
                ;;
            8) hash_identifier_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "text / encoding tools" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

port_reference_description() {
    local p="$1"
    case "$p" in
        20|21) echo "FTP - Service Enumeration" ;;
        22) echo "SSH - Service Enumeration" ;;
        23) echo "Telnet - Service Enumeration" ;;
        25|465|587) echo "SMTP - Service Enumeration" ;;
        53) echo "DNS - Network / DNS" ;;
        67|68) echo "DHCP - Network / DNS" ;;
        69) echo "TFTP - Service Enumeration" ;;
        80|443|8000|8080|8443) echo "HTTP/HTTPS - Web Enumeration" ;;
        110|995) echo "POP3/POP3S - Service Enumeration" ;;
        111) echo "RPCbind - Service Enumeration" ;;
        123) echo "NTP - Service Enumeration" ;;
        135) echo "MS RPC - SMB / Windows" ;;
        139|445) echo "SMB/NetBIOS - SMB / Windows" ;;
        143|993) echo "IMAP/IMAPS - Service Enumeration" ;;
        161|162) echo "SNMP - Service Enumeration" ;;
        389|636) echo "LDAP/LDAPS - Service Enumeration" ;;
        2049) echo "NFS - Service Enumeration" ;;
        3306) echo "MySQL - Service Enumeration" ;;
        3389) echo "RDP - SMB / Windows / Service Enumeration" ;;
        5432) echo "PostgreSQL - Service Enumeration" ;;
        5900) echo "VNC - Service Enumeration" ;;
        *) echo "No built-in reference entry. Start with Reconnaissance / Service Enumeration." ;;
    esac
}

port_reference_menu() {
    local p
    header "Tool_Box - Port Reference"
    read -r -p "Port number: " p
    if validate_port "$p"; then
        echo ""
        echo "Port $p: $(port_reference_description "$p")"
    else
        msg_error "Invalid port."
    fi
    echo ""
    pause
}

toolbox_quick_help() {
    header "Tool_Box - Quick Help"
    cat <<'EOF'
Recommended workflow
--------------------
1. Create/load a Workspace under Target & Scanning.
2. Set the target, subnet, ports, output directory, and defaults.
3. Run Nmap or a Scan Profile.
4. Import saved Nmap XML/grepable/text output into the workspace.
5. Review Service-Aware Recommendations.
6. Use Notes and Findings to keep important information separate from raw output.
7. Use Results / Reporting to search output and generate a Markdown report.

Privilege guidance
------------------
- Most enumeration can run as a standard user.
- Some Nmap scan types, packet capture, ARP scanning, and selected network actions need root/capabilities.
- Tool_Box marks elevated commands and asks for confirmation.
- System & Configuration -> Privilege / User Session can start a nested root Tool_Box.

Output
------
- Auto-Save stores command output under the configured results directory.
- Workspaces store project metadata, notes, findings, and imported service inventories.
- Dry-Run previews commands without executing them.
EOF
    echo ""
    pause
}

# -------------------------
# Scan Profiles
# -------------------------
run_profile_command() {
    local profile_name="$1"
    local tool_key="$2"
    shift 2
    command=("$@")

    header "Tool_Box - Profile: $profile_name"
    refresh_software_status "$tool_key"
    echo "Software: ${software_display[$tool_key]} - ${software_status[$tool_key]}"
    echo ""
    show_command
    echo ""
    require_program "$tool_key" || { pause; return 1; }
    run_command_logged "profiles" "$profile_name"
}

quick_recon_profile() {
    run_profile_command "quick-recon" nmap nmap -T4 -F -sV "$ip/$subnet"
}

full_tcp_profile() {
    run_profile_command "full-tcp-recon" nmap nmap -p- -sV -T4 "$ip"
}

web_server_profile() {
    local include_content
    header "Tool_Box - Profile: Web Server"
    refresh_software_status nmap
    refresh_software_status whatweb
    refresh_software_status curl
    refresh_software_status gobuster
    echo "Software:"
    echo " - Nmap      : $(software_status_text nmap)"
    echo " - WhatWeb   : $(software_status_text whatweb)"
    echo " - Curl      : $(software_status_text curl)"
    echo " - Gobuster  : $(software_status_text gobuster)"
    echo ""
    echo "This profile can run:"
    echo " - Nmap service detection on the selected web port"
    echo " - WhatWeb technology identification"
    echo " - Curl HTTP headers"
    echo " - Optional Gobuster content discovery"
    echo ""
    read -r -p "Include Gobuster content discovery? [y/N]: " include_content

    local web_port
    web_port="$(get_first_port)"

    if is_software_installed nmap; then
        command=(nmap -sV -p "$web_port" "$ip")
        run_command_logged "profiles" "web-nmap"
    else
        echo "Skipping Nmap: not installed."
    fi

    if is_software_installed whatweb; then
        command=(whatweb "http://$ip:$web_port")
        run_command_logged "profiles" "web-whatweb"
    else
        echo "Skipping WhatWeb: not installed."
    fi

    if is_software_installed curl; then
        command=(curl -I "http://$ip:$web_port")
        run_command_logged "profiles" "web-headers"
    else
        echo "Skipping Curl: not installed."
    fi

    if [[ "$include_content" =~ ^[Yy]$ ]]; then
        if is_software_installed gobuster; then
            command=(gobuster dir -u "http://$ip:$web_port" -w "$default_wordlist" -t "$default_threads")
            run_command_logged "profiles" "web-gobuster"
        else
            echo "Skipping Gobuster: not installed."
            pause
        fi
    fi
}

windows_smb_profile() {
    header "Tool_Box - Profile: Windows / SMB"
    refresh_software_status nmap
    refresh_software_status smbclient
    echo "Software:"
    echo " - Nmap      : $(software_status_text nmap)"
    echo " - SMBClient : $(software_status_text smbclient)"
    echo ""

    if is_software_installed nmap; then
        command=(nmap -p 445 --script smb-os-discovery,smb2-security-mode,smb2-time "$ip")
        run_command_logged "profiles" "windows-smb-nmap"
    else
        echo "Skipping Nmap: not installed."
        pause
    fi

    if is_software_installed smbclient; then
        command=(smbclient -L "//$ip" -N)
        run_command_logged "profiles" "windows-smb-shares"
    else
        echo "Skipping SMBClient: not installed."
        pause
    fi
}

linux_server_profile() {
    run_profile_command "linux-server" nmap nmap -sV -sC -p "$port" "$ip"
}

scan_profiles_software_menu() {
    local choice key i

    while true; do
        header "Tool_Box - Scan Profiles Software"
        echo "Software used by the Scan Profiles section:"
        echo ""

        i=1
        for key in "${profile_software_keys[@]}"; do
            refresh_software_status "$key"
            printf ' %d) %-12s : %-9s Package: %s\n' \
                "$i" "${software_display[$key]}" "${software_status[$key]}" "${software_package[$key]}"
            ((i++))
        done

        echo " 0) Back"
        echo ""
        menu_prompt choice

        if [[ "$choice" == "0" ]]; then
            return
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#profile_software_keys[@]} )); then
            key="${profile_software_keys[$((choice - 1))]}"
            software_details_menu "$key"
        else
            echo "Invalid option."
            pause
        fi
    done
}

scan_profiles_menu() {
    local choice
    while true; do
        header "Tool_Box - Scan Profiles"
        echo " 1) Quick Recon"
        echo " 2) Full TCP Recon"
        echo " 3) Web Server"
        echo " 4) Windows / SMB"
        echo " 5) Linux Server"
        echo " 6) Custom (Open Nmap Builder)"
        echo " 7) Scan Profiles Software"
        external_render "scan profiles"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) quick_recon_profile ;;
            2) full_tcp_profile ;;
            3) web_server_profile ;;
            4) windows_smb_profile ;;
            5) linux_server_profile ;;
            6) set_nmap ;;
            7) scan_profiles_software_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "scan profiles" || { echo "Invalid option."; pause; } ;;
        esac
    done
}


# -------------------------
# Settings Profiles
# -------------------------
sanitize_profile_name() {
    local value="$1"
    value="${value// /_}"
    value="${value//[^A-Za-z0-9._-]/_}"
    printf '%s' "$value"
}

save_settings_profile() {
    local name safe file
    header "Tool_Box - Save Settings Profile"
    read -r -p "Profile name: " name
    safe="$(sanitize_profile_name "$name")"
    [[ -n "$safe" ]] || { msg_error "Profile name cannot be empty."; pause; return 1; }
    mkdir -p -- "$config_profiles_dir" || { msg_error "Unable to create $config_profiles_dir"; pause; return 1; }
    file="$config_profiles_dir/$safe.conf"
    {
        printf 'default_threads=%s\n' "$default_threads"
        printf 'default_wordlist=%s\n' "$default_wordlist"
        printf 'output_folder=%s\n' "$output_folder"
        printf 'auto_save_output=%s\n' "$auto_save_output"
        printf 'verbose_mode=%s\n' "$verbose_mode"
        printf 'dry_run_mode=%s\n' "$dry_run_mode"
        printf 'color_enabled=%s\n' "$color_enabled"
    } > "$file" || { msg_error "Unable to write profile."; pause; return 1; }
    chmod 600 "$file" 2>/dev/null || true
    msg_success "Saved profile: $safe"
    pause
}

load_settings_profile_file() {
    local file="$1" line key value
    [[ -f "$file" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == *=* ]] || continue
        key="${line%%=*}"; value="${line#*=}"
        case "$key" in
            default_threads) [[ "$value" =~ ^[0-9]+$ ]] && default_threads="$value" ;;
            default_wordlist) default_wordlist="$value" ;;
            output_folder) output_folder="$value" ;;
            auto_save_output) [[ "$value" == true || "$value" == false ]] && auto_save_output="$value" ;;
            verbose_mode) [[ "$value" == true || "$value" == false ]] && verbose_mode="$value" ;;
            dry_run_mode) [[ "$value" == true || "$value" == false ]] && dry_run_mode="$value" ;;
            color_enabled) [[ "$value" == true || "$value" == false ]] && color_enabled="$value" ;;
        esac
    done < "$file"
    refresh_colors
}

select_settings_profile() {
    local action="$1" choice i file confirm
    local -a profiles=()
    mkdir -p -- "$config_profiles_dir" 2>/dev/null || true
    mapfile -t profiles < <(find "$config_profiles_dir" -maxdepth 1 -type f -name '*.conf' -printf '%f\n' 2>/dev/null | sort)
    header "Tool_Box - Settings Profiles"
    if ((${#profiles[@]} == 0)); then
        echo "No saved settings profiles."
        pause
        return 1
    fi
    for ((i=0;i<${#profiles[@]};i++)); do printf ' %2d) %s\n' "$((i+1))" "${profiles[$i]%.conf}"; done
    echo "  0) Cancel"
    echo ""
    menu_prompt choice
    [[ "$choice" == 0 ]] && return 1
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#profiles[@]} )); then
        msg_error "Invalid selection."; pause; return 1
    fi
    file="$config_profiles_dir/${profiles[$((choice-1))]}"
    case "$action" in
        load)
            load_settings_profile_file "$file" && msg_success "Loaded profile: ${profiles[$((choice-1))]%.conf}"
            ;;
        delete)
            read -r -p "Delete profile ${profiles[$((choice-1))]%.conf}? [y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then rm -- "$file" && msg_success "Profile deleted."; else msg_warn "Cancelled."; fi
            ;;
    esac
    pause
}

settings_profiles_menu() {
    local choice
    while true; do
        header "Tool_Box - Settings Profiles"
        echo "Profile directory: $config_profiles_dir"
        echo ""
        echo " 1) Save Current Settings as Profile"
        echo " 2) Load Profile"
        echo " 3) Delete Profile"
        echo " 4) List Profiles"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) save_settings_profile ;;
            2) select_settings_profile load ;;
            3) select_settings_profile delete ;;
            4)
                header "Tool_Box - Settings Profiles"
                find "$config_profiles_dir" -maxdepth 1 -type f -name '*.conf' -printf '%f\n' 2>/dev/null | sed 's/\.conf$//' | sort
                echo ""; pause
                ;;
            0) return ;;
            *) msg_error "Invalid option."; pause ;;
        esac
    done
}

# -------------------------
# Settings / config
# -------------------------
save_configuration() {
    header "Tool_Box - Save Configuration"
    {
        printf 'default_threads=%s\n' "$default_threads"
        printf 'default_wordlist=%s\n' "$default_wordlist"
        printf 'output_folder=%s\n' "$output_folder"
        printf 'auto_save_output=%s\n' "$auto_save_output"
        printf 'verbose_mode=%s\n' "$verbose_mode"
        printf 'dry_run_mode=%s\n' "$dry_run_mode"
        printf 'color_enabled=%s\n' "$color_enabled"
    } > "$config_file" || {
        echo "Unable to write $config_file"
        pause
        return 1
    }

    echo "Configuration saved to: $config_file"
    pause
}

load_configuration() {
    local line key value
    header "Tool_Box - Load Configuration"

    if [[ ! -f "$config_file" ]]; then
        echo "Configuration file not found: $config_file"
        pause
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == *=* ]] || continue
        key="${line%%=*}"
        value="${line#*=}"
        case "$key" in
            default_threads)
                [[ "$value" =~ ^[0-9]+$ ]] && default_threads="$value"
                ;;
            default_wordlist) default_wordlist="$value" ;;
            output_folder) output_folder="$value" ;;
            auto_save_output)
                [[ "$value" == true || "$value" == false ]] && auto_save_output="$value"
                ;;
            verbose_mode)
                [[ "$value" == true || "$value" == false ]] && verbose_mode="$value"
                ;;
            dry_run_mode)
                [[ "$value" == true || "$value" == false ]] && dry_run_mode="$value"
                ;;
            color_enabled)
                [[ "$value" == true || "$value" == false ]] && color_enabled="$value"
                ;;
        esac
    done < "$config_file"

    external_restore || pause
    echo "Configuration loaded from: $config_file"
    pause
}

reset_defaults() {
    header "Tool_Box - Reset Defaults"
    default_threads="10"
    if [[ -f "/usr/share/seclists/Discovery/Web-Content/common.txt" ]]; then
        default_wordlist="/usr/share/seclists/Discovery/Web-Content/common.txt"
    else
        default_wordlist="/usr/share/wordlists/dirb/common.txt"
    fi
    output_folder="./results"
    auto_save_output=false
    verbose_mode=false
    dry_run_mode=false
    color_enabled=true
    refresh_colors
    msg_success "Defaults restored for this session."
    pause
}

settings_menu() {
    local choice value
    while true; do
        header "Tool_Box - Settings"
        echo " 1) Default Wordlist : $default_wordlist"
        echo " 2) Default Threads  : $default_threads"
        echo " 3) Output Directory : $output_folder"
        echo " 4) Auto-Save Output : $(toggle_status "$auto_save_output")"
        echo " 5) Verbose Mode     : $(toggle_status "$verbose_mode")"
        echo " 6) Dry-Run Mode     : $(toggle_status "$dry_run_mode")"
        echo " 7) Color Output     : $(toggle_status "$color_enabled")"
        echo " 8) Save Configuration"
        echo " 9) Load Configuration"
        echo "10) Reset Defaults"
        echo "11) Settings Profiles"
        echo "12) External Modules"
        external_render "settings"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter default wordlist: " default_wordlist ;;
            2)
                read -r -p "Enter default thread count: " value
                [[ "$value" =~ ^[0-9]+$ ]] && default_threads="$value" || { echo "Invalid number."; pause; }
                ;;
            3) set_output_folder ;;
            4) auto_save_output=$(toggle_bool "$auto_save_output") ;;
            5) verbose_mode=$(toggle_bool "$verbose_mode") ;;
            6) dry_run_mode=$(toggle_bool "$dry_run_mode") ;;
            7)
                color_enabled=$(toggle_bool "$color_enabled")
                refresh_colors
                ;;
            8) save_configuration ;;
            9) load_configuration ;;
            10) reset_defaults ;;
            11) settings_profiles_menu ;;
            12) external_management_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "settings" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

# -------------------------
# Tool_Box Diagnostics
# -------------------------
diagnostics_software_status() {
    local key
    header "Tool_Box - Diagnostics - Software"
    detect_distribution
    echo "OS: $distro_pretty"
    echo ""
    scan_software_statuses
    printf '%-20s %-12s %s\n' "Software" "Status" "APT Repository"
    echo "----------------------------------------------------------"
    for key in "${installable_software_keys[@]}"; do
        printf '%-20s %-12s %s\n' "${software_display[$key]}" "${software_status[$key]}" "${software_repo_status[$key]}"
    done
    echo ""
    pause
}

diagnostics_output_folder() {
    header "Tool_Box - Diagnostics - Output"
    echo "Configured output folder: $output_folder"
    if ensure_output_folder; then
        echo "Status: OK - directory exists and is writable."
    else
        echo "Status: FAILED"
    fi
    echo ""
    pause
}

diagnostics_wordlist() {
    header "Tool_Box - Diagnostics - Wordlist"
    echo "Configured wordlist: $default_wordlist"
    if [[ -f "$default_wordlist" && -r "$default_wordlist" ]]; then
        echo "Status: OK - file exists and is readable."
    else
        echo "Status: MISSING / UNREADABLE"
    fi
    echo ""
    pause
}

diagnostics_network() {
    header "Tool_Box - Diagnostics - Network"
    if command -v ip >/dev/null 2>&1; then
        ip -br addr 2>/dev/null || ip addr
        echo ""
        echo "Routes:"
        ip route 2>/dev/null || true
    else
        echo "The ip command is not available."
    fi
    echo ""
    pause
}

diagnostics_environment() {
    header "Tool_Box - Diagnostics - Environment"
    detect_distribution
    echo "OS         : $distro_pretty"
    echo "User       : $(id -un 2>/dev/null || echo unknown)"
    echo "EUID       : $EUID"
    if (( EUID == 0 )); then
        echo "Privileges : root"
    elif command -v sudo >/dev/null 2>&1; then
        echo "Privileges : non-root; sudo is available"
    else
        echo "Privileges : non-root; sudo is NOT available"
    fi
    if command -v apt-get >/dev/null 2>&1; then
        echo "Package mgr: apt-get available"
    else
        echo "Package mgr: apt-get NOT available (automatic installs will not work)"
    fi
    echo "Shell      : ${BASH_VERSION:-unknown}"
    echo "Terminal   : ${TERM:-unknown}"
    echo "Color      : enabled=$color_enabled active=$color_active"
    [[ -n "${NO_COLOR:-}" ]] && echo "NO_COLOR   : set (ANSI color suppressed)"
    echo "Script     : ${BASH_SOURCE[0]}"
    echo ""
    pause
}

diagnostics_configuration() {
    local bad=0
    header "Tool_Box - Diagnostics - Configuration"
    echo "Target      : $ip/$subnet"
    echo "Ports       : $port"
    echo "Threads     : $default_threads"
    echo "Output      : $output_folder"
    echo "Auto-save   : $auto_save_output"
    echo "Dry-run     : $dry_run_mode"
    echo "Color       : $color_enabled (active: $color_active)"
    echo "Config file : $config_file"
    echo ""

    if ! [[ "$default_threads" =~ ^[0-9]+$ ]] || (( default_threads < 1 )); then
        echo "[FAIL] Default thread count is invalid."
        bad=1
    else
        echo "[ OK ] Default thread count"
    fi

    if [[ -f "$config_file" ]]; then
        if [[ -r "$config_file" ]]; then
            echo "[ OK ] Saved configuration is readable"
        else
            echo "[FAIL] Saved configuration is not readable"
            bad=1
        fi
    else
        echo "[INFO] No saved configuration file yet"
    fi

    if (( bad == 0 )); then
        echo ""
        echo "Configuration checks passed."
    fi
    echo ""
    pause
}

diagnostics_script_syntax() {
    header "Tool_Box - Diagnostics - Script Syntax"
    if [[ -r "${BASH_SOURCE[0]}" ]]; then
        if bash -n "${BASH_SOURCE[0]}"; then
            printf 'bash -n: %b\n' "$(status_text PASS)"
        else
            printf 'bash -n: %b\n' "$(status_text FAIL)"
        fi
    else
        echo "Unable to read the running script path."
    fi
    echo ""
    pause
}

diagnostics_run_all() {
    local missing=0 key
    header "Tool_Box - Diagnostics - Full Check"
    echo "Environment:"
    command -v apt-get >/dev/null 2>&1 && echo " [ OK ] apt-get" || echo " [WARN] apt-get missing"
    (( EUID == 0 )) && echo " [ OK ] running as root" || { command -v sudo >/dev/null 2>&1 && echo " [ OK ] sudo available" || echo " [WARN] sudo unavailable"; }
    echo ""

    echo "Output:"
    if ensure_output_folder; then
        echo " [ OK ] $output_folder is writable"
    else
        echo " [FAIL] output folder check failed"
    fi
    echo ""

    echo "Wordlist:"
    [[ -f "$default_wordlist" && -r "$default_wordlist" ]] && echo " [ OK ] $default_wordlist" || echo " [WARN] $default_wordlist missing/unreadable"
    echo ""

    echo "Software:"
    scan_software_statuses
    for key in "${installable_software_keys[@]}"; do
        if [[ "${software_status[$key]}" == "Installed" ]]; then
            printf ' [ OK ] %s
' "${software_display[$key]}"
        else
            printf ' [MISS] %-18s (%-20s) repo=%s\n' "${software_display[$key]}" "${software_package[$key]}" "${software_repo_status[$key]}"
            ((missing++))
        fi
    done
    echo ""
    echo "Missing supported packages: $missing"
    echo ""
    if bash -n "${BASH_SOURCE[0]}" 2>/dev/null; then
        printf 'Script syntax: %b\n' "$(status_text PASS)"
    else
        printf 'Script syntax: %b\n' "$(status_text FAIL)"
    fi
    echo ""
    pause
}


diagnostics_desktop_browser() {
    header "Tool_Box - Diagnostics - Desktop / Browser"
    echo "Current user    : $(id -un 2>/dev/null || echo unknown)"
    echo "EUID            : $EUID"
    echo "DISPLAY         : ${DISPLAY:-not set}"
    echo "WAYLAND_DISPLAY : ${WAYLAND_DISPLAY:-not set}"
    echo "XDG_RUNTIME_DIR : ${XDG_RUNTIME_DIR:-not set}"
    echo "DBUS session    : ${DBUS_SESSION_BUS_ADDRESS:-not set}"
    echo ""
    if find_default_browser_command >/dev/null 2>&1; then echo "xdg-open        : Available"; else echo "xdg-open        : Missing"; fi
    if find_firefox_command >/dev/null 2>&1; then echo "Firefox         : $(find_firefox_command)"; else echo "Firefox         : Missing"; fi
    if find_chrome_command >/dev/null 2>&1; then echo "Chrome/Chromium : $(find_chrome_command)"; else echo "Chrome/Chromium : Missing"; fi
    echo ""
    if command -v wl-copy >/dev/null 2>&1; then
        echo "Clipboard       : wl-copy"
    elif command -v xclip >/dev/null 2>&1; then
        echo "Clipboard       : xclip"
    elif command -v xsel >/dev/null 2>&1; then
        echo "Clipboard       : xsel"
    else
        echo "Clipboard       : No helper detected"
    fi
    if (( EUID == 0 )); then
        echo ""
        msg_warn "GUI applications launched directly as root may not have access to the desktop session."
        echo "Use Useful Links -> Open Firefox as User when needed."
    fi
    echo ""
    pause
}

diagnostics_menu() {
    local choice
    while true; do
        header "Tool_Box - Diagnostics"
        echo " 1) Run All Checks"
        echo " 2) Software Status"
        echo " 3) Output Folder Check"
        echo " 4) Default Wordlist Check"
        echo " 5) Network Interfaces / Routes"
        echo " 6) Configuration Check"
        echo " 7) Privilege / Package Manager Info"
        echo " 8) Bash Syntax Check"
        echo " 9) APT / Repository Troubleshooter"
        echo "10) Desktop / Browser / Clipboard Check"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) diagnostics_run_all ;;
            2) diagnostics_software_status ;;
            3) diagnostics_output_folder ;;
            4) diagnostics_wordlist ;;
            5) diagnostics_network ;;
            6) diagnostics_configuration ;;
            7) diagnostics_environment ;;
            8) diagnostics_script_syntax ;;
            9) repository_manager_menu ;;
            10) diagnostics_desktop_browser ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

# -------------------------
# Exploit
# -------------------------
metasploit_menu() {
    local choice

    while true; do
        command=(msfconsole)
        header "Tool_Box - Metasploit"
        show_software_description metasploit
        echo "This page only launches the local Metasploit console; Tool_Box does not install it."
        echo ""
        echo " 1) Launch msfconsole"
        echo " 2) Show Version"
        echo " 3) View Metasploit Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) require_program metasploit && run_command_interactive_logged "exploit" "metasploit-session" || pause ;;
            2)
                header "Tool_Box - Metasploit Version"
                software_version_output metasploit
                echo ""
                pause
                ;;
            3) view_man_page metasploit ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

exploit_menu() {
    local choice
    while true; do
        header "Tool_Box - Exploit"
        echo " 1) Metasploit"
        external_render "exploit"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) metasploit_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "exploit" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

# -------------------------
# Useful Links
# -------------------------
find_firefox_command() {
    local candidate
    for candidate in firefox firefox-esr; do
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done
    return 1
}

find_chrome_command() {
    local candidate
    for candidate in google-chrome google-chrome-stable chrome chromium chromium-browser; do
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done
    return 1
}

find_default_browser_command() {
    if command -v xdg-open >/dev/null 2>&1; then
        command -v xdg-open
        return 0
    fi
    return 1
}

browser_status_text() {
    local browser="$1"

    case "$browser" in
        default)
            if find_default_browser_command >/dev/null; then
                status_text "Available"
            else
                status_text "Missing"
            fi
            ;;
        firefox)
            if find_firefox_command >/dev/null; then
                status_text "Installed"
            else
                status_text "Missing"
            fi
            ;;
        chrome)
            if find_chrome_command >/dev/null; then
                status_text "Installed"
            else
                status_text "Missing"
            fi
            ;;
        *) status_text "Unknown" ;;
    esac
}

# Read a GUI environment variable from any process belonging to a user. This is
# a fallback for root shells, which usually do not inherit the desktop user's
# DISPLAY/WAYLAND/D-Bus environment.
find_user_process_env() {
    local run_uid="$1"
    local wanted="$2"
    local proc proc_uid value

    for proc in /proc/[0-9]*; do
        [[ -r "$proc/environ" ]] || continue
        proc_uid="$(stat -c '%u' "$proc" 2>/dev/null || true)"
        [[ "$proc_uid" == "$run_uid" ]] || continue

        value="$(tr '\0' '\n' < "$proc/environ" 2>/dev/null | sed -n "s/^${wanted}=//p" | head -n 1)"
        if [[ -n "$value" ]]; then
            printf '%s' "$value"
            return 0
        fi
    done

    return 1
}

# Resolve the selected user's actual desktop-session environment. On modern
# Ubuntu this is commonly a Wayland GNOME session, so simply forcing DISPLAY=:0
# is not reliable. We first ask the user's systemd session, then inspect their
# running processes, and finally use safe filesystem fallbacks.
resolve_user_gui_environment() {
    local run_user="$1"
    local run_uid="$2"
    local run_home="$3"
    local systemd_env=""
    local key value candidate

    USER_GUI_RUNTIME="/run/user/$run_uid"
    USER_GUI_DBUS=""
    USER_GUI_DISPLAY=""
    USER_GUI_WAYLAND=""
    USER_GUI_XAUTHORITY=""

    if [[ -S "$USER_GUI_RUNTIME/bus" ]]; then
        USER_GUI_DBUS="unix:path=$USER_GUI_RUNTIME/bus"
    fi

    # systemctl --user often contains the exact variables imported by GNOME.
    if command -v systemctl >/dev/null 2>&1 && [[ -n "$USER_GUI_DBUS" ]]; then
        if command -v runuser >/dev/null 2>&1; then
            systemd_env="$(runuser -u "$run_user" -- env \
                XDG_RUNTIME_DIR="$USER_GUI_RUNTIME" \
                DBUS_SESSION_BUS_ADDRESS="$USER_GUI_DBUS" \
                systemctl --user show-environment 2>/dev/null || true)"
        elif command -v sudo >/dev/null 2>&1; then
            systemd_env="$(sudo -u "$run_user" -H env \
                XDG_RUNTIME_DIR="$USER_GUI_RUNTIME" \
                DBUS_SESSION_BUS_ADDRESS="$USER_GUI_DBUS" \
                systemctl --user show-environment 2>/dev/null || true)"
        fi

        while IFS='=' read -r key value; do
            case "$key" in
                DISPLAY) USER_GUI_DISPLAY="$value" ;;
                WAYLAND_DISPLAY) USER_GUI_WAYLAND="$value" ;;
                XAUTHORITY) USER_GUI_XAUTHORITY="$value" ;;
                DBUS_SESSION_BUS_ADDRESS) [[ -n "$value" ]] && USER_GUI_DBUS="$value" ;;
                XDG_RUNTIME_DIR) [[ -n "$value" ]] && USER_GUI_RUNTIME="$value" ;;
            esac
        done <<< "$systemd_env"
    fi

    # If systemd did not know a value, copy it from an existing process in the
    # selected user's graphical login session.
    [[ -n "$USER_GUI_DISPLAY" ]] || USER_GUI_DISPLAY="$(find_user_process_env "$run_uid" DISPLAY 2>/dev/null || true)"
    [[ -n "$USER_GUI_WAYLAND" ]] || USER_GUI_WAYLAND="$(find_user_process_env "$run_uid" WAYLAND_DISPLAY 2>/dev/null || true)"
    [[ -n "$USER_GUI_XAUTHORITY" ]] || USER_GUI_XAUTHORITY="$(find_user_process_env "$run_uid" XAUTHORITY 2>/dev/null || true)"
    [[ -n "$USER_GUI_DBUS" ]] || USER_GUI_DBUS="$(find_user_process_env "$run_uid" DBUS_SESSION_BUS_ADDRESS 2>/dev/null || true)"

    # GNOME/Wayland fallbacks.
    if [[ -z "$USER_GUI_WAYLAND" && -d "$USER_GUI_RUNTIME" ]]; then
        for candidate in "$USER_GUI_RUNTIME"/wayland-*; do
            [[ -S "$candidate" ]] || continue
            USER_GUI_WAYLAND="${candidate##*/}"
            break
        done
    fi

    if [[ -z "$USER_GUI_XAUTHORITY" && -d "$USER_GUI_RUNTIME" ]]; then
        for candidate in "$USER_GUI_RUNTIME"/.mutter-Xwaylandauth.*; do
            [[ -f "$candidate" ]] || continue
            USER_GUI_XAUTHORITY="$candidate"
            break
        done
    fi

    if [[ -z "$USER_GUI_XAUTHORITY" && -f "$run_home/.Xauthority" ]]; then
        USER_GUI_XAUTHORITY="$run_home/.Xauthority"
    fi

    # X11 sessions still commonly use :0. Only use this fallback when no
    # Wayland socket was discovered.
    if [[ -z "$USER_GUI_DISPLAY" && -z "$USER_GUI_WAYLAND" ]]; then
        USER_GUI_DISPLAY=":0"
    fi
}

# Launch a browser in the current user's GUI session. If Tool_Box was started
# with sudo, automatically drop back to SUDO_USER when possible.
launch_browser_command() {
    local browser_command="$1"
    local url="$2"
    local browser_log="/tmp/tool_box_browser_${$}.log"
    local gui_user="${SUDO_USER:-}"
    local gui_uid=""
    local gui_home=""
    local pid rc
    local -a gui_env

    : > "$browser_log" 2>/dev/null || true

    if (( EUID == 0 )) && [[ -n "$gui_user" && "$gui_user" != "root" ]]; then
        gui_uid="$(id -u "$gui_user" 2>/dev/null || true)"
        gui_home="$(getent passwd "$gui_user" 2>/dev/null | cut -d: -f6)"
        [[ -n "$gui_home" ]] || gui_home="/home/$gui_user"

        resolve_user_gui_environment "$gui_user" "$gui_uid" "$gui_home"

        gui_env=(
            "HOME=$gui_home"
            "USER=$gui_user"
            "LOGNAME=$gui_user"
            "XDG_RUNTIME_DIR=$USER_GUI_RUNTIME"
        )
        [[ -n "$USER_GUI_DBUS" ]] && gui_env+=("DBUS_SESSION_BUS_ADDRESS=$USER_GUI_DBUS")
        [[ -n "$USER_GUI_DISPLAY" ]] && gui_env+=("DISPLAY=$USER_GUI_DISPLAY")
        [[ -n "$USER_GUI_WAYLAND" ]] && gui_env+=("WAYLAND_DISPLAY=$USER_GUI_WAYLAND" "MOZ_ENABLE_WAYLAND=1")
        [[ -n "$USER_GUI_XAUTHORITY" ]] && gui_env+=("XAUTHORITY=$USER_GUI_XAUTHORITY")

        if command -v runuser >/dev/null 2>&1; then
            runuser -u "$gui_user" -- env "${gui_env[@]}" \
                "$browser_command" "$url" >"$browser_log" 2>&1 &
        elif command -v sudo >/dev/null 2>&1; then
            sudo -u "$gui_user" -H env "${gui_env[@]}" \
                "$browser_command" "$url" >"$browser_log" 2>&1 &
        else
            msg_error "Neither runuser nor sudo is available to launch the desktop browser as '$gui_user'."
            pause
            return 1
        fi
        pid=$!
    else
        "$browser_command" "$url" >"$browser_log" 2>&1 &
        pid=$!
    fi

    sleep 2
    if ! kill -0 "$pid" 2>/dev/null; then
        wait "$pid" 2>/dev/null
        rc=$?
        if (( rc != 0 )); then
            msg_error "Browser launch failed (exit code $rc)."
            if [[ -s "$browser_log" ]]; then
                echo ""
                echo "Browser error:"
                tail -n 12 "$browser_log"
            fi
            echo ""
            echo "URL: $url"
            pause
            rm -f "$browser_log" 2>/dev/null || true
            return "$rc"
        fi
    fi

    rm -f "$browser_log" 2>/dev/null || true
    return 0
}

# Explicit root-only launcher. It prompts for the desktop username, discovers
# that user's live GUI session, and then executes Firefox with that account's
# HOME, runtime directory, D-Bus socket, Wayland/X11 display, and Xauthority.
launch_browser_as_user() {
    local browser_command="$1"
    local url="$2"
    local run_user=""
    local run_uid=""
    local run_home=""
    local browser_log="/tmp/tool_box_browser_${$}.log"
    local pid rc
    local -a gui_env

    if (( EUID != 0 )); then
        msg_warn "This option is intended for Tool_Box sessions running as root."
        pause
        return 1
    fi

    echo ""
    read -r -p "Username to run Firefox as: " run_user
    run_user="${run_user//[[:space:]]/}"

    if [[ -z "$run_user" ]]; then
        msg_error "No username entered."
        pause
        return 1
    fi

    if ! id "$run_user" >/dev/null 2>&1; then
        msg_error "User '$run_user' does not exist."
        pause
        return 1
    fi

    if [[ "$run_user" == "root" ]]; then
        msg_error "Choose the non-root user who owns the graphical desktop session."
        pause
        return 1
    fi

    run_uid="$(id -u "$run_user")"
    run_home="$(getent passwd "$run_user" 2>/dev/null | cut -d: -f6)"
    [[ -n "$run_home" ]] || run_home="/home/$run_user"

    resolve_user_gui_environment "$run_user" "$run_uid" "$run_home"

    echo ""
    echo "Desktop session detected for: $run_user"
    echo " XDG_RUNTIME_DIR : ${USER_GUI_RUNTIME:-Not detected}"
    echo " WAYLAND_DISPLAY : ${USER_GUI_WAYLAND:-Not detected}"
    echo " DISPLAY         : ${USER_GUI_DISPLAY:-Not detected}"
    echo " XAUTHORITY      : ${USER_GUI_XAUTHORITY:-Not detected}"
    echo " D-Bus           : ${USER_GUI_DBUS:-Not detected}"
    echo ""

    if [[ ! -d "$USER_GUI_RUNTIME" ]]; then
        msg_error "No active runtime directory exists for '$run_user'."
        echo "That usually means the user is not currently logged into the graphical desktop."
        pause
        return 1
    fi

    if [[ -z "$USER_GUI_WAYLAND" && -z "$USER_GUI_DISPLAY" ]]; then
        msg_error "No graphical display could be detected for '$run_user'."
        echo "Log into the desktop as that user first, then try again."
        pause
        return 1
    fi

    gui_env=(
        "HOME=$run_home"
        "USER=$run_user"
        "LOGNAME=$run_user"
        "XDG_RUNTIME_DIR=$USER_GUI_RUNTIME"
    )
    [[ -n "$USER_GUI_DBUS" ]] && gui_env+=("DBUS_SESSION_BUS_ADDRESS=$USER_GUI_DBUS")
    [[ -n "$USER_GUI_DISPLAY" ]] && gui_env+=("DISPLAY=$USER_GUI_DISPLAY")
    [[ -n "$USER_GUI_WAYLAND" ]] && gui_env+=("WAYLAND_DISPLAY=$USER_GUI_WAYLAND" "MOZ_ENABLE_WAYLAND=1")
    [[ -n "$USER_GUI_XAUTHORITY" ]] && gui_env+=("XAUTHORITY=$USER_GUI_XAUTHORITY")

    : > "$browser_log" 2>/dev/null || true

    if command -v runuser >/dev/null 2>&1; then
        runuser -u "$run_user" -- env "${gui_env[@]}" \
            "$browser_command" --new-tab "$url" >"$browser_log" 2>&1 &
    elif command -v sudo >/dev/null 2>&1; then
        sudo -u "$run_user" -H env "${gui_env[@]}" \
            "$browser_command" --new-tab "$url" >"$browser_log" 2>&1 &
    else
        msg_error "Neither runuser nor sudo is available."
        pause
        return 1
    fi
    pid=$!

    # Snap Firefox can take a little longer to report startup errors, so keep
    # the log around for several seconds instead of deleting it immediately.
    sleep 4
    if ! kill -0 "$pid" 2>/dev/null; then
        wait "$pid" 2>/dev/null
        rc=$?
        if (( rc != 0 )); then
            msg_error "Firefox launch as '$run_user' failed (exit code $rc)."
            if [[ -s "$browser_log" ]]; then
                echo ""
                echo "Firefox error:"
                tail -n 20 "$browser_log"
            fi
            echo ""
            echo "URL: $url"
            pause
            rm -f "$browser_log" 2>/dev/null || true
            return "$rc"
        fi
    fi

    # If the launcher exited successfully, it may simply have handed the URL to
    # an already-running Firefox process. Either case is considered success.
    if [[ -s "$browser_log" ]]; then
        # Keep non-empty output visible only when it looks like an error/warning.
        if grep -Eqi 'error|failed|cannot|denied|refused|not found|no display' "$browser_log"; then
            msg_warn "Firefox returned diagnostic output:"
            tail -n 20 "$browser_log"
            echo ""
            echo "URL: $url"
            pause
            rm -f "$browser_log" 2>/dev/null || true
            return 1
        fi
    fi

    rm -f "$browser_log" 2>/dev/null || true
    msg_success "Sent link to Firefox as desktop user '$run_user'."
    sleep 1
    return 0
}

open_useful_link_as_user() {
    local url="$1"
    local browser_command=""

    browser_command=$(find_firefox_command) || {
        msg_error "Firefox is not installed or is not in PATH."
        pause
        return 1
    }

    if [[ "$dry_run_mode" == true ]]; then
        msg_warn "DRY-RUN: Would prompt for a user and open $url with $browser_command."
        pause
        return 0
    fi

    launch_browser_as_user "$browser_command" "$url"
}

open_useful_link() {
    local browser="$1"
    local url="$2"
    local browser_command=""
    local browser_label=""

    case "$browser" in
        default)
            browser_command=$(find_default_browser_command) || {
                msg_error "xdg-open is not installed. Install xdg-utils or choose Firefox directly."
                pause
                return 1
            }
            browser_label="default browser"
            ;;
        firefox)
            browser_command=$(find_firefox_command) || {
                msg_error "Firefox is not installed or is not in PATH."
                pause
                return 1
            }
            browser_label="$browser_command"
            ;;
        chrome)
            browser_command=$(find_chrome_command) || {
                msg_error "Chrome/Chromium is not installed or is not in PATH."
                pause
                return 1
            }
            browser_label="$browser_command"
            ;;
        *)
            msg_error "Unknown browser: $browser"
            pause
            return 1
            ;;
    esac

    if [[ "$dry_run_mode" == true ]]; then
        msg_warn "DRY-RUN: Would open $url with $browser_label"
        pause
        return 0
    fi

    if launch_browser_command "$browser_command" "$url"; then
        msg_success "Sent link to $browser_label."
        sleep 1
    fi
}

useful_link_page() {
    local title="$1"
    local url="$2"
    local description="$3"
    local choice

    while true; do
        header "Tool_Box - Useful Links - $title"
        printf '%b\n' "${C_BOLD}Description:${C_RESET}"
        printf ' %s\n' "$description"
        echo ""
        printf '%b\n' "${C_BOLD}Link:${C_RESET}"
        printf ' %b%s%b\n' "$C_BLUE" "$url" "$C_RESET"
        echo ""
        printf ' Default opener : %b\n' "$(browser_status_text default)"
        printf ' Firefox        : %b\n' "$(browser_status_text firefox)"
        printf ' Chrome/Chromium: %b\n' "$(browser_status_text chrome)"
        echo ""
        echo " 1) Open in Default Browser"
        echo " 2) Open in Firefox"
        if (( EUID == 0 )); then
            echo " 3) Open Firefox as User (prompt for username)"
            echo " 4) Copy URL"
            echo " 5) Open in Chrome / Chromium"
        else
            echo " 3) Copy URL"
            echo " 4) Open in Chrome / Chromium"
        fi
        echo " 0) Back"
        echo ""
        menu_prompt choice

        if (( EUID == 0 )); then
            case "$choice" in
                1) open_useful_link default "$url" ;;
                2) open_useful_link firefox "$url" ;;
                3) open_useful_link_as_user "$url" ;;
                4)
                    if copy_to_clipboard "$url"; then msg_success "URL copied to clipboard."; else msg_warn "Clipboard helper unavailable; URL remains visible above."; fi
                    pause
                    ;;
                5) open_useful_link chrome "$url" ;;
                0) return ;;
                *) echo "Invalid option."; pause ;;
            esac
        else
            case "$choice" in
                1) open_useful_link default "$url" ;;
                2) open_useful_link firefox "$url" ;;
                3)
                    if copy_to_clipboard "$url"; then msg_success "URL copied to clipboard."; else msg_warn "Clipboard helper unavailable; URL remains visible above."; fi
                    pause
                    ;;
                4) open_useful_link chrome "$url" ;;
                0) return ;;
                *) echo "Invalid option."; pause ;;
            esac
        fi
    done
}

useful_links_shell_menu() {
    local choice
    while true; do
        header "Tool_Box - Useful Links - Shell / Session Tools"
        echo " 1) Penelope"
        echo " 2) Reverse Shell Generator"
        external_render "shell / session tools"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) useful_link_page "Penelope" "https://github.com/brightio/penelope" "Shell handler and session-management project useful in authorized lab environments." ;;
            2) useful_link_page "Reverse Shell Generator" "https://www.revshells.com/" "Reference and generator for shell command formats used in authorized labs." ;;
            0) return ;;
            *) external_dispatch "$choice" "shell / session tools" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

useful_links_data_menu() {
    local choice
    while true; do
        header "Tool_Box - Useful Links - Data / Encoding / Analysis"
        echo " 1) CyberChef"
        echo " 2) VirusTotal"
        external_render "data / encoding / analysis"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) useful_link_page "CyberChef" "https://gchq.github.io/CyberChef/" "Browser-based data transformation toolkit for encoding, decoding, hashing, byte manipulation, and format conversion." ;;
            2) useful_link_page "VirusTotal" "https://www.virustotal.com/" "File, URL, domain, and IP reputation and analysis service. Do not upload sensitive or private files." ;;
            0) return ;;
            *) external_dispatch "$choice" "data / encoding / analysis" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

useful_links_privilege_menu() {
    local choice
    while true; do
        header "Tool_Box - Useful Links - Privilege References"
        echo " 1) GTFOBins"
        echo " 2) LOLBAS"
        echo " 3) HackTricks"
        external_render "privilege references"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) useful_link_page "GTFOBins" "https://gtfobins.github.io/" "Reference for Unix binaries and security-relevant behaviors, useful when reviewing sudo rules and restricted environments." ;;
            2) useful_link_page "LOLBAS" "https://lolbas-project.github.io/" "Living Off The Land Binaries, Scripts and Libraries reference for Windows." ;;
            3) useful_link_page "HackTricks" "https://book.hacktricks.wiki/" "Large security reference covering enumeration, common services, web technologies, and lab methodology." ;;
            0) return ;;
            *) external_dispatch "$choice" "privilege references" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

useful_links_web_menu() {
    local choice
    while true; do
        header "Tool_Box - Useful Links - Web Security"
        echo " 1) PortSwigger Web Security Academy"
        echo " 2) OWASP Cheat Sheet Series"
        echo " 3) OWASP Web Security Testing Guide"
        external_render "web security"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) useful_link_page "PortSwigger Web Security Academy" "https://portswigger.net/web-security" "Hands-on web security learning material and labs." ;;
            2) useful_link_page "OWASP Cheat Sheet Series" "https://cheatsheetseries.owasp.org/" "Practical application-security guidance and defensive reference material." ;;
            3) useful_link_page "OWASP Web Security Testing Guide" "https://owasp.org/www-project-web-security-testing-guide/" "Structured web application security testing methodology." ;;
            0) return ;;
            *) external_dispatch "$choice" "web security" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

useful_links_recon_menu() {
    local choice
    while true; do
        header "Tool_Box - Useful Links - Recon / Vulnerabilities"
        echo " 1) crt.sh - Certificate Transparency"
        echo " 2) Nmap Reference Guide"
        echo " 3) Nmap NSE Documentation"
        echo " 4) Exploit Database"
        echo " 5) MITRE ATT&CK"
        echo " 6) CVE.org"
        echo " 7) NIST NVD"
        external_render "recon / vulnerabilities"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) useful_link_page "crt.sh" "https://crt.sh/" "Certificate Transparency search interface that can help with authorized domain and subdomain research." ;;
            2) useful_link_page "Nmap Reference Guide" "https://nmap.org/book/man.html" "Official Nmap command-line reference." ;;
            3) useful_link_page "Nmap NSE Documentation" "https://nmap.org/nsedoc/" "Official Nmap Scripting Engine script documentation." ;;
            4) useful_link_page "Exploit Database" "https://www.exploit-db.com/" "Public vulnerability and exploit-reference database for research and authorized testing." ;;
            5) useful_link_page "MITRE ATT&CK" "https://attack.mitre.org/" "Knowledge base of adversary tactics and techniques used for threat modeling and defensive analysis." ;;
            6) useful_link_page "CVE.org" "https://www.cve.org/" "Official CVE program site and vulnerability identifier reference." ;;
            7) useful_link_page "NIST NVD" "https://nvd.nist.gov/" "NIST vulnerability database with CVE enrichment and scoring information." ;;
            0) return ;;
            *) external_dispatch "$choice" "recon / vulnerabilities" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

useful_links_payloads_menu() {
    local choice
    while true; do
        header "Tool_Box - Useful Links - Payloads / Wordlists / Cheatsheets"
        echo " 1) PayloadsAllTheThings"
        echo " 2) SecLists"
        echo " 3) PacketLife Cheat Sheets"
        external_render "payloads / wordlists / cheatsheets"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) useful_link_page "PayloadsAllTheThings" "https://swisskyrepo.github.io/PayloadsAllTheThings/" "Security testing reference with payload examples and technique notes for authorized labs." ;;
            2) useful_link_page "SecLists" "https://github.com/danielmiessler/SecLists" "Collection of wordlists used for security assessments, discovery, usernames, passwords, and fuzzing." ;;
            3) useful_link_page "PacketLife Cheat Sheets" "https://packetlife.net/library/cheat-sheets/" "Networking protocol and command cheat sheets." ;;
            0) return ;;
            *) external_dispatch "$choice" "payloads / wordlists / cheatsheets" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

useful_links_training_menu() {
    local choice
    while true; do
        header "Tool_Box - Useful Links - Training"
        echo " 1) TryHackMe"
        echo " 2) PortSwigger Web Security Academy"
        external_render "training"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) useful_link_page "TryHackMe" "https://tryhackme.com/" "Hands-on cybersecurity training platform and lab environment." ;;
            2) useful_link_page "PortSwigger Web Security Academy" "https://portswigger.net/web-security" "Free web security learning material and interactive labs." ;;
            0) return ;;
            *) external_dispatch "$choice" "training" || { echo "Invalid option."; pause; } ;;
        esac
    done
}


custom_bookmarks_menu() {
    local bookmark_file="$HOME/.tool_box_links.tsv" choice title url description remove_num i
    local -a lines=()
    touch "$bookmark_file" 2>/dev/null || true
    chmod 600 "$bookmark_file" 2>/dev/null || true

    while true; do
        header "Tool_Box - Useful Links - Custom Bookmarks"
        mapfile -t lines < "$bookmark_file" 2>/dev/null || lines=()
        if ((${#lines[@]} > 0)); then
            echo "Saved bookmarks:"
            for ((i=0;i<${#lines[@]};i++)); do
                IFS=$'\t' read -r title url description <<< "${lines[$i]}"
                printf ' %2d) %s\n' "$((i+1))" "$title"
            done
        else
            echo "No custom bookmarks saved."
        fi
        echo ""
        echo " a) Add Bookmark"
        echo " r) Remove Bookmark"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            a|A)
                read -r -p "Title: " title
                read -r -p "URL: " url
                read -r -p "Description: " description
                [[ -n "$title" && "$url" =~ ^https?:// ]] || { msg_error "A title and http/https URL are required."; pause; continue; }
                title="${title//$'\t'/ }"; description="${description//$'\t'/ }"
                printf '%s\t%s\t%s\n' "$title" "$url" "$description" >> "$bookmark_file"
                msg_success "Bookmark saved."
                pause
                ;;
            r|R)
                read -r -p "Bookmark number to remove: " remove_num
                if [[ "$remove_num" =~ ^[0-9]+$ ]] && (( remove_num >= 1 && remove_num <= ${#lines[@]} )); then
                    : > "${bookmark_file}.tmp"
                    for ((i=0;i<${#lines[@]};i++)); do
                        (( i == remove_num-1 )) || printf '%s\n' "${lines[$i]}" >> "${bookmark_file}.tmp"
                    done
                    mv -- "${bookmark_file}.tmp" "$bookmark_file"
                    msg_success "Bookmark removed."
                else
                    msg_error "Invalid bookmark number."
                fi
                pause
                ;;
            0) return ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#lines[@]} )); then
                    IFS=$'\t' read -r title url description <<< "${lines[$((choice-1))]}"
                    useful_link_page "$title" "$url" "${description:-Custom bookmark.}"
                else
                    msg_error "Invalid option."
                    pause
                fi
                ;;
        esac
    done
}

useful_links_menu() {
    local choice
    while true; do
        header "Tool_Box - Useful Links"
        echo "Useful Links by Category:"
        echo ""
        echo " 1) Shell / Session Tools"
        echo " 2) Linux / Windows Privilege References"
        echo " 3) Data / Encoding / Analysis"
        echo " 4) Web Security"
        echo " 5) Recon / Vulnerability References"
        echo " 6) Payloads / Wordlists / Cheat Sheets"
        echo " 7) Training"
        echo " 8) Custom Bookmarks"
        external_render "useful links"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) useful_links_shell_menu ;;
            2) useful_links_privilege_menu ;;
            3) useful_links_data_menu ;;
            4) useful_links_web_menu ;;
            5) useful_links_recon_menu ;;
            6) useful_links_payloads_menu ;;
            7) useful_links_training_menu ;;
            8) custom_bookmarks_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "useful links" || { echo "Invalid option."; pause; } ;;
        esac
    done
}


# -------------------------
# Pass / Hash Cracking Menu
# -------------------------
pass_hash_cracking_menu() {
    local choice
    while true; do
        header "Tool_Box - Pass/Hash Cracking"
        echo "Pass / Hash Utilities:"
        echo ""
        echo " 1) Hash Identification Helper"
        echo " 2) Text / Encoding Tools"
        external_render "pass/hash cracking"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) hash_identifier_menu ;;
            2) text_encoding_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "pass/hash cracking" || { echo "Invalid option."; pause; } ;;
        esac
    done
}


# -------------------------
# Main Menu Groups
# -------------------------
target_scanning_menu() {
    local choice
    while true; do
        header "Tool_Box - Target & Scanning"
        echo "Target & Scanning:"
        echo ""
        echo " 1) Workspace / Project"
        echo " 2) Set Target / Data"
        echo " 3) Scan Profiles"
        echo " 4) Import Nmap Results"
        echo " 5) Service-Aware Recommendations"
        external_render "target & scanning"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) workspace_menu ;;
            2) set_data_menu ;;
            3) scan_profiles_menu ;;
            4) import_nmap_results ;;
            5) service_recommendations_page ;;
            0) return ;;
            *) external_dispatch "$choice" "target & scanning" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

recon_enumeration_hub_menu() {
    local choice
    while true; do
        header "Tool_Box - Recon & Enumeration"
        echo "Reconnaissance & Enumeration:"
        echo ""
        echo " 1) Reconnaissance"
        echo " 2) Web Enumeration"
        echo " 3) Network / DNS"
        echo " 4) SMB / Windows"
        echo " 5) Service Enumeration"
        echo " 6) Vulnerability Assessment"
        external_render "reconnaissance & enumeration"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) reconnaissance_menu ;;
            2) web_enumeration_menu ;;
            3) network_dns_menu ;;
            4) smb_windows_menu ;;
            5) service_enumeration_menu ;;
            6) vulnerability_assessment_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "reconnaissance & enumeration" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

access_exploitation_menu() {
    local choice
    while true; do
        header "Tool_Box - Access & Exploitation"
        echo "Credential Access & Exploitation:"
        echo ""
        echo " 1) Pass / Hash Cracking"
        echo " 2) Exploit"
        external_render "access & exploitation"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) pass_hash_cracking_menu ;;
            2) exploit_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "access & exploitation" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

analysis_reporting_menu() {
    local choice
    while true; do
        header "Tool_Box - Analysis & Reporting"
        echo "Analysis & Reporting:"
        echo ""
        echo " 1) Traffic Analysis"
        echo " 2) Results / Reporting"
        external_render "analysis & reporting"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) traffic_analysis_menu ;;
            2) results_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "analysis & reporting" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

utilities_resources_menu() {
    local choice
    while true; do
        header "Tool_Box - Utilities & Resources"
        echo "Utilities & Resources:"
        echo ""
        echo " 1) Command-Line Utilities"
        echo " 2) Network Information / VPN Status"
        echo " 3) Text / Encoding Tools"
        echo " 4) Port Reference"
        echo " 5) Useful Links"
        echo " 6) Quick Help / Workflow Guide"
        external_render "utilities & resources"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) utilities_menu ;;
            2) network_info_menu ;;
            3) text_encoding_menu ;;
            4) port_reference_menu ;;
            5) useful_links_menu ;;
            6) toolbox_quick_help ;;
            0) return ;;
            *) external_dispatch "$choice" "utilities & resources" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

# -------------------------
# Global navigation helpers
# -------------------------
restart_main_menu() {
    # Replace the current process rather than recursively calling main_menu().
    # Session variables are passed through the environment so the active target,
    # settings, and workspace survive a global Main Menu shortcut.
    local script_path
    script_path="$(readlink -f -- "$0" 2>/dev/null)"
    [[ -n "$script_path" && -f "$script_path" ]] || script_path="$0"

    exec env \
        TOOLBOX_NAV_RESTART=true \
        TOOLBOX_ELEVATED_SESSION="$toolbox_elevated_session" \
        TOOLBOX_PARENT_USER="$toolbox_parent_user" \
        TOOLBOX_SESSION_DOMAIN="$toolbox_domain" \
        TOOLBOX_SESSION_URL="$toolbox_url" \
        TOOLBOX_SESSION_USERNAME="$toolbox_username" \
        TOOLBOX_SESSION_IP="$ip" \
        TOOLBOX_SESSION_SUBNET="$subnet" \
        TOOLBOX_SESSION_PORT="$port" \
        TOOLBOX_SESSION_OUTPUT="$output_folder" \
        TOOLBOX_SESSION_WORDLIST="$default_wordlist" \
        TOOLBOX_SESSION_THREADS="$default_threads" \
        TOOLBOX_SESSION_AUTOSAVE="$auto_save_output" \
        TOOLBOX_SESSION_VERBOSE="$verbose_mode" \
        TOOLBOX_SESSION_DRYRUN="$dry_run_mode" \
        TOOLBOX_SESSION_COLOR="$color_enabled" \
        TOOLBOX_SESSION_WORKSPACE_NAME="$workspace_name" \
        TOOLBOX_SESSION_WORKSPACE_DIR="$workspace_dir" \
        TOOLBOX_SESSION_WORKSPACE_LOADED="$workspace_loaded" \
        bash "$script_path"
}

# -------------------------
# Privilege / user session management
# -------------------------
apply_session_state() {
    # Root-child sessions and global-navigation restarts receive the active
    # target/settings through environment variables. Apply them after config
    # loading so Tool_Box continues with the same working state.
    [[ "${TOOLBOX_SESSION_IP+x}" == x ]] && ip="$TOOLBOX_SESSION_IP"
    [[ "${TOOLBOX_SESSION_SUBNET+x}" == x ]] && subnet="$TOOLBOX_SESSION_SUBNET"
    [[ "${TOOLBOX_SESSION_PORT+x}" == x ]] && port="$TOOLBOX_SESSION_PORT"
    [[ "${TOOLBOX_SESSION_OUTPUT+x}" == x ]] && output_folder="$TOOLBOX_SESSION_OUTPUT"
    [[ "${TOOLBOX_SESSION_WORDLIST+x}" == x ]] && default_wordlist="$TOOLBOX_SESSION_WORDLIST"
    [[ "${TOOLBOX_SESSION_THREADS+x}" == x ]] && default_threads="$TOOLBOX_SESSION_THREADS"
    [[ "${TOOLBOX_SESSION_AUTOSAVE+x}" == x ]] && auto_save_output="$TOOLBOX_SESSION_AUTOSAVE"
    [[ "${TOOLBOX_SESSION_VERBOSE+x}" == x ]] && verbose_mode="$TOOLBOX_SESSION_VERBOSE"
    [[ "${TOOLBOX_SESSION_DRYRUN+x}" == x ]] && dry_run_mode="$TOOLBOX_SESSION_DRYRUN"
    [[ "${TOOLBOX_SESSION_COLOR+x}" == x ]] && color_enabled="$TOOLBOX_SESSION_COLOR"
    [[ "${TOOLBOX_SESSION_WORKSPACE_NAME+x}" == x ]] && workspace_name="$TOOLBOX_SESSION_WORKSPACE_NAME"
    [[ "${TOOLBOX_SESSION_WORKSPACE_DIR+x}" == x ]] && workspace_dir="$TOOLBOX_SESSION_WORKSPACE_DIR"
    [[ "${TOOLBOX_SESSION_WORKSPACE_LOADED+x}" == x ]] && workspace_loaded="$TOOLBOX_SESSION_WORKSPACE_LOADED"

    toolbox_domain="${TOOLBOX_SESSION_DOMAIN:-}"
    toolbox_url="${TOOLBOX_SESSION_URL:-}"
    toolbox_username="${TOOLBOX_SESSION_USERNAME:-}"
    refresh_colors
}

start_root_toolbox_session() {
    local script_path current_user status confirm

    header "Tool_Box - Privilege Management"

    if (( EUID == 0 )); then
        msg_warn "Tool_Box is already running as root."
        pause
        return 0
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        msg_error "sudo is not installed or is not available in PATH."
        pause
        return 1
    fi

    current_user="$(id -un)"
    script_path="$(readlink -f -- "$0" 2>/dev/null)"
    if [[ -z "$script_path" || ! -f "$script_path" ]]; then
        script_path="$0"
    fi

    echo "Current user : $current_user"
    echo "New session  : root"
    echo ""
    echo "This starts a ROOT Tool_Box session inside the current terminal."
    echo "Your current target, ports, output path, and active settings are carried over."
    echo "When the root Tool_Box session exits, you return to this $current_user session."
    echo ""
    msg_warn "Commands run from the elevated session have full root privileges."
    echo ""
    read -r -p "Start Tool_Box as root? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || {
        msg_warn "Elevation cancelled."
        pause
        return 0
    }

    echo ""
    msg_warn "sudo may prompt for the password for $current_user."

    # Use a nested sudo process instead of exec. This is intentional: after the
    # root child exits, the original standard-user Tool_Box continues with its
    # in-memory session state intact.
    sudo env \
        TOOLBOX_ELEVATED_SESSION=true \
        TOOLBOX_PARENT_USER="$current_user" \
        TOOLBOX_SESSION_DOMAIN="$toolbox_domain" \
        TOOLBOX_SESSION_URL="$toolbox_url" \
        TOOLBOX_SESSION_USERNAME="$toolbox_username" \
        TOOLBOX_SESSION_IP="$ip" \
        TOOLBOX_SESSION_SUBNET="$subnet" \
        TOOLBOX_SESSION_PORT="$port" \
        TOOLBOX_SESSION_OUTPUT="$output_folder" \
        TOOLBOX_SESSION_WORDLIST="$default_wordlist" \
        TOOLBOX_SESSION_THREADS="$default_threads" \
        TOOLBOX_SESSION_AUTOSAVE="$auto_save_output" \
        TOOLBOX_SESSION_VERBOSE="$verbose_mode" \
        TOOLBOX_SESSION_DRYRUN="$dry_run_mode" \
        TOOLBOX_SESSION_COLOR="$color_enabled" \
        TOOLBOX_SESSION_WORKSPACE_NAME="$workspace_name" \
        TOOLBOX_SESSION_WORKSPACE_DIR="$workspace_dir" \
        TOOLBOX_SESSION_WORKSPACE_LOADED="$workspace_loaded" \
        bash "$script_path"
    status=$?

    echo ""
    if (( status == 0 )); then
        msg_success "Returned to Tool_Box as $current_user."
    else
        msg_error "The root Tool_Box session exited with status $status."
    fi
    pause
    return "$status"
}

privilege_management_menu() {
    local choice current_user

    while true; do
        current_user="$(id -un)"
        header "Tool_Box - Privilege Management"
        echo "Privilege / User Session:"
        echo ""
        echo " Current User : $current_user"
        if (( EUID == 0 )); then
            printf ' Privileges   : %bROOT%b\n' "$C_RED$C_BOLD" "$C_RESET"
            if [[ "$toolbox_elevated_session" == true && -n "$toolbox_parent_user" ]]; then
                echo " Parent User  : $toolbox_parent_user"
                echo ""
                echo " 1) Return to $toolbox_parent_user Tool_Box"
            else
                echo ""
                echo " Tool_Box was started directly as root."
            fi
        else
            printf ' Privileges   : %bStandard user%b\n' "$C_GREEN" "$C_RESET"
            if command -v sudo >/dev/null 2>&1; then
                printf ' sudo         : %bAvailable%b\n' "$C_GREEN" "$C_RESET"
            else
                printf ' sudo         : %bUnavailable%b\n' "$C_RED" "$C_RESET"
            fi
            echo ""
            echo " 1) Start Tool_Box as Root"
        fi
        echo ""
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1)
                if (( EUID == 0 )); then
                    if [[ "$toolbox_elevated_session" == true && -n "$toolbox_parent_user" ]]; then
                        msg_success "Returning to $toolbox_parent_user..."
                        sleep 1
                        exit 0
                    else
                        msg_warn "There is no parent Tool_Box user session to return to."
                        pause
                    fi
                else
                    start_root_toolbox_session
                fi
                ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}


privilege_guide_page() {
    header "Tool_Box - Privilege Guide"
    cat <<'EOF'
Privilege guidance
------------------
[USER] Most web, DNS, SMB client, service enumeration, text processing, and reporting actions.
[ROOT OPTIONAL] Some Nmap options may work better with raw-socket privileges or capabilities.
[ROOT REQUIRED] Packet capture, some ARP/network discovery actions, and operations that modify system packages/repositories.

Tool_Box behavior
-----------------
- Elevated commands are marked before execution and require confirmation.
- A normal session can start a nested root Tool_Box from Privilege / User Session.
- When that root child exits, the original user session resumes.
- Workspaces and active target/settings are carried into the nested root session.
EOF
    echo ""
    pause
}

check_toolbox_update() {
    local remote remote_ver
    header "Tool_Box - Check for Update"
    if ! command -v curl >/dev/null 2>&1; then
        msg_error "curl is required to check GitHub."
        pause
        return 1
    fi
    echo "Checking: $toolbox_raw_url"
    remote="$(curl -fsSL --max-time 10 "$toolbox_raw_url" 2>/dev/null)" || {
        msg_error "Unable to retrieve the repository copy."
        pause
        return 1
    }
    remote_ver="$(printf '%s\n' "$remote" | sed -n 's/^ver="\([^"]*\)"/\1/p' | head -n1)"
    if [[ -z "$remote_ver" ]]; then
        msg_warn "Repository file was reachable, but its version could not be identified."
    else
        echo "Installed version : $ver"
        echo "Repository version: $remote_ver"
        if [[ "$remote_ver" == "$ver" ]]; then
            msg_success "This copy matches the repository version."
        else
            msg_info "A different version is available in the repository."
        fi
    fi
    echo ""
    msg_info "Tool_Box does not overwrite itself automatically."
    pause
}

expand_toolbox_path() {
    local path="$1"
    if [[ "$path" == "~" ]]; then
        path="$HOME"
    elif [[ "$path" == "~/"* ]]; then
        path="$HOME/${path#\~/}"
    fi
    printf '%s' "$path"
}

set_documentation_download_dir() {
    local requested create_choice resolved

    header "Tool_Box - Documentation - Download Location"
    echo "Current location: $documentation_download_dir"
    echo ""
    read -r -p "Enter download directory: " requested

    [[ -n "$requested" ]] || {
        msg_warn "Download location was not changed."
        pause
        return 1
    }

    requested="$(expand_toolbox_path "$requested")"

    if [[ ! -d "$requested" ]]; then
        read -r -p "Directory does not exist. Create it? [Y/n]: " create_choice
        if [[ "$create_choice" =~ ^[Nn]$ ]]; then
            msg_warn "Download location was not changed."
            pause
            return 1
        fi
        mkdir -p -- "$requested" 2>/dev/null || {
            msg_error "Unable to create directory: $requested"
            pause
            return 1
        }
    fi

    [[ -w "$requested" ]] || {
        msg_error "Directory is not writable: $requested"
        pause
        return 1
    }

    resolved="$(realpath -m -- "$requested" 2>/dev/null || printf '%s' "$requested")"
    documentation_download_dir="$resolved"
    msg_success "Documentation download location set to: $documentation_download_dir"
    pause
}

download_toolbox_document() {
    local url="$1"
    local filename="$2"
    local destination temp_file overwrite_choice downloader=""

    destination="${documentation_download_dir%/}/$filename"
    temp_file="${destination}.part.$$"

    if [[ ! -d "$documentation_download_dir" ]]; then
        msg_error "Download directory no longer exists: $documentation_download_dir"
        pause
        return 1
    fi

    if [[ ! -w "$documentation_download_dir" ]]; then
        msg_error "Download directory is not writable: $documentation_download_dir"
        pause
        return 1
    fi

    if [[ -e "$destination" ]]; then
        read -r -p "File already exists: $destination. Overwrite? [y/N]: " overwrite_choice
        [[ "$overwrite_choice" =~ ^[Yy]$ ]] || {
            msg_warn "Download cancelled."
            pause
            return 1
        }
    fi

    if command -v wget >/dev/null 2>&1; then
        downloader="wget"
    elif command -v curl >/dev/null 2>&1; then
        downloader="curl"
    else
        msg_error "Downloading documentation requires wget or curl."
        pause
        return 1
    fi

    echo ""
    echo "Source      : $url"
    echo "Destination : $destination"
    echo "Downloader  : $downloader"
    echo ""

    if [[ "$dry_run_mode" == true ]]; then
        msg_warn "DRY-RUN: Documentation was not downloaded."
        pause
        return 0
    fi

    rm -f -- "$temp_file" 2>/dev/null || true

    if [[ "$downloader" == "wget" ]]; then
        wget --https-only --timeout=20 --tries=2 -O "$temp_file" "$url" || {
            rm -f -- "$temp_file" 2>/dev/null || true
            msg_error "Download failed."
            pause
            return 1
        }
    else
        curl -fL --connect-timeout 10 --max-time 120 --retry 1 -o "$temp_file" "$url" || {
            rm -f -- "$temp_file" 2>/dev/null || true
            msg_error "Download failed."
            pause
            return 1
        }
    fi

    [[ -s "$temp_file" ]] || {
        rm -f -- "$temp_file" 2>/dev/null || true
        msg_error "The downloaded file was empty."
        pause
        return 1
    }

    mv -f -- "$temp_file" "$destination" || {
        rm -f -- "$temp_file" 2>/dev/null || true
        msg_error "Unable to move the downloaded file into place."
        pause
        return 1
    }

    msg_success "Downloaded: $destination"
    pause
}

download_all_toolbox_documents() {
    local failed=false

    # Download both without changing the selected download directory between files.
    # Each helper pauses so the user can see individual success/failure messages.
    download_toolbox_document "$toolbox_docs_pdf_url" "$toolbox_docs_pdf_name" || failed=true
    download_toolbox_document "$toolbox_docs_txt_url" "$toolbox_docs_txt_name" || failed=true

    [[ "$failed" == false ]]
}

documentation_download_menu() {
    local choice
    while true; do
        header "Tool_Box - Documentation"
        echo "Repository documentation:"
        echo ""
        echo " Full guide : $toolbox_docs_pdf_name"
        echo " Quick guide: $toolbox_docs_txt_name"
        echo " Location   : $documentation_download_dir"
        echo ""
        echo " 1) Download Full PDF Guide"
        echo " 2) Download Quick TXT Guide"
        echo " 3) Download Both Guides"
        echo " 4) Set Download Location"
        echo " 5) Open Repository"
        external_render "documentation"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) download_toolbox_document "$toolbox_docs_pdf_url" "$toolbox_docs_pdf_name" ;;
            2) download_toolbox_document "$toolbox_docs_txt_url" "$toolbox_docs_txt_name" ;;
            3) download_all_toolbox_documents ;;
            4) set_documentation_download_dir ;;
            5) useful_link_page "Tool_Box Repository" "$toolbox_repo_url" "Source repository and documentation for Tool_Box." ;;
            0) return ;;
            *) external_dispatch "$choice" "documentation" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

about_toolbox_menu() {
    local choice
    while true; do
        header "Tool_Box - About"
        echo "Version   : $ver"
        echo "Script    : ${BASH_SOURCE[0]}"
        echo "Repository: $toolbox_repo_url"
        echo ""
        echo "v0.30 adds repository documentation downloads with a user-selectable"
        echo "download location, while retaining the v0.29 navigation improvements."
        echo ""
        echo " 1) Open Repository"
        echo " 2) Copy Repository URL"
        echo " 3) Check Repository Version"
        echo " 4) Privilege Guide"
        echo " 5) Download Documentation"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) useful_link_page "Tool_Box Repository" "$toolbox_repo_url" "Source repository for Tool_Box." ;;
            2)
                if copy_to_clipboard "$toolbox_repo_url"; then msg_success "Repository URL copied."; else msg_warn "Clipboard helper unavailable."; fi
                pause
                ;;
            3) check_toolbox_update ;;
            4) privilege_guide_page ;;
            5) documentation_download_menu ;;
            0) return ;;
            *) msg_error "Invalid option."; pause ;;
        esac
    done
}

system_configuration_menu() {
    local choice
    while true; do
        header "Tool_Box - System & Configuration"
        echo "System & Configuration:"
        echo ""
        echo " 1) Install / Manage Software"
        echo " 2) Settings"
        echo " 3) Tool_Box Diagnostics"
        echo " 4) Privilege / User Session"
        echo " 5) About / Version / Update Check"
        echo " 6) Documentation / Download Guides"
        external_render "system & configuration"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) software_dependencies_menu ;;
            2) settings_menu ;;
            3) diagnostics_menu ;;
            4) privilege_management_menu ;;
            5) about_toolbox_menu ;;
            6) documentation_download_menu ;;
            0) return ;;
            *) external_dispatch "$choice" "system & configuration" || { echo "Invalid option."; pause; } ;;
        esac
    done
}

# -------------------------
# Main Menu
# -------------------------
main_menu() {
    local menu1

    # Load saved defaults automatically when present.
    if [[ -f "$config_file" ]]; then
        local line key value
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" == *=* ]] || continue
            key="${line%%=*}"
            value="${line#*=}"
            case "$key" in
                default_threads) [[ "$value" =~ ^[0-9]+$ ]] && default_threads="$value" ;;
                default_wordlist) default_wordlist="$value" ;;
                output_folder) output_folder="$value" ;;
                auto_save_output) [[ "$value" == true || "$value" == false ]] && auto_save_output="$value" ;;
                verbose_mode) [[ "$value" == true || "$value" == false ]] && verbose_mode="$value" ;;
                dry_run_mode) [[ "$value" == true || "$value" == false ]] && dry_run_mode="$value" ;;
                color_enabled) [[ "$value" == true || "$value" == false ]] && color_enabled="$value" ;;
            esac
        done < "$config_file"
    fi

    # A nested root session should inherit the active standard-user Tool_Box
    # state instead of resetting the target/settings when sudo starts it.
    if [[ "$toolbox_elevated_session" == true || "$toolbox_nav_restart" == true ]]; then
        apply_session_state
    fi

    external_restore || pause

    while true; do
        header "Tool_Box"
        printf '%b\n' "${C_BOLD}Main Menu${C_RESET}"
        echo ""
        echo " 1) Target & Scanning"
        echo " 2) Reconnaissance & Enumeration"
        echo " 3) Access & Exploitation"
        echo " 4) Analysis & Reporting"
        echo " 5) Utilities & Resources"
        echo " 6) System & Configuration"
        echo ""
        echo " 0) Exit"
        echo ""
        menu_prompt menu1

        case "$menu1" in
            1) target_scanning_menu ;;
            2) recon_enumeration_hub_menu ;;
            3) access_exploitation_menu ;;
            4) analysis_reporting_menu ;;
            5) utilities_resources_menu ;;
            6) system_configuration_menu ;;
            0)
                echo "Exiting..."
                exit 0
                ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

# -------------------------
# Start Program
# -------------------------
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    trap 'printf "%b\n" "$C_RESET"; exit 130' INT TERM
    main_menu
fi
