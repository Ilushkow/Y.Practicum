-- Команда на создание схемы raw_data
CREATE SCHEMA IF NOT EXISTS raw_data;

-- Команда на создание таблицы sales в схеме raw_data
CREATE TABLE IF NOT EXISTS raw_data.sales (
id integer NOT NULL,
auto char(30) NOT NULL,
gasoline_consumption real,
price NUMERIC(9,2) NOT NULL,
date date NOT NULL,
person_name char(50) NOT NULL,
phone char(50) NOT NULL,
discount integer NOT NULL,
brand_origin char(20) NULL);

-- Команда на копирование данных из файла cars.csv из локального расположения
COPY raw_data.sales(id, auto, gasoline_consumption, price, "date", person_name, phone, discount, brand_origin)
FROM '/usr/local/share/cars.csv' CSV HEADER NULL AS 'null';

-- Команда на создание схемы car_shop
CREATE SCHEMA IF NOT EXISTS car_shop;

-- Команда на создание таблицы users в схеме car_shop
CREATE TABLE IF NOT EXISTS car_shop.users(
id serial PRIMARY KEY,
name varchar(30) NOT NULL,
phone varchar(25) NOT NULL,
created_at timestamptz NOT NULL DEFAULT current_timestamp);

-- Команда на заполнение данными таблицы users в схеме car_shop из таблицы sales схемы raw_data
INSERT INTO car_shop.users (name, phone)
SELECT DISTINCT person_name, phone
FROM raw_data.sales
ON CONFLICT DO NOTHING; 

-- Команда на создание таблицы countries в схеме car_shop
CREATE TABLE IF NOT EXISTS car_shop.countries(
id serial PRIMARY KEY,
"name" varchar(15) NOT NULL,
created_at timestamptz NOT NULL DEFAULT current_timestamp);

-- Команда на заполнение данными таблицы countries в схеме car_shop из таблицы sales схемы raw_data
INSERT INTO car_shop.countries ("name")
SELECT DISTINCT brand_origin 
FROM raw_data.sales
WHERE raw_data.sales.brand_origin IS NOT NULL
ON CONFLICT DO NOTHING;

-- Команда на создание таблицы brands в схеме car_shop
CREATE TABLE IF NOT EXISTS car_shop.brands (
id serial PRIMARY KEY,
country_id integer REFERENCES car_shop.countries,
name varchar(10) NOT NULL,
created_at timestamptz NOT NULL DEFAULT current_timestamp);

-- Команда на заполнение данными таблицы brands в схеме car_shop
INSERT INTO car_shop.brands ("name", country_id)
SELECT DISTINCT split_part(s.auto, ' ', 1), c.id
FROM raw_data.sales s
LEFT JOIN car_shop.countries c ON s.brand_origin = c."name"
ORDER BY 2
ON CONFLICT DO NOTHING;

-- Команда на создание таблицы models в схеме car_shop
CREATE TABLE IF NOT EXISTS car_shop.models (
id serial PRIMARY KEY,
brand_id integer NOT NULL REFERENCES car_shop.brands,
name varchar(20) NOT NULL,
gasoline_consumption REAL,
created_at timestamptz NOT NULL DEFAULT current_timestamp);

-- Команда на заполнение данными таблицы models в схеме car_shop
INSERT INTO car_shop.models ("name", brand_id, gasoline_consumption)
SELECT DISTINCT TRIM(CONCAT(TRIM(split_part(s.auto, ' ', 2), ','), ' ', RTRIM(split_part(s.auto, ' ', 3), 'egyrdnoaplwbuik,')), ' '), b.id, s.gasoline_consumption
FROM raw_data.sales s
JOIN car_shop.brands b ON b."name" = split_part(s.auto, ' ', 1)
ORDER BY 3
ON CONFLICT DO NOTHING;

-- Команда на создание таблицы colors в схеме car_shop
CREATE TABLE IF NOT EXISTS car_shop.colors(
id serial PRIMARY KEY,
name varchar(10) NOT NULL,
created_at timestamptz NOT NULL DEFAULT current_timestamp);

-- Команда на заполнение данными таблицы colors в схеме car_shop из таблицы sales схемы raw_data
INSERT INTO car_shop.colors (name)
SELECT DISTINCT LTRIM(substr(auto, strpos(auto, ',')+1))
FROM raw_data.sales
ON CONFLICT DO NOTHING;

-- Команда на создание таблицы purchases в схеме car_shop
CREATE TABLE IF NOT EXISTS car_shop.purchases(
id serial PRIMARY KEY,
user_id integer NOT NULL REFERENCES car_shop.users,
model_id integer NOT NULL REFERENCES car_shop.models,
color_id integer NOT NULL REFERENCES car_shop.colors,
price numeric(7, 2) NOT NULL,
discount integer NOT NULL,
"date" date NOT NULL,
created_at timestamptz NOT NULL DEFAULT current_timestamp);

-- Команда на заполнение данными таблицы purchases в схеме car_shop из таблицы sales схемы raw_data
INSERT INTO car_shop.purchases (user_id, model_id, color_id, price, discount, date)
SELECT u.id user_id, m.id model_id, c.id color_id, s.price, s.discount, s."date"
FROM raw_data.sales s 
JOIN car_shop.users u ON s.person_name = u."name"
JOIN car_shop.colors c ON c."name" = split_part(s.auto, ', ', 2)
JOIN car_shop.models m ON m."name" = TRIM(CONCAT(TRIM(split_part(s.auto, ' ', 2), ','), ' ', RTRIM(split_part(s.auto, ' ', 3), 'egyrdnoaplwbuik,')), ' ')
ORDER BY 1
ON CONFLICT DO NOTHING;

-- Задание №1
SELECT ROUND(COUNT(CASE 
				WHEN m.gasoline_consumption IS NULL THEN 1
			END)*100.0 / COUNT(m.*), 4) nulls_percentage_gasoline_consumption
FROM car_shop.models m;

-- Задание №2
SELECT b."name" brand_name, EXTRACT(YEAR FROM p."date") "year", ROUND(AVG(p.price), 2) price_avg
FROM car_shop.purchases p 
JOIN car_shop.models m ON p.model_id = m.id 
JOIN car_shop.brands b ON m.brand_id = b.id
WHERE p.discount != 0
GROUP BY 1, 2
ORDER BY 1 ASC, 2 ASC;

-- Задание №3
SELECT EXTRACT(MONTH FROM p.date) "month", EXTRACT(YEAR FROM p.date) "year", ROUND(AVG(p.price), 2) price_avg
FROM car_shop.purchases p
WHERE EXTRACT(YEAR FROM p.date) = 2022
GROUP BY 1, 2;

-- Задание №4
SELECT u."name" person, STRING_AGG((b."name" || ' ' || m."name"), ', ') cars
FROM car_shop.purchases p 
JOIN car_shop.users u ON p.user_id = u.id
JOIN car_shop.models m ON p.model_id = m.id 
JOIN car_shop.brands b ON m.brand_id = b.id
GROUP BY 1
ORDER BY 1;

-- Задание №5
SELECT c.name brand_origin, 
	   MAX(p.price / (1 - p.discount / 100.0)) price_max, 
	   MIN(p.price / (1 - p.discount / 100.0)) price_min
FROM car_shop.purchases p 
JOIN car_shop.models m ON p.model_id = m.id 
JOIN car_shop.brands b ON m.brand_id = b.id 
JOIN car_shop.countries c ON b.country_id = c.id
GROUP BY 1;

-- Задание №6
SELECT COUNT(u.*) persons_from_usa_count
FROM car_shop.users u 
WHERE u.phone ILIKE '+1%';