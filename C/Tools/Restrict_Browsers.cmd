@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: Restrict_Browsers_ICACLS.bat
:: Denies Read and Write access to browser executables for
:: specific local exam-related user accounts using ICACLS.
::
:: Must be run as Administrator.
:: ============================================================

:: --- Check for Administrator privileges ---
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: This script must be run as Administrator.
    pause
    exit /b 1
)

echo.
echo === Applying DENY (Read/Write) to Microsoft Edge ===
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    icacls "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" /deny "Paper Exam:(R,W)"
    icacls "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" /deny "MBBS Exam:(R,W)"
    icacls "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" /deny "Digital Exams:(R,W)"
) else (
    echo WARNING: File not found
)

echo.
echo === Applying DENY (Read/Write) to Google Chrome ===
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    icacls "C:\Program Files\Google\Chrome\Application\chrome.exe" /deny "Paper Exam:(R,W)"
) else (
    echo WARNING: File not found
)

echo.
echo === Done. Verify with: icacls "path\to\file.exe" ===
endlocal