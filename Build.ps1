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
$BranchConfigurationPath = Join-Path $LocalDirectory $BranchConfigurationFileName
$buildLogFile = Builder-BuildSolutions $BranchConfigurationPath $LogsPath $LocalDirectory

$branchConfiguration = [xml](Get-Content $BranchConfigurationPath -Raw)

$currentLocation = Get-Location
Set-Location $LocalDirectory
foreach($destination in $branchConfiguration.Branch.Solution.Output.Destination)
{
	git add $destination
}

git commit -m ("Commit of built performed on {0}" -f (Get-Date))

Set-Location $currentLocation
If (Test-Path $LogsPackagePath)
{
	Remove-Item $LogsPackagePath
}

Add-Type -A System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($LogsPath, $LogsPackagePath)
Write-Host $buildLogFile
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