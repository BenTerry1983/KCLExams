$Langs = @(
    "en-GB",
    "ar-SA",
    "fr-FR",
    "de-DE",
    "it-IT",
    "ko-KR",
    "zh-CN",
    "zh-TW",
    "es-ES",
    "el-GR"
)

$List = Get-WinUserLanguageList
foreach ($L in $Langs) {
    if (-not ($List.LanguageTag -contains $L)) {
        $List.Add($L)
    }
}
Set-WinUserLanguageList $List -Force