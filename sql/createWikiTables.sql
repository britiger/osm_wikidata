CREATE TABLE IF NOT EXISTS wikidata (
    wikidataId VARCHAR(128) PRIMARY KEY,
    data jsonb,
    categories VARCHAR(255)[],
    imported timestamp DEFAULT NOW()
);

CREATE UNLOGGED TABLE IF NOT EXISTS wikidata_import (
    data jsonb
);
