-- Слои учебного хранилища для демо OpenMetadata.
-- Выполняется один раз при первой инициализации контейнера.

CREATE SCHEMA IF NOT EXISTS stg;   -- сырой слой (raw/staging)
CREATE SCHEMA IF NOT EXISTS ods;   -- очищенный/нормализованный слой
CREATE SCHEMA IF NOT EXISTS dm;    -- витрины данных (data marts)
