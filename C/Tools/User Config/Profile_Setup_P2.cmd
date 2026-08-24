@echo off

:checkifrun
IF EXIST "C:\tools\User Config\%USERNAME%\Prep_Complete_P2.tag" (exit)
IF /I NOT "%USERNAME:Exam=%"=="%USERNAME%" (goto :examuser)

exit

:examuser

powershell -NoProfile -Command "$wp='C:\Tools\User Config\%USERNAME%\Wallpaper\KCL %USERNAME%.jpg'; Add-Type '[DllImport(\"user32.dll\",CharSet=CharSet.Auto)] public static extern int SystemParametersInfo(int a,int b,string c,int d);' -Name W -Namespace N; [N.W]::SystemParametersInfo(20,0,$wp,3)"

REM Taskbar
taskkill /f /im explorer.exe
del "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.*" /q
copy "C:\Tools\User Config\%USERNAME%\Taskbar\*.lnk" "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" /Y
reg import "C:\Tools\User Config\%USERNAME%\Taskbar\Taskbar.reg"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f
start explorer.exe

timeout /t 3 /nobreak >nul

REM Desktop icon layout
"C:\Tools\DesktopOK\DesktopOK.exe" /load "C:\Tools\User Config\%USERNAME%\Icon Layout\Icons.dok"

REM Start Menu
taskkill /f /im StartMenuExperienceHost.exe
rd "%localappdata%\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState" /s /q
xcopy "C:\Tools\User Config\%USERNAME%\Start Menu\LocalState" "%LOCALAPPDATA%\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState" /ehryi
REM copy "C:\Tools\User Config\%USERNAME%\Start Menu\StartLayout.json" "%LOCALAPPDATA%\Microsoft\Windows\Shell\LayoutModification.json" /y


echo Prep Completed > "C:\tools\User Config\%USERNAME%\Prep_Complete_P2.tag"

exit