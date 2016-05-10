$MsBuildPath="C:\Program Files (x86)\MSBuild\12.0\Bin\MsBuild.exe"
$MsTestPath="C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\MSTest.exe"

function Builder-SolutionBuildResult () {
	param (
		[String]$SolutionName,
		[Boolean]$CodeBuilt,
		[Boolean]$UnitTestsPassed,
		[Boolean]$Succeeded
	)
	
	$result = New-Object PSObject | Select-Object SolutionName, CodeBuilt, UnitTestsPassed, Succeeded
	
	$result.SolutionName = $SolutionName
	$result.CodeBuilt = $CodeBuilt
	$result.UnitTestsPassed = $UnitTestsPassed
	$result.Succeeded = $Succeeded
	
	Return $result
}

function Builder-BuildResults() {
	param (
		[DateTime]$BuildStart,
		[DateTime]$BuildEnd,
		[Int]$Succeeded,
		[Int]$Failed
	)
	
	$result = New-Object PSObject | Select-Object BuildStart, BuildEnd, Succeeded, Failed, Solutions
	
	$result.BuildStart = $BuildStart
	$result.BuildEnd = $BuildEnd
	$result.Succeeded = $Succeeded
	$result.Failed = $Failed
	$result.Solutions = New-Object System.Collections.ArrayList
	
	Return $result
}


function Builder-LogFileLocation {
	param (
		[String]$SolutionName,
		[String]$LogDirectory
	)
	
	Return "$LogDirectory/$SolutionName.log"
}

# Builds a solution.
function Builder-BuildSolution {
	param (
		[String]$SolutionPath,
		[String]$SolutionName,
		[String]$LogDirectory,
		[String]$TestsLibrary
	)
	
	& $MsBuildPath $SolutionPath /t:Clean /p:Configuration=Release /verbosity:quiet > $null
	$params = "/fileLoggerParameters:LogFile=$(Builder-LogFileLocation $SolutionName $LogDirectory);Verbosity=quiet;Encoding=UTF-8"
	& $MsBuildPath $SolutionPath /t:Rebuild /p:Configuration=Release /fileLogger $params > $null
	$codeBuilt = ($LastExitCode -Eq 0)
	$result = $LastExitCode
	$unitTestsPassed = $true
	If (!($TestsLibrary -Eq ''))
	{
		$testsResultsDirectory = (Join-Path $LogDirectory ($solutionName + "Tests"))
		Tools-CreateDirectoryIfNotExists $testsResultsDirectory
		$resultsFile = (Join-Path $testsResultsDirectory 'TestResults.trx')
		& $MsTestPath /testcontainer:$TestsLibrary /resultsfile:$resultsFile > $null
		$unitTestsPassed = ($LastExitCode -Eq 0)
	}
	
	Return (Builder-SolutionBuildResult $SolutionName $codeBuilt $unitTestsPassed ($codeBuilt -And $unitTestsPassed))
}

