-- table
CREATE TABLE IF NOT EXISTS wikidata_classes (
    wikidataId VARCHAR(128) PRIMARY KEY,
    found_in VARCHAR(128)[],
    class_name VARCHAR(255)
);

-- adding classification
INSERT INTO wikidata_classes VALUES ('Q5', '{"P31","P279"}', 'human') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q2985549', '{"P31"}', 'mononymous person') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q20643955', '{"P31"}', 'human biblical figure') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q6581097', '{"P21"}', 'human (male)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q15145778', '{"P21"}', 'human (male cis)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q6581072', '{"P21"}', 'human (female)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q15145779', '{"P21"}', 'human (female cis)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q1052281', '{"P21"}', 'human (female trans)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q2449503', '{"P21"}', 'human (male trans)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q1097630', '{"P21"}', 'human (intersex)') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q10884', '{"P279"}', 'tree') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q958314','{"P31"}','grape variety') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q486972', '{"P279"}', 'human settlement') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q55659167', '{"P31","P279"}', 'natural watercourse') ON CONFLICT DO NOTHING;

-- table for subcategories
CREATE TABLE IF NOT EXISTS wikidata_subcategories (
    propertyId VARCHAR(128) PRIMARY KEY
);

-- add subcategories
INSERT INTO wikidata_subcategories VALUES ('P31') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_subcategories VALUES ('P171') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_subcategories VALUES ('P279') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_subcategories VALUES ('P361') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_subcategories VALUES ('P366') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_subcategories VALUES ('P427') ON CONFLICT DO NOTHING;

-- table for link the classification
CREATE TABLE IF NOT EXISTS wikidata_class_links (
    wikidataIdClass VARCHAR(128),
    wikidataIdEntity VARCHAR(128),
    wikidataProperty VARCHAR(64),
    CONSTRAINT class_link_unique UNIQUE (wikidataIdClass, wikidataProperty, wikidataIdEntity)
);

CREATE INDEX IF NOT EXISTS wikidata_class_links_entity_idx ON wikidata_class_links(wikidataIdEntity);
