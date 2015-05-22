These are the notes from a talk given at the [Azure Dev Camp in Victoria](http://www.meetup.com/Victoria-App-Developer/events/221644488/) on 25 April 2015. They are a work in progress. If you see something that doesn't seem quite right, let me know, via an email, a pull request, or a tweet to @dicshaunary. I'll update the demo and its notes if appropriate. 

We'll present this again on [23 May in Vancouver](http://www.meetup.com/Vancouver-Windows-Platform-Developers-Group/events/221830707/).

# Overview

Use Visual Studio, Git, and Azure Web Apps to quickly test out development scenarios and/or do continuous integration over the long term. This talk will cover: 

* NuGet in Visual Studio to keep assemblies out of version control
* Git to commit locally and then push to a remote (in the demo, we'll use GitHub)
    * we could also use Visual Studio Online 
* Azure Web Apps that use Kudu to deploy from version control

This workflow can be lightweight enough for scenario testing, in which we spin up an Azure Web App and tear it down when we've finished. It can also support longer term continuous integration and testing scenarios. 

We'll also cover:

* multiple deployment slots in Azure Web Apps that connect to multiple Git branches
* Kudu deployment scripts that tell Azure to run our unit tests and sync only builds that pass
* the web-based service control manager for Web Apps (at mydomain.scm.azurewebsites.net)

In short, well cover:

    Local --> Remote --> Azure

This is the LIVE result (it isn't pretty - it's scaffolding):

* http://deploywebapp2azure.azurewebsites.net/
* http://deploywebapp2azure-staging.azurewebsites.net/

# Prerequisites

* A remote Git repository (e.g. a GitHub account.) 
* A Microsoft Azure account (free and with an automatic spending cap of zero.)
* Git installed locally (msysgit.github.io)
* For the purpose of this demo
  * PowerShell
  * NPM (the node package manager)
  * Node
  * Azure Command Line Interface

# Remote: Setup a Git Repo

This is the remote Git repository that stores our source code. [github.com]() has detailed instructions.

* Setup a remote repository.
* Copy it's uri.
* For the demo we'll use `git@github.com:bigfont/silly-frogs.git`

# Local: Setup Git

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
    git push --set-upstream origin master
    git checkout -b staging
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

# Local: Add a Simple, Custom Deployment Script

* Create a custom deployment script

[PowerShell]

The `.deployment` file is optional. We can set value either in it or in the app settings of our Web App. To start with, let's just add `echo Hello world.` to our custom deployment file. 

	Add-Content .deployment "[config] `r`n command = deploy-nothing.cmd"
    Add-Content deploy-nothing.cmd "echo Deploying nothing."
    git add -A
    git commit -m "Add deployment script."
    git push

Note: This no longer does any deployment! It **only** echos "Hello World."

# Local: Add Unit Tests

* Open MyWebApp.sln in Visual Studio
* Right click the solution > Add > New Project > Visual C# > Test > MyWebApp.Test
* Resultant directory structure

[Directory Structure]

    SillyFrogs
        .git
        .gitignore
        MyWebApp.sln
        MyWebApp.Test
            MyWebApp.Test.csproj
        MyWebApp
            MyWebApp.csproj
    
* Add, commit, and push

[Git]

    git add -A
    git commit -m "Add unit tests."
    git push

* The unit tests will not build nor run yet. 

# Integrate Unit Tests into Deployment

* Edit the Kudu deploy.cmd file.

[Kudu Script]

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
    git commit -m "Run unit tests on deployment."
    git push

# Notes

* By using Nuget, we can keep *most* binaries out of the repository.
* Be sure to add a .gitignore file with bin/ and obj/
* If you want to run \Release\ tests, then build with /property:Configuration=Release
* Kudu builds into a temporary folder and then syncs the result if the build and tests succeed.
* We can switch staging and master with a single click of Swap from the Web App dashboard.

# Possible Additions

* It's a good list. Maybe you can add some ARM based deployments. Also GitHub Deploy Button is good. From [David Ebbo]( https://twitter.com/davidebbo/status/601607544302243841)
