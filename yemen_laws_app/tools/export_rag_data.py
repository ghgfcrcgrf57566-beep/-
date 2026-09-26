"""Read-only export of the existing legal SQLite database for the RAG backend."""
import argparse, json, sqlite3
from pathlib import Path

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--db",required=True); p.add_argument("--out",required=True)
    a=p.parse_args(); out=Path(a.out); out.mkdir(parents=True,exist_ok=True)
    con=sqlite3.connect(a.db); con.row_factory=sqlite3.Row
    for table in ("laws","abwab","fusul","mawad"):
        rows=[dict(r) for r in con.execute("SELECT * FROM "+table)]
        (out/(table+".json")).write_text(json.dumps(rows,ensure_ascii=False,separators=(",",":")),encoding="utf-8")
    con.close()
    print("Exported RAG data to",out)
if __name__=="__main__": main()
