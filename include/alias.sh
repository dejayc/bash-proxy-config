#! /bin/bash

# bash-proxy-config: Copyright 2018 by Dejay Clayton, all rights reserved.
# Licensed under the 2-Clause BSD License.
#  https://github.com/dejayc/bash-proxy-config
#  http://opensource.org/licenses/BSD-2-Clause

# Prior to calling this script, set BASH_PROXY_CONFIG to a file appropriate for
# your system, if the default file is not sufficient.
[[ -n "${BASH_PROXY_CONFIG-}" ]] || \
  declare BASH_PROXY_CONFIG="${HOME}/.bash-proxy-config/config.sh"

alias proxy="$( printf \
  "p(){ source '%s' && proxy-call -u -f '%s' %s; unset -f p; }; p" \
  "${BASH_SOURCE[0]%/*}/proxy.sh" "${BASH_PROXY_CONFIG}" '"${@:+${@}}"' )"

unset BASH_PROXY_CONFIG
