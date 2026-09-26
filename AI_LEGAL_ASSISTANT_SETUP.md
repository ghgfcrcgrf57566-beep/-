# AI Legal Assistant Setup

## Architecture

Flutter -> HTTPS Cloudflare Worker -> D1 lexical retrieval + Vectorize semantic retrieval -> Workers AI -> Arabic answer + cited legal sources.

The original SQLite database remains unchanged. The mobile app continues to use it for offline browsing and source opening.

## Existing legal database

The app is Flutter. The legal corpus is the existing SQLite asset:

yemen_laws_app/assets/db/app_database.db

The schema contains laws, abwab, fusul and mawad. Each article is represented by law_id, number and body, with hierarchy references.

The local repository already provides FTS5 search through LawsRepository. The AI backend adds a separate retrieval layer rather than changing the source database.

## Backend

Location: backend/legal-ai

Cloudflare services:
- Workers: HTTPS API
- D1: server-side copy of the legal corpus for retrieval
- Vectorize: semantic article embeddings
- Workers AI: multilingual embeddings and answer generation

Cloudflare documents Vectorize + Workers AI as a supported RAG architecture. The bge-m3 model is multilingual and is used here for Arabic semantic retrieval. Verify the model vector dimension in the Cloudflare catalog before creating the index because Vectorize dimensions are fixed.

## Initial setup

The production Worker name is `odd-mouse-c1e0`. The D1 binding is `yemen_laws_db` and the Vectorize index is `yemen-laws-articles`. The repository configuration points to the D1 database ID supplied for this deployment; Cloudflare must still confirm that the ID exists in the target account.

1. Install Node.js 18+ and Wrangler.
2. cd backend/legal-ai
3. npm install
4. Create D1: npx wrangler d1 create yemen_laws_db
5. Put the returned database_id into wrangler.toml.
6. Create Vectorize. For bge-m3, use the dimension reported by the current Cloudflare model catalog: npx wrangler vectorize create yemen-laws-articles --dimensions=1024 --metric=cosine
7. Apply schema: npx wrangler d1 execute yemen_laws_db --remote --file=schema.sql
8. Export the unchanged mobile database: python3 ../../yemen_laws_app/tools/export_rag_data.py --db ../../yemen_laws_app/assets/db/app_database.db --out data

The exported JSON files are gitignored because they duplicate the legal corpus.

## Importing the corpus

Import laws, abwab, fusul and mawad into D1 while preserving IDs and original text exactly.

Generate one embedding for each article using @cf/baai/bge-m3 and upsert each vector into Vectorize using the article ID as the vector ID. The Worker maps vector matches back to D1 records.

## Semantic index initialization

The protected POST /admin/reindex endpoint embeds batches of existing articles and upserts them into Vectorize. It accepts after and limit query parameters and returns next_after. Keep the reindex token only in deployment secrets. Do not put it in Flutter or Git.

## API

POST /api/legal/ask

Request: {"question":"ما هي شروط الطلاق؟","conversation_id":"optional","history":[]}

Response: {"answer":"...","sources":[{"article_id":123,"law_name":"...","article_number":"...","article_text":"..."}]}

Errors include empty/oversized questions, unsupported app versions, rate limits and server errors.

## Security

- HTTPS is provided by Cloudflare.
- No AI provider API key is placed in Flutter.
- The Worker validates app version and question size.
- Requests are rate limited to 20 per minute per hashed client IP bucket.
- The raw client IP is not stored; the Worker stores a SHA-256 hash only.
- Add Cloudflare WAF/rate-limiting rules before public launch.
- Never put Cloudflare account tokens or deployment secrets in Git.

## Flutter configuration

The app reads the Worker URL at build time:

flutter build apk --release --dart-define=LEGAL_AI_BASE_URL=https://odd-mouse-c1e0.ghgfcrcgrf57566.workers.dev

The value is intentionally not hard-coded because the actual deployed Worker URL belongs to the deployment account and must be supplied during deployment.

## Theme and navigation

The new AI screen uses the existing theme extensions and is reachable from RootShell as a full-width card. It follows light, dark and automatic theme changes without replacing the existing navigation or splash screen.

Each returned source opens the existing ArticleDetailScreen using the original local article ID.

## Local development

Mobile: cd yemen_laws_app; flutter pub get; flutter analyze; flutter test.

Backend: cd backend/legal-ai; npm install; npm run typecheck; npm run dev

Cloudflare AI/Vectorize functionality should be tested with remote bindings.

## Deployment

1. Configure D1 and Vectorize.
2. Import the legal corpus.
3. Generate and upsert article embeddings.
4. npx wrangler deploy --name odd-mouse-c1e0
5. Build the APK with the deployed Worker URL using --dart-define.
6. Test /health, then the Android assistant screen.

## Updating the laws

Do not edit legal text inside D1 manually. The source of truth remains yemen_laws_app/assets/db/app_database.db.

When the corpus is intentionally updated, replace the SQLite asset using the existing database build process, increment dbAssetVersion, export the updated corpus, replace D1 records preserving IDs and text, regenerate affected embeddings, and rebuild the app if its local database changed.

## Changing the AI model

Change AI_MODEL in wrangler.toml to a currently supported Workers AI chat model. Keep EMBEDDING_MODEL compatible with the Vectorize index dimension. If the embedding model changes dimension, create a new Vectorize index and re-embed the corpus.

## Production note

The repository contains the application and backend code, but it must not contain Cloudflare account credentials or an invented deployment URL. Those values are supplied during deployment.
