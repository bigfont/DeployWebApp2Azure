echo "My Custom Deployment Script"

:: The @ supresses echoing of a line.
:: THE %% accesses environmental variables.

echo %SCM_TRACE_LEVEL%

@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off
