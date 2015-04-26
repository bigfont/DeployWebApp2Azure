
# Remote

* Setup a remote repository. 
* Copy it's uri.
* e.g. `git@github.com:shaunluttin/DeployWebApp2Azure.git`

# Local

* Create a new directory. 
* Initiate git to speak to the remote.

[PowerShell]

    New-Item -type dir DeployWebApp2Azure
    cd DeployWebApp2Azure
    New-Item -type f .gitignore
    Add-Content .gitignore ("bin/" + "`n" + "obj/" + "`n")
    git init
    git remote add origin <uri>
    git pull origin master
    git add -A
    git commit -m "Initial commit."
    git push --set-upstream origin master
    git checkout -b staging
    git push --set-upstream-to=origin/staging staging

# Azure

* Create new Azure Web App

* Go to its Dashboard 
    * Setup deployment from source control
    * GitHub
    * Repository Name > DeployWebApp2Azure
    * Branch to Deploy > master

* Go to Azure Dashboard
    * Add a new deployment slot
    * staging 
    * Don't clone

* Go to Azure Dashboard for staging deployment
    * Setup deployment from source control
    * GitHub
    * RepositoryName > DeployWebApp2Azure
    * Branch to Deploy > staging

# Create ASP.NET Web Application

* Open Visual Studio
* New a new Empty Web App (New Project > Templates > Visual C# > Web > ASP.NET Web Application)
* Resultant directory structure

    DeployWebApp2Azure
        .git
        .gitignore
        MyWebApp.sln
        MyWebApp
            MyWebApp.csproj
            
* Add, Commit, Push (we're on staging right now).

[PowerShell]

    git add -A
    git commit -m "Create empty ASP.NET Web Application"
    git push

* Remember --> Azure will deploy this :-)

# Add Unit Test 

* Open MyWebApp.sln in Visual Studio
* Right click the solution > Add > New Project > Visual C# > Test > MyWebApp.Test
* Resultant directory structure

    DeployWebApp2Azure
        .git
        .gitignore
        MyWebApp.sln
        MyWebApp.Test
            MyWebApp.Text.csproj
        MyWebApp
            MyWebApp.csproj
    
* Add, commit, and push

    git add -A
    git commit -m "Add unit tests."
    git push

* The unit tests will not build nor run yet. 

# Integrate Unit Tests into Deployment

* Install Azure Command Line Interface
* Create a custom deployment script

    npm install azure-cli -g
    azure site deploymentscript --aspWAP MyWebApp\MyWebApp.csproj -s MyWebApp.sln

* Be careful with your file paths!
* Edit the Kudu deploy.cmd file.

    :: Custom 1. Build test project
    echo Building test project
    "%MSBUILD_PATH%" "%DEPLOYMENT_SOURCE%\MyWebApp.Tests\MyWebApp.Tests.csproj"
    IF !ERRORLEVEL! NEQ 0 goto error

    :: Custom 2. Run tests
    echo Running tests
    vstest.console.exe "%DEPLOYMENT_SOURCE%\MvcTest.Tests\bin\Debug\MvcTest.Tests.dll"
    IF !ERRORLEVEL! NEQ 0 goto error

* Add, commit, and push

    git add -A
    git commit -m "Run unit tests on deployment."
    git push

# Notes

* By using Nuget, we can keep *most* binaries out of the repository.
* Be sure to add a .gitignore file with bin/ and obj/
* If you want to run \Release\ tests, then build with /property:Configuration=Release
