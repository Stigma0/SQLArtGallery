-- Author: [Arda Derbent]

-- INSERT Trigger
-- Description: This trigger enforces a minimum starting price of $1,000 for any new original art piece 
-- from the 21st century being inserted into the art_piece table.
--Purpose: To enforce a minimum starting price for original 21st-century art pieces.
CREATE OR REPLACE TRIGGER trg_check_price_for_original_21st
BEFORE INSERT ON art_piece
FOR EACH ROW
WHEN (NEW.originality = 'Original' AND NEW.century = '21st' AND NEW.starting_price < 1000)
BEGIN
    RAISE_APPLICATION_ERROR(-20002, 'For original 21st-century art pieces, the starting price cannot be less than $1,000');
END;
/

-- Insert a New Artist:
INSERT INTO artist (id, name, country_of_birth, date_of_birth)
VALUES (1000000, 'Test Artist', 'Test Country', SYSDATE);

-- Attempt to insert an original 21st-century art piece with a starting price below the threshold
-- This should result in an error
INSERT INTO art_piece (id, name, sizes, century, originality, starting_price, artist_id)
VALUES (1000001, 'Test Art Piece 1000001', '20x30', '21st', 'Original', 500.00, 1000000);

-- Verify that the art piece was inserted
SELECT id, name FROM art_piece WHERE artist_id = 1000000;

-- Attempt to insert an original 21st-century art piece with a starting price above the threshold
-- This should succeed
INSERT INTO art_piece (id, name, sizes, century, originality, starting_price, artist_id)
VALUES (1000002, 'Test Art Piece 1000002', '30x40', '21st', 'Original', 1500.00, 1000000);

--Verify that the art piece was inserted
SELECT id, name FROM art_piece WHERE artist_id = 1000000;

-- Clean up test data
-- Delete the art pieces
DELETE FROM art_piece WHERE artist_id = 1000000;

-- Delete the test artist
DELETE FROM artist WHERE id = 1000000;

-- UPDATE Trigger
-- Description: This trigger ensures that updates to the paints_used in the painting table 
-- are limited to a set of predefined acceptable paint types.
--Purpose: To prevent changes to the paints_used attribute in the painting table that are not among a set of predefined values.
CREATE OR REPLACE TRIGGER trg_validate_paints_used
BEFORE UPDATE OF paints_used ON painting
FOR EACH ROW
DECLARE
    v_invalid_paint BOOLEAN := TRUE;
BEGIN
    -- List of acceptable paints
    IF :NEW.paints_used IN ('Oil', 'Acrylic', 'Watercolor') THEN
        v_invalid_paint := FALSE;
    END IF;

    -- If the new paint is not in the acceptable list, prevent the update
    IF v_invalid_paint THEN
        RAISE_APPLICATION_ERROR(-20003, 'Invalid paint type. Acceptable types are Oil, Acrylic, and Watercolor.');
    END IF;
END;
/

-- Insert a test artist
INSERT INTO artist (id, name, country_of_birth, date_of_birth)
VALUES (1000000, 'Test Artist', 'Test Country', SYSDATE);

-- Insert a test art piece related to the artist
INSERT INTO art_piece (id, name, sizes, century, originality, starting_price, artist_id)
VALUES (1000001, 'Test Art Piece 1000001', '20x30', '21st', 'Original', 1500.00, 1000000);

-- Insert a test painting linked to the art piece
INSERT INTO painting (paints_used, type_of_painting, art_piece_id)
VALUES ('Oil', 'Landscape', 1000001);

-- Select painting record before update attempts
SELECT * FROM painting WHERE art_piece_id = 1000001;

-- Attempt to update the painting with an unacceptable paint type
-- This should result in an error
UPDATE painting SET paints_used = 'Tempera' WHERE art_piece_id = 1000001;

-- Select painting record after failed update attempt
SELECT * FROM painting WHERE art_piece_id = 1000001;

-- Attempt to update the painting with an acceptable paint type
-- This should succeed
UPDATE painting SET paints_used = 'Acrylic' WHERE art_piece_id = 1000001;

-- Select painting record after successful update
SELECT * FROM painting WHERE art_piece_id = 1000001;

-- Clean up test data
-- Delete the test painting record
DELETE FROM painting WHERE art_piece_id = 1000001;

-- Delete the test art piece
DELETE FROM art_piece WHERE id = 1000001;

-- Delete the test artist
DELETE FROM artist WHERE id = 1000000;

-- DELETE TRIGGER
-- Description: This trigger prevents the deletion of an artist if they still have art pieces associated with them in the art_piece table.
--Purpose: To prevent the deletion of an artist who still has art pieces in the database.
CREATE OR REPLACE TRIGGER trg_prevent_artist_deletion
BEFORE DELETE ON artist
FOR EACH ROW
DECLARE
    v_art_piece_count NUMBER;
BEGIN
    -- Check how many art pieces are associated with the artist
    SELECT COUNT(*)
    INTO v_art_piece_count
    FROM art_piece
    WHERE artist_id = :OLD.id;

    -- If there are art pieces, prevent the deletion
    IF v_art_piece_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cannot delete artist with existing art pieces');
    END IF;
END;
/

-- Testing the trigger
-- Insert a New Artist:
INSERT INTO artist (id, name, country_of_birth, date_of_birth)
VALUES (1000000, 'Test Artist', 'Test Country', SYSDATE);
--Insert New Art Pieces Associated with the Artist:
INSERT INTO art_piece (id, name, sizes, century, originality, starting_price, artist_id)
VALUES (1000001, 'Test Art Piece 1000001', '20x30', '21st', 'Original', 1000.00, 1000000);

INSERT INTO art_piece (id, name, sizes, century, originality, starting_price, artist_id)
VALUES (1000002, 'Test Art Piece 1000002', '20x30', '21st', 'Original', 1000.00, 1000000);

INSERT INTO art_piece (id, name, sizes, century, originality, starting_price, artist_id)
VALUES (1000003, 'Test Art Piece 1000003', '20x30', '21st', 'Original', 1000.00, 1000000);

-- Verify that the artist and art pieces exist before attempting the deletion:
SELECT id, name FROM artist WHERE id = 1000000;
SELECT id, name FROM art_piece WHERE artist_id = 1000000;

-- Attempt to Delete the Artist (This should be prevented by the trigger):
DELETE FROM artist WHERE id = 1000000;

-- After Delete: Verify the artist was not deleted
SELECT id, name FROM artist WHERE id = 1000000;

--Now Delete the art pieces the artist has
DELETE FROM art_piece WHERE artist_id  =1000000;

--Try deleleting the artist again
DELETE FROM artist WHERE id = 1000000;

-- After Delete: Verify the artist was deleted
SELECT id, name FROM artist WHERE id = 1000000;
