
# Remote

* Setup a remote repository. 
* Copy it's uri.
* e.g. `git@github.com:shaunluttin/DeployWebApp2Azure.git`

# Local

* Create a new directory. 
* Initiate git to speak to the remote.

    New-Item -type dir DeployWebApp2Azure
    cd DeployWebApp2Azure
    git init
    git remote add origin <uri>
    git pull origin master
    git add -A
    git commit -m "Initial commit."
    git push --set-upstream origin master


