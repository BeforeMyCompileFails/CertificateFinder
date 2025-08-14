@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: =========================
:: Certificate Finder
:: Usage: CertificateFinder.bat <SOURCE_DRIVE_LETTER>
:: Example: CertificateFinder.bat G:
:: Run as Administrator.
:: =========================

if "%~1"=="" (
  echo Usage: %~nx0 ^<SOURCE_DRIVE_LETTER^>
  echo Example: %~nx0 G:
  exit /b 1
)

set "SRC=%~1"
if "%SRC:~-1%"==":" set "SRC=%SRC%\"
if not exist "%SRC%" (
  echo [ERROR] Source "%SRC%" not found.
  exit /b 1
)

:: Timestamped output
for /f "tokens=1-3 delims=/. " %%a in ("%date%") do set "TODAY=%%c-%%a-%%b"
for /f "tokens=1-3 delims=:." %%a in ("%time%") do set "NOW=%%a%%b%%c"
set "OUT=Cert_Collection_%TODAY%_%NOW%"
set "FILES_OUT=%OUT%\files"
set "FFX_OUT=%OUT%\firefox_profiles"
set "SYS_OUT=%OUT%\windows_crypto"
set "MISC_OUT=%OUT%\misc"
set "LOG=%OUT%\collection.log"
set "CSV=%OUT%\manifest.csv"

mkdir "%FILES_OUT%" "%FFX_OUT%" "%SYS_OUT%" "%MISC_OUT%" >nul 2>&1

echo Collection started %date% %time% > "%LOG%"
> "%CSV%" echo "sha256","size_bytes","source_path","copied_to"

:: Extensions to hunt
set "EXTS=.pfx .p12 .p7b .p7c .p7m .cer .crt .pem .key .der .jks .keystore .asc"

echo [INFO] Searching for candidate certificate/key files...
for %%X in (%EXTS%) do (
  for /r "%SRC%" %%F in (*%%X) do (
    set "SRCFILE=%%~fF"
    set "RELPATH=!SRCFILE:%SRC%=!"
    set "DEST=%FILES_OUT%\!RELPATH!"
    set "DESTDIR=!DEST!"
    for %%Z in ("!DESTDIR!") do set "DESTDIR=%%~dpZ"
    if not exist "!DESTDIR!" mkdir "!DESTDIR!" >nul 2>&1

    copy /y "!SRCFILE!" "!DEST!" >nul
    if exist "!DEST!" (
      for /f "tokens=1,* delims=:" %%h in ('certutil -hashfile "!DEST!" SHA256 ^| find /i "SHA256"') do set "HASHLINE=%%i"
      for /f "tokens=1" %%k in ('echo !HASHLINE!') do set "SHA=%%k"
      for %%S in ("!SRCFILE!") do set "SIZE=%%~zS"
      >> "%CSV%" echo "!SHA!","!SIZE!","!SRCFILE!","!DEST!"
    )
  )
)

echo [INFO] Collecting Firefox profiles (cert9.db, key4.db, profiles.ini)...
for /d %%U in ("%SRC%\Users\*") do (
  if exist "%%~fU\AppData\Roaming\Mozilla\Firefox" (
    robocopy "%%~fU\AppData\Roaming\Mozilla\Firefox" "%FFX_OUT%\Users\%%~nxU\Firefox" profiles.ini installs.ini /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >nul
    for /d %%P in ("%%~fU\AppData\Roaming\Mozilla\Firefox\Profiles\*") do (
      if exist "%%~fP\cert9.db" (
        if not exist "%FFX_OUT%\Users\%%~nxU\Firefox\Profiles\%%~nxP" mkdir "%FFX_OUT%\Users\%%~nxU\Firefox\Profiles\%%~nxP" >nul 2>&1
        copy /y "%%~fP\cert9.db" "%FFX_OUT%\Users\%%~nxU\Firefox\Profiles\%%~nxP\" >nul
      )
      if exist "%%~fP\key4.db" (
        if not exist "%FFX_OUT%\Users\%%~nxU\Firefox\Profiles\%%~nxP" mkdir "%FFX_OUT%\Users\%%~nxU\Firefox\Profiles\%%~nxP" >nul 2>&1
        copy /y "%%~fP\key4.db" "%FFX_OUT%\Users\%%~nxU\Firefox\Profiles\%%~nxP\" >nul
      )
    )
  )
)

echo [INFO] Collecting Windows Crypto/DPAPI material...
:: Per-user crypto/DPAPI
for /d %%U in ("%SRC%\Users\*") do (
  if exist "%%~fU\AppData\Roaming\Microsoft\SystemCertificates" robocopy "%%~fU\AppData\Roaming\Microsoft\SystemCertificates" "%SYS_OUT%\Users\%%~nxU\SystemCertificates" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >nul
  if exist "%%~fU\AppData\Roaming\Microsoft\Crypto"            robocopy "%%~fU\AppData\Roaming\Microsoft\Crypto" "%SYS_OUT%\Users\%%~nxU\Crypto" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >nul
  if exist "%%~fU\AppData\Roaming\Microsoft\Protect"           robocopy "%%~fU\AppData\Roaming\Microsoft\Protect" "%SYS_OUT%\Users\%%~nxU\Protect" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >nul
)

:: Machine-level keys and registry hives
if exist "%SRC%\ProgramData\Microsoft\Crypto\RSA\MachineKeys" robocopy "%SRC%\ProgramData\Microsoft\Crypto\RSA\MachineKeys" "%SYS_OUT%\MachineKeys" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >nul
if exist "%SRC%\Windows\System32\Microsoft\Protect"           robocopy "%SRC%\Windows\System32\Microsoft\Protect" "%SYS_OUT%\SystemProtect" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >nul
if exist "%SRC%\Windows\System32\config"                      robocopy "%SRC%\Windows\System32\config" "%SYS_OUT%\RegistryHives" SAM SECURITY SOFTWARE SYSTEM DEFAULT /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >nul

echo [OK] Done.
echo Output folder: "%CD%\%OUT%"
echo Manifest:      "%CD%\%CSV%"
echo Log:           "%CD%\%LOG%"

endlocal