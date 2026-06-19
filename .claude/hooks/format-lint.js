#!/usr/bin/env node

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

async function readStdinJson() {
  const chunks = [];

  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }

  const raw = Buffer.concat(chunks).toString().trim();

  if (!raw) {
    return {};
  }

  return JSON.parse(raw);
}

async function main() {
  const input = await readStdinJson();
  const filePath = input.tool_input?.file_path;

  if (!filePath) {
    process.exit(0);
  }

  const projectRoot = process.cwd();
  const hasPackageJson = fs.existsSync(path.join(projectRoot, 'package.json'));
  const pnpmExists =
    spawnSync('pnpm', ['--version'], {
      stdio: 'ignore',
      shell: process.platform === 'win32',
    }).status === 0;

  if (!hasPackageJson || !pnpmExists) {
    process.exit(0);
  }

  const isFormatTarget =
    /\.(js|jsx|ts|tsx|mjs|cjs|json|css|scss|html|md|mdx|yaml|yml|svelte)$/i.test(
      filePath,
    );
  const isLintTarget = /\.(js|jsx|ts|tsx|svelte)$/i.test(filePath);

  const options = {
    stdio: 'inherit',
    shell: process.platform === 'win32',
  };

  if (isFormatTarget) {
    spawnSync('pnpm', ['prettier', '--write', filePath], options);
  }

  if (isLintTarget) {
    spawnSync('pnpm', ['eslint', '--fix', filePath], options);
  }

  // 不阻塞 Claude Hook；Prettier 失敗也讓掛鉤正常結束
  process.exit(0);
}

main().catch((error) => {
  console.error(`[format-lint Hook Error] ${error.message}`);
  process.exit(0);
});
