-- Lukasz Stanecki
-- Arda Derbent

-- Insert random data into art_enthusiast table
INSERT INTO art_enthusiast (ssn, art_enthusiast_name, enthusiast_address, contact_information)
SELECT
    TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(10000000000,99999999999))) AS ssn,

    dbms_random.string('U', 1) || dbms_random.string('L', floor(DBMS_RANDOM.VALUE(2,10))) || ' ' ||
    dbms_random.string('U', 1) || dbms_random.string('L', floor(DBMS_RANDOM.VALUE(2,10))) AS art_enthusiast_name,

    dbms_random.string('U', 1) || dbms_random.string('L', floor(DBMS_RANDOM.VALUE(4,10))) || ' ' ||
    dbms_random.string('U', 1) || dbms_random.string('L', floor(DBMS_RANDOM.VALUE(4,15))) || ' ' ||
    TO_CHAR(FLOOR(DBMS_RANDOM.VALUE(1, 100))) AS enthusiast_address,

    CASE WHEN FLOOR(DBMS_RANDOM.VALUE(0,2)) = 1 THEN
        dbms_random.string('A', floor(DBMS_RANDOM.VALUE(4,10))) || '@' ||
        dbms_random.string('A', floor(DBMS_RANDOM.VALUE(2,8))) || '.' ||
        dbms_random.string('A', floor(DBMS_RANDOM.VALUE(2,3)))
    ELSE
        '+1' || ' ' || TO_CHAR(FLOOR(DBMS_RANDOM.VALUE(1, 999)), 'FM000') || ' ' ||
        TO_CHAR(FLOOR(DBMS_RANDOM.VALUE(1, 9999)), 'FM0000') || ' ' ||
        TO_CHAR(FLOOR(DBMS_RANDOM.VALUE(1, 9999)), 'FM0000')
    END AS contact_information

FROM dual
CONNECT BY level <= 30;


-- Insert random data into artist table
INSERT INTO artist (id, artist_name, country_of_birth, date_of_birth)
SELECT
    level AS id,

    dbms_random.string('U', 1) || dbms_random.string('L', floor(DBMS_RANDOM.VALUE(2,10))) || ' ' ||
    dbms_random.string('U', 1) || dbms_random.string('L', floor(DBMS_RANDOM.VALUE(2,10))) AS artist_name,

    CASE WHEN FLOOR(DBMS_RANDOM.VALUE(0,10)) = 1 THEN
        NULL
    ELSE
        dbms_random.string('U', 1) || dbms_random.string('L', floor(DBMS_RANDOM.VALUE(4,10)))
    END AS contact_information,


    CASE WHEN FLOOR(DBMS_RANDOM.VALUE(0,10)) = 1 THEN
        NULL
    ELSE
        TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '1000-01-01','J') ,TO_CHAR(DATE '2023-12-31','J'))), 'J')
    END AS date_of_birth
   
FROM dual
CONNECT BY level <= 60; 

-- Insert random data into art_piece table
INSERT INTO art_piece (id, art_piece_name, sizes, century, originality, starting_price, artist_id)
SELECT
  level AS id,

  dbms_random.string('A', floor(DBMS_RANDOM.VALUE(1,25))) AS art_piece_name,

  dbms_random.string('A', 20) AS sizes,

  CASE WHEN FLOOR(DBMS_RANDOM.VALUE(0,10)) = 1 THEN
        NULL
    ELSE
        TO_CHAR(FLOOR(DBMS_RANDOM.VALUE(10, 22))) || 'th'
    END AS century,

  dbms_random.string('A', 10) AS originality,

  CASE WHEN FLOOR(DBMS_RANDOM.VALUE(0,10)) = 1 THEN
        NULL
    ELSE
        dbms_random.value(500, 10000)
    END AS starting_price,

    CASE WHEN level <= 60 THEN
      level
    ELSE
        FLOOR(DBMS_RANDOM.VALUE(1,61)) 
    END AS artist_id
  
FROM dual CONNECT BY level <= 200;


-- Insert random data into auction table
INSERT INTO auction (auction_number, auction_date, art_piece_id)
SELECT
    level AS auction_number,

    TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2023-01-01','J') ,TO_CHAR(DATE '2023-12-31','J'))), 'J') AS auction_date,

    FLOOR(DBMS_RANDOM.VALUE(1, 201)) AS art_piece_id

FROM dual CONNECT BY level <= 500;

-- Insert random data into purchase table
INSERT INTO purchase (purchase_number, purchase_date, art_enthusiast_ssn)
SELECT
    level AS purchase_number,

    TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '2023-01-01','J') ,TO_CHAR(DATE '2023-12-31','J'))), 'J') AS purchase_date,

    (SELECT ssn FROM art_enthusiast ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY) AS art_enthusiast_ssn
    -- Initialy associate all to one art_enthusiast because of problems with craeting corelated queries in insert in oracle

FROM dual CONNECT BY level <= 150;

