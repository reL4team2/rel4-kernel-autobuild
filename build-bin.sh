#!/usr/bin/env bash
set -eux
export REL4_INSTALL_DIR=$(realpath .)/kit/.env/seL4
export REL4_PREFIX=$REL4_INSTALL_DIR
export SEL4_PREFIX=$REL4_INSTALL_DIR
export CC_aarch64_unknown_none=aarch64-linux-gnu-gcc

rustup default nightly-2024-02-01
if [ -d "rel4_kernel" ]; then
        echo "rel4_kernel dir exist"
else
        git clone https://github.com/reL4team2/rel4-integral.git rel4_kernel --config advice.detachedHead=false
fi
if [ -d "kernel" ]; then
        echo "kernel dir exist"
else
        git clone https://github.com/reL4team2/seL4_c_impl.git kernel --config advice.detachedHead=false
fi
if [ -d "kit" ]; then
        echo "kit dir exist"
else
        git clone https://github.com/reL4team2/rel4-linux-kit.git kit --config advice.detachedHead=false
fi
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

url="https://github.com/reL4team2/rust-sel4.git";
rev="642b58d807c5e5fc22f0c15d1467d6bec328faa9";
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
if [ -f "aarch64-linux-musl-cross.tgz" ]; then
        echo "the musl cross complier is exist"
else
        wget https://musl.cc/aarch64-linux-musl-cross.tgz
        tar zxf aarch64-linux-musl-cross.tgz
fi
export PATH=$PATH:`pwd`/aarch64-linux-musl-cross/bin
make test-examples

make run

cd ../rel4_kernel && cargo clean
