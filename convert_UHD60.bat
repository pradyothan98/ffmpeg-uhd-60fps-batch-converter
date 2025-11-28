@echo off
setlocal EnableDelayedExpansion

REM ========================================================
REM 4K UHD + 60 FPS CONVERTER (GPU NVENC, HIGH QUALITY)
REM Prompts for input folder and output folder
REM ========================================================

REM Check ffmpeg
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] ffmpeg not found in PATH.
    echo Install ffmpeg or place ffmpeg.exe in the same folder as this .bat
    pause
    exit /b
)

echo.
echo Enter FULL PATH of the INPUT folder containing videos:
echo (You can paste with or without quotes, e.g. G:\My Folder\Videos)
set /p "SRC=Input Folder: "

REM Remove any quotes from SRC
set "SRC=%SRC:"=%"

if not exist "%SRC%" (
    echo.
    echo [ERROR] Folder does not exist:
    echo "%SRC%"
    pause
    exit /b
)

echo.
echo Enter FULL PATH of the OUTPUT folder for converted videos:
echo (You can paste with or without quotes, e.g. G:\New folder)
set /p "OUT=Output Folder: "

REM Remove any quotes from OUT
set "OUT=%OUT:"=%"

if not exist "%OUT%" (
    echo Output folder does not exist — creating it...
    mkdir "%OUT%"
)

echo.
echo ============ FOLDERS SELECTED ============
echo Input  : "%SRC%"
echo Output : "%OUT%"
echo ==========================================
echo.

echo Starting conversion...
echo.

for %%F in ("%SRC%\*.mp4" "%SRC%\*.mkv" "%SRC%\*.avi" "%SRC%\*.mov") do (
    if exist "%%F" (
        echo -----------------------------------------
        echo Processing: %%~nxF
        echo -----------------------------------------

        set "OUTFILE=%OUT%\%%~nF_UHD60.mp4"

        ffmpeg -y -hwaccel cuda -i "%%F" ^
            -vf "scale=3840:2160,minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1" ^
            -c:v hevc_nvenc -preset p5 -tune hq -rc vbr -b:v 25000000 -maxrate 45000000 -bufsize 90000000 ^
            -c:a copy "!OUTFILE!"

        echo Done → "!OUTFILE!"
        echo.
    )
)

echo.
echo All videos processed.
pause
endlocal
