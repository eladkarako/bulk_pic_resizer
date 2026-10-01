::@echo off
chcp 65001 1>nul 2>nul
set "LANG=en_US.UTF-8"
set "LANGUAGE=en_US"
set "LC_CTYPE=en_US.UTF-8"
set "LC_NUMERIC=en_US.UTF-8"
set "LC_TIME=en_US.UTF-8"
set "LC_COLLATE=en_US.UTF-8"
set "LC_MONETARY=en_US.UTF-8"
set "LC_MESSAGES=en_US.UTF-8"
set "LC_PAPER=en_US.UTF-8"
set "LC_NAME=en_US.UTF-8"
set "LC_ADDRESS=en_US.UTF-8"
set "LC_TELEPHONE=en_US.UTF-8"
set "LC_MEASUREMENT=en_US.UTF-8"
set "LC_IDENTIFICATION=en_US.UTF-8"
set "LC_ALL=en_US.UTF-8"
set "TZ=UTC"

pushd "%~sdp0"

::------------------------------------------- on Windows for Windows
rustup target add   x86_64-pc-windows-msvc   i686-pc-windows-msvc
title x86_64-pc-windows-msvc
cargo build  --release  --target   x86_64-pc-windows-msvc
title i686-pc-windows-msvc
cargo build  --release  --target   i686-pc-windows-msvc

::------------------------------------------- on Windows for Android
rustup target add   x86_64-linux-android   i686-linux-android   aarch64-linux-android   armv7-linux-androideabi
title x86_64-linux-android
cargo build  --release  --target   x86_64-linux-android
title i686-linux-android
cargo build  --release  --target   i686-linux-android
title aarch64-linux-android
cargo build  --release  --target   aarch64-linux-android
title armv7-linux-androideabi
cargo build  --release  --target   armv7-linux-androideabi

timeout /t 5