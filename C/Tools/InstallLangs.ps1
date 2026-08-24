<#
.SYNOPSIS
    Installs full UI Language Experience Packs (LXP) plus selected Features on Demand
    (Basic, OCR, Handwriting, Text-to-Speech, Speech) for a defined list of languages.

.DESCRIPTION
    Uses the LanguagePackManagement module's Install-Language cmdlet to pull the full
    Local Experience Pack for each language (the complete translated UI, not just the
    lightweight UXP keyboard/typing layer), then uses Add-WindowsCapability to layer on
    the requested Features on Demand for each language.

.REQUIREMENTS
    - Windows 11 22H2+ (LanguagePackManagement module is built in) or Windows 10 22H2
      with the relevant optional update installed. Run `Get-Command Install-Language`
      to confirm availability before running this script.
    - Administrator rights (script requires elevation).
    - Internet access to Windows Update, OR Features on Demand content made available
      locally/via WSUS (see the "OFFLINE FOD SOURCE" note near the bottom of this file).

.NOTES
    Not every language supports every FOD family - Speech (recognition) and Handwriting
    in particular are only available for a subset of locales. The script checks
    availability with Get-WindowsCapability before attempting each install and reports
    anything that isn't available rather than failing the whole run.

    A restart is recommended after this script completes for all changes to fully apply.
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 1. Languages to install (BCP-47 tags)
# ---------------------------------------------------------------------------
$Languages = @(
    'ar-SA'   # Arabic (Saudi Arabia)
    'fr-FR'   # French (France)
    'de-DE'   # German (Germany)
    'it-IT'   # Italian (Italy)
    'ja-JP'   # Japanese
    'ko-KR'   # Korean
    'zh-CN'   # Chinese (Simplified, Mainland)
    'zh-TW'   # Chinese (Traditional, Taiwan)
    'pt-PT'   # Portuguese (Portugal)
    'ru-RU'   # Russian (Russia)
    'es-ES'   # Spanish (Spain)
    'el-GR'   # Greek (Greece)
    'en-US'   # English (US)
)

# ---------------------------------------------------------------------------
# 2. Feature on Demand families to attach to each language
# ---------------------------------------------------------------------------
$FodFamilies = @(
    'Language.Basic'
    'Language.OCR'
    'Language.Handwriting'
    'Language.TextToSpeech'
    'Language.Speech'
)

# ---------------------------------------------------------------------------
# Offline FOD source: use the mounted "Languages and Optional Features" ISO
# (drive D:) instead of reaching out to Windows Update.
# ---------------------------------------------------------------------------
$FodSourcePath = 'D:\'

if (-not (Test-Path $FodSourcePath)) {
    throw "FOD source path '$FodSourcePath' not found - confirm the Languages and Optional Features ISO is mounted as D: before running this script."
}

$wuPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
if (-not (Test-Path $wuPolicyPath)) {
    New-Item -Path $wuPolicyPath -Force | Out-Null
}
Set-ItemProperty -Path $wuPolicyPath -Name 'LocalSourcePath' -Value $FodSourcePath
Set-ItemProperty -Path $wuPolicyPath -Name 'UseWUServer' -Value 0

# Also tell DISM/Add-WindowsCapability directly to use the ISO, in case the
# registry policy above is overridden by other management (e.g. Intune/GPO).
$DismSourceArgs = @{ Source = $FodSourcePath; LimitAccess = $true }

Write-Host "Using offline FOD source: $FodSourcePath" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------
if (-not (Get-Command Install-Language -ErrorAction SilentlyContinue)) {
    throw "Install-Language cmdlet not found. This script needs the LanguagePackManagement module (Windows 11 22H2+, or Windows 10 22H2 with the language pack management update). Update Windows and try again."
}

Write-Host "=== Installing Language Experience Packs + FODs ===" -ForegroundColor Cyan

$results = foreach ($lang in $Languages) {

    Write-Host "`n--- $lang ---" -ForegroundColor Yellow

    # --- Full LXP install ---------------------------------------------------
    try {
        $installed = Get-InstalledLanguage -ErrorAction SilentlyContinue |
                     Where-Object LanguageId -eq $lang

        if ($installed) {
            Write-Host "  [LXP] $lang already installed - skipping." -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [LXP] Installing full language pack for $lang ..."
            # -CopyToSettings also applies the language to the welcome screen /
            # new user accounts. Remove the switch if you only want it for the
            # current user profile.
            Install-Language -Language $lang -CopyToSettings
            Write-Host "  [LXP] $lang installed." -ForegroundColor Green
        }
        $lxpStatus = 'OK'
    }
    catch {
        Write-Warning "  [LXP] Failed to install $lang : $($_.Exception.Message)"
        $lxpStatus = "FAILED: $($_.Exception.Message)"
    }

    # --- Features on Demand --------------------------------------------------
    $fodStatus = @{}

    foreach ($family in $FodFamilies) {

        # FOD capability names look like: Language.Basic~~~en-US~0.0.1.0
        $capability = Get-WindowsCapability -Online |
                      Where-Object { $_.Name -like "$family~~~$lang~*" } |
                      Select-Object -First 1

        if (-not $capability) {
            Write-Host "  [$family] Not available for $lang - skipping." -ForegroundColor DarkGray
            $fodStatus[$family] = 'NOT AVAILABLE'
            continue
        }

        if ($capability.State -eq 'Installed') {
            Write-Host "  [$family] Already installed for $lang." -ForegroundColor DarkGray
            $fodStatus[$family] = 'ALREADY INSTALLED'
            continue
        }

        try {
            Write-Host "  [$family] Installing ($($capability.Name)) ..."
            Add-WindowsCapability -Online -Name $capability.Name @DismSourceArgs | Out-Null
            Write-Host "  [$family] Installed." -ForegroundColor Green
            $fodStatus[$family] = 'OK'
        }
        catch {
            Write-Warning "  [$family] Failed for $lang : $($_.Exception.Message)"
            $fodStatus[$family] = "FAILED: $($_.Exception.Message)"
        }
    }

    [pscustomobject]@{
        Language     = $lang
        LXP          = $lxpStatus
        Basic        = $fodStatus['Language.Basic']
        OCR          = $fodStatus['Language.OCR']
        Handwriting  = $fodStatus['Language.Handwriting']
        TextToSpeech = $fodStatus['Language.TextToSpeech']
        Speech       = $fodStatus['Language.Speech']
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

Write-Host "`nA restart is recommended for all language and FOD changes to fully apply." -ForegroundColor Yellow

# ---------------------------------------------------------------------------
# OPTIONAL: add all installed languages to this user's language list and set
# a preferred UI language, once you've decided which one should be default.
# ---------------------------------------------------------------------------
# $list = Get-WinUserLanguageList
# foreach ($lang in $Languages) {
#     if ($list.LanguageTag -notcontains $lang) { $list.Add($lang) }
# }
# Set-WinUserLanguageList -LanguageList $list -Force
# Set-SystemPreferredUILanguage 'en-US'   # or whichever should be default
