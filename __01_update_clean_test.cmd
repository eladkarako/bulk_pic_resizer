::@echo off

::------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
:: updates cargo once (for Cargo.lock)
:: updates local rust components in Windows and WSL.
:: clean and test on Windows for native Windows (x86_64), and WSL for native Linux (x86_64).
:: **** if a test fails the result of cargo test effects the shell's exit code, which will quit before building
:: it builds on Windows for Windows, and on WSL for Android NDK, Linux, embedded and powerpc. (Android recently moved toolchain from Windows to WSL, keeping just windows-msvc on Windows).
::------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


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


::------------------ run once, on Windows for all builds/tests.
cargo update




::  ███████████    ██████████     █████████     ███████████     █████████ 
:: ░█░░░███░░░█   ░░███░░░░░█    ███░░░░░███   ░█░░░███░░░█    ███░░░░░███
:: ░   ░███  ░     ░███  █ ░    ░███    ░░░    ░   ░███  ░    ░███    ░░░ 
::     ░███        ░██████      ░░█████████        ░███       ░░█████████ 
::     ░███        ░███░░█       ░░░░░░░░███       ░███        ░░░░░░░░███
::     ░███        ░███ ░   █    ███    ░███       ░███        ███    ░███
::     █████       ██████████   ░░█████████        █████      ░░█████████ 
::    ░░░░░       ░░░░░░░░░░     ░░░░░░░░░        ░░░░░        ░░░░░░░░░  


title TESTS - on Windows for Windows
::------------------ update toolchains and components (Windows)
rustup update
cargo clean
cargo test --jobs 16 --future-incompat-report --message-format human --verbose --color never --timings --target x86_64-pc-windows-msvc
set "EXIT_CODE=%ErrorLevel%"
if ["%EXIT_CODE%"] neq ["0"] ( goto ERROR_TEST )


title TESTS - on WSL for Linux
set "ARGS="
set "ARGS=%ARGS% set +o pipefail;"
set "ARGS=%ARGS% set +o errexit;"
set "ARGS=%ARGS% set -o xtrace;"
set "ARGS=%ARGS% sleep 5;"
set "ARGS=%ARGS% source ~/.profile;"
set "ARGS=%ARGS% source ~/.bashrc;"
set "ARGS=%ARGS% rustup update;"
set "ARGS=%ARGS% cargo clean;"
set "ARGS=%ARGS% cargo test --jobs 16 --future-incompat-report --message-format human --verbose --color never --timings --target x86_64-unknown-linux-gnu;"
call wsl bash -lc "%ARGS%"
set "EXIT_CODE=%ErrorLevel%"
if ["%EXIT_CODE%"] neq ["0"] ( goto ERROR_TEST )


echo [INFO] success.


goto END


:ERROR_TEST
  echo [INFO] test failed.            1>&2
  goto END


:END
  echo [INFO] EXIT_CODE: %EXIT_CODE%  1>&2
  pause
  exit /b %EXIT_CODE%
