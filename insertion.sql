-- Quelques monuments emblématiques
INSERT INTO MONUMENT (name, cost, effect) VALUES
('Train Station', 4.00, 'You may choose to roll 2 dice instead of 1.'),
('Shopping Mall', 10.00, 'Your Cup (red) and Bread (green) establishments earn +1 coin each.'),
('Amusement Park', 16.00, 'If you roll doubles with 2 dice, take an extra turn (max 1 bonus).'),
('Radio Tower', 22.00, 'Once per turn, re-roll your dice (same number, only the 2nd result counts).'),
('Harbor', 2.00, 'If the dice result is 10 or more, add +2. Also activates Small Fishing Boat and Trawler.'),
('Airport', 30.00, 'If you do not build anything this turn, receive 10 coins from the bank.');

-- Établissements Bleus (IDs 100+)
INSERT INTO CARD (card_id, name, activation_number, cost, color, icon, effect) VALUES
(100, 'Wheat Field', '1', 1, 'Blue', 'Wheat', 'Get 1 coin from the bank.'),
(101, 'Ranch', '2', 1, 'Blue', 'Cattle', 'Get 1 coin from the bank.'),
(102, 'Forest', '5', 3, 'Blue', 'Gear', 'Get 1 coin from the bank.'),
(103, 'Vineyard', '7', 3, 'Blue', 'Wheat', 'Get 3 coins from the bank.'),
(104, 'Fishing Boat', '8', 2, 'Blue', 'Boat', 'Get 3 coins (Requires Harbor).'),
(105, 'Mine', '9', 6, 'Blue', 'Gear', 'Get 5 coins from the bank.'),
(106, 'Apple Orchard', '10', 3, 'Blue', 'Wheat', 'Get 3 coins from the bank.'),
(107, 'Trawler', '12-14', 5, 'Blue', 'Boat', 'Roll 2 dice, get the sum (Requires Harbor).');


-- Établissements Verts (IDs 200+)
INSERT INTO CARD (card_id, name, activation_number, cost, color, icon, effect) VALUES
(200, 'Bakery', '2-3', 1, 'Green', 'Bread', 'Get 1 coin from the bank.'),
(201, 'General Store', '2', 0, 'Green', 'Bread', 'Get 2 coins (if < 2 monuments built).'),
(202, 'Convenience Store', '7', 2, 'Green', 'Bread', 'Get 3 coins from the bank.'),
(203, 'Cheese Factory', '7', 5, 'Green', 'Factory', 'Get 3 coins per Cattle icon owned.'),
(204, 'Furniture Factory', '8', 3, 'Green', 'Factory', 'Get 3 coins per Gear icon owned.'),
(205, 'Fruit & Veg Market', '11-12', 2, 'Green', 'Fruit', 'Get 2 coins per Wheat icon owned.');

-- Établissements Rouges (IDs 300+)
INSERT INTO CARD (card_id, name, activation_number, cost, color, icon, effect) VALUES
(300, 'Cafe', '3', 2, 'Red', 'Cup', 'The player who rolled gives you 1 coin.'),
(301, 'Pizza Joint', '7', 1, 'Red', 'Cup', 'The player who rolled gives you 1 coin.'),
(302, 'Family Restaurant', '9-10', 3, 'Red', 'Cup', 'The player who rolled gives you 2 coins.'),
(303, 'Private Club', '12-14', 4, 'Red', 'Cup', 'Active if roller has 3+ monuments. They give you all their coins.');


-- Établissements Violets - Majeurs (IDs 400+)
INSERT INTO CARD (card_id, name, activation_number, cost, color, icon, effect) VALUES
(400, 'Stadium', '6', 6, 'Purple', 'Suitcase', 'Every other player gives you 2 coins.'),
(401, 'TV Station', '6', 7, 'Purple', 'Suitcase', 'Choose a player: they give you 5 coins.'),
(402, 'Business Center', '6', 8, 'Purple', 'Suitcase', 'Trade a non-purple card with an opponent.'),
(403, 'Publisher', '7', 5, 'Purple', 'Suitcase', 'Each opponent gives 1 coin per Cup/Bread icon they own.'),
(404, 'Tax Office', '8-9', 4, 'Purple', 'Suitcase', 'Players with 10+ coins give you half (rounded down).');

