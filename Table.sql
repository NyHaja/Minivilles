-- Désactive temporairement les contraintes de clés étrangères (sécurité pour MySQL)
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS PURCHASE_HISTORY;
DROP TABLE IF EXISTS PARTICIPATES_PLAYER;
DROP TABLE IF EXISTS PARTICIPATES_GUEST;

DROP TABLE IF EXISTS SYSTEM_LOG;
DROP TABLE IF EXISTS ARCHIVED_PLAYER;

DROP TABLE IF EXISTS REGISTERED_PLAYER;
DROP TABLE IF EXISTS GUEST_PLAYER;
DROP TABLE IF EXISTS GAME;
DROP TABLE IF EXISTS MONUMENT;

-- Réactive les contraintes de clés étrangères
SET FOREIGN_KEY_CHECKS = 1;

-- Table des Monuments
CREATE TABLE MONUMENT (
    monument_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    base_price DECIMAL(10, 2),
    description TEXT
);

-- Table des Joueurs Enregistrés
CREATE TABLE REGISTERED_PLAYER (
    player_id INT PRIMARY KEY AUTO_INCREMENT,
    nickname VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    avatar_url VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login_at DATETIME,
    wins_count INT DEFAULT 0,
    games_played_count INT DEFAULT 0
);

-- Table des Invités (Guest)
CREATE TABLE GUEST_PLAYER (
    guest_id INT PRIMARY KEY AUTO_INCREMENT,
    nickname VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME
);

-- Table des Parties
CREATE TABLE GAME (
    game_id INT PRIMARY KEY AUTO_INCREMENT,
    played_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    ended_at DATETIME, 
    Status VARCHAR(255) 
);

-- Participation des joueurs enregistrés
CREATE TABLE PARTICIPATES_PLAYER (
    player_id INT,
    game_id INT,
    final_score INT,
    is_winner  INT CHECK (is_winner IN (0, 1)) ,
    is_host  INT CHECK (is_host IN (0, 1)) ,
    PRIMARY KEY (player_id, game_id),
    FOREIGN KEY (player_id) REFERENCES REGISTERED_PLAYER(player_id) ON DELETE CASCADE,
    FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
);

-- Participation des invités (Guest)
CREATE TABLE PARTICIPATES_GUEST (
    guest_id INT,
    game_id INT,
    final_score INT DEFAULT 0,
    is_winner BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (guest_id, game_id),
    FOREIGN KEY (guest_id) REFERENCES GUEST_PLAYER(guest_id) ON DELETE CASCADE,
    FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
);

-- Historique des achats (Lien complexe entre Joueur/Guest, Game et Monument)
CREATE TABLE PURCHASE_HISTORY (
    purchase_id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NULL,
    guest_id INT NULL,
    game_id INT NOT NULL,
    monument_id INT NOT NULL,
    purchase_price DECIMAL(10, 2),
    purchased_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES REGISTERED_PLAYER(player_id) ON DELETE CASCADE,
    FOREIGN KEY (guest_id) REFERENCES GUEST_PLAYER(guest_id) ON DELETE CASCADE,
    FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE ,
    FOREIGN KEY (monument_id) REFERENCES MONUMENT(monument_id) ON DELETE CASCADE
);


-- Table d'Archive
CREATE TABLE ARCHIVED_PLAYER (
    player_id INT PRIMARY KEY,
    nickname VARCHAR(50),
    email VARCHAR(100),
    created_at DATETIME,
    last_login_at DATETIME,
    archived_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    archive_reason VARCHAR(255)
);

-- Table de Logs Système
CREATE TABLE SYSTEM_LOG (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    action_type VARCHAR(50), 
    target_id INT,           
    details TEXT,
    executed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);