-- ============================================================================
-- TRIGGERS — Base de données Minivilles Deluxe
-- ============================================================================
-- SGBD : MySQL
-- Tables concernées : 	REGISTERED_PLAYER, GUEST_PLAYER, GAME, PARTICIPATES_PLAYER,
--          			PARTICIPATES_GUEST, MONUMENT, GAME_HISTORY, CARD
--                      SYSTEM_LOG
-- ============================================================================

-- ############################################################################
--  1. 	MISE À JOUR DE last_login_at QUAND UNE PARTICIPATION EST AJOUTÉE
-- 		INCRÉMENTATION DE games_played_count QUAND UN JOUEUR REJOINT UNE PARTIE
-- ############################################################################


DELIMITER //

CREATE TRIGGER trg_participates_player_after_insert
    AFTER INSERT ON PARTICIPATES_PLAYER
    FOR EACH ROW
BEGIN
	-- [Trigger 1] last_login_at + [Trigger 2] games_played_count
    UPDATE REGISTERED_PLAYER
    SET last_login_at = NOW(),
        games_played_count = games_played_count + 1
    WHERE player_id = NEW.player_id;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER trg_participates_player_update_winner
    AFTER UPDATE ON PARTICIPATES_PLAYER
    FOR EACH ROW
BEGIN
    -- is_winner passe de 0 (ou NULL) à 1
    IF (OLD.is_winner IS NULL OR OLD.is_winner = 0) AND NEW.is_winner = 1 THEN
        UPDATE REGISTERED_PLAYER
        SET wins_count = wins_count + 1
        WHERE player_id = NEW.player_id;
    END IF;

    -- is_winner passe de 1 à 0 (annulation) → décrémenter
    IF OLD.is_winner = 1 AND (NEW.is_winner = 0 OR NEW.is_winner IS NULL) THEN
        UPDATE REGISTERED_PLAYER
        SET wins_count = GREATEST(wins_count - 1, 0)
        WHERE player_id = NEW.player_id;
    END IF;
END //

DELIMITER ;

-- ############################################################################
--  2. LOG AUTOMATIQUE — INSCRIPTION D'UN JOUEUR
-- ############################################################################
DELIMITER //

DROP TRIGGER IF EXISTS trg_registered_player_log_insert //

CREATE TRIGGER trg_registered_player_log_insert
    AFTER INSERT ON REGISTERED_PLAYER
    FOR EACH ROW
BEGIN
    INSERT INTO SYSTEM_LOG (action_type, target_id, details, executed_at)
    VALUES (
        'PLAYER_REGISTERED',
        NEW.player_id,
        CONCAT('Inscription du joueur "', NEW.nickname, '" (email: ', NEW.email, ')'),
        NOW()
    );
END //

DELIMITER ;


-- ############################################################################
--  4. UN SEUL GAGNANT PAR PARTIE — PARTICIPATES_PLAYER (UPDATE)
-- ############################################################################

DELIMITER //

CREATE TRIGGER trg_participates_player_one_winner_update
    BEFORE UPDATE ON PARTICIPATES_PLAYER
    FOR EACH ROW
BEGIN
    DECLARE total_winners INT;

    IF NEW.is_winner = 1 AND (OLD.is_winner IS NULL OR OLD.is_winner = 0) THEN
        SELECT (
            (SELECT COUNT(*) FROM PARTICIPATES_PLAYER
             WHERE game_id = NEW.game_id AND is_winner = 1
             AND player_id != NEW.player_id)
            +
            (SELECT COUNT(*) FROM PARTICIPATES_GUEST
             WHERE game_id = NEW.game_id AND is_winner = 1)
        ) INTO total_winners;

        IF total_winners > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Cette partie a déjà un gagnant. Un seul gagnant autorisé par partie.';
        END IF;
    END IF;
END //

DELIMITER ;

-- ############################################################################
--  5. UN SEUL GAGNANT PAR PARTIE — PARTICIPATES_GUEST (INSERT)
-- ############################################################################


DELIMITER //

CREATE TRIGGER trg_participates_guest_before_insert
    BEFORE INSERT ON PARTICIPATES_GUEST
    FOR EACH ROW
BEGIN
    DECLARE total_participants INT;
    DECLARE total_winners INT;
    DECLARE guest_expiry DATETIME;

    -- Score >= 0
    IF NEW.final_score IS NOT NULL AND NEW.final_score < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le score final ne peut pas être négatif.';
    END IF;

    -- Guest non expiré
    SELECT expires_at INTO guest_expiry
    FROM GUEST_PLAYER
    WHERE guest_id = NEW.guest_id;

    IF guest_expiry IS NOT NULL AND guest_expiry < NOW() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ce joueur invité a expiré et ne peut plus rejoindre de partie.';
    END IF;

    -- Maximum 5 joueurs par partie
    SELECT (
        (SELECT COUNT(*) FROM PARTICIPATES_PLAYER WHERE game_id = NEW.game_id)
        +
        (SELECT COUNT(*) FROM PARTICIPATES_GUEST WHERE game_id = NEW.game_id)
    ) INTO total_participants;

    IF total_participants >= 5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La partie est pleine (maximum 5 joueurs).';
    END IF;

    -- Un seul gagnant par partie
    IF NEW.is_winner = 1 THEN
        SELECT (
            (SELECT COUNT(*) FROM PARTICIPATES_PLAYER
             WHERE game_id = NEW.game_id AND is_winner = 1)
            +
            (SELECT COUNT(*) FROM PARTICIPATES_GUEST
             WHERE game_id = NEW.game_id AND is_winner = 1)
        ) INTO total_winners;

        IF total_winners > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Cette partie a déjà un gagnant.';
        END IF;
    END IF;
