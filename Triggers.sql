-- ============================================================================
-- TRIGGERS — Base de données Minivilles Deluxe
-- ============================================================================
-- SGBD : MySQL
-- Tables concernées : 	REGISTERED_PLAYER, GUEST_PLAYER, GAME, PARTICIPATES_PLAYER,
--          			PARTICIPATES_GUEST, PURCHASE_HISTORY, MONUMENT,
--         				ARCHIVED_PLAYER, SYSTEM_LOG
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

create trigger trg_registered_player_log_insert
	after insert on registered_player
	for each row
begin
	insert into system_log (action_type, target_id, details, executed_at)
	values (
		'PLAYER_REGISTERED',
		new.player_id,
		concat('Inscription du joueur "', new.nickname, '"(email: ', new.email, ')'),
		now()
	);
end //

DELIMITER ;

-- ############################################################################
--  3. LOG AUTOMATIQUE — ARCHIVAGE D'UN JOUEUR
-- ############################################################################

DELIMITER //

CREATE TRIGGER trg_archived_player_log_insert
    AFTER INSERT ON ARCHIVED_PLAYER
    FOR EACH ROW
BEGIN
    INSERT INTO SYSTEM_LOG (action_type, target_id, details, executed_at)
    VALUES (
        'PLAYER_ARCHIVED',
        NEW.player_id,
        CONCAT('Archivage du joueur "', NEW.nickname, '" — Raison : ',
               IFNULL(NEW.archive_reason, 'Non spécifiée')),
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
-- 8. L'ACHETEUR DOIT PARTICIPER À LA PARTIE — PURCHASE_HISTORY
-- ############################################################################

DELIMITER //

CREATE TRIGGER trg_purchase_history_check_participant
    BEFORE INSERT ON PURCHASE_HISTORY
    FOR EACH ROW
BEGIN
    DECLARE is_participant INT DEFAULT 0;

    -- Vérifier qu'exactement un des deux (player_id ou guest_id) est renseigné
    IF (NEW.player_id IS NULL AND NEW.guest_id IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un achat doit être lié à un joueur inscrit OU un invité.';
    END IF;

    IF (NEW.player_id IS NOT NULL AND NEW.guest_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un achat ne peut pas être lié à un joueur inscrit ET un invité en même temps.';
    END IF;

    -- Vérifier la participation
    IF NEW.player_id IS NOT NULL THEN
        SELECT COUNT(*) INTO is_participant
        FROM PARTICIPATES_PLAYER
        WHERE player_id = NEW.player_id AND game_id = NEW.game_id;
    ELSE
        SELECT COUNT(*) INTO is_participant
        FROM PARTICIPATES_GUEST
        WHERE guest_id = NEW.guest_id AND game_id = NEW.game_id;
    END IF;

    IF is_participant = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'L''acheteur ne participe pas à cette partie. Achat refusé.';
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
    IF NEW.base_price IS NULL OR NEW.base_price <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le prix de base d''un monument doit être strictement supérieur à 0.';
    END IF;
END //

DELIMITER ;

-- ############################################################################
-- 10. ARCHIVAGE AUTOMATIQUE — COPIE AVANT SUPPRESSION
-- ############################################################################
-- Quand un joueur inscrit est supprimé, ses données sont automatiquement
-- sauvegardées dans ARCHIVED_PLAYER.

DELIMITER //

CREATE TRIGGER trg_registered_player_archive_on_delete
    BEFORE DELETE ON REGISTERED_PLAYER
    FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ARCHIVED_PLAYER WHERE player_id = OLD.player_id) THEN
        INSERT INTO ARCHIVED_PLAYER (
            player_id, nickname, email, created_at, last_login_at,
            archived_at, archive_reason
        ) VALUES (
            OLD.player_id, OLD.nickname, OLD.email, OLD.created_at,
            OLD.last_login_at, NOW(), 'Suppression automatique du compte'
        );
    END IF;
END //

DELIMITER ;