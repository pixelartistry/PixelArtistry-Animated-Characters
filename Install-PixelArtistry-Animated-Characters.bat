@echo off
setlocal EnableExtensions DisableDelayedExpansion
title PixelArtistry - Animated Characters installer (workflows 05 + 05p)
cd /d "%~dp0"

rem ===================================================================
rem  PixelArtistry - Animated Characters installer for ComfyUI
rem  https://github.com/pixelartistry/PixelArtistry-Animated-Characters
rem
rem  Installs everything the workflows
rem    PixelArtistry_05_Image_to_LowPoly_Character_UltraTex  (character)
rem    PixelArtistry_05p_Image_to_LowPoly_Prop_UltraTex       (props)
rem  need: MostAadTech's 3D nodes + the Pixal3D / TRELLIS.2 models (through
rem  the PixelArtistry Watertight-Meshes installer), MostAadTech's low-VRAM
rem  UltraTex nodes + their GGUF models, Blender, and the workflows.
rem
rem  Works with ComfyUI-Easy-Install and ComfyUI Portable (python_embeded).
rem  Put this folder into ComfyUI-Easy-Install\Add-Ons\ (or next to
rem  "python_embeded"), close ComfyUI, and double-click this file.
rem  Safe to run again: existing files are kept, downloads resume.
rem
rem  No Hugging Face token needed: the GGUF models are not gated.
rem  FLUX.2 Klein base is under the FLUX Non-Commercial License; your
rem  outputs are yours, but check bfl.ai/licensing before commercial use.
rem ===================================================================

rem -------- Pinned versions: the exact commits of the tested run (15 Oct 2026) --------
set "PIN_DATE=2026-10-15"
set "UTX_REPO=https://github.com/Mstafa-awad/UltraTex-ComfyUI-nodes"
set "UTX_SHA=b98f4f45057a5a40561ffbb0770ef3a4e0400112"
set "GGUF_REPO=https://github.com/city96/ComfyUI-GGUF"
set "GGUF_SHA=4dfc025e4be06ba9c210bd1189546f7af67f445d"
set "WT_URL=https://raw.githubusercontent.com/pixelartistry/PixelArtistry-Watertight-Meshes/main/watertightMeshes_win_installer.bat"
rem  To try the newest versions instead: open cmd, run  set PA_LATEST=1  and start this file there.

set "HERE=%~dp0"
set "ROOT="
if exist "%HERE%python_embeded\python.exe" set "ROOT=%HERE%"
if not defined ROOT if exist "%HERE%..\python_embeded\python.exe" for %%I in ("%HERE%..") do set "ROOT=%%~fI\"
if not defined ROOT if exist "%HERE%..\..\python_embeded\python.exe" for %%I in ("%HERE%..\..") do set "ROOT=%%~fI\"
if not defined ROOT goto :no_python
set "PY=%ROOT%python_embeded\python.exe"
set "COMFY=%ROOT%ComfyUI"
set "NODES=%COMFY%\custom_nodes"
set "HELPER=%HERE%pa_helper.py"
set "WFDST=%COMFY%\user\default\workflows\PixelArtistry"
set "FAILS=0"
set "WARNS=0"
set "BLOCKERS=0"

echo.
echo  ============================================================
echo    PixelArtistry - Animated Characters installer (workflows 05 + 05p)
echo  ============================================================
echo    ComfyUI: %COMFY%
echo.

rem ------------------------------------------------------------------ 1
echo [1/7] Checking ComfyUI, Python and tools
if not exist "%HELPER%" goto :no_helper
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-Process python -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq [IO.Path]::GetFullPath($env:PY) }) { exit 3 }" >nul 2>&1
if "%errorlevel%"=="3" goto :comfy_running
"%PY%" -I "%HELPER%" version "%COMFY%"
if errorlevel 1 (
    echo     [WARN] ComfyUI is older than the tested version - run "Update ComfyUI.bat" first
    set /a WARNS+=1
)
"%PY%" -I -c "import torch,sys; print('    Python', sys.version.split()[0], '/ torch', torch.__version__, '/ CUDA', torch.version.cuda)"
"%PY%" -I -c "import sys,torch; v=torch.__version__.split('+')[0]; c=torch.version.cuda or ''; sys.exit(0 if sys.version_info[:2]==(3,12) and v.startswith('2.8.') and c.startswith('12.') else 1)"
if errorlevel 1 (
    echo.
    echo     [WARN] This Python/torch/CUDA combination is not the tested one.
    echo            The WTiVo watertight node is prebuilt for Python 3.12 + torch 2.8 + CUDA 12.x
    echo            and will not load here. The compatibility check after step 4 shows details.
    echo            Easy-Install and ComfyUI Portable ship this combination.
    set /a WARNS+=1
    choice /c YN /n /m "           Continue anyway? [Y/N] "
    if errorlevel 2 exit /b 1
)
set "HAVE_GIT="
git --version >nul 2>&1
if not errorlevel 1 set "HAVE_GIT=1"
where tar >nul 2>&1
if errorlevel 1 if not defined HAVE_GIT goto :no_tools

