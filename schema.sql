DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS categories;


CREATE TABLE categories (
id serial PRIMARY KEY,
name text NOT NULL UNIQUE
);

CREATE TABLE items (
id serial PRIMARY KEY,
name text NOT NULL,
num_need int NOT NULL,
num_have int NOT NULL DEFAULT 0,
category_id int NOT NULL REFERENCES categories(id) ON DELETE CASCADE
);

INSERT INTO categories (name)
VALUES ('Tea Set'), ('Condiments'), ('Plates'), 
('Cups and Mugs'), ('Canisters'), ('Bowls'), 
('Serving Pieces'), ('Miscellaneous');

INSERT INTO items (name, num_need, num_have, category_id)
VALUES ('Tea Cups', 8, 1, 1), ('Saucers', 8, 1, 1), ('Teapot', 1, 1, 1),
('Small Salt & Pepper', 1, 0, 2), ('Large Salt & Pepper', 1, 0, 2), ('Salt Mill', 1, 1, 2),
('Pepper Mill', 1, 1, 2), ('Oil Cruet', 1, 0, 2), ('Vinegar Cruet', 1, 0, 2), ('Condiment Tray', 1, 0, 2),
('Dinner Plates', 8, 8, 3), ('Luncheon Plates', 8, 0, 3), ('Salad Plates', 8, 1, 3), ('Bread Plates', 8, 8, 3),
('Crescent Plates', 8, 0, 3), ('Small Coffee Mugs', 8, 0, 4), ('Large Coffee Mugs', 8, 0, 4), 
('Juice Cups', 8, 0, 4), ('Flour Canister', 1, 1, 5), ('Sugar Canister', 1, 1, 5), ('Coffee Canister', 1, 1, 5),
('Tea Canister', 1, 1, 5), ('Soup Bowls', 8, 4, 6), ('Berry Bowls', 8, 8, 6), ('Butter Dish', 1, 1, 2), 
('Mustard Jar', 1, 0, 2), ('Gravy Boat', 1, 1, 2), ('Ladle', 1, 1, 2), ('Creamer', 1, 1, 2), ('Sugar Bowl', 1, 1, 2),
('Large Pitcher', 1, 0, 7), ('Medium Pitcher', 1, 0, 7), ('Small Pitcher', 1, 0, 7), 
('Chop Plate', 1, 0, 7), ('Medium Serving Platter', 1, 0, 7), ('Large Serving Platter', 1, 0, 7),
 ('Serving Bowl', 1, 0, 7),  ('Large Serving Bowl', 1, 0, 7), ('Covered Casserole Dish', 1, 0, 7),
 ('Large Covered Casserole Dish', 1, 0, 7), ('Small Covered Casserole Dish', 1, 0, 7),
 ('Divided Serving Dish', 1, 0, 7), ('Large Ashtray', 1, 0, 8), ('Spoon Rest', 1, 1, 8), ('Egg Cups', 8, 0, 8);