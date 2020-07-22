-- table
CREATE TABLE IF NOT EXISTS wikidata_classes (
    wikidataId VARCHAR(128) PRIMARY KEY,
    found_in VARCHAR(128)[],
    class_name VARCHAR(255)
);

-- adding classification
INSERT INTO wikidata_classes VALUES ('Q5', '{"P31","P279"}', 'human') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q6581097', '{"P21"}', 'human (male)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q15145778', '{"P21"}', 'human (male cis)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q6581072', '{"P21"}', 'human (female)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q15145779', '{"P21"}', 'human (female cis)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q1052281', '{"P21"}', 'human (female trans)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q2449503', '{"P21"}', 'human (male trans)') ON CONFLICT DO NOTHING;
INSERT INTO wikidata_classes VALUES ('Q1097630', '{"P21"}', 'human (intersex)') ON CONFLICT DO NOTHING;

INSERT INTO wikidata_classes VALUES ('Q10884', '{"P279"}', 'tree') ON CONFLICT DO NOTHING;

-- table
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
