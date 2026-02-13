# AutoHackMD

[中文](#中文) | [English](#english)

---

## 中文

### 簡介

AutoHackMD 是一個跨平台 AI Skill，當 AI 助手為你建立「學習」、「研究」或「整理」類型的 Markdown 筆記時，會自動：

1. 將 Markdown 儲存到本地分類資料夾（`~/mds/study/`、`~/mds/research/`、`~/mds/summary/`）
2. 透過 HackMD API 上傳到 HackMD
3. 設定分享權限（所有人可閱讀、只有你可編輯）
4. 回傳分享連結

### 支援平台

| 平台 | 指令檔 | 說明 |
|------|--------|------|
| **Cursor** | `SKILL.md` | 放入 `~/.cursor/skills/autohackmd/` |
| **OpenClaw** | `SKILL.md` | 放入 `~/.openclaw/skills/autohackmd/` |
| **Claude Code** | `CLAUDE.md` | 放入專案根目錄或 `~/.claude/` |
| **Codex** | `AGENTS.md` | 放入專案根目錄或 home 目錄 |
| **GitHub Copilot** | `.github/copilot-instructions.md` | 放入專案 `.github/` 目錄 |
| **Gemini CLI** | `GEMINI.md` | 放入專案根目錄或 `~/.gemini/` |
| **Open Code** | `AGENTS.md` | 放入專案根目錄 |

### 系統需求

- **Linux / macOS**: `bash`、`curl`（系統通常已內建）
- **Windows**: `PowerShell 5.1+`（Windows 10+ 內建）

### 快速開始

#### 1. 取得 HackMD API Token

1. 登入 [HackMD](https://hackmd.io)
2. 前往 [Settings > API](https://hackmd.io/settings#api)
3. 點擊「Create API token」
4. 複製 token

#### 2. 設定 Token

**Linux / macOS:**
```bash
bash scripts/linux/hackmd_config.sh --token "你的token"
bash scripts/linux/hackmd_config.sh --verify  # 驗證
```

**Windows:**
```powershell
.\scripts\windows\hackmd_config.ps1 -Token "你的token"
.\scripts\windows\hackmd_config.ps1 -Verify  # 驗證
```

或者設定環境變數：
```bash
export HACKMD_API_TOKEN="你的token"
```

#### 3. 安裝到 AI 平台

**Cursor:**
```bash
mkdir -p ~/.cursor/skills
ln -s /path/to/autohackmd ~/.cursor/skills/autohackmd
```

**OpenClaw:**
```bash
mkdir -p ~/.openclaw/skills
ln -s /path/to/autohackmd ~/.openclaw/skills/autohackmd
```

**Claude Code（專案層級）：**
```bash
cp /path/to/autohackmd/CLAUDE.md ./CLAUDE.md
```

**Codex / Open Code（專案層級）：**
```bash
cp /path/to/autohackmd/AGENTS.md ./AGENTS.md
```

**GitHub Copilot:**
```bash
mkdir -p .github
cp /path/to/autohackmd/.github/copilot-instructions.md .github/
```

**Gemini CLI:**
```bash
cp /path/to/autohackmd/GEMINI.md ./GEMINI.md
```

### 手動使用腳本

#### 上傳筆記

**Linux / macOS:**
```bash
# 從檔案上傳
bash scripts/linux/hackmd_upload.sh --file ~/mds/study/my-note.md --tags "study,linux"

# 從文字上傳
bash scripts/linux/hackmd_upload.sh --title "我的筆記" --content "# 內容" --tags "study"
```

**Windows:**
```powershell
# 從檔案上傳
.\scripts\windows\hackmd_upload.ps1 -File "~/mds/study/my-note.md" -Tags "study,linux"

# 從文字上傳
.\scripts\windows\hackmd_upload.ps1 -Title "我的筆記" -Content "# 內容" -Tags "study"
```

#### 更新筆記

**Linux / macOS:**
```bash
# 更新權限
bash scripts/linux/hackmd_update.sh --note-id "abc123" --read-perm guest --write-perm owner

# 更新內容
bash scripts/linux/hackmd_update.sh --note-id "abc123" --file ~/mds/study/my-note.md

# 刪除筆記
bash scripts/linux/hackmd_update.sh --note-id "abc123" --delete
```

**Windows:**
```powershell
# 更新權限
.\scripts\windows\hackmd_update.ps1 -NoteId "abc123" -ReadPerm guest -WritePerm owner

# 更新內容
.\scripts\windows\hackmd_update.ps1 -NoteId "abc123" -File "~/mds/study/my-note.md"

# 刪除筆記
.\scripts\windows\hackmd_update.ps1 -NoteId "abc123" -Delete
```

### 權限說明

| 值 | 含義 |
|----|------|
| `owner` | 僅筆記擁有者 |
| `signed_in` | 任何已登入的 HackMD 使用者 |
| `guest` | 所有人（包含匿名） |

### 專案結構

```
autohackmd/
├── SKILL.md                          # Cursor + OpenClaw
├── AGENTS.md                         # Codex + Copilot + Open Code
├── CLAUDE.md                         # Claude Code
├── GEMINI.md                         # Gemini CLI
├── .github/
│   └── copilot-instructions.md       # GitHub Copilot
├── scripts/
│   ├── linux/
│   │   ├── hackmd_upload.sh          # 上傳（bash + curl）
│   │   ├── hackmd_update.sh          # 更新（bash + curl）
│   │   └── hackmd_config.sh          # 設定 token（bash）
│   └── windows/
│       ├── hackmd_upload.ps1         # 上傳（PowerShell）
│       ├── hackmd_update.ps1         # 更新（PowerShell）
│       └── hackmd_config.ps1         # 設定 token（PowerShell）
├── references/
│   └── hackmd-api.md                 # API 快速參考
├── README.md                         # 本文件
├── .gitignore
└── .env.example                      # 環境變數範例
```

### 授權

MIT License

---

## English

### Introduction

AutoHackMD is a cross-platform AI Skill that automatically handles markdown notes when an AI assistant creates "study", "research", or "summary" content:

1. Saves the markdown to a categorized local folder (`~/mds/study/`, `~/mds/research/`, `~/mds/summary/`)
2. Uploads it to HackMD via the HackMD API
3. Sets sharing permissions (readable by everyone, editable only by you)
4. Returns the share link

### Supported Platforms

| Platform | Instruction File | Setup |
|----------|-----------------|-------|
| **Cursor** | `SKILL.md` | Place in `~/.cursor/skills/autohackmd/` |
| **OpenClaw** | `SKILL.md` | Place in `~/.openclaw/skills/autohackmd/` |
| **Claude Code** | `CLAUDE.md` | Place in project root or `~/.claude/` |
| **Codex** | `AGENTS.md` | Place in project root or home directory |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Place in project `.github/` directory |
| **Gemini CLI** | `GEMINI.md` | Place in project root or `~/.gemini/` |
| **Open Code** | `AGENTS.md` | Place in project root |

### Requirements

- **Linux / macOS**: `bash`, `curl` (usually pre-installed)
- **Windows**: `PowerShell 5.1+` (built-in on Windows 10+)

### Quick Start

#### 1. Get a HackMD API Token

1. Sign in to [HackMD](https://hackmd.io)
2. Go to [Settings > API](https://hackmd.io/settings#api)
3. Click "Create API token"
4. Copy the token

#### 2. Configure Token

**Linux / macOS:**
```bash
bash scripts/linux/hackmd_config.sh --token "your-token"
bash scripts/linux/hackmd_config.sh --verify  # verify it works
```

**Windows:**
```powershell
.\scripts\windows\hackmd_config.ps1 -Token "your-token"
.\scripts\windows\hackmd_config.ps1 -Verify  # verify it works
```

Or set an environment variable:
```bash
export HACKMD_API_TOKEN="your-token"
```

#### 3. Install for Your AI Platform

**Cursor:**
```bash
mkdir -p ~/.cursor/skills
ln -s /path/to/autohackmd ~/.cursor/skills/autohackmd
```

**OpenClaw:**
```bash
mkdir -p ~/.openclaw/skills
ln -s /path/to/autohackmd ~/.openclaw/skills/autohackmd
```

**Claude Code (project-level):**
```bash
cp /path/to/autohackmd/CLAUDE.md ./CLAUDE.md
```

**Codex / Open Code (project-level):**
```bash
cp /path/to/autohackmd/AGENTS.md ./AGENTS.md
```

**GitHub Copilot:**
```bash
mkdir -p .github
cp /path/to/autohackmd/.github/copilot-instructions.md .github/
```

**Gemini CLI:**
```bash
cp /path/to/autohackmd/GEMINI.md ./GEMINI.md
```

### Manual Script Usage

#### Upload a Note

**Linux / macOS:**
```bash
# Upload from file
bash scripts/linux/hackmd_upload.sh --file ~/mds/study/my-note.md --tags "study,linux"

# Upload from text
bash scripts/linux/hackmd_upload.sh --title "My Note" --content "# Content" --tags "study"
```

**Windows:**
```powershell
# Upload from file
.\scripts\windows\hackmd_upload.ps1 -File "~/mds/study/my-note.md" -Tags "study,linux"

# Upload from text
.\scripts\windows\hackmd_upload.ps1 -Title "My Note" -Content "# Content" -Tags "study"
```

#### Update a Note

**Linux / macOS:**
```bash
# Update permissions
bash scripts/linux/hackmd_update.sh --note-id "abc123" --read-perm guest --write-perm owner

# Update content
bash scripts/linux/hackmd_update.sh --note-id "abc123" --file ~/mds/study/my-note.md

# Delete note
bash scripts/linux/hackmd_update.sh --note-id "abc123" --delete
```

**Windows:**
```powershell
# Update permissions
.\scripts\windows\hackmd_update.ps1 -NoteId "abc123" -ReadPerm guest -WritePerm owner

# Update content
.\scripts\windows\hackmd_update.ps1 -NoteId "abc123" -File "~/mds/study/my-note.md"

# Delete note
.\scripts\windows\hackmd_update.ps1 -NoteId "abc123" -Delete
```

### Permission Values

| Value | Meaning |
|-------|---------|
| `owner` | Only the note owner |
| `signed_in` | Any signed-in HackMD user |
| `guest` | Anyone (including anonymous) |

### Project Structure

```
autohackmd/
├── SKILL.md                          # Cursor + OpenClaw
├── AGENTS.md                         # Codex + Copilot + Open Code
├── CLAUDE.md                         # Claude Code
├── GEMINI.md                         # Gemini CLI
├── .github/
│   └── copilot-instructions.md       # GitHub Copilot
├── scripts/
│   ├── linux/
│   │   ├── hackmd_upload.sh          # Upload (bash + curl)
│   │   ├── hackmd_update.sh          # Update (bash + curl)
│   │   └── hackmd_config.sh          # Config token (bash)
│   └── windows/
│       ├── hackmd_upload.ps1         # Upload (PowerShell)
│       ├── hackmd_update.ps1         # Update (PowerShell)
│       └── hackmd_config.ps1         # Config token (PowerShell)
├── references/
│   └── hackmd-api.md                 # API quick reference
├── README.md                         # This file
├── .gitignore
└── .env.example                      # Environment variable example
```

### License

MIT License
