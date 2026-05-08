-- P1. INSCRIPTION D'UN JOUEUR
-- ############################################################################
-- Crée un joueur avec wins_count et games_played_count à 0.
-- Les stats ne sont pas en paramètre : un nouveau joueur commence toujours
-- à zéro, c'est les triggers qui les incrémentent.

DELIMITER //

DROP PROCEDURE IF EXISTS insertPlayer //

CREATE PROCEDURE insertPlayer(
    IN p_nickname   VARCHAR(50),
    IN p_password   VARCHAR(255),
    IN p_mail       VARCHAR(100), 
    IN p_avatar        VARCHAR(255)
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
        games_played_count, 
        total_monuments_built
    ) VALUES (
        p_nickname, 
        p_password, 
        p_mail, 
        p_avatar, 
        NOW(),
        NOW(),
        0,
        0,
        0
    );
    COMMIT;
END //

DELIMITER ;


-- ############################################################################
-- . INSERT GAME_HISTORY
-- ############################################################################

DELIMITER //

DROP PROCEDURE IF EXISTS insertHistory //

DELIMITER //

CREATE PROCEDURE insertHistory(
    IN p_game_id INT,
    IN p_player_id INT,
    IN p_guest_id INT,
    IN p_card_id INT,
    IN p_monument_id INT,
    IN p_turn_number INT,
    IN p_action_type VARCHAR(50),
    IN p_dice_result INT,
    IN p_amount_exchanged INT,
    IN p_execute_at DATETIME
)
BEGIN
    INSERT INTO GAME_HISTORY (
        game_id, 
        player_id, 
        guest_id, 
        card_id, 
        monument_id, 
        turn_number, 
        action_type, 
        dice_result, 
        amount_exchanged, 
        executed_at
    ) 
    VALUES (
        p_game_id, 
        p_player_id, 
        p_guest_id, 
        p_card_id, 
        p_monument_id, 
        p_turn_number, 
        p_action_type, 
        p_dice_result, 
        p_amount_exchanged, 
        COALESCE(p_execute_at, NOW()) -- Si p_execute_at est NULL
    );
END //

DELIMITER ;




-- ############################################################################
-- P2. CRÉATION D'UN COMPTE INVITÉ
-- ############################################################################
-- Génère un nickname automatique si NULL, calcule expires_at à +24h.
-- Pas besoin de passer l'ID : AUTO_INCREMENT s'en charge.

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
        NOW(), 
        p_expires_at
    );

    COMMIT;
END //

DELIMITER ;
 
DELIMITER //
-- L'activation du scheduler peut se faire hors delimiter
SET GLOBAL event_scheduler = ON; //

DROP EVENT IF EXISTS purge_expired_guests //
CREATE EVENT purge_expired_guests
ON SCHEDULE EVERY 100 MINUTE
DO
BEGIN
  DELETE FROM GUEST_PLAYER WHERE expires_at <= NOW();
END //

DELIMITER ;

-- ############################################################################
-- P3. CRÉATION D'UNE PARTIE
-- ############################################################################
-- Crée une GAME et ajoute automatiquement le créateur comme premier
-- participant. Le créateur peut être un joueur inscrit OU un invité.

DELIMITER //

DROP PROCEDURE IF EXISTS createGame //

