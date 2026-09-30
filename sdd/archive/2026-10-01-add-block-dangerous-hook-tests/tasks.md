# tasks — add-block-dangerous-hook-tests

- [x] 1. 確認 Node 版本支援 `node:test`；建立 `tests/block-dangerous.test.js` 骨架：以相對路徑（或 `HOOK_PATH` 環境變數）找到 hook、假專案目錄常數、`runHook(command)` 與 `runRaw(stdin)` 輔助函式。
- [x] 2. 搬入「刪除指令」案例（該擋／該放行），含別名、旗標縮寫、合併短旗標、cmd 的 `/s`、專案內外路徑；`C:\Users\…` 改用 `os.homedir()` 組出。
- [x] 3. 搬入 git 規則案例（`clean`、`reset --hard`、`push --force`／`-f`／`+refspec`，以及 `--force-with-lease`、`clean -n` 放行）。
- [x] 4. 搬入引號與跳脫、`.git` 保護（大小寫、尾端點、`GIT~1`）與外殼／`cd` 案例。
- [x] 5. 搬入 fail-closed 案例（空 stdin、無效 JSON、缺 command、型別錯誤），並新增「專案目錄為家目錄時所有遞迴刪除都擋」案例。
- [x] 6. 合併去重，依類別用 `describe` 分組，確認單一案例失敗時能從名稱看出是哪一類。
- [x] 7. 執行 `node --test`，全部通過。
- [x] 8. 用 `git show HEAD:user/.claude/hooks/block-dangerous.js` 取出修改前的舊版 hook 到暫存檔，以 `HOOK_PATH` 指向它重跑測試，確認新增的案例會失敗（證明測試抓得到退步）；暫存檔放 scratchpad，不進 repo。
- [x] 9. 更新 `README.md`：結構樹加入 `tests/`，補上 `node --test` 的執行方式。
- [x] 10. 執行 `sync-claude-scope.ps1 -Scope User -WhatIf`，確認清單不含 `tests/` 內任何檔案，也沒有寫入任何檔案。

## 驗收條件

- 情境：在 repo 根目錄執行 `node --test`，就跑完所有案例且全部通過，不需要安裝任何套件。
- 情境：把專案搬到另一個路徑或另一個使用者帳號，測試仍然通過（不含寫死的絕對路徑或使用者名稱）。
- 情境：用修改前的舊版 hook（`HOOK_PATH` 指向它）跑測試，就有案例失敗，且失敗名稱能看出所屬類別。
- 情境：測試涵蓋的類別至少包含刪除指令、git 規則、引號與跳脫、`.git` 保護、外殼與 `cd`、fail-closed。
- 情境：「刻意不修」的缺口（`sudo` 前綴、`--forc` 縮寫、`> $null`）沒有被寫成預期行為的測試。
- 情境：`-Scope User -WhatIf` 的同步清單不含 `tests/`，`user/.claude/` 與 `%USERPROFILE%\.claude` 都沒有被修改。
- 情境：`README.md` 的結構樹列出 `tests/`，並說明如何執行測試。

## 備註

- 執行指令是 `node --test`（自動尋找 `*.test.js`）。在 Node v22 下 `node --test tests/` 會把目錄當成單一檔案載入而失敗，所以文件內的 `node --test tests/` 已更正。
- 任務 7：135 個測試全數通過（Node v22.20.0）。
- 任務 8：舊版 hook 是 `git show HEAD~1:…`（hook 修改已先提交，所以不是任務文字寫的 `HEAD`），經 `HOOK_PATH` 重跑，135 個中有 51 個失敗，涵蓋遞迴旗標、目標路徑、`.git`、git、引號、外殼與 cd、fail-closed；固定規則與一般指令沒有失敗（舊版本來就有）。
- 任務 9：除了結構樹與測試說明，也一併更新 README「Hook 行為」段落——它還停留在舊版的描述，與 `improve-block-dangerous-hook` 之後的行為不符。
- 任務 10：`-Scope User -WhatIf` 清單只有 `user/.claude/` 內的檔案，不含 `tests/`，也沒有寫入任何檔案。
- 「刻意不修」的缺口（`sudo` 前綴、`--forc` 縮寫、`> $null`、舊規則對引號內文字的誤擋）沒有寫成測試。`[slug]` 這類含方括號的目標屬於保守設計，同樣不列入測試。
