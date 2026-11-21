# Шаг 2 — Каталог + локальная LLM (всё в Docker)

> Продолжение [Шага 1](guide-catalog.md). Всё поднимается в Docker — на хосте ничего устанавливать не нужно.
> Ollama (локальная модель) → OpenCode (агент) → MCP OpenMetadata → скиллы для маленькой модели.

## Что строится

OpenCode v2 (Web UI, http://localhost:4096) берёт модель из Ollama (gemma4:e4b, 8B, tool-calling) и сам ходит в MCP OpenMetadata (http://openmetadata-server:8585/mcp). Скиллы в skills/ диктуют модели порядок работы.

Важно: **Ollama не ходит в MCP напрямую** — Ollama это только локальная модель. Соединяет всё агент OpenCode.

## Предпосылки
- Выполнен Шаг 1 (OpenMetadata + PostgreSQL подняты).
- Порты 11434 (Ollama) и 4096 (OpenCode) свободны.
- Модель gemma4:e4b (~9.6 ГБ) скачается при первом запуске.

## Пошагово

### 1. Токен бота для MCP
Открой http://localhost:8585 → Settings → Bots → ingestion-bot → Generate Token. Скопируй JWT:

```bash
export OM_BOT_TOKEN='<вставь JWT сюда>'
```

### 2. Поднять Ollama и OpenCode

```bash
docker compose -f docker-compose.yml -f docker-compose.postgres.yml \
               -f docker-compose.ollama.yml -f docker-compose.opencode.yml up -d
docker compose ps
```

Ожидаем: сервисы Up/healthy; execute_migrate_all вышел с кодом 0.

### 3. Загрузить модель

```bash
docker exec openmetadata_ollama ollama pull gemma4:e4b
```

### 4. Открыть Web UI

Браузер: http://localhost:4096 (логин/пароль из docker-compose.opencode.yml). Выбрать модель ollama/gemma4:e4b.

Проверка:

> Опиши таблицу postgres.retail.dm.orders_daily: что это, колонки, владелец.

Агент вызывает MCP-инструменты и возвращает описание из каталога = связка работает.

## Скиллы — помощь маленькой модели

- om-catalog: search_metadata → get_entity_details → get_entity_lineage; FQN; «не выдумывать имена».
- om-investigate-lineage: от dm.orders_daily вверх по lineage; факт vs гипотеза.

Скиллы лежат в skills/, подключены в opencode.json.

## Полный сценарий

```bash
cd ~/openmetadata-catalog
export OM_BOT_TOKEN='<JWT>'
docker compose -f docker-compose.yml -f docker-compose.postgres.yml \
               -f docker-compose.ollama.yml -f docker-compose.opencode.yml up -d
docker exec openmetadata_ollama ollama pull gemma4:e4b
```

В браузере http://localhost:4096 спроси:

> Почему метрика «оплаченные заказы за вчера» упала? Найди витрину, проследи lineage, проверь качество.

## Типовые сбои

┌─────────────────────────────┬────────────────────────────────┬────────────────────────────────────────┐
│           Симптом           │            Причина             │                Действие                │
├─────────────────────────────┼────────────────────────────────┼────────────────────────────────────────┤
│ Агент отвечает без каталога │ MCP не подключился             │ проверь токен и /mcp                   │
├─────────────────────────────┼────────────────────────────────┼────────────────────────────────────────┤
│ 401/403 на /mcp             │ токен невалиден/не бот         │ перегенерируй токен                    │
├─────────────────────────────┼────────────────────────────────┼────────────────────────────────────────┤
│ 404 на /mcp                 │ эндпоинта нет                  │ проверь версию OpenMetadata 2.0.8      │
├─────────────────────────────┼────────────────────────────────┼────────────────────────────────────────┤
│ Модель выдумывает таблицы   │ не отработал скилл             │ усиль правило «имена только из вывода» │
├─────────────────────────────┼────────────────────────────────┼────────────────────────────────────────┤
│ Модель забывает начало      │ малый контекст                 │ подними num_ctx на Ollama              │
├─────────────────────────────┼────────────────────────────────┼────────────────────────────────────────┤
│ Падает цепочка вызовов      │ 8B слабо держит многошаговость │ упрости вопрос                         │
└─────────────────────────────┴────────────────────────────────┴────────────────────────────────────────┘

## Проверить /mcp

```bash
curl -X POST http://localhost:8585/mcp -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"probe","version":"1.0"}}}'
```

Ответ `{"error":{"code":-32001,"message":"Missing bearer token"}}` = транспорт работает, не хватает токена.

## Итог

Ollama в Docker (gemma4:e4b), OpenCode v2 в Docker (Web UI), MCP через mcp.servers.openmetadata (Streamable HTTP), скиллы om-catalog и om-investigate-lineage. Хост не тронут.

## Источники

- https://docs.open-metadata.org/v2.0.x/how-to-guides/mcp/connect
- https://opencode.ai/docs/mcp-servers
- https://opencode.ai/docs/config
- https://docs.ollama.com/docker
