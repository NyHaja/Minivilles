from flask import Flask, request, jsonify
import mysql.connector
from mysql.connector import Error
from datetime import datetime, timedelta

app = Flask(__name__)

# ============================================================================
# 0. CONFIGURATION ET CONNEXION À LA BASE DE DONNÉES
# ============================================================================
DB_CONFIG = {
    'host': '127.0.0.1',       # localhost car l'API tourne sur la même VM que MySQL
    'database': 'miniville_bd',  # 
    'user': 'acces_bdd',        #
    'password': 'miniville2026' # 
}



def get_db_connection():
    """Génère et retourne une connexion à la base de données MySQL."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except Error as e:
        print(f"Erreur de connexion MySQL: {e}")
        return None


# ============================================================================
# P1 & F1. GESTION DES JOUEURS INSCRITS
# ============================================================================

@app.route('/register', methods=['POST'])
def register():
    """P1. INSCRIPTION D'UN JOUEUR"""
    data = request.json
    conn = get_db_connection()
    if not conn:
        return jsonify({"status": "error", "message": "Erreur serveur (BDD)"}), 500

    cursor = conn.cursor()
    try:
        cursor.callproc('insertPlayer', (
            data.get('nickname'), 
            data.get('password'), 
            data.get('email'), 
            data.get('avatar_url')
        ))
        conn.commit()
        return jsonify({"status": "success", "message": "Joueur inscrit !"})
    except Error as e:
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 400
    finally:
        cursor.close()
        conn.close()
@app.route('/get_auth_data', methods=['POST'])
def get_auth_data():
    """RÉCUPÈRE L'ID ET LE HASH POUR VÉRIFICATION SUR LE GAME SERVER"""
    data = request.json
    email = data.get('email')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({"status": "error", "message": "Erreur serveur (BDD)"}), 500
        
    cursor = conn.cursor()
    try:
        cursor.execute(
            "SELECT id, password_hash FROM players WHERE email = %s",
            (email,)
        )
        result = cursor.fetchone()
        
        if result:
            return jsonify({
                "status": "success",
                "player_id": result[0],
                "password_hash": result[1] 
            })
        else:
            return jsonify({
                "status": "error", 
                "message": "Utilisateur non trouvé"
            }), 404
            
    except Error as e:
        return jsonify({"status": "error", "message": str(e)}), 400
    finally:
        cursor.close()
        conn.close()
# ============================================================================
# P2 & F2. GESTION DES INVITÉS
# ============================================================================

@app.route('/guest/register', methods=['POST'])
def register_guest():
    """P2. CRÉATION D'UN COMPTE INVITÉ"""
    data = request.json
    conn = get_db_connection()
    if not conn:
        return jsonify({"status": "error", "message": "Erreur serveur (BDD)"}), 500

    cursor = conn.cursor()
    try:
        expires_at = (datetime.now() + timedelta(hours=24)).strftime('%Y-%m-%d %H:%M:%S')
        created_at = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        # None permet de laisser l'AUTO_INCREMENT générer l'ID
        cursor.callproc('insertGuestPlayer', (
            None, 
            data.get('nickname'), 
            created_at, 
            expires_at
        ))
        conn.commit()
        return jsonify({"status": "success", "message": "Compte invité créé avec succès !"})
    except Error as e:
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 400
    finally:
        cursor.close()
        conn.close()

@app.route('/guest/<int:guest_id>/valid', methods=['GET'])
def check_guest_valid(guest_id):
    """F2. VÉRIFIER SI UN INVITÉ EST VALIDE (NON EXPIRÉ)"""
    conn = get_db_connection()
    if not conn: return jsonify({"status": "error", "message": "Erreur BDD"}), 500

    cursor = conn.cursor()
    try:
        cursor.execute("SELECT isGuestValid(%s)", (guest_id,))
        result = cursor.fetchone()
        is_valid = bool(result[0]) if result else False
        return jsonify({"status": "success", "is_valid": is_valid})
    finally:
        cursor.close()
        conn.close()


# ============================================================================
# HISTORIQUE (EVENT SOURCING)
# ============================================================================

@app.route('/history/insert', methods=['POST'])
def insert_history():
    """INSERT GAME_HISTORY (Enregistrement d'une action)"""
    data = request.json
    conn = get_db_connection()
    if not conn:
        return jsonify({"status": "error", "message": "Erreur serveur (BDD)"}), 500

    cursor = conn.cursor()
    try:
        cursor.callproc('insertHistory', (
            data.get('game_id'),
            data.get('player_id'),    # Ne remplir QUE player_id OU guest_id (Trigger 10)
            data.get('guest_id'),     
            data.get('card_id'),      
            data.get('monument_id'),  
            data.get('turn_number'),
            data.get('action_type'),
            data.get('dice_result'),
            data.get('amount_exchanged', 0),
            None  # execute_at est géré par MySQL
        ))
        conn.commit()
        return jsonify({"status": "success", "message": "Action enregistrée dans l'historique !"})
    except Error as e:
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 400
    finally:
        cursor.close()
        conn.close()


# ============================================================================
# P3 à P6. MODIFICATION DES PARTIES (CRÉER, REJOINDRE, QUITTER, TERMINER)
# ============================================================================

