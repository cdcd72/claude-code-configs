---
description: 執行提交、推送與建立 Pull Request 流程 (符合 Conventional Commits 規範)
allowed-tools: PowerShell(git branch:*), PowerShell(git checkout:*), PowerShell(git status:*), PowerShell(git diff:*), PowerShell(git add:*), PowerShell(git commit:*), PowerShell(git push:*), PowerShell(gh pr create:*)
metadata:
  author: Neil
  version: '2026.6.19'
---

# 程式碼提交、推送與建立 Pull Request 指令

請根據目前工作區的實際變更，完成一次符合 Conventional Commits 的 Git 提交，並將變更推送到遠端倉庫，最後建立 Pull Request。

## 流程

1. 檢查目前分支與變更：

   ```pwsh
   git branch --show-current
   git status -s
   git diff HEAD
   ```

2. 根據實際 diff 判斷分支類型、分支名稱與 commit message；不要使用空泛描述，且若沒有實際變更，請停止，不要建立空提交。

3. 如果目前在 `main` 分支，先建立新分支：

   ```pwsh
   git checkout -b <type>/<description>
   ```

4. 暫存並確認提交內容：

   ```pwsh
   git add .
   git status -s
   git diff --cached
   ```

5. 建立單一提交：

   ```pwsh
   git commit -m "<type>(<scope>): <description>"
   ```

6. 確認目前分支並推送到遠端倉庫：

   ```pwsh
   git branch --show-current
   git push -u origin <current-branch>
   ```

7. 根據實際 diff 與 commit 內容撰寫 Pull Request title 與 description。

8. 建立 Pull Request：

   ```pwsh
   gh pr create --base main --title "<title>" --body "<description>"
   ```

## 規範

### 分支（Branch）

格式：

```txt
<type>/<description>
```

- `type` 使用：`feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `style`
- `description` 使用英文、kebab-case、命令式描述
- 不要加標點符號

### 提交訊息（Commit Message）

格式：

```txt
<type>(<scope>): <description>
```

或省略 scope：

```txt
<type>: <description>
```

- `type` 同 branch type
- `scope` 可選，使用受影響的模組或功能名稱
- `description` 使用繁體中文 (Traditional Chinese)
- 必須根據實際 diff 撰寫
- 不要使用「更新檔案」、「修改內容」等空泛描述
- 不要加標點符號
- 重大變更使用 `!` 或 `BREAKING CHANGE:`

### Pull Request

#### 標題（Title）

- 同提交訊息的 `<type>(<scope>): <description>` 格式規範
- 必須根據實際 diff 撰寫

#### 描述（Description）

要求:

- 使用繁體中文（Traditional Chinese）。
- 根據實際 diff 撰寫內容。
- 使用具體且明確的項目清單描述實際程式碼變更，並適當分組。
- 視實際變更內容選擇適用分類。
- 提及新增、修改、移除或重構的元件（如適用）。
- 不要遺漏相關變更，也不要編造、推測或描述 diff 中不存在的內容。
- 避免使用空泛描述，例如「修改程式碼」、「修正問題」、「改善功能」或「更新邏輯」。
- 僅保留有實際內容的章節，不要輸出空章節或「無」、「N/A」等內容。

格式：

```markdown
## 變更內容

- ...

## 變更目的

- ...

## 測試項目

- ...

## 注意事項

- ...
```

## 限制

- 只建立一個 commit
- 不要 amend
- 不要提交 secrets、`.env`、建置產物、暫存檔或無關檔案
