# tasks — improve-block-dangerous-hook

- [x] 1. 確認 hook stdin JSON 是否帶 `cwd`（先印出一次實際輸入），決定專案目錄的取得方式；結論記在本檔下方備註。
- [x] 2. 在 `user/.claude/hooks/block-dangerous.js` 加入 PowerShell 刪除指令解析：辨識 `Remove-Item` 與別名（`ri`、`rm`、`rmdir`、`del`、`erase`、`rd`）、遞迴／強制旗標（含縮寫、`-Recurse:$true`），並取出目標路徑。
- [x] 3. 加入「危險目標」判斷：磁碟根、家目錄、`*`、`.`、`..`、專案目錄本身或上層、專案外絕對路徑、`.git`；含變數、萬用字元或無法解析者一律視為危險；專案內明確子路徑放行。
- [x] 4. 將 cmd 風格 `del /s`、`rd /s`、`rmdir /s` 接到同一套目標判斷。
- [x] 5. 新增 `git clean -fdx`、`git reset --hard`、`git push --force` / `-f` 規則。
- [x] 6. 錯誤處理改為 fail-closed：`main().catch` 改 `exit(2)` 並寫出錯誤原因到 stderr。
- [x] 7. 用臨時腳本（放 scratchpad）對 hook 餵 JSON，驗證「該擋／該放行」兩組指令，結果列表回報。
- [x] 8. 以 `scripts/sync-claude-scope.ps1 -Scope User -WhatIf` 與 `-Diff` 預覽，確認只有 `block-dangerous.js` 有差異；不實際同步。

## 驗收條件

- 情境：當指令是 `Remove-Item C:\ -Recurse -Force`、`rm -rf ~`、`ri -r -fo $env:USERPROFILE`、`rd /s /q C:\`，就擋下（exit 2）。
- 情境：當指令是 `Remove-Item src\posts\sdd-test-empty -Recurse -Force`（目標在專案內），就放行（exit 0）。
- 情境：當目標含變數、萬用字元或無法解析（例如 `Remove-Item $x -Recurse -Force`、`Remove-Item * -Recurse -Force`），就擋下。
- 情境：當指令是 `Remove-Item -Recurse:$true -fo <專案外路徑>` 或 `del /s /q <專案外路徑>`，就擋下。
- 情境：當指令是 `git clean -fdx`、`git reset --hard`、`git push --force`，就擋下；`git push --force-with-lease` 與一般 `git push` 不受影響。
- 情境：當指令是一般安全指令（如 `git status`、`Get-ChildItem`、不帶遞迴強制旗標的 `Remove-Item file.txt`），就放行。
- 情境：當 stdin 不是合法 JSON，就擋下（exit 2）並在 stderr 顯示錯誤原因，而不是放行。
- 情境：`-Scope User -WhatIf` / `-Diff` 預覽只顯示 `hooks/block-dangerous.js` 有差異，其他檔案與 `%USERPROFILE%\.claude` 都沒有被寫入。

## 備註

- 任務 1：實作採 `input.cwd || process.cwd()`。尚未在真實 hook 環境實測 stdin 是否帶 `cwd`；同步後，若「刪除專案內子路徑」被放行，即代表取得正確。
- 任務 7：59 個案例全數通過（38 個該擋、20 個該放行、1 個無效 JSON）。驗證腳本在 scratchpad，不在 repo 內。
- 任務 8：預覽顯示 `CLAUDE.md`、`settings.json` 也有差異，與最後一條驗收條件不符。`settings.json` 差異是真實環境的自訂內容（`model`、`SessionStart` 的 herdr hook 等）；`CLAUDE.md` 逐行比對內容相同，推測是換行或空白差異。不加 `-Force` 時同步腳本會連 `block-dangerous.js` 一起跳過（衝突），加 `-Force` 則會覆蓋 `settings.json`（先備份）。建議只複製 `block-dangerous.js` 這一個檔案。
- 子代理審查後的補修（第二輪）：
  - 遞迴旗標：接受 `-rfv`、`-rv`、`-Ir` 等合併短旗標，以及 `/s/q` 連寫。
  - 引號：處理反引號跳脫；引號未配對時拋錯擋下，不再讓後面的敘述被吞掉。
  - `.git` 保護改為不分大小寫，並處理尾端點與 `GIT~1` 短檔名。
  - 空 stdin、缺少 `tool_input.command`、型別錯誤一律 `exit 2`；空字串 command 放行。
  - 第二輪驗證 39 個案例全數通過，並重跑第一輪 59 個案例無退步。
  - 刻意不修：`sudo`／`env`／`command`／`xargs` 前綴、git 長選項縮寫（`--forc`）、`> $null` 重導向誤擋、舊規則對引號內文字的誤擋。
- 已知限制：目標含 `[ ]`（如 `[slug]` 路由目錄）或萬用字元時，遞迴刪除一律擋下；變數拼出來的指令無法解析。
