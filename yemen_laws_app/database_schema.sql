-- مخطط قاعدة بيانات موسوعة القوانين اليمنية
-- (مرجع مستقل - نفس المخطط المُستخدم فعليًا في tools/build_db.py)

CREATE TABLE laws (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_name TEXT,
    order_num INTEGER,
    articles_count INTEGER DEFAULT 0
);

CREATE TABLE abwab (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    law_id INTEGER NOT NULL REFERENCES laws(id) ON DELETE CASCADE,
    parent_bab_id INTEGER REFERENCES abwab(id) ON DELETE CASCADE,
    level TEXT,
    label TEXT,
    title TEXT,
    order_num INTEGER
);

CREATE TABLE fusul (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    law_id INTEGER NOT NULL REFERENCES laws(id) ON DELETE CASCADE,
    bab_id INTEGER REFERENCES abwab(id) ON DELETE CASCADE,
    label TEXT,
    title TEXT,
    order_num INTEGER
);

CREATE TABLE mawad (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    law_id INTEGER NOT NULL REFERENCES laws(id) ON DELETE CASCADE,
    fasl_id INTEGER REFERENCES fusul(id) ON DELETE CASCADE,
    bab_id INTEGER REFERENCES abwab(id) ON DELETE CASCADE,
    number TEXT,
    body TEXT NOT NULL,
    order_num INTEGER
);

CREATE TABLE favorites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    mada_id INTEGER NOT NULL REFERENCES mawad(id) ON DELETE CASCADE,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(mada_id)
);

CREATE VIRTUAL TABLE mawad_fts USING fts5(
    body, number, content='mawad', content_rowid='id'
);

CREATE TRIGGER mawad_ai AFTER INSERT ON mawad BEGIN
    INSERT INTO mawad_fts(rowid, body, number) VALUES (new.id, new.body, new.number);
END;

CREATE INDEX idx_abwab_law ON abwab(law_id);
CREATE INDEX idx_abwab_parent ON abwab(parent_bab_id);
CREATE INDEX idx_fusul_law ON fusul(law_id);
CREATE INDEX idx_fusul_bab ON fusul(bab_id);
CREATE INDEX idx_mawad_law ON mawad(law_id);
CREATE INDEX idx_mawad_fasl ON mawad(fasl_id);
CREATE INDEX idx_mawad_bab ON mawad(bab_id);
