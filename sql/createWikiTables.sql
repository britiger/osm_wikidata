SET client_min_messages TO WARNING;

-- table for all wikidata content
CREATE TABLE IF NOT EXISTS wikidata (
    wikidataId VARCHAR(128) PRIMARY KEY,
    data jsonb,
    linked boolean DEFAULT false,
    imported timestamp DEFAULT NOW()
);

-- temporary table for importing data
CREATE UNLOGGED TABLE IF NOT EXISTS wikidata_import (
    data jsonb
);

-- create table for wikidata entities needed by others for analyze
CREATE OR REPLACE VIEW wikidata_depenencies AS
SELECT jsonb_array_elements(data->'claims'->prop)->'mainsnak'->'datavalue'->'value'->>'id' as wikidataId,
    data->>'id' as wikidataSource,
    data->'labels'->'en'->>'value' as wikidataSourceName
FROM wikidata 
INNER JOIN (SELECT propertyId AS prop FROM wikidata_subcategories) AS props ON TRUE;

-- View for get all needed wikidata / need to import
CREATE OR REPLACE VIEW wikidata_needed AS
SELECT DISTINCT unnest(wikidata) AS wikidata FROM clustered_roads WHERE wikidata IS NOT NULL
    UNION 
SELECT DISTINCT unnest("name:etymology:wikidata") AS wikidata FROM clustered_roads WHERE "name:etymology:wikidata" IS NOT NULL
    UNION
SELECT DISTINCT wikidataId AS wikidata FROM wikidata_depenencies WHERE wikidataId IS NOT NULL
    UNION
SELECT wikidataId AS wikidata FROM wikidata_classes;
CREATE OR REPLACE VIEW wikidata_needed_import AS
SELECT DISTINCT trim(wikidata)::VARCHAR AS wikidata FROM wikidata_needed WHERE trim(wikidata) NOT IN(SELECT wikidataId FROM wikidata) AND wikidata!='' AND wikidata!='no';
