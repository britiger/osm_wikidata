CREATE OR REPLACE VIEW osm_full_ways AS

SELECT * FROM osm_ways WHERE NOT(tags ? 'name:etymology:wikidata')
    UNION
SELECT ow.id, ow.version, ow.uid, ow.timestamp, ow.changeset, 
    ow.tags - 
       -- Clean some keys
       ARRAY['maxspeed', 'lit', 'cycleway', 'sidewalk', 'bicycle', 'foot', 'surface', 'postal_code', 'surface', 'smoothness', 'destination'] 
    || hstore('name:etymology:wikidata:gender', eqsGetGender(string_to_array(replace(ow.tags->'name:etymology:wikidata','; ',';'),';')))
    || hstore('name:etymology:wikidata:ishuman', eqsIsHuman(string_to_array(replace(ow.tags->'name:etymology:wikidata','; ',';'),';'))::TEXT)
    || hstore('name:etymology:wikidata:birth', eqsGetBirth(string_to_array(replace(ow.tags->'name:etymology:wikidata','; ',';'),';'))::TEXT)
    || hstore('name:etymology:wikidata:death', eqsGetDeath(string_to_array(replace(ow.tags->'name:etymology:wikidata','; ',';'),';'))::TEXT)
    || hstore('name:etymology:wikidata:image', eqsGetImage(string_to_array(replace(ow.tags->'name:etymology:wikidata','; ',';'),';'))::TEXT)
    || hstore('name:etymology:wikidata:classification', classification)
    || hstore('name:etymology:wikidata:name', COALESCE(wd.data->'labels'->'de'->>'value', wd.data->'labels'->'en'->>'value'))
    || hstore('name:etymology:wikidata:description', COALESCE(wd.data->'descriptions'->'de'->>'value', wd.data->'descriptions'->'en'->>'value'))
    , ow.nodes, ow.geom
FROM osm_ways ow
LEFT JOIN LATERAL (SELECT string_agg(DISTINCT class_name, ', ') AS classification FROM wikidata_class_links AS wcl
    LEFT JOIN wikidata_classes AS wdc ON wcl.wikidataIdClass=wdc.wikidataId AND wcl.wikidataProperty=ANY(found_in)
    WHERE wcl.wikidataIdEntity= ow.tags->'name:etymology:wikidata'
    ) AS wdclassify ON true
LEFT JOIN wikidata wd ON wd.wikidataid=ow.tags->'name:etymology:wikidata'
WHERE ow.tags ? 'name:etymology:wikidata';

CREATE OR REPLACE VIEW osm_full_relations AS

SELECT * FROM osm_relations WHERE NOT(tags ? 'name:etymology:wikidata')
    UNION
SELECT ow.id, ow.version, ow.uid, ow.timestamp, ow.changeset, 
    ow.tags - 
       -- Clean some keys
       ARRAY['maxspeed', 'lit', 'cycleway', 'sidewalk', 'bicycle', 'foot', 'surface', 'postal_code', 'surface', 'smoothness', 'destination'] 
    || hstore('name:etymology:wikidata:gender', eqsGetGender(string_to_array(replace(ow.tags->'name:etymology:wikidata','; ',';'),';')))
    || hstore('name:etymology:wikidata:ishuman', eqsIsHuman(string_to_array(replace(ow.tags->'name:etymology:wikidata','; ',';'),';'))::TEXT)
    || hstore('name:etymology:wikidata:birth', eqsGetBirth(string_to_array(replace(ow.tags->'name:etymology:wikidata','; ',';'),';'))::TEXT)
    || hstore('name:etymology:wikidata:death', eqsGetDeath(string_to_array(replace(ow.tags->'name:etymology:wikidata','; ',';'),';'))::TEXT)
    || hstore('name:etymology:wikidata:image', eqsGetImage(string_to_array(replace(ow.tags->'name:etymology:wikidata','; ',';'),';'))::TEXT)
    || hstore('name:etymology:wikidata:classification', classification)
    || hstore('name:etymology:wikidata:name', COALESCE(wd.data->'labels'->'de'->>'value', wd.data->'labels'->'en'->>'value'))
    || hstore('name:etymology:wikidata:description', COALESCE(wd.data->'descriptions'->'de'->>'value', wd.data->'descriptions'->'en'->>'value'))
    , ow.member_refs, ow.member_types, member_roles, ow.geom
FROM osm_relations ow
LEFT JOIN LATERAL (SELECT string_agg(DISTINCT class_name, ', ') AS classification FROM wikidata_class_links AS wcl
    LEFT JOIN wikidata_classes AS wdc ON wcl.wikidataIdClass=wdc.wikidataId AND wcl.wikidataProperty=ANY(found_in)
    WHERE wcl.wikidataIdEntity= ow.tags->'name:etymology:wikidata'
    ) AS wdclassify ON true
LEFT JOIN wikidata wd ON wd.wikidataid=ow.tags->'name:etymology:wikidata'
WHERE ow.tags ? 'name:etymology:wikidata';