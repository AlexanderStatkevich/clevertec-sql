--Вывести к каждому самолету класс обслуживания и количество мест этого класса

SELECT aircraft_code, fare_conditions, COUNT(seat_no) AS seat_count
FROM seats
GROUP BY aircraft_code, fare_conditions;

--Найти 3 самых вместительных самолета (модель + кол-во мест)

SELECT model ->> (SELECT * FROM lang()) AS model, COUNT(seat_no) AS seat_count
FROM seats
         LEFT JOIN aircrafts_data ad ON ad.aircraft_code = seats.aircraft_code
GROUP BY ad.aircraft_code
ORDER BY seat_count DESC
LIMIT 3;

--Вывести код,модель самолета и места не эконом класса для самолета 'Аэробус A321-200' с сортировкой по местам

--Вывод с дублированием кода и модели
SELECT ad.aircraft_code, model ->> (SELECT * FROM lang()) AS model, seat_no
FROM aircrafts_data AS ad
         LEFT JOIN seats s USING (aircraft_code)
WHERE model ->> (SELECT * FROM lang()) = 'Аэробус A321-200'
  AND fare_conditions <> 'Economy'
ORDER BY seat_no;

--Вывод с агрегированием в массив
WITH required_aircraft_code AS (SELECT aircraft_code
                                FROM aircrafts_data
                                WHERE (model ->> (SELECT * FROM lang())) = 'Аэробус A321-200')
SELECT ad.aircraft_code, model ->> (SELECT * FROM lang()) AS model, ARRAY_AGG(seat_no) AS seat_numbers
FROM aircrafts_data AS ad
         LEFT JOIN seats s USING (aircraft_code)
WHERE ad.aircraft_code = (SELECT * FROM required_aircraft_code)
  AND fare_conditions <> 'Economy'
GROUP BY 1, 2
ORDER BY seat_numbers;

--Вывести города в которых больше 1 аэропорта (код аэропорта, аэропорт, город)

SELECT airport_code, airport_name ->> (SELECT * FROM lang()) AS name, city ->> (SELECT * FROM lang()) AS city
FROM airports_data
WHERE city = ANY (SELECT city
                  FROM airports_data
                  GROUP BY city
                  HAVING COUNT(airport_code) > 1);

-- Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация

CREATE INDEX registration_available
    ON flights (status) WHERE status IN ('Scheduled', 'Delayed', 'On Time');

SELECT flight_id, flight_no, scheduled_departure
FROM flights AS f
         INNER JOIN airports_data ad1 ON ad1.airport_code = f.arrival_airport
    AND ad1.city ->> (SELECT * FROM lang()) = 'Москва'
         INNER JOIN airports_data ad2 ON ad2.airport_code = f.departure_airport
    AND ad2.city ->> (SELECT * FROM lang()) = 'Екатеринбург'
WHERE (scheduled_departure - INTERVAL '1 hour') >= (SELECT * FROM bookings.NOW())
  AND status IN ('Scheduled', 'Delayed', 'On Time')
ORDER BY scheduled_departure
LIMIT 1;

--Вывести самый дешевый и дорогой билет и стоимость ( в одном результирующем ответе)

--Самый дешевый и догорогой учитывая сортировку
(SELECT ticket_no, amount
 FROM ticket_flights
 ORDER BY amount DESC
 LIMIT 1)
UNION
(SELECT ticket_no, amount
 FROM ticket_flights
 ORDER BY amount
 LIMIT 1);
--Все самые дешевые и самые дорогие
(SELECT ticket_no, amount
 FROM ticket_flights
 WHERE amount IN (SELECT amount
                  FROM ticket_flights
                  ORDER BY amount DESC
                  LIMIT 1))
UNION
(SELECT ticket_no, amount
 FROM ticket_flights
 WHERE amount IN (SELECT amount
                  FROM ticket_flights
                  ORDER BY amount
                  LIMIT 1))
ORDER BY amount;

-- Написать DDL таблицы Customers , должны быть поля id , firstName, LastName, email , phone. Добавить ограничения на поля ( constraints) .

CREATE TABLE customers
(
    id         bigserial PRIMARY KEY,
    first_name varchar(255) NOT NULL,
    last_name  varchar(255) NOT NULL,
    email      varchar(255) NOT NULL UNIQUE,
    phone      varchar(25)  NOT NULL
);

-- Написать DDL таблицы Orders , должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + ограничения

CREATE TABLE orders
(
    id          bigserial PRIMARY KEY,
    customer_id bigint REFERENCES customers (id),
    quantity    int NOT NULL
);

-- Написать 5 insert в эти таблицы

WITH customer_id AS (INSERT INTO customers (first_name, last_name, email, phone)
    VALUES ('name1', 'ivanov', 'email1', 375291112211) RETURNING id)
INSERT
INTO orders (customer_id, quantity)
VALUES ((SELECT * FROM customer_id), 15);

WITH customer_id AS (INSERT INTO customers (first_name, last_name, email, phone)
    VALUES ('name2', 'surname2', 'emeil2', 375291112222) RETURNING id)
INSERT
INTO orders (customer_id, quantity)
VALUES ((SELECT * FROM customer_id), 16);

WITH customer_id AS (INSERT INTO customers (first_name, last_name, email, phone)
    VALUES ('name3', 'surname3', 'email3', 375291112233) RETURNING id)
INSERT
INTO orders (customer_id, quantity)
VALUES ((SELECT * FROM customer_id), 17);

WITH customer_id AS (INSERT INTO customers (first_name, last_name, email, phone)
    VALUES ('name4', 'ivanov', 'email4', 375291112244) RETURNING id)
INSERT
INTO orders (customer_id, quantity)
VALUES ((SELECT * FROM customer_id), 18);

WITH customer_id AS (INSERT INTO customers (first_name, last_name, email, phone)
    VALUES ('name5', 'ivanov', 'email5', 375291112255) RETURNING id)
INSERT
INTO orders (customer_id, quantity)
VALUES ((SELECT * FROM customer_id), 19);

-- удалить таблицы

DROP TABLE customers,orders;

-- Написать свой кастомный запрос ( rus + sql)

-- Вывести фамилии и сумму заказов для каждой фамилии,
-- если фамилия заказчика повторяется более 2х раз и адрес почты содержит слово 'email'.

SELECT last_name, SUM(o.quantity)
FROM customers AS c
         LEFT JOIN orders AS o USING (id)
WHERE email LIKE 'email%'
GROUP BY last_name
HAVING COUNT(last_name) > 2;
