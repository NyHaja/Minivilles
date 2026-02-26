CREATE TABLE PLAYER (
    player_id INT PRIMARY KEY AUTO_INCREMENT,
    nickname VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(255),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at DATETIME DEFAULT NULL,
    CONSTRAINT uc_player_nickname UNIQUE (nickname),
    CONSTRAINT uc_player_email UNIQUE (email)
);

CREATE TABLE GAME ( 
    game_id INT PRIMARY KEY AUTO_INCREMENT, 
    played_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_host INT NOT NULL,
    id_winner INT, 

    CONSTRAINT fk_game_host 
        FOREIGN KEY (id_host) REFERENCES PLAYER(player_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_game_winner 
        FOREIGN KEY (id_winner) REFERENCES PLAYER(player_id) 
        ON DELETE SET NULL
); 

CREATE TABLE PARTICIPATES (
    id_game INT NOT NULL, 
    id_player INT NOT NULL, 
    final_score INT DEFAULT 0,
    PRIMARY KEY (id_game, id_player),
    CONSTRAINT fk_parts_game 
        FOREIGN KEY (id_game) REFERENCES GAME(game_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_parts_player 
        FOREIGN KEY (id_player) REFERENCES PLAYER(player_id) 
        ON DELETE CASCADE
); 

CREATE TABLE STATISTICS (
    id_player INT PRIMARY KEY ,
    wins_count INT DEFAULT 0, 
    games_played_count INT DEFAULT 0, 
    CONSTRAINT ck_wins_positive CHECK (wins_count >= 0),
    CONSTRAINT ck_games_positive CHECK (games_played_count >= 0),
    CONSTRAINT fk_stats_player 
        FOREIGN KEY (id_player) REFERENCES PLAYER(player_id) 
        ON DELETE CASCADE
);