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
	[String]$BranchToBuild,
	[parameter(Position=5,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Path to zip file containing logs.")]
	[ValidateNotNullOrEmpty()]
	[String]$LogsPackagePath
)

. ".\GitDownloader.ps1"
. ".\Builder.ps1"

Clear-Host

GitDownloader-GetRepository $GitRepositoryPath $LocalDirectory $BranchToBuild
$buildLogFile = Builder-BuildSolutions (Join-Path $LocalDirectory $BranchConfigurationFileName) $LogsPath $LocalDirectory

Add-Type -A System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($LogsPath, $LogsPackagePath)

Move-Item $LogsPackagePath $LogsPackagePath
$text = Get-Content $buildLogFile -Raw
$subject = "Report from building of branch $BranchToBuild"
Send-MailMessage `
	-Attachments $LogsPackagePath `
	-Body $text `
	-DeliveryNotificationOption OnFailure `
	-From lukasz.nowakowski@axadirect-solutions.pl `
	-SmtpServer mail.axadirect-solutions.pl `
	-Subject $subject `
	-To lukasz.nowakowski@axadirect-solutions.pl