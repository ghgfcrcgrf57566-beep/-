import {
  AIProviderError,
  createAIProvider,
} from "./ai_provider";

export interface Env {
  DB: D1Database;
  VECTOR_INDEX?: VectorizeIndex;
  AI: Ai;
  ALLOWED_APP_VERSION: string;
  MAX_QUESTION_CHARS: string;
  MAX_RESULTS: string;
  MIN_RELEVANCE_SCORE: string;
  AI_PROVIDER: string;
  AI_MODEL: string;
  EMBEDDING_MODEL: string;
  GEMINI_API_KEY?: string;
  REINDEX_TOKEN?: string;
}

type Source = {
  article_id: number;
  law_name: string;
  article_number: string;
  article_text: string;
  chapter?: string | null;
  score?: number;
};

type HistoryMessage = {
  role: "user" | "assistant";
  content: string;
};

type WebSource = {
  title: string;
  url: string;
};

type ChatRequestBody = {
  message?: unknown;
  question?: unknown;
  conversation_id?: unknown;
  history?: unknown;
  language?: unknown;
  fallback_from_local?: unknown;
};

const HEADERS = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, POST, OPTIONS",
  "access-control-allow-headers": "content-type, x-app-version",
};

const SYSTEM = "أنت مساعد معرفي وقانوني لموسوعة القوانين اليمنية. استخدم بحث Google على الإنترنت كمصدر البحث الوحيد لهذه المحادثة. لا تعتمد على قاعدة البيانات المحلية للموسوعة ولا على ذاكرتك وحدها عند الإجابة. ابحث في الويب فعليًا قبل الإجابة، ثم لخّص المعلومات بالعربية وبوضوح. عند السؤال عن قانون أو مادة يمنية، حاول الوصول إلى نص القانون أو مصدر رسمي أو مصدر قانوني موثوق، واذكر المصدر. إذا لم تجد معلومات موثوقة، قل ذلك بوضوح ولا تخمّن. يمكنك شرح الكلمات والمصطلحات القانونية وغير القانونية شرحًا مبسطًا. فرّق بين المعلومة المنشورة على الويب وبين الرأي أو الشرح. لا تقدّم الإجابة باعتبارها حكمًا قضائيًا أو استشارة قانونية ملزمة.";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: HEADERS });
    }

    if (url.pathname === "/health") {
      return json({ ok: true });
    }

    if (url.pathname === "/admin/reindex") {
      return handleReindex(request, env, url);
    }

    if (url.pathname === "/api/chat" || url.pathname === "/api/legal/ask") {
      if (request.method !== "POST") {
        return json({ error: "Method not allowed" }, 405);
      }
      return handleChat(request, env, url.pathname === "/api/legal/ask");
    }

    return json({ error: "Not found" }, 404);
  },
};

async function handleChat(
  request: Request,
  env: Env,
  legacyResponse: boolean,
): Promise<Response> {
  const version = request.headers.get("x-app-version") || "";
  if (env.ALLOWED_APP_VERSION && version !== env.ALLOWED_APP_VERSION) {
    return json({ error: "نسخة التطبيق غير مدعومة حالياً." }, 403);
  }

  if (!(await rateLimit(request, env))) {
    return json({ error: "تم تجاوز حد الاستخدام مؤقتاً. حاول لاحقاً." }, 429);
  }

  try {
    const body = await request.json() as ChatRequestBody;
    const rawQuestion =
      typeof body.message === "string"
        ? body.message
        : typeof body.question === "string"
          ? body.question
          : "";

    const question = rawQuestion.trim();
    const max = Number(env.MAX_QUESTION_CHARS || 1200);

    if (!question) {
      return json({ error: "السؤال فارغ." }, 400);
    }

    if (question.length > max) {
      return json({ error: "السؤال أطول من الحد المسموح." }, 400);
    }

    const history = normalizeHistory(body.history);
    const language =
      typeof body.language === "string" && body.language.trim()
        ? body.language.trim().slice(0, 16)
        : "ar";

    const conversationId =
      typeof body.conversation_id === "string" && body.conversation_id.trim()
        ? body.conversation_id.trim().slice(0, 128)
        : crypto.randomUUID();

    // الإنترنت هو مصدر البحث الوحيد. لا نستدعي D1 أو Vectorize للإجابة.
    const result = await generateAnswer(
      question,
      language,
      history,
      [],
      env,
      SYSTEM,
    );

    return json({
      answer: result.answer,
      sources: result.webSources,
      conversation_id: conversationId,
      response_source: "web_search",
    });
  } catch (error) {
    if (error instanceof AIProviderError) {
      return json({ error: error.userMessage }, 503);
    }

    console.error(
      "Legal AI request failed",
      error instanceof Error ? error.message : String(error),
    );
    return json({ error: "حدث خطأ داخلي أثناء معالجة السؤال." }, 500);
  }
}

