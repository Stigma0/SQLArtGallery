-- task 3 triggers
-- Assumption before runing any lines in this file ddl_corrected.sql and populating_script.sql (two out of 3 files sent during task 2) were run.
-- Lukasz Stanecki

-- In this task db changes are caused by line 
-- ALTER TABLE art_enthusiast
-- ADD amount_spent NUMBER(10, 2);
-- Used in deletion trigger.


-- Trigger on insert - this trigger is making sure that art_piece is assigned to only one category at a time
-- by deleting the previuce data when table with new category is added. This type of trigger can be useful when
-- after fixing mistakes in the database (misclasifying one of the art_pieces) previuce data might be left by mistake along with new one.
-- This trigger saves only in case of inserting to table sculpture for the sake of the test but
-- in normal system the same mechanism would be introduced on other types of tables (photography and painting) but in this test only sculpture will be tested and therefore it is the only one introduced.

-- Adding sample artist to which art pieces will be assigned.
INSERT INTO artist (id, name, country_of_birth, date_of_birth)
VALUES (63, 'Leonardo da Vinci', 'Italy', (DATE '1452-04-15'));

-- Inserting an art_piece of type painting to show the change.
INSERT INTO art_piece VALUES (203, 'Insert test art piece 1', '20x30', '21st', 'Original', 10000.00, 63);
INSERT INTO painting (paints_used, type_of_painting, art_piece_id)
VALUES ('Oil', 'Painting', 203);

-- Inserting another art_piece of type painting to show only the art piece of which the type was changed will be changed.
INSERT INTO art_piece VALUES (204, 'Insert test art piece 2', '30x40', '20th', 'Original', 15000.00, 63);
INSERT INTO painting (paints_used, type_of_painting, art_piece_id)
VALUES ('Watercolor', 'Painting', 204);

-- Initial select to show the state of the test before using the trigger (material used is an attribute of a sculpture and should be empty for painting).
SELECT ap.id, ap.name, p.paints_used, p.type_of_painting, s.material_used
FROM art_piece ap
LEFT JOIN sculpture s on s.art_piece_id = ap.id
LEFT JOIN painting p on p.art_piece_id = ap.id
WHERE ap.id IN (203, 204);

-- Adding a trigger on insert.
CREATE OR REPLACE TRIGGER delete_duplicate_art_piece_type_on_sculpture
BEFORE INSERT ON sculpture
FOR EACH ROW
DECLARE
  temp_art_piece_id NUMBER(9);
BEGIN
  temp_art_piece_id := :new.art_piece_id;

  DELETE FROM sculpture WHERE art_piece_id = temp_art_piece_id;

  DELETE FROM painting WHERE art_piece_id = temp_art_piece_id;

  DELETE FROM photography WHERE art_piece_id = temp_art_piece_id;
END;
/

-- Adding new type of sculpture to art_piece id 203 (changing its type).
INSERT INTO sculpture (material_used, art_piece_id)
VALUES ('Marble', 203);

-- Select to show the state of the test after using the trigger 
--(material used is an atribute of a sculpture and should be changed for art_piece id 203 and art_piece 204 should be unchanged).
SELECT ap.id, ap.name, p.paints_used, p.type_of_painting, s.material_used
FROM art_piece ap
LEFT JOIN sculpture s on s.art_piece_id = ap.id
LEFT JOIN painting p on p.art_piece_id = ap.id
WHERE ap.id IN (203, 204);



-- Trigger on insert - this trigger is making sure that art_piece created by given artist can not be older than the artis.
-- If artist's data of birth is by mistake set incorectly and their works centru is assumed incorectly this trigger makes sure to fix this mistake.
-- During artist date of birth update each if the new date is after art piece century this data is assumed to be wrong and century for this art piece is set to null.
-- In real system more sufisticated system should be introduced to make sure that information is not delted accidently because of incorect change in artist table.
-- This trigger asumes normal way of conting centuries (for example 18th century satarts 1701-01-01) without taking into acount how old the artist should be to make an art_piece.

-- Line nececery to see date in format YYYY-MM-DD istead of YY-MM-DD that is nececery in understanding this test.
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

-- Adding sample artist to which art pieces will be assigned.
INSERT INTO artist (id, name, country_of_birth, date_of_birth)
VALUES (64, 'Vincent van Gogh', 'Netherlands', (DATE '1753-03-30'));

-- To simplify the test art_piece type (sculpture, painting, photography) will not be set
-- Inserting an artpiece to show the change.
INSERT INTO art_piece VALUES (205, 'Edit test art piece 1', '20x30', '18th', 'Original', 40000.00, 64);

-- Inserting another artpiece to show only the art piece of which are after the new date of birth of artist will be changed.
INSERT INTO art_piece VALUES (206, 'Edit test art piece 2', '30x40', '19th', 'Original', 25000.00, 64);

-- Initial select to show the state of the test before using the trigger 
-- (assuming all previously inserted datas were correct (for the test they are) all centurys are after the date of birth).
SELECT 
    a.id as artist_id,
    a.name as artist_name,
    ap.id as art_piece_id,
    ap.name as art_piece_name,
    a.date_of_birth as artist_date_of_birth,
    ap.century as art_century
FROM art_piece ap
LEFT JOIN artist a on a.id = ap.artist_id
WHERE ap.id IN (205, 206);

-- Adding a trigger on edit.
CREATE OR REPLACE TRIGGER update_art_piece_century
AFTER UPDATE OF date_of_birth ON artist
FOR EACH ROW
DECLARE
    temp_artist_century VARCHAR2(10);
    temp_century_decide VARCHAR2(2);
    temp_century_compere varchar2(10);
