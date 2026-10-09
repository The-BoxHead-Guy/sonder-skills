---
name: ci-devops-expert
description: >
  Expert in CI/CD pipelines, DevOps infrastructure, and deployment automation.
  Activates when setting up CI workflows, configuring deployments, debugging
  pipeline failures, optimizing builds, managing infrastructure, or when the
  user mentions GitHub Actions, Nx CI/CD, deploy, VPS, Docker, SSL, Sentry,
  Horizon, Supervisor, backups, environment management, or server setup.
  Also activates for static analysis, code quality gates, security scanning,
  and release management. Uses the DataEmergencia monorepo as reference.
---

# CI & DevOps Expert

> **Core**: 500 lines — always loaded. **Detailed guidance** below the divider — load on demand.

## Core Philosophy

**Automate everything, document what can't be automated.** Every manual step is a potential failure point. Every undocumented procedure is knowledge lost.

**Reliability before velocity.** A fast pipeline that fails silently is worthless. A slower pipeline with proper verification, rollback, and observability is worth far more.

## Quick Reference

| Domain | Primary Tool | Key Pattern |
|--------|-------------|-------------|
| CI Orchestration | Nx (affected) | `nx affected -t ci-test --base=origin/main` |
| Runner | GitHub Actions | 5 workflows: build / test / analysis / format / deploy |
| Deploy | SSH + atomic symlink | `appleboy/ssh-action` → `ln -sfn releases/N current` → `systemctl reload php-fpm` |
| Queue | Laravel Horizon | `stopwaitsecs=3600`, `--max-time=3600`, `maxJobs=500` |
| Monitoring | Sentry (prod) + Telescope (dev) | Trace sampling 10%, breadcrumbs on all events |
| Backups | spatie/laravel-backup | S3 + local dual-destination, 7-day retention |
| Secrets | GCP Secret Manager | Runtime resolution via ServiceProvider, cached hourly |
| Static Analysis | PHPStan L5 + Pint + ESLint | Separate CI jobs, parallel execution |
| SSL | Let's Encrypt / Certbot | ECDSA P-256, OCSP stapling, auto-renew via systemd timer |

## CI/CD Pipeline Architecture

### Monorepo CI Flow (DataEmergencia Pattern)

```
GitHub PR
  ├── ci.yml        → nx affected -t build
  ├── tests.yml     → nx affected -t ci-test
  ├── analysis.yml  → nx affected -t analyse + lint + typecheck
  └── format.yml    → nx affected -t pint + format-assets → auto-commit

GitHub Push → main
  └── deploy.yml    → SSH into VPS → atomic symlink deploy
```

### Common Setup (All Workflows)

```yaml
steps:
  - uses: actions/checkout@v7
    with: { fetch-depth: 0, filter: tree:0 }
  - uses: shivammathur/setup-php@v2
    with: { php-version: '8.4', extensions: mbstring,xml,ctype,iconv,intl,pdo_sqlite,dom,filter,gd,json,pdo,tokenizer,fileinfo,openssl,zip, coverage: none }
  - uses: pnpm/action-setup@v6
  - uses: actions/setup-node@v6
    with: { node-version: 22, cache: pnpm }
  - run: pnpm install --frozen-lockfile
  - uses: actions/cache@v6.1.0
    with:
      path: apps/*/vendor
      key: ${{ runner.os }}-composer-${{ hashFiles('apps/*/composer.lock') }}
      restore-keys: ${{ runner.os }}-composer-
  - run: |
      git fetch origin main
      echo "BASE_SHA=$(git rev-parse origin/main)" >> $GITHUB_ENV
      echo "HEAD_SHA=HEAD" >> $GITHUB_ENV
```

### Nx as CI Orchestrator

Every workflow runs `pnpm exec nx affected -t <target> --parallel=3 --base=$BASE_SHA --head=$HEAD_SHA`.

| Target | Runs | Depends On |
|--------|------|------------|
| `ci-test` | `php artisan test --parallel` | `ci-test-setup` |
| `ci-test-setup` | `cp .env.example .env` + `key:generate` + `config:clear` | — |
| `build` | `vite build` | — |
| `build:php` | `composer install --optimize-autoloader` + migrate + caches + queue:restart | — |
| `analyse` | `vendor/bin/phpstan analyse --memory-limit=2G` | — |
| `pint` / `pint-check` | `vendor/bin/pint --parallel -v` / `--test` | — |
| `lint` | ESLint | — |
| `typecheck` | TypeScript (`tsc --noEmit`) | — |
| `format-assets` | `prettier --write ./resources` | — |

