
:: The `@` supresses echoing of a line.
:: THE `%%` accesses environmental variables.

@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

echo "My Custom Deployment Script"

:: `where` is a command line utility (where.exe)
:: its looking for node
:: `2>nul` redirects the error message to nul
:: `>nul` redirects the command output to nul

where node 2>nul >nul

:: Error level zero means the `where` search was successful.

IF %ERRORLEVEL% NEQ 0 (

    echo Missing node.js
    goto error
)

:: Expand variables at execution time not parse time.
:: Expansion basically means replacing the variable with its value.
:: Obversely, if we expand at parse time, then at expansion time, we will execute the result.

setlocal enabledelayedexpansion

:: `%~dp0%` expands to the path of the batch file.
:: We're going back one directory and then into the artifacts folder.

echo %~dp0%

:: `SET` Sets an environmental variable for the session.
:: `IF NOT DEFINED` Checks one for existance

SET ARTIFACTS=%~dp0%..\artifacts

:: Note that within parentheses, blank lines are forbidden between statements.

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
   SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot

)

IF NOT DEFINED NEXT_MANIFEST_PATH (
   SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

    IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
        SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest

    )
)

IF NOT DEFINED KUDU_SYNC_CMD (
    :: `call` lets us call one batch file from another
    echo Installing Kudu Sync with node package manager
    call npm install kudusync -g silent
    :: We're using `!!` to access the enviromental variable.
    :: That means we evaluate the variable at execution time not parse time.
    echo Parse time %ERRORLEVEL%
    echo Execution time !ERRORLEVEL!    
    IF !ERRORLEVEL! NEQ 0 goto error

    SET KUDU_SYNC_CMD=%appdata%\npm\kuduSync.cmd
)

IF NOT DEFINED DEPLOYMENT_TEMP (
    SET DEPLOYMENT_TEMP=%temp%\___deployTemp%random%
    SET CLEAN_LOCAL_DEPLOYMENT_TEMP=true
)

IF DEFINED CLEAN_LOCAL_DEPLOYMENT_TEMP (
    IF EXIST "%DEPLOYMENT_TEMP%" rd /s /q "%DEPLOYMENT_TEMP%"
    mkdir "%DEPLOYMENT_TEMP%"
)

echo %DEPLOYMENT_TEMP%

IF NOT DEFINED MSBUILD_PATH (
    SET MSBUILD_PATH=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\msbuild.exe
)

::
::
:: Skip ASP.NET application deployment, for now.
:: Just focus on Kudu Sync, to find out whether we can avoid overwriting.

echo Run Kudu Sync
echo TODO

:error
echo There was an error.
