/**
 * Callable: openrouterChat
 * Секрет OPENROUTER_API_KEY задаётся в Firebase (не в репозитории):
 *   firebase functions:secrets:set OPENROUTER_API_KEY
 */
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");

const openrouterKey = defineSecret("OPENROUTER_API_KEY");

const DEFAULT_MODEL = "google/gemma-3n-e4b-it:free";
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";

exports.openrouterChat = onCall(
  {
    secrets: [openrouterKey],
    region: "europe-west1",
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Нужна сессия Firebase (войди по почте в приложении).",
      );
    }

    const {messages, model} = request.data || {};
    if (!Array.isArray(messages) || messages.length === 0) {
      throw new HttpsError("invalid-argument", "Передай messages[]");
    }

    const modelId =
      typeof model === "string" && model.trim().length > 0
        ? model.trim()
        : DEFAULT_MODEL;

    const key = openrouterKey.value();
    if (!key || !key.trim()) {
      console.error("OPENROUTER_API_KEY пуст");
      throw new HttpsError("failed-precondition", "Сервер ИИ не настроен");
    }

    let res;
    try {
      res = await fetch(OPENROUTER_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${key.trim()}`,
          "X-OpenRouter-Title": "FitMonster",
        },
        body: JSON.stringify({
          model: modelId,
          messages,
          temperature: 0.7,
          max_tokens: 1800,
        }),
      });
    } catch (e) {
      console.error("OpenRouter fetch error", e);
      throw new HttpsError("unavailable", "Сеть до OpenRouter недоступна");
    }

    const text = await res.text();
    let data;
    try {
      data = JSON.parse(text);
    } catch {
      console.error("OpenRouter non-JSON", res.status, text.slice(0, 500));
      throw new HttpsError("internal", "Некорректный ответ OpenRouter");
    }

    if (!res.ok) {
      const msg =
        data && data.error && data.error.message
          ? String(data.error.message)
          : `HTTP ${res.status}`;
      console.error("OpenRouter error", res.status, msg);
      throw new HttpsError("internal", msg);
    }

    const content = data.choices?.[0]?.message?.content;
    if (typeof content !== "string" || !content.trim()) {
      throw new HttpsError("internal", "Пустой ответ модели");
    }

    return {content: content.trim()};
  },
);
