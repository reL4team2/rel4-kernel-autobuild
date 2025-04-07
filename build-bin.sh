#!/usr/bin/env bash
set -eux

if [ -d "kit" ]; then
        echo "kit dir exist"
else
        git clone https://github.com/reL4team2/rel4-linux-kit.git kit --config advice.detachedHead=false
fi

cd ./kit

# install rel4 kernel
rel4-cli install kernel --bin -P $(realpath .)/.env/seL4

# rel4-linux-kit test steps
if [ -d ".env/aarch64" ]; then
        echo "the test cases is exist"
else
        mkdir -p .env
        wget -qO- https://github.com/yfblock/rel4-kernel-autobuild/releases/download/release-2025-03-06/aarch64.tgz | tar -xf - -C .env
        mkdir -p testcases
        pip3 install capstone lief
        ./tools/modify-multi.py .env/aarch64 testcases
fi

make run LOG=error
