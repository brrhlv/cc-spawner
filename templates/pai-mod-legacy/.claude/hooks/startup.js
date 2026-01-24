#!/usr/bin/env node

/**
 * PAI Mod - Minimal Startup Hook
 * Initializes session without profile system
 */

const { existsSync } = require('fs');
const { join } = require('path');
const { execSync } = require('child_process');

async function run() {
  console.log('\n🚀 PAI Mod - Initializing session...');

  const HOME = process.env.HOME || process.env.USERPROFILE || '';

  // System checks
  console.log('\n🔍 Running system checks...');

  const checks = [
    { name: 'Node.js', cmd: 'node --version' },
    { name: 'Git', cmd: 'git --version' }
  ];

  for (const check of checks) {
    try {
      execSync(check.cmd, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
      console.log(`  ✅ ${check.name}: OK`);
    } catch {
      console.log(`  ❌ ${check.name}: Not available`);
    }
  }

  // Check for optional directories
  console.log('\n📁 Checking PAI directories...');

  const dirs = ['skills', 'agents', 'hooks', 'bridge'];
  for (const dir of dirs) {
    const path = join(HOME, '.claude', dir);
    if (existsSync(path)) {
      console.log(`  ✓ ${dir}/`);
    } else {
      console.log(`  - ${dir}/ (not configured)`);
    }
  }

  console.log('\n✅ Session initialization complete!\n');
}

module.exports = { run };

if (require.main === module) {
  run().catch(console.error);
}