function Builder-BuildSolutions {
	param (
		[String]$ConfigurationFile,
		[String]$BranchRoot,
		[String]$LogsDirectory,
        [String]$BuildLog
	)

	$buildStart = Get-Date
	$buildResults = (Builder-BuildResults $buildStart $buildStart 0 0)
	$MsBuildLogs = (Join-Path $LogsDirectory "MsBuildLogs")
	Tools-CreateDirectoryIfNotExists $MsBuildLogs $false
	$BranchConfiguration = [xml](Get-Content $ConfigurationFile)
	$repeats = $BranchConfiguration.Branch.Buildable.Solution.Name | Group {$_} | Where-Object {$_.Count -gt 1} | measure | % {$_.Count}
	if ($repeats -gt 0)
	{
		Write-Error "Solution names must be unique"
		Return;
	}

    $successes = 0
    $failures = 0
    [SystemCollections.ArrayList]$failedProjects = New-Object System.Collections.ArrayList
	foreach ($solution in $BranchConfiguration.Branch.Buildable.Solution)
	{
		$unitTestsLibrary = ''
		If (!($solution.UnitTestsLibrary -Eq '') -And !($solution.UnitTestsLibrary -Eq $null))
		{
			$unitTestsLibrary = (Join-Path $BranchRoot $solution.UnitTestsLibrary)
		}
		
		$result = `
			Builder-BuildSolution `
				"$BranchRoot/$($solution.Path)" `
				$solution.Name `
				$MsBuildLogs `
				$unitTestsLibrary
		$buildResults.Solutions.Add($result) > $null
		if ($result.Succeeded)
		{
			$successes++
			Write-Host "Build for solution $($solution.Name) succeeded"
			foreach ($output in $solution.Output)
			{
				foreach ($pattern in $output.Pattern)
				{
					$compiledFiles = Get-ChildItem $BranchRoot -Filter $pattern
					foreach ($compiled in $compiledFiles)
					{
						Copy-Item $compiled.FullName "$BranchRoot/$($output.Destination)"
					}
				}
			}
		}
		else
		{
            $failures++
            [void]$failedProjects.Add($solution.Path)
			Write-Host "Build for solution $($solution.Name) failed"
		}
	}
	
	$buildEnd = Get-Date
	$buildResults.BuildStart = $buildStart
	$buildResults.BuildEnd = $buildEnd
	$buildResults.Succeeded = $successes
	$buildResults.Failed = $failures
	Return $buildResults
}

function Builder-PublishSolution {
	param (
		[String]$ProjectPath,
		[String]$ProjectName,
		[String]$LogDirectory,
		[String]$OutputDirectory,
		[String]$Mode
	)
	
	& $MsBuildPath $ProjectPath /t:Clean /p:Configuration=Release /verbosity:quiet > $null
	$tempPath = "$($env:temp)/TempPublish"
	$buildResult = $true
	If ($Mode -eq "Publish")
	{
		$params = "/fileLoggerParameters:LogFile=$(Builder-LogFileLocation $ProjectName $LogDirectory);Verbosity=quiet;Encoding=UTF-8"
		& $MsBuildPath $ProjectPath /t:Rebuild /p:Configuration=Release /p:DeployOnBuild=true /p:CreatePackageOnPublish=false /p:OutDir=$tempPath /t:ResolveReferences /fileLogger $params > $null
		$result = $LastExitCode
		If (!($result -Eq 0))
		{
			$buildResult = $false
		}
		Else
		{
			Remove-Item "$tempPath/_PublishedWebsites/$ProjectName" -Include "*.config" -Recurse -Force
			Copy-Item "$tempPath/_PublishedWebsites/$ProjectName/*" $OutputDirectory -Recurse -Force
			$buildResult = $true
		}
	}
	ElseIf ($Mode -eq "CopyOutput")
	{
		$params = "/fileLoggerParameters:LogFile=$(Builder-LogFileLocation $ProjectName $LogDirectory);Verbosity=quiet;Encoding=UTF-8"
		& $MsBuildPath $ProjectPath /t:Rebuild /p:Configuration=Release /p:OutputPath=$tempPath /fileLogger $params > $null
		$result = $LastExitCode
		If (!($result -Eq 0))
		{
			$buildResult = $false
		}
		Else
		{
			Remove-Item "$tempPath" -Include "*.config" -Recurse -Force
			Copy-Item "$tempPath/*" $OutputDirectory -Recurse -Force
			$buildResult = $true
		}
	}

	Remove-Item $tempPath/* -Force -Recurse
	If ($buildResult)
	{
		Write-Host "Publish for solution $ProjectName succeeded"
	}
	Else
	{
		Write-Host "Publish for solution $ProjectName failed"
	}
	
	Return $buildResult
}

function Builder-PublishSolutions {
	param (
		[String]$ConfigurationFile,
		[String]$BranchRoot,
		[String]$LogsDirectory,
        [String]$PublishLog,
		[String]$SchedulerRoot,
		[String]$WwwRoot
	)

	$buildStart = Get-Date
	$publishResults = (Builder-BuildResults $buildStart $buildStart 0 0)
	$MsBuildLogs = (Join-Path $LogsDirectory "PublishLogs")
	Tools-CreateDirectoryIfNotExists $MsBuildLogs $false
	$BranchConfiguration = [xml](Get-Content $ConfigurationFile)
	$repeats = $BranchConfiguration.Branch.Buildable.Solution.Name | Group {$_} | Where-Object {$_.Count -gt 1} | measure | % {$_.Count}
	if ($repeats -gt 0)
	{
		Write-Error "Solution names must be unique"
		Return $False;
	}

    $successes = 0
    $failures = 0
    [SystemCollections.ArrayList]$failedProjects = New-Object System.Collections.ArrayList
	$succeeded = 0
	$failures = 0
	foreach ($solution in $BranchConfiguration.Branch.Buildable.Solution)
	{
		foreach ($project in $solution.PublishedProjects.Project)
		{
			$projectPath = (Join-Path $BranchRoot $project.Path)
			$outputDirectory = If ($project.Repository -eq "Scheduler") { $SchedulerRoot } Else { $WwwRoot }
			$outputDirectory = (Join-Path $outputDirectory ($project.TargetDirectory))
			$publishResult = Builder-PublishSolution $projectPath ($project.Name) $MsBuildLogs $outputDirectory ($project.Mode)
			$publishResults.Solutions.Add((Builder-SolutionBuildResult $project.Name $true $true $publishResult)) > $null
			If ($publishResult)
			{
				$successes++
			}
			Else
			{
				$failures++
			}
		}
	}

	$buildEnd = Get-Date
	$publishResults.BuildStart = $buildStart
	$publishResults.BuildEnd = $buildEnd
	$publishResults.Succeeded = $successes
	$publishResults.Failed = $failures
	Return $publishResults
}