#!/usr/bin/env bash

export REL4_INSTALL_DIR=$(realpath .)/kit/.env/seL4
export REL4_PREFIX=$REL4_INSTALL_DIR
export SEL4_PREFIX=$REL4_INSTALL_DIR
export CC_aarch64_unknown_none=aarch64-linux-gnu-gcc

rustup default nightly-2024-02-01
git clone https://github.com/reL4team2/rel4-integral.git rel4_kernel --config advice.detachedHead=false
git clone https://github.com/reL4team2/seL4_c_impl.git kernel --config advice.detachedHead=false
git clone https://github.com/reL4team2/rel4-linux-kit.git kit --config advice.detachedHead=false
cd rel4_kernel/kernel
cargo update -p home --precise 0.5.5
cargo build --release --target aarch64-unknown-none-softfloat -F ENABLE_SMC --bin rel4_kernel -F BUILD_BINARY
cd ../../kernel
cmake \
    -DCROSS_COMPILER_PREFIX=aarch64-linux-gnu- \
    -DCMAKE_INSTALL_PREFIX=${REL4_PREFIX} \
    -DKernelAllowSMCCalls=ON \
    -DREL4_KERNEL=TRUE \
    -C ./kernel-settings-aarch64.cmake \
    -G Ninja \
    -S . \
    -B build

ninja -C build all
ninja -C build install

rustup default nightly-2024-08-01

url="https://github.com/seL4/rust-sel4";
rev="1cd063a0f69b2d2045bfa224a36c9341619f0e9b";
common_args="--git $url --rev $rev --root $REL4_INSTALL_DIR";

cargo install $common_args \
    sel4-kernel-loader-add-payload

rustup toolchain install nightly-2024-08-01
rustup component add rust-src --toolchain nightly-2024-08-01
rustup default nightly-2024-08-01

cargo install \
    -Z build-std=core,compiler_builtins \
    -Z build-std-features=compiler-builtins-mem \
    --target aarch64-unknown-none \
    $common_args \
    sel4-kernel-loader;

cd ../kit
pip install capstone
pip install lief
dd if=/dev/zero of=mount.img bs=4M count=32
mkfs.ext4 -b 4096 mount.img
wget https://musl.cc/aarch64-linux-musl-cross.tgz
tar zxf aarch64-linux-musl-cross.tgz
export PATH=$PATH:`pwd`/aarch64-linux-musl-cross/bin
make test-examples
