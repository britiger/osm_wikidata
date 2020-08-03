-- Table to store names of roads which are updated
CREATE TABLE IF NOT EXISTS import_updated_roadnames (
    name VARCHAR(255) UNIQUE
);

-- if create update all names
INSERT INTO import_updated_roadnames
SELECT DISTINCT name FROM imposm_roads
ON CONFLICT DO NOTHING;

-- create trigger for updates
CREATE OR REPLACE FUNCTION update_roadnames() RETURNS trigger AS
$$
BEGIN
	IF (TG_OP = 'DELETE') THEN
		INSERT INTO import_updated_roadnames (name) VALUES (OLD.name) ON CONFLICT DO NOTHING;
		RETURN OLD;
	ELSIF (TG_OP = 'UPDATE') THEN
		INSERT INTO import_updated_roadnames (name) VALUES (OLD.name) ON CONFLICT DO NOTHING;
        INSERT INTO import_updated_roadnames (name) VALUES (NEW.name) ON CONFLICT DO NOTHING;
		RETURN NEW;
	ELSIF (TG_OP = 'INSERT') THEN
		INSERT INTO import_updated_roadnames (name) VALUES (NEW.name) ON CONFLICT DO NOTHING;
		RETURN NEW;
	END IF;
END
$$
LANGUAGE plpgsql 
VOLATILE
PARALLEL SAFE;

CREATE TRIGGER trigger_update_roadnames BEFORE INSERT OR UPDATE OR DELETE ON imposm_roads FOR EACH ROW EXECUTE PROCEDURE update_roadnames();
