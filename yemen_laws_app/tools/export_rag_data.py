"""Read-only export of the existing legal SQLite database for the RAG backend."""
import argparse, json, sqlite3
from pathlib import Path

def sql(v):
    if v is None: return "NULL"
    return "'" + str(v).replace("'", "''") + "'"

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--db",required=True); p.add_argument("--out",required=True)
    a=p.parse_args(); out=Path(a.out); out.mkdir(parents=True,exist_ok=True)
    con=sqlite3.connect(a.db); con.row_factory=sqlite3.Row
    statements=[]
    for table in ("laws","abwab","fusul","mawad"):
        rows=[dict(r) for r in con.execute("SELECT * FROM "+table)]
        (out/(table+".json")).write_text(json.dumps(rows,ensure_ascii=False,separators=(",",":")),encoding="utf-8")
        for row in rows:
            cols=", ".join(row.keys())
            vals=", ".join(sql(v) for v in row.values())
            statements.append("INSERT OR REPLACE INTO "+table+" ("+cols+") VALUES ("+vals+");")
    (out/"seed.sql").write_text("\n".join(statements)+"\n",encoding="utf-8")
    con.close()
    print("Exported JSON and D1 seed SQL to",out)

if __name__=="__main__": main()
