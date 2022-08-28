@echo off

rem escape double quotes
set _argv=%*
set _argv=%_argv:"=\"%
rem powershell -c echo %_argv%
powershell -c Invoke-Clojure %_argv%