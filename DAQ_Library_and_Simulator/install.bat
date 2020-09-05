@echo off

SETLOCAL EnableDelayedExpansion

:: local files and folders
set "CURRENT_DIR=%~dp0"
set "DAQ_PROGRAM_DIR=!CURRENT_DIR!\DAQlib"
set "DAQ_TEMPLATE_DIR=!CURRENT_DIR!\DAQlib\VS\DAQTemplate"
set "DAQ_TEMPLATE_MANIFEST=!DAQ_TEMPLATE_DIR!\APSC160.DAQlib.Templates.Project.vstman"

:: check administrative rights and prompt for installation
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running installer as administrator
    echo.

:adminchoice
    set /P c= "Do you wish to install DAQlib for all users [Y/N]? "
    if /I "!c!" EQU "Y" goto :admininstall
    if /I "!c!" EQU "N" goto :userchoice
    echo     Invalid option !c!.  Please enter Y or N.
goto :adminchoice

) else (
    echo Running installer as user %USERNAME%
    echo.

:userchoice
    set /P c= "Do you wish to install DAQlib for user %USERNAME% [Y/N]? "
    if /I "!c!" EQU "Y" goto :userinstall
    if /I "!c!" EQU "N" goto :exit
    echo     Invalid option !c!.  Please enter Y or N.
goto :userchoice
)

:admininstall
echo.
echo Installing DAQlib for all users ...
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
    echo Could not find Visual Studio installation directory '!VS_INSTALL_DIR!' && goto :exit
)

set "VS_TEMPLATE_ROOT=!VS_INSTALL_DIR!\Common7\IDE\ProjectTemplates\VC"
set "INSTALL_ROOT=%PROGRAMDATA%"
set "VS_MANIFEST_ROOT=!VS_INSTALL_DIR!\Common7\IDE\ProjectTemplates"

goto :install

:userinstall
echo.
echo Installing DAQlib for user %USERNAME% ...
echo.

:: find User's "Documents" folder (seems to vary if OneDrive is configured to store documents )
FOR /F "tokens=3" %%G IN ('REG QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Personal"') DO SET USER_DOCUMENTS_DIR=%%G

set "VS_TEMPLATE_ROOT=!USER_DOCUMENTS_DIR!\Visual Studio 2017\Templates\ProjectTemplates\Visual C++ Project"
set "INSTALL_ROOT=%APPDATA%"
goto :install


:install
:: main installation routine

:: copy program
set "INSTALL_DIR=!INSTALL_ROOT!\APSC160\DAQlib"
echo Copying files to program directory '!INSTALL_DIR!'
xcopy "!DAQ_PROGRAM_DIR!" "!INSTALL_DIR!" /s/e/i/y/q 1>nul
if !errorlevel! neq 0 (
	echo    Failed to install the DAQlib library in '!INSTALL_DIR!' && goto :exit
)

:: copy template
set "TEMPLATE_DIR=!VS_TEMPLATE_ROOT!\APSC160\DAQlib\DAQTemplate"
if not exist "!VS_TEMPLATE_ROOT!" mkdir "!VS_TEMPLATE_ROOT!"
echo Copying template to directory '!TEMPLATE_DIR!'
xcopy "!DAQ_TEMPLATE_DIR!" "!TEMPLATE_DIR!" /s/e/i/y/q 1>nul
if !errorlevel! neq 0 (
	echo    Failed to install the DAQlib template in '!TEMPLATE_DIR!' && goto :exit
)

:: if global, install manifast
if defined VS_MANIFEST_ROOT (
    echo Installing template manifest '!DAQ_TEMPLATE_MANIFEST!' to '!VS_MANIFEST_ROOT!'
    copy "!DAQ_TEMPLATE_MANIFEST!" "!VS_MANIFEST_ROOT!" 1>nul
    echo Running devenv /installvstemplates
    "!VS_INSTALL_DIR!\Common7\IDE\devenv.exe" /installvstemplates
    if !errorlevel! neq 0 (
    	echo    Failed to install the DAQlib template manifest && goto :exit
    )
)

echo.
echo The DAQlib library and Visual Studio template have been successfully installed.
echo They should be available the next time Visual Studio is started.

:exit
echo.
ENDLOCAL

pause