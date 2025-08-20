# Setup Guide for LA Transit App

## Prerequisites Installation

### 1. Install Node.js

Since Node.js is not currently installed on your system, you'll need to install it first:

1. **Download Node.js**:
   - Go to [https://nodejs.org/](https://nodejs.org/)
   - Download the LTS (Long Term Support) version for Windows
   - Choose the Windows Installer (.msi) file

2. **Install Node.js**:
   - Run the downloaded .msi file
   - Follow the installation wizard
   - Make sure to check "Add to PATH" during installation
   - Complete the installation

3. **Verify Installation**:
   - Open a new Command Prompt or PowerShell window
   - Run: `node --version`
   - Run: `npm --version`
   - Both commands should return version numbers

### 2. Alternative: Use Node Version Manager (nvm) for Windows

If you prefer to use nvm for managing Node.js versions:

1. **Install nvm-windows**:
   - Go to [https://github.com/coreybutler/nvm-windows/releases](https://github.com/coreybutler/nvm-windows/releases)
   - Download the latest `nvm-setup.exe`
   - Run the installer

2. **Install Node.js via nvm**:
   ```bash
   nvm install latest
   nvm use latest
   ```

## Running the LA Transit App

Once Node.js is installed:

1. **Open Command Prompt or PowerShell** in the project directory
2. **Install dependencies**:
   ```bash
   npm install
   ```
3. **Start the development server**:
   ```bash
   npm start
   ```
4. **Open your browser** and go to `http://localhost:3000`

## Troubleshooting

### Common Issues:

1. **"npm is not recognized"**:
   - Restart your terminal/command prompt after installing Node.js
   - Make sure Node.js was added to PATH during installation

2. **Port 3000 already in use**:
   - The app will automatically suggest using a different port
   - Or manually kill the process using port 3000

3. **Permission errors**:
   - Run Command Prompt as Administrator
   - Or use a different directory for the project

### Getting Help:

- Check the [Node.js documentation](https://nodejs.org/en/docs/)
- Visit the [npm documentation](https://docs.npmjs.com/)
- Review the project's README.md for more details

## Quick Start (Alternative)

If you want to see the app immediately without installing Node.js, you can:

1. Use the simple HTML version in the `simple-version` folder
2. Open `index.html` directly in your browser
3. This provides a basic version of the transit app without the full React features 