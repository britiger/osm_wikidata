CREATE TABLE IF NOT EXISTS clustered_roads (
  osm_ids bigint[],
  name varchar(255),
  road_types text,
  cluster int,
  "name:etymology:wikidata" varchar(255)[],
  wikidata varchar(255)[],
  geom geometry
);

CREATE INDEX ON imposm_roads (name);

DO $$DECLARE r record;
BEGIN
    -- clean table
    TRUNCATE TABLE clustered_roads;

    FOR r IN SELECT DISTINCT name FROM imposm_roads WHERE name != '' AND name IS NOT NULL
    LOOP
        EXECUTE 'INSERT INTO clustered_roads 
                SELECT array_agg(osm_id) AS osm_ids,
                    name,
                    string_agg(DISTINCT cluster_tab.highway, '', '') AS road_types,
                    cluster, 
                    array_agg(DISTINCT cluster_tab."name:etymology:wikidata") FILTER (WHERE cluster_tab."name:etymology:wikidata" is not null) AS "name:etymology:wikidata",
                    array_agg(DISTINCT cluster_tab.wikidata) FILTER (WHERE cluster_tab.wikidata is not null) AS wikidata,
                    st_union(cluster_tab.geometry) AS geom
                FROM (SELECT    nullif(road.wikidata,'''') AS wikidata, 
                                unnest(
                                    case when road."name:etymology:wikidata" = '''' then
                                        ''{null}''::varchar(255)[]
                                    else
                                        string_to_array(road."name:etymology:wikidata",'';'')
                                    end
                                ) AS "name:etymology:wikidata",  
                                osm_id, 
                                name, 
                                highway,
                                ST_ClusterDBSCAN(geometry, eps := 100, minpoints := 1) over (PARTITION BY name) AS cluster,
                                geometry
                        FROM imposm_roads road) AS cluster_tab
                WHERE name=$1
                GROUP BY name, cluster' USING r.name;
    END LOOP;
END$$;