async function handleReindex(
  request: Request,
  env: Env,
  url: URL,
): Promise<Response> {
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  if (
    !env.REINDEX_TOKEN ||
    request.headers.get("authorization") !== `Bearer ${env.REINDEX_TOKEN}`
  ) {
    return json({ error: "Unauthorized" }, 401);
  }

  if (!env.VECTOR_INDEX) {
    return json({ error: "Vectorize is not configured." }, 503);
  }

  try {
    const after = Number(url.searchParams.get("after") || 0);
    const limit = Math.min(
      Math.max(Number(url.searchParams.get("limit") || 40), 1),
      60,
    );

    const rows = await env.DB
      .prepare(
        "SELECT id,law_id,number,body FROM mawad WHERE id>? ORDER BY id LIMIT ?",
      )
      .bind(after, limit)
      .all<{ id: number; law_id: number; number: string; body: string }>();

    const articles = rows.results || [];
    if (!articles.length) {
      return json({ done: true, next_after: after, processed: 0 });
    }

    const embeddings = await env.AI.run(
      env.EMBEDDING_MODEL,
      { text: articles.map((article) => String(article.body)) },
    ) as { data: number[][] };

    const vectors = articles.map((article, index) => ({
      id: String(article.id),
      values: embeddings.data[index],
    }));

    await env.VECTOR_INDEX.upsert(vectors);

    const next = Number(articles[articles.length - 1].id);
    return json({
      done: articles.length < limit,
      next_after: next,
      processed: articles.length,
    });
  } catch (error) {
    console.error(
      "Reindex failed",
      error instanceof Error ? error.message : String(error),
    );
    return json({ error: "تعذر تحديث الفهرس الدلالي حالياً." }, 500);
  }
}

function normalizeHistory(value: unknown): HistoryMessage[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .filter(
      (message: any) =>
        message &&
        (message.role === "user" || message.role === "assistant") &&
        typeof message.content === "string",
    )
    .map((message: any) => ({
      role: message.role,
      content: message.content.trim().slice(0, 2000),
    }))
    .filter((message) => message.content)
    .slice(-12);
}

function hasEnoughEvidence(sources: Source[], env: Env): boolean {
  if (!sources.length) {
    return false;
  }

  const threshold = Number(env.MIN_RELEVANCE_SCORE || 0.15);
  return Number(sources[0].score || 0) >= threshold;
}

async function retrieve(
  question: string,
  env: Env,
): Promise<Source[]> {
  const limit = Math.min(
    Math.max(Number(env.MAX_RESULTS || 8), 3),
    12,
  );

  const [semantic, lexical] = await Promise.all([
    semanticSearch(question, env, limit),
    lexicalSearch(question, env, limit),
  ]);

  const merged = new Map<number, Source>();

  for (const source of [...semantic, ...lexical]) {
    const previous = merged.get(source.article_id);
    if (!previous || (source.score || 0) > (previous.score || 0)) {
      merged.set(source.article_id, source);
    }
  }

  return [...merged.values()]
    .sort((a, b) => (b.score || 0) - (a.score || 0))
    .slice(0, limit);
}