rem ------------------------------------------------------------------ 2
echo.
echo [2/7] MostAadTech 3D nodes + Pixal3D / TRELLIS.2 models
echo     Running the PixelArtistry Watertight-Meshes installer. It asks before
echo     downloading models; press a key when it shows its summary.
set "WT_BAT=%TEMP%\pa_watertightMeshes_win_installer.bat"
curl -L --fail -s -o "%WT_BAT%" "%WT_URL%"
if errorlevel 1 (
    echo     [FAIL] Could not download the Watertight-Meshes installer
    set /a FAILS+=1
    goto :ultratex
)
rem  The Watertight installer finds ComfyUI from its own folder, so run a copy next to python_embeded.
copy /y "%WT_BAT%" "%ROOT%pa_watertight_tmp.bat" >nul
call cmd /c ""%ROOT%pa_watertight_tmp.bat""
del "%ROOT%pa_watertight_tmp.bat" >nul 2>&1

:ultratex
rem ------------------------------------------------------------------ 3
echo.
echo [3/7] UltraTex low-VRAM nodes (MostAadTech) + ComfyUI-GGUF
if exist "%NODES%\UltraTex-ComfyUI-nodes\" (
    echo     [WARN] Found a second copy "UltraTex-ComfyUI-nodes" - remove it, two copies conflict
    set /a WARNS+=1
)
call :node "%NODES%\comfyui_ultratex_modular" "%UTX_REPO%" "%UTX_SHA%" "UltraTex modular by MostAadTech"
call :node "%NODES%\ComfyUI-GGUF" "%GGUF_REPO%" "%GGUF_SHA%" "ComfyUI-GGUF by city96"

rem ------------------------------------------------------------------ 4
echo.
echo [4/7] Python packages
"%PY%" -I -m pip install --quiet --disable-pip-version-check --no-warn-script-location -r "%NODES%\comfyui_ultratex_modular\requirements.txt" "gguf>=0.13"
if errorlevel 1 (echo     [FAIL] pip install failed & set /a FAILS+=1) else (echo     [OK]      UltraTex + GGUF packages)
"%PY%" -I -c "import triton" >nul 2>&1
if errorlevel 1 (
    echo     [WARN] Triton missing - UltraTex low-VRAM needs it. Easy-Install includes it; see the UltraTex README
    set /a WARNS+=1
) else (echo     [OK]      Triton)

echo.
echo     Compatibility check (loads every compiled part in this Python):
"%PY%" -I "%HELPER%" compat "%COMFY%"
set "BLOCKERS=%errorlevel%"

rem ------------------------------------------------------------------ 5
echo.
echo [5/7] UltraTex models (GGUF route, no token needed)
"%PY%" -I "%HELPER%" models "%COMFY%"
if not errorlevel 1 goto :blender
echo.
choice /c YN /n /m "    Download the missing UltraTex models now (up to ~11 GB)? [Y/N] "
if errorlevel 2 (
    echo     Skipped - run this file again to download them later
    set /a WARNS+=1
    goto :blender
)
"%PY%" -I "%HELPER%" models "%COMFY%" --download
if errorlevel 1 (echo     [FAIL] Some downloads failed - run this file again to resume & set /a FAILS+=1)

:blender
rem ------------------------------------------------------------------ 6
echo.
echo [6/7] Blender (LODTailor and Bake Forger run in Blender)
set "BLENDER="
for /f "delims=" %%B in ('where blender 2^>nul') do if not defined BLENDER set "BLENDER=%%B"
if not defined BLENDER for /d %%D in ("%ProgramFiles%\Blender Foundation\Blender*") do if exist "%%D\blender.exe" set "BLENDER=%%D\blender.exe"
if not defined BLENDER for /d %%D in ("C:\blender*" "D:\blender*" "E:\blender*") do (
    if exist "%%D\blender.exe" set "BLENDER=%%D\blender.exe"
    for /d %%E in ("%%D\blender*") do if exist "%%E\blender.exe" set "BLENDER=%%E\blender.exe"
)
if defined BLENDER goto :blender_found
echo     Not found automatically. Paste the full path to blender.exe
echo     (a clean portable Blender without add-ons works best), or press Enter to skip.
set /p "BLENDER=    blender.exe: "
if not defined BLENDER goto :blender_skip
set "BLENDER=%BLENDER:"=%"
if not exist "%BLENDER%" (
    echo     [WARN] "%BLENDER%" does not exist
    set "BLENDER="
    goto :blender_skip
)
:blender_found
echo     [OK]      %BLENDER%
goto :workflows
:blender_skip
echo     [WARN] No Blender - set the "Blender path" node in the workflows by hand
set /a WARNS+=1
set "BLENDER=blender"

