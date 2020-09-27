SET client_min_messages TO WARNING;

-- CSV for other.csv
COPY (SELECT name, eqsGetGender("name:etymology:wikidata") AS gender, array_to_string("name:etymology:wikidata",',') AS wikidata, 'way' AS "type"
FROM clustered_roads 
WHERE st_within(geom,(SELECT geometry FROM imposm_admin WHERE osm_id=##RELATION##))
    AND eqsGetGender("name:etymology:wikidata") IS NULL
ORDER BY array_to_string("name:etymology:wikidata",','), name) TO STDOUT CSV HEADER;
