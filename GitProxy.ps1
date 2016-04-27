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
function GitProxy-GetRepository {
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
	git clone $RemotePath $LocalPath -b $Branch
	
	Write-Host ""
	Write-Host ""
}

function GitProxy-CommitChanges {
	param (
		[String]$BranchConfigurationPath,
		[String]$LocalDirectory
	)

	$branchConfiguration = [xml](Get-Content $BranchConfigurationPath -Raw)

	$currentLocation = Get-Location
	Set-Location $LocalDirectory
	foreach($destination in $branchConfiguration.Branch.Solution.Output.Destination)
	{
		git add $destination
	}

	git commit -m ("Commit of built performed on {0}" -f (Get-Date))
	# git push

	Set-Location $currentLocation
}
