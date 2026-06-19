---
description: 執行提交流程 (符合 Conventional Commits 規範)
allowed-tools: PowerShell(git branch:*), PowerShell(git checkout:*), PowerShell(git status:*), PowerShell(git diff:*), PowerShell(git add:*), PowerShell(git commit:*)
metadata:
  author: Neil
  version: '2026.6.19'
---

# 程式碼提交指令

請根據目前工作區的實際變更，完成一次符合 Conventional Commits 的 Git 提交。

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

## 限制

- 只建立一個 commit
- 不要 push
- 不要 amend
- 不要提交 secrets、`.env`、建置產物、暫存檔或無關檔案
