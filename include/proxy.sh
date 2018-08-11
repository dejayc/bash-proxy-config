#! /bin/bash

# bash-proxy-config: Copyright 2018 by Dejay Clayton, all rights reserved.
# Licensed under the 2-Clause BSD License.
#  https://github.com/dejayc/bash-proxy-config
#  http://opensource.org/licenses/BSD-2-Clause

# Enable the following line for development and testing of this script, but
# disable them during actual use, so that this script doesn't adversely
# interfere with the environment or specified commands.
# set -eu

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
    proxy-get-settings proxy-lcase proxy-settings proxy-show proxy-ucase
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

  declare -a PROXIES_SETTINGS=()

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

      [[ "${SETTING}" =~ ^PROXY_ ]] && {
        PROXIES_SETTINGS[${#PROXIES_SETTINGS[@]}]="${SETTING}=${VALUE}"
      }
    }
  done

  PROXIES_LIST="$( proxy-ucase "${PROXIES_LIST}" )"
  declare -a PROXIES="( ${PROXIES_LIST} )"

  local PROXIES_LOOKUP=''
  printf -v PROXIES_LOOKUP '[%s]' "${PROXIES[@]}"

  printf -v PROXIES_LIST '%s, ' "${PROXIES[@]}"
  PROXIES_LIST="$( proxy-lcase "${PROXIES_LIST%%, }" )"

  # The following syntaxes are supported:
  # proxy [for:all|nonlocal] [to:PROXY] [CMD]

  local FLAG_FOR=''
  local FLAG_TO=''
  local FLAG_TO_LC=''
  local FLAG_OFF=''

  while [ ${#} -gt 0 ]
  do
    local ARG="${1}"

    case "${ARG}" in
    'for:'*)
      [[ "${ARG}" =~ ^for:(.+)$ ]] || {
        echo "ERROR: Parameter 'for:' requires a value"
        return 1
      } >&2

      FLAG_FOR="${BASH_REMATCH[1]}"
      [[ "${FLAG_FOR}" =~ ^all|nonlocal$ ]] || {
        proxy-cat <<:ERR
ERROR: Parameter 'for:' contains an invalid value.  Allowed values are 'all'
  or 'nonlocal'
VALUE: '${FLAG_FOR}'
:ERR
        return 1
      } >&2

      shift
      ;;

    'off')
      let FLAG_OFF=1
      shift
      ;;

    'to:'*)
      [[ "${ARG}" =~ ^to:(.+)$ ]] || {
        echo "ERROR: Parameter 'to:' requires a value"
        return 1
      } >&2

      FLAG_TO="$( proxy-ucase "${BASH_REMATCH[1]}" )"
      FLAG_TO_LC="$( proxy-lcase "${FLAG_TO}" )"

      [[ "${PROXIES_LOOKUP}" =~ \[${FLAG_TO}\] ]] || {
        proxy-cat <<:ERR
ERROR: Parameter 'to:' references an undefined proxy configuration
PROXY: '${FLAG_TO_LC}'
VALID PROXIES: ${PROXIES_LIST}
SETTINGS FILE: '${SETTINGS_FILE}'
:ERR
        return 2
      } >&2

      shift
      ;;

    *)
      break
      ;;
    esac
  done

  local CMD=''
  [[ $# -gt 0 ]] && {
    CMD="$( printf '%q ' "${@}" )"
    CMD="${CMD% }"
  }

  declare -i STATUS=0

  if [[ ${FLAG_OFF} -ne 0 ]]
  then
    [[ -z "${FLAG_FOR}${FLAG_TO}" ]] || {
      echo "ERROR: Parameter 'off' may not be combined with other parameters"
      return 1
    } >&2

    if [[ $# -gt 0 ]]
    then
      echo 'Disabling proxy for command'
      HTTP_PROXY='' \
        HTTPS_PROXY='' \
        http_proxy='' \
        https_proxy='' \
        no_proxy='' \
        NODE_TLS_REJECT_UNAUTHORIZED=1 \
        eval "${CMD}" || let STATUS=${?} ||:
        return ${STATUS}
    else
      echo 'Disabling proxy'
      unset HTTP_PROXY
      unset HTTPS_PROXY
      unset http_proxy
      unset https_proxy
      unset no_proxy
      unset NODE_TLS_REJECT_UNAUTHORIZED
    fi
  else
    [[ -n "${FLAG_TO}" ]] || {
      [[ -n "${PROXY_DEFAULT_TO-}" ]] || {
        proxy-cat <<:ERR
ERROR: Parameter 'to:' was missing, and no default proxy configuration was
  specified via proxy configuration variable
VARIABLE: 'PROXY_DEFAULT_TO'
VALID VALUES: ${PROXIES_LIST}
SETTINGS FILE: '${SETTINGS_FILE}'
:ERR
        return 1
      } >&2

      FLAG_TO="$( proxy-ucase "${PROXY_DEFAULT_TO}" )"
      FLAG_TO_LC="$( proxy-lcase "${FLAG_TO}" )"
    }

    [[ -n "${FLAG_FOR}" ]] || {

      local PROXY_FOR_VAR="PROXY_$( proxy-ucase "${FLAG_TO}" )_FOR"
      local PROXY_FOR="${!PROXY_FOR_VAR-}"

      [[ -n "${PROXY_FOR}" ]] || {
        proxy-cat <<:ERR
ERROR: Parameter 'for:' was missing, and no default value was specified via
  the proxy configuration variable
VARIABLE: '${PROXY_FOR_VAR}'
SETTINGS FILE: '${SETTINGS_FILE}'
:ERR
        return 2
      } >&2

      FLAG_FOR="$( proxy-lcase "${PROXY_FOR}" )"
    }

    local PROXY_NO_PROXY_VAR=''
    local PROXY_NO_PROXY=''

    [[ "${FLAG_FOR}" == 'nonlocal' ]] && {
      PROXY_NO_PROXY_VAR="PROXY_${FLAG_TO}_NO_PROXY"
      PROXY_NO_PROXY="${!PROXY_NO_PROXY_VAR-}"
    }

    local PROXY_FTP_URL_VAR="PROXY_${FLAG_TO}_FTP_URL"
    local PROXY_FTP_URL="${!PROXY_FTP_URL_VAR-}"

    local PROXY_HTTP_URL_VAR="PROXY_${FLAG_TO}_HTTP_URL"
    local PROXY_HTTP_URL="${!PROXY_HTTP_URL_VAR-}"

    local PROXY_HTTPS_URL_VAR="PROXY_${FLAG_TO}_HTTPS_URL"
    local PROXY_HTTPS_URL="${!PROXY_HTTPS_URL_VAR-}"

    if [[ $# -gt 0 ]]
    then
      echo \
"Proxying ${FLAG_FOR} traffic to '${FLAG_TO_LC}' for command"
      FTP_PROXY="${PROXY_FTP_URL}" \
        HTTP_PROXY="${PROXY_HTTP_URL}" \
        HTTPS_PROXY="${PROXY_HTTPS_URL}" \
        ftp_proxy="${PROXY_FTP_URL}" \
        http_proxy="${PROXY_HTTP_URL}" \
        https_proxy="${PROXY_HTTPS_URL}" \
        no_proxy="${PROXY_NO_PROXY}" \
        NODE_TLS_REJECT_UNAUTHORIZED=0 \
        eval "${CMD}" || let STATUS=${?} ||:
        return ${STATUS}
    else
      echo "Proxying ${FLAG_FOR} traffic to '${FLAG_TO_LC}'"
      export FTP_PROXY="${PROXY_FTP_URL}"
      export HTTP_PROXY="${PROXY_HTTP_URL}"
      export HTTPS_PROXY="${PROXY_HTTPS_URL}"
      export ftp_proxy="${PROXY_FTP_URL}"
      export http_proxy="${PROXY_HTTP_URL}"
      export https_proxy="${PROXY_HTTPS_URL}"
      export no_proxy="${PROXY_NO_PROXY}"
      export NODE_TLS_REJECT_UNAUTHORIZED=0
    fi
  fi
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
     'PROXY_LOCAL_HTTP_URL', 'PROXY_LOCAL_DEFAULT', etc.
  2. bash command 'compgen -A variable PROXY_' works
SETTINGS FILE: '${SETTINGS_FILE}'
:ERR
    return 2
  } >&2

  declare -a PROXY_VARS=()
  IFS=$'\n' read -r -d '' -a PROXY_VARS <<< "${PROXY_VAR_LIST}" ||:

  declare -a PROXIES=()
  local PROXIES_LOOKUP=''

  declare -i I=0
  while [ ${I} -lt ${#PROXY_VARS[@]} ]
  do
    local PROXY_VAR="${PROXY_VARS[I]}"
    let I+=1

    [[ "${PROXY_VAR}" =~ ^PROXY_([0-9A-Z]+)_\
(DEFAULT|((FTP_|HTTP_|HTTPS_)?URL)|NO_PROXY)$ ]] && {
      local PROXY="${BASH_REMATCH[1]}"
      [[ "${PROXIES_LOOKUP}" =~ \[${PROXY}\] ]] || {
        PROXIES[${#PROXIES[@]}]="${PROXY}"
        PROXIES_LOOKUP="[${PROXY}]${PROXIES_LOOKUP}"
      }
    }
  done

  [[ ${#PROXIES[@]} -gt 0 ]] || {
    proxy-cat <<:ERR
ERROR: Unable to retrieve a list of proxy configuration variables.  Please
  ensure that one or more variables exist with prefix 'PROXY_'.  For example,
  to configure a proxy named 'local', define variables such as
  'PROXY_LOCAL_HTTP_URL', 'PROXY_LOCAL_DEFAULT', etc.
SETTINGS FILE: '${SETTINGS_FILE}'
:ERR
    return 2
  } >&2

  local ORDERED=''

  declare -i I=0
  while [ ${I} -lt ${#PROXIES[@]} ]
  do
    local PROXY="${PROXIES[I]}"
    let I+=1

    local DEFAULT_VAR="PROXY_${PROXY}_DEFAULT"
    local DEFAULT="$( proxy-ucase "${!DEFAULT_VAR-}" )"

    [[ -n "${DEFAULT}" ]] || {
      [[ "${ORDERED}" =~ \[${PROXY}\] ]] || ORDERED="[${PROXY}]${ORDERED}"
      continue
    }

    local PROXY_LC="$( proxy-lcase "${PROXY}" )"
    local DEFAULT_LC="$( proxy-lcase "${DEFAULT}" )"

    [[ "${DEFAULT}" != "${PROXY}" ]] || {
      proxy-cat <<:ERR
ERROR: Proxy configuration cannot default to itself
PROXY: '${PROXY_LC}'
:ERR
      return 2
    } >&2

    [[ "${DEFAULT}" =~ ^[0-9A-Z]+$ ]] || {
      proxy-cat <<:ERR
ERROR: Proxy configuration contains invalid default configuration name
PROXY: '${PROXY_LC}'
DEFAULT: '${DEFAULT_LC}'
:ERR
      return 2
    } >&2

    [[ "${PROXIES_LOOKUP}" =~ \[${DEFAULT}\] ]] || {
      proxy-cat <<:ERR
ERROR: Proxy configuration references undefined default configuration
PROXY: '${PROXY_LC}'
DEFAULT: '${DEFAULT_LC}'
:ERR
      return 2
    } >&2

    if [[ "${ORDERED}" =~ \[${PROXY}\] ]]
    then
      if [[ "${ORDERED}" =~ \[${PROXY}\].*\[${DEFAULT}\] ]]
      then {
        proxy-cat <<:ERR
ERROR: Proxy configuration has circular dependency upon default configuration
PROXY: '${PROXY_LC}'
DEFAULT: '${DEFAULT_LC}'
:ERR
        return 2
      } >&2
      else
        ORDERED="${ORDERED//\[${PROXY}\]/[${DEFAULT}][${PROXY}]}"
      fi
    else
      if [[ "${ORDERED}" =~ \[${DEFAULT}\] ]]
      then
        ORDERED="${ORDERED//\[${DEFAULT}\]/[${DEFAULT}][${PROXY}]}"
      else
        ORDERED="[${DEFAULT}][${PROXY}]${ORDERED}"
      fi
    fi
  done

  ORDERED="${ORDERED//\]\[/ }"
  ORDERED="${ORDERED#\[}"
  ORDERED="${ORDERED%\]}"
  declare -a ORDERED_PROXIES=()
  read -a ORDERED_PROXIES -d '' <<< "${ORDERED}"

  declare -a SETTINGS=()

  local DEFAULT_TO_VAR="PROXY_DEFAULT_TO"
  local DEFAULT_TO="$( proxy-ucase "${!DEFAULT_TO_VAR-}" )"
  local DEFAULT_TO_LC="$( proxy-lcase "${DEFAULT_TO}" )"

  [[ -n "${DEFAULT_TO}" ]] && {
    [[ "${PROXIES_LOOKUP}" =~ \[${DEFAULT_TO}\] ]] || {
      proxy-cat <<:ERR
ERROR: Proxy variable 'DEFAULT_TO' references an undefined configuration
DEFAULT_TO: '${DEFAULT_TO_LC}'
:ERR
      return 2
    } >&2

    declare "${DEFAULT_TO_VAR}"="${DEFAULT_TO}"
    local ASSIGNMENT=''
    printf -v ASSIGNMENT '%s=%q' "${DEFAULT_TO_VAR}" "${DEFAULT_TO}"
    SETTINGS[${#SETTINGS[@]}]="${ASSIGNMENT}"
  }

  let I=0
  while [ ${I} -lt ${#ORDERED_PROXIES[@]} ]
  do
    local PROXY="${ORDERED_PROXIES[I]}"
    let I+=1

    local DEFAULT_VAR="PROXY_${PROXY}_DEFAULT"
    local DEFAULT="$( proxy-ucase "${!DEFAULT_VAR-}" )"

    local PROXY_FOR_VAR="PROXY_${PROXY}_FOR"
    local PROXY_FOR="$( proxy-lcase "${!PROXY_FOR_VAR-}" )"

    [[ -n "${PROXY_FOR}" ]] && {
      [[ "${PROXY_FOR}" =~ ^all|nonlocal$ ]] || {
        proxy-cat <<:ERR
ERROR: Proxy variable '${PROXY_FOR_VAR}' contains an invalid value.  Valid
  values are 'all' or 'nonlocal'
${PROXY_FOR_VAR}: '${PROXY_FOR}'
:ERR
        return 2
      } >&2
    }

    [[ -z "${PROXY_FOR}" && -n "${DEFAULT}" ]] && {
      local DEFAULT_FOR_VAR="PROXY_${DEFAULT}_FOR"
      PROXY_FOR="$( proxy-lcase "${!DEFAULT_FOR_VAR-}" )"
    }

    declare "${PROXY_FOR_VAR}"="${PROXY_FOR}"
    local ASSIGNMENT=''
    printf -v ASSIGNMENT '%s=%q' "${PROXY_FOR_VAR}" "${PROXY_FOR}"
    SETTINGS[${#SETTINGS[@]}]="${ASSIGNMENT}"

    local PROXY_NO_PROXY_VAR="PROXY_${PROXY}_NO_PROXY"
    local PROXY_NO_PROXY="${!PROXY_NO_PROXY_VAR-}"

    [[ -z "${PROXY_NO_PROXY}" && -n "${DEFAULT}" ]] && {
      local DEFAULT_NO_PROXY_VAR="PROXY_${DEFAULT}_NO_PROXY"
      PROXY_NO_PROXY="${!DEFAULT_NO_PROXY_VAR-}"
    }

    declare "${PROXY_NO_PROXY_VAR}"="${PROXY_NO_PROXY}"
    local ASSIGNMENT=''
    printf -v ASSIGNMENT '%s=%q' "${PROXY_NO_PROXY_VAR}" "${PROXY_NO_PROXY}"
    SETTINGS[${#SETTINGS[@]}]="${ASSIGNMENT}"

    declare -a ATTRS=( 'URL' )
    declare -i A=0

    while [ ${A} -lt ${#ATTRS[@]} ]
    do
      local ATTR="${ATTRS[A]}"
      let A+=1

      local DEFAULT_FALLBACK_ATTR_VAR=''
      local DEFAULT_FALLBACK_ATTR=''

      [[ -n "${DEFAULT}" ]] && {
        DEFAULT_FALLBACK_ATTR_VAR="PROXY_${DEFAULT}_${ATTR}"
        DEFAULT_FALLBACK_ATTR="${!DEFAULT_FALLBACK_ATTR_VAR-}"
      }

      local PROXY_FALLBACK_ATTR_VAR="PROXY_${PROXY}_${ATTR}"
      local PROXY_FALLBACK_ATTR="${!PROXY_FALLBACK_ATTR_VAR-}"

      declare -a PROTOCOLS=( 'FTP' 'HTTP' 'HTTPS' )
      declare -i P=0

      while [ ${P} -lt ${#PROTOCOLS[@]} ]
      do
        local PROTOCOL="${PROTOCOLS[P]}"
        let P+=1

        local PROXY_PROTOCOL_ATTR_VAR="PROXY_${PROXY}_${PROTOCOL}_${ATTR}"

        declare -a VARS=(
          "${PROXY_PROTOCOL_ATTR_VAR}" "${PROXY_FALLBACK_ATTR_VAR}" )

        [[ -n "${DEFAULT}" ]] && {
          VARS[${#VARS[@]}]="PROXY_${DEFAULT}_${PROTOCOL}_${ATTR}"
          VARS[${#VARS[@]}]="PROXY_${DEFAULT}_${ATTR}"
        }

        local SETTING=''

        declare -i V=0
        while [ ${V} -lt ${#VARS[@]} ]
        do
          local VAR="${VARS[V]}"
          let V+=1

          [[ -n "${!VAR-}" ]] && {
            SETTING="${!VAR}"
            break
          }
        done

        declare "${PROXY_PROTOCOL_ATTR_VAR}"="${SETTING}"
        local ASSIGNMENT=''
        printf -v ASSIGNMENT '%s=%q' \
          "${PROXY_PROTOCOL_ATTR_VAR}" "${SETTING}"
        SETTINGS[${#SETTINGS[@]}]="${ASSIGNMENT}"
      done

      # Update the current proxy protocol-agnostic attribute default value
      # from the default proxy protocol-agnostic attribute default value, so
      # that future defaults upon this proxy configuration are propagated.
      [[ -n "${PROXY_FALLBACK_ATTR}" ]] || \
        PROXY_FALLBACK_ATTR="${DEFAULT_FALLBACK_ATTR}"

      declare "${PROXY_FALLBACK_ATTR_VAR}"="${PROXY_FALLBACK_ATTR}"
      local ASSIGNMENT=''
      printf -v ASSIGNMENT '%s=%q' \
        "${PROXY_FALLBACK_ATTR_VAR}" "${PROXY_FALLBACK_ATTR}"
      SETTINGS[${#SETTINGS[@]}]="${ASSIGNMENT}"
    done
  done

  local ASSIGNMENT=''
  printf -v ASSIGNMENT '%s ' "${PROXIES[@]}"
  printf -v ASSIGNMENT '%s=%q' 'PROXIES_LIST' "${ASSIGNMENT%% }"
  SETTINGS[${#SETTINGS[@]}]="${ASSIGNMENT}"

  printf -v OUTPUT '%s\n' "${SETTINGS[@]}"
  echo -n "${OUTPUT%[[:space:]]}"
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

function proxy-settings()
{
  [[ ${#PROXIES_SETTINGS[@]-} -gt 0 ]] && {
    printf '%s\n' "${PROXIES_SETTINGS[@]}"
  }
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
