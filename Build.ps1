param (
	[parameter(Mandatory=$true,HelpMessage="Root path of repository.")]
	[ValidateNotNullOrEmpty()]
	[String]$GitRepositoryRoot,
	[parameter(Mandatory=$true,HelpMessage="Path to directory to store logs in.")]
	[ValidateNotNullOrEmpty()]
	[String]$LogsDirectory,
	[parameter(Mandatory=$true,HelpMessage="Path to local directory for download source code.")]
	[ValidateNotNullOrEmpty()]
	[String]$LocalDirectory,
	[parameter(Mandatory=$true,HelpMessage="Name of axa-applications branch to build.")]
	[ValidateNotNullOrEmpty()]
	[String]$ApplicationsBranch,
	[parameter(Mandatory=$true,HelpMessage="Name of axa-services branch to build.")]
	[ValidateNotNullOrEmpty()]
	[String]$ServicesBranch,
	[parameter(Mandatory=$true,HelpMessage="Name of axa-bin-scheduler branch to build.")]
	[ValidateNotNullOrEmpty()]
	[String]$SchedulerBranch,
	[parameter(Mandatory=$true,HelpMessage="Name of axa-bin-wwwroot branch to build.")]
	[ValidateNotNullOrEmpty()]
	[String]$WwwBranch,
	[parameter(Mandatory=$true,HelpMessage="Path to root directory for logs persistence.")]
	[ValidateNotNullOrEmpty()]
	[String]$LogsPersistencePath,
	[parameter(Mandatory=$true,HelpMessage="Receiver address.")]
	[ValidateNotNullOrEmpty()]
	[String]$MailSender,
	[parameter(Mandatory=$true,HelpMessage="Receivers addresses.")]
	[ValidateNotNullOrEmpty()]
	[String[]]$MailReceivers,
	[parameter(Mandatory=$false,HelpMessage="Path to directory to store created package in")]
	[ValidateNotNullOrEmpty()]
	[String]$PackagesDirectory
)

function ResultsContainer {
	param (
		[Nullable[DateTime]]$StartDate,
		[Nullable[DateTime]]$EndDate,
		[Nullable[DateTime]]$GitDownloadStart,
		[Nullable[DateTime]]$GitDownloadEnd,
		[Nullable[DateTime]]$GitCommitStart,
		[Nullable[DateTime]]$GitCommitEnd,
		[PSObject]$BuildResults,
		[PSObject]$PublishResults
	)
	
	$result = New-Object PSObject | Select StartDate, EndDate, GitDownloadStart, GitDownloadEnd, GitCommitStart, GitCommitEnd, BuildResults, PublishResults
	
	$result.StartDate = $StartDate
	$result.EndDate = $EndDate
	$result.GitDownloadStart = $GitDownloadStart
	$result.GitDownloadEnd = $GitDownloadEnd
	$result.GitCommitStart = $GitCommitStart
	$result.GitCommitEnd = $GitCommitEnd
	$result.BuildResults = $BuildResults
	$result.PublishResults = $PublishResults
	
	return $result
}

$operationsResult = ResultsContainer $null $null $null $null $null $null $null, $null
$applicationsRoot = (Join-Path $LocalDirectory 'axa-applications')
$servicesRoot = (Join-Path $LocalDirectory 'axa-services')
$schedulerRoot = (Join-Path $LocalDirectory 'axa-bin-scheduler')
$wwwRoot = (Join-Path $LocalDirectory 'axa-bin-wwwroot')
$htmlLogPath = ''
$logsPackagePath = ''

# Import helper scripts
. "$PSSCriptRoot\Tools.ps1"
. "$PSSCriptRoot\GitProxy.ps1"
. "$PSSCriptRoot\Builder.ps1"
. "$PSSCriptRoot\MailSender.ps1"
. "$PSSCriptRoot\Packager.ps1"

function Initialize {
	Clear-Host
	Tools-CreateDirectoryIfNotExists $LocalDirectory
	Tools-CreateDirectoryIfNotExists $LogsDirectory
}

