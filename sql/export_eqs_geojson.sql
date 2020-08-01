-- all.json
COPY (SELECT 
    json_build_object(
        'type', 'FeatureCollection',
        'features', jsonb_agg(json_feature)
    ) AS json_data
FROM eqs_features
WHERE st_within(geometry,(SELECT geometry FROM imposm_admin WHERE osm_id=##RELATION##))) TO STDOUT;
