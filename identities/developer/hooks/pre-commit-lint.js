/**
 * Pre-commit hook for linting staged files
 * Runs ESLint/Prettier on staged .js/.ts files
 */

const { execSync } = require('child_process');
const fs = require('fs');

// Get staged files
function getStagedFiles() {
  try {
    const result = execSync('git diff --cached --name-only --diff-filter=ACM', { encoding: 'utf-8' });
    return result.split('\n').filter(f => f.match(/\.(js|ts|jsx|tsx)$/));
  } catch {
    return [];
  }
}

// Run linter on files
function lintFiles(files) {
  if (files.length === 0) return true;

  try {
    execSync(`npx eslint ${files.join(' ')} --fix`, { stdio: 'inherit' });
    // Re-add fixed files
    execSync(`git add ${files.join(' ')}`);
    return true;
  } catch (error) {
    console.error('Linting failed. Fix errors before committing.');
    return false;
  }
}

const files = getStagedFiles();
if (!lintFiles(files)) {
  process.exit(1);
}
