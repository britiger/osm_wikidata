SET client_min_messages TO WARNING;

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

INSERT INTO wikidata_classes VALUES ('Q6581097', '{"P21"}', 'gender (male)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q15145778', '{"P21"}', 'gender (male cis)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q6581072', '{"P21"}', 'gender (female)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q15145779', '{"P21"}', 'gender (female cis)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q1052281', '{"P21"}', 'gender (female trans)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q2449503', '{"P21"}', 'gender (male trans)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q1097630', '{"P21"}', 'gender (intersex)') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q28640', '{"P31"}', 'profession') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q756', '{"P279"}', 'plant') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q10884', '{"P279"}', 'tree') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q729', '{"P279"}', 'animal') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q38829', '{"P31"}', 'animal') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q5113', '{"P171"}','bird') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q22007593', '{"P171"}','bird') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q5856078', '{"P171"}','bird') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q618828', '{"P171"}','butterfly') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q958314','{"P31"}','grape variety') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q6256', '{"P31","P279"}', 'country') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q486972', '{"P31","P279"}', 'human settlement') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q285451', '{"P31","P279"}', 'river system') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q23397', '{"P31"}', 'lake') ON CONFLICT DO NOTHING;

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

-- delete previous/replaced classes
DELETE FROM wikidata_classes WHERE wikidataId='Q55659167';
DELETE FROM wikidata_class_links WHERE wikidataIdClass='Q55659167';
