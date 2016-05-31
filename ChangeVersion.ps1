param (
	[String]$GitRepositoryRoot,
	[String]$RootDirectory,
	[String]$BranchName,
	[String]$NewVersion
)

. "$PSSCriptRoot\Tools.ps1"
. "$PSSCriptRoot\GitProxy.ps1"

function ChangeVersion-NewVersionText {
	param (
		[String]$Version
	)
	
	Return 'AssemblyVersion("' + $Version + '")'
}

function ChangeVersion-NewFileVersionText {
	param (
		[String]$Version
	)
	
	Return 'AssemblyVersion("' + $version + '")'
}

function ChangeVersion-ChangeFileVersion {
	param (
		[String]$FilePath,
		[String]$Version
	)

	$contents = (Get-Content $FilePath -Raw)
	$contents = $contents -Replace 'AssemblyVersion\("[0-9]+(\.([0-9]+)){1,3}"\)', (ChangeVersion-NewVersionText $Version)
	$contents = $contents -Replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+)){1,3}"\)', (ChangeVersion-NewFileVersionText $Version)
	$contents > $FilePath
}

function ChangeVersion-ChangeDirectoryVersion {
	param (
		[String]$DirectoryPath,
		[String]$Version
	)
	
	Write-Host "Changing file versions in $DirectoryPath"
	$files = Get-ChildItem $DirectoryPath -Recurse -Include AssemblyInfo.cs
	ForEach ($file in $files)
	{
		ChangeVersion-ChangeFileVersion $file.Fullname $Version
	}
}

If (!($NewVersion -Match "[0-9]+(\.([0-9]+|\*)){1,3}"))
{
	Write-Host "Invalid version text"
	Break
}

Clear-Host
Tools-CreateDirectoryIfNotExists $RootDirectory
$applicationsRoot = (Join-Path $RootDirectory 'axa-applications')
$servicesRoot = (Join-Path $RootDirectory 'axa-services')
If (!(GitProxy-GetRepository "$($GitRepositoryRoot)axa-applications.git" $applicationsRoot $BranchName))
{
	Write-Host "Download of axa-applications failed"
	Break
}

If (!(GitProxy-GetRepository "$($GitRepositoryRoot)axa-services.git" $servicesRoot $BranchName))
{
	Write-Host "Download of axa-services failed"
	Break
}

ChangeVersion-ChangeDirectoryVersion $applicationsRoot $NewVersion
ChangeVersion-ChangeDirectoryVersion $servicesRoot $NewVersion
If (!(GitProxy-CommitChanges "" $applicationsRoot ("Commit of assembly versions change made on {0}" -f (Get-Date))))
{
	Write-Host "Commit to axa-applications failed"
	Break
}

If (!(GitProxy-CommitChanges "" $servicesRoot ("Commit of assembly versions change made on {0}" -f (Get-Date))))
{
	Write-Host "Commit to axa-services failed"
	Break
}

GitProxy-SetTag $applicationsRoot $NewVersion
GitProxy-SetTag $servicesRoot $NewVersion

GitProxy-Push $applicationsRoot
GitProxy-Push $servicesRoot
