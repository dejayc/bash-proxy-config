#! /bin/bash

# bash-proxy-config: Copyright 2018 by Dejay Clayton, all rights reserved.
# Licensed under the 2-Clause BSD License.
#  https://github.com/dejayc/bash-proxy-config
#  http://opensource.org/licenses/BSD-2-Clause

# Enable the following line for development and testing of this script, but
# disable them during actual use, so that this script doesn't adversely
# interfere with the environment or specified commands.
set -eu

declare PROXY_LCS="abcdefghijklmnopqrstuvwxyz"
declare PROXY_UCS="ABCDEFGHIJKLMNOPQRSTUVWXYZ"

function proxy-call()
{
  proxy-exec "${@:+${@}}" &&:
  declare -i STATUS=$?

  [[ ${PROXY_CLEANUP_FUNCTIONS-0} -eq 0 ]] || proxy-cleanup-functions ||:
  unset PROXY_CLEANUP_FUNCTIONS
  return ${STATUS}
}
 
function proxy-cat()
{
  IFS='' read -r -d '' OUTPUT ||:
  echo "${OUTPUT}"
}

function proxy-cleanup-functions()
{
  unset -f \
    proxy-call proxy-cat proxy-cleanup-functions proxy-exec \
    proxy-get-settings proxy-lcase proxy-show proxy-ucase
  unset PROXY_LCS PROXY_UCS
}
 
