#! /bin/bash
#
# Copyright 2019 Garmin Ltd. or its subsidiaries
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

INIT_PWD=$PWD

# Prevent some variables from being unset so their value can be captured
unset() {
    for var in "$@"; do
        case "$var" in
            BITBAKEDIR) ;;
            OEROOT) ;;
            *)
                builtin unset "$var"
                ;;
        esac
    done
}

# Consume all arguments before sourcing the environment script
shift $#

. $PYREX_OEINIT
if [ $? -ne 0 ]; then
    exit 1
fi

if [ -z "$BITBAKEDIR" ]; then
    echo "\$BITBAKEDIR not captured!"
    exit 1
fi

if [ -z "$OEROOT" ]; then
    echo "\$OEROOT not captured!"
    exit 1
fi

cat > $PYREX_CAPTURE_DEST <<HEREDOC
{
    "tempdir": "$PWD/pyrex",
    "user" : {
        "cwd": "$PWD"
    },
    "container": {
        "shell": "/bin/bash",
        "commands": {
            "include": [
                "$BITBAKEDIR/bin/*",
                "$OEROOT/scripts/*"
            ],
            "exclude": [
                "$OEROOT/scripts/runqemu*"
            ]
        }
    },
    "run": {
        "env" : {
            "BBPATH": "$BBPATH",
            "PATH": "$PATH",
            "BUILDDIR": "$BUILDDIR"
        },
        "bind": [
            "$BITBAKEDIR",
            "$OEROOT"
        ]
    },
    "bypass": {
        "env": {
            "PYREX_OEINIT": "$PYREX_OEINIT",
            "PYREX_OEINIT_DIR": "$INIT_PWD"
        }
    }
}
HEREDOC

