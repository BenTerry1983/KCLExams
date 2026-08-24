@echo off

echo Setting Power Scheme Settings
powercfg /change monitor-timeout-ac 180
powercfg /change monitor-timeout-dc 10

echo Setting Default File Associations
Dism /Online /Import-DefaultAppAssociations:"C:\Tools\User Config\AppAssociations.xml"

echo Allowing SPSS through Windows Firewall
netsh advfirewall firewall add rule name="IBM SPSS Statistics" dir=in action=allow program="C:\Program Files\IBM\SPSS Statistics\Stats.exe" enable=yes profile=domain,private,public

echo Creating Local User Accounts
net user "Digital Exams" "" /add
net user "MBBS Exam" "" /add
net user "Paper Exam" "" /add

echo Adding accounts to the local Administrators group
net localgroup Administrators "Digital Exams" /add
net localgroup Administrators "MBBS Exam" /add
net localgroup Administrators "Paper Exam" /add

echo Setting Passwords to Never Expire
powershell -Command "Set-LocalUser -Name 'Digital Exams' -PasswordNeverExpires $true"
powershell -Command "Set-LocalUser -Name 'MBBS Exam' -PasswordNeverExpires $true"
powershell -Command "Set-LocalUser -Name 'Paper Exam' -PasswordNeverExpires $true"

echo Ensuring Accounts are Enabled
net user "Digital Exams" /active:yes
net user "MBBS Exam" /active:yes
net user "Paper Exam" /active:yes

echo Importing Application Registry Settings
reg import "C:\Tools\User Config\App Settings.reg"

echo Enabling Logon Scripts
reg import "C:\Tools\User Config\ActiveSetup.reg"
Copy "C:\Tools\User Config\Profile_Setup_P2.cmd" "c:\programdata\microsoft\windows\Start Menu\Programs\Startup"

echo Setting Initial User Logon Name (Digital Exams)
reg import "C:\Tools\User Config\Winlogon.reg"

echo Preventing Chrome Sign-in Message
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v BrowserSignin /t REG_DWORD /d 0 /f

echo Disabling Start Menu on First Logon
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v StartShownOnUpgrade /t REG_DWORD /d 1 /f
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f

echo Importing Scheduled Tasks
schtasks /Create /TN "Activate SPSS" /XML "C:\Tools\Scheduled Tasks\Activate SPSS.xml"
schtasks /Create /TN "Set Volume to Zero" /XML "C:\Tools\Scheduled Tasks\Set Volume to Zero.xml"
REN schtasks /Create /TN "Disable KCLAdmin" /XML "C:\Tools\Scheduled Tasks\Disable KCLAdmin.xml"

echo Setting Default User Account Picture for All Users
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v UseDefaultTile /t REG_DWORD /d 1 /f

echo Preventing Edge from Creating a Shortcut for New Users
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v CreateDesktopShortcutDefault /t REG_DWORD /d 0 /f

echo Restricting access to Edge for All Accounts, and Chrome for Paper Exam User
cmd /c "C:\Tools\Restrict_Browsers.cmd"

REM Resolution - didn't work here. Moved to Profile Setup.
REM PowerShell -ExecutionPolicy Bypass -File "C:\Tools\SetResolution.ps1"

echo Disabling Windows Update
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f
sc config wuauserv start= disabled
sc stop wuauserv