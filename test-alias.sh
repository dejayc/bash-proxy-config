#! /bin/bash

# bash-proxy-config: Copyright 2018 by Dejay Clayton, all rights reserved.
# Licensed under the 2-Clause BSD License.
#  https://github.com/dejayc/bash-proxy-config
#  http://opensource.org/licenses/BSD-2-Clause

set -eu
shopt -s expand_aliases

echo "Sourcing 'alias.sh'"
source './include/alias.sh'
echo

echo 'Listing proxy environment variables:'
set | grep -i proxy