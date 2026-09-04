#!/bin/bash

# ==========================================================
# Tool_Box
# A menu-driven wrapper for common Linux/network lab tools.
# ==========================================================

# -------------------------
# Global configuration
# -------------------------
ver="0.23"
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

# Set by run_privileged_command() so elevated actions receive an extra warning.
command_requires_privilege=false

# Command currently being previewed.
command=()

# -------------------------
# Software database
# -------------------------
# Tools that have menus/documentation support. Some are also available through
# Tool_Box's apt-based installer; the rest remain menu/documentation-only.
software_keys=(
    nmap gobuster curl wget nc dig whois traceroute jq openssl
    tcpdump tshark ffuf feroxbuster whatweb nikto smbclient
    enum4linux-ng arp-scan metasploit ipcmd ssh snmpwalk
    ldapsearch showmount rpcinfo
)

# Software Tool_Box can install automatically on apt-based systems.
# Each major section keeps a focused list so it can expose its own
# software-management page without duplicating installer logic.
recon_software_keys=(nmap dig whois traceroute)
web_software_keys=(gobuster ffuf feroxbuster whatweb nikto curl openssl)
network_software_keys=(dig whois traceroute arp-scan nc ipcmd)
smb_software_keys=(enum4linux-ng smbclient nmap)
traffic_software_keys=(tcpdump tshark)
utilities_software_keys=(curl wget nc jq openssl)
profile_software_keys=(nmap whatweb curl gobuster smbclient)
service_software_keys=(nmap ssh nc snmpwalk ldapsearch showmount rpcinfo)
vulnerability_software_keys=(nmap)
installable_software_keys=(
    nmap dig whois traceroute
    gobuster ffuf feroxbuster whatweb nikto curl openssl
    arp-scan nc ipcmd
    enum4linux-ng smbclient
    tcpdump tshark
    wget jq
    ssh snmpwalk ldapsearch showmount rpcinfo
)

declare -A software_display software_command software_package software_status software_man software_repo_status

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

menu_prompt() {
    local variable_name="$1"
    printf '%b' "${C_CYAN}${C_BOLD} # ${C_RESET}"
    IFS= read -r "$variable_name"
}

header() {
    local title="$1"
    refresh_colors
    clear 2>/dev/null || true
    printf '%b\n' "${C_CYAN}${C_BOLD}========================================${C_RESET}"
    printf '%b\n' "  ${C_BOLD}${title}${C_RESET}  ${C_DIM}v${ver}${C_RESET}"
    printf '%b\n' "${C_CYAN}${C_BOLD}========================================${C_RESET}"
    printf '%b\n' "Target : ${C_YELLOW}${ip}/${subnet}${C_RESET}   Ports: ${C_YELLOW}${port}${C_RESET}"
    printf '%b\n' "Output : ${C_BLUE}${output_folder}${C_RESET}"
    printf '%b\n' "Modes  : Save $(toggle_status "$auto_save_output")  Verbose $(toggle_status "$verbose_mode")  Dry-Run $(toggle_status "$dry_run_mode")"
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
    printf '%q ' "${command[@]}"
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
    else
        "${command[@]}"
        status=$?
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
    else
        "${command[@]}" </dev/null
        status=$?
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
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) set_ip ;;
            2) set_subnet ;;
            3) set_ports ;;
            4) set_output_folder ;;
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
    nmap_save_output=false
    nmap_output_file=""
    nmap_custom=""

    nmap_render

    while true; do
        refresh_software_status nmap
        header "Tool_Box - Nmap"
        echo "Status: $(software_status_text nmap)"
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
        echo "11) Save Output             : $(toggle_status "$nmap_save_output")"
        [[ "$nmap_save_output" == true ]] && echo "    Output File             : $nmap_output_file"
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
            11) nmap_save_output=$(toggle_bool "$nmap_save_output") ;;
            12)
                require_program nmap || { pause; continue; }
                nmap_render
                [[ "$nmap_save_output" == true ]] && ensure_output_folder || true
                run_command
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
    nmap_output_file=""

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

    if [[ "$nmap_save_output" == true ]]; then
        nmap_output_file=$(build_output_file "nmap" "nmap")
        command+=("-oN" "$nmap_output_file")
    fi

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
    gobuster_save_output=false
    gobuster_output_file=""
    gobuster_custom=""
    gobuster_port="$(get_first_port)"

    gobuster_render

    while true; do
        refresh_software_status gobuster
        header "Tool_Box - Gobuster"
        echo "Status:   $(software_status_text gobuster)"
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
        echo "11) Save Output        : $(toggle_status "$gobuster_save_output")"
        [[ "$gobuster_save_output" == true ]] && echo "    Output File        : $gobuster_output_file"
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
            11) gobuster_save_output=$(toggle_bool "$gobuster_save_output") ;;
            12)
                require_program gobuster || { pause; continue; }
                gobuster_render
                run_command
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
    gobuster_output_file=""

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

    if [[ "$gobuster_save_output" == true ]]; then
        gobuster_output_file=$(build_output_file "web" "gobuster")
        command+=("-o" "$gobuster_output_file")
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
            *) echo "Invalid option."; pause ;;
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
            0) return ;;
            *) echo "Invalid option."; pause ;;
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
    local choice
    while true; do
        command=(dig -x "$ip")
        refresh_software_status dig
        header "Tool_Box - Reverse DNS"
        echo "Dig Status: $(software_status_text dig)"
        show_command
        echo ""
        echo " 1) Run Reverse DNS"
        echo " 2) View Dig Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program dig && run_command_logged "dns" "reverse-dns" || pause ;;
            2) view_man_page dig ;;
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
        show_command
        echo ""
        echo " 1) Query: $query"
        echo " 2) Run WHOIS"
        echo " 3) View WHOIS Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter IP or domain: " query ;;
            2) require_program whois && run_command_logged "recon" "whois" || pause ;;
            3) view_man_page whois ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

