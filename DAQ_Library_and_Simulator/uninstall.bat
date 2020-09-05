@echo off

SETLOCAL EnableDelayedExpansion

set "ADMIN_INSTALL_ROOT=%PROGRAMDATA%"
set "USER_INSTALL_ROOT=%APPDATA%"

:: Check administrative rights and prompt for installation
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running uninstaller as administrator
    echo.

    if exist "!ADMIN_INSTALL_ROOT!\APSC160" (
:adminchoice
        set /P c= "Do you wish to uninstall DAQlib for all users [Y/N]? "
        if /I "!c!" EQU "Y" goto :adminuninstall
        if /I "!c!" EQU "N" goto :userchoice
        echo     Invalid option !c!.  Please enter Y or N.
goto :adminchoice
    ) else (
        echo No system-wide DAQlib installation found. && goto :exit
    )

) else (
    echo Running uninstaller as user %USERNAME%
    echo.

    if exist "!USER_INSTALL_ROOT!\APSC160" (
:userchoice
        set /P c= "Do you wish to uninstall DAQlib for user %USERNAME% [Y/N]? "
        if /I "!c!" EQU "Y" goto :useruninstall
        if /I "!c!" EQU "N" goto :exit
        echo     Invalid option !c!.  Please enter Y or N.
goto :userchoice
     ) else (
        echo No DAQlib installation found for user %USERNAME%.
        echo Try running the uninstaller as administrator to remove for all users.
        goto :exit
     )
)

:adminuninstall
echo.
echo Uninstalling DAQlib for all users ...
echo.

:: check for Visual Studio installation
::   vswhere will find the latest installed version, but its location differs on 32-bit vs 64-bit machines
set "VSWHERE=vswhere.exe"
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
  set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
) else (
    if exist "%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe" (
      set "VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
    ) else (
      echo WARNING: You need VS 2017 version 15.2 or later (for vswhere.exe) && goto :exit
    )
)

:: find installation's template directory
for /f "usebackq tokens=*" %%i in (`"!VSWHERE!" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
  set VS_INSTALL_DIR=%%i
)
if not exist "!VS_INSTALL_DIR!" (
    echo Could not find Visual Studio installation directory && goto :exit
)

set "VS_TEMPLATE_ROOT=!VS_INSTALL_DIR!\Common7\IDE\ProjectTemplates\VC"
set "VS_TEMPLATE_MANIFEST=!VS_INSTALL_DIR!\Common7\IDE\ProjectTemplates\APSC160.DAQlib.Templates.Project.vstman"
set "INSTALL_ROOT=!ADMIN_INSTALL_ROOT!"

goto :uninstall

:useruninstall
echo.
echo Uninstalling DAQlib for user %USERNAME% ...
echo.

:: find User's "Documents" folder (seems to vary if OneDrive is configured to store documents )
FOR /F "tokens=3" %%G IN ('REG QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Personal"') DO SET USER_DOCUMENTS_DIR=%%G

set "VS_TEMPLATE_ROOT=!USER_DOCUMENTS_DIR!\Visual Studio 2017\Templates\ProjectTemplates\Visual C++ Project"
set "INSTALL_ROOT=!USER_INSTALL_ROOT!"

goto :uninstall


:uninstall
:: main uninstallation routine

set "INSTALL_DIR=!INSTALL_ROOT!\APSC160"
set "TEMPLATE_DIR=!VS_TEMPLATE_ROOT!\APSC160"

:: if global, remove template manifest
if defined VS_TEMPLATE_MANIFEST (
    echo Uninstalling template manifest '!VS_TEMPLATE_MANIFEST!'
    del /Q "!VS_TEMPLATE_MANIFEST!"
    echo Running devenv /installvstemplates
    "!VS_INSTALL_DIR!\Common7\IDE\devenv.exe" /installvstemplates
    if !errorlevel! neq 0 (
    	echo    Failed to uninstall the DAQlib template manifest && goto :exit
    )
)

:: remove template
echo Removing template from user directory '!TEMPLATE_DIR!'
del /S /Q "!TEMPLATE_DIR!" 1>nul
rmdir /S /Q "!TEMPLATE_DIR!" 1>nul
if !errorlevel! neq 0 (
	echo    Failed to uninstall the DAQlib template. Try removing manually. && goto :exit
)

:: remove program
echo Removing program files from '!INSTALL_DIR!'
del /S /Q "!INSTALL_DIR!" 1>nul
rmdir /S /Q "!INSTALL_DIR!" 1>nul
if !errorlevel! neq 0 (
	echo    Failed to uninstall the DAQlib library.  Try removing manually. && goto :exit
)

echo.
echo The DAQlib library and Visual Studio template have been successfully uninstalled.

:exit
echo.
ENDLOCAL

pause