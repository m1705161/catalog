# OpenMetadata Data Catalog — учебный стенд

Локальный стенд для знакомства с data catalog на примере OpenMetadata 2.0.8:

1. поднимаем OpenMetadata в Docker;
2. поднимаем учебный PostgreSQL со слоями `stg` / `ods` / `dm` и сгенерированными данными;
3. добавляем Postgres как источник и видим таблицы в каталоге;
4. описываем данные (owner, domain, glossary, tags, tier);
5. рисуем lineage вручную;
6. добавляем проверки качества (Test Suite) и видим pass/fail.

Всё учебное и локальное: синтетические данные, демо-пароли, никаких корпоративных систем.

## Содержимое

| Файл | Назначение |
|---|---|
| [`README.md`](README.md) | этот файл |
| [`guide-catalog.md`](guide-catalog.md) | Шаг 1 — пошаговый гайд от запуска до lineage и проверок |
| [`step2-ai.md`](step2-ai.md) | Шаг 2 — Ollama + OpenCode + MCP OpenMetadata + скиллы |
| [`docker-compose.yml`](docker-compose.yml) | официальный Compose-файл OpenMetadata 2.0.8 |
| [`docker-compose.postgres.yml`](docker-compose.postgres.yml) | доп. Compose-файл с учебным PostgreSQL |
| [`postgres-init/`](postgres-init/) | SQL-скрипты: схемы, таблицы, генерация данных |
| [`skills/`](skills/) | скиллы-подсказки для локальной модели (Шаг 2) |

## Быстрый старт

```bash
mkdir -p ~/openmetadata-catalog && cd ~/openmetadata-catalog
# скопируй сюда все файлы из этой папки
docker compose -f docker-compose.yml -f docker-compose.postgres.yml up -d
```

Дальше — по [`guide-catalog.md`](guide-catalog.md).

## Креды (учебные, демо)

| Что | Значение |
|---|---|
| OpenMetadata UI | http://localhost:8585 |
| Логин admin | `admin@open-metadata.org` / `admin` |
| PostgreSQL | host `postgres`, port `5432`, user `demo`, password `demo`, db `retail` |

Внимание: host для источника в OpenMetadata — **`postgres`**, а не `localhost` (ingestion живёт внутри Docker-сети).
