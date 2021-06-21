-- NOTE: Modified Version of openstreetmap-vecto => all highways are merged with osm_ways => osm_full_ways
-- Add view osm_full_ways in z10

-- Drop views
DROP MATERIALIZED VIEW osm_ways_z10;
DROP MATERIALIZED VIEW osm_ways_z11;
DROP MATERIALIZED VIEW osm_ways_z12;
DROP MATERIALIZED VIEW osm_ways_z13;
DROP VIEW osm_ways_z14;
DROP VIEW osm_ways_z15;
DROP VIEW osm_ways_z16;
DROP VIEW osm_ways_z17;
DROP VIEW osm_ways_z18;
DROP VIEW osm_ways_z19;
DROP VIEW osm_ways_z20;

DROP MATERIALIZED VIEW osm_relations_z10;
DROP MATERIALIZED VIEW osm_relations_z11;
DROP MATERIALIZED VIEW osm_relations_z12;
DROP MATERIALIZED VIEW osm_relations_z13;
DROP VIEW osm_relations_z14;
DROP VIEW osm_relations_z15;
DROP VIEW osm_relations_z16;
DROP VIEW osm_relations_z17;
DROP VIEW osm_relations_z18;
DROP VIEW osm_relations_z19;
DROP VIEW osm_relations_z20;

-- Ways
CREATE MATERIALIZED VIEW osm_ways_z10 AS
SELECT id, tags, geom
FROM (
    SELECT id, tags, st_simplifypreservetopology(geom, 78271.516953125 / POWER(2, 10)) as geom
    FROM osm_full_ways
    WHERE tags ?| ARRAY[
        'aeroway', 'amenity', 'boundary', 'amenity', 'highway', 'man_made',
        'landuse', 'natural','power', 'railway', 'route', 'waterway'
    ]
) AS osm_ways
WHERE geom IS NOT NULL;

CREATE MATERIALIZED VIEW osm_ways_z11 AS
SELECT id, tags, geom
FROM (
    SELECT id, tags, st_simplifypreservetopology(geom, 78271.516953125 / POWER(2, 11)) as geom
    FROM osm_full_ways
    WHERE tags ?| ARRAY[
        'aeroway', 'amenity', 'boundary', 'amenity', 'highway', 'man_made',
        'landuse', 'natural','power', 'railway', 'route', 'waterway'
    ]
) AS osm_ways
WHERE geom IS NOT NULL;

CREATE MATERIALIZED VIEW osm_ways_z12 AS
SELECT id, tags, geom
FROM (
    SELECT id, tags, st_simplifypreservetopology(geom, 78271.516953125 / POWER(2, 12)) as geom
    FROM osm_full_ways
    WHERE tags ?| ARRAY[
        'aeroway', 'amenity', 'boundary', 'amenity', 'highway', 'man_made',
        'landuse', 'natural','power', 'railway', 'route', 'waterway'
    ]
) AS osm_ways
WHERE geom IS NOT NULL;

CREATE MATERIALIZED VIEW osm_ways_z13 AS
SELECT id, tags, geom
FROM (
    SELECT id, tags, st_simplifypreservetopology(geom, 78271.516953125 / POWER(2, 13)) as geom
    FROM osm_full_ways
    WHERE tags ?| ARRAY[
        'aeroway', 'amenity', 'boundary', 'amenity', 'highway', 'man_made',
        'landuse', 'natural','power', 'railway', 'route', 'waterway'
    ]
) AS osm_ways
WHERE geom IS NOT NULL;


CREATE VIEW osm_ways_z14 AS SELECT id, tags, geom FROM osm_full_ways;
CREATE VIEW osm_ways_z15 AS SELECT id, tags, geom FROM osm_full_ways;
CREATE VIEW osm_ways_z16 AS SELECT id, tags, geom FROM osm_full_ways;
CREATE VIEW osm_ways_z17 AS SELECT id, tags, geom FROM osm_full_ways;
CREATE VIEW osm_ways_z18 AS SELECT id, tags, geom FROM osm_full_ways;
CREATE VIEW osm_ways_z19 AS SELECT id, tags, geom FROM osm_full_ways;
CREATE VIEW osm_ways_z20 AS SELECT id, tags, geom FROM osm_full_ways;

