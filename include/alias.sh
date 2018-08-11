#! /bin/bash

# bash-proxy-config: Copyright 2018 by Dejay Clayton, all rights reserved.
# Licensed under the 2-Clause BSD License.
#  https://github.com/dejayc/bash-proxy-config
#  http://opensource.org/licenses/BSD-2-Clause

alias proxy="$( printf \
  "p(){ source '%s' && proxy-call %s; unset -f p; }; p" \
  "${BASH_SOURCE[0]%/*}/proxy.sh" '"${@:+${@}}"' )"
