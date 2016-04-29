# TelematicsBuilder
This is a set of scripts, that provide automation of build and deployment of Telematics project.

At the moment scripts support building of code and copying built dependencies to target directories.

## How to use
Main script of the set is `Build.ps1`. It accepts multiple parameters, listed below

### GitRepositoryRoot
Path to Git's repository of organization hosting project. From location defined by this parameter
script will assume existence of repositories like `axa-applications` and `axa-services` and will
proceed, as if they exist.

### LogsDirectory
Path to directory to store log files in during build. If this directory doesn't exist, it will be
created automatically. If it exists, all its contents will be removed without prompt.

### LocalDirectory
Path to directory to store files downloaded from Git repositories. If this directory doesn't exist,
it will be created automatically. If it exists, all its contents will be removed without prompt.

### ApplicationsBranch
Name of branch of `axa-applications` project to work on.

### ServicesBranch
Name of branch of `axa-services` project to work on. Usually it will be the same as
`ApplicationsBranch`.

## Description of process
Script first retrieves `axa-applications` and `axa-services` repositories from Git. git command may
require entry of credentials.

When code is downloaded, script builds all solutions in repository and copies outputs of builds to
"lib" directories of solutions that need them. Information about what to copy where comes from
predefined XML file containing all solutions to build and information about dependencies between
them. Structure of this file is contained in `BranchConfiguration.xsd` file.

After build is completed, changes made are commited to local branches and pushed to remote
repository.

Each step above logs its process to a file or files. When changes are commited and pushed, those
logs are gathered and sent to defined e-mail address.
