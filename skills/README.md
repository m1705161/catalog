# Скиллы для OpenCode — помощь маленькой модели

Скиллы диктуют маленькой модели (gemma4:e4b) порядок работы с каталогом OpenMetadata через MCP.
Подключаются через ../opencode.json: `"skills": {"paths": ["/skills"]}` (в Docker skills/ монтируется в /skills).

- om-catalog — найти и описать актив: search_metadata → get_entity_details → get_entity_lineage; FQN; «не выдумывать имена».
- om-investigate-lineage — расследование «почему упала метрика»: вверх по lineage, факт vs гипотеза.

FQN: `<сервис>.<база>.<схема>.<таблица>`. В стенде: сервис postgres, база retail, схемы stg/ods/dm.

Токен бота — переменная OM_BOT_TOKEN, подставляется как `{env:OM_BOT_TOKEN}`; реальный JWT в файлах не хранится.