BEGIN
    IF :NEW.date_of_birth IS NOT NULL THEN
        temp_artist_century := TO_CHAR(EXTRACT(YEAR FROM :NEW.date_of_birth));
        temp_century_decide := SUBSTR(temp_artist_century, 3, 2);
        temp_artist_century := SUBSTR(temp_artist_century, 1, 2);
    END IF;

    IF TO_NUMBER(temp_century_decide) != 0 THEN
        temp_artist_century := (TO_NUMBER(temp_artist_century) + 1);
    END IF;

    FOR art_rec IN (SELECT century, id FROM art_piece WHERE art_piece.artist_id = :NEW.id) LOOP
        temp_century_compere := SUBSTR(art_rec.century, 1, 2);

        IF TO_NUMBER(temp_century_compere) < TO_NUMBER(temp_artist_century) THEN
            UPDATE art_piece
            SET art_piece.century = NULL
            WHERE art_piece.id = art_rec.id;
            EXIT;
        END IF;
    END LOOP;
END;
/

-- Changing the date of birth of artist id 64.
UPDATE artist
SET date_of_birth = (DATE '1853-03-30')
WHERE id = 64;

-- Select to show the state of the test after using the trigger 
--(in art_piece id 205 with 18th century was replaced with null because 1853 is alredy 19th century where for art_piece id 206 there was no change).
SELECT 
    a.id as artist_id,
    a.name as artist_name,
    ap.id as art_piece_id,
    ap.name as art_piece_name,
    a.date_of_birth as artist_date_of_birth,
    ap.century as art_century
FROM art_piece ap
LEFT JOIN artist a on a.id = ap.artist_id
WHERE ap.id IN (205, 206);



-- Trigger on delete - this trigger is making sure that art_enthusiast's amount_spent (value conuting total spent by an artist) is consistant in case of delition of purchouce detail.
-- Deletion of purchouce detail can be caused because of detail being inputed by mistake or purchouce of specific art_piece not coming to fluition.
-- This test uses art_piece values from previuce tests if run separatly those values should be run first.

-- Adding sample art_enthusiast to which perchuces will be assigned.
INSERT INTO art_enthusiast (ssn, name, address, contact_information)
VALUES ('1', 'Test enthusiast for deletion test 1', 'Address 1', 'Contact 1');

-- Adding sample purchase where the purchase_detail will be modified.
INSERT INTO purchase (purchase_number, "date", art_enthusiast_ssn)
VALUES (151, (DATE '2024-01-19'), '1');

-- Adding sample purchase where the purchase_detail will not be modified to keep some value of Amount_spent.
INSERT INTO purchase (purchase_number, "date", art_enthusiast_ssn)
VALUES (152, (DATE '2024-01-19'), '1');

-- Adding sample purchase_detail to be deleted in the test.
INSERT INTO purchase_detail (detail_id, price, purchase_number, art_piece_id)
VALUES (301, 13000.00, 151, 203);

-- Adding sample purchase_detail not to be deleted in connected to the same purchase as deleted one.
INSERT INTO purchase_detail (detail_id, price, purchase_number, art_piece_id)
VALUES (302, 6050.00, 151, 204);

-- Adding sample purchase_detail that will not be modified to keep some value of Amount_spent (other than purchase_detail id 302).
INSERT INTO purchase_detail (detail_id, price, purchase_number, art_piece_id)
VALUES (303, 1550.00, 152, 205);

-- Adding sample purchase_detail that will not be modified to keep some value of Amount_spent (other than purchase_detail id 302).
INSERT INTO purchase_detail (detail_id, price, purchase_number, art_piece_id)
VALUES (304, 4500.00, 152, 206);

-- In delete trigger derived attributes will be used initialized.
ALTER TABLE art_enthusiast
ADD amount_spent NUMBER(10, 2);

-- Setting values for new attribute before using triggers.
UPDATE art_enthusiast ae
SET amount_spent = (
    SELECT SUM(pd.price)
    FROM purchase p
    LEFT JOIN purchase_detail pd ON p.purchase_number = pd.purchase_number
    WHERE p.art_enthusiast_ssn = ae.ssn
)
WHERE ae.ssn IN (SELECT art_enthusiast_ssn FROM purchase);

-- Initila select to show the state of the test before using the trigger 
-- (the value of amount_spent for tested art_enthusiast ssn 1 should be 25100 (13000 + 6050 + 1550 + 4500 = 25100))
-- (in this test some other 4 random art_enthusiast will act as a comparison that trigger modifies the values only for correct art_enthusiast).
SELECT ae.ssn, ae.name, ae.amount_spent
FROM art_enthusiast ae
ORDER BY ssn ASC
FETCH FIRST 5 ROWS ONLY;

-- Adding a trigger on delete.
CREATE OR REPLACE TRIGGER update_amount_spent
AFTER DELETE ON purchase_detail
FOR EACH ROW
DECLARE
    temp_purchase_amount NUMBER(10, 2);
BEGIN
    UPDATE art_enthusiast
    SET amount_spent = (NVL(amount_spent, 0) - :OLD.price)
    WHERE ssn = (SELECT art_enthusiast_ssn FROM purchase WHERE purchase_number = :OLD.purchase_number);
END;
/

-- Deleting the purchase_detail id 301 with perchouce price of 13000.
DELETE FROM purchase_detail
WHERE detail_id = 301;

-- Initila select to show the state of the test before using the trigger 
-- (the value of amount_spent for tested art_enthusiast SSN 1 should be 12100 (6050 + 1550 + 4500 = 12100))
SELECT ae.ssn, ae.name, ae.amount_spent
FROM art_enthusiast ae
ORDER BY ssn ASC
FETCH FIRST 5 ROWS ONLY;