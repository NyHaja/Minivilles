from flask import Flask, request, jsonify
import jwt
import datetime

app = Flask(__name__)
app.config["SECRET_KEY"] = "cle_super_secrete_a_changer"

# Faux utilisateurs temporaires pour test
users = {
    "ton_mail@test.com": {
        "player_id": 1,
        "password": "ton_mdp"
    }
}

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()

    if not data:
        return jsonify({
            "status": "error",
            "message": "JSON manquant."
        }), 400

    email = data.get("email")
    password = data.get("password")

    if email not in users or users[email]["password"] != password:
        return jsonify({
            "status": "error",
            "message": "Email ou mot de passe incorrect."
        }), 401

    player_id = users[email]["player_id"]

    access_token = jwt.encode(
        {
            "player_id": player_id,
            "email": email,
            "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)
        },
        app.config["SECRET_KEY"],
        algorithm="HS256"
    )

    refresh_token = jwt.encode(
        {
            "player_id": player_id,
            "type": "refresh",
            "exp": datetime.datetime.utcnow() + datetime.timedelta(days=7)
        },
        app.config["SECRET_KEY"],
        algorithm="HS256"
    )

    return jsonify({
        "status": "success",
        "message": "Connexion réussie.",
        "player_id": player_id,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "expires_in": 3600
    }), 200


@app.route("/register", methods=["POST"])
def register():
    data = request.get_json()

    if not data:
        return jsonify({
            "status": "error",
            "message": "JSON manquant."
        }), 400

    nickname = data.get("nickname")
    email = data.get("email")
    password = data.get("password")

    if not email or not password or not nickname:
        return jsonify({
            "status": "error",
            "message": "Champs manquants."
        }), 400

    if email in users:
        return jsonify({
            "status": "error",
            "message": "Utilisateur déjà existant."
        }), 409

    new_id = len(users) + 1
    users[email] = {
        "player_id": new_id,
        "password": password
    }

    return jsonify({
        "status": "success",
        "message": "Inscription réussie.",
        "player_id": new_id
    }), 201


@app.route("/history/insert", methods=["POST"])
def insert_history():
    auth_header = request.headers.get("Authorization", "")

    if not auth_header.startswith("Bearer "):
        return jsonify({
            "status": "error",
            "message": "Token manquant."
        }), 401

    token = auth_header.split(" ", 1)[1]

    try:
        payload = jwt.decode(
            token,
            app.config["SECRET_KEY"],
            algorithms=["HS256"]
        )
    except jwt.ExpiredSignatureError:
        return jsonify({
            "status": "error",
            "message": "Token expiré."
        }), 401
    except jwt.InvalidTokenError:
        return jsonify({
            "status": "error",
            "message": "Token invalide."
        }), 401

    data = request.get_json()

    return jsonify({
        "status": "success",
        "message": "Historique enregistré.",
        "player_id": payload["player_id"],
        "data": data
    }), 200


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)