async function semanticSearch(
  question: string,
  env: Env,
  limit: number,
): Promise<Source[]> {
  if (!env.VECTOR_INDEX) {
    return [];
  }

  try {
    const embedding = await env.AI.run(
      env.EMBEDDING_MODEL,
      { text: [question] },
    ) as { data: number[][] };

    const vector = embedding.data?.[0];
    if (!vector) {
      return [];
    }

    const result = await env.VECTOR_INDEX.query(vector, {
      topK: limit,
      returnMetadata: "none",
    });

    const ids = (result.matches || [])
      .map((match: any) => Number(match.id))
      .filter(Number.isFinite);

    if (!ids.length) {
      return [];
    }

    const placeholders = ids.map(() => "?").join(",");
    const rows = await env.DB
      .prepare(
        "SELECT m.id article_id,l.name law_name,m.number article_number,m.body article_text,COALESCE(f.label,b.label) chapter " +
        "FROM mawad m JOIN laws l ON l.id=m.law_id " +
        "LEFT JOIN fusul f ON f.id=m.fasl_id " +
        "LEFT JOIN abwab b ON b.id=m.bab_id " +
        "WHERE m.id IN (" + placeholders + ")",
      )
      .bind(...ids)
      .all<Source>();

    const scores = new Map(
      (result.matches || []).map((match: any) => [
        Number(match.id),
        Number(match.score || 0),
      ]),
    );

    return (rows.results || []).map((row) => ({
      ...row,
      score: scores.get(row.article_id) || 0,
    }));
  } catch (error) {
    console.error(
      "Semantic retrieval failed",
      error instanceof Error ? error.message : String(error),
    );
    return [];
  }
}

async function lexicalSearch(
  question: string,
  env: Env,
  limit: number,
): Promise<Source[]> {
  const terms = normalize(question)
    .split(/\s+/)
    .filter((term) => term.length >= 2)
    .slice(0, 10);

  if (!terms.length) {
    return [];
  }

  const clauses = terms
    .map(() => "(m.body LIKE ? OR m.number LIKE ? OR l.name LIKE ?)")
    .join(" OR ");

  const args: string[] = [];
  for (const term of terms) {
    args.push(`%${term}%`, `%${term}%`, `%${term}%`);
  }

  const rows = await env.DB
    .prepare(
      "SELECT m.id article_id,l.name law_name,m.number article_number,m.body article_text,COALESCE(f.label,b.label) chapter " +
      "FROM mawad m JOIN laws l ON l.id=m.law_id " +
      "LEFT JOIN fusul f ON f.id=m.fasl_id " +
      "LEFT JOIN abwab b ON b.id=m.bab_id " +
      "WHERE " + clauses + " LIMIT 80",
    )
    .bind(...args)
    .all<Source>();

  return (rows.results || [])
    .map((row) => {
      const haystack = normalize(
        row.law_name + " " + row.article_number + " " + row.article_text,
      );

      const hits = terms.reduce(
        (count, term) => count + (haystack.includes(term) ? 1 : 0),
        0,
      );

      return {
        ...row,
        score: hits / terms.length,
      };
    })
    .sort((a, b) => (b.score || 0) - (a.score || 0))
    .slice(0, limit);
}

async function generateAnswer(
  question: string,
  language: string,
  history: HistoryMessage[],
  sources: Source[],
  env: Env,
  systemInstruction: string,
): Promise<{ answer: string; webSources: WebSource[] }> {
  const provider = createAIProvider(env);

  return provider.generateAnswer({
    systemInstruction,
    language,
    question,
    history,
    sources,
  });
}

import {
  AIProviderError,
  createAIProvider,
} from "./ai_provider";

export interface Env {
  DB: D1Database;
  VECTOR_INDEX?: VectorizeIndex;
  AI: Ai;
  ALLOWED_APP_VERSION: string;
  MAX_QUESTION_CHARS: string;
  MAX_RESULTS: string;
  MIN_RELEVANCE_SCORE: string;
  AI_PROVIDER: string;
  AI_MODEL: string;
  EMBEDDING_MODEL: string;
  GEMINI_API_KEY?: string;
  REINDEX_TOKEN?: string;
}

