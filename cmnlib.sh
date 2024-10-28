#!/usr/bin/env bash

STEP="------>"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

readonly RED
readonly GREEN
readonly YELLOW
readonly NC


# `cmn::output::debug`, `cmn::output::info`, `cmn::output::warn` and
# `cmn::output::err` leverage the same trick:
# Calling `exec` without a /command/ argument (which is the case here) applies
# any redirection applied to it to the current shell.
# Consequently, calling `exec <<< "${@}" feeds stdin with $@.
# This allows the function to be called with an argument or with an heredoc.


cmn::output::info() {
	[[ ${#} -gt 0 ]] && exec <<< "${@}"

	while read -r line; do
		printf "\t%b\n" "${line}"
	done
}

cmn::output::warn() {
	[[ ${#} -gt 0 ]] && exec <<< "${@}"

	while read -r line; do
		printf "%b !\t%b%b\n" "${YELLOW}" "${line}" "${NC}"
	done
}

cmn::output::err() {
	[[ ${#} -gt 0 ]] && exec <<< "${@}"

	while read -r line; do
		printf "%b !!\t%b%b\n" "${RED}" "${line}" "${NC}" >&2
	done

	if [[ -n ${DEBUG} ]]; then
		printf " !!\t%s\n" "Traceback:"

		for (( i=1; i<${#FUNCNAME[@]}; i++ )); do
			>&2 printf " !!\t%s: %s: %s\n" \
				"${BASH_SOURCE[i]}" \
				"${FUNCNAME[$i]}" \
				"${BASH_LINENO[$i-1]}"
		done
	fi
}

cmn::output::debug() {
	[[ -z "${DEBUG}" ]] && return

	[[ ${#} -gt 0 ]] && exec <<< "${@}"

	echo
	while read -r line; do
		printf " *\t%s: %s: %s: %s\n" \
			"${BASH_SOURCE[1]}" \
			"${FUNCNAME[1]}" \
			"${BASH_LINENO[0]}" \
			"${line}"
	done
}



cmn::trap::setup() {
	trap cmn::main::fail EXIT SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM
}

cmn::trap::teardown() {
	trap - EXIT SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM
}



cmn::main::start() {
	cmn::trap::setup
}

cmn::main::finish() {
	cmn::trap::teardown
	printf "\n%b%b%b\n" "${GREEN}" "All done." "${NC}"
	exit 0
}

cmn::main::fail() {
	cmn::trap::teardown
	printf "\n%b%b%b\n" "${RED}" "Failed." "${NC}" >&2
	exit 1
}



cmn::step::start() {
	printf "%s\t%b\n" "${STEP}" "${*}"
}

cmn::step::finish() {
	printf "%b\t%b%b\n" "${GREEN}" "Done." "${NC}"
}

cmn::step::fail() {
	printf "%b\t%b%b\n" "${RED}" "Failed." "${NC}"
}



cmn::task::start() {
	echo -n "	$*... "
}

cmn::task::finish() {
	echo "OK."
}

cmn::task::fail() {
	echo "Failed."

	if [[ -n "${1}" ]]; then
		cmn::output::err "${1}"
	fi
}



cmn::file::check_checksum() {
	local rc

	local file

	local hash_file
	local hash_algo
	local hash

	rc=1
	file="${1}"; shift
	hash_file="${1}"; shift

	hash_algo="${hash_file##*.}"

	hash="$( cut -d " " -f 1 < "${hash_file}" )"

	case "${hash_algo}" in
		"sha1")
			shasum --algorithm 1 --check --status <<< "${hash} ${file}"
			rc="${?}"
			;;
		"sha256")
			shasum --algorithm 256 --check --status <<< "${hash} ${file}"
			rc="${?}"
			;;
		"md5")
		    md5sum --check --status <<< "${hash} ${file}"
			rc="${?}"
			;;
		*)
			rc=2
			;;
	esac

	return "${rc}"
}

cmn::file::download() {
	local rc
	local url
	local cached

	rc=1
	url="${1}"; shift
	cached="${1}"; shift

	if curl --silent --retry 3 --location "${url}" --output "${cached}"; then
		rc=0
	fi

	return "${rc}"
}



cmn::str::join() {
	local IFS

	IFS="${1}"

	shift
	echo "${*}"
}



cmn::env::read() {
	local env_dir
	local env_vars

	env_dir="${1}"
	env_vars="$( cmn::env::list "${env_dir}" )"

	while read -r e; do
		local value
		value="$( cat "${env_dir}/${e}" )"

		export "${e}=${value}"
	done <<< "${env_vars}"
}

cmn::env::list() {
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

	blocklist_regex="^($( cmn::str::join "|" "${blocklist[@]}" ))$"

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



cmn::bp::run() {
	local rc
	local buildpack_url
	local build_dir
	local cache_dir
	local env_dir

	rc=1
	buildpack_url="${1}"; shift
	build_dir="${1}"; shift
	cache_dir="${1}"; shift
	env_dir="${1}"; shift

	local bp_dir
	bp_dir="$( mktemp --directory sub_buildpack_XXXXX )"

	# If the repo is not reachable, fail instead of asking for credentials
	if ! GIT_TERMINAL_PROMPT=0 \
			git clone --quiet --depth=1 "${buildpack_url}" "${bp_dir}" \
				2>/dev/null
	then
		rc=2
	else
		if ! "${bp_dir}/bin/compile" "${build_dir}" "${cache_dir}" "${env_dir}"
		then
			rc="${?}"
		else
			# Source `export` file if it exists:
			if [[ -f "${bp_dir}/export" ]]; then
				source "${bp_dir}/export"
			fi

			# Silently remove the buildpack temporary directory:
			rm --recursive --force "${bp_dir}"

			rc=0
		fi
	fi

	return "${rc}"
}



readonly -f cmn::output::info
readonly -f cmn::output::warn
readonly -f cmn::output::err

readonly -f cmn::trap::setup
readonly -f cmn::trap::teardown

readonly -f cmn::main::start
readonly -f cmn::main::finish
readonly -f cmn::main::fail

readonly -f cmn::step::start
readonly -f cmn::step::finish
readonly -f cmn::step::fail

readonly -f cmn::task::start
readonly -f cmn::task::finish
readonly -f cmn::task::fail

readonly -f cmn::file::check_checksum
readonly -f cmn::file::download

readonly -f cmn::str::join

readonly -f cmn::env::read
readonly -f cmn::env::list

readonly -f cmn::bp::run
