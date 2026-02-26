-- 1. INSERTION DES JOUEURS
INSERT INTO PLAYER (nickname, password, email, avatar_url) VALUES
('GamerPro99', 'hash123', 'gamerpro@mail.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=1'),
('LuckyLucy', 'hash456', 'lucy@mail.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=2'),
('DarkKnight', 'hash789', 'knight@mail.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=3'),
('MiniVilloise', 'hashabc', 'villoise@mail.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=4'),
('ZeldaFan', 'hashdef', 'zelda@mail.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=5'),
('PixelArt', 'hashghi', 'pixel@mail.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=6'),
('SpeedRunner', 'hashjkl', 'speed@mail.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=7'),
('NoobMaster69', 'hashmno', 'noob@mail.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=8'),
('CyberPunk', 'hashpqr', 'cyber@mail.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=9'),
('AlphaJoueur', 'hashstu', 'alpha@mail.com', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10');

-- 2. INSERTION DES STATISTIQUES (Liées aux IDs 1 à 10)
INSERT INTO STATISTICS (id_player, wins_count, games_played_count) VALUES
(1, 5, 10), (2, 8, 12), (3, 2, 15), (4, 10, 20), (5, 0, 5),
(6, 3, 8), (7, 12, 12), (8, 1, 30), (9, 4, 10), (10, 7, 14);

-- 3. INSERTION DES PARTIES (GAME)
-- id_host et id_winner font référence aux IDs de 1 à 10 créés plus haut
INSERT INTO GAME (id_host, id_winner, played_at) VALUES
(1, 2, '2026-02-01 14:00:00'),
(3, 3, '2026-02-05 10:30:00'),
(5, 1, '2026-02-10 18:45:00'),
(2, NULL, '2026-02-12 21:00:00'), -- Partie sans gagnant (égalité ou abandon)
(4, 4, '2026-02-15 15:00:00'),
(6, 7, '2026-02-18 12:00:00'),
(8, 9, '2026-02-20 19:30:00'),
(10, 10, '2026-02-22 09:00:00'),
(1, 4, '2026-02-24 23:15:00'),
(7, 7, '2026-02-25 16:40:00');

-- 4. INSERTION DES PARTICIPATIONS (PARTICIPATES)
-- On lie des joueurs à chaque partie (id_game, id_player)
INSERT INTO PARTICIPATES (id_game, id_player, final_score) VALUES
(1, 1, 45), (1, 2, 52), (1, 3, 30),
(2, 3, 60), (2, 4, 12),
(3, 5, 20), (3, 1, 85), (3, 2, 44),
(4, 2, 10), (4, 6, 10),
(5, 4, 100), (5, 8, 55),
(6, 6, 30), (6, 7, 45), (6, 9, 12),
(7, 8, 0), (7, 9, 25),
(8, 10, 77), (8, 1, 50),
(9, 1, 33), (9, 4, 89),
(10, 7, 65), (10, 2, 40);