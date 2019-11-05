#! /usr/bin/env python3
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
#
#
# A shim helper for podman that implements a poor man's BuildKit. Creates a new
# temporary Dockerfile with all unnecessary build targets removed to speed up
# build times

import argparse
import os
import re
import string
import subprocess
import sys
import tempfile
import time

PYREX_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

def forward():
    os.execvp('podman', ['podman'] + sys.argv[1:])
    sys.exit(1)

def call_buildkit(args):
    rootlesskit = os.environ.get('ROOTLESSKIT', os.path.join(PYREX_ROOT, 'buildkit', 'bin', 'rootlesskit'))
    buildkitd = os.environ.get('BUILDKITD', os.path.join(PYREX_ROOT, 'buildkit', 'bin', 'buildkitd'))
    buildctl = os.environ.get('BUILDCTL', os.path.join(PYREX_ROOT, 'buildkit', 'bin', 'buildctl'))
    podman = os.environ.get('PODMAN', 'podman')
    buildkit_cache = os.environ.get('BUILDKIT_CACHE', os.path.join(PYREX_ROOT, 'buildkit', 'cache'))



    with tempfile.TemporaryDirectory(prefix='pyrex-buildkit-') as tempdir:

        image_tar = os.path.join(tempdir, 'image.tar')
        addr = '--addr=unix://%s/buildkitd.sock' % tempdir

        p = subprocess.Popen([rootlesskit, buildkitd, addr])
        try:
            print("Daemon spawned with pid %d" % p.pid)

            tries = 0
            while True:
                if subprocess.run([buildctl, addr, 'debug', 'workers'], stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT).returncode == 0:
                    break

                if tries < 1000:
                    tries += 1
                    time.sleep(.01)
                else:
                    print("Could not connect to daemon after %d tries" % tries)
                    return 1

            buildkit_args = [
                buildctl,
                addr,
                'build',
                '--frontend', 'dockerfile.v0',
                '--local', 'dockerfile=%s' % (os.path.dirname(args.file) if args.file else '.'),
                '--local', 'context=%s' % args.path,
                '--output', 'type=oci,dest=%s' % image_tar,
                ]

            if args.target:
                buildkit_args.extend(['--opt', 'target=%s' % args.target])

            for a in args.build_arg:
                buildkit_args.extend(['--opt', 'build-arg:%s' % a])

            print(' '.join(buildkit_args))

            subprocess.check_call(buildkit_args)

            podman_args = [
                podman,
                'load',
                '-i', image_tar,
                ]

            if args.tag:
                podman_args.append(args.tag)

            subprocess.check_call(podman_args)
            #buildctl_p = subprocess.Popen(buildkit_args, stdout=subprocess.PIPE)
            #podman_p = subprocess.Popen(podman_args, stdin=buildctl_p.stdout)

            #buildctl_p.wait()
            #podman_p.wait()

        finally:
            p.kill()
            p.wait()

    return 0

def main():
    if len(sys.argv) < 2 or sys.argv[1] != 'build':
        forward()

    parser = argparse.ArgumentParser(description='Container build helper')
    parser.add_argument('--build-arg', action='append', default=[],
                        help='name and value of a buildarg')
    parser.add_argument('--file', '-f', default='Dockerfile',
                        help='Docker file')
    parser.add_argument('--target', help='set target build stage to build')
    parser.add_argument('--network', help='Set the networking mode for the RUN instructions during build', choices=('bridge', 'host', 'overlay', 'none'))
    parser.add_argument('--tag', '-t', help='Name and optionally tag in the `name:tag` format')
    parser.add_argument('path', help='Context path')

    args = parser.parse_args(sys.argv[2:])

    return call_buildkit(args)

if __name__ == "__main__":
    sys.exit(main())
