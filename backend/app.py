from flask import Flask, request, jsonify
import jwt
import datetime
import bcrypt
import mysql.connector
from mysql.connector import Error
 
app = Flask(__name__)
app.config["SECRET_KEY"] = "cle_super_secrete_a_changer"  # À changer en production

# CONFIGURATION ET CONNEXION À LA BASE DE DONNÉES
DB_CONFIG = {
    'host':     '127.0.0.1',
    'database': 'miniville_bd',
    'user':     'acces_bdd',
    'password': 'miniville2026'
}
 
def get_db_connection():
    """Retourne une connexion à la base de données MySQL."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except Error as e:
        print(f"Erreur de connexion MySQL: {e}")
        return None




# AUTHENTIFICATION
@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
 
    if not data:
        return jsonify({"status": "error", "message": "JSON manquant."}), 400
 
    email    = data.get("email", "").strip()
    password = data.get("password", "")
 
    if not email or not password:
        return jsonify({"status": "error", "message": "Email ou mot de passe manquant."}), 400
 
    # Récupération du joueur en BDD
    conn = get_db_connection()
    if not conn:
        return jsonify({"status": "error", "message": "Erreur serveur (BDD)."}), 500
 
    cursor = conn.cursor()
    try:
        cursor.execute(
            "SELECT player_id, password FROM REGISTERED_PLAYER WHERE email = %s",
            (email,)
        )
        result = cursor.fetchone()
    except Error as e:
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()
 
    # Joueur introuvable
    if not result:
        return jsonify({"status": "error", "message": "Email ou mot de passe incorrect."}), 401
 
    player_id, password_hash = result
 
    # Vérification du mot de passe avec bcrypt
    if not bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8")):
        return jsonify({"status": "error", "message": "Email ou mot de passe incorrect."}), 401
 
    # Génération du token JWT (3h)
    access_token = jwt.encode(
        {
            "player_id": player_id,
            "email":     email,
            "exp":       datetime.datetime.utcnow() + datetime.timedelta(hours=3)
        },
        app.config["SECRET_KEY"],
        algorithm="HS256"
    )
 
    return jsonify({
        "status":       "success",
        "message":      "Connexion réussie.",
        "player_id":    player_id,
        "access_token": access_token,
        "expires_in":   10800  # 3h en secondes
    }), 200



# UTILITAIRE — VÉRIFICATION DU TOKEN
def verify_token(request):
    """
    Extrait et vérifie le JWT depuis le header Authorization.
    Retourne le payload si valide, ou None + message d'erreur.
    """
    auth_header = request.headers.get("Authorization", "")
 
    if not auth_header.startswith("Bearer "):
        return None, "Token manquant."
 
    token = auth_header.split(" ", 1)[1]
 
    try:
        payload = jwt.decode(
            token,
            app.config["SECRET_KEY"],
            algorithms=["HS256"]
        )
        return payload, None
    except jwt.ExpiredSignatureError:
        return None, "Token expiré."
    except jwt.InvalidTokenError:
        return None, "Token invalide."




# EXEMPLE DE ROUTE PROTÉGÉE — HISTORIQUE
@app.route("/history/insert", methods=["POST"])
def insert_history():
    payload, error = verify_token(request)
    if error:
        return jsonify({"status": "error", "message": error}), 401
 
    data = request.get_json()
    if not data:
        return jsonify({"status": "error", "message": "JSON manquant."}), 400
 
    # Ici brancher sur la vraie logique d'insertion (cf. apiUpdateBdd.py)
    return jsonify({
        "status":    "success",
        "message":   "Historique enregistré.",
        "player_id": payload["player_id"],
        "data":      data
    }), 200


# LANCEMENT
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)