traceroute_menu() {
    local choice
    while true; do
        command=(traceroute "$ip")
        refresh_software_status traceroute
        header "Tool_Box - Traceroute"
        echo "Status: $(software_status_text traceroute)"
        show_command
        echo ""
        echo " 1) Run Traceroute"
        echo " 2) View Traceroute Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program traceroute && run_command_logged "network" "traceroute" || pause ;;
            2) view_man_page traceroute ;;
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
    local choice nc_port
    nc_port="$(get_first_port)"
    while true; do
        command=(nc -vz -w 3 "$ip" "$nc_port")
        refresh_software_status nc
        header "Tool_Box - Netcat TCP Test"
        echo "Netcat Status: $(software_status_text nc)"
        show_command
        echo ""
        echo " 1) Port: $nc_port"
        echo " 2) Run TCP Connection Test"
        echo " 3) View Netcat Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) read -r -p "Enter port: " nc_port; validate_port "$nc_port" || nc_port="$(get_first_port)" ;;
            2) require_program nc && run_command_logged "network" "netcat-test" || pause ;;
            3) view_man_page nc ;;
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
        show_command
        echo ""
        echo " 1) Show Local Interfaces"
        echo " 2) View ip Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) require_program ipcmd && run_command || pause ;;
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
        show_command
        echo ""
        echo " 1) Show Routing Table"
        echo " 2) View ip Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) require_program ipcmd && run_command || pause ;;
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
            *) echo "Invalid option."; pause ;;
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
                require_program smbclient && run_command || pause
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
            *) echo "Invalid option."; pause ;;
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
            *) echo "Invalid option."; pause ;;
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
        echo "Nmap Status: $(software_status_text nmap)"
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
            *) echo "Invalid option."; pause ;;
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
                run_command
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
        show_command
        echo ""
        echo " 1) List Interfaces"
        echo " 2) View tcpdump Man Page / Help"
        echo " 0) Back"
        menu_prompt choice
        case "$choice" in
            1) require_program tcpdump && run_command || pause ;;
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
            *) echo "Invalid option."; pause ;;
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
            2) require_program wget && run_command || pause ;;
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
                require_program openssl && run_command || pause
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
        echo ""
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
        printf '%s
' "${command_history[@]}"
    elif [[ -f "$history_file" ]]; then
        tail -n 100 "$history_file"
    else
        echo "No Tool_Box commands have been recorded yet."
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
        echo " 1) List Targets with Results"
        echo " 2) List Recent Result Files"
        echo " 3) View a Text Result"
        echo " 4) Show Current Target Result Directory"
        echo " 5) Compare Two Text Results"
        echo " 6) Generate Markdown Target Report"
        echo " 7) Archive Current Target Results"
        echo " 8) Delete a Result File"
        echo " 9) View Tool_Box Command History"
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) results_list_targets ;;
            2) results_recent_files ;;
            3) results_view_file ;;
            4)
                header "Tool_Box - Target Result Directory"
                echo "${output_folder%/}/$(safe_target_name)"
                echo ""
                pause
                ;;
            5) results_compare_files ;;
            6) generate_markdown_report ;;
            7) archive_target_results ;;
            8) delete_result_file ;;
            9) command_history_menu ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
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
            *) echo "Invalid option."; pause ;;
        esac
    done
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
            *) echo "Invalid option."; pause ;;
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
            0) return ;;
            *) echo "Invalid option."; pause ;;
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
        echo "This page only launches the local Metasploit console; Tool_Box does not install it."
        echo ""
        echo " 1) Launch msfconsole"
        echo " 2) Show Version"
        echo " 3) View Metasploit Man Page / Help"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) require_program metasploit && run_command || pause ;;
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
        echo " 0) Back"
        echo ""
        menu_prompt choice
        case "$choice" in
            1) metasploit_menu ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

# -------------------------
# Useful Links
# -------------------------
find_firefox_command() {
    if command -v firefox >/dev/null 2>&1; then
        printf '%s' "firefox"
        return 0
    fi
    if command -v firefox-esr >/dev/null 2>&1; then
        printf '%s' "firefox-esr"
        return 0
    fi
    return 1
}

