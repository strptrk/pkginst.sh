#!/usr/bin/env bash
# vim ft=bash

__VERSION__=1.0.0
__NAME__=$(basename "$0")

usage(){
    cat <<EOF
Usage:
    ${__NAME__} [options] [--] PACKAGES

Options:
    -p    Set properties for package manager (instead of relying on automatic detection):
          Format is -p key="value"
          Possible keys are:
              install: command to install a package.
              installed: command to check if a package is installed.
              sudoprog: command for privilege escalation (you can leave it empty).
          Examples:
              ${__NAME__} -p install="pacman -S --noconfirm" -p installed="pacman -Q" -p sudoprog="doas"
              ${__NAME__} -p install="pkg install" -p installed="dpkg -s" -p sudoprog=""
    -v    Increase verbosity level. By default ${__NAME__} does not print anything.
          Use twice to enable debugging logs as well.
          Use thrice to enable package manager outputs.
    -h    Display this message
    -V    Display script version

Package Managers:
    Automatically detected package managers are (first found will be configured):
        pkg (termux)
        brew
        portage
        pacman
        dnf
        apt


Packages:
    For each package arguement, the script is going to check if the package is installed,
    and in case it is not, it will attempt to install it.

    Checking if the package is installed can be done with using either the executable name or the package name.
    - 1: `package_name`: the script will check if `package_name` is installed and attempt to install it in case it isn't.
    - 2: `{package_name1,package_name2...}`: the script will check if `package_name1` is installed and attempt to install it in case it isn't,
        but keep trying with `package_name2` ... and so on if the installation fails.
    - 3: `executable:package_name`: the script will check if `executable` can be run and to install `package_name` in case it cannot be.
    - 4: `executable:{package_name1,package_name2,...}`: the script will check if `executable` can be run and to install `package_name` in case it cannot be,
        but keep trying with `package_name2` ... and so on if the installation fails.
    - 5: `{executable1,executable2,...}:package_name`: the script will check if any of `executable1`, `executable2`, ... can be run and attempt to install `package_name` in case none of them can be.
    - 6: `{executable1,executable2,...}:{package_name1,package_name2,...}`: the script will check if any of `executable1`, `executable2`, ... can be run
        and attempt to install `package_name1`, `package_name2`, ... in case none of them can be.

    Examples:
        ${__NAME__} "{fd,fdfind}:{fd,fd-find}"
        ${__NAME__} "rg:ripgrep"
        ${__NAME__} "cmake"

Return code:
    ${__NAME__} returns 0 if every specified package could be installed.
    ${__NAME__} returns 1 if at least one package could not be installed.
EOF
}


declare -A pkgmanager=()
verbosity=0
silence_output=">/dev/null 2>&1"

log::1(){
    if ((verbosity >= 1)); then
        echo "$@"
    fi
}

log::2(){
    if ((verbosity >= 2)); then
        echo "$@"
    fi
}

cmd::exists(){
    command -v "$1" >/dev/null 2>&1
}

pkg::parse_option(){
    local pkgopt="$1"
    IFS=':' read -r -a split <<< "${pkgopt}"
    echo "${split[0]}"
}

pkg::install(){
    eval "${pkgmanager[sudoprog]} ${pkgmanager[install]} $1 ${silence_output}"
}

pkg::installed(){
    eval "${pkgmanager[installed]} $1 ${silence_output}"
}

pkg::install_needed(){
    log::2 "------------"
    local return_value=0
    for pkgopt in "$@"; do
        IFS=':' read -r -a split <<< "${pkgopt}"
        local executables
        local packages
        IFS=" " read -r -a executables <<< "$(eval "echo ${split[0]}")"
        IFS=" " read -r -a packages <<< "$(eval "echo ${split[1]}")"
        if [[ -z "${packages[0]}" ]]; then
            packages=("${executables[@]}")
            executables=()
        fi

        log::2 executables = "[${executables[*]}]"
        log::2 packages = "[${packages[*]}]"

        local found_type="Package"

        local installed=""

        for executable in "${executables[@]}"; do
            if cmd::exists "${executable}"; then
                installed="${executable}"
                found_type="Executable"
                break
            fi
        done

        if [[ -z "${installed}" ]]; then
            for package in "${packages[@]}"; do
                if pkg::installed "${package}"; then
                    installed="${package}"
                    break;
                fi
            done
        fi

        if [[ -z "${installed}" ]]; then
            local success=false
            for package in "${packages[@]}"; do
                if pkg::install "${package}"; then
                    success=true
                    installed="${package}"
                    break;
                fi
            done

            if "${success}"; then
                log::1 "Installed ${installed}"
            else
                log::1 "None of [${packages[*]}] could be installed!" >&2
                return_value=1
            fi
        else
            log::1 "${found_type} ${installed} is already installed."
        fi
        log::2 "------------"
    done
    return "${return_value}"
}

pkg::setup_force(){
    local optionstring="$1"
    IFS='=' read -r -a split <<< "${optionstring}"
    pkgmanager[${split[0]}]="${split[*]:1}"
}

pkg::setup_auto(){
    if cmd::exists doas; then
        pkgmanager[sudoprog]=doas
    elif cmd::exists sudo; then
        pkgmanager[sudoprog]=sudo
    fi

    if cmd::exists pkg; then
        pkgmanager[install]="pkg install -y"
        pkgmanager[installed]="dpkg -s"
        pkgmanager[sudoprog]=""
    elif cmd::exists brew; then
        pkgmanager[install]="brew install"
        pkgmanager[installed]="brew ls --versions"
        pkgmanager[sudoprog]=""
    elif cmd::exists emerge; then
        pkgmanager[install]="emerge -a n"
        pkgmanager[installed]="equery list"
    elif cmd::exists pacman; then
        pkgmanager[install]="pacman -S --noconfirm"
        pkgmanager[installed]="pacman -Q"
    elif cmd::exists dnf; then
        pkgmanager[install]="dnf install -y"
        pkgmanager[installed]="dnf list installed"
    elif cmd::exists apt; then
        pkgmanager[install]="apt install -y"
        pkgmanager[installed]="dpkg -s"
    else
        return 1
    fi
    return 0
}

main(){
    pkg::setup_auto
    while getopts ":hVp:v" opt; do
        case "${opt}" in
            h)
                usage
                exit 0
                ;;
            p)
                pkg::setup_force "${OPTARG}"
                ;;
            V)
                echo "${__VERSION__}"
                exit 0
                ;;
            v)
                verbosity=$((verbosity + 1))
                ;;
            *)
                echo -e "\n  Option does not exist : ${OPTARG}\n"
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))

    if ((verbosity > 3)); then
        verbosity=3
    fi

    if ((verbosity == 3)); then
        silence_output=""
    fi

    log::2 "Verbosity level: ${verbosity}"

    log::2 "Package manager configuration:"
    log::2 "    sudoprog  = \"${pkgmanager[sudoprog]}\""
    log::2 "    install   = \"${pkgmanager[install]}\""
    log::2 "    installed = \"${pkgmanager[installed]}\""

    pkg::install_needed "$@"
}

main "$@"
