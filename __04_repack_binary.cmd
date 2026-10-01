::@echo off
chcp 65001 1>nul 2>nul
pushd "%~dp0"

set "BINARY="
for %%I in ("%CD%") do ( 
  set "BINARY=%%~nxI"
  goto EXIT_LOOP_BINARY
) 
:EXIT_LOOP_BINARY


pushd "%CD%\target"


goto MAIN


::------------------------------------------------
:METHOD
  setlocal
  set "TARGET_NAME=%~1"
  set "FULL_PATH=%CD%\%TARGET_NAME%\release\%BINARY%"

  if exist "%FULL_PATH%.exe" (
    set "FULL_PATH=%FULL_PATH%.exe"
  )

  title %TARGET_NAME%
  start "" /MAX /ABOVENORMAL "7z.exe" a -tzip -y -ssp -sse -ssw -mmt4 -mx9 -mm=Deflate -mem=ZipCrypto -w"%CD%" -x!"%TARGET_NAME%.zip" "%TARGET_NAME%.zip" "%FULL_PATH%"
  endlocal
  goto :eof
::------------------------------------------------



:MAIN
for %%x in ( 
aarch64-linux-android
aarch64-unknown-linux-gnu
aarch64-unknown-linux-musl
armv7-linux-androideabi
i686-linux-android
i686-pc-windows-msvc
powerpc64-unknown-linux-gnu
powerpc64le-unknown-linux-gnu
powerpc-unknown-linux-gnu
x86_64-linux-android
x86_64-pc-windows-msvc
x86_64-unknown-linux-gnu
x86_64-unknown-linux-musl
) do ( 
  call :METHOD "%%x"
)


::-------------------------------------------------------------------------------------
:: zip packing just the binary file, of each release.
:: - zip files, named by the target's name, under '/target/'
:: - multi-process (parallel run). 4 threads, max compression. compatible zip.
:: - assumes project-name is same as binary name (often is).
:: - assumes '7z.exe' folder is in system's PATH.
::-------------------------------------------------------------------------------------
