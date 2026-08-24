@echo off

REM Resolution and WiFi
IF EXIST "C:\tools\User Config\Res_Set.tag" (goto :checkifrun)
PowerShell -ExecutionPolicy Bypass -File "C:\Tools\SetResolution.ps1"
netsh wlan add profile filename="C:\tools\User Config\Kings2026.xml"
echo Resolution Set via QRes > "C:\tools\User Config\Res_Set.tag"

:checkifrun
IF EXIST "C:\tools\User Config\%USERNAME%\Prep_Complete.tag" (exit)
IF /I NOT "%USERNAME:Exam=%"=="%USERNAME%" (goto :examuser)

exit

:examuser


REM Taskbar
REM del "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.*" /q
REM copy "C:\Tools\User Config\%USERNAME%\Taskbar\*.lnk" "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" /Y
REM reg import "C:\Tools\User Config\%USERNAME%\Taskbar\Taskbar.reg"
REM reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f
REM reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f
REM taskkill /f /im explorer.exe
REM start explorer.exe

REM Desktop Icons
del "%USERPROFILE%\Desktop\Google Chrome.lnk" /q
copy "C:\Tools\User Config\%USERNAME%\Desktop\*.*" "%USERPROFILE%\Desktop" /y
REM timeout /t 3 /nobreak >nul
REM "C:\Tools\DesktopOK\DesktopOK.exe" /load "C:\Tools\User Config\%USERNAME%\Icon Layout\Icons.dok"

REM Wallpaper
REM reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "C:\Tools\User Config\%USERNAME%\Wallpaper\KCL %USERNAME%.jpg" /f
REM reg add "HKCU\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d 10 /f
REM reg add "HKCU\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d 0 /f
REM rundll32.exe user32.dll,UpdatePerUserSystemParameters

REM powershell -NoProfile -Command "$wp='C:\Tools\User Config\%USERNAME%\Wallpaper\KCL %USERNAME%.jpg'; Add-Type '[DllImport(\"user32.dll\",CharSet=CharSet.Auto)] public static extern int SystemParametersInfo(int a,int b,string c,int d);' -Name W -Namespace N; [N.W]::SystemParametersInfo(20,0,$wp,3)"

REM Start Menu
REM copy "C:\Tools\User Config\%USERNAME%\Start Menu\StartLayout.json" "%LOCALAPPDATA%\Microsoft\Windows\Shell\LayoutModification.json" /y
REM taskkill /f /im StartMenuExperienceHost.exe

REM Languages
REM PowerShell -ExecutionPolicy Bypass -File "C:\Tools\FixLangs.ps1"

echo Prep Completed > "C:\tools\User Config\%USERNAME%\Prep_Complete.tag"

exit