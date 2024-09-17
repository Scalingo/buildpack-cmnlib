#!/usr/bin/env bash

STEP="----->"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

readonly STEP
readonly RED
readonly GREEN
readonly YELLOW
readonly NC


cmnlib::info() {
    echo "       $*"
}

cmnlib::warn() {
    echo -e "${YELLOW} !     $*${NC}"
}

cmnlib::err() {
    echo -e "${RED} !!    $*${NC}" >&2
}


cmnlib::trap_setup() {
    trap cmnlib::fail EXIT SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM
}

cmnlib::trap_teardown() {
    trap - EXIT SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM
}


cmnlib::start() {
    cmnlib::trap_setup
}

cmnlib::finish() {
    cmnlib::trap_teardown
    echo
    echo -e "${GREEN}All done!${NC}"
    exit 0
}

cmnlib::fail() {
    cmnlib::trap_teardown
    echo
    echo -e "${RED}Failed.${NC}" >&2
    exit 1
}


cmnlib::step_start() {
    echo "${STEP} $*"
}

cmnlib::step_finish() {
    echo -e "${GREEN}       Done.${NC}"
}

cmnlib::step_fail() {
    echo -e "${RED}       Failed.${NC}"
}


cmnlib::task_start() {
    echo -n "       $*... "
}

cmnlib::task_finish() {
    echo "OK."
}

cmnlib::task_fail() {
    echo "Failed."

    if [[ -n "${1}" ]]; then
        cmnlib::err "${1}"
    fi
}


cmnlib::check_file_checksum() {
    local rc

    local file
    local file_checksum

    local hash_file
    local hash_algo
    local hash

    rc=1
    file="${1}"
    hash_file="${2}"

    hash_algo="${hash_file##*.}"

    case "${hash_algo}" in
        "sha1")
            file_checksum="$( shasum -a 1 "${file}" | cut -d " " -f 1 )"
            ;;
        "sha256")
            file_checksum="$( shasum -a 256 "${file}" | cut -d " " -f 1 )"
            ;;
        "md5")
            file_checksum="$( md5sum "${file}" | cut -d " " -f 1 )"
            ;;
        *)
            cmnlib::info "Unsupported hash algorithm. Aborting."
            rc=2
            ;;
    esac

    if [[ -n "${file_checksum}" ]]; then
        hash="$( cat "${hash_file}" )"

        if [[ "${file_checksum}" == "${hash}" ]]; then
            rc=0
        else
            rm --force "${file}"
        fi
    fi

    return "${rc}"
}

cmnlib::download() {
    local rc
    local url
    local cached

    rc=1
    url="${1}"
    cached="${2}"

    if curl --silent --retry 3 --location "${url}" --output "${cached}"; then
        rc=0
    fi

    return "${rc}"
}

cmnlib::str_join() {
    local IFS

    IFS="${1}"

    shift
    echo "${*}"
}


cmnlib::read_env() {
    local env_dir
    local env_vars

    env_dir="${1}"
    env_vars="$( cmnlib::list_env_vars "${env_dir}" )"

    while read -r e
    do
        local value
        value="$( cat "${env_dir}/${e}" )"

        export "${e}=${value}"
    done <<< "${env_vars}"
}

cmnlib::list_env_vars() {
    local env_dir
    local env_vars
    local blocklist
    local blocklist_regex

    env_dir="${1}"
    env_vars=""

    blocklist=( "PATH" "GIT_DIR" "CPATH" "CPPATH" )
    blocklist+=( "LD_PRELOAD" "LIBRARY_PATH" "LD_LIBRARY_PATH" )
    blocklist+=( "JAVA_OPTS" "JAVA_TOOL_OPTIONS" )
    blocklist+=( "BUILDPACK_URL" "BUILD_DIR" )

    blocklist_regex="^($( cmnlib::str_join "|" "${blocklist[@]}" ))$"

    if [[ -d "${env_dir}" ]]; then
        # shellcheck disable=SC2010
        env_vars="$( ls "${env_dir}" \
                        | grep \
                            --invert-match \
                            --extended-regexp \
                            "${blocklist_regex}" )"
    fi

    echo "${env_vars}"
}


readonly -f cmnlib::info
readonly -f cmnlib::warn
readonly -f cmnlib::err

readonly -f cmnlib::trap_setup
readonly -f cmnlib::trap_teardown

readonly -f cmnlib::start
readonly -f cmnlib::finish
readonly -f cmnlib::fail

readonly -f cmnlib::step_start
readonly -f cmnlib::step_finish
readonly -f cmnlib::step_fail

readonly -f cmnlib::task_start
readonly -f cmnlib::task_finish
readonly -f cmnlib::task_fail

readonly -f cmnlib::check_file_checksum
readonly -f cmnlib::download
readonly -f cmnlib::str_join

readonly -f cmnlib::read_env
readonly -f cmnlib::list_env_vars
