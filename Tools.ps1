﻿function Tools-CompressDirectory {
	param (
		[String]$SourcePath,
		[String]$TargetPath
	)

	Add-Type -A System.IO.Compression.FileSystem
	[IO.Compression.ZipFile]::CreateFromDirectory($SourcePath, $TargetPath)
}

function Tools-RemovePathIfExists {
	param (
		[String]$Path
	)

	if (Test-Path $Path) {
		Remove-Item $Path -Force -Recurse -ErrorAction Stop
	}
}

function Tools-CreateDirectoryIfNotExists {
	param (
		[String]$DirectoryPath,
		[Boolean]$ClearIfExists = $true
	)
	
	If (!(Test-Path $DirectoryPath))
	{
		[void](New-Item -Path $DirectoryPath -ItemType Directory)
	}
    ElseIf ($ClearIfExists)
    {
        [void](Remove-Item -Path (Join-Path $DirectoryPath *) -Recurse -Force)
    }
}

function Tools-ParentDirectory {
	param (
		[String]$FilePath
	)
	
	Return (Get-Item $FilePath).DirectoryName
}

function Tools-XsltTransform {
	param (
		$xml,
		$output
	)

	$xslt = New-Object System.Xml.Xsl.XslCompiledTransform;
	$xslt.Load("$PSSCriptRoot\Report.xsl");
	$xslt.Transform($xml, $output);
}

function Tools-CopyItems {
	param (
		[String]$SourceDir,
		[String]$TargetDir,
		[String]$Filter
	)
	
	Copy-Item $SourceDir $TargetDir -Filter $Filter -Recurse
}

function Tools-AddResults {
	param (
		[PSObject]$To,
		[PSObject]$From
	)

	$To.BuildEnd = $From.BuildEnd
	$To.Succeeded += $From.Succeeded
	$To.Failed += $From.Failed
	$To.Solutions.AddRange($From.Solutions)
}

function Tools-FileSize {
	param (
		[String]$FilePath
	)
	
	Return (Get-Item $FilePath).Length
}