### Workflow Templates

**Build** (`ci.yml`): `on: pull_request` → `composer-install` → `build` (affected)  
**Tests** (`tests.yml`): `on: pull_request` → `composer-install` → `vite:build` → `ci-test` (affected)  
**Analysis** (`analysis.yml`): `on: pull_request` → `composer-install` → `analyse` + `lint` + `typecheck` (affected)  
**Format** (`format.yml`): `on: pull_request` → `composer-install` → `pint` + `format-assets` → `stefanzweifel/git-auto-commit-action`  
**Deploy** (`deploy.yml`): `on: push branches: [main]` → `appleboy/ssh-action` with secrets `VPS_HOST`, `VPS_USER`, `SSH_PRIVATE_KEY`, `VPS_DEPLOY_PATH`, `VPS_DEPLOY_COMMAND`

## Deployment Strategy

### Atomic Symlink Structure

```
/var/www/app/
  current -> releases/20260708_143000/     # Live (symlink)
  releases/20260708_100000/
  releases/20260708_143000/                # New release
  shared/.env                               # Shared config
  shared/storage/                           # Persistent files
```

### Deploy Sequence

```bash
# 1. Create release dir, clone code
mkdir -p releases/$(date +%Y%m%d_%H%M%S) && cd $_

# 2. Dependencies
composer install --no-dev --optimize-autoloader
npm ci && npm run build

# 3. Link shared resources
ln -sfn ../../shared/.env .env && ln -sfn ../../shared/storage storage

# 4. Optimization + migration
php artisan optimize && php artisan migrate --force

# 5. Atomic swap (zero-downtime)
ln -sfn $(pwd) ../current

# 6. Reload services
systemctl reload php8.4-fpm    # Clears OPcache, graceful
php artisan queue:restart      # Graceful Horizon restart

# 7. Health check
curl -f http://localhost/health || rollback
```

### Rollback (takes seconds)

```bash
cd /var/www/app
PREV=$(ls -t releases/ | sed -n '2p')
ln -sfn releases/$PREV current
systemctl reload php8.4-fpm && php artisan queue:restart
```

## Queue Workers (Horizon + Supervisor)

### Supervisor Config

```ini
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/app/current/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600 --queue=high,default,low
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=4
stopwaitsecs=3600    # Must exceed longest job
stdout_logfile=/var/log/supervisor/laravel-worker.log
```

### Horizon Config (Production)

```php
'supervisor-1' => [
    'connection' => 'redis',
    'queue' => ['critical', 'high', 'default', 'low'],
    'balance' => 'auto',
    'minProcesses' => 1,
    'maxProcesses' => 10,
    'balanceMaxShift' => 1,
    'balanceCooldown' => 3,
    'tries' => 3,
    'timeout' => 300,
],
```

**`stopwaitsecs=3600`** MUST exceed your longest job. Workers finish current job, then restart. Include `php artisan queue:restart` in every deploy.

## Monitoring

### Sentry (Laravel)

```bash
composer require sentry/sentry-laravel
php artisan sentry:publish --dsn=<dsn>
```

**Key config**: `traces_sample_rate=0.1`, `send_default_pii=false`, breadcrumbs on all events (logs, cache, SQL, queue, HTTP client, notifications), tracing on queue jobs + SQL + views.

**Release tracking**: `SENTRY_RELEASE=$(git rev-parse HEAD)` — associate errors with commits.

### Telescope

Enabled in `local` only (20+ watchers). Good for debugging queries, cache, queue, notifications during development.

### Health Check Scheduler

```php
// routes/console.php
Schedule::command('backup:monitor')->dailyAt('10:00');
Schedule::command('scrapmap:health-check')->everyFifteenMinutes();
```

## Backups (spatie/laravel-backup)

```php
'destination' => ['disks' => ['backups', 'backups_s3']],
'cleanup' => [
    'keepAllBackupsForDays' => 7,
    'keepDailyBackupsForDays' => 16,
    'keepWeeklyBackupsForWeeks' => 8,
    'keepMonthlyBackupsForMonths' => 4,
    'maxStorageInMegabytes' => 5000,
],
'notifications' => ['BackupHasFailed' => ['mail', 'slack']],
```

**Scheduler**: `backup:clean` 01:30, `backup:run --only-db` 02:00 daily, `backup:run` weekly Sunday 03:00.

## Server Commands

