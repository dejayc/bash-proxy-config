#! /bin/bash

# bash-proxy-config: Copyright 2018 by Dejay Clayton, all rights reserved.
# Licensed under the 2-Clause BSD License.
#  https://github.com/dejayc/bash-proxy-config
#  http://opensource.org/licenses/BSD-2-Clause

# Enable the following line for development and testing of this script, but
# disable them during actual use, so that this script doesn't adversely
# interfere with the environment or specified commands.
set -eu

function proxy-call()
{
  proxy-exec "${@:+${@}}"
}
 
function proxy-exec()
{
  local SETTINGS_FILE="./config.sh"

  local PROXIES_SETTINGS_LIST=''
  PROXIES_SETTINGS_LIST="$(
    proxy-get-settings "${SETTINGS_FILE}" )" || return

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

  if [[ -n "${SETTINGS_FILE-}" ]]
  then
    [[ -f "${SETTINGS_FILE}" ]] && source "${SETTINGS_FILE}" || {
      proxy-cat <<:ERR
ERROR: Unable to load the default proxy settings file.  Please ensure that
  one exists.
FILE: '${SETTINGS_FILE}'
:ERR
      return 3
    } >&2
  else
    proxy-cat <<:ERR
ERROR: No default proxy settings file was specified
:ERR
    return 3
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
