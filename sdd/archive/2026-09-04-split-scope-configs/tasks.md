# tasks — split-scope-configs

- [x] 1. 建立 `user/.claude/` 與 `project/.claude/` 目錄骨架，並在 README 或短說明中定義兩個 scope 的職責邊界。
- [x] 2. 把 `block-dangerous.js` 移到 `user/.claude/hooks/`；把 `format-lint.js` 移到 `project/.claude/hooks/`。（原本在任務 2 曾於根 `.claude/hooks/` 留一份供本 repo 開發，後於任務 11 一併移除、改為需要時由同步腳本產生。）
- [x] 3. 移動 `.claude/agents/` 到 `user/.claude/agents/`（該檔另於任務 3c 改名）。
- [x] 3c. 用語言/框架無關版內容取代原本的 `test-quality-reviewer.md`，檔名與 `name` 都改為 `generic-test-quality-reviewer`（泛用類型）；確認無任何公司內部專屬字樣。
- [x] 3b. 整個移除 `.claude/commands/`（commit / commit-push / commit-push-pr / review / test），並清掉 README 對這些指令的說明；理由：已由其他 repo 以 skill 形式維護。
- [x] 4. 撰寫 `user/.claude/settings.json`：env、defaultShell、permissions、PreToolUse(block-dangerous)，hook 路徑用可被腳本改寫的佔位字串。
- [x] 5. 撰寫 `project/.claude/settings.json`：只含 PostToolUse(format-lint)。（當時也把根 `.claude/settings.json` 改為相同內容，該檔後於任務 11 移除。）
- [x] 6. 拆 `CLAUDE.md`：通用 PowerShell 規則同步一份到 `user/.claude/CLAUDE.md`，並確認整個 repo 無任何公司內部專屬規則段落。
- [x] 7. 寫 `scripts/sync-claude-scope.ps1` 的 `-Scope User` 流程：同步、路徑改寫、`-WhatIf` / `-Diff` / `-Force`（含備份）/ `-Uninstall`、manifest（SHA-256）。
- [x] 8. 在同一腳本加 `-Scope Project -TargetRepo <path>`：把 `project/.claude/` 疊進目標 repo 的 `.claude/`（衝突時 `-Force` 前先備份）。
- [x] 9. 用 `-WhatIf` 與 `-Diff` 對兩個 scope 各跑一次，確認輸出正確且不誤改檔案。
- [x] 10. 更新 `README.md`：新的雙 scope 目錄樹、各檔案職責、`sync-claude-scope.ps1` 各模式用法。
- [x] 11. 清理拆分後根目錄的殘留檔案：
  - 移除 repo 根目錄的 `.claude/`（內容與 `project/.claude/` 完全重複），改為 `.gitignore` 忽略；README 補「本 repo 開發」說明，用 `sync-claude-scope.ps1 -Scope Project -TargetRepo .` 產生本機用的 `.claude/`。
  - 移除 repo 根目錄的 `CLAUDE.md`（與 `user/.claude/CLAUDE.md` 內容完全相同的殘留副本），並從 README 結構樹拿掉。
  - `%USERPROFILE%\.claude\.claude-scope-backups\` 先前事故遺留的備份資料夾，交給使用者執行刪除。

## 驗收條件

- 情境：在 repo 根目錄執行 `scripts/sync-claude-scope.ps1 -Scope User -WhatIf`，就列出會同步到 `%USERPROFILE%\.claude` 的檔案清單（CLAUDE.md、settings.json、hooks/block-dangerous.js、agents/generic-test-quality-reviewer.md），且不寫入任何檔案。
- 情境：實際執行 `-Scope User`（非 WhatIf）後，`%USERPROFILE%\.claude\settings.json` 內 PreToolUse hook 的 `args` 路徑，就是同步後 `block-dangerous.js` 的實際絕對路徑，不含佔位字串。
- 情境：當 `%USERPROFILE%\.claude` 已有內容不同的同名檔案且未加 `-Force`，就跳過該檔並提示需要 `-Force`，不覆蓋。
- 情境：加上 `-Force` 覆蓋時，就先把舊檔備份到 `%USERPROFILE%\.claude\.<backup 目錄>\<時間戳>\` 再寫入。
- 情境：執行 `-Scope Project -TargetRepo <某 repo>`，就把 `project/.claude/settings.json` 與 `hooks/format-lint.js` 疊進該 repo 的 `.claude/`，不動 User Scope 的檔案。
- 情境：git 追蹤的檔案裡不再有 repo 根目錄的 `.claude/`；`.gitignore` 有一條忽略 `/.claude/`，README 說明本機開發要用 `-Scope Project -TargetRepo .` 產生它。而 User Scope 的 settings.json 裡不含任何 PostToolUse 設定。
- 情境：在整個 repo 搜尋，就找不到任何公司名稱、內部專案代號或公司內部專屬規則段落。
- 情境：在整個 repo 搜尋，就找不到 `.claude/commands/` 目錄，README 也不再提及 commit / review / test 指令。
