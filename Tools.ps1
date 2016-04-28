function Tools-CreateDirectoryIfNotExists {
	param (
		[String]$DirectoryPath
	)
	
	if (!(Test-Path $DirectoryPath))
	{
		[void](New-Item -Path $DirectoryPath -ItemType Directory)
	}
    else
    {
        [void](Remove-Item -Path (Join-Path $DirectoryPath *) -Recurse -Force)
    }
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
