---
name: autohackmd
description: >
  Auto-save and upload Markdown notes to HackMD when creating study, research,
  or summary content. Use when AI creates markdown files with learning, research,
  or organizational content. Triggers on keywords: study, research, summary,
  學習, 研究, 整理, notes, 筆記, 知識整理.
metadata:
  openclaw:
    emoji: "📝"
    requires:
      anyBins: ["curl", "pwsh"]
      env: ["HACKMD_API_TOKEN"]
    primaryEnv: "HACKMD_API_TOKEN"
    os: ["darwin", "linux", "win32"]
---

# AutoHackMD

Automatically save markdown notes locally and upload them to HackMD when creating study, research, or summary content.

## Trigger Conditions

Activate this skill when ALL of the following are true:

1. You are creating or have just created a **markdown file** for the user
2. The content nature is one of:
   - **Study / Learning** (學習): tutorials, learning notes, course notes, study guides
   - **Research** (研究): research notes, analysis, investigation, technical deep-dives
   - **Summary / Organization** (整理): knowledge summaries, checklists, organized references, documentation

Do NOT trigger for: casual conversations, code-only files, config files, changelogs, or commit messages.

## Workflow

When triggered, execute these steps in order:

### Step 1: Classify Content

Determine the category based on content nature:

| Category | Keywords / Signals |
|----------|-------------------|
| `study` | learning, tutorial, course, study guide, 學習, 教學 |
| `research` | research, analysis, investigation, deep-dive, 研究, 分析 |
| `summary` | summary, organization, reference, checklist, 整理, 總結 |
| `others` | Does not fit above but still worth archiving |

### Step 2: Save Locally

Save the markdown file to `~/mds/{category}/`:

- Path: `~/mds/study/`, `~/mds/research/`, `~/mds/summary/`, or `~/mds/others/`
- Filename: `YYYYMMDD-HHMMSS-{sanitized-title}.md`
- Create the directory if it does not exist
- Sanitize title: lowercase, replace spaces with hyphens, remove special chars

### Step 3: Detect OS and Locate Scripts

Determine the script path based on the current OS. The `AUTOHACKMD_SKILL_DIR` variable should point to this skill's root directory.

- **Linux / macOS**: Use `scripts/linux/*.sh`
- **Windows**: Use `scripts/windows/*.ps1`

If the skill directory is unknown, check these common locations:
- `~/.cursor/skills/autohackmd/`
- `~/.openclaw/skills/autohackmd/`
- The repo where this file resides

### Step 4: Check Token

Before uploading, verify the HackMD API token exists:

**Linux/macOS:**
```bash
bash scripts/linux/hackmd_config.sh --verify
```

**Windows:**
```powershell
.\scripts\windows\hackmd_config.ps1 -Verify
```

If no token is found, guide the user:
1. Go to https://hackmd.io/settings#api
2. Click "Create API token"
3. Copy the token
4. Run: `hackmd_config.sh --token <token>` or `.\hackmd_config.ps1 -Token <token>`
5. Alternatively, set `HACKMD_API_TOKEN` environment variable

### Step 5: Upload to HackMD

**Linux/macOS:**
```bash
bash scripts/linux/hackmd_upload.sh --file ~/mds/{category}/{filename}.md --tags "{category}"
```

**Windows:**
```powershell
.\scripts\windows\hackmd_upload.ps1 -File "~/mds/{category}/{filename}.md" -Tags "{category}"
```

The script will:
- Set `readPermission: "guest"` (everyone can read)
- Set `writePermission: "owner"` (only the owner can edit)
- Set `commentPermission: "everyone"`
- Default to view mode (publishType: "view")
- Return JSON with `noteId`, `publishLink`, `shortId`, `title`

### Step 6: Report to User

After successful upload, tell the user:

```
已將筆記上傳至 HackMD!
📎 分享連結: {publishLink}
📁 本地備份: ~/mds/{category}/{filename}.md
🏷️ 分類: {category}

目前權限設定:
  - 瀏覽模式: 檢視
  - 可閱讀: 所有人
  - 可編輯: 只有你

你可以告訴我進行以下操作:
  - 「修改權限」- 調整閱讀/編輯權限
  - 「修改標籤」- 新增或修改 HackMD 標籤
  - 「更新內容」- 將修改後的內容同步到 HackMD
  - 「刪除筆記」- 從 HackMD 刪除此筆記
```

### Step 7: Handle Follow-up Requests

Listen for these user commands and execute accordingly:

**Change permissions** (修改權限 / change permissions):
```bash
# Linux/macOS
bash scripts/linux/hackmd_update.sh --note-id {noteId} --read-perm {value} --write-perm {value}
# Windows
.\scripts\windows\hackmd_update.ps1 -NoteId {noteId} -ReadPerm {value} -WritePerm {value}
```
Valid values: `owner`, `signed_in`, `guest`

**Change tags** (修改標籤 / change tags):
- Read the local file, update the `###### tags:` line, then:
```bash
# Linux/macOS
bash scripts/linux/hackmd_update.sh --note-id {noteId} --file {local-file-path}
# Windows
.\scripts\windows\hackmd_update.ps1 -NoteId {noteId} -File {local-file-path}
```

**Update content** (更新內容 / update content):
```bash
# Linux/macOS
bash scripts/linux/hackmd_update.sh --note-id {noteId} --file {local-file-path}
# Windows
.\scripts\windows\hackmd_update.ps1 -NoteId {noteId} -File {local-file-path}
```

**Delete note** (刪除筆記 / delete note):
```bash
# Linux/macOS
bash scripts/linux/hackmd_update.sh --note-id {noteId} --delete
# Windows
.\scripts\windows\hackmd_update.ps1 -NoteId {noteId} -Delete
```

## References

- For HackMD API details, see [references/hackmd-api.md](references/hackmd-api.md)