-- Relations
CREATE MATERIALIZED VIEW osm_relations_z10 AS
SELECT id, tags, geom
FROM (
    SELECT id, tags, st_simplifypreservetopology(geom, 78271.516953125 / POWER(2, 10)) as geom
    FROM osm_relations
    WHERE tags ?| ARRAY[
        'aeroway', 'amenity', 'boundary', 'amenity', 'highway', 'man_made',
        'landuse', 'natural','power', 'railway', 'route', 'waterway'
    ]
) AS osm_relations
WHERE geom IS NOT NULL;

CREATE MATERIALIZED VIEW osm_relations_z11 AS
SELECT id, tags, geom
FROM (
    SELECT id, tags, st_simplifypreservetopology(geom, 78271.516953125 / POWER(2, 11)) as geom
    FROM osm_relations
    WHERE tags ?| ARRAY[
        'aeroway', 'amenity', 'boundary', 'amenity', 'highway', 'man_made',
        'landuse', 'natural','power', 'railway', 'route', 'waterway'
    ]
) AS osm_relations
WHERE geom IS NOT NULL;

CREATE MATERIALIZED VIEW osm_relations_z12 AS
SELECT id, tags, geom
FROM (
    SELECT id, tags, st_simplifypreservetopology(geom, 78271.516953125 / POWER(2, 12)) as geom
    FROM osm_relations
    WHERE tags ?| ARRAY[
        'aeroway', 'amenity', 'boundary', 'amenity', 'highway', 'man_made',
        'landuse', 'natural','power', 'railway', 'route', 'waterway'
    ]
) AS osm_relations
WHERE geom IS NOT NULL;

CREATE MATERIALIZED VIEW osm_relations_z13 AS
SELECT id, tags, geom
FROM (
    SELECT id, tags, st_simplifypreservetopology(geom, 78271.516953125 / POWER(2, 13)) as geom
    FROM osm_relations
    WHERE tags ?| ARRAY[
        'aeroway', 'amenity', 'boundary', 'amenity', 'highway', 'man_made',
        'landuse', 'natural','power', 'railway', 'route', 'waterway'
    ]
) AS osm_relations
WHERE geom IS NOT NULL;

CREATE VIEW osm_relations_z14 AS SELECT id, tags, geom FROM osm_relations;
CREATE VIEW osm_relations_z15 AS SELECT id, tags, geom FROM osm_relations;
CREATE VIEW osm_relations_z16 AS SELECT id, tags, geom FROM osm_relations;
CREATE VIEW osm_relations_z17 AS SELECT id, tags, geom FROM osm_relations;
CREATE VIEW osm_relations_z18 AS SELECT id, tags, geom FROM osm_relations;
CREATE VIEW osm_relations_z19 AS SELECT id, tags, geom FROM osm_relations;
CREATE VIEW osm_relations_z20 AS SELECT id, tags, geom FROM osm_relations;


-- recreate index
CREATE INDEX IF NOT EXISTS osm_ways_z10_spgist ON osm_ways_z10 USING SPGIST (geom);
CREATE INDEX IF NOT EXISTS osm_ways_z11_spgist ON osm_ways_z11 USING SPGIST (geom);
CREATE INDEX IF NOT EXISTS osm_ways_z12_spgist ON osm_ways_z12 USING SPGIST (geom);
CREATE INDEX IF NOT EXISTS osm_ways_z13_spgist ON osm_ways_z13 USING SPGIST (geom);

CREATE INDEX IF NOT EXISTS osm_relations_z10_spgist ON osm_relations_z10 USING SPGIST (geom);
CREATE INDEX IF NOT EXISTS osm_relations_z11_spgist ON osm_relations_z11 USING SPGIST (geom);
CREATE INDEX IF NOT EXISTS osm_relations_z12_spgist ON osm_relations_z12 USING SPGIST (geom);
CREATE INDEX IF NOT EXISTS osm_relations_z13_spgist ON osm_relations_z13 USING SPGIST (geom);
