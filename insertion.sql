-- Quelques monuments emblématiques
INSERT INTO MONUMENT (name, base_price, description) VALUES
('Gare', 4.00, 'Vous pouvez choisir de lancer 2 dés au lieu d''un.'),
('Centre commercial', 10.00, 'Vos établissements Tasse (rouge) et Pain (vert) rapportent +1 pièce chacun.'),
('Parc d''attractions', 16.00, 'Si vous obtenez un double avec 2 dés, rejouez un tour supplémentaire (max 1 bonus).'),
('Tour radio', 22.00, 'Une fois par tour, relancez vos dés (même nombre, seul le 2e résultat compte).'),
('Port', 2.00, 'Si résultat dés >= 10, ajoutez +2. Active aussi Petit bateau et Chalutier.'),
('Aéroport', 30.00, 'Si vous ne construisez rien ce tour, recevez 10 pièces de la banque.');

-- Joueurs enregistrés (Mots de passe fictifs, à hacher en prod !)
INSERT INTO REGISTERED_PLAYER (nickname, password, email, avatar_url) VALUES
('Alex_Pro', 'hash_alex123', 'alex@example.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Alex'),
('Elena_Strategy', 'hash_elena456', 'elena@example.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Elena'),
('Dark_Knight', 'hash_dk789', 'dk@example.com', NULL);

-- Invités (Expirations à 24h et 48h)
INSERT INTO GUEST_PLAYER (nickname, expires_at) VALUES
('Guest_42', DATE_ADD(NOW(), INTERVAL 1 DAY)),
('Guest_99', DATE_ADD(NOW(), INTERVAL 2 DAY));


-- Une partie terminée et une en cours
INSERT INTO GAME (played_at, ended_at, Status) VALUES
('2024-05-20 14:00:00', '2024-05-20 15:30:00', 'Finished'),
(NOW(), NULL, 'In_Progress');

-- Participation à la partie 1 (Finie)
-- Alex était l'hôte et a gagné
INSERT INTO PARTICIPATES_PLAYER (player_id, game_id, final_score, is_winner, is_host) VALUES
(1, 1, 2500, 1, 1), 
(2, 1, 1800, 0, 0);

-- Participation du Guest à la partie 1
INSERT INTO PARTICIPATES_GUEST (guest_id, game_id, final_score, is_winner) VALUES
(1, 1, 1200, 0);

-- Participation à la partie 2 (En cours)
INSERT INTO PARTICIPATES_PLAYER (player_id, game_id, final_score, is_winner, is_host) VALUES
(3, 2, 450, 0, 1);

-- Historique des achats durant la partie 1
INSERT INTO PURCHASE_HISTORY (player_id, guest_id, game_id, monument_id, purchase_price) VALUES
(1, NULL, 1, 1, 4.00), 
(NULL, 1, 1, 3, 16.00);

-- Un joueur archivé (Ancien compte supprimé)
INSERT INTO ARCHIVED_PLAYER (player_id, nickname, email, created_at, archive_reason) VALUES
(99, 'Old_User', 'old@mail.com', '2023-01-01 10:00:00', 'Demande de suppression de compte');

-- Logs système pour tracer l'activité
INSERT INTO SYSTEM_LOG (action_type, target_id, details) VALUES
('USER_REGISTER', 1, 'Nouvel utilisateur enregistré : Alex_Pro'),
('GAME_START', 2, 'Partie lancée par Dark_Knight'),
('PURCHASE', 1, 'Monument 1 acheté par joueur 1 pour 1500.00');