@app.route('/game/create', methods=['POST'])
def create_game():
    """P3. CRÉATION D'UNE PARTIE"""
    data = request.json
    conn = get_db_connection()
    if not conn: return jsonify({"status": "error", "message": "Erreur serveur"}), 500

    cursor = conn.cursor()
    try:
        cursor.callproc('createGame', (
            data.get('player_id'), 
            data.get('player_type')
        ))
        
        game_id = None
        for result in cursor.stored_results():
            row = result.fetchone()
            if row: game_id = row[0]

        conn.commit()
        return jsonify({"status": "success", "message": "Partie créée", "game_id": game_id})
    except Error as e:
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 400
    finally:
        cursor.close()
        conn.close()

@app.route('/game/join', methods=['POST'])
def join_game():
    """P4. REJOINDRE UNE PARTIE"""
    data = request.json
    conn = get_db_connection()
    if not conn: return jsonify({"status": "error"}), 500

    cursor = conn.cursor()
    try:
        cursor.callproc('joinGame', (
            data.get('player_id'), data.get('game_id'), data.get('player_type')
        ))
        conn.commit()
        return jsonify({"status": "success", "message": "Partie rejointe avec succès !"})
    except Error as e:
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 400
    finally:
        cursor.close()
        conn.close()

@app.route('/game/end', methods=['POST'])
def end_game():
    """P5. TERMINER UNE PARTIE"""
    data = request.json
    conn = get_db_connection()
    if not conn: return jsonify({"status": "error"}), 500

    cursor = conn.cursor()
    try:
        cursor.callproc('endGame', (
            data.get('game_id'), data.get('winner_id'), data.get('winner_type')
        ))
        conn.commit()
        return jsonify({"status": "success", "message": "Partie terminée !"})
    except Error as e:
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 400
    finally:
        cursor.close()
        conn.close()

@app.route('/game/leave', methods=['POST'])
def leave_game():
    """P6. QUITTER UNE PARTIE"""
    data = request.json
    conn = get_db_connection()
    if not conn: return jsonify({"status": "error"}), 500

    cursor = conn.cursor()
    try:
        cursor.callproc('leaveGame', (
            data.get('player_id'), data.get('game_id'), data.get('player_type')
        ))
        conn.commit()
        return jsonify({"status": "success", "message": "Joueur retiré."})
    except Error as e:
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 400
    finally:
        cursor.close()
        conn.close()


# ============================================================================
# F3 à F8. LECTURE DES DONNÉES ET STATISTIQUES
# ============================================================================

@app.route('/game/<int:game_id>/participants', methods=['GET'])
def count_participants(game_id):
    """F3. NOMBRE DE PARTICIPANTS D'UNE PARTIE"""
    conn = get_db_connection()
    if not conn: return jsonify({"status": "error"}), 500
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT countParticipants(%s)", (game_id,))
        result = cursor.fetchone()
        count = result[0] if result else 0
        return jsonify({"status": "success", "game_id": game_id, "participants": count})
    finally:
        cursor.close()
        conn.close()

@app.route('/player/winrate', methods=['GET'])
def get_winrate():
    """F4. TAUX DE VICTOIRE D'UN JOUEUR"""
    email = request.args.get('email')
    conn = get_db_connection()
    if not conn: return jsonify({"status": "error"}), 500
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT tauxVictoire(%s)", (email,))
        result = cursor.fetchone()
        winrate = int(result[0]) if result else 0
        return jsonify({"status": "success", "email": email, "winrate": winrate})
    finally:
        cursor.close()
        conn.close()

@app.route('/player/<int:player_id>/rank', methods=['GET'])
def get_player_rank(player_id):
    """F5. RANG D'UN JOUEUR DANS LE CLASSEMENT"""
    conn = get_db_connection()
    if not conn: return jsonify({"status": "error"}), 500
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT playerRank(%s)", (player_id,))
        result = cursor.fetchone()
        rank = result[0] if result else 0
        return jsonify({"status": "success", "player_id": player_id, "rank": rank})
    finally:
        cursor.close()
        conn.close()

@app.route('/game/<int:game_id>/isfull', methods=['GET'])
def check_game_full(game_id):
    """F6. LA PARTIE EST-ELLE PLEINE ?"""
    conn = get_db_connection()
    if not conn: return jsonify({"status": "error"}), 500
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT isGameFull(%s)", (game_id,))
        result = cursor.fetchone()
        is_full = bool(result[0]) if result else False
        return jsonify({"status": "success", "game_id": game_id, "is_full": is_full})
    finally:
        cursor.close()
        conn.close()

@app.route('/game/<int:game_id>/haswinner', methods=['GET'])
def check_game_winner(game_id):
    """F7. LA PARTIE A-T-ELLE UN GAGNANT ?"""
    conn = get_db_connection()
    if not conn: return jsonify({"status": "error"}), 500
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT hasWinner(%s)", (game_id,))
        result = cursor.fetchone()
        has_winner = bool(result[0]) if result else False
        return jsonify({"status": "success", "game_id": game_id, "has_winner": has_winner})
    finally:
        cursor.close()
        conn.close()

@app.route('/monument/<int:monument_id>/price', methods=['GET'])
def get_monument_price(monument_id):
    """F8. PRIX D'UN MONUMENT"""
    conn = get_db_connection()
    if not conn: return jsonify({"status": "error"}), 500
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT getMonumentPrice(%s)", (monument_id,))
        result = cursor.fetchone()
        price = result[0] if result else None
        return jsonify({"status": "success", "monument_id": monument_id, "price": price})
    finally:
        cursor.close()
        conn.close()


# ============================================================================
# LANCEMENT DE L'API REST
# ============================================================================

if __name__ == '__main__':
    # host='0.0.0.0' permet d'écouter les requêtes venant de ta VM Godot
    app.run(host='0.0.0.0', port=5000)
