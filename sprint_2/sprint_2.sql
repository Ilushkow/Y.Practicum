-- Создаем новый тип ENUM 
CREATE TYPE cafe.restaurant_type AS ENUM ('coffee_shop', 'restaurant', 'bar', 'pizzeria');

-- Создаем таблицу cafe.restaurants
CREATE TABLE IF NOT EXISTS cafe.restaurants(
	uuid UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
	district_id integer NOT NULL REFERENCES cafe.districts,
	name VARCHAR(50) NOT NULL UNIQUE,
	"type" cafe.restaurant_type NOT NULL,
	menu JSONB NOT NULL,
	"location" geometry(geometry, 4326)
);

-- Заполняем таблицу cafe.restaurants данными по ресторанам
INSERT INTO cafe.restaurants (name, "type", menu, "location", district_id)
SELECT DISTINCT m.cafe_name, s."type"::cafe.restaurant_type, m.menu, ST_SetSRID(ST_Point(longitude, latitude), 4326) AS "location", d.id 
FROM raw_data.sales s
JOIN raw_data.menu m ON s.cafe_name = m.cafe_name
JOIN cafe.districts d ON ST_Within(ST_SetSRID(ST_Point(longitude, latitude), 4326), d.geom);

-- Создаем таблицу cafe.managers
CREATE TABLE IF NOT EXISTS cafe.managers(
	uuid UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
	full_name varchar(50) NOT NULL,
	phone varchar(50)
);

-- Заполняем таблицу cafe.managers всеми уникальными сотрудниками
INSERT INTO cafe.managers(full_name, phone)
SELECT DISTINCT manager, manager_phone 
FROM raw_data.sales;

-- Создаем таблицу cafe.restaurant_manager_work_dates
CREATE TABLE IF NOT EXISTS cafe.restaurant_manager_work_dates(
	restaurant_uuid UUID NOT NULL REFERENCES cafe.restaurants,
	manager_uuid UUID NOT NULL REFERENCES cafe.managers,
	date_start date NOT NULL,
	date_end date NOT NULL,
	PRIMARY KEY (restaurant_uuid, manager_uuid)
);

-- Заполняем таблицу cafe.restaurant_manager_work_dates данными о работе менеджеров в ресторанах
INSERT INTO cafe.restaurant_manager_work_dates(restaurant_uuid, manager_uuid, date_start, date_end)
SELECT r."uuid", m."uuid", MIN(s.report_date) date_start, MAX(s.report_date) date_end
FROM cafe.managers m 
JOIN raw_data.sales s ON m.full_name = s.manager
JOIN cafe.restaurants r ON s.cafe_name = r."name" 
GROUP BY 1, 2
ORDER BY 1;

-- Создаем таблицу cafe.sales
CREATE TABLE IF NOT EXISTS cafe.sales(
	restaurant_uuid UUID NOT NULL REFERENCES cafe.restaurants,
	"date" date NOT NULL,
	avg_check numeric(6, 2) NOT NULL,
	PRIMARY KEY (restaurant_uuid, "date")
);

-- Заполняем таблицу cafe.sales всеми заказами
INSERT INTO cafe.sales(restaurant_uuid, "date", avg_check)
SELECT r."uuid", report_date, avg_check
FROM raw_data.sales s
JOIN cafe.restaurants r ON s.cafe_name = r."name";

-- Задание №1
CREATE VIEW IF NOT EXISTS cafe.top_3_restaurants_by_avg_check AS
WITH t1 AS (
    SELECT s.restaurant_uuid,
           ROUND(AVG(s.avg_check), 2) AS avg_check
    FROM cafe.sales s
    GROUP BY s.restaurant_uuid
),
t2 AS (
    SELECT r."name" AS restaurant_name,
           r."type" AS restaurant_type,
           t1.avg_check,
           ROW_NUMBER() OVER (PARTITION BY r."type" ORDER BY t1.avg_check DESC, r."name") AS rank
    FROM t1 
    JOIN cafe.restaurants r ON t1.restaurant_uuid = r.uuid
)
SELECT t2.restaurant_name,
       t2.restaurant_type,
       t2.avg_check
FROM t2
WHERE t2.rank <= 3;

