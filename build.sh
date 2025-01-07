#!/usr/bin/env bash

# 默认支持MCS，如果不需要MCS，可以修改脚本使用传参的形式关闭 -F KERNEL_MCS

export REL4_INSTALL_DIR=$(realpath .)/build/reL4
export REL4_PREFIX=$REL4_INSTALL_DIR
export SEL4_PREFIX=$REL4_INSTALL_DIR
export CC_aarch64_unknown_none=aarch64-linux-gnu-gcc

rustup default nightly-2024-02-01
git clone https://github.com/reL4team2/rel4-integral.git rel4_kernel --config advice.detachedHead=false
git clone https://github.com/reL4team2/seL4_c_impl.git --config advice.detachedHead=false
cd rel4_kernel
cargo update -p home --precise 0.5.5
cargo build --release --target aarch64-unknown-none-softfloat -F KERNEL_MCS
cd ../seL4_c_impl
cmake \
    -DCROSS_COMPILER_PREFIX=aarch64-linux-gnu- \
    -DCMAKE_INSTALL_PREFIX=${REL4_PREFIX} \
    -DKernelIsMCS=ON \
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

cargo install \
    -Z build-std=core,compiler_builtins \
    -Z build-std-features=compiler-builtins-mem \
    --target aarch64-unknown-none \
    $common_args \
    sel4-kernel-loader;
