# AI Legal Assistant Setup

## Architecture

Flutter -> HTTPS Cloudflare Worker -> D1 + Vectorize retrieval -> Gemini Provider -> Arabic answer + legal sources.

The local SQLite database remains the source of truth for the mobile app. D1 is a server-side retrieval copy.

## Legal corpus

Source:

yemen_laws_app/assets/db/app_database.db

Legal tables:

- laws
- abwab
- fusul
- mawad

Use yemen_laws_app/tools/export_rag_data.py to export these tables while preserving IDs and original Arabic text.

Do not replace the schema with a simplified experimental schema.

## Local-first search priority

Every assistant question now follows a strict sequential fallback:

1. Search the mobile SQLite database first using the same canonical legal corpus.
2. If one or more local legal matches are found, return those articles immediately and do not call the Backend or Gemini.
3. Only when the local search returns no matches does Flutter call POST /api/chat with fallback_from_local=true.
4. The Backend then performs its server-side lexical/semantic retrieval and may call Gemini only when it has sufficient retrieved legal evidence.

If the local database search itself fails, the app reports the local search failure instead of silently sending the question to AI.

## Search history

The mobile database table search_history keeps each assistant lookup with:

- id
- query
- response
- source: local_db or gemini_ai
- created_at

The app migrates the older search_history schema in place so existing installations are not broken. The assistant screen exposes the history from the top bar.

## Backend API

Primary endpoint:

POST /api/chat

Request:

{"message":"ما شروط بطلان العقد؟","conversation_id":"optional-id","language":"ar","history":[]}

Response:

{"answer":"...","sources":[{"article_id":123,"law_title":"...","article_number":"...","article_text":"...","reference":"..."}],"conversation_id":"..."}

Compatibility endpoint:

POST /api/legal/ask

The compatibility endpoint keeps the earlier source field names used by previous app builds.

Health:

GET /health

Expected:

{"ok":true}

## AI provider

The backend uses an abstraction:

/api/chat -> AIProvider -> GeminiProvider

Environment:

AI_PROVIDER=gemini
AI_MODEL=gemini-3.8-flash

The Gemini API key is server-side only and must be stored as a Cloudflare Worker Secret:

GEMINI_API_KEY

Never put the key in Flutter, Gradle, assets, Git, or workflow logs.

The Android app never needs to know which AI provider is used.

## RAG

Question -> lexical + semantic retrieval -> relevant legal articles -> Gemini -> answer + sources.

Legal facts must come only from retrieved legal material.

Conversation history is context only and is not treated as legal evidence.

When evidence is insufficient, the API returns:

لم أجد معلومات قانونية كافية في قاعدة موسوعة القوانين اليمنية للإجابة عن هذا السؤال.

with an empty sources array.

## Embeddings and Vectorize

Embedding model:

@cf/baai/bge-m3

Vectorize index:

yemen-laws-articles

The current Cloudflare model catalog lists bge-m3 as 1024-dimensional. Vectorize dimensions are fixed when the index is created, so do not change the embedding model/dimensions without rebuilding the index.

Workers AI remains the embedding service; Gemini is the answer-generation provider.

## D1

D1 database:

yemen_laws_db

Schema:

backend/legal-ai/schema.sql

The schema mirrors the legal hierarchy used by the app.

Do not insert invented legal material.

Import from the existing SQLite database and preserve all original IDs and Arabic text.

## Reindexing

POST /admin/reindex is protected by the Cloudflare Worker Secret:

REINDEX_TOKEN

It embeds batches of articles with bge-m3 and upserts them into Vectorize using the article ID.

## Flutter configuration

The base URL is centralized in:

yemen_laws_app/lib/core/app_config.dart

Build-time variable:

LEGAL_AI_BASE_URL

The Flutter client sends only HTTPS requests to /api/chat.

Example:

flutter build apk --release --dart-define=LEGAL_AI_BASE_URL=https://odd-mouse-c1e0.ghgfcrcgrf57566.workers.dev

## UI

The existing assistant screen remains in:

yemen_laws_app/lib/screens/legal_ai/legal_ai_screen.dart

It keeps the current theme, RTL layout, conversation UI, loading/error handling and opens returned articles using the existing ArticleDetailScreen.

No application-wide redesign is required.

## CI

.github/workflows/main.yml validates HTTPS for LEGAL_AI_BASE_URL, runs Flutter analysis/tests, runs backend TypeScript typecheck, and builds the release APK.

## Production checklist

Before the assistant can work in production:

1. D1 schema must be applied.
2. Legal corpus must be imported from app_database.db.
3. Vectorize index must exist.
4. Article embeddings must be generated.
5. GEMINI_API_KEY must be configured as a Cloudflare Worker Secret.
6. REINDEX_TOKEN must be configured.
7. Worker odd-mouse-c1e0 must be deployed with the repository code.
8. /health and /api/chat must be tested against the deployed Worker.

Repository changes alone do not deploy Cloudflare resources.

## Security

- HTTPS only.
- No Gemini key in the APK.
- Request length validation.
- Rate limiting.
- CORS.
- Safe public error messages.
- No stack traces or secrets in API responses.
- Retrieved legal text is treated as data, not instructions.
