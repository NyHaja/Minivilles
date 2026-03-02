-- ============================================================================
-- TRIGGERS — Base de données Minivilles Deluxe
-- ============================================================================
-- SGBD : MySQL
-- Tables concernées : PLAYER, STATISTICS, GAME, PARTICIPATES
-- ============================================================================


-- ############################################################################
-- TABLE PLAYER
-- ############################################################################

-- --------------------------------------------------------------------------
-- 1. Mise à jour automatique de last_login_at à chaque connexion
-- --------------------------------------------------------------------------
-- Le serveur applicatif fait un UPDATE sur PLAYER lors de l'authentification.
-- Ce trigger garantit que last_login_at est toujours mis à jour,
-- même si le serveur oublie de le faire explicitement.

DELIMITER //

CREATE TRIGGER trg_player_update_last_login
    BEFORE UPDATE ON PLAYER
    FOR EACH ROW
BEGIN
    -- Si last_login_at n'a pas été modifié dans la requête,
    -- on le met à jour automatiquement
    IF NEW.last_login_at <=> OLD.last_login_at THEN
        SET NEW.last_login_at = NOW();
    END IF;
END //

DELIMITER ;


-- --------------------------------------------------------------------------
-- 2. Vérification du format du mot de passe (INSERT)
-- --------------------------------------------------------------------------
-- NOTE IMPORTANTE :
-- En production, la validation de la complexité du mot de passe
-- (longueur, majuscules, chiffres, caractères spéciaux) est normalement
-- gérée côté serveur applicatif AVANT le hashage.
--
-- Le trigger côté BDD sert de FILET DE SÉCURITÉ pour :
--   - Empêcher le stockage d'un mot de passe trop court (non hashé)
--   - Vérifier le format bcrypt si vous utilisez le hashage applicatif
--
-- Deux versions sont proposées ci-dessous : choisissez selon votre archi.
-- --------------------------------------------------------------------------

-- ==============================
-- VERSION A : Mot de passe stocké EN CLAIR (phase prototype)
-- ==============================
-- Utiliser cette version si le hashage n'est pas encore implémenté.
-- Vérifie la complexité du mot de passe directement.

DELIMITER //

CREATE TRIGGER trg_player_check_password_insert
    BEFORE INSERT ON PLAYER
    FOR EACH ROW
