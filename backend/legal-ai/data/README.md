# D1 seed data

`seed.sql` is generated from the application's canonical SQLite database:

- `../../yemen_laws_app/assets/db/app_database.db`
- exporter: `../../yemen_laws_app/tools/export_rag_data.py`

Run `bash setup-cloudflare.sh` to regenerate the seed before applying it to D1.

Do not hand-edit legal text in this directory. The mobile SQLite database remains the legal source of truth.