:workflows
rem ------------------------------------------------------------------ 7
echo.
echo [7/7] Workflows
"%PY%" -I "%HELPER%" workflows "%HERE%workflows" "%WFDST%" "%BLENDER%"
if errorlevel 1 (echo     [FAIL] Workflows not copied & set /a FAILS+=1)
if not exist "%HERE%input\" goto :inputs_done
for %%F in ("%HERE%input\*.png") do if not exist "%COMFY%\input\%%~nxF" copy /y "%%F" "%COMFY%\input\" >nul
echo     [OK]      Example images in ComfyUI\input
:inputs_done

rem ---------------------------------------------------------------- summary
echo.
echo ============================ SUMMARY ============================
if defined PA_LATEST (echo  [INFO] Newest node versions from GitHub - NOT the tested versions) else (echo  [OK]   UltraTex + GGUF nodes pinned to the versions tested on %PIN_DATE%)
if "%BLOCKERS%"=="0" (echo  [OK]   Compatibility check: every compiled part loads in this Python/torch/CUDA) else (echo  [FAIL] Compatibility check: %BLOCKERS% part^(s^) cannot run here - see step 4)
if not "%BLOCKERS%"=="0" set /a FAILS+=1
if "%FAILS%"=="0" if "%WARNS%"=="0" echo  [OK]   Everything installed
if not "%WARNS%"=="0" echo  [WARN] %WARNS% warning(s) above
if not "%FAILS%"=="0" echo  [FAIL] %FAILS% step(s) failed - run this file again
echo.
echo  Next: start ComfyUI, open Workflows - PixelArtistry -
echo        PixelArtistry_05_Image_to_LowPoly_Character_UltraTex,
echo        set the UltraTex scratch folder to a drive with free space,
echo        load your image and press Run.
echo        Output: ComfyUI\output\3d\PixelArtistry_char_final_*.glb
echo.
if /i not "%~1"=="NoPause" pause
exit /b %FAILS%

rem ================================================================ helpers
:node
rem  %1 folder  %2 repo  %3 pinned sha  %4 label
set "N_DIR=%~1"
set "N_REPO=%~2"
set "N_SHA=%~3"
if defined PA_LATEST set "N_SHA=main"
if exist "%N_DIR%\.git\" goto :node_git_update
if exist "%N_DIR%\__init__.py" (
    echo     [OK]      %~4 present ^(not a git checkout - left as is^)
    exit /b 0
)
if defined HAVE_GIT goto :node_git_clone
rem  No git: download the pinned commit as a zip
set "N_ZIP=%TEMP%\pa_node.zip"
curl -L --fail -s -o "%N_ZIP%" "%N_REPO:https://github.com=https://codeload.github.com%/zip/%N_SHA%"
if errorlevel 1 goto :node_fail
set "N_TMP=%TEMP%\pa_node_unzip"
if exist "%N_TMP%" rmdir /s /q "%N_TMP%"
mkdir "%N_TMP%"
tar -xf "%N_ZIP%" -C "%N_TMP%"
if errorlevel 1 goto :node_fail
for /d %%D in ("%N_TMP%\*") do move "%%D" "%N_DIR%" >nul
if not exist "%N_DIR%\__init__.py" goto :node_fail
echo     [OK]      %~4 installed ^(zip %N_SHA:~0,7%^)
exit /b 0
:node_git_clone
git clone --quiet "%N_REPO%" "%N_DIR%"
if errorlevel 1 goto :node_fail
:node_git_update
git -C "%N_DIR%" fetch --quiet origin
if defined PA_LATEST (git -C "%N_DIR%" checkout --quiet origin/main) else (git -C "%N_DIR%" checkout --quiet "%N_SHA%")
if errorlevel 1 (
    echo     [WARN] %~4: could not switch to %N_SHA:~0,7% - local changes? Left as is
    set /a WARNS+=1
    exit /b 0
)
for /f %%H in ('git -C "%N_DIR%" rev-parse --short HEAD') do echo     [OK]      %~4 at %%H
exit /b 0
:node_fail
echo     [FAIL] %~4 could not be installed
set /a FAILS+=1
exit /b 1

:no_python
echo  [ERROR] "python_embeded" not found. Put this folder into ComfyUI-Easy-Install\Add-Ons\
echo          or next to python_embeded, and run it again.
pause
exit /b 1
:no_helper
echo  [ERROR] pa_helper.py is missing - keep the whole installer folder together.
pause
exit /b 1
:comfy_running
echo  [ERROR] ComfyUI from this folder is running. Close it, then run this file again.
pause
exit /b 1
:no_tools
echo  [ERROR] Neither git nor tar was found - install Git for Windows and run this again.
pause
exit /b 1
