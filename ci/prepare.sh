#! /bin/sh
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

set -e

TOP_DIR=$(readlink -f $(dirname $0)/../)

rm -rf $TOP_DIR/poky $TOP_DIR/buildkit
mkdir $TOP_DIR/poky $TOP_DIR/buildkit

wget --no-check-certificate -O $TOP_DIR/poky/poky.tar.bz2 "https://downloads.yoctoproject.org/releases/yocto/yocto-2.6/poky-thud-20.0.0.tar.bz2"
wget -O $TOP_DIR/buildkit/buildkit.tar.gz https://github.com/moby/buildkit/releases/download/v0.6.2/buildkit-v0.6.2.linux-amd64.tar.gz
wget -O $TOP_DIR/buildkit/docker-rootless-extras.tgz https://master.dockerproject.org/linux/x86_64/docker-rootless-extras.tgz
sha256sum -c <<HEREDOC
ef3d4305054282938bfe70dc5a08eba8a701a22b49795b1c2d8ed5aed90d0581 *poky/poky.tar.bz2
6168bc2a88cb9ade329a91f8fac3acdc3247f66abbf9bccabd069b9c9ac37dc3 *buildkit/docker-rootless-extras.tgz
1e4988fe2ec90ec63f92f840a0765f5a65bd6548af4a07b597cbc31310222c9e *buildkit/buildkit.tar.gz
HEREDOC

echo "Extracting..."
tar -xf $TOP_DIR/poky/poky.tar.bz2 -C $TOP_DIR/poky --strip-components=1
ln -s ../pyrex-init-build-env $TOP_DIR/poky/
tar -xf $TOP_DIR/buildkit/buildkit.tar.gz -C $TOP_DIR/buildkit
tar -xf $TOP_DIR/buildkit/docker-rootless-extras.tgz -C $TOP_DIR/buildkit/bin --strip-components=1

