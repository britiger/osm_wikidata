-- Function for link classification to entities
CREATE OR REPLACE FUNCTION classifyAll()
RETURNS INT AS $$
DECLARE 
    resultCount int;
BEGIN
    WITH wc AS (SELECT wikidataId, unnest(found_in) AS found_in FROM wikidata_classes)
    INSERT INTO wikidata_class_links
    SELECT wc.wikidataId AS wikidataIdClass, wd.wikidataId AS wikidataIdEntity, wc.found_in AS wikidataProperty
                FROM wc
                INNER JOIN LATERAL (SELECT * 
                        FROM wikidata AS wdl
                        WHERE wc.wikidataId IN (
                                SELECT jsonb_array_elements(data->'claims'->wc.found_in)->'mainsnak'->'datavalue'->'value'->>'id' FROM wikidata wdi WHERE wdi.wikidataId=wdl.wikidataId
                            )
                    ) AS wd ON TRUE
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS resultCount = ROW_COUNT;
    CALL checkLoops();
    return resultCount;
END;
$$ LANGUAGE plpgsql;

-- Reset known loops wikidata entities
CREATE OR REPLACE PROCEDURE checkLoops()
LANGUAGE SQL
AS $$
    -- Mark these entrries as linked
    UPDATE wikidata SET linked=true WHERE wikidataID='Q23958852'; -- variable-order metaclass 
    UPDATE wikidata SET linked=true WHERE wikidataID='Q23960977'; -- (meta)class
    UPDATE wikidata SET linked=true WHERE wikidataID='Q19478619'; -- metaclass
    UPDATE wikidata SET linked=true WHERE wikidataID='Q5127848'; -- class
    UPDATE wikidata SET linked=true WHERE wikidataID='Q16889133'; -- class
    UPDATE wikidata SET linked=true WHERE wikidataID='Q151885'; -- concept
    UPDATE wikidata SET linked=true WHERE wikidataID='Q35120'; -- entity
$$;

-- Function for linking classify elements
CREATE OR REPLACE FUNCTION classifyLinkId(i_wikidataId varchar)
RETURNS INT AS $$
DECLARE 
    resultCount int;
BEGIN
    -- add classifications from dependencies (only direct)
    WITH depList AS (
        SELECT jsonb_array_elements(data->'claims'->prop)->'mainsnak'->'datavalue'->'value'->>'id' as depId
            FROM wikidata 
            INNER JOIN (SELECT propertyId AS prop FROM wikidata_subcategories) AS props ON TRUE
        WHERE wikidataId=i_wikidataId 
          AND wikidataId NOT IN('Q219160','Q173853') -- block Q5 - human for specific Ids
    )
    INSERT INTO wikidata_class_links
    SELECT wcl.wikidataIdClass, i_wikidataId AS wikidataIdEntity, wcl.wikidataProperty
        FROM wikidata_class_links AS wcl WHERE wikidataIdEntity IN (SELECT depId FROM depList)    
    ON CONFLICT DO NOTHING;

    GET DIAGNOSTICS resultCount = ROW_COUNT;
    IF resultCount > 0 THEN
        RAISE NOTICE 'Updated % for %.', resultCount, i_wikidataId;
    END IF;

    -- set entity as linked
    UPDATE wikidata SET linked=TRUE WHERE wikidataId=i_wikidataId;

    return resultCount;
END;
$$ LANGUAGE plpgsql;

SELECT classifyAll();
SELECT wikidataId, classifyLinkId(wikidataId) FROM wikidata;
