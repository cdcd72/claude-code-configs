#!/usr/bin/env node

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

function isDangerousCommand(command) {
  const rules = [
    /\brm\s+(-[^\s]*r[^\s]*f|-.[^\s]*f[^\s]*r)\b/, // rm -rf / rm -fr
    /\brm\s+-r\s+\/\b/, // rm -r /
    /\brm\s+(-[^\s]*r[^\s]*f|-.[^\s]*f[^\s]*r)\s+\/\b/, // rm -rf /
    /\bsudo\s+rm\s+(-[^\s]*r[^\s]*f|-.[^\s]*f[^\s]*r)\b/,
    /\bdd\s+.*\bof=\/dev\//,
    /\bmkfs(\.\w+)?\b/,
    /\bshutdown\b/,
    /\breboot\b/,
  ];

  return rules.some((rule) => rule.test(command));
}

async function main() {
  const input = await readStdinJson();
  const command = input.tool_input?.command;

  if (!command) {
    process.exit(0);
  }

  if (isDangerousCommand(command)) {
    console.error(`禁止執行危險指令：${command}`);
    process.exit(2); // exit 2 = 阻止 Claude 執行該操作
  }

  process.exit(0);
}

main().catch((error) => {
  console.error(`[block-dangerous Hook Error] ${error.message}`);
  process.exit(0);
});