type Source = {
  article_id: number;
  law_name: string;
  article_number: string;
  article_text: string;
  chapter?: string | null;
  score?: number;
};

type HistoryMessage = {
  role: "user" | "assistant";
  content: string;
};

type ChatRequestBody = {
  message?: unknown;
  question?: unknown;
  conversation_id?: unknown;
  history?: unknown;
  language?: unknown;
  fallback_from_local?: unknown;
};

const HEADERS = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, POST, OPTIONS",
  "access-control-allow-headers": "content-type, x-app-version",
};

const SYSTEM = "أنت مساعد معرفي وقانوني لموسوعة القوانين اليمنية. استخدم بحث Google على الإنترنت كمصدر البحث الوحيد لهذه المحادثة. لا تعتمد على قاعدة البيانات المحلية للموسوعة ولا على ذاكرتك وحدها عند الإجابة. ابحث في الويب فعليًا قبل الإجابة، ثم لخّص المعلومات بالعربية وبوضوح. عند السؤال عن قانون أو مادة يمنية، حاول الوصول إلى نص القانون أو مصدر رسمي أو مصدر قانوني موثوق، واذكر المصدر. إذا لم تجد معلومات موثوقة، قل ذلك بوضوح ولا تخمّن. يمكنك شرح الكلمات والمصطلحات القانونية وغير القانونية شرحًا مبسطًا. فرّق بين المعلومة المنشورة على الويب وبين الرأي أو الشرح. لا تقدّم الإجابة باعتبارها حكمًا قضائيًا أو استشارة قانونية ملزمة.";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: HEADERS });
    }

    if (url.pathname === "/health") {
      return json({ ok: true });
    }

    if (url.pathname === "/admin/reindex") {
      return handleReindex(request, env, url);
    }

    if (url.pathname === "/api/chat" || url.pathname === "/api/legal/ask") {
      if (request.method !== "POST") {
        return json({ error: "Method not allowed" }, 405);
      }
      return handleChat(request, env, url.pathname === "/api/legal/ask");
    }

    return json({ error: "Not found" }, 404);
  },
};

async function handleChat(
  request: Request,
  env: Env,
  legacyResponse: boolean,
): Promise<Response> {
  const version = request.headers.get("x-app-version") || "";
  if (env.ALLOWED_APP_VERSION && version !== env.ALLOWED_APP_VERSION) {
    return json({ error: "نسخة التطبيق غير مدعومة حالياً." }, 403);
  }

  if (!(await rateLimit(request, env))) {
    return json({ error: "تم تجاوز حد الاستخدام مؤقتاً. حاول لاحقاً." }, 429);
  }

  try {
    const body = await request.json() as ChatRequestBody;
    const rawQuestion =
      typeof body.message === "string"
        ? body.message
        : typeof body.question === "string"
          ? body.question
          : "";

    const question = rawQuestion.trim();
    const max = Number(env.MAX_QUESTION_CHARS || 1200);

    if (!question) {
      return json({ error: "السؤال فارغ." }, 400);
    }

    if (question.length > max) {
      return json({ error: "السؤال أطول من الحد المسموح." }, 400);
    }

    const history = normalizeHistory(body.history);
    const language =
      typeof body.language === "string" && body.language.trim()
        ? body.language.trim().slice(0, 16)
        : "ar";

    const conversationId =
      typeof body.conversation_id === "string" && body.conversation_id.trim()
        ? body.conversation_id.trim().slice(0, 128)
        : crypto.randomUUID();

    // الإنترنت هو مصدر البحث الوحيد. لا نستدعي D1 أو Vectorize للإجابة.
    const result = await generateAnswer(
      question,
      language,
      history,
      [],
      env,
      SYSTEM,
    );

    return json({
      answer: result.answer,
      sources: result.webSources,
      conversation_id: conversationId,
      response_source: "web_search",
    });
  } catch (error) {
    if (error instanceof AIProviderError) {
      return json({ error: error.userMessage }, 503);
    }

    console.error(
      "Legal AI request failed",
      error instanceof Error ? error.message : String(error),
    );
    return json({ error: "حدث خطأ داخلي أثناء معالجة السؤال." }, 500);
  }
}

