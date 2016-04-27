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
		[String]$BranchRoot,
		[String]$LogsDirectory,
        [String]$BuildLog
	)

	$MsBuildLogs = (Join-Path $LogsDirectory "MsBuildLogs")
	New-Item $MsBuildLogs -ItemType Directory > $null
	$BranchConfiguration = [xml](Get-Content $ConfigurationFile)
	$repeats = $BranchConfiguration.Branch.Solution.Name | Group {$_} | Where-Object {$_.Count -gt 1} | measure | % {$_.Count}
	if ($repeats -gt 0)
	{
		Write-Error "Solution names must be unique"
		Return;
	}

    $successes = 0
    $failures = 0
    [SystemCollections.ArrayList]$failedProjects = New-Object System.Collections.ArrayList
	foreach ($solution in $BranchConfiguration.Branch.Solution)
	{
		$result = (Builder-BuildSolution "$BranchRoot/$($solution.Path)" $solution.Name $MsBuildLogs)
		if ($result)
		{
            $successes++
			Write-Host "Build for solution $($solution.Name) succeeded"
			Remove-Item (Builder-LogFileLocation $solution.Name $MsBuildLogs) -Force
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
		
		Write-Host ""
	}

    Write-Host "Build $($successes + $failures) projects"
    Write-Host "$successes succeeded"
    Write-Host "$failures failed"
    if ($failures -gt 0)
    {
        Write-Host "Failed projects:"
        foreach ($solution in $failedProjects)
        {
            Write-Host "    $solution"
        }
    }
}