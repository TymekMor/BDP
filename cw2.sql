create extension postgis;
create table roads (id integer, name varchar(255), geometry geometry)

insert into roads (id, name, geometry) values (1, 'roadX', 'LineString(0 4.5, 12 4.5)')
insert into roads (id, name, geometry) values (2, 'roadY', 'LineString(7.5 10.5,7.5 0)')

create table buildings (id integer, name varchar(255), geometry geometry)

TRUNCATE TABLE buildings;
INSERT INTO buildings (id, name, geometry) 
VALUES (1, 'BuildingA', 'Polygon((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))');
INSERT INTO buildings (id, name, geometry) 
VALUES (2, 'BuildingB', 'Polygon((4 7, 6 7, 6 5, 4 5, 4 7))');
INSERT INTO buildings (id, name, geometry) 
VALUES (3, 'BuildingC', 'Polygon((3 8, 5 8, 5 6,3 6, 3 8))');
INSERT INTO buildings (id, name, geometry) 
VALUES (4, 'BuildingD', 'Polygon((9 9, 10 9, 9 8, 10 8, 9 9))');
INSERT INTO buildings (id, name, geometry) 
VALUES (5, 'BuildingF', 'Polygon((1 2,2 2,2 1, 1 1, 2 1 , 1 2))');

create table poi (id integer, name varchar(255), geometry geometry);
TRUNCATE TABLE poi;
INSERT INTO poi (id, name, geometry) 
VALUES (1, 'K', 'Point(6 9.5)');
INSERT INTO poi (id, name, geometry) 
VALUES (2, 'I', 'Point(6.5 6)');
INSERT INTO poi (id, name, geometry) 
VALUES (3, 'J', 'Point(9.5 6)');
INSERT INTO poi (id, name, geometry) 
VALUES (4, 'G', 'Point(1 3.5)');
INSERT INTO poi (id, name, geometry) 
VALUES (5, 'H', 'Point(5.5 1.5)');

select * from poi;

-- 6a
SELECT SUM(ST_LENGTH(geometry)) FROM roads;

-- 6b
SELECT name,ST_AsText(geometry) as WKT,ST_Area(geometry) as area, ST_Perimeter(geometry) as perim FROM buildings
WHERE name LIKE '%A';

-- 6c
SELECT name,ST_Area(geometry) as area FROM buildings
ORDER BY name;

-- 6d
SELECT name,ST_Perimeter(geometry) as perim FROM buildings
ORDER BY ST_Area(geometry) DESC
LIMIT 2;

-- 6e
WITH crossed AS (SELECT 
    building.id AS building_id, 
    building.name AS building_name, 
    building.geometry AS building_geometry, 
    poi.id AS poi_id, 
    poi.name AS poi_name, 
    poi.geometry AS poi_geometry
FROM buildings AS building
CROSS JOIN poi)

SELECT ST_Distance(building_geometry,poi_geometry) FROM crossed
WHERE building_name LIKE '%C' AND poi_name = 'K';

-- 6f

SELECT ST_Area(
    ST_Difference(buildingC.geometry, 
                  ST_Buffer(buildingB.geometry, 0.5))
) AS area
FROM buildings AS buildingC, buildings AS buildingB
WHERE buildingC.name = 'BuildingC' 
  AND buildingB.name = 'BuildingB';

 -- 6g

SELECT building.name
FROM buildings AS building, roads AS road
WHERE road.name = 'roadX'
  AND ST_Y(ST_Centroid(building.geometry)) > ST_Y(ST_Centroid(road.geometry));

-- 6h
SELECT ST_Area(
    ST_SymDifference(
        buildingC.geometry, 
        'POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'::geometry
    )
) AS area
FROM buildings AS buildingC
WHERE buildingC.name = 'BuildingC';
