# split-scope-configs（重構）

## 為什麼做

目前 `.claude/` 把兩種性質的設定混在一起：

- **機器層級（User Scope）**：`block-dangerous.js` 危險指令攔截、PowerShell 環境偏好、`deny: Bash`、`CLAUDE.md` 的 shell 規則 —— 這些跟專案無關，應該對該帳號所有專案生效。
- **專案層級（Project Scope）**：`format-lint.js` 的 PostToolUse hook 依賴專案的 `package.json` / pnpm / Prettier / ESLint 設定，只在有前端工具鏈的 repo 才有意義。

混在一份 `settings.json` 裡，導致無法乾淨地「只把 User Scope 同步到 `%USERPROFILE%\.claude`」，也讓其他 repo 想沿用專案層級 hook 時只能整包複製。

另一份外部參考設定只處理 User Scope，且綁了公司內部專屬規則，不適合直接照搬。

## 要改什麼

- 在 repo 內建立兩個獨立的 scope 目錄，各自帶一份 `.claude/`：
  - `user/.claude/` —— User Scope：`settings.json`（env / shell / permissions / PreToolUse: block-dangerous）、`CLAUDE.md`、`hooks/block-dangerous.js`、`agents/`
  - `project/.claude/` —— Project Scope 範本：`settings.json`（只有 PostToolUse: format-lint）、`hooks/format-lint.js`
- 整個移除 `.claude/commands/`（commit / commit-push / commit-push-pr / review / test）：這些流程已由其他 repo 以 skill 形式維護，本 repo 不再重複。
- `CLAUDE.md` 拆分：把通用 PowerShell 規則放進 `user/.claude/CLAUDE.md`；不引入任何公司內部專屬規則段落。
- 新增同步腳本 `scripts/sync-claude-scope.ps1`：
  - `-Scope User`：把 `user/.claude/` 內容同步到 `%USERPROFILE%\.claude`（可用 `-UserScopePath` 覆寫目標），自動改寫 hook 腳本的絕對路徑，支援 `-WhatIf` / `-Diff` / `-Force`（覆蓋前備份）/ `-Uninstall`，並寫 manifest 記錄受管理檔案與 SHA-256。
  - `-Scope Project -TargetRepo <path>`：把 `project/.claude/` 疊進指定 repo 的 `.claude/`。
- repo 根目錄自身的 `.claude/` 與 `CLAUDE.md`：從 git 移除；`.claude/` 改為 `.gitignore` 忽略，本 repo 開發時用 `sync-claude-scope.ps1 -Scope Project -TargetRepo .` 產生。
- 更新 `README.md` 說明新的雙 scope 結構與 `scripts/sync-claude-scope.ps1` 用法。

## 影響範圍

新增：

- `user/.claude/settings.json`、`user/.claude/CLAUDE.md`、`user/.claude/hooks/block-dangerous.js`
- `user/.claude/agents/generic-test-quality-reviewer.md`（由原 `test-quality-reviewer.md` 改名，內容換為語言/框架無關版，`name` 同步改為 `generic-test-quality-reviewer`）
- `project/.claude/settings.json`、`project/.claude/hooks/format-lint.js`
- `scripts/sync-claude-scope.ps1`

修改：

- `README.md`（結構與用法說明）
- `.gitignore` → 新增 `/.claude/`

移動 / 刪除：

- `.claude/settings.json` → 內容拆進 `user/.claude/settings.json`（User Scope 部分）與 `project/.claude/settings.json`（format-lint）；原檔隨根 `.claude/` 一併移除
- `.claude/hooks/block-dangerous.js` → `user/.claude/hooks/`
- `.claude/hooks/format-lint.js` → `project/.claude/hooks/`
- `.claude/agents/test-quality-reviewer.md` → `user/.claude/agents/generic-test-quality-reviewer.md`（改名 + 換內容）
- `.claude/commands/` → 整個刪除（已由其他 repo 的 skill 取代）
- repo 根目錄 `.claude/` → 從 git 移除並改為 `.gitignore` 忽略；本機開發用 `sync-claude-scope.ps1 -Scope Project -TargetRepo .` 產生
- repo 根目錄 `CLAUDE.md` → 移除（與 `user/.claude/CLAUDE.md` 完全重複的殘留副本）
