# NVM for Windows - Node Version Manager

This script installs [NVM for Windows](https://github.com/coreybutler/nvm-windows) and automatically installs the latest LTS version of Node.js.

## What's Installed

- **NVM for Windows**: A Node.js version manager for Windows
- **Node.js LTS**: The latest Long-Term Support version of Node.js
- **npm**: Node Package Manager (included with Node.js)

## Common Commands

### Managing Node.js Versions

```powershell
# List all installed Node.js versions
nvm list

# List all available Node.js versions for download
nvm list available

# Install a specific Node.js version
nvm install 20.10.0

# Install the latest LTS version
nvm install lts

# Install the latest current version
nvm install latest

# Uninstall a specific version
nvm uninstall 18.17.0
```

### Switching Between Versions

```powershell
# Use a specific installed version
nvm use 20.10.0

# Use the LTS version
nvm use lts

# Use the latest installed version
nvm use latest
```

### Checking Versions

```powershell
# Check NVM version
nvm version

# Check current Node.js version
node --version

# Check npm version
npm --version

# Show which Node.js version is currently active
nvm current
```

## Quick Start Examples

### Create a New Node.js Project

```powershell
# Create a new directory
mkdir my-project
cd my-project

# Initialize a new Node.js project
npm init -y

# Install dependencies
npm install express

# Create a simple server
@"
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello World!');
});

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
"@ | Out-File -FilePath index.js -Encoding UTF8

# Run the server
node index.js
```

### Install Global npm Packages

```powershell
# Install commonly used global packages
npm install -g typescript
npm install -g ts-node
npm install -g nodemon
npm install -g yarn
npm install -g pnpm

# List globally installed packages
npm list -g --depth=0
```

## Troubleshooting

### Node or npm commands not found

If `node` or `npm` commands are not recognized after installation:

1. Close and reopen your terminal
2. If that doesn't work, restart your system
3. Verify NVM is in PATH: `echo $env:PATH`
4. Check NVM installation: `nvm list`

### Switching versions doesn't work

Make sure to run your terminal as Administrator when using `nvm use` commands, as NVM needs elevated permissions to create symlinks.

### Installing a specific version fails

```powershell
# Check available versions
nvm list available

# Try installing with full version number
nvm install 20.10.0
```

### Multiple Node.js installations conflict

If you had Node.js installed before NVM:

1. Uninstall the previous Node.js installation
2. Restart your terminal
3. Use NVM to reinstall Node.js: `nvm install lts`

## Configuration

NVM for Windows stores its configuration in:

- **Installation Directory**: `C:\Users\<username>\AppData\Roaming\nvm`
- **Node.js Versions**: `C:\Users\<username>\AppData\Roaming\nvm\v*`
- **Settings File**: `C:\Users\<username>\AppData\Roaming\nvm\settings.txt`

## Additional Resources

- [NVM for Windows GitHub](https://github.com/coreybutler/nvm-windows)
- [Node.js Official Website](https://nodejs.org/)
- [npm Documentation](https://docs.npmjs.com/)
- [Node.js LTS Release Schedule](https://nodejs.org/en/about/releases/)

## Tips

- Always use LTS versions for production applications
- Use `.nvmrc` files in your projects to specify Node.js versions:
  ```
  echo "20.10.0" > .nvmrc
  nvm use
  ```
- Keep Node.js and npm updated for security and features
- Use `npm outdated` to check for package updates
