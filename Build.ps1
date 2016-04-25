param (
    [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Path to the Git repository.")]
	[ValidateNotNullOrEmpty()]
	[String]$GitRepositoryPath,
    [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Name of branch configuration file.")]
	[ValidateNotNullOrEmpty()]
	[String]$BranchConfigurationFileName,
    [parameter(Position=2,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Path to directory to store logs in.")]
	[ValidateNotNullOrEmpty()]
	[String]$LogsPath,
    [parameter(Position=3,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Path to local directory for download source code.")]
	[ValidateNotNullOrEmpty()]
	[String]$LocalDirectory,
    [parameter(Position=4,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Name of Git branch to build.")]
	[ValidateNotNullOrEmpty()]
	[String]$BranchToBuild
)

. ".\GitDownloader.ps1"
. ".\Builder.ps1"

Clear-Host

#GitDownloader-GetRepository $GitRepositoryPath $LocalDirectory "master"
Builder-BuildSolutions (Join-Path $LocalDirectory $BranchConfigurationFileName) $LogsPath $LocalDirectory
