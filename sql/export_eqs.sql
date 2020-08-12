
CREATE OR REPLACE FUNCTION eqsGetGender(wikidataIds varchar[])
RETURNS VARCHAR AS $$
DECLARE
    r record;
    resultCount int;
    resultChar VARCHAR;
    curResultChar VARCHAR;
BEGIN
    resultChar := NULL;
    curResultChar := NULL;

    FOR r IN SELECT DISTINCT wikidataIdClass
                FROM wikidata_class_links WHERE wikidataIdEntity=ANY(wikidataIds)
    LOOP
        CASE r.wikidataIdClass
            WHEN 'Q6581097', 'Q15145778' THEN
                curResultChar := 'M';
            WHEN 'Q6581072', 'Q15145779' THEN
                curResultChar := 'F';
            WHEN 'Q1052281' THEN
                curResultChar := 'FX';
            WHEN 'Q2449503' THEN
                curResultChar := 'MX';
            WHEN 'Q1097630' THEN
                curResultChar := 'X';
            ELSE
                -- do nothing      
        END CASE;
        IF resultChar IS NOT NULL AND curResultChar != resultChar THEN
            return NULL;
        END IF;
        resultChar := curResultChar;
    END LOOP;
    return resultChar;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION eqsIsHuman(wikidataIds varchar[])
RETURNS BOOLEAN AS $$
DECLARE
    resultCount int;
BEGIN

    SELECT count(*) INTO resultCount
            FROM wikidata_class_links WHERE wikidataIdEntity=ANY(wikidataIds) AND wikidataIdClass IN ('Q5','Q2985549','Q20643955');
    if resultCount > 0 THEN
        return TRUE;
    ELSE
        return FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION eqsGetBirth(wikidataIds varchar[])
RETURNS INT AS $$
DECLARE
    resultYear int;
    curResultYear int;
    r record;
BEGIN
    resultYear := NULL;
    curResultYear := NULL;

    FOR r IN SELECT substr(jsonb_array_elements(data->'claims'->'P569')->'mainsnak'->'datavalue'->'value'->>'time', 1, 5)::int AS year FROM wikidata WHERE wikidataId=ANY(wikidataIds)
    LOOP
        curResultYear := r.year;
        IF resultYear IS NOT NULL AND curResultYear != resultYear THEN
            return NULL;
        END IF;
        resultYear := curResultYear;
    END LOOP;
    return resultYear;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION eqsGetDeath(wikidataIds varchar[])
RETURNS INT AS $$
DECLARE
    resultYear int;
    curResultYear int;
    r record;
BEGIN
    resultYear := NULL;
    curResultYear := NULL;

    FOR r IN SELECT substr(jsonb_array_elements(data->'claims'->'P570')->'mainsnak'->'datavalue'->'value'->>'time', 1, 5)::int AS year FROM wikidata WHERE wikidataId=ANY(wikidataIds)
    LOOP
        curResultYear := r.year;
        IF resultYear IS NOT NULL AND curResultYear != resultYear THEN
            return NULL;
        END IF;
        resultYear := curResultYear;
    END LOOP;
    return resultYear;
END;
$$ LANGUAGE plpgsql;