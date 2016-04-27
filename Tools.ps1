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
