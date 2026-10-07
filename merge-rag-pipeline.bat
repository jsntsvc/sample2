@echo off
setlocal EnableDelayedExpansion
REM ============================================================================
REM OmniAI - merge rag-pipeline image parts into one tar.gz
REM
REM   The rag-pipeline image is about 3.8 GB, so it is split into 45 MiB parts
REM   and spread over sample2, sample3 and sample4. This joins them back.
REM
REM   Run this from the sample2 folder. sample3 and sample4 must sit next to it.
REM
REM usage:
REM   merge-rag-pipeline.bat                 output to the parent folder
REM   merge-rag-pipeline.bat D:\tmp          output to the given folder
REM
REM requires:
REM   - sample2, sample3, sample4 all present, with their images subfolders
REM   - free disk space for the merged file (about 4 GB)
REM
REM after this:
REM   docker load -i rag-pipeline.tar.gz
REM ============================================================================

set "NAME=rag-pipeline.tar.gz"
set "HERE=%~dp0"
set "BASE=%HERE%.."
if not "%~1"=="" (set "OUTDIR=%~1") else (set "OUTDIR=%BASE%")
REM Normalise the path so the messages do not show a trailing "\..".
for %%I in ("%OUTDIR%") do set "OUTDIR=%%~fI"
set "OUT=%OUTDIR%\%NAME%"

echo.
echo ============================================================
echo   OmniAI - merge %NAME%
echo   parts from : sample2 sample3 sample4
echo   output     : %OUT%
echo ============================================================
echo.

pushd "%BASE%" || (echo [ERROR] cannot enter %BASE% & exit /b 1)

REM --- 1) check the three folders and count the parts --------------------------
set /a TOTAL=0
for %%D in (sample2 sample3 sample4) do (
    if not exist "%%D\images\" (
        echo [ERROR] folder not found: %%D\images
        echo         All three of sample2, sample3 and sample4 are needed.
        popd
        exit /b 1
    )
    set /a N=0
    for /f %%F in ('dir /b /on "%%D\images\%NAME%.part-*" 2^>nul') do set /a N+=1
    if !N!==0 (
        echo [ERROR] no parts in %%D\images
        popd
        exit /b 1
    )
    echo         %%D : !N! parts
    set /a TOTAL+=!N!
)
echo         total : %TOTAL% parts
echo.

REM --- 2) build the ordered list ----------------------------------------------
REM copy /b joins in the order given, so the order here is what matters.
REM Names are zero padded (part-000 .. part-081), so /on sorts them correctly.
set "LIST="
for %%D in (sample2 sample3 sample4) do (
    for /f %%F in ('dir /b /on "%%D\images\%NAME%.part-*"') do (
        if defined LIST (set "LIST=!LIST!+"%%D\images\%%F"") else (set "LIST="%%D\images\%%F"")
    )
)
if not defined LIST (
    echo [ERROR] no parts found
    popd
    exit /b 1
)

REM --- 3) merge ---------------------------------------------------------------
if exist "%OUT%" (
    echo [INFO] removing the previous %NAME%
    del /f /q "%OUT%"
)
echo [MERGE] joining %TOTAL% parts. This takes a few minutes.
copy /b %LIST% "%OUT%" >nul
if errorlevel 1 (
    echo [ERROR] merge failed
    popd
    exit /b 1
)
for %%S in ("%OUT%") do echo         done: %%~zS bytes
echo.

REM --- 4) verify against the checksum shipped in sample ----------------------
set "SUMS=sample\SHA256SUMS.txt"
if not exist "%SUMS%" (
    echo [SKIP] %SUMS% not found, cannot verify.
    echo        The merged file is at %OUT%
    popd
    exit /b 0
)

set "WANT="
for /f "tokens=1,2" %%A in ('type "%SUMS%"') do (
    set "F=%%B"
    set "F=!F:*%NAME%=!"
    if "!F!"=="" set "WANT=%%A"
)
if not defined WANT (
    echo [SKIP] no %NAME% line in %SUMS%, cannot verify.
    popd
    exit /b 0
)

echo [VERIFY] computing SHA256. This also takes a few minutes.
set "GOT="
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "%OUT%" SHA256') do (
    if not defined GOT set "GOT=%%H"
)
set "GOT=%GOT: =%"

echo          expected %WANT%
echo          actual   %GOT%
if /i "%GOT%"=="%WANT%" (
    echo.
    echo [OK] merge verified.
    echo      next: docker load -i "%OUT%"
    popd
    exit /b 0
)

echo.
echo [ERROR] checksum does not match.
echo         A part is missing, truncated, or was copied in text mode.
echo         Check each folder with: cd ^<folder^>\images ^&^& certutil -hashfile ^<part^> SHA256
echo         and compare against SHA256SUMS.txt in that folder.
popd
exit /b 1
