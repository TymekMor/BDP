CREATE EXTENSION POSTGIS;

-- 1. Zaimportuj następujące pliki shapefile do bazy:
-- - T2018_KAR_BUILDINGS
-- - T2019_KAR_BUILDINGS
-- Pliki te przedstawiają zabudowę miasta Karlsruhe w latach 2018 i 2019.
-- Znajdź budynki, które zos

SELECT * FROM t2018_kar_buildings;
SELECT * FROM t2019_kar_buildings;
DROP TABLE kar_building_changes;
CREATE TEMP TABLE kar_building_changes AS 
SELECT b.polygon_id AS id_2019, b.geom AS geom
FROM t2018_kar_buildings a
FULL OUTER JOIN t2019_kar_buildings b
ON a.polygon_id = b.polygon_id
WHERE a.polygon_id IS NULL -- nowy budynek w 2019
   OR NOT ST_Equals(a.geom, b.geom); -- zmieniony budynek

-- 2. Zaimportuj dane dotyczące POIs (Points of Interest) z obu lat:
-- - T2018_KAR_POI_TABLE
-- - T2019_KAR_POI_TABLE
-- Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub
-- wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.
WITH new_pois AS (
    SELECT t2019_kar_poi_table.poi_id,
       t2019_kar_poi_table.poi_name,
       t2019_kar_poi_table.type,
       t2019_kar_poi_table.geom
	FROM t2019_kar_poi_table
	LEFT JOIN t2018_kar_poi_table ON t2019_kar_poi_table.poi_id = t2018_kar_poi_table.poi_id
	WHERE t2018_kar_poi_table.poi_id IS NULL
)

SELECT new_pois.type, COUNT(new_pois.poi_id) AS poi_count
FROM new_pois
JOIN kar_building_changes
ON ST_DWithin(new_pois.geom, kar_building_changes.geom, 0.005) -- promień 500m
GROUP BY new_pois.type
ORDER BY poi_count DESC;

-- Zad 3
-- Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
-- T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.
CREATE TABLE new_streets AS SELECT * FROM t2019_kar_streets;

SELECT * 
FROM spatial_ref_sys
WHERE srid = 3068;  -- SRID dla DHDN.Berlin/Cassini

UPDATE new_streets SET geom = ST_SetSRID(geom, 3068);

-- Zad 4
-- Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
-- Użyj następujących współrzędnych:
-- X Y
-- 8.36093 49.03174
-- 8.39876 49.00644


CREATE TABLE input_points (id int, geom geometry);

INSERT INTO input_points VALUES (1, 'POINT(8.36093 49.0374)'), (2, 'POINT(8.39876 49.00644)');

-- Zad 5
--  Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych
-- DHDN.Berlin/Cassini.

UPDATE input_points SET geom = ST_SetSRID(geom, 3068);

-- 6. Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej
-- z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj
-- reprojekcji geometrii, aby była zgodna z resztą tabel

UPDATE t2019_kar_street_node SET geom = ST_SetSRID(geom, 3068);

WITH line_geom AS (
    SELECT ST_MakeLine(geom) AS line
    FROM input_points
),
nearby_nodes AS (
SELECT node_id, geom
FROM t2019_kar_street_node AS nodes, line_geom
WHERE ST_DWithin(nodes.geom, line_geom.line, 0.002)
)
SELECT * FROM nearby_nodes;

-- 7. Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
-- w odległości 300 m od parków (LAND_USE_A).

SELECT * FROM t2019_kar_poi_table poi 
JOIN t2019_kar_land_use_a ON ST_DWithin(poi.geom, t2019_kar_land_use_a.geom, 0.003)
WHERE poi.type = 'Sporting Goods Store'

-- 8. Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz
-- znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’.

CREATE TABLE T2019_KAR_BRIDGES (
    gid SERIAL PRIMARY KEY,
    geom geometry(Point)
);

INSERT INTO T2019_KAR_BRIDGES (geom)
SELECT ST_Intersection(r.geom, w.geom) AS geom
FROM t2019_kar_railways r
JOIN t2019_kar_water_lines w
ON ST_Intersects(r.geom, w.geom)
WHERE ST_GeometryType(ST_Intersection(r.geom, w.geom)) = 'ST_Point';


