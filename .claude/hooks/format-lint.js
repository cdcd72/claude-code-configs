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

  const runOptions = {
    shell: process.platform === 'win32',
  };

  // Prettier：純粹「盡力而為」，格式化失敗不阻斷、不回報給 Claude
  if (isFormatTarget) {
    spawnSync('pnpm', ['prettier', '--write', filePath], {
      ...runOptions,
      stdio: 'ignore',
    });
  }

  // ESLint：先 --fix，再用 --format json 檢查「修不掉」的殘留 error
  if (isLintTarget) {
    const eslintResult = spawnSync(
      'pnpm',
      ['eslint', '--fix', '--format', 'json', filePath],
      { ...runOptions, encoding: 'utf-8' },
    );

    let lintReports = [];
    try {
      lintReports = JSON.parse(eslintResult.stdout || '[]');
    } catch {
      // eslint 本身跑不起來（設定錯誤、套件缺失等），只記錄，不當成需要 Claude 處理的 lint error
      if (eslintResult.stderr) {
        console.error(`[format-lint] eslint 執行異常：${eslintResult.stderr.slice(0, 500)}`);
      }
      process.exit(0);
    }

    const fileReport = lintReports.find((r) => r.filePath === filePath) ?? lintReports[0];

    if (fileReport && fileReport.errorCount > 0) {
      const summary = fileReport.messages
        .filter((m) => m.severity === 2) // 2 = error, 1 = warning
        .slice(0, 10)
        .map((m) => `  L${m.line}:${m.column} [${m.ruleId ?? 'unknown-rule'}] ${m.message}`)
        .join('\n');

      console.error(
        `[format-lint] ${path.basename(filePath)} 仍有 ${fileReport.errorCount} 個 ESLint 無法自動修復的錯誤：\n${summary}\n請修正這些問題。`,
      );

      process.exit(2);
    }

    // 只剩 warning（或完全沒問題）：不 escalate
  }

  process.exit(0);
}

main().catch((error) => {
  console.error(`[format-lint Hook Error] ${error.message}`);
  process.exit(0);
});
