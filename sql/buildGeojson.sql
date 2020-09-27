SET client_min_messages TO WARNING;

-- Function and Views to build an export geojson

-- View for build equalstreetnames feature
CREATE OR REPLACE VIEW eqs_features AS
SELECT name, 
    road_types,
    wikidata, 
    "name:etymology:wikidata", 
    eqsGetGender("name:etymology:wikidata") AS gender, 
    eqsIsHuman("name:etymology:wikidata") AS person, 
    wd.data->'labels' AS labels, 
    wd.data->'sitelinks' AS sitelinks,
    wd.data->'descriptions' AS descriptions,
    eqsGetBirth("name:etymology:wikidata") AS birth,
    eqsGetDeath("name:etymology:wikidata") AS death,
    eqsGetImage("name:etymology:wikidata") AS image,
    geom AS "geometry",
    json_build_object(
        'type', 'Feature',
        'id', osm_ids[1],
        'properties',
            json_build_object(
                'name', name,
                'wikidata', wikidata[1], -- TODO: how to output multiple ids?
                'gender', eqsGetGender("name:etymology:wikidata"),
                'details', json_build_object(
                    'wikidata', "name:etymology:wikidata"[1], -- TODO: how to output multiple ids?
                    'person', eqsIsHuman("name:etymology:wikidata"),
                    'labels', wd.data->'labels',
                    'descriptions', wd.data->'descriptions',
                    -- nicknames TODO
                    'gender', eqsGetGender("name:etymology:wikidata"),
                    'birth', eqsGetBirth("name:etymology:wikidata"),
                    'death', eqsGetDeath("name:etymology:wikidata"),
                    'image', eqsGetImage("name:etymology:wikidata"),
                    'sitelinks', wd.data->'sitelinks'
                )
            ),
        'geometry', ST_AsGeoJSON(ST_Transform(geom,4326))::json
    ) AS json_feature
FROM clustered_roads
    LEFT JOIN wikidata AS wd ON wd.wikidataId=any("name:etymology:wikidata");

