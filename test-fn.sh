#! /bin/bash

# bash-proxy-config: Copyright 2018 by Dejay Clayton, all rights reserved.
# Licensed under the 2-Clause BSD License.
#  https://github.com/dejayc/bash-proxy-config
#  http://opensource.org/licenses/BSD-2-Clause

set -eu

echo "Sourcing 'fn.sh'"
BASH_PROXY_CONFIG="${1-}" source './include/fn.sh'
echo

echo 'Requesting proxy environment variables:'
proxy proxy-show
echo

echo 'Requesting proxy configuration variables:'
proxy proxy-settings
echo

echo 'Listing proxy environment variables:'
set | grep -i proxy
