param (
	[String]$GitRepositoryRoot,
	[String]$RootDirectory,
	[String]$BranchName,
	[String]$NewVersion
)

. "$PSSCriptRoot\Tools.ps1"
. "$PSSCriptRoot\GitProxy.ps1"

If (!($NewVersion -Match "[0-9]+(\.([0-9]+|\*)){1,3}"))
{
	Write-Host "Invalid version text"
	Break
}

Clear-Host
Tools-CreateDirectoryIfNotExists $RootDirectory
$wwwRoot = (Join-Path $RootDirectory 'axa-bin-wwwroot')
$servicesRoot = (Join-Path $RootDirectory 'axa-bin-scheduler')
If (!(GitProxy-GetRepository "$($GitRepositoryRoot)axa-bin-wwwroot.git" $wwwRoot $BranchName))
{
	Write-Host "Download of axa-bin-wwwRoot failed"
	Break
}

If (!(GitProxy-GetRepository "$($GitRepositoryRoot)axa-bin-scheduler.git" $servicesRoot $BranchName))
{
	Write-Host "Download of axa-bin-scheduler failed"
	Break
}

GitProxy-SetTag $wwwRoot $NewVersion
GitProxy-SetTag $servicesRoot $NewVersion

GitProxy-Push $wwwRoot
GitProxy-Push $servicesRoot
