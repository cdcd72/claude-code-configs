# add-block-dangerous-hook-tests（新功能：為危險指令 hook 補上自動化測試）

## 為什麼做

`user/.claude/hooks/block-dangerous.js` 在 `improve-block-dangerous-hook` 之後，規則靠自訂的指令切分、引號解析與路徑判斷實作，改一處很容易壞另一處。目前的驗證只存在於臨時腳本（scratchpad 內的 `test-hook.cjs`、`test-hook-round2.cjs`，共約 100 個案例），不在 repo 內，換個對話或換台機器就沒了，之後調整 hook 時無法立刻知道有沒有退步。

## 要改什麼

- 新增 `tests/block-dangerous.test.js`，把臨時腳本的案例搬進 repo，使用 Node 內建的 `node:test`，不新增任何 npm 依賴，以 `node --test` 執行。
- 案例依類別分組：刪除指令（該擋／該放行）、git 規則、引號與跳脫、`.git` 保護、fail-closed（異常輸入）、外殼與 `cd`。
- 調整原本不可移植的部分：
  - 以相對於測試檔的路徑找到 hook，不寫死絕對路徑。
  - 專案目錄改用假的路徑（例如 `D:\Work\demo`）；`path.win32.resolve` 不碰檔案系統，目錄不必存在。
  - 原本寫死 `C:\Users\Ame\…` 的案例改用 `os.homedir()` 動態組路徑，與使用者名稱無關。
  - 新增「專案目錄就是家目錄時，所有遞迴刪除都擋」的案例（對應 `tooBroad` 邏輯，原本沒有測）。
- 測試檔支援以環境變數 `HOOK_PATH` 指定要測的 hook 檔案（預設為 repo 內的 hook），用來證明測試真的抓得到退步：拿修改前的舊版 hook 跑，新增的案例必須失敗。
- 更新 `README.md`：結構樹加入 `tests/`，補上執行方式。

## 影響範圍

新增：

- `tests/block-dangerous.test.js`

修改：

- `README.md`（結構樹與測試執行方式）

不動：

- `user/.claude/hooks/block-dangerous.js` 與 `user/.claude/` 內任何檔案
- `scripts/sync-claude-scope.ps1`、`project/.claude/`

`tests/` 放在 repo 根目錄，不在 `user/.claude/` 或 `project/.claude/` 底下，避免被同步腳本複製到 `%USERPROFILE%\.claude` 或其他 repo。

## 待確認的假設

- Node 版本支援 `node:test`（18 以上）；實作時先用 `node --version` 確認。
- 測試只驗證 hook 的輸入輸出（exit code 與 stderr），不驗證 Claude Code 實際如何呼叫 hook。
- 已知「刻意不修」的行為（`sudo`／`env` 前綴、git 長選項縮寫、`> $null` 誤擋等）不寫成測試，避免把暫時的缺口固化成預期行為。
- 不新增 `package.json`、不接 CI。
