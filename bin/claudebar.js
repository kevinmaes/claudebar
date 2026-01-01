#!/usr/bin/env node

import { spawn } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readFileSync } from 'node:fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = join(__dirname, '..');

const getVersion = () => {
  const pkg = JSON.parse(readFileSync(join(rootDir, 'package.json'), 'utf8'));
  return pkg.version;
};

const showHelp = () => {
  console.log(`
claudebar - A bash statusline for Claude Code

Usage:
  npx claudebar [command]

Commands:
  install      Install claudebar statusline (default)
  uninstall    Remove claudebar statusline
  update       Update to the latest version

Options:
  --version, -v    Show version number
  --help, -h       Show this help message

Examples:
  npx claudebar            # Install (default)
  npx claudebar update     # Update to latest
  npx claudebar uninstall  # Remove

Documentation: https://github.com/kevinmaes/claudebar
`);
};

const runScript = (scriptName) => {
  const scriptPath = join(rootDir, scriptName);

  // Check for bash availability
  const shell = process.platform === 'win32' ? 'bash' : '/bin/bash';

  const child = spawn(shell, [scriptPath], {
    stdio: 'inherit',
    cwd: rootDir,
  });

  child.on('error', (err) => {
    if (err.code === 'ENOENT') {
      console.error('Error: bash is required to run claudebar.');
      console.error('On Windows, please use WSL or Git Bash.');
      process.exit(1);
    }
    console.error(`Error: ${err.message}`);
    process.exit(1);
  });

  child.on('close', (code) => {
    process.exit(code ?? 0);
  });
};

const commands = {
  install: () => runScript('install.sh'),
  uninstall: () => runScript('uninstall.sh'),
  update: () => runScript('update.sh'),
};

const main = () => {
  const args = process.argv.slice(2);
  const command = args[0];

  if (command === '--help' || command === '-h') {
    showHelp();
    process.exit(0);
  }

  if (command === '--version' || command === '-v') {
    console.log(`claudebar v${getVersion()}`);
    process.exit(0);
  }

  // Default to install if no command given
  const handler = commands[command] ?? commands.install;
  if (command && !commands[command]) {
    console.error(`Unknown command: ${command}`);
    console.error('Run "npx claudebar --help" for usage.');
    process.exit(1);
  }

  handler();
};

main();