```bash
# PHP-FPM reload (zero-downtime, clears OPcache)
sudo systemctl reload php8.4-fpm

# Supervisor
sudo supervisorctl reload
sudo supervisorctl restart laravel-worker:*

# Horizon
php artisan queue:restart      # Graceful worker restart
php artisan horizon:terminate

# Redis
redis-cli -n 1 FLUSHDB         # Flush cache DB (db 1)

# Nginx
sudo nginx -t && sudo systemctl reload nginx

# SSL (Let's Encrypt)
sudo certbot --nginx --key-type ecdsa --elliptic-curve secp256r1 -d example.com
sudo certbot renew --dry-run   # Test auto-renewal
```

---

<!-- ======================================================================== -->
<!-- DETAILED GUIDANCE — load on demand -->
<!-- ======================================================================== -->

## Detailed Guidance (Load on Demand)

### PHP 8.4 OPcache Production

```ini
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=32
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0      # Eliminates stat() — CRITICAL for prod
opcache.save_comments=1            # Required for attributes
opcache.huge_code_pages=1
opcache.jit=tracing
opcache.jit_buffer_size=64M
```

### Nginx TLS (A+)

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
ssl_prefer_server_ciphers off;
ssl_ecdh_curve X25519:secp384r1:secp256r1;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 1d;
ssl_stapling on;
ssl_stapling_verify on;
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
```

### VPS RAM Budget (4GB)

| Service | Allocation |
|---------|-----------|
| OS | ~512 MB |
| MySQL (innodb_buffer_pool) | ~1.5 GB |
| Redis (maxmemory) | 256 MB |
| PHP-FPM (~50MB × 30 children) | ~1.5 GB |

**`pm.max_children`** = `(Total RAM − OS − Nginx − Redis − DB) / Avg PHP process size`. Use `pm = static` for predictable RAM.

### Security Gates in CI

```yaml
- run: pnpm audit --audit-level=high && composer audit
- run: pnpm exec nx affected -t analyse     # PHPStan
- run: pnpm exec nx affected -t pint-check  # Style enforcement
- run: pnpm exec nx affected -t lint        # ESLint
- run: pnpm exec nx affected -t typecheck   # TypeScript
```

### GitHub Actions Security Rules

| Rule | How |
|------|-----|
| Minimal permissions | `permissions: read-all` at top, override per-job |
| SHA pinning | Pin all `uses:` to full commit SHA |
| Environment protection | Required reviewers, branch restrictions for prod |
| No `pull_request_target` misuse | Only for labeling, never for checkout |
| Script injection prevention | Pass user values through `env:`, not inline |
| Dependabot | Enable for `github-actions` ecosystem |

### Project-Specific Reference

| App | Type | Test | Build | Monitoring |
|-----|------|------|-------|------------|
| `ssg.nexovial.net` | Laravel 13 API | `pest --parallel` | `vite build` | Sentry ❌, Telescope ❌ |
| `api.dataemergencia.com` | Laravel 12 API | `pest` | `composer install` | Backups ✅ |
| `carnets.qrnet.app` | Laravel 13 Inertia | `vitest + pest` | `vite build` | Sentry ✅, Telescope ✅ |
| `scaem.app` | Vanilla PHP | `pest --no-coverage` | `npm run build` | — |
| `sar.scaem.app` | Laravel 13 Inertia | `pest` | `vite build` | Sentry ✅ |
| `nexovial.net` | Laravel 12 Inertia | `vitest + pest` | `vite build` | — |
| `bp.scaem.app` | Laravel 12 | `pest` | `vite build` | — |

### Scheduled Tasks by App

| App | Key Tasks |
|-----|-----------|
| **ssg.nexovial.net** | reports:auto-close (hourly), backup (02:00), scrapmap:dispatch (5min), voices:cleanup (03:30) |
| **api.dataemergencia.com** | backup (02:30), fie:audit (5min), finances:debt (09:00), emails:prune (02:00) |
| **carnets.qrnet.app** | backup (02:00), carnets:expire (02:05), templates:clean (24h), codes:replenish (15min) |

### Infrastructure Stack

| Component | Spec |
|-----------|------|
| VPS | 6GB RAM, 2-4 vCPU |
| Web Server | Nginx + PHP 8.4 FPM |
| Database | MySQL 8+ |
| Cache / Queue | Redis (DB1, 300MB, allkeys-lru) |
| Process Manager | Supervisor |
| CDN | Netlify (frontends) |
| CI/CD | GitHub Actions → SSH deploy |
| Monitoring | Sentry (prod) / Telescope (dev) |
