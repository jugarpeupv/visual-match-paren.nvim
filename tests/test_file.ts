import { expect } from 'chai';
import { spawn } from 'child_process';
import { PACKAGE_NAMES } from '../../dependencies';
import { ServiceInitializer } from '../shared/services/services-initializer';
import { getNpmPackageName } from '../shared/utils/utils';
import { readFileSync } from 'fs';

export async function generateNxWorkspace(options: {
  nxVersion: string;
  outputPath: string;
  workspaceName: string;
  defaultMainBranch: string;
  skipGit?: boolean;
}) {
  ServiceInitializer.logger.info('Generating NX workspace');
  let errorBuffer = '';
  const output = spawn(
    'npx',
    [
      getNpmPackageName({
        name: PACKAGE_NAMES.createNxWorkspace,
        version: options.nxVersion,
      }),
      options.workspaceName,
      '--preset=apps',
      '--nxCloud=skip',
      '--interactive=false',
      '--defaultBase',
      options.defaultMainBranch,
      `--skipGit=${options.skipGit ? 'true' : 'false'}`,
    ],
    {
      shell: true,
      env: {
        ...process.env,
        NX_ADD_PLUGINS: 'false',
      },
      stdio: ['ignore', 'pipe', 'pipe'],
      cwd: options.outputPath,
    },
  );

  output.stdout.on('data', (data) => {
    const message = data.toString();
    ServiceInitializer.logger.info(message);
    checkForNpmInstallationLogErrors(message);
  });
  output.stderr.on('data', (data) => {
    const message = data.toString();
    ServiceInitializer.logger.info(message);
    checkForNpmInstallationLogErrors(message);
    errorBuffer += data.toString();
  });

  await new Promise((resolve) => {
    output.on('close', (code) => {
      expect(code, `Couldn't generate workspace: ${errorBuffer}`).equals(0);
      resolve(code);
    });
  });
  ServiceInitializer.logger.info('NX workspace generated');
}

function checkForNpmInstallationLogErrors(message: string) {
  // Check if the message contains 'Log file'
  const logFileMatch = message.match(/Log file:\s*(\/[^\s]+)/);
  if (logFileMatch) {
    const logFilePath = logFileMatch[1]; // Extract the log file path
    try {
      const logContent = readFileSync(logFilePath, 'utf-8'); // Read the log file content
      ServiceInitializer.logger.error(`Content of error log file (${logFilePath}):\n${logContent}`);
    } catch (err) {
      if (err instanceof Error) {
        ServiceInitializer.logger.error(
          `Failed to read log file at ${logFilePath}:`,
          err.message,
        );
      } else {
        ServiceInitializer.logger.error(
          `An unknown error occurred while reading the log file at ${logFilePath}.`,
        );
      }
    }
  }
}
