function Set-DenyPermission {
    param(
        [string]$FilePath,
        [string]$UserName
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        Write-Warning "File not found, skipping: $FilePath"
        return
    }

    try {
        $account = New-Object System.Security.Principal.NTAccount($env:COMPUTERNAME, $UserName)
        $sid = $account.Translate([System.Security.Principal.SecurityIdentifier])
    }
    catch {
        Write-Warning "Local user '$UserName' not found on this machine. Skipping rule for $FilePath."
        return
    }

    try {
        $acl = Get-Acl -LiteralPath $FilePath

        $existingRules = $acl.Access | Where-Object {
            $_.IdentityReference.Value -eq $account.Value -or $_.IdentityReference.Value -eq $sid.Value
        }
        foreach ($rule in $existingRules) {
            $acl.RemoveAccessRule($rule) | Out-Null
        }

        # Compute the flags FIRST, as their own statement
        $rights = [System.Security.AccessControl.FileSystemRights]::Read -bor `
                  [System.Security.AccessControl.FileSystemRights]::Write

        # Use -ArgumentList instead of parenthesized "constructor" syntax
        $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule -ArgumentList @(
            $account,
            $rights,
            [System.Security.AccessControl.AccessControlType]::Deny
        )

        $acl.AddAccessRule($denyRule)
        Set-Acl -LiteralPath $FilePath -AclObject $acl

        Write-Host "Applied DENY Read/Write for '$UserName' on '$FilePath'" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set permission for '$UserName' on '$FilePath': $_"
    }
}