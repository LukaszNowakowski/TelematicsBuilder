$MsBuildPath="C:\Program Files (x86)\MSBuild\12.0\Bin\MsBuild.exe"

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
		[String]$LogDirectory
	)
	
	& $MsBuildPath $SolutionPath /t:Clean /p:Configuration=Release /verbosity:quiet > $null
	$params = "/fileLoggerParameters:LogFile=$(Builder-LogFileLocation $SolutionName $LogDirectory);Verbosity=quiet;Encoding=UTF-8"
	& $MsBuildPath $SolutionPath /t:Rebuild /p:Configuration=Release /fileLogger $params > $null
	$result = $LastExitCode
	Return $result -Eq 0
}

function Builder-BuildSolutions {
	param (
		[String]$ConfigurationFile,
		[String]$LogsDirectory,
		[String]$BranchRoot
	)

	If (Test-Path $LogsDirectory)
	{
		Remove-Item $LogsDirectory -Force -Recurse
	}

	New-Item $LogsDirectory -ItemType Directory > $null
	$buildLog = (Join-Path $LogsDirectory "BranchBuild.log")
	[void](Start-Transcript -Path $buildLog -Force)
	$MsBuildLogs = (Join-Path $LogsDirectory "MsBuildLogs")
	New-Item $MsBuildLogs -ItemType Directory > $null
	$BranchConfiguration = [xml](Get-Content $ConfigurationFile)
	$repeats = $BranchConfiguration.Branch.Solution.Name | Group {$_} | Where-Object {$_.Count -gt 1} | measure | % {$_.Count}
	if ($repeats -gt 0)
	{
		Write-Error "Solution names must be unique"
		Return;
	}

	foreach ($solution in $BranchConfiguration.Branch.Solution)
	{
		Write-Host "Rebuilding solution $($solution.Name)"
		$result = (Builder-BuildSolution "$BranchRoot/$($solution.Path)" $solution.Name $MsBuildLogs)
		if ($result)
		{
			Write-Host "Build for solution $($solution.Name) succeeded"
			Remove-Item (Builder-LogFileLocation $solution.Name $MsBuildLogs) -Force
			if ($solution.Output -And $solution.Output.Pattern)
			{
				if ($solution.Output.Pattern.Count -gt 0)
				{
					foreach ($pattern in $solution.Output.Pattern)
					{
						$outputs = Get-ChildItem $BranchRoot -Filter $pattern
						foreach ($output in $outputs)
						{
							Copy-Item $output.FullName "$BranchRoot/$($solution.Output.Destination)"
						}
					}
				}
			}
		}
		else
		{
			Write-Host "Build for solution $($solution.Name) failed"
		}
		
		Write-Host ""
		Write-Host ""
	}
		
	[void](Stop-Transcript)
	
	Return $buildLog
}