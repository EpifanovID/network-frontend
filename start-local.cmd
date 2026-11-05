@echo off
setlocal
cd /d "%~dp0"
echo Starting the local application. Internet is not required.
echo Keep this window open. After startup, open http://127.0.0.1:4173/
call npm start
if errorlevel 1 (
    echo Startup failed. Check the message above and docs/LOCAL_RUN.md.
    pause
)
