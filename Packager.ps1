function Packager-CreatePackage {
	param (
		[String]$RepositoryDirectory,
		[String]$TargetPath
	)
	
	$gitDirectory = (Join-Path $RepositoryDirectory '.git')
	Tools-RemovePathIfExists $gitDirectory
	Tools-RemovePathIfExists $TargetPath
	Tools-CompressDirectory $RepositoryDirectory $TargetPath
}