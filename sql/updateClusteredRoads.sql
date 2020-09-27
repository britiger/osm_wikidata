SET client_min_messages TO WARNING;

CREATE TABLE IF NOT EXISTS clustered_roads (
  osm_ids bigint[],
  name varchar(255),
  road_types text,
  cluster int,
  "name:etymology:wikidata" varchar(255)[],
  wikidata varchar(255)[],
  geom geometry(geometry, 3857)
);
CREATE INDEX IF NOT EXISTS imposm_roads_name_idx ON imposm_roads (name);

DO $$DECLARE r record;
BEGIN
    -- clean table
    DELETE FROM clustered_roads WHERE name IN (SELECT name FROM import_updated_roadnames);

    FOR r IN SELECT name FROM import_updated_roadnames WHERE name != '' AND name IS NOT NULL
    LOOP
        -- RAISE NOTICE 'Cluster road %', r.name;
        EXECUTE 'INSERT INTO clustered_roads 
                SELECT array_agg(osm_id) AS osm_ids,
                    name,
                    string_agg(DISTINCT cluster_tab.highway, '', '') AS road_types,
                    cluster, 
                    array_agg(DISTINCT cluster_tab."name:etymology:wikidata") FILTER (WHERE cluster_tab."name:etymology:wikidata" is not null) AS "name:etymology:wikidata",
                    array_agg(DISTINCT cluster_tab.wikidata) FILTER (WHERE cluster_tab.wikidata is not null) AS wikidata,
                    ST_SetSRID(st_union(cluster_tab.geometry),3857) AS geom
                FROM (SELECT    nullif(road.wikidata,'''') AS wikidata, 
                                unnest(
                                    case when road."name:etymology:wikidata" = '''' then
                                        ''{null}''::varchar(255)[]
                                    else
                                        string_to_array(replace(road."name:etymology:wikidata",''; '','';''),'';'')
                                    end
                                ) AS "name:etymology:wikidata",  
                                osm_id, 
                                name, 
                                highway,
                                ST_ClusterDBSCAN(geometry, eps := 100, minpoints := 1) over (PARTITION BY name) AS cluster,
                                geometry
                        FROM imposm_roads road
                        WHERE highway NOT IN(''platform'',''A3.0'',''rest_area'',''bus_stop'',''elevator'')) AS cluster_tab
                WHERE name=$1
                GROUP BY name, cluster' USING r.name;
    END LOOP;

    -- Delete processed names
    TRUNCATE TABLE import_updated_roadnames;
END$$;

CREATE INDEX IF NOT EXISTS clustered_roads_geom_idx ON clustered_roads USING GIST (geom);
