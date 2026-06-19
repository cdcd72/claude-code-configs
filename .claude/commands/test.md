---
description: 執行測試流程：運行現有測試、修復失敗案例，或為關鍵邏輯補充測試
allowed-tools: PowerShell(pnpm run *), Filesystem(*)
metadata:
  author: Neil
  version: '2026.6.19'
---

# 程式碼測試指令

請執行以下測試與品質保證流程。你的目標是確保程式碼的正確性與強健性。

## 流程

1. **指令分析**：先查看 `package.json` 的 `scripts`，確認可用的測試指令（例如 `test`、`test:unit`、`test:coverage`）。若沒有可執行的測試腳本，先說明目前無法執行測試的原因，再決定是否補充測試。
2. **執行測試**：使用 PowerShell 工具執行找到的測試指令；若命令失敗，記錄錯誤訊息並分析原因。
3. **錯誤修復 (若測試失敗)**：
   - 分析錯誤堆疊 (Stack Trace)。
   - **不應單純修改測試來讓它通過**，除非確認是測試案例本身的錯誤。
   - 修正原始程式碼邏輯以通過測試。
4. **補充測試 (若測試缺失)**：
   - 若專案缺乏測試，或覆蓋率不足，請為核心商業邏輯撰寫單元測試。
   - 確保測試具備**原子性 (Atomicity)**，不依賴外部環境 (需使用 Mock/Stub)。

## 參考資訊

為了協助你選擇正確的指令，請參考以下內容：

- `package.json` Scripts：!`sls "scripts" package.json -Context 0, 15`
