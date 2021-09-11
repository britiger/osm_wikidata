import http.server
import re
import os
import psycopg2

# Database to connect to
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

# HTTP server information
HOST = 'localhost'
PORT = 9009


########################################################################

class TileRequestHandler(http.server.BaseHTTPRequestHandler):

    DATABASE_CONNECTION = None

    # Search REQUEST_PATH for /{z}/{x}/{y}.{format} patterns
    def pathToTile(self, path):
        m = re.search(r'^\/(\d+)\/(\d+)\/(\d+)\.(\w+)', path)
        if (m):
            return {'zoom':   int(m.group(1)), 
                    'x':      int(m.group(2)), 
                    'y':      int(m.group(3)), 
                    'format': m.group(4)}
        else:
            return None


    # Do we have all keys we need? 
    # Do the tile x/y coordinates make sense at this zoom level?
    def tileIsValid(self, tile):
        if not ('x' in tile and 'y' in tile and 'zoom' in tile):
            return False
        if 'format' not in tile or tile['format'] not in ['pbf', 'mvt']:
            return False
        size = 2 ** tile['zoom'];
        if tile['x'] >= size or tile['y'] >= size:
            return False
        if tile['x'] < 0 or tile['y'] < 0:
            return False
        return True


    # Generate a SQL query to pull a tile worth of MVT data
    # from the table of interest.        
    def envelopeToSQL(self, tile):
        if tile['zoom'] < 11:
            tbl = TABLE_LOW.copy()
        else:
            tbl = TABLE_HIGH.copy()
        tbl['zoom'] = tile['zoom']
        tbl['y'] = tile['y']
        tbl['x'] = tile['x']
        # Materialize the bounds
        # Select the relevant geometry and clip to MVT bounds
        # Convert to MVT format
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


    # Run tile query SQL and return error on failure conditions
    def sqlToPbf(self, sql):
        # Make and hold connection to database
        if not self.DATABASE_CONNECTION:
            try:
                self.DATABASE_CONNECTION = psycopg2.connect(**DATABASE)
            except (Exception, psycopg2.Error) as error:
                self.send_error(500, "cannot connect: %s" % (str(DATABASE)))
                return None

        # Query for MVT
        with self.DATABASE_CONNECTION.cursor() as cur:
            cur.execute(sql)
            if not cur:
                self.send_error(404, "sql query failed: %s" % (sql))
                return None
            return cur.fetchone()[0]
        
        return None


    # Handle HTTP GET requests
    def do_GET(self):

        tile = self.pathToTile(self.path)
        if not (tile and self.tileIsValid(tile)):
            self.send_error(400, "invalid tile path: %s" % (self.path))
            return

        sql = self.envelopeToSQL(tile)
        pbf = self.sqlToPbf(sql)

        # self.log_message("path: %s\ntile: %s" % (self.path, tile))
        # self.log_message("sql: %s" % (sql))
        
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-type", "application/vnd.mapbox-vector-tile")
        self.end_headers()
        self.wfile.write(pbf)



########################################################################


with http.server.ThreadingHTTPServer((HOST, PORT), TileRequestHandler) as server:
    try:
        print("serving at port", PORT)
        server.serve_forever()
    except KeyboardInterrupt:
        if self.DATABASE_CONNECTION:
            self.DATABASE_CONNECTION.close()
        print('^C received, shutting down server')
        server.socket.close()