CREATE PROCEDURE createGame(
    IN p_player_id   INT,
    IN p_player_type VARCHAR(10)    -- 'registered' ou 'guest'
)
BEGIN
    DECLARE v_game_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Vérifier le type de joueur
    IF p_player_type NOT IN ('registered', 'guest') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Type de joueur invalide. Utilisez "registered" ou "guest".';
    END IF;

    -- Vérifier que le joueur existe
    IF p_player_type = 'registered' THEN
        IF NOT EXISTS (SELECT 1 FROM REGISTERED_PLAYER WHERE player_id = p_player_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Joueur inscrit introuvable.';
        END IF;
    ELSE
        IF NOT EXISTS (SELECT 1 FROM GUEST_PLAYER WHERE guest_id = p_player_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Joueur invité introuvable.';
        END IF;
        -- Vérifier que l'invité n'a pas expiré
        IF EXISTS (SELECT 1 FROM GUEST_PLAYER
                   WHERE guest_id = p_player_id AND expires_at < NOW()) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Ce joueur invité a expiré.';
        END IF;
    END IF;

    START TRANSACTION;

    -- Créer la partie
    INSERT INTO GAME (played_at,status) VALUES (NOW(),"in progress");
    SET v_game_id = LAST_INSERT_ID();

    -- Ajouter le créateur comme premier participant
    IF p_player_type = 'registered' THEN
        INSERT INTO PARTICIPATES_PLAYER (player_id, game_id, final_score, is_winner)
        VALUES (p_player_id, v_game_id, 0, 0);
    ELSE
        INSERT INTO PARTICIPATES_GUEST (guest_id, game_id, final_score, is_winner)
        VALUES (p_player_id, v_game_id, 0, 0);
    END IF;

    COMMIT;

    -- Retourner l'ID de la partie créée
    SELECT v_game_id AS game_id;
END //

DELIMITER ;

-- ############################################################################
-- P4. REJOINDRE UNE PARTIE
-- ############################################################################
-- Vérifie : partie pas pleine, joueur pas déjà dedans, invité pas expiré.
-- Les triggers existants (max 5, guest expiré) servent de filet de sécurité,
-- mais la procédure donne des messages d'erreur plus clairs.

DELIMITER //

DROP PROCEDURE IF EXISTS joinGame //

CREATE PROCEDURE joinGame(
    IN p_player_id   INT,
    IN p_game_id     INT,
    IN p_player_type VARCHAR(10)    -- 'registered' ou 'guest'
)
BEGIN
    DECLARE v_total INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Vérifier que la partie existe
    IF NOT EXISTS (SELECT 1 FROM GAME WHERE game_id = p_game_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Partie introuvable.';
    END IF;

    -- Vérifier le nombre de participants
    SELECT (
        (SELECT COUNT(*) FROM PARTICIPATES_PLAYER WHERE game_id = p_game_id)
        +
        (SELECT COUNT(*) FROM PARTICIPATES_GUEST WHERE game_id = p_game_id)
    ) INTO v_total;

    IF v_total >= 5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La partie est pleine (maximum 5 joueurs).';
    END IF;

    IF p_player_type = 'registered' THEN
        -- Vérifier que le joueur n'est pas déjà dans la partie
        IF EXISTS (SELECT 1 FROM PARTICIPATES_PLAYER
                   WHERE player_id = p_player_id AND game_id = p_game_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Ce joueur participe déjà à cette partie.';
        END IF;

        START TRANSACTION;
        INSERT INTO PARTICIPATES_PLAYER (player_id, game_id, final_score, is_winner)
        VALUES (p_player_id, p_game_id, 0, 0);
        COMMIT;

    ELSEIF p_player_type = 'guest' THEN
        -- Vérifier que l'invité n'a pas expiré
        IF EXISTS (SELECT 1 FROM GUEST_PLAYER
                   WHERE guest_id = p_player_id AND expires_at < NOW()) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Ce joueur invité a expiré.';
        END IF;

        -- Vérifier qu'il n'est pas déjà dans la partie
        IF EXISTS (SELECT 1 FROM PARTICIPATES_GUEST
                   WHERE guest_id = p_player_id AND game_id = p_game_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Cet invité participe déjà à cette partie.';
        END IF;

        START TRANSACTION;
        INSERT INTO PARTICIPATES_GUEST (guest_id, game_id, final_score, is_winner)
        VALUES (p_player_id, p_game_id, 0, 0);
        COMMIT;

    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Type de joueur invalide. Utilisez "registered" ou "guest".';
    END IF;
END //

DELIMITER ;


-- ############################################################################
-- P5. TERMINER UNE PARTIE
-- ############################################################################
-- Déclare le gagnant et met à jour les scores finaux.
-- Le gagnant doit être un participant de cette partie.
-- Les triggers gèrent l'incrémentation de wins_count automatiquement.

DELIMITER //

DROP PROCEDURE IF EXISTS endGame //

CREATE PROCEDURE endGame(
    IN p_game_id      INT,
    IN p_winner_id    INT,
    IN p_winner_type  VARCHAR(10)   -- 'registered' ou 'guest'
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Vérifier que la partie existe
    IF NOT EXISTS (SELECT 1 FROM GAME WHERE game_id = p_game_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Partie introuvable.';
    END IF;

    -- Vérifier qu'il n'y a pas déjà un gagnant
    IF EXISTS (
        SELECT 1 FROM PARTICIPATES_PLAYER
        WHERE game_id = p_game_id AND is_winner = 1
        UNION ALL
        SELECT 1 FROM PARTICIPATES_GUEST
        WHERE game_id = p_game_id AND is_winner = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cette partie a déjà un gagnant.';
    END IF;

    START TRANSACTION;

    IF p_winner_type = 'registered' THEN
        -- Vérifier que le gagnant participe
        IF NOT EXISTS (SELECT 1 FROM PARTICIPATES_PLAYER
                       WHERE player_id = p_winner_id AND game_id = p_game_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Le gagnant déclaré ne participe pas à cette partie.';
        END IF;

        -- Marquer le gagnant (le trigger 3 incrémente wins_count)
        UPDATE PARTICIPATES_PLAYER
        SET is_winner = 1
        WHERE player_id = p_winner_id AND game_id = p_game_id;

    ELSEIF p_winner_type = 'guest' THEN
        IF NOT EXISTS (SELECT 1 FROM PARTICIPATES_GUEST
                       WHERE guest_id = p_winner_id AND game_id = p_game_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Le gagnant déclaré ne participe pas à cette partie.';
        END IF;

        UPDATE PARTICIPATES_GUEST
        SET is_winner = 1
        WHERE guest_id = p_winner_id AND game_id = p_game_id;

    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Type de joueur invalide.';
    END IF;

    COMMIT;
END //

DELIMITER ;


-- ############################################################################
-- P6. QUITTER UNE PARTIE
-- ############################################################################
-- Retire un joueur d'une partie.
-- Le trigger 17 décrémente automatiquement games_played_count et wins_count.

DELIMITER //

DROP PROCEDURE IF EXISTS leaveGame //

CREATE PROCEDURE leaveGame(
    IN p_player_id   INT,
    IN p_game_id     INT,
    IN p_player_type VARCHAR(10)
)
BEGIN
    DECLARE v_min_players INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Compter combien de joueurs restent après le départ
    SELECT (
        (SELECT COUNT(*) FROM PARTICIPATES_PLAYER WHERE game_id = p_game_id)
        +
        (SELECT COUNT(*) FROM PARTICIPATES_GUEST WHERE game_id = p_game_id)
    ) INTO v_min_players;

    -- Empêcher de vider complètement une partie
    IF v_min_players <= 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Impossible de quitter : il doit rester au moins 1 joueur. Supprimez la partie à la place.';
    END IF;

    START TRANSACTION;

    IF p_player_type = 'registered' THEN
        IF NOT EXISTS (SELECT 1 FROM PARTICIPATES_PLAYER
                       WHERE player_id = p_player_id AND game_id = p_game_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Ce joueur ne participe pas à cette partie.';
        END IF;

        DELETE FROM PARTICIPATES_PLAYER
        WHERE player_id = p_player_id AND game_id = p_game_id;

    ELSEIF p_player_type = 'guest' THEN
        IF NOT EXISTS (SELECT 1 FROM PARTICIPATES_GUEST
                       WHERE guest_id = p_player_id AND game_id = p_game_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Cet invité ne participe pas à cette partie.';
        END IF;

        DELETE FROM PARTICIPATES_GUEST
        WHERE guest_id = p_player_id AND game_id = p_game_id;

    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Type de joueur invalide.';
    END IF;

    COMMIT;
END //

DELIMITER ;

-- ############################################################################
-- P7. Mise à jour des statistics du joueur 
-- ############################################################################
DELIMITER //

DROP PROCEDURE IF EXISTS updateStatPlayer //

CREATE PROCEDURE updateStatPlayer(
    IN p_new_


-- ############################################################################
--                           FONCTIONS
-- ############################################################################


-- ############################################################################
-- F1. AUTHENTIFICATION D'UN JOUEUR
-- ############################################################################
-- Retourne le player_id si les identifiants correspondent, NULL sinon.
-- Retourner l'ID est plus utile qu'un booléen : le serveur en a besoin
-- pour la session.
-- NOT DETERMINISTIC car le résultat change si les données changent.
DELIMITER //

DROP FUNCTION IF EXISTS authenPlayer //

CREATE FUNCTION authenPlayer(
    p_email    VARCHAR(100), 
    p_password VARCHAR(100)
) 
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_id INT DEFAULT -1;  

    SELECT player_id INTO v_id
    FROM REGISTERED_PLAYER 
    WHERE email = p_email 
      AND password = p_password
    LIMIT 1;

    IF v_id IS NULL THEN
        RETURN -1;
    ELSE
        RETURN v_id;
    END IF; 
END //

DELIMITER ;


-- ############################################################################
-- F2. VÉRIFIER SI UN INVITÉ EST VALIDE (NON EXPIRÉ)
-- ############################################################################
-- Retourne TRUE si l'invité existe ET n'a pas expiré, FALSE sinon.

DELIMITER //

DROP FUNCTION IF EXISTS isGuestValid //

CREATE FUNCTION isGuestValid(
    p_guest_id INT
)
RETURNS BOOLEAN
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_expires DATETIME;

    SELECT expires_at INTO v_expires
    FROM GUEST_PLAYER
    WHERE guest_id = p_guest_id;

    -- Guest introuvable
    IF v_expires IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Guest expiré
    IF v_expires < NOW() THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END //

DELIMITER ;

-- ############################################################################
-- F3. NOMBRE DE PARTICIPANTS D'UNE PARTIE
-- ############################################################################
-- Compte dans les DEUX tables (inscrits + invités).

DELIMITER //

DROP FUNCTION IF EXISTS countParticipants //

CREATE FUNCTION countParticipants(
    p_game_id INT
)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT;

    SELECT (
        (SELECT COUNT(*) FROM PARTICIPATES_PLAYER WHERE game_id = p_game_id)
        +
        (SELECT COUNT(*) FROM PARTICIPATES_GUEST WHERE game_id = p_game_id)
    ) INTO v_total;

    RETURN IFNULL(v_total, 0);
END //

DELIMITER ;

-- ############################################################################
-- F4. TAUX DE VICTOIRE D'UN JOUEUR
-- ############################################################################
-- Retourne le pourcentage de victoires (0-100).
-- Gère la division par zéro si le joueur n'a aucune partie.
DELIMITER //

DROP FUNCTION IF EXISTS tauxVictoire //

CREATE FUNCTION tauxVictoire(p_email VARCHAR(100)) 
RETURNS INT -- <-- RETURNS avec un S
DETERMINISTIC 
READS SQL DATA
BEGIN 
    DECLARE nb_win INT DEFAULT 0;
    DECLARE nb_games INT DEFAULT 0;

    SELECT wins_count, games_played_count 
    INTO nb_win, nb_games 
    FROM REGISTERED_PLAYER 
    WHERE email = p_email;

    -- <-- Protection contre la division par zéro
    IF nb_games IS NULL OR nb_games = 0 THEN
        RETURN 0;
    ELSE
        RETURN (nb_win / nb_games) * 100; -- <-- Point-virgule ajouté
    END IF;
END // 

DELIMITER ;

-- ############################################################################
-- F5. RANG D'UN JOUEUR DANS LE CLASSEMENT
-- ############################################################################
-- Classé par nombre de victoires, puis par taux de victoire en cas d'égalité.
-- Retourne la position (1 = meilleur joueur).

DELIMITER //

DROP FUNCTION IF EXISTS playerRank //

CREATE FUNCTION playerRank(
    p_player_id INT
)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_rank INT;

    SELECT ranking INTO v_rank
    FROM (
        SELECT
            player_id,
            ROW_NUMBER() OVER (
                ORDER BY wins_count DESC,
                         CASE WHEN games_played_count > 0
                              THEN wins_count / games_played_count
                              ELSE 0
                         END DESC
            ) AS ranking
        FROM REGISTERED_PLAYER
    ) AS classement
    WHERE player_id = p_player_id;

    RETURN IFNULL(v_rank, 0);
END //

DELIMITER ;


-- ############################################################################
-- F6. LA PARTIE EST-ELLE PLEINE ?
-- ############################################################################
-- Retourne TRUE si la partie a déjà 5 participants.

DELIMITER //

DROP FUNCTION IF EXISTS isGameFull //

CREATE FUNCTION isGameFull(
    p_game_id INT
)
RETURNS BOOLEAN
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    RETURN countParticipants(p_game_id) >= 5;
END //

DELIMITER ;


-- ############################################################################
-- F7. LA PARTIE A-T-ELLE UN GAGNANT ?
-- ############################################################################
-- Retourne TRUE si un is_winner = 1 existe dans l'une des deux tables.

DELIMITER //

DROP FUNCTION IF EXISTS hasWinner //

CREATE FUNCTION hasWinner(
    p_game_id INT
)
RETURNS BOOLEAN
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_winners INT;

    SELECT (
        (SELECT COUNT(*) FROM PARTICIPATES_PLAYER
         WHERE game_id = p_game_id AND is_winner = 1)
        +
        (SELECT COUNT(*) FROM PARTICIPATES_GUEST
         WHERE game_id = p_game_id AND is_winner = 1)
    ) INTO v_winners;

    RETURN v_winners > 0;
END //

DELIMITER ;


-- ############################################################################
-- F8. PRIX D'UN MONUMENT
-- ############################################################################
-- Retourne le base_price d'un monument, NULL si introuvable.

DELIMITER //

DROP FUNCTION IF EXISTS getMonumentPrice //

CREATE FUNCTION getMonumentPrice(
    p_monument_id INT
)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_price INT;

    SELECT cost INTO v_price
    FROM MONUMENT
    WHERE monument_id = p_monument_id;

    RETURN v_price;
END //

DELIMITER ;




    
