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
  :
}

function proxy-cat()
{
  IFS='' read -r -d '' OUTPUT ||:
  echo "${OUTPUT}"
}

function proxy-get-settings()
{
  :
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