function proxy-exec()
{
  local SETTINGS_FILE=''
  local DEFAULT_SETTINGS_FILE="${HOME-}/.bash-proxy-config/config.sh"

  # Parse function options.
  declare -i OPTIND
  local OPT=''

  while getopts ":f:u" OPT
  do
    case "${OPT}" in
    u)
      export PROXY_CLEANUP_FUNCTIONS=1
      ;;
    f)
      SETTINGS_FILE="${OPTARG}"
      ;;
    *) {
      echo "ERROR: Unsupported flag '-${OPTARG}' encountered"
      return 2
    } >&2
    esac
  done
  shift $(( OPTIND - 1 ))
  # Done parsing function options.

  local PROXIES_SETTINGS_LIST=''
  PROXIES_SETTINGS_LIST="$(
    proxy-get-settings "${SETTINGS_FILE}" "${DEFAULT_SETTINGS_FILE}" )" \
    || return

  declare -a ASSIGNMENTS=()
  IFS=$'\n' read -r -d '' -a ASSIGNMENTS <<< "${PROXIES_SETTINGS_LIST}" ||:

  declare -i I=0
  while [ ${I} -lt ${#ASSIGNMENTS[@]} ]
  do
    local ASSIGNMENT="${ASSIGNMENTS[I]}"
    let I+=1

    [[ "${ASSIGNMENT}" =~ ^([^=]+)=(.*)$ ]] && {
      local SETTING="${BASH_REMATCH[1]}"
      local VALUE="${BASH_REMATCH[2]}"

      eval declare "${SETTING}"="${VALUE}"
    }
  done
}

function proxy-cat()
{
  IFS='' read -r -d '' OUTPUT ||:
  echo "${OUTPUT}"
}

function proxy-get-settings()
{
  local SETTINGS_FILE="${1-}"
  local DEFAULT_SETTINGS_FILE="${2-}"

  if [[ -n "${SETTINGS_FILE-}" ]]
  then
    [[ -f "${SETTINGS_FILE}" ]] && source "${SETTINGS_FILE}" || {
      proxy-cat <<:ERR
ERROR: Unable to load the specified proxy settings file.  Please specify a
  valid file via the '-f' flag, or omit the flag to load the default file.
SPECIFIED FILE: '${SETTINGS_FILE}'
:ERR
      return 3
    } >&2
  else
    SETTINGS_FILE="${DEFAULT_SETTINGS_FILE}"

    [[ -f "${SETTINGS_FILE}" ]] && source "${SETTINGS_FILE}" || {
    proxy-cat <<:ERR
ERROR: Unable to load the default proxy settings file.  Please ensure that
  one exists, or specify a different file via the '-f' flag.
FILE: '${SETTINGS_FILE}'
:ERR
    return 3
    } >&2
  fi

  local PROXY_VAR_LIST=''
  PROXY_VAR_LIST="$( compgen -A variable 'PROXY_' )" || {
    proxy-cat <<:ERR
ERROR: Unable to retrieve a list of proxy configuration variables.  Please
  ensure that:
  1. one or more variables exist with prefix 'PROXY_'.  For example,
     to configure a proxy named 'local', define variables such as
     'PROXY_LOCAL_HTTP_URL', 'PROXY_LOCAL_URL', etc.
  2. bash command 'compgen -A variable PROXY_' works
SETTINGS FILE: '${SETTINGS_FILE}'
:ERR
    return 2
  } >&2

  declare -a PROXY_VARS=()
  IFS=$'\n' read -r -d '' -a PROXY_VARS <<< "${PROXY_VAR_LIST}" ||:

  declare -a PROXIES=()
  local PROXIES_LOOKUP=''

  declare -a SETTINGS=()

  declare -i I=0
  while [ ${I} -lt ${#PROXY_VARS[@]} ]
  do
    local PROXY_VAR="${PROXY_VARS[I]}"
    let I+=1

    [[ "${PROXY_VAR}" =~ ^PROXY_([0-9A-Z]+)_\
(((FTP_|HTTP_|HTTPS_)?URL)|NO_PROXY)$ ]] && {
      local PROXY="${BASH_REMATCH[1]}"
      [[ "${PROXIES_LOOKUP}" =~ \[${PROXY}\] ]] || {
        PROXIES[${#PROXIES[@]}]="${PROXY}"
        PROXIES_LOOKUP="[${PROXY}]${PROXIES_LOOKUP}"
      }
      local ASSIGNMENT=''
      printf -v ASSIGNMENT '%s=%q' "${PROXY_VAR}" "${!PROXY_VAR-}"
      SETTINGS[${#SETTINGS[@]}]="${ASSIGNMENT}"
    }
  done

  [[ ${#PROXIES[@]} -gt 0 ]] || {
    proxy-cat <<:ERR
ERROR: Unable to retrieve a list of proxy configuration variables.  Please
  ensure that one or more variables exist with prefix 'PROXY_'.  For example,
  to configure a proxy named 'local', define variables such as
  'PROXY_LOCAL_HTTP_URL', 'PROXY_LOCAL_URL', etc.
SETTINGS FILE: '${SETTINGS_FILE}'
:ERR
    return 2
  } >&2

  local ASSIGNMENT=''
  printf -v ASSIGNMENT '%s ' "${PROXIES[@]}"
  printf -v ASSIGNMENT '%s=%q' 'PROXIES_LIST' "${ASSIGNMENT%% }"
  SETTINGS[${#SETTINGS[@]}]="${ASSIGNMENT}"

  printf -v OUTPUT '%s\n' "${SETTINGS[@]}"
  echo -n "${OUTPUT%[[:space:]]}"
  echo "${OUTPUT%[[:space:]]}" >&2
}

function proxy-lcase()
{
  local TARGET="${1-}"
  local UCHAR=''
  local UOFFSET=''

  while [[ "${TARGET}" =~ ([A-Z]) ]]
  do
    UCHAR="${BASH_REMATCH[1]}"
    UOFFSET="${PROXY_UCS%%${UCHAR}*}"
    TARGET="${TARGET//${UCHAR}/${PROXY_LCS:${#UOFFSET}:1}}"
  done

  echo -n "${TARGET}"
}

function proxy-show()
{
  printf '%s: [%s]\n' \
    'FTP_PROXY' "${FTP_PROXY-}" \
    'HTTP_PROXY' "${HTTP_PROXY-}" \
    'HTTPS_PROXY' "${HTTPS_PROXY-}" \
    'ftp_proxy' "${ftp_proxy-}" \
    'http_proxy' "${http_proxy-}" \
    'https_proxy' "${https_proxy-}" \
    'no_proxy' "${no_proxy-}" \
    'NODE_TLS_REJECT_UNAUTHORIZED' "${NODE_TLS_REJECT_UNAUTHORIZED-}"
}

function proxy-ucase()
{
  local TARGET="${1-}"
  local LCHAR=''
  local LOFFSET=''

  while [[ "${TARGET}" =~ ([a-z]) ]]
  do
    LCHAR="${BASH_REMATCH[1]}"
    LOFFSET="${PROXY_LCS%%${LCHAR}*}"
    TARGET="${TARGET//${LCHAR}/${PROXY_UCS:${#LOFFSET}:1}}"
  done

  echo -n "${TARGET}"
}
