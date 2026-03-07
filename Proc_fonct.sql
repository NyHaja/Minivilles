-- ############################################################################
-- INSERTION D'UN NOUVEAU PLAYER OU GUEST 
-- ############################################################################

DELIMITER //

DROP PROCEDURE IF EXISTS insertPlayer //

CREATE PROCEDURE insertPlayer(
    IN p_nickname   VARCHAR(50),
    IN p_password   VARCHAR(255),
    IN p_mail       VARCHAR(100), 
    IN p_url        VARCHAR(255), 
    IN p_created    DATETIME, 
    IN p_last_login DATETIME, 
    IN p_wins       INT, 
    IN p_games      INT
)
BEGIN 
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        RESIGNAL; 
    END;

    START TRANSACTION;

    INSERT INTO REGISTERED_PLAYER (
        nickname, 
        password, 
        email, 
        avatar_url, 
        created_at, 
        last_login_at, 
        wins_count, 
        games_played_count
    ) VALUES (
        p_nickname, 
        p_password, 
        p_mail, 
        p_url, 
        p_created, 
        p_last_login, 
        p_wins, 
        p_games
    );
    COMMIT;
END //

DELIMITER ;

--- INSERT GUEST_PLAYER 
DELIMITER //

DROP PROCEDURE IF EXISTS insertGuestPlayer //

CREATE PROCEDURE insertGuestPlayer(
    IN p_id         INT,              
    IN p_nickname   VARCHAR(50),      
    IN p_created_at DATETIME,          
    IN p_expires_at DATETIME           
)
BEGIN 
    -- 1. Gestionnaire pour l'ID en double (Erreur 1062 = Duplicate Entry)
    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        ROLLBACK;
        SELECT CONCAT('Erreur : L''ID invité ', p_id, ' existe déjà.') AS ErrorMessage;
    END;

    -- 2. Gestionnaire pour toutes les autres erreurs SQL
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        RESIGNAL; -- Renvoie l'erreur d'origine
    END;

    -- Début de la transaction
    START TRANSACTION;

    INSERT INTO GUEST_PLAYER (
        guest_id, 
        nickname, 
        created_at, 
        expires_at
    ) VALUES (
        p_id, 
        p_nickname, 
        p_created_at, 
        p_expires_at
    );

    COMMIT;
END //

DELIMITER ;
 
--- supprimer le guest des que ca date expires 

SET GLOBAL event_scheduler = ON; -- activer le event_scheduler 
CREATE EVENT purge_expired_guests
ON SCHEDULE EVERY 100 MINUTE
DO
  DELETE FROM GUEST_PLAYER WHERE expires_at <= NOW();



-- ############################################################################
-- FONCTION  
-- ############################################################################

-- Authentification d'un joueur 

DELIMITER //

DROP FUNCTION IF EXISTS authenPlayer //

CREATE FUNCTION authenPlayer(
    p_email    VARCHAR(100), 
    p_password VARCHAR(100)
) 
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_nb INT DEFAULT 0;  

    SELECT COUNT(*) INTO v_nb 
    FROM REGISTERED_PLAYER 
    WHERE email = p_email AND password = p_password; 

    IF v_nb > 0 THEN 
        RETURN TRUE;
    ELSE
        RETURN FALSE; 
    END IF; 
END //

DELIMITER ;


DELIMITER //
CREATE OR REPLACE FUNCTION tauxVictoire(email_in IN VARCHAR(100)) 
RETURN INT 
DETERMINISTIC 
READS SQL DATA
BEGIN 
    DECLARE nb_win INT;
    DECLARE nb_games INT;

    SELECT
    wins_count into nb_win,
    games_played_count into nb_games 
    FROM REGISTERED_PLAYER 
    WHERE email = email_in ;

    RETURN nb_win / nb_games * 100 
END // 
DELIMITER ;


    



    