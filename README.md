These are the notes from a talk given at the [Azure Dev Camp in Victoria](http://www.meetup.com/Victoria-App-Developer/events/221644488/) on 25 April 2015. They are a work in progress. If you see something that doesn't seem quite right, let me know, via an email, a pull request, or a tweet to @dicshaunary. I'll update the demo and its notes if appropriate. 

We'll present this again on [23 May in Vancouver](http://www.meetup.com/Vancouver-Windows-Platform-Developers-Group/events/221830707/).

# Overview

* Git (to commit locally and then push to a remote)
* Visual Studio and ASP.NET (to build web apps)
* Azure Web Apps (to host web apps)
* Nuget (to keep assemblies out of version control)
* Kudu, for deployments

Scenarios

* short-term scenario testing
* long-term continuous integration

We'll also cover:

* multiple Azure deployment slots connected to multiple Git branches
* custom Kudu deployment scripts for unit testing
* web based service control manager for Web Apps (domain.scm.azurewebsites.net)

This is the LIVE result (it isn't pretty - it's scaffolding):

* http://deploywebapp2azure.azurewebsites.net/
* http://deploywebapp2azure-staging.azurewebsites.net/

# Prerequisites

* Remote Git repo (e.g. GitHub, BitBucket, Visual Studio Online) 
* Local Git repo (msysgit.github.io)
* Microsoft Azure account (free, with automatic spending cap of zero)
* For this demo
  * PowerShell
  * NPM (node package manager)
  * Node
  * Azure Command Line Interface (azure-cli)

# Remote: Setup a Git Repo

This is the remote Git repository that stores our source code. See [github.com]() for detailed instructions.

* Setup a remote repository.
* Copy it's uri.
* For the demo we'll use `git@github.com:bigfont/silly-frogs.git`

# Local: Setup Git and Hello World

The is our development environment.

[PowerShell] Create a new directory with a `.gitignore` file and a default document.

    New-Item -type dir SillyFrogs
    cd SillyFrogs
    New-Item -type f .gitignore
    Add-Content .gitignore ("bin/" + "`n" + "obj/" + "`n")
    Add-Content index.html "Hello World."
    
[Git & PowerShell] Initiate git to speak to the remote with a `master` and `staging` branch.

    git init
    git remote add origin git@github.com:bigfont/silly-frogs.git
    # git pull origin master # necessary if remote has newer content

    git add -A
    git commit -m "Initial commit."

    # add MASTER to index.html first

    git add -A
    git commit -m "Add MASTER flag."
    git push --set-upstream origin master

    git checkout -b staging
    
    # add STAGING to index.html first

    git add -A
    git commit -m "Add staging flag."
    git push --set-upstream origin staging

# Azure: Create a Web App

This is where we're hosting our Web App.

There are UI gestures to do this. Alternatively, we can use the `azure-cli`. 

[CMD] Create a new MS Azure Web App

    npm install azure-cli -g
    azure account download
    azure account import <file>
    azure site create --location "West US" SillyFrogs
    # after doing this, 
    # we might have to upgrade its pricing tier
    # to allow for multiple deployment slots
    # portal.azure.com

We'll do the rest using the MS Azure UI thought the `azure-cli` works too.

* Go to the Web App's Dashboard 
    * Setup deployment from source control
    * GitHub
    * Repository Name > `SillyFrogs`
    * Branch to Deploy > `master`

* Return to the Azure Dashboard
    * Add a new deployment slot named `staging`
    * Don't clone
    * (I believe we need to be in a non-free tier to do this.)

* Go to Azure Dashboard for the staging deployment slot
    * Setup deployment from source control
    * GitHub
    * RepositoryName > `SillyFrogs`
    * Branch to Deploy > `staging`

We can view the details of the deployments slot with this command. 

    azure site show SillyFrogs --slot staging

At this point, we will have two **Hello World.** sites. One for master, another for staging. We can demonstration this by updating the index.html file in the `staging` branch with staging content.

[Git & PowerShell]

    git checkout staging
    Add-Content index.html "Staging"
    git add -A
    git commit -m "Add staging content."
    git push

# Local: Create ASP.NET Web Application

* Open Visual Studio
* Create a new Empty Web App
* File New Project > Templates > Visual C# > Web > ASP.NET Web Application
  * Name: `MyWebApp` 
  * Location: `<my-local-git-repo-dir`
  * Solution Name: `Create new solution`
  * Create directory for solution: `NO`
  * Add to source control: `NO`
* Empty (the others have too much distraction.)

[Directory Structure]

    DeployWebApp2Azure
        .git
		.vs
        MyWebApp
            MyWebApp.csproj          <----- this is what Azure will build
        .gitignore
        index.html                   <----- this is what will render
        MyWebApp.sln        
            
* Add, Commit, Push (we're on staging right now).

[Git]

    git add -A
    git commit -m "Create empty ASP.NET Web Application"
    git push

Remember: This will deploy to our staging deployment slot. We're currently using the default deployment command that comes out of the box with an Azure Web App. Often this is sufficient.

[SCM] Resultant wwwroot on Azure with default deployment script.

    bin
        MyWebApp.dll
    .gitignore
    index.html
    web.config

The Web App lacks functionality, so lets add simple MVC scaffolding.

* Controller etc
  * Solution Explorer > Project > Right Click
  * Add > New Scaffold Item
  * Common > MVC > Controller > MVC 5 Controller - Empty
  * `DefaultController`
* View
  * Inside DefaultController.cs > Right Click `Index()` > Add View > Accept Defaults

[Git]

    git add -A
    git commit -m "Add MVC scaffolding."
    git push

Again, this will deploy to Azure with the default deployment commands.

* Default is still `index.html` with Hello World.
* We can also view `~/default` now. 

# Local: Add Unit Tests

* Open MyWebApp.sln in Visual Studio
* Right click the solution > Add > New Project > Visual C# > Test
  * Name: `MyWebApp.Test`
  * Location: `<my-git-repository-dir>`

[Directory Structure]

    SillyFrogs
		.git
		.vs
		MyWebApp
		MyWebApp.Test
		packages
		.deployment
		.gitignore
		deploy-nothing.cmd
		index.html
		MyWebApp.sln
    
* Add, commit, and push

[Git]

    git add -A
    git commit -m "Add unit tests."
    git push

* Note: In Azure, the unit tests will not build nor run yet.

# Local: Add a Simple, Custom Deployment Script

This is an aside to show how deployment scripts work.

* Create a custom deployment script

[PowerShell]

The `.deployment` file is optional. We can set value either in it or in the app settings of our Web App. To start with, let's just add `echo Hello world.` to our custom deployment file. 

	Add-Content .deployment "[config] `r`n command = deploy-nothing.cmd"
    Add-Content deploy-nothing.cmd "echo Deploying nothing."
    git add -A
    git commit -m "Add deployment script."
    git push

Note: This no longer does any deployment! It **only** echos "Hello World."

# Integrate Unit Tests into Deployment

* Generate a deploy.cmd with scaffolding for MyWebApp.
* For help, type `azure site deploymentscript -h`

[cmd]

     azure site deploymentscript --aspWAP .\MyWebApp\MyWebApp.csproj -s .\MyWebApp.sln

Now, lets copy and edit the Kudu deploy.cmd file to integrate tests.

[PowerShell]

    Copy-Item deploy.cmd deploy-tests.cmd

[Kudu Script] Add this before `:: 3 Kudu Sync`

    :: Custom 1. Build test project
    echo Building test project
    "%MSBUILD_PATH%" "%DEPLOYMENT_SOURCE%\MyWebApp.Test\MyWebApp.Test.csproj"
    IF !ERRORLEVEL! NEQ 0 goto error

    :: Custom 2. Run tests
    echo Running tests
    vstest.console.exe "%DEPLOYMENT_SOURCE%\MyWebApp.Test\bin\Debug\MyWebApp.Test.dll"
    IF !ERRORLEVEL! NEQ 0 goto error

* Add, commit, and push

[Git]

    git add -A
    git commit -m "Add a deploy-tests deployment command file."
    git push

This won't run until we tell Azure to do so, either by updating the `.deployment` file to run `deploy-tests.cmd` or add an app setting via the portal. Let's do the former for now.

Since we added a failing test, Kudu will not sync. 

# Kudu Sync

    kudu -v 50 -f "%DEPLOYMENT_TEMP%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"

    -v Verbose logging with maximum number of output lines
    -f Source directory to sync
    -t Destination directory to sync
    -n Next manifest file path
    -p Previous manifest file path
    -i List of files/directories not to sync, delimited by `;`

TODO: How can we sync just static files (e.g. CSS).

# Notes

* By using Nuget, we can keep *most* binaries out of the repository.
* Be sure to add a .gitignore file with bin/ and obj/
* If you want to run \Release\ tests, then build with /property:Configuration=Release
* Kudu builds into a temporary folder and then syncs the result if the build and tests succeed.
* We can switch staging and master with a single click of Swap from the Web App dashboard.

# Possible Additions

* It's a good list. Maybe you can add some ARM based deployments. Also GitHub Deploy Button is good. From [David Ebbo]( https://twitter.com/davidebbo/status/601607544302243841)
