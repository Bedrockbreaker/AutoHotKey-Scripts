@echo off
title Java Version Switcher

:menu
cls
echo Current Java version:
java -version
echo.
echo Choose new version:
echo [1] JRE 1.8.0_202
echo [2] JDK 1.8.0_202
echo [3] JRE 21.0.2.13
echo [x] Cancel
echo.
set /p choice=

if "%choice%"=="1" (
	call :setJavaHome "C:\Program Files\Java\jre1.8.0_202"
	goto :eof
)
if "%choice%"=="2" (
	call :setJavaHome "C:\Program Files\Java\jdk1.8.0_202"
	goto :eof
)
if "%choice%"=="3" (
	call :setJavaHome "C:\Program Files\Eclipse Adoptium\jre-21.0.2.13-hotspot"
	goto :eof
)
if "%choice%"=="x" (
	goto :eof
)

echo Invalid choice.
pause
goto menu

:setJavaHome
setx JAVA_HOME "%~1" /m
set "JAVA_HOME=%~1"
set "Path=%JAVA_HOME%\bin;%Path%"
echo Java version switched successfully.
java -version
pause