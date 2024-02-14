-- Lukasz Stanecki
-- Arda Derbent

-- Selecting all art pieces not associated with any purchases using a left join
SELECT art_piece.id
FROM art_piece
LEFT JOIN purchase_detail ON art_piece.id = purchase_detail.art_piece_id
WHERE purchase_detail.art_piece_id IS NULL;

-- Selecting all art enthusiasts that have at least one purchouce and payed more than avrage with nested not correlated queries, group by and having clause, aggregation functions and join
SELECT ae.SSN   
FROM art_enthusiast ae
WHERE ssn IN (
    SELECT p.art_enthusiast_ssn
    FROM purchase p
    JOIN purchase_detail pd ON p.purchase_number = pd.purchase_number
    GROUP BY p.art_enthusiast_ssn
    HAVING SUM(pd.price) > (
        SELECT AVG(total_price)
        FROM (
            SELECT p1.art_enthusiast_ssn, SUM(pd1.price) as total_price
            FROM purchase p1
            JOIN purchase_detail pd1 ON p1.purchase_number = pd1.purchase_number
            GROUP BY p1.art_enthusiast_ssn
        ) avg_subquery
    )
);

-- Selecting all artists that have their paintings in the database and no other type of art piece with logic operator in where clause and join
SELECT a.id
FROM artist a
WHERE a.id NOT IN (
    SELECT art_piece_id FROM sculpture
) AND a.id NOT IN (
    SELECT art_piece_id FROM photography 
) AND a.id IN (
    SELECT ap.artist_id
    FROM art_piece ap
    JOIN painting p ON ap.id = p.art_piece_id
);

-- Selecting art enthusiasts with at who spend at least 100000 and used their email (indicated by looking for @) in contact information in descending order with join and group by with having
SELECT ae.ssn, ae.contact_information, SUM(pd.price) total_purchase_amount
FROM art_enthusiast ae
JOIN purchase p ON ae.ssn = p.art_enthusiast_ssn
JOIN purchase_detail pd ON p.purchase_number = pd.purchase_number
WHERE ae.contact_information LIKE '%@%'
GROUP BY ae.ssn, ae.contact_information 
-- contact_information is included only because of oracle requirements all selected columns to be selected but other sql would work just with primary key (ssn)
HAVING SUM(pd.price) >= 100000
ORDER BY total_purchase_amount DESC;


-- Selecting art pieces that were on the most auctions without being sold with subqueries, group by with having, 2 types of join and agregation functions
SELECT art_piece_id, num_auctions
FROM (
    SELECT ap.id AS art_piece_id, COUNT(a.auction_number) num_auctions
    FROM art_piece ap
    JOIN auction a ON ap.id = a.art_piece_id
    LEFT JOIN purchase_detail pd ON ap.id = pd.art_piece_id
    GROUP BY ap.id
    HAVING COUNT(pd.detail_id) = 0
)
WHERE num_auctions = (
    SELECT MAX(num_auctions)
    FROM (
        SELECT COUNT(a.auction_number) num_auctions
        FROM art_piece ap
        JOIN auction a ON ap.id = a.art_piece_id
        LEFT JOIN purchase_detail pd ON ap.id = pd.art_piece_id
        GROUP BY ap.id
        HAVING COUNT(pd.detail_id) = 0
    )
);

-- Selecting art enthusiasts who spend less than 20000000 and ordering them by number of auctions attedneded and secodarly by amount spent with both types of join, logical operator in where cluse, group by with having 
SELECT ae.ssn, COUNT(a.auction_number) AS num_auctions, SUM(pd.price) AS total_spending
FROM art_enthusiast ae
JOIN auction_to_art_enthusiast aae ON ae.ssn = aae.art_enthusiast_ssn
JOIN auction a ON aae.auction_number = a.auction_number
LEFT JOIN purchase p ON ae.ssn = p.art_enthusiast_ssn
LEFT JOIN purchase_detail pd ON p.purchase_number = pd.purchase_number
GROUP BY ae.ssn
HAVING SUM(pd.price) < 20000000
ORDER BY num_auctions DESC, total_spending ASC;

-- Selecting the photography from 18th or 19th or 20th centru or one where the century is not known with the highest starting price with join, logic operators in where clause, notcorrelated subquery and aggregatioe function
SELECT ap.id, ap.starting_price
FROM art_piece ap
JOIN photography ph ON ap.id = ph.art_piece_id
WHERE ap.starting_price = (
    SELECT MAX(ap1.starting_price)
    FROM art_piece ap1
    JOIN photography ph1 ON ap1.id = ph1.art_piece_id
    WHERE ap1.century IN ('18th', '19th', '20th') OR ap1.century IS NULL
) AND (ap.century IN ('18th', '19th', '20th') OR ap.century IS NULL)

--Selecting art enthusiast, their total spendings, number of auctions they attended, number of art pieces purchased ordered by total spent descending order with left join, aggregation functions and group by
SELECT ae.ssn, ae.art_enthusiast_name, COUNT(DISTINCT aae.auction_number) AS num_auctions_attended, COUNT(DISTINCT p.purchase_number) AS num_purchases, SUM(pd.price) AS total_spent
FROM art_enthusiast ae
LEFT JOIN auction_to_art_enthusiast aae ON ae.ssn = aae.art_enthusiast_ssn
LEFT JOIN purchase p ON ae.ssn = p.art_enthusiast_ssn
LEFT JOIN purchase_detail pd ON p.purchase_number = pd.purchase_number
GROUP BY ae.ssn, ae.art_enthusiast_name
ORDER BY total_spent DESC;

--Selecting art pieces that have been sold for a price higher than the average price of all pieces sold by the same artist with nested correlated subquey. Same art piece can be sold multiple times.
SELECT ap.id, ap.art_piece_name, ap.artist_id, pd.price
FROM art_piece ap
JOIN purchase_detail pd ON ap.id = pd.art_piece_id
WHERE pd.price > (
    SELECT AVG(pd1.price)
    FROM art_piece ap1
    JOIN purchase_detail pd1 ON ap1.id = pd1.art_piece_id
    WHERE ap1.artist_id = ap.artist_id
    GROUP BY ap1.artist_id
)