async function handleReindex(
  request: Request,
  env: Env,
  url: URL,
): Promise<Response> {
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  if (
    !env.REINDEX_TOKEN ||
    request.headers.get("authorization") !== `Bearer ${env.REINDEX_TOKEN}`
  ) {
    return json({ error: "Unauthorized" }, 401);
  }

  if (!env.VECTOR_INDEX) {
    return json({ error: "Vectorize is not configured." }, 503);
  }

  try {
    const after = Number(url.searchParams.get("after") || 0);
    const limit = Math.min(
      Math.max(Number(url.searchParams.get("limit") || 40), 1),
      60,
    );

    const rows = await env.DB
      .prepare(
        "SELECT id,law_id,number,body FROM mawad WHERE id>? ORDER BY id LIMIT ?",
      )
      .bind(after, limit)
      .all<{ id: number; law_id: number; number: string; body: string }>();

    const articles = rows.results || [];
    if (!articles.length) {
      return json({ done: true, next_after: after, processed: 0 });
    }

    const embeddings = await env.AI.run(
      env.EMBEDDING_MODEL,
      { text: articles.map((article) => String(article.body)) },
    ) as { data: number[][] };

    const vectors = articles.map((article, index) => ({
      id: String(article.id),
      values: embeddings.data[index],
    }));

    await env.VECTOR_INDEX.upsert(vectors);

    const next = Number(articles[articles.length - 1].id);
    return json({
      done: articles.length < limit,
      next_after: next,
      processed: articles.length,
    });
  } catch (error) {
    console.error(
      "Reindex failed",
      error instanceof Error ? error.message : String(error),
    );
    return json({ error: "تعذر تحديث الفهرس الدلالي حالياً." }, 500);
  }
}

function normalizeHistory(value: unknown): HistoryMessage[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .filter(
      (message: any) =>
        message &&
        (message.role === "user" || message.role === "assistant") &&
        typeof message.content === "string",
    )
    .map((message: any) => ({
      role: message.role,
      content: message.content.trim().slice(0, 2000),
    }))
    .filter((message) => message.content)
    .slice(-12);
}

function hasEnoughEvidence(sources: Source[], env: Env): boolean {
  if (!sources.length) {
    return false;
  }

  const threshold = Number(env.MIN_RELEVANCE_SCORE || 0.15);
  return Number(sources[0].score || 0) >= threshold;
}

async function retrieve(
  question: string,
  env: Env,
): Promise<Source[]> {
  const limit = Math.min(
    Math.max(Number(env.MAX_RESULTS || 8), 3),
    12,
  );

  const [semantic, lexical] = await Promise.all([
    semanticSearch(question, env, limit),
    lexicalSearch(question, env, limit),
  ]);

  const merged = new Map<number, Source>();

  for (const source of [...semantic, ...lexical]) {
    const previous = merged.get(source.article_id);
    if (!previous || (source.score || 0) > (previous.score || 0)) {
      merged.set(source.article_id, source);
    }
  }

  return [...merged.values()]
    .sort((a, b) => (b.score || 0) - (a.score || 0))
    .slice(0, limit);
}

async function semanticSearch(
  question: string,
  env: Env,
  limit: number,
): Promise<Source[]> {
  if (!env.VECTOR_INDEX) {
    return [];
  }

  try {
    const embedding = await env.AI.run(
      env.EMBEDDING_MODEL,
      { text: [question] },
    ) as { data: number[][] };

    const vector = embedding.data?.[0];
    if (!vector) {
      return [];
    }

    const result = await env.VECTOR_INDEX.query(vector, {
      topK: limit,
      returnMetadata: "none",
    });

    const ids = (result.matches || [])
      .map((match: any) => Number(match.id))
      .filter(Number.isFinite);

    if (!ids.length) {
      return [];
    }

    const placeholders = ids.map(() => "?").join(",");
    const rows = await env.DB
      .prepare(
        "SELECT m.id article_id,l.name law_name,m.number article_number,m.body article_text,COALESCE(f.label,b.label) chapter " +
        "FROM mawad m JOIN laws l ON l.id=m.law_id " +
        "LEFT JOIN fusul f ON f.id=m.fasl_id " +
        "LEFT JOIN abwab b ON b.id=m.bab_id " +
        "WHERE m.id IN (" + placeholders + ")",
      )
      .bind(...ids)
      .all<Source>();

    const scores = new Map(
      (result.matches || []).map((match: any) => [
        Number(match.id),
        Number(match.score || 0),
      ]),
    );

    return (rows.results || []).map((row) => ({
      ...row,
      score: scores.get(row.article_id) || 0,
    }));
  } catch (error) {
    console.error(
      "Semantic retrieval failed",
      error instanceof Error ? error.message : String(error),
    );
    return [];
  }
}

