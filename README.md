# TelematicsBuilder
This is a set of scripts, that provide automation of build and deployment of Telematics project.

Scripted activites are:

* build code and copy build outputs to correct directories

* publish applications to _publish_ respositories

* set common version for all libraries

## `Build.ps1`

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

### SchedulerBranch
Name of branch of `axa-bin-scheduler` project to work on.

### WwwRoot
Name of branch of `axa-bin-wwwroot` project to work on.

### LogsPersistencePath
Path to directory, to store logs from builds.

### MailSender
Address to send report from. It can be in one of two forms:

* "Display name &lt;email address&gt;"

* "email address"

Using first form should allow displaying friendly name in e-mail clients.

### MailReceivers
Array of addresses to send report to. Each entry can take any of the forms defined for `MailSender`
parameter.

#### Description of process
Script first retrieves `axa-applications` and `axa-services` repositories from Git. git command may
require entry of credentials.

When code is downloaded, script builds all solutions defined in branch configuration file  and
copies outputs of builds to "lib" directories of solutions that need them. Information about what to
copy where comes from predefined XML file containing all solutions to build and information about
dependencies between them. Structure of this file is contained in `BranchConfiguration.xsd` file.

When build of all solutions succeeds, code is then deployed to `axa-bin-scheduler` and
`axa-bin-wwwroot` repositories. Information about what to deploy where is also stored in XML branch
configuration file.

After "publish" is completed, changes made are commited to local branches and pushed to remote
repository.

Each step above logs its process to a file or files. When changes are commited and pushed, those
logs are gathered and sent to defined e-mail address.

Logs are then stored in requested location (by parameter LogsPersistencePath). Under directory
defined there a structure of directories is created to make it easier to search specific log. On
first level there are directories for each year in which process was executed. Under each year there
are directories for months. Underneath there are log files that have names in structure:
{%ApplicationsBranch%}\_{%ServicesBranch%}\_{%yyyy-MM-dd.HH-mm-ss%}.zip, where date is date of
completion of operations.

When logs are backed up, next step of process removes all files created leaving only the back ups 
of the log.

## `CreateSourceVersion.ps1`
Sets version of libraries for all projects in source code branches and sets version tag in
repository.

### GitRepositoryRoot
Path to Git's repository of organization hosting project. From location defined by this parameter
script will assume existence of repositories like `axa-applications` and `axa-services` and will
proceed, as if they exist

### RootDirectory
Directory to store downloaded code temporarily.

### NewVersion
Version number to set for all libraries. It must be in format A.B.C.D.

### BranchName
Name of branch to download.

## `CreateDeployVersion.ps1`
Sets version tag on deployment repositories.

### GitRepositoryRoot
Path to Git's repository of organization hosting project. From location defined by this parameter
script will assume existence of repositories like `axa-applications` and `axa-services` and will
proceed, as if they exist

### RootDirectory
Directory to store downloaded code temporarily.

### NewVersion
Version number to set. It must be in format A.B.C.D.

### BranchName
Name of branch to download.

This application is provided as is.
No warranty is provided.