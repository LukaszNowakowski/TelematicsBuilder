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

	$currentLocation = Get-Location
	Set-Location $LocalDirectory
	If (!!$BranchConfigurationPath)
	{
		$branchConfiguration = [xml](Get-Content $BranchConfigurationPath -Raw)
		foreach($destination in $branchConfiguration.Branch.Buildable.Solution.Output.Destination)
		{
			git add $destination
			Write-Host "Added $destination to source control"
		}
		
		foreach ($path in $branchConfiguration.Branch.External.Path)
		{
			git add $path
			Write-Host "Added $path to source control"
		}
	}
	Else
	{
		git add (Join-Path $LocalDirectory "*")
	}

	git commit -m ("Commit of built performed on {0}" -f (Get-Date))
	Write-Host "Commited to local repository"
	git push
	Write-Host "Pushed to remote repository"

	Set-Location $currentLocation
}
