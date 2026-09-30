# improve-block-dangerous-hook（新功能：調整既有 hook 行為）

## 為什麼做

`user/.claude/hooks/block-dangerous.js` 是 User Scope 的危險指令攔截 hook，目前有三個實際問題：

- **誤擋**：`Remove-Item` 只要同時帶 `-Recurse` 與 `-Force` 就擋，不看刪除的目標。實際案例：在另一個專案刪除專案內的測試資料夾 `src\posts\sdd-test-*` 被擋，和刪 `C:\` 被同樣對待。
- **漏擋**：規則只比對字面的 `Remove-Item` 與完整旗標。`ri`、`rmdir`、`del`、`rd`、`-fo`、`-Recurse:$true`、cmd 的 `del /s`、`rd /s` 都不會被擋；`git clean -fdx`、`git reset --hard`、`git push --force` 這類不可逆操作也不在清單內。
- **fail-open**：hook 自己出錯（例如 stdin JSON 解析失敗）時 `process.exit(0)` 直接放行，保護失效卻沒有任何訊息。

## 要改什麼

1. **依目標路徑判斷刪除指令**：解析 `Remove-Item` 與其別名（`ri`、`rm`、`rmdir`、`del`、`erase`、`rd`）的遞迴／強制旗標（含縮寫與 `-Recurse:$true` 寫法）及目標路徑，只在目標危險時才擋。
   - 危險目標：磁碟根目錄、家目錄（`~`、`$env:USERPROFILE`）、`*`、`.`、`..`、專案目錄本身或其上層、專案目錄以外的絕對路徑、`.git`。
   - 目標含變數、萬用字元或無法解析時，一律視為危險（保守）。
   - 目標明確位於專案目錄內的子路徑時，放行。
   - 專案目錄取自 hook stdin 的 `cwd`。
2. **補上漏洞**：cmd 風格的 `del /s`、`rd /s`（`rmdir /s`）套用同一套目標判斷；新增 `git clean -fdx`、`git reset --hard`、`git push --force`（含 `-f`）規則；`--force-with-lease` 不擋。
3. **fail-closed**：hook 內部錯誤時改為 `exit(2)` 擋下，並把錯誤原因寫到 stderr。

## 影響範圍

修改：

- `user/.claude/hooks/block-dangerous.js`（唯一的原始碼來源；`%USERPROFILE%\.claude\hooks\` 內的副本由同步腳本更新）

不新增、不刪除任何檔案。驗證用的臨時腳本放在 scratchpad，不放進本 repo（避免被 `user/.claude/` 同步到 `%USERPROFILE%\.claude`）。

不動：

- `user/.claude/settings.json`、`scripts/sync-claude-scope.ps1`、`project/.claude/`、`README.md`
- 被擋時的訊息內容（命中規則說明與替代做法）、`ask` 確認機制、允許清單——本次不做，待前三點穩定後再評估。

## 待確認的假設

- hook 的 stdin JSON 有 `cwd` 欄位可作為專案目錄；實作時先實際印出一次確認，若沒有則改用 `process.cwd()`。
- 「專案目錄本身、其上層、`.git`」視為危險，即使帶明確路徑也擋。
- 實際同步到 `%USERPROFILE%\.claude` 由使用者決定，本任務只預覽差異（`-WhatIf` / `-Diff`），不自行同步。
