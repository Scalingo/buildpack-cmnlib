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
	trap cmn::bp::fail EXIT SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM
}

cmn::trap::teardown() {
	trap - EXIT SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM
}



cmn::bp::start() {
	cmn::trap::setup
}

cmn::bp::finish() {
	cmn::trap::teardown
	printf "\n%b%b%b\n" "${GREEN}" "All done." "${NC}"
	exit 0
}

cmn::bp::fail() {
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
	local file_checksum

	local hash_file
	local hash_algo
	local hash

	rc=1
	file="${1}"
	hash_file="${2}"

	hash_algo="${hash_file##*.}"

	if file_checksum="$( cmn::file::sum "${file}" "${hash_algo}" )"; then
		hash="$( cat "${hash_file}" )"

		if [ "${file_checksum}" = "${hash}" ]; then
			rc=0
		else
			rm --force "${file}"
		fi
	fi

	return "${rc}"
}

cmn::file::sum() {
	local checksum
	local rc=0

	local file="${1}"
	local hash_algo="${2}"

	case "${hash_algo}" in
		"sha1")
			checksum="$( shasum -a 1 "${file}" | cut -d " " -f 1 )"
			;;
		"sha256")
			checksum="$( shasum -a 256 "${file}" | cut -d " " -f 1 )"
			;;
		"md5")
			checksum="$( md5sum "${file}" | cut -d " " -f 1 )"
			;;
		*)
			rc=2
			;;
	esac

	printf "%s" "${checksum}"

	return "${rc}"
}

cmn::file::download() {
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



readonly -f cmn::output::info
readonly -f cmn::output::warn
readonly -f cmn::output::err

readonly -f cmn::trap::setup
readonly -f cmn::trap::teardown

readonly -f cmn::bp::start
readonly -f cmn::bp::finish
readonly -f cmn::bp::fail

readonly -f cmn::step::start
readonly -f cmn::step::finish
readonly -f cmn::step::fail

readonly -f cmn::task::start
readonly -f cmn::task::finish
readonly -f cmn::task::fail

readonly -f cmn::file::check_checksum
readonly -f cmn::file::sum
readonly -f cmn::file::download

readonly -f cmn::str::join

readonly -f cmn::env::read
readonly -f cmn::env::list
