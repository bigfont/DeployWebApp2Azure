These are the notes from a talk given at the [Azure Dev Camp in Victoria](http://www.meetup.com/Victoria-App-Developer/events/221644488/) on 25 April 2015. They are a work in progress. If you see something that doesn't seem quite right, let me know, via an email, a pull request, or a tweet to @dicshaunary. I'll update the demo and its notes if appropriate. 

We'll present this again on [23 May in Vancouver](http://www.meetup.com/Vancouver-Windows-Platform-Developers-Group/events/221830707/).

# Overview

Use Visual Studio, Git, and Azure Web Apps to quickly test out development scenarios or do continuous integration over the long term. This talk will cover: 

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

* A was to create a remote Git repository (e.g. a GitHub account.) 
* A Microsoft Azure account (free and with an automatic spending cap of zero.)
* Git installed locally (msysgit.github.io)
* For the purpose of this demo
  * PowerShell (only for the purposes of this demo.)
  * Node
  * Azure Command Line Interface

# Remote: Setup a Git Repo

This is the remote Git repository that stores our source code. [github.com]() has detailed instructions.

* Setup a remote repository with a README.md
* Copy it's uri.
* For the demo we'll use `git@github.com:bigfont/Deploy2Azure.git`

# Local: Setup Git

The is our development environment.

[PowerShell] Create a new directory with a `.gitignore` file.

    New-Item -type dir Deploy2Azure
    cd Deploy2Azure
    New-Item -type f .gitignore
    Add-Content .gitignore ("bin/" + "`n" + "obj/" + "`n")
    
[Git] Initiate git to speak to the remote with a `master` and `staging` branch.

    git init
    git remote add origin git@github.com:bigfont/Deploy2Azure.git
    # git pull origin master
    git add -A
    git commit -m "Initial commit."
    git push --set-upstream origin master
    git checkout -b staging
    git push --set-upstream origin staging

# Azure: Create a Web App

This is where we're hosting our Web App.

There are both UI gestures to do this or we can use the Azure Command Line Interface. 

[CMD] Create a new MS Azure Web App

    npm install azure-cli -g
    azure account download
    azure account import <file>
    azure site create --location "West US" Deploy2Azure

We'll do the rest using the MS Azure UI thought the `azure-cli` works too.

* Go to the Web App's Dashboard 
    * Setup deployment from source control
    * GitHub
    * Repository Name > `Deploy2Azure`
    * Branch to Deploy > `master`

* Return to the Azure Dashboard
    * Add a new deployment slot named `staging`
    * Don't clone
    * (I believe we need to be in a non-free tier to do this.)

* Go to Azure Dashboard for the *staging deployment slot*
    * Setup deployment from source control
    * GitHub
    * RepositoryName > `Deploy2Azure`
    * Branch to Deploy > `staging`

We can view the details of the deployments slot with this command. 

    azure site show deployapp2azure

# Create ASP.NET Web Application

* Open Visual Studio
* New a new Empty Web App (New Project > Templates > Visual C# > Web > ASP.NET Web Application)
* Resultant directory structure

[Directory Structure]

    DeployWebApp2Azure
        .git
        .gitignore
        MyWebApp.sln
        MyWebApp
            MyWebApp.csproj
            
* Add, Commit, Push (we're on staging right now).

[Git]

    git add -A
    git commit -m "Create empty ASP.NET Web Application"
    git push

* Remember --> Azure will deploy this :-)

# Add Unit Test 

* Open MyWebApp.sln in Visual Studio
* Right click the solution > Add > New Project > Visual C# > Test > MyWebApp.Test
* Resultant directory structure

[Directory Structure]

    Deploy2Azure
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

* Install Azure Command Line Interface
* Create a custom deployment script

[Command Line]

    npm install azure-cli -g
    azure site deploymentscript --aspWAP MyWebApp\MyWebApp.csproj -s MyWebApp.sln

* Be careful with your file paths!
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