function RetrieveRepositories {
	$script:operationsResult.GitDownloadStart = Get-Date
	$GitDownloadLog = (Join-Path $LogsDirectory 'GitDownload.log')
	Start-Transcript -Path $GitDownloadLog -Force > $null
	$result = $false
	If ((GitProxy-GetRepository "$($GitRepositoryRoot)axa-applications.git" $script:applicationsRoot $ApplicationsBranch))
	{
		If ((GitProxy-GetRepository "$($GitRepositoryRoot)axa-services.git" $script:servicesRoot $ServicesBranch))
		{
			If ((GitProxy-GetRepository "$($GitRepositoryRoot)axa-bin-scheduler.git" $script:schedulerRoot $SchedulerBranch))
			{
				$result = GitProxy-GetRepository "$($GitRepositoryRoot)axa-bin-wwwroot.git" $script:wwwRoot $WwwBranch
			}
		}
	}
	
	$script:operationsResult.GitDownloadEnd = Get-Date
	Stop-Transcript > $null
	Return $result
}
	
function BuildCode {
	$BuildLogFile = (Join-Path $LogsDirectory 'Build.log')
	Start-Transcript -Path $BuildLogFile -Force > $null
	$script:operationsResult.BuildResults = Builder-BuildSolutions "$($script:applicationsRoot)/BranchBuildConfiguration.xml" $script:applicationsRoot $LogsDirectory $BuildLogFile
	Tools-CopyItems (Join-Path $script:applicationsRoot 'CRMEntities/bin/Release/*') (Join-Path $script:servicesRoot 'lib') 'CRMEntities.*'
	Tools-CopyItems (Join-Path $script:applicationsRoot 'UBI.QS.Console/QS.Shared/bin/Release/*') (Join-Path $script:servicesRoot 'lib') 'QS.Shared.dll'
	Tools-CopyItems (Join-Path $script:applicationsRoot 'UBI.Paybox.Shared/UBI.Paybox.Shared/bin/Release/*') (Join-Path $script:servicesRoot 'lib') 'UBI.Paybox.Shared.dll'
	$temp = Builder-BuildSolutions "$($script:servicesRoot)/BranchBuildConfiguration.xml" $script:servicesRoot $LogsDirectory $BuildLogFile
	Tools-AddResults $script:operationsResult.BuildResults $temp
    Write-Host "Built $($script:operationsResult.BuildResults.Succeeded + $script:operationsResult.BuildResults.Failed) projects"
    Write-Host "$($script:operationsResult.BuildResults.Succeeded) succeeded"
    Write-Host "$($script:operationsResult.BuildResults.Failed) failed"
	$success = $true
    if ($script:operationsResult.BuildResults.Failed -gt 0)
    {
        Write-Host "Failed projects:"
        foreach ($solution in $script:operationsResult.BuildResults.Solutions)
        {
			If (!($solution.Succeeded))
			{
				Write-Host "    $($solution.SolutionName) - Build: $($solution.CodeBuilt) - Tests: $($solution.UnitTestsPassed)"
			}
        }
		
		$success = $false
    }

	Stop-Transcript > $null
	Return $success
}

function Publish {
	$BuildLogFile = (Join-Path $LogsDirectory 'Publish.log')
	Start-Transcript -Path $BuildLogFile -Force > $null
	$script:operationsResult.PublishResults = Builder-PublishSolutions "$($script:applicationsRoot)/BranchBuildConfiguration.xml" $script:applicationsRoot $LogsDirectory $BuildLogFile $script:schedulerRoot $script:wwwRoot	
	$temp = Builder-PublishSolutions "$($script:servicesRoot)/BranchBuildConfiguration.xml" $script:servicesRoot $LogsDirectory $BuildLogFile $script:schedulerRoot $script:wwwRoot	
	Tools-AddResults $script:operationsResult.PublishResults $temp
    Write-Host "Published $($script:operationsResult.PublishResults.Succeeded + $script:operationsResult.PublishResults.Failed) projects"
    Write-Host "$($script:operationsResult.PublishResults.Succeeded) succeeded"
    Write-Host "$($script:operationsResult.PublishResults.Failed) failed"
	$success = $true
    if ($script:operationsResult.PublishResults.Failed -gt 0)
    {
        Write-Host "Failed projects:"
        foreach ($solution in $script:operationsResult.PublishResults.Solutions)
        {
			If (!($solution.Succeeded))
			{
				Write-Host "    $($solution.SolutionName)"
			}
        }

		$success = $false
    }

	Stop-Transcript > $null
	Return $success
}

