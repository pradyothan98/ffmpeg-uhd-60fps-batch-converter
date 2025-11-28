@echo off
setlocal EnableDelayedExpansion

REM ================================================================
REM  4K UHD + 60 FPS VIDEO CONVERTER (FFmpeg + NVIDIA NVENC, Windows)
REM ================================================================
REM  WHAT THIS SCRIPT DOES:
REM  ----------------------
REM  - Prompts the user for:
REM        1) Input folder containing source videos
REM        2) Output folder where converted videos will be saved
REM  - Processes all videos with extensions:
REM        .mp4, .mkv, .avi, .mov
REM  - For each video:
REM        * Uses FFmpeg to:
REM            - Decode using GPU where possible (-hwaccel cuda)
REM            - Upscale to 4K UHD (3840x2160) using scale filter
REM            - Interpolate frames to 60 FPS using minterpolate
REM            - Encode with NVIDIA HEVC (hevc_nvenc) encoder
REM            - Use quality-focused VBR bitrate settings
REM            - Copy audio as-is (no re-encode)
REM
REM  REQUIREMENTS:
REM  -------------
REM  - Windows
REM  - FFmpeg installed and either:
REM        * Added to PATH, OR
REM        * ffmpeg.exe placed in the same folder as this .bat
REM  - NVIDIA GPU with NVENC support
REM  - FFmpeg build that includes:
REM        * hevc_nvenc encoder
REM        * minterpolate filter
REM
REM  HOW TO USE:
REM  -----------
REM  - Double-click this .bat file.
REM  - When prompted:
REM      * Paste your input folder path (with or without quotes).
REM      * Paste your output folder path (with or without quotes).
REM  - The script will:
REM      * Clean the quotes from the paths.
REM      * Create the output folder if it does not exist.
REM      * Convert all compatible videos it finds.
REM ================================================================


REM ------------------------------------------------
REM STEP 1: VERIFY THAT FFMPEG IS AVAILABLE
REM ------------------------------------------------
REM 'where ffmpeg' checks if ffmpeg.exe is accessible via PATH.
REM If ffmpeg is not found, errorlevel will be 1 or greater.
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] FFmpeg was not found.
    echo.
    echo This script requires ffmpeg.exe to run.
    echo
    echo OPTIONS:
    echo   1) Install FFmpeg and add it to your PATH, OR
    echo   2) Place ffmpeg.exe in the same directory as this .bat file.
    echo.
    pause
    exit /b
)


REM ------------------------------------------------
REM STEP 2: ASK USER FOR INPUT FOLDER (SOURCE VIDEOS)
REM ------------------------------------------------
echo.
echo ===================================================
echo Enter FULL PATH of the INPUT folder containing videos
echo (You can paste with or without quotes, e.g.)
echo   G:\My Videos\TV Shows
echo or
echo   "G:\My Videos\TV Shows"
echo ===================================================
set /p "SRC=Input Folder: "

REM Remove any double quotes from the input folder path.
REM Example:
REM   "G:\My Videos\TV Shows"  -->  G:\My Videos\TV Shows
set "SRC=%SRC:"=%"

REM Validate that the input folder actually exists.
if not exist "%SRC%" (
    echo.
    echo [ERROR] The input folder does not exist:
    echo   %SRC%
    echo Please check the path and try again.
    echo.
    pause
    exit /b
)


REM ------------------------------------------------
REM STEP 3: ASK USER FOR OUTPUT FOLDER (DESTINATION)
REM ------------------------------------------------
echo.
echo ===================================================
echo Enter FULL PATH of the OUTPUT folder for converted videos
echo (You can paste with or without quotes, e.g.)
echo   G:\New folder
echo or
echo   "G:\New folder"
echo ===================================================
set /p "OUT=Output Folder: "

REM Remove any double quotes from the output folder path.
set "OUT=%OUT:"=%"

REM If the output folder does not exist, create it.
if not exist "%OUT%" (
    echo.
    echo Output folder does not exist. Creating:
    echo   %OUT%
    mkdir "%OUT%"
)


REM ------------------------------------------------
REM STEP 4: DISPLAY SUMMARY OF SELECTED FOLDERS
REM ------------------------------------------------
echo.
echo ================== CONFIGURATION ==================
echo Input  folder : "%SRC%"
echo Output folder : "%OUT%"
echo ==================================================
echo.

echo Starting batch conversion...
echo.


