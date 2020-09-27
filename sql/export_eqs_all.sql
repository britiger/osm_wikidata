SET client_min_messages TO WARNING;

CREATE OR REPLACE VIEW export_eqs_all AS 
SELECT name, 
    eqsGetGender("name:etymology:wikidata") AS gender,
    eqsIsHuman("name:etymology:wikidata") AS IsHuman,
    eqsGetBirth("name:etymology:wikidata") AS birth,
    eqsGetDeath("name:etymology:wikidata") AS death,
    array_to_string("name:etymology:wikidata",',') AS etymology, 
    classification,
    array_to_string(cr.wikidata,',') AS wikidata,
    cr.geom
FROM clustered_roads AS cr
    LEFT JOIN LATERAL (SELECT string_agg(DISTINCT class_name, ', ') AS classification FROM wikidata_class_links AS wcl
    LEFT JOIN wikidata_classes AS wdc ON wcl.wikidataIdClass=wdc.wikidataId AND wcl.wikidataProperty=ANY(found_in)
    WHERE wcl.wikidataIdEntity=ANY("name:etymology:wikidata")
    ) AS wdclassify ON true;

-- CSV for all.csv (new)
COPY (SELECT name, gender, birth, death, IsHuman, etymology, classification, wikidata
FROM export_eqs_all
WHERE st_within(geom,(SELECT geometry FROM imposm_admin WHERE osm_id=##RELATION##))
ORDER BY name) TO STDOUT CSV header;