find_chrome_command() {
    local candidate
    for candidate in google-chrome google-chrome-stable chrome; do
        if command -v "$candidate" >/dev/null 2>&1; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

browser_status_text() {
    local browser="$1"

    case "$browser" in
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

open_useful_link() {
    local browser="$1"
    local url="$2"
    local browser_command=""

    case "$browser" in
        firefox)
            browser_command=$(find_firefox_command) || {
                msg_error "Firefox is not installed or is not in PATH."
                pause
                return 1
            }
            ;;
        chrome)
            browser_command=$(find_chrome_command) || {
                msg_error "Google Chrome is not installed or is not in PATH."
                pause
                return 1
            }
            ;;
        *)
            msg_error "Unknown browser: $browser"
            pause
            return 1
            ;;
    esac

    if [[ "$dry_run_mode" == true ]]; then
        msg_warn "DRY-RUN: Would open $url with $browser_command"
        pause
        return 0
    fi

    "$browser_command" "$url" >/dev/null 2>&1 &
    msg_success "Opened link in $browser_command."
    sleep 1
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
        printf ' Firefox : %b\n' "$(browser_status_text firefox)"
        printf ' Chrome  : %b\n' "$(browser_status_text chrome)"
        echo ""
        echo " 1) Open in Firefox"
        echo " 2) Open in Chrome"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) open_useful_link firefox "$url" ;;
            2) open_useful_link chrome "$url" ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
        esac
    done
}

penelope_link_page() {
    useful_link_page \
        "Penelope" \
        "https://github.com/brightio/penelope" \
        "Penelope is a shell handler for authorized penetration-testing and lab work. Its project page documents interactive shell handling and related session-management features."
}

revshells_link_page() {
    useful_link_page \
        "Reverse Shell Generator" \
        "https://www.revshells.com/" \
        "A browser-based reference and generator for reverse-shell command formats across many common shells and platforms. Useful as a lab reference when working with systems you are authorized to test."
}

gtfobins_less_link_page() {
    useful_link_page \
        "GTFOBins - less" \
        "https://gtfobins.org/gtfobins/less/" \
        "The GTFOBins reference page for the Unix 'less' utility. It documents security-relevant behaviors of less that may matter when reviewing sudo rules, restricted shells, or other Linux privilege configurations."
}

cyberchef_link_page() {
    useful_link_page \
        "CyberChef" \
        "https://gchq.github.io/CyberChef/" \
        "GCHQ's browser-based data transformation and analysis toolkit. It is useful for encoding and decoding, hashes, text and byte manipulation, format conversion, and many other data-processing tasks."
}

useful_links_menu() {
    local choice

    while true; do
        header "Tool_Box - Useful Links"
        echo "Useful Links:"
        echo ""
        echo " 1) Penelope"
        echo " 2) Reverse Shell Generator"
        echo " 3) GTFOBins - less"
        echo " 4) CyberChef"
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            1) penelope_link_page ;;
            2) revshells_link_page ;;
            3) gtfobins_less_link_page ;;
            4) cyberchef_link_page ;;
            0) return ;;
            *) echo "Invalid option."; pause ;;
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
        echo "Pass/Hash Cracking:"
        echo ""
        echo " No tools have been added yet."
        echo ""
        echo " 0) Back"
        echo ""
        menu_prompt choice

        case "$choice" in
            0) return ;;
            *) echo "Invalid option."; pause ;;
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

    while true; do
        header "Tool_Box"
        echo "Menu:"
        echo " 1) Set Target / Data"
        echo " 2) Reconnaissance"
        echo " 3) Web Enumeration"
        echo " 4) Network / DNS"
        echo " 5) SMB / Windows"
        echo " 6) Service Enumeration"
        echo " 7) Traffic Analysis"
        echo " 8) Vulnerability Assessment"
        echo " 9) Pass/Hash Cracking"
        echo "10) Utilities"
        echo "11) Scan Profiles"
        echo "12) Results / Reporting"
        echo "13) Install Software"
        echo "14) Settings"
        echo "15) Tool_Box Diagnostics"
        echo "16) Exploit"
        echo "17) Useful Links"
        echo " 0) Exit"
        echo ""
        menu_prompt menu1

        case "$menu1" in
            1) set_data_menu ;;
            2) reconnaissance_menu ;;
            3) web_enumeration_menu ;;
            4) network_dns_menu ;;
            5) smb_windows_menu ;;
            6) service_enumeration_menu ;;
            7) traffic_analysis_menu ;;
            8) vulnerability_assessment_menu ;;
            9) pass_hash_cracking_menu ;;
            10) utilities_menu ;;
            11) scan_profiles_menu ;;
            12) results_menu ;;
            13) software_dependencies_menu ;;
            14) settings_menu ;;
            15) diagnostics_menu ;;
            16) exploit_menu ;;
            17) useful_links_menu ;;
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
trap 'printf "%b\n" "$C_RESET"; exit 130' INT TERM
main_menu
