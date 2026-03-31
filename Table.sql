SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS PARTICIPATES_PLAYER;
DROP TABLE IF EXISTS PARTICIPATES_GUEST;
DROP TABLE IF EXISTS game_history;
DROP TABLE IF EXISTS SYSTEM_LOG;
DROP TABLE IF EXISTS REGISTERED_PLAYER;
DROP TABLE IF EXISTS GUEST_PLAYER;
DROP TABLE IF EXISTS GAME;
DROP TABLE IF EXISTS MONUMENT;
DROP TABLE IF EXISTS card;
SET FOREIGN_KEY_CHECKS = 1;

-- Table des Monuments
CREATE TABLE MONUMENT (
    monument_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    cost INT NOT NULL, -- Coût en pièces (ex: Gare = 4) 
    effect TEXT
);

-- Table des Cartes (Etablissements)
CREATE TABLE CARD (
    card_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,    
    activation_number VARCHAR(10), -- Ex: "1", "2-3", "12-14" 
    cost INT NOT NULL,
    color ENUM('Blue', 'Green', 'Red', 'Purple') NOT NULL, -- Respecte les types PDF 
    icon ENUM('Wheat', 'Cattle', 'Gear', 'Boat', 'Bread', 'Factory', 'Fruit', 'Suitcase', 'Cup') NULL,
    effect TEXT NOT NULL
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
    games_played_count INT DEFAULT 0,
    total_monuments_built INT DEFAULT 0 -- Ajout du type INT ici
);

-- Table des Invités
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
    status VARCHAR(255) -- Correction minuscule pour consistance
);

-- Historique des actions (Event Sourcing)
CREATE TABLE GAME_HISTORY (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    game_id INT NOT NULL,
    player_id INT,
    guest_id INT,
    card_id INT,
    monument_id INT,
    turn_number INT NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    dice_result INT,
    amount_exchanged INT DEFAULT 0,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_history_game FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE,
    CONSTRAINT fk_history_player FOREIGN KEY (player_id) REFERENCES REGISTERED_PLAYER(player_id) ON DELETE SET NULL,
    CONSTRAINT fk_history_guest FOREIGN KEY (guest_id) REFERENCES GUEST_PLAYER(guest_id) ON DELETE SET NULL,
    CONSTRAINT fk_history_card FOREIGN KEY (card_id) REFERENCES card(card_id) ON DELETE SET NULL,
    CONSTRAINT fk_history_monument FOREIGN KEY (monument_id) REFERENCES MONUMENT(monument_id) ON DELETE SET NULL
);

-- Participations
CREATE TABLE PARTICIPATES_PLAYER (
    player_id INT,
    game_id INT,
    final_score INT DEFAULT 0,
    is_winner TINYINT(1) DEFAULT 0, -- Utilisation de BOOLEAN standard
    is_host TINYINT(1) DEFAULT 0,
    PRIMARY KEY (player_id, game_id),
    FOREIGN KEY (player_id) REFERENCES REGISTERED_PLAYER(player_id) ON DELETE CASCADE,
    FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
);

CREATE TABLE PARTICIPATES_GUEST (
    guest_id INT,
    game_id INT,
    final_score INT DEFAULT 0,
    is_winner TINYINT(1) DEFAULT 0,
    PRIMARY KEY (guest_id, game_id),
    FOREIGN KEY (guest_id) REFERENCES GUEST_PLAYER(guest_id) ON DELETE CASCADE,
    FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
);

-- Logs Système
CREATE TABLE SYSTEM_LOG (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    action_type VARCHAR(50), 
    target_id INT,           
    details TEXT,
    executed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