END //

DELIMITER ;

-- ############################################################################
-- 6. UN SEUL GAGNANT PAR PARTIE — PARTICIPATES_GUEST (UPDATE)
-- ############################################################################

DELIMITER //

CREATE TRIGGER trg_participates_guest_one_winner_update
    BEFORE UPDATE ON PARTICIPATES_GUEST
    FOR EACH ROW
BEGIN
    DECLARE total_winners INT;

    IF NEW.is_winner = 1 AND (OLD.is_winner IS NULL OR OLD.is_winner = 0) THEN
        SELECT (
            (SELECT COUNT(*) FROM PARTICIPATES_PLAYER
             WHERE game_id = NEW.game_id AND is_winner = 1)
            +
            (SELECT COUNT(*) FROM PARTICIPATES_GUEST
             WHERE game_id = NEW.game_id AND is_winner = 1
             AND guest_id != NEW.guest_id)
        ) INTO total_winners;

        IF total_winners > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Cette partie a déjà un gagnant. Un seul gagnant autorisé par partie.';
        END IF;
    END IF;
END //

DELIMITER ;

-- ############################################################################
-- 7. COHÉRENCE wins_count <= games_played_count
-- ############################################################################

DELIMITER //

CREATE TRIGGER trg_registered_player_check_stats_update
    BEFORE UPDATE ON REGISTERED_PLAYER
    FOR EACH ROW
BEGIN
    IF NEW.wins_count < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre de victoires ne peut pas être négatif.';
    END IF;

    IF NEW.games_played_count < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre de parties jouées ne peut pas être négatif.';
    END IF;

    IF NEW.wins_count > NEW.games_played_count THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre de victoires ne peut pas dépasser le nombre de parties jouées.';
    END IF;
END //

DELIMITER ;

-- ############################################################################
-- 9. base_price > 0 SUR MONUMENT
-- ############################################################################

DELIMITER //

CREATE TRIGGER trg_monument_check_price_insert
    BEFORE INSERT ON MONUMENT
    FOR EACH ROW
BEGIN
    IF NEW.base_price IS NULL OR NEW.base_price <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le prix de base d''un monument doit être strictement supérieur à 0.';
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER trg_monument_check_price_update
    BEFORE UPDATE ON MONUMENT
    FOR EACH ROW
BEGIN
    IF NEW.cost IS NULL OR NEW.cost <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le prix de base d''un monument doit être strictement supérieur à 0.';
    END IF;
END //

DELIMITER ;

-- ############################################################################
-- 10. Trigger sur GUEST_ID ET PLAYER_ID 
-- ############################################################################
-- le triggers permet d'éviter le fais d'avoir le guest_id et player_id rempli sur la même donnée


DELIMITER //

CREATE TRIGGER tg_check_player_guest_before_insert
BEFORE INSERT ON GAME_HISTORY
FOR EACH ROW
BEGIN
    -- Cas 1 : Les deux sont remplis (Interdit)
    IF (NEW.player_id IS NOT NULL AND NEW.guest_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Impossible d''avoir player_id ET guest_id. Choisissez-en un seul.';
    END IF;

    -- Cas 2 : Aucun n'est rempli (Interdit)
    IF (NEW.player_id IS NULL AND NEW.guest_id IS NULL) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Vous devez spécifier soit un player_id, soit un guest_id.';
    END IF;
END //

DELIMITER ;


-- ############################################################################
-- 11. Trigger update Monument_built 
-- ############################################################################
-- ici on doit avoir un trigger qui augmente le nombre de monument construis à partir de l'historique 
DELIMITER //

DELIMITER //

DROP TRIGGER IF EXISTS update_monument_built //

CREATE TRIGGER update_monument_built 
AFTER INSERT ON GAME_HISTORY
FOR EACH ROW
BEGIN
    -- On vérifie que c'est un joueur enregistré ET qu'un monument est impliqué
    IF (NEW.player_id IS NOT NULL 
        AND NEW.monument_id IS NOT NULL) THEN 
        
        UPDATE REGISTERED_PLAYER
        SET total_monuments_built = total_monuments_built + 1
        WHERE player_id = NEW.player_id; 

        -- AJOUT DU POINT-VIRGULE À LA FIN DE CETTE LIGNE :
        INSERT INTO SYSTEM_LOG (action_type, target_id, details, executed_at)
        VALUES ('BUILT MONUMENT', NEW.player_id, 'Incrémentation du nombre de monuments construits', NOW());
        
    END IF; 
END //

DELIMITER ;

-- ############################################################################
-- 12. Décrémenter les stats si on quitte la partie 
-- ############################################################################


DELIMITER //
DROP TRIGGER IF EXISTS trg_participates_player_after_delete //
CREATE TRIGGER trg_participates_player_after_delete
    AFTER DELETE ON PARTICIPATES_PLAYER
    FOR EACH ROW
BEGIN
    -- On décrémente le nombre de parties jouées (sans descendre sous 0)
    UPDATE REGISTERED_PLAYER
    SET games_played_count = GREATEST(games_played_count - 1, 0)
    WHERE player_id = OLD.player_id;

    -- S'il était marqué comme gagnant (peu probable s'il quitte, mais par sécurité), on annule la victoire
    IF OLD.is_winner = 1 THEN
        UPDATE REGISTERED_PLAYER
        SET wins_count = GREATEST(wins_count - 1, 0)
        WHERE player_id = OLD.player_id;
    END IF;
END //
DELIMITER ;



