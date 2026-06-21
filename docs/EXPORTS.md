# Exports & Backup

## Supported formats

| Format | Contents |
|--------|----------|
| **ZIP** | Media files + `metadata.json` + `source_urls.txt` + `README.txt` (attribution) |
| **JSON** | Full item metadata + export timestamp |
| **CSV** | Tabular summary (id, url, author, status, dates) |

## Architecture

```
ExportService (facade)
├── ZipExportService
├── MetadataExportService
└── CloudBackupService
    ├── WebDavBackupAdapter — PROPFIND test + PUT upload
    ├── S3BackupAdapter — AWS Sig V4 PUT (MinIO, R2, AWS)
    └── GoogleDriveBackupAdapter — OAuth deferred
```

## Creator-safe attribution

Every ZIP export includes `README.txt` reminding users to respect creators and platform terms.

## Pro gating

Batch ZIP export from library may require Pro; single-file share remains free.

## Future

- Scheduled backups to NAS / WebDAV
- Encrypted export archives
- Selective collection export UI polish
