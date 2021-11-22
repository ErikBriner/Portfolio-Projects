#Selecting database
USE albums;

#Checking for null values in the albums table

SELECT 
    *
FROM
    albums
WHERE
    album_name IS NULL;
    
---------------------

SELECT 
    SUM(CASE
        WHEN album_name IS NULL THEN 1
        ELSE 0
    END) AS count_nulls
FROM
    albums;
    
#Verifying if the release date from the albums table belong to the corresponding artist duration contract 

SELECT 
    art.*,
    CASE
        WHEN alb.release_date BETWEEN art.record_label_contract_start_date AND art.record_label_contract_end_date THEN 'Valid'
        ELSE 'Invalid'
    END AS validity
FROM
    artists art
        JOIN
    albums alb ON art.artist_id = alb.artist_id
WHERE
    art.record_label_contract_start_date IS NOT NULL
        AND art.record_label_contract_end_date IS NOT NULL;
        
#Counting the number of mismatches

SELECT 
    SUM(CASE
        WHEN alb.release_date BETWEEN art.record_label_contract_start_date AND art.record_label_contract_end_date THEN 0
        ELSE 1
    END) AS validity
FROM
    artists art
        JOIN
    albums alb ON art.artist_id = alb.artist_id
WHERE
    art.record_label_contract_start_date IS NOT NULL
        AND art.record_label_contract_end_date IS NOT NULL;
        
#Number of albums recorded in each record label

SELECT 
    record_label_id, COUNT(*) AS albums_recorded
FROM
    albums
WHERE
    record_label_id IS NOT NULL
GROUP BY record_label_id
ORDER BY record_label_id;

#Unique artists performing in any of the genre types g02, g06, g12 and whose albums release dates bewtween the 1st of january 1997 and 31st of december 2004

SELECT DISTINCT
    (artist_id)
FROM
    albums
WHERE
    genre_id IN ('g02' , 'g06', 'g12')
        AND release_date BETWEEN '1997/1/1' AND '2004/12/31'
ORDER BY artist_id;

#List of all artists with over 10 years of professional experience who have been in the top 100 for aminimum of 15 weeks

SELECT 
    *
FROM
    artists
WHERE
    no_weeks_top_100 > 15
        AND TIMESTAMPDIFF(YEAR,
        record_label_contract_start_date,
        record_label_contract_end_date) > 10;
        
#Artists that have released albums in different genres

SELECT 
    a.artist_id, a.artist_first_name, a.artist_last_name
FROM
    artists a
        JOIN
    albums al ON a.artist_id = al.artist_id
GROUP BY artist_id
HAVING COUNT(DISTINCT (al.genre_id)) > 1;

#Checking Cho Momir genres in which he has released albums

SELECT 
    art.artist_id,
    art.artist_first_name,
    art.artist_last_name,
    g.genre_id,
    g.genre_name
FROM
    artists art
        JOIN
    albums alb ON art.artist_id = alb.artist_id
        JOIN
    genre g ON alb.genre_id = g.genre_id
WHERE
    art.artist_id = 1094
GROUP BY g.genre_id
ORDER BY g.genre_id;

#Last artist to start their career as an independent artist

SELECT 
    a.artist_id,
    a.artist_first_name,
    a.artist_last_name,
    a.start_date_ind_artist
FROM
    (SELECT 
        MAX(start_date_ind_artist) AS start_date_ind_artist
    FROM
        artists) aa
        JOIN
    artists a ON a.start_date_ind_artist = aa.start_date_ind_artist
WHERE
    dependency = 'independent artist';
    
#Creaing a trigger to prompt the user when a newly inserted record contains information about an artist below age 18 and information about the number of weeks the artist has spend in the top 100.

DROP TRIGGER IF EXISTS trig_artist;
DELIMITER $$
CREATE TRIGGER trig_artist
BEFORE INSERT ON artists
FOR EACH ROW
BEGIN
		IF (YEAR(DATE(SYSDATE())) - YEAR((NEW.birth_date))) < 18 THEN 
        SET NEW.dependency = 'Not Professional Yet',
        NEW.no_weeks_top_100 = 0;
		END IF;
END $$

DELIMITER ;

INSERT INTO artists
VALUES (1345, 'Tom', 'Donovan', '2009-01-18', 4, 10, 'signed to a record label', '2014-2-2', '2018-5-14', NULL);

SELECT 
    *
FROM
    artists
WHERE
    artist_id = 1345;
    
#A list with all possible record labels the first 15 artists can be assigned to.

SELECT 
    a.artist_first_name,
    a.artist_last_name,
    rl.record_label_name
FROM
    artists a
        CROSS JOIN
    record_labels rl
WHERE
    a.artist_id < 1016;
    
#Creating a function that takes a time frame specified by start and end date, and finds the average number of weeks the artist born within that time frame has spent in top 100

DROP FUNCTION IF EXISTS f_avg_no_weeks_100;

DELIMITER $$
CREATE FUNCTION f_avg_no_weeks_100(p_start_year INTEGER, p_end_year INTEGER) RETURNS DECIMAL(10,4)
DETERMINISTIC
BEGIN
		DECLARE v_avg_no_weeks_100 DECIMAL(10,4);
        
SELECT 
    AVG(no_weeks_top_100)
INTO v_avg_no_weeks_100 FROM
    artists
WHERE
    YEAR(birth_date) BETWEEN p_start_year AND p_end_year;
        
        RETURN v_avg_no_weeks_100;
END $$

DELIMITER ;
    
SELECT albums.f_avg_no_weeks_100(1988, 2002);

#Creating a view that provides a list with the ID numbers of all artists that have released albums in different genres

CREATE OR REPLACE VIEW albums_multiple_genres AS
    SELECT 
        art.artist_id, COUNT(DISTINCT (genre_id)) AS no_of_genres
    FROM
        albums alb
            JOIN
        artists art ON alb.artist_id = art.artist_id
    GROUP BY artist_id
    HAVING no_of_genres > 1;
    
SELECT * FROM albums.albums_multiple_genres;

#Creating an index to accelerate the data retrieval process

CREATE INDEX i_composite ON artists(record_label_contract_start_date, record_label_contract_end_date, start_date_ind_artist);

