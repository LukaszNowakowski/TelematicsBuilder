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

. ".\GitProxy.ps1"
. ".\Builder.ps1"

Clear-Host

#GitProxy-GetRepository $GitRepositoryPath $LocalDirectory $BranchToBuild
$BranchConfigurationPath = Join-Path $LocalDirectory $BranchConfigurationFileName
$buildLogFile = "C:\GitHub\AXA\buildLogs\BranchBuild.log"
#$buildLogFile = Builder-BuildSolutions $BranchConfigurationPath $LogsPath $LocalDirectory
#GitProxy-CommitChanges $BranchConfigurationPath $LocalDirectory

If (Test-Path $LogsPackagePath)
{
	Remove-Item $LogsPackagePath
}

Add-Type -A System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($LogsPath, $LogsPackagePath)

./MailSender.ps1 `
	-Sender "Łukasz Nowakowski <lukasz.nowakowski@axadirect-solutions.pl>" `
	-To (,"Łukasz Nowakowski <lukasz.nowakowski@axadirect-solutions.pl>") `
	-Subject "Report from building of branch $BranchToBuild" `
	-Body (Get-Content $buildLogFile -Raw) `
	-MailServer "mail.axadirect-solutions.pl" `
	-IsBodyHtml $false `
	-Attachments (,$LogsPackagePath)
# Write-Host $buildLogFile
# $text = Get-Content $buildLogFile -Raw
# $subject = "Report from building of branch $BranchToBuild"
# Send-MailMessage `
	# -Attachments $LogsPackagePath `
	# -Body $text `
	# -DeliveryNotificationOption OnFailure `
	# -From lukasz.nowakowski@axadirect-solutions.pl `
	# -SmtpServer mail.axadirect-solutions.pl `
	# -Subject $subject `
	# -To lukasz.nowakowski@axadirect-solutions.pl