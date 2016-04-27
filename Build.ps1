param (
    [parameter(Position=1,Mandatory=$false,ValueFromPipeline=$true,HelpMessage="Root path of repository.")]
    [ValidateNotNullOrEmpty()]
    [String]$GitRepositoryRoot = 'git@github.com:Operasoft/',
    [parameter(Position=2,Mandatory=$false,ValueFromPipeline=$true,HelpMessage="Path to directory to store logs in.")]
	[ValidateNotNullOrEmpty()]
	[String]$LogsDirectory = 'C:/GitHub/AXA/Logs',
    [parameter(Position=3,Mandatory=$false,ValueFromPipeline=$true,HelpMessage="Path to local directory for download source code.")]
	[ValidateNotNullOrEmpty()]
	[String]$LocalDirectory = 'C:/GitHub/AXA/BuildWorkspace',
    [parameter(Position=4,Mandatory=$false,ValueFromPipeline=$true,HelpMessage="Name of axa-applications branch to build.")]
	[ValidateNotNullOrEmpty()]
	[String]$ApplicationsBranch = 'branch-automation-refactoring',
    [parameter(Position=4,Mandatory=$false,ValueFromPipeline=$true,HelpMessage="Name of axa-services branch to build.")]
	[ValidateNotNullOrEmpty()]
	[String]$ServicesBranch = 'branch-automation-refactoring'

)

# Import helper scripts
. "$PSSCriptRoot\Tools.ps1"
. "$PSSCriptRoot\GitProxy.ps1"
. "$PSSCriptRoot\Builder.ps1"
. "$PSSCriptRoot\MailSender.ps1"

# Initialization
Clear-Host
#Tools-CreateDirectoryIfNotExists $LogsDirectory

# Retrieve repositories
$GitDownloadLog = (Join-Path $LogsDirectory 'GitDownload.log')
$ApplicationsRoot = (Join-Path $LocalDirectory 'axa-applications')
$ServicesRoot = (Join-Path $LocalDirectory 'axa-services')
#Start-Transcript -Path $GitDownloadLog -Force
#GitProxy-GetRepository "$($GitRepositoryRoot)axa-applications.git" $ApplicationsRoot $ApplicationsBranch
#GitProxy-GetRepository "$($GitRepositoryRoot)axa-services.git" $ServicesRoot $ServicesBranch
#Stop-Transcript

# Build code
$BuildLogFile = (Join-Path $LogsDirectory 'Build.log')

# Build axa-applications
#Start-Transcript -Path $BuildLogFile -Force
#Builder-BuildSolutions "$ApplicationsRoot/BranchBuildConfiguration.xml" $ApplicationsRoot $LogsDirectory $BuildLogFile
#Stop-Transcript

# Commit changes
$GitCommitLog = (Join-Path $LogsDirectory 'GitCommit.log')
#Start-Transcript -Path $GitCommitLog -Force -Append
#GitProxy-CommitChanges "$ApplicationsRoot/BranchBuildConfiguration.xml" $ApplicationsRoot
#GitProxy-CommitChanges "$ServicesRoot/BranchBuildConfiguration.xml" $ServicesRoot
#Stop-Transcript

$LogsPackagePath = "$LogsDirectory.zip"
If (Test-Path $LogsPackagePath)
{
	Remove-Item $LogsPackagePath
}

Add-Type -A System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($LogsDirectory, $LogsPackagePath)


# Send e-mail
MailSender-SendMail `
	-Sender "Łukasz Nowakowski <lukasz.nowakowski@axadirect-solutions.pl>" `
	-To (,"Łukasz Nowakowski <lukasz.nowakowski@axadirect-solutions.pl>") `
	-Subject "Report from building of branch $BranchToBuild" `
	-Body (Get-Content $buildLogFile -Raw) `
	-MailServer "mail.axadirect-solutions.pl" `
	-IsBodyHtml $false `
	-Attachments (,$LogsPackagePath)