# Claude Code 設定

集中管理 Claude Code 的自訂設定。依「作用範圍（scope）」分成兩份，各自帶一個獨立的 `.claude/`；Claude Code 執行時會合併兩層，兩邊的 hook 同時作用。

| Scope       | 目錄               | 套用位置                                             | 內容                                                           |
| ----------- | ------------------ | ---------------------------------------------------- | -------------------------------------------------------------- |
| **User**    | `user/.claude/`    | 同步到 `%USERPROFILE%\.claude`，對該帳號所有專案生效 | 與專案無關的機器層級設定：shell 偏好、危險指令攔截、共用子代理 |
| **Project** | `project/.claude/` | 疊進某個 repo 的 `.claude/`，只對該 repo 生效        | 依賴專案工具鏈的設定：寫檔後的 format / lint                   |

## 結構

```text
user/.claude/
├─ settings.json                             # env / defaultShell / permissions（deny Bash）/ PreToolUse
├─ CLAUDE.md                                 # PowerShell 優先的環境規則
├─ hooks/block-dangerous.js                  # PreToolUse：攔截危險指令
└─ agents/generic-test-quality-reviewer.md   # 語言/框架無關的測試品質審查子代理
project/.claude/
├─ settings.json                             # PostToolUse
└─ hooks/format-lint.js                      # 寫檔後 format / lint
scripts/sync-claude-scope.ps1                # 同步腳本
sdd/                                         # SDD 流程紀錄（提案 / 任務清單）
```

## 同步腳本 `scripts/sync-claude-scope.ps1`

需要 PowerShell 7+。所有模式都不會改動來源檔案。

`-WhatIf` / `-Diff` / `-Force` / `-Uninstall` 對兩種 scope 皆適用；其中 `-WhatIf`、`-Diff`、`-Uninstall` 三者互斥。同步後會在目標寫入 `.claude-scope-sync.json`（受管理檔案 + SHA-256），供 `-Uninstall` 判斷；被使用者改過的檔案不會被移除。

### User Scope

同步 `user/.claude/` 到 `%USERPROFILE%\.claude`，並把 `settings.json` 裡 hook 的佔位路徑改寫成實際絕對路徑。

```powershell
pwsh -NoProfile -File .\scripts\sync-claude-scope.ps1 -Scope User -WhatIf     # 預覽
pwsh -NoProfile -File .\scripts\sync-claude-scope.ps1 -Scope User -Diff       # 看差異
pwsh -NoProfile -File .\scripts\sync-claude-scope.ps1 -Scope User             # 同步（內容不同又沒 -Force 的會跳過）
pwsh -NoProfile -File .\scripts\sync-claude-scope.ps1 -Scope User -Force       # 覆蓋，先備份到 .claude-scope-backups\<時間戳>\
pwsh -NoProfile -File .\scripts\sync-claude-scope.ps1 -Scope User -Uninstall   # 移除本腳本管理的檔案
```

目標預設 `%USERPROFILE%\.claude`，可用 `-UserScopePath <路徑>` 覆寫。

### Project Scope

疊 `project/.claude/` 進指定 repo 的 `.claude/`，`-TargetRepo` 必填。

```powershell
pwsh -NoProfile -File .\scripts\sync-claude-scope.ps1 -Scope Project -TargetRepo C:\path\to\repo
```

### 本 repo 開發

根目錄 `.claude/` 已被 `.gitignore` 忽略。要在本 repo 內啟用 format-lint hook：

```powershell
pwsh -NoProfile -File .\scripts\sync-claude-scope.ps1 -Scope Project -TargetRepo .
```

## Hook 行為

- **`block-dangerous.js`**（PreToolUse，`Bash|PowerShell`）：指令執行前比對，命中即以 exit 2 擋下。涵蓋 `rm -rf`、`dd of=/dev/*`、`mkfs`、`shutdown`/`reboot`、`Remove-Item -Recurse -Force`、`Format-Volume`、`Clear-Disk`、`Stop-Computer`/`Restart-Computer`。
- **`format-lint.js`**（PostToolUse，`Edit|Write`）：偵測不到 `package.json` 或 pnpm 就跳過。對目標檔跑 `pnpm prettier --write`（失敗不阻斷），js/ts/svelte 再跑 `pnpm eslint --fix`；修完仍有 error 時以 exit 2 回報。

## 維護

- 設定依性質放進對應 scope 目錄，不要混進同一份 `settings.json`。
- 改動後同步更新本 README。
