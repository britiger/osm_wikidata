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

-- FUNCTION to calculate zxy for a point
-- USING: SELECT point_to_zxy(14, ST_SetSRID(ST_Point( 13.821, 54.0), 4326));
CREATE OR REPLACE FUNCTION point_to_zxy(zoom int, coord geometry)
RETURNS int[] 
AS $$
DECLARE
    zxy int[];
    max numeric := 20037508.34;
    res numeric := (max*2)/(2^zoom);
    x int;
    coordx float;
    y int;
    coordy float;
BEGIN
    coordx = ST_X(ST_Transform(coord, 3857));
    coordy = ST_Y(ST_Transform(coord, 3857));
    x = FLOOR((coordx + max) / res);
    y = FLOOR((max - coordy) / res);
    zxy = ARRAY[zoom, x, y]::int[];
    return zxy;
END
$$
LANGUAGE plpgsql
PARALLEL SAFE;

CREATE OR REPLACE FUNCTION zoom_out_xyz(tile int[], tozoom int)
RETURNS int[][]
AS $$
DECLARE
    zxy int[][3];
    nw int[];
    z int;
    x int;
    y int;
BEGIN
    zxy = ARRAY[tile];
    x = tile[2];
    y = tile[3];
    FOR z IN REVERSE (tile[1]-1)..tozoom LOOP
        x = FLOOR(x/2);
        y = FLOOR(y/2);
        nw = ARRAY[z,x,y];
        zxy = nw || zxy;
    END LOOP;

    return zxy;
END
$$
LANGUAGE plpgsql
PARALLEL SAFE;

CREATE OR REPLACE FUNCTION bbox_to_zxy(zoom int, tozoom int, bbox box2d)
RETURNS int[][]
AS $$
DECLARE
    zxy int[][3];
    nw int[];
    low int[];
    high int[];
    x int;
    y int;
BEGIN
    low = point_to_zxy(zoom, ST_SetSRID(ST_Point(ST_XMIN(bbox),ST_YMIN(bbox)),3857));
    high = point_to_zxy(zoom, ST_SetSRID(ST_Point(ST_XMAX(bbox),ST_YMAX(bbox)),3857));
    if low[2] = high[2] AND low[3] = high[3] THEN
        return zoom_out_xyz(low, tozoom);	
    ELSE
        zxy = ARRAY[ARRAY[NULL,NULL,NULL]::int[]]; -- need to append multiple Array
        FOR x IN (low[2])..(high[2]) LOOP
            FOR y IN (high[3])..(low[3]) LOOP
                nw = ARRAY[zoom, x, y];
                zxy = zoom_out_xyz(nw, tozoom) || zxy;
            END LOOP;
        END LOOP;
        zxy = zxy[1:array_upper(zxy, 1) - 1]; -- remove added NULL-value
        return zxy;
    END IF;
END
$$
LANGUAGE plpgsql
PARALLEL SAFE;

CREATE OR REPLACE FUNCTION add_zxy(tiles int[][])
RETURNS BOOLEAN
AS $$
DECLARE
    z int;
BEGIN
    FOR z IN 1..array_length(tiles, 1) LOOP
        EXECUTE format('INSERT INTO import_updated_zyx VALUES (%L,%L,%L) ON CONFLICT DO NOTHING', tiles[z][1], tiles[z][2], tiles[z][3]);
    END LOOP;

    return true;
END
$$
LANGUAGE plpgsql
PARALLEL SAFE;
