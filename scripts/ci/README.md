# CI scripts (workspace)

Bu klasör workspace ürün reposu için CI yardımcı notlarını içerir.

## GitHub Actions workflow

Ana pipeline: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)

| Job | Amaç |
|-----|------|
| `backend-test` | `backend/` → `dotnet restore`, `build`, `test` (.NET 8) |
| `mobile-test` | `mobile/` → `flutter pub get`, `analyze`, `test` |
| `compose-validate` | `docker compose --env-file .env.example config` (`.env` CI'da yok) |

## Gerekli GitHub Secrets

| Secret | Açıklama |
|--------|----------|
| `CI_POSTGRES_PASSWORD` | Backend job Postgres service container parolası |

Workflow dosyasında düz metin parola **commit edilmez**.

## Yerel doğrulama

Orchestrator kökünden:

```bash
python scripts/verify_ci_setup.py --workspace path/to/workspace
```

Workspace kökünden compose:

```bash
docker compose --env-file .env.example -f docker-compose.yml config
```

Backend / mobile komutları orchestrator verify ile aynı dizinlerde çalışır (`backend/`, `mobile/`).

## Kapsam dışı

- Production deploy / `git push` otomasyonu (Aşama Deployment)
- Uygulama kodu değişiklikleri (Backend / Mobile agent)