BEGIN
    -- Minimum 8 caractères
    IF CHAR_LENGTH(NEW.password) < 8 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins 8 caractères.';
    END IF;

    -- Au moins une lettre majuscule
    IF NEW.password NOT REGEXP '[A-Z]' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins une lettre majuscule.';
    END IF;

    -- Au moins une lettre minuscule
    IF NEW.password NOT REGEXP '[a-z]' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins une lettre minuscule.';
    END IF;

    -- Au moins un chiffre
    IF NEW.password NOT REGEXP '[0-9]' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins un chiffre.';
    END IF;

    -- Au moins un caractère spécial
    IF NEW.password NOT REGEXP '[^a-zA-Z0-9]' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins un caractère spécial (!@#$%...).';
    END IF;
END //

DELIMITER ;


-- --------------------------------------------------------------------------
-- 3. Même vérification sur UPDATE du mot de passe
-- --------------------------------------------------------------------------

DELIMITER //

CREATE TRIGGER trg_player_check_password_update
    BEFORE UPDATE ON PLAYER
    FOR EACH ROW
BEGIN
    -- On ne vérifie que si le mot de passe a changé
    IF NOT (NEW.password <=> OLD.password) THEN

        IF CHAR_LENGTH(NEW.password) < 8 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins 8 caractères.';
        END IF;

        IF NEW.password NOT REGEXP '[A-Z]' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins une lettre majuscule.';
        END IF;

        IF NEW.password NOT REGEXP '[a-z]' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins une lettre minuscule.';
        END IF;

        IF NEW.password NOT REGEXP '[0-9]' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins un chiffre.';
        END IF;

        IF NEW.password NOT REGEXP '[^a-zA-Z0-9]' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins un caractère spécial (!@#$%...).';
        END IF;
    END IF;
END //

DELIMITER ;


-- ==============================
-- VERSION B : Mot de passe stocké HASHÉ (production avec bcrypt)
-- ==============================
-- À utiliser quand le serveur applicatif hash le mot de passe avant
-- l'envoi en BDD. Le trigger vérifie seulement que c'est bien un hash.
-- → Décommentez cette version et commentez la Version A si vous passez
--   au hashage côté serveur.

/*
DELIMITER //

CREATE TRIGGER trg_player_check_hash_insert
    BEFORE INSERT ON PLAYER
    FOR EACH ROW
BEGIN
    -- Un hash bcrypt fait toujours 60 caractères et commence par $2
    IF CHAR_LENGTH(NEW.password) < 60 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le mot de passe ne semble pas hashé (longueur < 60). Hashez-le côté serveur.';
    END IF;

    IF NEW.password NOT REGEXP '^\\$2[aby]\\$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le hash ne respecte pas le format bcrypt ($2a$/$2b$/$2y$).';
    END IF;
END //

CREATE TRIGGER trg_player_check_hash_update
    BEFORE UPDATE ON PLAYER
    FOR EACH ROW
BEGIN
    IF NOT (NEW.password <=> OLD.password) THEN
        IF CHAR_LENGTH(NEW.password) < 60 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Le mot de passe ne semble pas hashé (longueur < 60). Hashez-le côté serveur.';
        END IF;

        IF NEW.password NOT REGEXP '^\\$2[aby]\\$' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Le hash ne respecte pas le format bcrypt ($2a$/$2b$/$2y$).';
        END IF;
    END IF;
END //

DELIMITER ;
*/


-- ############################################################################
-- TABLE STATISTICS — Création automatique à l'inscription d'un joueur
-- ############################################################################

-- --------------------------------------------------------------------------
-- 4. Créer une ligne STATISTICS quand un nouveau PLAYER est inséré
-- --------------------------------------------------------------------------

DELIMITER //

CREATE TRIGGER trg_player_create_statistics
    AFTER INSERT ON PLAYER
    FOR EACH ROW
BEGIN
    INSERT INTO STATISTICS (id_player, wins_count, games_played_count)
    VALUES (NEW.player_id, 0, 0);
END //

DELIMITER ;


-- ############################################################################
-- TABLE PARTICIPATES — Mise à jour automatique des statistiques
-- ############################################################################

-- --------------------------------------------------------------------------
-- 5. Incrémenter games_played_count quand un joueur rejoint une partie
-- --------------------------------------------------------------------------

DELIMITER //

CREATE TRIGGER trg_participates_increment_games
    AFTER INSERT ON PARTICIPATES
    FOR EACH ROW
BEGIN
    UPDATE STATISTICS
    SET games_played_count = games_played_count + 1
    WHERE id_player = NEW.id_player;
END //

DELIMITER ;


-- ############################################################################
-- TABLE GAME — Mise à jour du compteur de victoires
-- ############################################################################

-- --------------------------------------------------------------------------
-- 6. Incrémenter wins_count quand un gagnant est déclaré
-- --------------------------------------------------------------------------

DELIMITER //

CREATE TRIGGER trg_game_update_winner_stats
    AFTER UPDATE ON GAME
    FOR EACH ROW
BEGIN
    -- Seulement si id_winner passe de NULL à une valeur (fin de partie)
    IF OLD.id_winner IS NULL AND NEW.id_winner IS NOT NULL THEN
        UPDATE STATISTICS
        SET wins_count = wins_count + 1
        WHERE id_player = NEW.id_winner;
    END IF;
END //

DELIMITER ;


-- ############################################################################
-- TABLE PLAYER — Vérification du format email (bonus)
-- ############################################################################

-- --------------------------------------------------------------------------
-- 7. Vérifier le format email à l'insertion
-- --------------------------------------------------------------------------

DELIMITER //

CREATE TRIGGER trg_player_check_email_insert
    BEFORE INSERT ON PLAYER
    FOR EACH ROW
BEGIN
    IF NEW.email NOT REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le format de l\'adresse email est invalide.';
    END IF;
END //

DELIMITER ;

-- --------------------------------------------------------------------------
-- 8. Vérifier le format email à la mise à jour
-- --------------------------------------------------------------------------

DELIMITER //

CREATE TRIGGER trg_player_check_email_update
    BEFORE UPDATE ON PLAYER
    FOR EACH ROW
BEGIN
    IF NOT (NEW.email <=> OLD.email) THEN
        IF NEW.email NOT REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Le format de l\'adresse email est invalide.';
        END IF;
    END IF;
END //

DELIMITER ;

-- ############################################################################
-- TABLE STATISTICS — Contrôle de cohérence des données
-- ############################################################################

-- --------------------------------------------------------------------------
-- 9. Vérification de cohérence à l'INSERT sur STATISTICS
-- --------------------------------------------------------------------------
-- Règles :
--   • wins_count >= 0                    (déjà couvert par CHECK, double sécurité)
--   • games_played_count >= 0            (idem)
--   • wins_count <= games_played_count   (on ne peut pas gagner plus qu'on a joué)

DELIMITER //

CREATE TRIGGER trg_statistics_check_coherence_insert
    BEFORE INSERT ON STATISTICS
    FOR EACH ROW
BEGIN
    -- Nombre de victoires ne peut pas être négatif
    IF NEW.wins_count < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre de victoires ne peut pas être négatif.';
    END IF;

    -- Nombre de parties jouées ne peut pas être négatif
    IF NEW.games_played_count < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre de parties jouées ne peut pas être négatif.';
    END IF;

    -- Cohérence croisée : on ne peut pas avoir plus de victoires que de parties
    IF NEW.wins_count > NEW.games_played_count THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre de victoires ne peut pas dépasser le nombre de parties jouées.';
    END IF;
END //

DELIMITER ;


-- --------------------------------------------------------------------------
-- 10. Vérification de cohérence à l'UPDATE sur STATISTICS
-- --------------------------------------------------------------------------

DELIMITER //

CREATE TRIGGER trg_statistics_check_coherence_update
    BEFORE UPDATE ON STATISTICS
    FOR EACH ROW
BEGIN
    -- Nombre de victoires ne peut pas être négatif
    IF NEW.wins_count < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre de victoires ne peut pas être négatif.';
    END IF;

    -- Nombre de parties jouées ne peut pas être négatif
    IF NEW.games_played_count < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre de parties jouées ne peut pas être négatif.';
    END IF;

    -- Cohérence croisée : victoires <= parties jouées
    IF NEW.wins_count > NEW.games_played_count THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre de victoires ne peut pas dépasser le nombre de parties jouées.';
    END IF;

    -- Cohérence avec la table PARTICIPATES :
    -- games_played_count ne peut pas être inférieur au nombre réel de participations
    -- (empêche une modification manuelle incohérente)
    IF NEW.games_played_count < (
        SELECT COUNT(*) FROM PARTICIPATES WHERE id_player = NEW.id_player
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre de parties ne peut pas être inférieur au nombre réel de participations enregistrées.';
    END IF;

    -- Cohérence avec la table GAME :
    -- wins_count ne peut pas être inférieur au nombre réel de victoires
    IF NEW.wins_count < (
        SELECT COUNT(*) FROM GAME WHERE id_winner = NEW.id_player
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre de victoires ne peut pas être inférieur au nombre réel de victoires enregistrées.';
    END IF;
END //

DELIMITER ;


-- ############################################################################
-- TABLE PARTICIPATES — Contrôle du score final
-- ############################################################################

-- --------------------------------------------------------------------------
-- 11. Le score final ne peut pas être négatif (INSERT)
-- --------------------------------------------------------------------------

DELIMITER //

CREATE TRIGGER trg_participates_check_score_insert
    BEFORE INSERT ON PARTICIPATES
    FOR EACH ROW
BEGIN
    IF NEW.final_score < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le score final ne peut pas être négatif.';
    END IF;
END //

DELIMITER ;

-- --------------------------------------------------------------------------
-- 12. Le score final ne peut pas être négatif (UPDATE)
-- --------------------------------------------------------------------------

DELIMITER //

CREATE TRIGGER trg_participates_check_score_update
    BEFORE UPDATE ON PARTICIPATES
    FOR EACH ROW
BEGIN
    IF NEW.final_score < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le score final ne peut pas être négatif.';
    END IF;
END //

DELIMITER ;