-- Задание №2
CREATE MATERIALIZED VIEW IF NOT EXISTS cafe.avg_check_yearly_change AS
WITH t1 AS (
    SELECT s.restaurant_uuid,
           EXTRACT(YEAR FROM s.date) AS sale_year,
           ROUND(AVG(s.avg_check), 2) AS avg_check
    FROM cafe.sales s
    WHERE EXTRACT(YEAR FROM s.date) != 2023
    GROUP BY 1, 2
),
t2 AS (
    SELECT
        r."name" AS restaurant_name,
        r."type" AS restaurant_type,
        t1.sale_year,
        t1.avg_check,
        LAG(t1.avg_check) OVER (PARTITION BY r."name" ORDER BY t1.sale_year) AS prev_year_avg_check
    FROM t1
    JOIN cafe.restaurants r ON t1.restaurant_uuid = r.uuid
)
SELECT t2.restaurant_name,
       t2.restaurant_type,
       t2.sale_year,
       t2.avg_check,
       t2.prev_year_avg_check,
    ROUND(((avg_check - prev_year_avg_check) / prev_year_avg_check) * 100, 2) AS pct_change
FROM t2
WHERE prev_year_avg_check IS NOT NULL;

-- Задание №3
SELECT r."name" AS cafe_name,
       COUNT(DISTINCT m."manager_uuid") AS manager_change_cnt
FROM cafe.restaurants r
JOIN cafe.restaurant_manager_work_dates m ON r."uuid" = m."restaurant_uuid"
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- Задание №4
WITH t1 AS (
    SELECT r."name" AS pizzeria_name,
           COUNT(*) AS pizza_cnt,
           DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
    FROM cafe.restaurants r, jsonb_each_text(r."menu" -> 'Пицца') AS menu_items
    WHERE r."type" = 'pizzeria'
    GROUP BY 1
)
SELECT t1.pizzeria_name,
       t1.pizza_cnt
FROM t1
WHERE rank = 1;

-- Задание №5
WITH t1 AS (
    SELECT 
        r."name" AS pizzeria_name,
        'Пицца' AS dish_type,
        menu_items.key AS pizza_name,
        (menu_items.value::numeric) AS price
    FROM cafe.restaurants r, jsonb_each_text(r."menu"->'Пицца') AS menu_items
    WHERE r."type" = 'pizzeria'
),
t2 AS (
    SELECT
        pizzeria_name,
        dish_type,
        pizza_name,
        price,
        ROW_NUMBER() OVER (PARTITION BY pizzeria_name ORDER BY price DESC) AS rank
    FROM t1
)
SELECT t2.pizzeria_name,
       t2.dish_type,
       t2.pizza_name,
       t2.price
FROM t2
WHERE rank = 1
ORDER BY 1 ASC;

-- Задание №6
WITH t1 AS (
	SELECT ST_Distance(r."location"::geography, r2."location"::geography) "dist_rest",
		   r."name" "frst_rest",
		   r2."name" "sec_rest",
		   r."type" "type_rest"
	FROM cafe.restaurants r
	JOIN cafe.restaurants r2 ON r."type" = r2."type")
SELECT t1."frst_rest", 
	   t1."sec_rest", 
	   t1."type_rest",
	   MIN(t1."dist_rest") dist
FROM t1
WHERE t1."frst_rest" != t1."sec_rest"
GROUP BY t1."frst_rest", t1."sec_rest", t1."type_rest"
ORDER BY 1 ASC
LIMIT 1;

-- Задание №7
WITH t1 AS (
    SELECT d."name" AS "district_name", COUNT(r."uuid") AS "restaurant_cnt" 
    FROM cafe.restaurants r 
    JOIN cafe.districts d ON r.district_id = d.id 
    GROUP BY d."name"
)
SELECT *
FROM (
    SELECT t1."district_name", 
           t1."restaurant_cnt"
    FROM t1
    ORDER BY 2 DESC
    LIMIT 1
) AS district_max_restaurants

UNION ALL

SELECT *
FROM (
    SELECT t1."district_name", 
           t1."restaurant_cnt"
    FROM t1
    ORDER BY 2 ASC
    LIMIT 1
) AS district_min_restaurants;