@echo off
setlocal
if not defined JAVA_HOME set "JAVA_HOME=C:\Program Files\Java\jdk-21"
if exist "%~dp0.tools\apache-maven-3.9.11\bin\mvn.cmd" goto run
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-maven.ps1"
if errorlevel 1 exit /b 1
:run
call "%~dp0.tools\apache-maven-3.9.11\bin\mvn.cmd" -f "%~dp0pom.xml" %*
