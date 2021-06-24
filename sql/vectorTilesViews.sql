-- 
CREATE OR REPLACE VIEW vector_highlevel AS
SELECT wdata.*, cr.*,
    eqsGetGender("name:etymology:wikidata") AS gender,
    eqsIsHuman("name:etymology:wikidata") AS IsHuman,
    eqsGetBirth("name:etymology:wikidata") AS birth,
    eqsGetDeath("name:etymology:wikidata") AS death,
    eqsGetImage("name:etymology:wikidata") AS image,
    classification
FROM clustered_roads cr
    LEFT JOIN LATERAL (SELECT string_agg(DISTINCT class_name, ', ') AS classification FROM wikidata_class_links AS wcl
    LEFT JOIN wikidata_classes AS wdc ON wcl.wikidataIdClass=wdc.wikidataId AND wcl.wikidataProperty=ANY(found_in)
    WHERE wcl.wikidataIdEntity=ANY("name:etymology:wikidata")
    ) AS wdclassify ON true
    LEFT JOIN LATERAL (SELECT 
                            json_agg(COALESCE(wd.data->'labels'->'de'->>'value', wd.data->'labels'->'en'->>'value')) AS wd_label,
                            json_agg(COALESCE(wd.data->'descriptions'->'de'->>'value', wd.data->'descriptions'->'en'->>'value')) AS wd_desc
                        FROM wikidata wd WHERE wd.wikidataid=ANY("name:etymology:wikidata")) AS wdata ON true;

--
CREATE OR REPLACE VIEW vector_lowlevel AS
SELECT cr.*
FROM clustered_roads cr
WHERE "name:etymology:wikidata" IS NULL;