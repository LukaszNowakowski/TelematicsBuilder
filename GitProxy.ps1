# Removes item pointed by path, if it exists.
function RemovePathIfExists {
	param (
		[String]$Path
	)

	if (Test-Path $Path) {
		Remove-Item $Path -Force -Recurse -ErrorAction Stop
	}
}

# Migrates changes from Git repository to TFS repository
function GitProxy-GetRepository {
	param (
		[String]$RemotePath,
		[String]$LocalPath,
		[String]$Branch
	)
	
	Try
	{
		Write-Host "Downloading '$RemotePath'"
		Write-Host "	Removing existing directory for download ($LocalPath)"
		RemovePathIfExists $LocalPath
		Write-Host "	Directory removed"
		
		Write-Host "	Downloading repository"
		git clone $RemotePath $LocalPath -b $Branch
		If (!($LastExitCode -eq 0))
		{
			Write-Host "Error downloading $RemotePath"
		}
		
		Write-Host ""
		Write-Host ""
		Return $LastExitCode -eq 0
	}
	Catch
	{
		Write-Host "Error details"
		Write-Host "Source: $($_.Exception.Source)"
		Write-Host "Message: $($_.Exception.Message)"
		Write-Host "Target site:$($_.Exception.TargetSite)"
		Return $false
	}
}

# Commits changes to remote repository.
function GitProxy-CommitChanges {
	param (
		[String]$BranchConfigurationPath,
		[String]$LocalDirectory,
		[String]$Comment
	)

	$currentLocation = Get-Location
	Set-Location $LocalDirectory
	If (!!$BranchConfigurationPath)
	{
		$branchConfiguration = [xml](Get-Content $BranchConfigurationPath -Raw)
		foreach($destination in $branchConfiguration.Branch.Buildable.Solution.Output.Destination)
		{
			git add $destination
			If (!($LastExitCode -eq 0))
			{
				Write-Host "$destination not staged for commit"
				Return $false
			}
			Else
			{
				Write-Host "$destination staged for commit"
			}
		}
		
		foreach ($path in $branchConfiguration.Branch.External.Path)
		{
			git add $path
			If (!($LastExitCode -eq 0))
			{
				Write-Host "$path not staged for commit"
				Return $false
			}
			Else
			{
				Write-Host "$path staged for commit"
			}
		}
	}
	Else
	{
		git add (Join-Path $LocalDirectory "*")
		If (!($LastExitCode -eq 0))
		{
			Write-Host "$LocalDirectory not staged for commit"
			Return $false
		}
		Else
		{
			Write-Host "$LocalDirectory staged for commit"
		}
	}

	git commit -m $Comment
	If (!($LastExitCode -eq 0))
	{
		Write-Host "Commit to local repository failed"
		Return $false
	}
	Else
	{
		Write-Host "Commited to local repository"
	}
	
	git push
	If (!($LastExitCode -eq 0))
	{
		Write-Host "Push to remote repository failed"
		Return $false
	}
	Else
	{
		Write-Host "Pushed to remote repository"
	}

	Set-Location $currentLocation
	Return $true
}

function GitProxy-SetTag {
	param (
		[String]$RepositoryPath,
		[String]$Version
	)
	
	$currentLocation = Get-Location
	Set-Location $RepositoryPath
	git tag "v$Version"
	Set-Location $currentLocation
}

function GitProxy-Push {
	param (
		[String]$RepositoryPath
	)
	
	$currentLocation = Get-Location
	Set-Location $RepositoryPath
	git push
	Set-Location $currentLocation
}