function CommitChanges {
	$script:operationsResult.GitCommitStart = Get-Date
	$GitCommitLog = (Join-Path $LogsDirectory 'GitCommit.log')
	Start-Transcript -Path $GitCommitLog -Force -Append > $null
	If ((GitProxy-CommitChanges "$($script:applicationsRoot)/BranchBuildConfiguration.xml" $script:applicationsRoot ("Commit of build performed on {0}" -f (Get-Date))))
	{
		Write-Host "Commit of 'axa-applications' completed"
		If ((GitProxy-CommitChanges "$($script:servicesRoot)/BranchBuildConfiguration.xml" $script:servicesRoot ("Commit of build performed on {0}" -f (Get-Date))))
		{
			Write-Host "Commit of 'axa-services' completed"
			If ((GitProxy-CommitChanges "" $script:schedulerRoot ("Commit of build performed on {0}" -f (Get-Date))))
			{
				Write-Host "Commit of 'axa-bin-scheduler' completed"
				If ((GitProxy-CommitChanges "" $script:wwwRoot ("Commit of build performed on {0}" -f (Get-Date))))
				{
					Write-Host "Commit of 'axa-bin-wwwroot' completed"
				}
				Else
				{
					Write-Host "Commit of 'axa-bin-wwwroot' failed"
					Return $false
				}
			}
			Else
			{
				Write-Host "Commit of 'axa-bin-scheduler' failed"
				Return $false
			}
		}
		Else
		{
			Write-Host "Commit of 'axa-services' failed"
			Return $false
		}
	}
	Else
	{
		Write-Host "Commit of 'axa-applications' failed"
		Return $false
	}
	
	$script:operationsResult.GitCommitEnd = Get-Date
	Stop-Transcript > $null
	Return $true
}

function CreatePackages {
	If (!$PackagesDirectory)
	{
		Return
	}
	
	Tools-CreateDirectoryIfNotExists $PackagesDirectory $false
	$packageTime = ("{0:yyyy-MM-dd_hh-mm-ss}" -f (Get-Date))
	$schedulerPath = (Join-Path $PackagesDirectory ("scheduler_{0}.zip" -f $packageTime))
	Packager-CreatePackage $script:schedulerRoot $schedulerPath
	$schedulerPath = (Join-Path $PackagesDirectory ("wwwroot_{0}.zip" -f $packageTime))
	Packager-CreatePackage $script:wwwRoot $schedulerPath
}

function CreateLogs {
	$script:logsPackagePath = "$LogsDirectory.zip"
	If (Test-Path $script:logsPackagePath)
	{
		Remove-Item $script:logsPackagePath
	}

	# Create report file
	$logXmlPath = (Join-Path $LogsDirectory 'Log.xml')
	($script:operationsResult | ConvertTo-Xml -Depth 4 -NoTypeInformation).Save($logXmlPath)
	$script:htmlLogPath = (Join-Path $LogsDirectory 'Log.html')
	Tools-XsltTransform $logXmlPath $script:htmlLogPath
	Tools-CompressDirectory $LogsDirectory $script:logsPackagePath
}

function SendReport {
	If ((Tools-FileSize $script:logsPackagePath) -gt 1Mb)
	{
		MailSender-SendMail `
			-Sender $MailSender `
			-To $MailReceivers `
			-Subject "Report from building of branch $BranchToBuild" `
			-Body (Get-Content $script:htmlLogPath -Raw) `
			-MailServer "mail.axadirect-solutions.pl" `
			-IsBodyHtml $true
	}
	Else
	{
		MailSender-SendMail `
			-Sender $MailSender `
			-To $MailReceivers `
			-Subject "Report from building of branch $BranchToBuild" `
			-Body (Get-Content $script:htmlLogPath -Raw) `
			-MailServer "mail.axadirect-solutions.pl" `
			-IsBodyHtml $true `
			-Attachments (,$script:logsPackagePath)
	}
}

function BackupLogs {
	$logDirectory = ('{0}\{1}' -f (Get-Date -f yyyy), (Get-Date -f MM))
	$logDirectory = (Join-Path $LogsPersistencePath $logDirectory)
	Tools-CreateDirectoryIfNotExists $logDirectory $false
	$newFileName = $ApplicationsBranch + '_' + $ServicesBranch + '_' + ('{0:yyyy-MM-dd.hh-mm-ss}' -f (Get-Date)) + [System.IO.Path]::GetExtension($script:logsPackagePath)
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
If (RetrieveRepositories)
{
	If (BuildCode)
	{
		If (Publish)
		{
			If (CommitChanges)
			{
				CreatePackages
			}
		}
	}
}

$operationsResult.EndDate = Get-Date
CreateLogs
SendReport
BackupLogs
CleanUp