-- updating data to randomise corelation with art enthusiasts
UPDATE purchase
SET art_enthusiast_ssn = (
    SELECT ssn
    FROM art_enthusiast
    WHERE art_enthusiast.ssn != purchase_number 
    ORDER BY DBMS_RANDOM.RANDOM
    FETCH FIRST 1 ROW ONLY
);

-- Insert random data into purchase_detail table
INSERT INTO purchase_detail (detail_id, price, purchase_number, art_piece_id)
SELECT
    level AS detail_id,

    dbms_random.value(500, 100000) AS price,

    CASE WHEN level <= 150 THEN
        level
    ELSE
        FLOOR(DBMS_RANDOM.VALUE(1, 151))
    END AS purchase_number,

    FLOOR(DBMS_RANDOM.VALUE(1, 200)) AS art_piece_id --We chose 200 to ensure at least 1 art piece isn't sold

FROM dual CONNECT BY level <= 300;

-- Insert a new artist with ID 61
INSERT INTO artist (id, artist_name, country_of_birth, date_of_birth)
VALUES (61, 'Random Artist Name', 'Country', (DATE '1000-01-01'));

-- Insert a new art piece with ID 201, connected to artist ID 61
INSERT INTO art_piece (id, art_piece_name, sizes, century, originality, starting_price, artist_id)
VALUES (201, 'Art Piece Name', 'Size', 'Century', 'Oryginal', 4000, 61); 

-- Insert a painting record for art piece ID 201
INSERT INTO painting (paints_used, type_of_painting, art_piece_id)
VALUES ('Paints Used', 'Type of Painting', 201); 
--These lines are here to ensure that we have at least 1 artist with only paintings to ensure some value in the select

-- Insert a new artist with ID 62
INSERT INTO artist (id, artist_name, country_of_birth, date_of_birth)
VALUES (62, 'Artist Name', 'Country', (DATE '1000-01-01'));

-- Insert a new art piece with ID 202, linked to artist ID 62
INSERT INTO art_piece (id, art_piece_name, sizes, century, originality, starting_price, artist_id)
VALUES (202, 'Art Piece Name', 'Size', '19th', 'Oryginal', 10000, 62); 

-- Classify this art piece as photography
INSERT INTO photography (type_of_photography, color, art_piece_id)
VALUES ('Type', 'Color', 202); 
--These lines ensure that we have at least 1 photography with correct century 

DECLARE 
  random_ssn art_enthusiast.ssn%TYPE;
  random_auction_number NUMBER;
  random_paints_used painting.paints_used%TYPE;
  random_type_of_painting painting.type_of_painting%TYPE;
  random_type_of_photography photography.type_of_photography%TYPE;
  random_color photography.color%TYPE;
  random_material_used sculpture.material_used%TYPE;
  random_art_piece_id NUMBER;
  temp NUMBER;
BEGIN
  -- Insert random data into auction_to_art_enthusiast table
  FOR i IN 1..2000 LOOP
    SELECT ssn INTO random_ssn FROM (
      SELECT ssn FROM art_enthusiast ORDER BY DBMS_RANDOM.VALUE
    ) FETCH FIRST 1 ROW ONLY;

    IF i <= 200 THEN
      random_auction_number := i;
    ELSE
      random_auction_number := FLOOR(DBMS_RANDOM.VALUE(1, 201));
    END IF;

    BEGIN
      INSERT INTO auction_to_art_enthusiast (auction_number, art_enthusiast_ssn)
      VALUES (random_auction_number, random_ssn);
      COMMIT;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    END;
  END LOOP;

  FOR i in 1..200 LOOP 
    BEGIN
      SELECT id INTO random_art_piece_id
      FROM art_piece
      WHERE id NOT IN (
        SELECT art_piece_id FROM painting
      ) AND id NOT IN (
        SELECT art_piece_id FROM photography
      ) AND id NOT IN (
        SELECT art_piece_id FROM sculpture
      ) FETCH FIRST 1 ROW ONLY;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        EXIT;
    END;

    temp := FLOOR(DBMS_RANDOM.VALUE(1,7));

    CASE WHEN temp = 1 THEN
        random_material_used := dbms_random.string('A', 10);
        BEGIN
          -- Insert random data into sculpture table
          INSERT INTO sculpture (material_used, art_piece_id)
          VALUES (random_material_used, random_art_piece_id);
          COMMIT;
        END;
      WHEN temp > 4 THEN
        -- Insert random data into photography table
        random_type_of_photography := dbms_random.string('A', 10);
        random_color := dbms_random.string('A', 10);
        BEGIN
          INSERT INTO photography (type_of_photography, color, art_piece_id)
          VALUES (random_type_of_photography, random_color, random_art_piece_id);
          COMMIT;
        END;
      ELSE
        -- Insert random data into painting table
        random_paints_used := dbms_random.string('A', 10);
        random_type_of_painting := dbms_random.string('A', 10);
        BEGIN
          INSERT INTO painting (paints_used, type_of_painting, art_piece_id)
          VALUES (random_paints_used, random_type_of_painting, random_art_piece_id);
          COMMIT;
        END;
    END CASE;
  END LOOP;
  

END;
