-- CREATE VIEW to extracted and filter hstore data
CREATE OR REPLACE VIEW wikidata_osm_ways AS
SELECT id, tags -> 'name' AS name, tags->'wikidata' AS wikidata, tags->'name:etymology:wikidata' AS "name:etymology:wikidata", NULL::geometry AS geom
FROM osm_ways 
WHERE tags ? 'highway' AND tags ? 'name' AND tags -> 'highway' NOT IN('platform','A3.0','rest_area','bus_stop','elevator');

CREATE OR REPLACE VIEW wikidata_osm_relations AS
SELECT id, tags -> 'name' AS name, tags->'wikidata' AS wikidata, tags->'name:etymology:wikidata' AS "name:etymology:wikidata", NULL::geometry AS geom
FROM osm_relations
WHERE tags ? 'highway' AND tags ? 'name' AND tags -> 'highway' NOT IN('platform','A3.0','rest_area','bus_stop','elevator');

-- create fake-table for clustered_roads
CREATE OR REPLACE VIEW clustered_roads AS
SELECT name, string_to_array(replace("wikidata",'; ',';'),';') AS wikidata, string_to_array(replace("name:etymology:wikidata",'; ',';'),';') AS "name:etymology:wikidata", geom
FROM wikidata_osm_ways WHERE wikidata IS NOT NULL OR "name:etymology:wikidata" IS NOT NULL
UNION
SELECT name, string_to_array(replace("wikidata",'; ',';'),';') AS wikidata, string_to_array(replace("name:etymology:wikidata",'; ',';'),';') AS "name:etymology:wikidata", geom
FROM wikidata_osm_relations WHERE wikidata IS NOT NULL OR "name:etymology:wikidata" IS NOT NULL;
