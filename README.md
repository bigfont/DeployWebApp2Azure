These are the notes from a talk given at the [Azure Dev Camp in Victoria](http://www.meetup.com/Victoria-App-Developer/events/221644488/) on 25 April 2015. They are a work in progress. If you see something that doesn't seem quite right, let me know, via an email, a pull request, or a tweet to @dicshaunary. I'll update the demo and its notes if appropriate.

Use Visual Studio, Git Deploy, and Azure Web Apps to quickly test out development scenarios or do continiuous integration over the long term. This talk will cover: 

* NuGet in Visual Studio to keep assemblies out of version control
* Git to commit locally and then push to a remote (in the demo, we'll use GitHub) 
    * we could also use Visual Studio Online 
* Azure Web Apps that connect to GitHub (or another remote) for deployment from version control

This lightweight workflow allows quick scenario testing in which we spin up an Azure Web App and tear it down when we've finished. For longer term continuous integration and testing scenarios, we'll also cover:

* multiple deployment slots in Azure Web Apps that connect to multiple Git branches
* Kudu deployment scripts that tell Azure to run our unit tests and only Sync builds that pass
* the web-based service control manager for Web Apps (at mydomain.scm.azurewebsites.net)

In short, well cover:

    Local --> Remote --> Azure

This is the LIVE result (it isn't pretty - it's scaffolding):

* http://deploywebapp2azure.azurewebsites.net/
* http://deploywebapp2azure-staging.azurewebsites.net/

# Remote

This is the remote repository that stores our source code.

* Setup a remote repository. 
* Copy it's uri.
* e.g. `git@github.com:shaunluttin/DeployWebApp2Azure.git`

# Local

The is our development environment.

* Create a new directory. 
* Initiate git to speak to the remote.

[PowerShell]

    New-Item -type dir DeployWebApp2Azure
    cd DeployWebApp2Azure
    New-Item -type f .gitignore
    Add-Content .gitignore ("bin/" + "`n" + "obj/" + "`n")
    
[Git]

    git init
    git remote add origin <uri>
    git pull origin master
    git add -A
    git commit -m "Initial commit."
    git push --set-upstream origin master
    git checkout -b staging
    git push --set-upstream-to=origin/staging staging

# Azure

This is where we're hosting our Web App.

* Create new Azure Web App

* Go to its Dashboard 
    * Setup deployment from source control
    * GitHub
    * Repository Name > `DeployWebApp2Azure`
    * Branch to Deploy > `master`

* Return to the Azure Dashboard
    * Add a new deployment slot named `staging`
    * Don't clone

* Go to Azure Dashboard for the *staging deployment slot*
    * Setup deployment from source control
    * GitHub
    * RepositoryName > `DeployWebApp2Azure`
    * Branch to Deploy > `staging`

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

    DeployWebApp2Azure
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
