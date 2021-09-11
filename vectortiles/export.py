
import pathlib
import os
import gzip
import psycopg2
from tqdm import tqdm
from multiprocessing import Pool, RLock

# Database connection from enviroment
DATABASE = {
    'user':     os.getenv('PGUSER', 'osm'),
    'password': os.getenv('PGPASSWORD', 'osm'),
    'host':     os.getenv('PGHOST', 'localhost'),
    'port':     os.getenv('PGPORT', '5432'),
    'database': os.getenv('PGDATABASE', 'osm_etymology')
    }

# Table to query for MVT data, and columns to
# include in the tiles.
TABLE_LOW = {
    'table':       'vector_lowlevel',
    'srid':        '3857',
    'geomColumn':  'geom',
    'attrColumns': 'array_to_json(osm_ids) AS osm_ids, array_to_json(wikidata) AS wikidata, name, road_types AS highway, array_to_json("name:etymology:wikidata") AS "name:etymology:wikidata"'
    }  

TABLE_HIGH = {
    'table':       'vector_highlevel',
    'srid':        '3857',
    'geomColumn':  'geom',
    'attrColumns': 'array_to_json(osm_ids) AS osm_ids, array_to_json(wikidata) AS wikidata, name, road_types AS highway, array_to_json("name:etymology:wikidata") AS "name:etymology:wikidata", wd_label AS "name:etymology:wikidata:name", wd_desc AS "name:etymology:wikidata:description", gender AS "name:etymology:wikidata:gender", ishuman AS "name:etymology:wikidata:human", birth AS "name:etymology:wikidata:birth", death AS "name:etymology:wikidata:death", image AS "name:etymology:wikidata:image", classification AS "name:etymology:wikidata:classification"'
    }  

database_connection = None
export_path=os.getenv('TILES_EXPORT_PATH', '/tmp/wikidata_tiles/')
compress=True

########################################################################

# Generate a SQL query to pull a tile worth of MVT data
def envelopeToSQL(tile):
    if tile['zoom'] < 11:
        tbl = TABLE_LOW.copy()
    else:
        tbl = TABLE_HIGH.copy()
    tbl['zoom'] = tile['zoom']
    tbl['y'] = tile['y']
    tbl['x'] = tile['x']

    sql_tmpl = """
        WITH
        d{table} AS (
            SELECT ST_CollectionExtract({geomColumn}, 2) AS d{geomColumn}, * FROM {table} WHERE {geomColumn} && ST_TileEnvelope({zoom}, {x}, {y}, margin => (64.0 / 4096))
            UNION ALL
            SELECT ST_CollectionExtract({geomColumn}, 3) AS d{geomColumn}, * FROM {table} WHERE {geomColumn} && ST_TileEnvelope({zoom}, {x}, {y}, margin => (64.0 / 4096))
        ),
        mvtgeom AS (
            SELECT ST_AsMVTGeom(ST_Transform(t.d{geomColumn}, 3857), ST_TileEnvelope({zoom}, {x}, {y}), extent => 4096, buffer => 64) AS geom,
                    {attrColumns}
            FROM d{table} t
        ) 
        SELECT ST_AsMVT(mvtgeom.*, 'wikidata') FROM mvtgeom
    """
    return sql_tmpl.format(**tbl)

def dbConnection():
    global database_connection
    # Make and hold connection to database
    if not database_connection:
        try:
            database_connection = psycopg2.connect(**DATABASE)
        except (Exception, psycopg2.Error) as error:
            print("cannot connect: %s" % (str(DATABASE)))
            return None

# Run tile query SQL and return error on failure conditions
def sqlToPbf(sql):
    global database_connection

    dbConnection()

    # Query for MVT
    with database_connection.cursor() as cur:
        cur.execute(sql)
        if not cur:
            print("sql query failed: %s" % (sql))
            return None
        return cur.fetchone()[0]
    
    return None


def exportTile(tile):
    sql = envelopeToSQL(tile)
    pbf = sqlToPbf(sql)
    
    pbf_path=export_path+"/"+str(tile['zoom'])+"/"+str(tile['x'])+"/"
    tile_name=pbf_path+str(tile['y'])+".pbf"

    pathlib.Path(pbf_path).mkdir(parents=True, exist_ok=True)

    if compress:
        tilesFile = gzip.open(tile_name, "wb")
    else:
        tilesFile = open(tile_name, "wb")

    tilesFile.write(pbf)
    tilesFile.close()


def exportTiles(for_zoom, process_pos):
    global database_connection
    
    sql = "SELECT zoom, x, y FROM import_updated_zyx WHERE zoom="+str(for_zoom)+" ORDER by zoom,x,y" 
    tqdm_text = "Level {}".format(for_zoom).zfill(2)

    dbConnection()
    with database_connection.cursor() as cur, database_connection.cursor() as cur_del:
        cur.execute(sql)
        if not cur:
            print("sql query failed: %s" % (sql))
            return None
        rowcount = cur.rowcount
        if rowcount < 1:
            print("No tiles for export.")
            return
        row = cur.fetchone()
        last_zoom=row[0]
        pbar = tqdm(total=rowcount, desc=tqdm_text, position=(process_pos*2)+1, unit='tiles')
        for i in range(rowcount):
        # do something with row
            if last_zoom != row[0]:
                print("Zoom Level "+str(last_zoom)+" completed. Start exporting zoom level "+ str(row[0]))
            tile = {'zoom': row[0], 'x': row[1], 'y': row[2]}
            last_zoom = row[0]
            # print(str(rowpos) + "/" + str(rowcount) + " " + str(tile))
            exportTile(tile)
            cur_del.execute("DELETE FROM import_updated_zyx WHERE zoom = %s AND x = %s AND y = %s", (row[0],row[1],row[2]))
            database_connection.commit()
            row = cur.fetchone()
            pbar.update(1)

def main():
    from_zoom = 9
    to_zoom = 14
    num_processes = to_zoom-from_zoom+1

    pool = Pool(processes=num_processes, initargs=(RLock(),), initializer=tqdm.set_lock)
    jobs = [pool.apply_async(exportTiles, args=(z, z-from_zoom)) for z in range(from_zoom, to_zoom+1)]
    pool.close()
    result_list = [job.get() for job in jobs]
    print ("\n" * (num_processes*2))

if __name__ == "__main__":
    main()