REM ------------------------------------------------
REM STEP 5: PROCESS VIDEO FILES IN THE INPUT FOLDER
REM ------------------------------------------------
REM The FOR loop below will iterate over all files in %SRC%
REM that match these patterns:
REM   *.mp4   *.mkv   *.avi   *.mov
REM
REM For each matching file:
REM   - %%F will hold the full path to the file.
REM   - %%~nxF is the filename with extension.
REM   - %%~nF  is the filename without extension.
REM
REM NOTES:
REM - The outer quotes around "%SRC%\*.ext" ensure correct
REM   behavior even when the path contains spaces.
REM - The 'if exist "%%F"' check ensures we skip patterns
REM   that match nothing (avoids spurious error messages).
for %%F in ("%SRC%\*.mp4" "%SRC%\*.mkv" "%SRC%\*.avi" "%SRC%\*.mov") do (
    if exist "%%F" (
        echo ----------------------------------------------------------
        echo Processing file:
        echo   %%~nxF
        echo ----------------------------------------------------------

        REM Build the output file path.
        REM   - %OUT% is the chosen output folder.
        REM   - %%~nF is the original filename (without extension).
        REM   - We append _UHD60 to indicate upscaled 4K 60FPS.
        REM   - Output is always .mp4 container.
        set "OUTFILE=%OUT%\%%~nF_UHD60.mp4"

        REM ------------------------------------------------------
        REM STEP 6: CALL FFMPEG FOR THIS FILE
        REM ------------------------------------------------------
        REM FLAGS EXPLAINED:
        REM  -y
        REM       Overwrite output file without asking.
        REM
        REM  -hwaccel cuda
        REM       Use NVIDIA CUDA hardware acceleration for decoding
        REM       when possible. This can speed up processing and
        REM       reduce CPU load.
        REM
        REM  -i "%%F"
        REM       The input file (current video in the loop).
        REM
        REM  -vf "scale=3840:2160,minterpolate=..."
        REM       'scale=3840:2160'
        REM           Upscales or resizes the video to 4K UHD resolution.
        REM           Width:  3840 px
        REM           Height: 2160 px
        REM
        REM       'minterpolate=fps=60:...'
        REM           Uses motion interpolation to generate new frames
        REM           and reach 60 frames per second. This can make
        REM           motion appear smoother compared to simple frame
        REM           duplication.
        REM
        REM           Parameters:
        REM             fps=60
        REM                 Target frame rate: 60 FPS.
        REM             mi_mode=mci
        REM                 Motion interpolation mode.
        REM             mc_mode=aobmc
        REM                 Motion compensation mode.
        REM             me_mode=bidir
        REM                 Motion estimation uses bidirectional prediction.
        REM             vsbmc=1
        REM                 Enables variable-size block motion compensation.
        REM
        REM  -c:v hevc_nvenc
        REM       Use NVIDIA's HEVC (H.265) hardware encoder (NVENC).
        REM       This uses the GPU to encode video much faster than
        REM       software encoding in many cases.
        REM
        REM  -preset p5
        REM       NVENC preset controlling speed vs quality.
        REM       Higher numbers usually mean better quality and slower
        REM       encoding. (Exact meanings can vary by FFmpeg/driver.)
        REM       p5 is a quality-focused preset.
        REM
        REM  -tune hq
        REM       High-quality tune, telling the encoder to prefer
        REM       higher quality at the cost of additional GPU usage.
        REM
        REM  -rc vbr
        REM       Use Variable Bit Rate rate control.
        REM       Bitrate can fluctuate based on content complexity.
        REM
        REM  -b:v 25000000
        REM       Target average video bitrate: 25,000,000 bits/second
        REM       (about 25 Mbps). Increase this if you want even higher
        REM       quality and larger files.
        REM
        REM  -maxrate 45000000
        REM       Maximum instantaneous bitrate: 45 Mbps.
        REM       This acts as a ceiling during complex scenes.
        REM
        REM  -bufsize 90000000
        REM       Rate control buffer size. Typically set to about
        REM       2x the maxrate or more. Helps smooth bitrate spikes.
        REM
        REM  -c:a copy
        REM       Copy the audio stream from the input without re-encoding.
        REM       This preserves original audio quality and is faster.
        REM
        REM  "!OUTFILE!"
        REM       Final output file path for this conversion.
        REM ------------------------------------------------------
        ffmpeg -y -hwaccel cuda -i "%%F" ^
            -vf "scale=3840:2160,minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1" ^
            -c:v hevc_nvenc -preset p5 -tune hq -rc vbr -b:v 25000000 -maxrate 45000000 -bufsize 90000000 ^
            -c:a copy "!OUTFILE!"

        REM After FFmpeg finishes for this file, we print a message.
        echo.
        echo Finished file:
        echo   "!OUTFILE!"
        echo.
    )
)


REM ------------------------------------------------
REM STEP 7: DONE
REM ------------------------------------------------
echo.
echo =====================================================
echo All possible video files have been processed.
echo Check the output folder for your 4K 60FPS files:
echo   "%OUT%"
echo =====================================================
echo.
pause
endlocal
