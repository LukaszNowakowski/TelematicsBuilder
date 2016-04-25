# Removes item pointed by path, if it exists.
function RemovePathIfExists {
	param (
		[String]$Path
	)

	if (Test-Path $Path) {
		Remove-Item $Path -Force -Recurse
	}
}

# Migrates changes from Git repository to TFS repository
function GitDownloader-GetRepository {
	param (
		[String]$RemotePath,
		[String]$LocalPath,
		[String]$Branch
	)
	
	Write-Host "Downloading '$RemotePath'"
	Write-Host "	Removing existing directory for download ($LocalPath)"
	RemovePathIfExists $LocalPath
	Write-Host "	Directory removed"
	
	Write-Host "	Downloading repository"
	git clone $RemotePath $LocalPath
	
	$currentLocation = Get-Location
	Set-Location ($LocalPath)

	Write-Host "Switching to branch $Branch"
	git checkout $Branch
	Set-Location $currentLocation
	Write-Host ""
	Write-Host ""
}

#GitDownloader-GetRepository "https://github.com/Operasoft/axa-applications.git" "C:\GitHub\AXA\Temp" "master"