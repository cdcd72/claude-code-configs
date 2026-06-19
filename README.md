# Claude Code 設定

本儲存庫用於集中管理 Claude Code 的自訂環境設定與工作流程，包含設定檔、命令定義、掛鉤腳本與安全限制。

## 目前結構

```text
.
├─ .claude/
│  ├─ commands/
│  │  ├─ commit-push-pr.md
│  │  ├─ commit-push.md
│  │  ├─ commit.md
│  │  ├─ review.md
│  │  └─ test.md
│  ├─ hooks/
│  │  ├─ block-dangerous.js
│  │  └─ format-lint.js
│  └─ settings.json
├─ CLAUDE.md
├─ LICENSE
└─ README.md
```

## 目錄與檔案說明

- `.claude/settings.json`：Claude Code 的主要設定檔。
  - 強制使用 PowerShell 作為預設 shell。
  - 啟用 PowerShell 相關權限，禁止使用 Bash。
  - 註冊 `PreToolUse` / `PostToolUse` / `Stop` hooks，提供安全檢查與自動整理流程。

- `.claude/commands/`：自訂指令模板，提供常見開發流程。
  - `commit.md`：執行提交流程，依照 Conventional Commits 規範。
  - `commit-push.md`：補充提交後推送流程。
  - `commit-push-pr.md`：整合提交、推送與建立 PR 的流程。
  - `review.md`：執行程式碼審查與問題診斷。
  - `test.md`：執行測試、修復失敗案例與補充測試。

- `.claude/hooks/`：Claude Code 執行前後的自動化掛鉤。
  - `block-dangerous.js`：阻止危險指令（例如 `rm -rf /`、`mkfs`、`shutdown` 等）。
  - `format-lint.js`：在檔案寫入後，自動執行 Prettier / ESLint 修正（若環境支援）。

- `CLAUDE.md`：本倉庫的 Claude 專用規則與開發限制說明。

- `LICENSE`：專案授權條款。

## 主要功能

### 1. PowerShell 優先環境

這個設定偏好在 Windows 環境下使用 PowerShell，避免不必要的 Bash 相依，並在設定中明確限制危險操作。

### 2. 危險命令防護

透過 `block-dangerous.js`，可以在 Claude 執行工具指令前攔截高風險命令，降低誤操作風險。

### 3. 自動化開發流程

透過 `commands/` 與 hooks，這個專案整合了：

- 提交流程
- 程式碼審查流程
- 測試流程
- 格式化與 lint 修正

## 快速上手

1. 直接將此倉庫作為 Claude Code 的設定範本使用。
2. 若要調整環境行為，可修改 `.claude/settings.json`。
3. 若要新增或調整開發流程，可在 `.claude/commands/` 新增指令檔。
4. 若要強化安全或品質檢查，可在 `.claude/hooks/` 加入新的掛鉤腳本。

## 維護建議

- 新增或修改命令、掛鉤或設定後，請同步更新本 README。
- 若新增新的自動化流程，請確認其行為與現有工作流程兼容。
- 保持安全規則與品質檢查保持可控，避免過度放寬權限。

## 貢獻

歡迎針對設定、流程與安全規則提出建議或改善內容。
