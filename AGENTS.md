# AutoHackMD

> This file provides instructions for AI agents (Codex, Copilot, Open Code, and other AGENTS.md-compatible tools).

Automatically save markdown notes locally and upload them to HackMD when creating study, research, or summary content.

## Trigger Conditions

Activate this workflow when ALL of the following are true:

1. You are creating or have just created a **markdown file** for the user
2. The content nature is one of:
   - **Study / Learning** (學習): tutorials, learning notes, course notes, study guides
   - **Research** (研究): research notes, analysis, investigation, technical deep-dives
   - **Summary / Organization** (整理): knowledge summaries, checklists, organized references, documentation

Do NOT trigger for: casual conversations, code-only files, config files, changelogs, or commit messages.

## Workflow

### Step 1: Classify Content

| Category | Keywords / Signals |
|----------|-------------------|
| `study` | learning, tutorial, course, study guide, 學習, 教學 |
| `research` | research, analysis, investigation, deep-dive, 研究, 分析 |
| `summary` | summary, organization, reference, checklist, 整理, 總結 |
| `others` | Does not fit above but still worth archiving |

### Step 2: Save Locally

- Path: `~/mds/study/`, `~/mds/research/`, `~/mds/summary/`, or `~/mds/others/`
- Filename: `YYYYMMDD-HHMMSS-{sanitized-title}.md`
- Create the directory if it does not exist

### Step 3: Detect OS and Locate Scripts

Find the autohackmd skill directory. Check these paths in order and use the first one that exists:
1. `~/.cursor/skills/autohackmd/`
2. `~/.openclaw/skills/autohackmd/`
3. `~/git/autohackmd/`
4. The directory containing this AGENTS.md file

Store the resolved absolute path as `SKILL_DIR`.

- **Linux / macOS**: Use `${SKILL_DIR}/scripts/linux/*.sh`
- **Windows**: Use `${SKILL_DIR}\scripts\windows\*.ps1`

### Step 4: Check Token

Before uploading, verify the HackMD API token:

**Linux/macOS:**
```bash
bash "${SKILL_DIR}/scripts/linux/hackmd_config.sh" --verify
```

**Windows:**
```powershell
& "${SKILL_DIR}\scripts\windows\hackmd_config.ps1" -Verify
```

If no token, guide user to https://hackmd.io/settings#api to create one, then:
- `bash "${SKILL_DIR}/scripts/linux/hackmd_config.sh" --token <token>`
- Or on Windows: `& "${SKILL_DIR}\scripts\windows\hackmd_config.ps1" -Token <token>`
- Or set `HACKMD_API_TOKEN` environment variable

### Step 5: Upload to HackMD

**Linux/macOS:**
```bash
bash "${SKILL_DIR}/scripts/linux/hackmd_upload.sh" --file ~/mds/{category}/{filename}.md --tags "{category}"
```

**Windows:**
```powershell
& "${SKILL_DIR}\scripts\windows\hackmd_upload.ps1" -File "~/mds/{category}/{filename}.md" -Tags "{category}"
```

Permissions are automatically set to:
- `readPermission: "guest"` (everyone can read)
- `writePermission: "owner"` (only owner can edit)
- View mode by default

### Step 6: Report to User

Tell the user the share link and available follow-up commands:

```
已將筆記上傳至 HackMD!
📎 分享連結: {publishLink}
📁 本地備份: ~/mds/{category}/{filename}.md
🏷️ 分類: {category}

目前權限設定:
  - 瀏覽模式: 檢視
  - 可閱讀: 所有人
  - 可編輯: 只有你

你可以告訴我:
  - 「修改權限」- 調整閱讀/編輯權限
  - 「修改標籤」- 新增或修改 HackMD 標籤
  - 「更新內容」- 同步修改到 HackMD
  - 「刪除筆記」- 從 HackMD 刪除
```

### Step 7: Handle Follow-up Requests

**Change permissions** (修改權限):
```bash
# Linux/macOS
bash "${SKILL_DIR}/scripts/linux/hackmd_update.sh" --note-id {noteId} --read-perm {value} --write-perm {value}
# Windows
& "${SKILL_DIR}\scripts\windows\hackmd_update.ps1" -NoteId {noteId} -ReadPerm {value} -WritePerm {value}
```
Valid values: `owner`, `signed_in`, `guest`

**Change tags** (修改標籤): Update the `###### tags:` line in the local file, then upload updated content.

**Update content** (更新內容):
```bash
# Linux/macOS
bash "${SKILL_DIR}/scripts/linux/hackmd_update.sh" --note-id {noteId} --file {local-file-path}
# Windows
& "${SKILL_DIR}\scripts\windows\hackmd_update.ps1" -NoteId {noteId} -File {local-file-path}
```

**Delete note** (刪除筆記):
```bash
# Linux/macOS
bash "${SKILL_DIR}/scripts/linux/hackmd_update.sh" --note-id {noteId} --delete
# Windows
& "${SKILL_DIR}\scripts\windows\hackmd_update.ps1" -NoteId {noteId} -Delete
```
