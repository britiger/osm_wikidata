DELETE FROM import_updated_geoms WHERE bbox IS NULL;
WITH del AS (
    DELETE FROM import_updated_geoms RETURNING *
)
SELECT add_zxy(bbox_to_zxy(9, 9, bbox)),
add_zxy(bbox_to_zxy(10, 10, bbox)),
add_zxy(bbox_to_zxy(11, 11, bbox)),
add_zxy(bbox_to_zxy(12, 12, bbox)),
add_zxy(bbox_to_zxy(13, 13, bbox)),
add_zxy(bbox_to_zxy(14, 14, bbox)) FROM del;
