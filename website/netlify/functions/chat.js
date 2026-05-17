const SYSTEM_PROMPT = `Tu es l'assistant du jeu mobile Minivilles (adaptation de Machi Koro).
Réponds en français ou anglais selon la langue de l'utilisateur. Sois concis et amical.

RÈGLES : 2 à 4 joueurs. Champ de blé (1) + Boulangerie (2-3) + 3 pièces au départ.
Tour : 1) Lancer les dés  2) Collecter revenus  3) Acheter une carte (facultatif)
Ordre des effets : Rouge → Vert → Bleu → Violet. Victoire : 5 monuments construits.

MONUMENTS : Port (2), Gare (4), Centre Commercial (10), Parc (16), Tour Radio (22), Aéroport (30)
ÉTABLISSEMENTS : Chalutier (bleu,8), Pizzeria (rouge,7), Restaurant (rouge,9-10), Moonster Soda (rouge,7), Entreprise Travaux (vert,4-5-6)`;

exports.handler = async (event) => {
  if (event.httpMethod !== "POST") {
    return { statusCode: 405, body: "Method Not Allowed" };
  }

  const apiKey = process.env.KEY;
  if (!apiKey) {
    return { statusCode: 500, body: JSON.stringify({ error: "Clé API manquante" }) };
  }

  let messages;
  try {
    messages = JSON.parse(event.body).messages || [];
  } catch {
    return { statusCode: 400, body: JSON.stringify({ error: "JSON invalide" }) };
  }

  const response = await fetch("https://api.mistral.ai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: "mistral-small-latest",
      messages: [{ role: "system", content: SYSTEM_PROMPT }, ...messages],
      max_tokens: 300
    })
  });

  const data = await response.json();
  return {
    statusCode: response.status,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data)
  };
};
