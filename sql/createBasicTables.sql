SET client_min_messages TO WARNING;

-- Table to store names of roads which are updated
CREATE TABLE IF NOT EXISTS import_updated_roadnames (
    name VARCHAR(255) UNIQUE
);

CREATE TABLE IF NOT EXISTS import_updated_geoms (
    bbox box2d
);

CREATE TABLE IF NOT EXISTS import_updated_zyx (
    zoom smallint NOT NULL,
    x int NOT NULL,
    y int NOT NULL,
    UNIQUE (zoom, x, y)
);

-- if create update all names
INSERT INTO import_updated_roadnames
SELECT DISTINCT name FROM imposm_roads
ON CONFLICT DO NOTHING;

INSERT INTO import_updated_geoms
SELECT ST_Extent(geometry) FROM imposm_admin;

-- create trigger for updates
CREATE OR REPLACE FUNCTION update_roadnames() RETURNS trigger AS
$$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO import_updated_roadnames (name) VALUES (OLD.name) ON CONFLICT DO NOTHING;
        INSERT INTO import_updated_geoms (bbox) VALUES (box2d(OLD.geometry)) ON CONFLICT DO NOTHING;
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO import_updated_roadnames (name) VALUES (OLD.name) ON CONFLICT DO NOTHING;
        INSERT INTO import_updated_roadnames (name) VALUES (NEW.name) ON CONFLICT DO NOTHING;
        INSERT INTO import_updated_geoms (bbox) VALUES (box2d(ST_Union(OLD.geometry,NEW.geometry))) ON CONFLICT DO NOTHING;
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO import_updated_roadnames (name) VALUES (NEW.name) ON CONFLICT DO NOTHING;
        INSERT INTO import_updated_geoms (bbox) VALUES (box2d(NEW.geometry)) ON CONFLICT DO NOTHING;
        RETURN NEW;
    END IF;
END
$$
LANGUAGE plpgsql 
VOLATILE
PARALLEL SAFE;

CREATE TRIGGER trigger_update_roadnames BEFORE INSERT OR UPDATE OR DELETE ON imposm_roads FOR EACH ROW EXECUTE PROCEDURE update_roadnames();
