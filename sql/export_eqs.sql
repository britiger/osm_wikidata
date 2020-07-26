
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