-- Joueurs enregistrés (Mots de passe fictifs, à hacher en prod !)
INSERT INTO REGISTERED_PLAYER 
(nickname, password, email, avatar_url, wins_count, games_played_count, total_monuments_built) 
VALUES
('MayorMachi', '$2b$12$K9r8XJ...', 'machi_fan@example.com', 'https://robohash.org/Mayor', 15, 40, 75),
('DiceKing', '$2b$12$L8s9YK...', 'dice_master@gaming.net', 'https://robohash.org/Dice', 22, 50, 110),
('CityPlanner', '$2b$12$M7t0ZL...', 'urban@design.org', 'https://robohash.org/Urban', 5, 12, 25),
('BlueCardLover', '$2b$12$N6u1AM...', 'wheat@fields.com', 'https://robohash.org/Wheat', 8, 30, 40),
('RedBaron', '$2b$12$O5v2BN...', 'cafe_owner@food.fr', 'https://robohash.org/Red', 12, 28, 60);

-- Invités (Expirations à 24h et 48h)
INSERT INTO GUEST_PLAYER (nickname, created_at, expires_at) VALUES
('Guest_Alpha', NOW(), DATE_ADD(NOW(), INTERVAL 24 HOUR)),
('Player_Unknown', NOW(), DATE_ADD(NOW(), INTERVAL 24 HOUR)),
('MachiRookie_99', NOW(), DATE_ADD(NOW(), INTERVAL 24 HOUR)),
('QuickBuilder', NOW(), DATE_ADD(NOW(), INTERVAL 24 HOUR)),
('Visitor_404', NOW(), DATE_ADD(NOW(), INTERVAL 24 HOUR));


-- Une partie terminée et une en cours
INSERT INTO GAME (played_at, ended_at, status) VALUES
('2026-03-13 14:00:00', '2026-03-13 14:45:00', 'Finished'),
('2026-03-13 15:30:00', '2026-03-13 16:10:00', 'Finished'),
('2026-03-13 22:00:00', NULL, 'In Progress'),
('2026-03-13 23:15:00', NULL, 'In Progress'),
('2026-03-13 23:50:00', NULL, 'Waiting for Players');

-- Participation à la partie 1 (Finie)
INSERT INTO PARTICIPATES_PLAYER (player_id, game_id, final_score, is_winner, is_host) VALUES
(1, 1, 25, 0, 1), -- MayorMachi : Hôte de la partie 1, a perdu avec 25 pts
(2, 1, 32, 1, 0), -- DiceKing : Joueur dans la partie 1, a gagné avec 32 pts
(3, 2, 15, 0, 1), -- CityPlanner : Hôte de la partie 2, a perdu
(4, 3, 0, 0, 1),  -- BlueCardLover : Hôte de la partie 3 (En cours, score 0)
(5, 4, 0, 0, 1);  -- RedBaron : Hôte de la partie 4 (En cours, score 0)

-- Participation du Guest à la partie 1
INSERT INTO PARTICIPATES_GUEST (guest_id, game_id, final_score, is_winner) VALUES
(1, 1, 10, 0), -- Guest_Alpha : Troisième joueur de la partie 1
(2, 2, 30, 1), -- Player_Unknown : A gagné la partie 2 face à CityPlanner
(3, 2, 12, 0), -- MachiRookie_99 : Troisième joueur de la partie 2
(4, 4, 0, 0),  -- QuickBuilder : Joue actuellement dans la partie 4
(5, 5, 0, 0);  -- Visitor_404 : En attente dans le salon de la partie 5
