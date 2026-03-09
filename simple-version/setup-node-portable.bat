@echo off
echo 🚀 Setting up Portable Node.js (No Admin Required)
echo ================================================

:: Create directories
mkdir "%USERPROFILE%\Desktop\node-portable" 2>nul
cd "%USERPROFILE%\Desktop\node-portable"

:: Download Node.js portable
echo 📥 Downloading Node.js portable...
powershell -Command "& {Invoke-WebRequest -Uri 'https://nodejs.org/dist/v18.17.0/node-v18.17.0-win-x64.zip' -OutFile 'node-portable.zip'}"

:: Extract
echo 📦 Extracting Node.js...
powershell -Command "& {Expand-Archive -Path 'node-portable.zip' -DestinationPath '.' -Force}"

:: Move to correct location
move "node-v18.17.0-win-x64\*" "." 2>nul
rmdir "node-v18.17.0-win-x64" 2>nul

:: Create batch file to run npm
echo @echo off > run-npm.bat
echo set PATH=%~dp0;%~dp0node_modules\.bin;%PATH% >> run-npm.bat
echo npm %%* >> run-npm.bat

:: Create batch file to run node
echo @echo off > run-node.bat
echo set PATH=%~dp0;%~dp0node_modules\.bin;%PATH% >> run-node.bat
echo node %%* >> run-node.bat

echo ✅ Portable Node.js setup complete!
echo.
echo 📁 Location: %USERPROFILE%\Desktop\node-portable
echo.
echo 🚀 To use npm:
echo    cd "%USERPROFILE%\Desktop\node-portable"
echo    run-npm.bat install
echo.
echo 🚀 To use node:
echo    cd "%USERPROFILE%\Desktop\node-portable"
echo    run-node.bat your-script.js
echo.
pause
