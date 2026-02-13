# HackMD API Quick Reference

Base URL: `https://api.hackmd.io/v1`

Authentication: `Authorization: Bearer <token>`

## Endpoints

### User Info
- `GET /me` - Get current user info (useful for verifying token)

### Notes

#### List Notes
- `GET /notes` - Get all notes in user's workspace

#### Get Note
- `GET /notes/:noteId` - Get a specific note with content
- Response includes: `id`, `title`, `tags`, `content`, `readPermission`, `writePermission`, `publishLink`, `shortId`

#### Create Note
- `POST /notes`
- Body (JSON):
```json
{
  "title": "Note title",
  "content": "# Markdown content",
  "readPermission": "guest",
  "writePermission": "owner",
  "commentPermission": "everyone"
}
```

| Field | Type | Values |
|-------|------|--------|
| title | string | Note title |
| content | string | Markdown content |
| readPermission | string | `owner`, `signed_in`, `guest` |
| writePermission | string | `owner`, `signed_in`, `guest` |
| commentPermission | string | `disabled`, `forbidden`, `owners`, `signed_in_users`, `everyone` |
| permalink | string | Custom URL slug |

- Response: `201 Created` with note object

**Title behavior:**
1. H1 header in content overrides the title field
2. If no H1, YAML metadata `title` is used
3. If neither, the `title` field or "Untitled" is used

**Permission rules:**
- Both `readPermission` and `writePermission` must be provided together
- `writePermission` must be stricter than or equal to `readPermission`

#### Update Note
- `PATCH /notes/:noteId`
- Body (JSON): any subset of `content`, `readPermission`, `writePermission`, `permalink`
- Response: `202 Accepted`

#### Delete Note
- `DELETE /notes/:noteId`
- Response: `204 No Content`

### History
- `GET /history` - Get read history

## Permission Values

| Value | Meaning |
|-------|---------|
| `owner` | Only the note owner |
| `signed_in` | Any signed-in HackMD user |
| `guest` | Anyone (including anonymous) |

## Tags

Tags are embedded in markdown content using this format:
```
###### tags: `tag1` `tag2` `tag3`
```

Place this line right after the H1 title for best results.

## Swagger Documentation

Interactive API docs: https://api.hackmd.io/v1/docs

## Token Management

Create tokens at: https://hackmd.io/settings#api
