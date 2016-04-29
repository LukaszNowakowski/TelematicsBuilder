param (
	[parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Root path of repository.")]
	[ValidateNotNullOrEmpty()]
	[String]$GitRepositoryRoot,
	[parameter(Position=2,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Path to directory to store logs in.")]
	[ValidateNotNullOrEmpty()]
	[String]$LogsDirectory,
	[parameter(Position=3,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Path to local directory for download source code.")]
	[ValidateNotNullOrEmpty()]
	[String]$LocalDirectory,
	[parameter(Position=4,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Name of axa-applications branch to build.")]
	[ValidateNotNullOrEmpty()]
	[String]$ApplicationsBranch,
	[parameter(Position=4,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Name of axa-services branch to build.")]
	[ValidateNotNullOrEmpty()]
	[String]$ServicesBranch,
	[parameter(Position=5,Mandatory=$true,ValueFromPipeline=$false,HelpMessage="Path to root directory for logs persistence.")]
	[ValidateNotNullOrEmpty()]
	[String]$LogsPersistencePath
)

function ResultsContainer {
	param (
		[Nullable[DateTime]]$StartDate,
		[Nullable[DateTime]]$EndDate,
		[Nullable[DateTime]]$GitDownloadStart,
		[Nullable[DateTime]]$GitDownloadEnd,
		[Nullable[DateTime]]$GitCommitStart,
		[Nullable[DateTime]]$GitCommitEnd,
		[PSObject]$BuildResults
	)
	
	$result = New-Object PSObject | Select StartDate, EndDate, GitDownloadStart, GitDownloadEnd, GitCommitStart, GitCommitEnd, BuildResults
	
	$result.StartDate = $StartDate
	$result.EndDate = $EndDate
	$result.GitDownloadStart = $GitDownloadStart
	$result.GitDownloadEnd = $GitDownloadEnd
	$result.GitDownloadStart = $GitDownloadStart
	$result.GitDownloadEnd = $GitDownloadEnd
	$result.BuildResults = $BuildResults
	
	return $result
}

$operationsResult = ResultsContainer $null $null $null $null $null $null $null
$applicationsRoot = (Join-Path $LocalDirectory 'axa-applications')
$servicesRoot = (Join-Path $LocalDirectory 'axa-services')
$htmlLogPath = ''
$logsPackagePath = ''

# Import helper scripts
. "$PSSCriptRoot\Tools.ps1"
. "$PSSCriptRoot\GitProxy.ps1"
. "$PSSCriptRoot\Builder.ps1"
. "$PSSCriptRoot\MailSender.ps1"

function Initialize {
	Clear-Host
	Tools-CreateDirectoryIfNotExists $LogsDirectory
}

function RetrieveRepositories {
	$script:operationsResult.GitDownloadStart = Get-Date
	$GitDownloadLog = (Join-Path $LogsDirectory 'GitDownload.log')
	Start-Transcript -Path $GitDownloadLog -Force
	GitProxy-GetRepository "$($GitRepositoryRoot)axa-applications.git" $script:applicationsRoot $ApplicationsBranch
	GitProxy-GetRepository "$($GitRepositoryRoot)axa-services.git" $script:servicesRoot $ServicesBranch
	$script:operationsResult.GitDownloadEnd = Get-Date
	Stop-Transcript
}
	
function BuildCode {
	$BuildLogFile = (Join-Path $LogsDirectory 'Build.log')
	Start-Transcript -Path $BuildLogFile -Force
	$script:operationsResult.BuildResults = Builder-BuildSolutions "$($script:applicationsRoot)/BranchBuildConfiguration.xml" $script:applicationsRoot $LogsDirectory $BuildLogFile
	Stop-Transcript
}

function CommitChanges {
	# Commit changes
	$script:operationsResult.GitCommitStart = Get-Date
	$GitCommitLog = (Join-Path $LogsDirectory 'GitCommit.log')
	Start-Transcript -Path $GitCommitLog -Force -Append
	GitProxy-CommitChanges "$($script:applicationsRoot)/BranchBuildConfiguration.xml" $script:applicationsRoot
	GitProxy-CommitChanges "$($script:servicesRoot)/BranchBuildConfiguration.xml" $script:servicesRoot
	$script:operationsResult.GitCommitEnd = Get-Date
	Stop-Transcript
	$BuildEnd = Get-Date
}

function CreateLogs {
	$script:logsPackagePath = "$LogsDirectory.zip"
	If (Test-Path $script:logsPackagePath)
	{
		Remove-Item $script:logsPackagePath
	}

	# Create report file
	# $result = (ResultsContainer $BuildStart $BuildEnd $GitDownloadStart $GitDownloadEnd $GitCommitStart $GitCommitEnd $applicationsBuildResult)
	$logXmlPath = (Join-Path $LogsDirectory 'Log.xml')
	($script:operationsResult | ConvertTo-Xml -Depth 4 -NoTypeInformation).Save($logXmlPath)
	$script:htmlLogPath = (Join-Path $LogsDirectory 'Log.html')
	Tools-XsltTransform $logXmlPath $script:htmlLogPath

	Add-Type -A System.IO.Compression.FileSystem
	[IO.Compression.ZipFile]::CreateFromDirectory($LogsDirectory, $script:logsPackagePath)
}

function SendReport {
	MailSender-SendMail `
		-Sender "Łukasz Nowakowski <lukasz.nowakowski@axadirect-solutions.pl>" `
		-To (,"Łukasz Nowakowski <lukasz.nowakowski@axadirect-solutions.pl>") `
		-Subject "Report from building of branch $BranchToBuild" `
		-Body (Get-Content $script:htmlLogPath -Raw) `
		-MailServer "mail.axadirect-solutions.pl" `
		-IsBodyHtml $true `
		-Attachments (,$script:logsPackagePath)
}

function BackupLogs {
	$logDirectory = ('{0}\{1}' -f (Get-Date -f yyyy), (Get-Date -f MM))
	$logDirectory = (Join-Path $LogsPersistencePath $logDirectory)
	Tools-CreateDirectoryIfNotExists $logDirectory $false
	$newFileName = $ApplicationsBranch + '_' + $ServicesBranch + '_' + ('{0:yyyy-MM-dd.HH-mm-ss}' -f (Get-Date)) + [System.IO.Path]::GetExtension($script:logsPackagePath)
	$newFileName = (Join-Path $logDirectory $newFileName)
	Copy-Item $script:logsPackagePath $newFileName
}

function CleanUp {
	Remove-Item $script:logsPackagePath -Force
	Remove-Item $LogsDirectory -Recurse -Force
	Remove-Item $LocalDirectory -Recurse -Force
}

$operationsResult.StartDate = Get-Date
Initialize
RetrieveRepositories
BuildCode
CommitChanges
$operationsResult.EndDate = Get-Date
CreateLogs
SendReport
BackupLogs
CleanUp
