# Activate-SPSS.ps1

$TaskName = 'Activate SPSS'

# Test Internet connectivity
if (-not (Test-NetConnection graph.microsoft.com -Port 443 -InformationLevel Quiet)) {
    exit 0
}

try {
    # Activate SPSS
    Start-Process `
        -FilePath "C:\Program Files\IBM\SPSS Statistics\licenseactivator.exe" `
        -ArgumentList "7c1c1d04a5b1f6403547" `
        -Wait

    # Disable task after successful activation attempt
    Disable-ScheduledTask `
        -TaskName $TaskName `
        -ErrorAction SilentlyContinue
}
catch {
    # Leave the task enabled so it retries on the next run
    exit 1
}

exit 0