async function lexicalSearch(
  question: string,
  env: Env,
  limit: number,
): Promise<Source[]> {
  const terms = normalize(question)
    .split(/\s+/)
    .filter((term) => term.length >= 2)
    .slice(0, 10);

  if (!terms.length) {
    return [];
  }

  const clauses = terms
    .map(() => "(m.body LIKE ? OR m.number LIKE ? OR l.name LIKE ?)")
    .join(" OR ");

  const args: string[] = [];
  for (const term of terms) {
    args.push(`%${term}%`, `%${term}%`, `%${term}%`);
  }

  const rows = await env.DB
    .prepare(
      "SELECT m.id article_id,l.name law_name,m.number article_number,m.body article_text,COALESCE(f.label,b.label) chapter " +
      "FROM mawad m JOIN laws l ON l.id=m.law_id " +
      "LEFT JOIN fusul f ON f.id=m.fasl_id " +
      "LEFT JOIN abwab b ON b.id=m.bab_id " +
      "WHERE " + clauses + " LIMIT 80",
    )
    .bind(...args)
    .all<Source>();

  return (rows.results || [])
    .map((row) => {
      const haystack = normalize(
        row.law_name + " " + row.article_number + " " + row.article_text,
      );

      const hits = terms.reduce(
        (count, term) => count + (haystack.includes(term) ? 1 : 0),
        0,
      );

      return {
        ...row,
        score: hits / terms.length,
      };
    })
    .sort((a, b) => (b.score || 0) - (a.score || 0))
    .slice(0, limit);
}

async function generateAnswer(
  question: string,
  language: string,
  history: HistoryMessage[],
  sources: Source[],
  env: Env,
  systemInstruction: string,
): Promise<string> {
  const provider = createAIProvider(env);

  return provider.generateAnswer({
    systemInstruction,
    language,
    question,
    history,
    sources,
  });
}

function normalize(value: string): string {
  return value
    .toLowerCase()
    .replace(/[ً-ٟ]/g, "")
    .replace(/[إأآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه")
    .replace(/ـ/g, "")
    .replace(/[^\u0600-\u06FF\w\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

async function rateLimit(
  request: Request,
  env: Env,
): Promise<boolean> {
  const ip = request.headers.get("CF-Connecting-IP") || "unknown";
  const data = new TextEncoder().encode(ip);
  const digest = await crypto.subtle.digest("SHA-256", data);
  const key = [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");

  const bucket = Math.floor(Date.now() / 60000);
  const row = await env.DB
    .prepare(
      "SELECT count FROM ai_rate_limits WHERE key=? AND bucket=?",
    )
    .bind(key, bucket)
    .first<{ count: number }>();

  const count = (row?.count || 0) + 1;
  if (count > 20) {
    return false;
  }

  await env.DB
    .prepare(
      "INSERT INTO ai_rate_limits(key,bucket,count) VALUES(?,?,?) " +
      "ON CONFLICT(key,bucket) DO UPDATE SET count=count+1",
    )
    .bind(key, bucket, 1)
    .run();

  await env.DB
    .prepare("DELETE FROM ai_rate_limits WHERE bucket<?")
    .bind(bucket - 2)
    .run();

  return true;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: HEADERS,
  });
}
