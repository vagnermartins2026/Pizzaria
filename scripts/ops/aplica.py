# Aplica supabase/migrations em ordem no projeto da Pizzalia pela API de administração (a chave entra sozinha pelo proxy).
# Cada arquivo: BEGIN; <arquivo>; INSERT no registro supabase_migrations; COMMIT. Para no primeiro erro (o arquivo volta inteiro).
# Pula o que já está no registro (pode ser rodado de novo).
import json, os, sys, urllib.request, time
REF = "tsidqofldtkkgexbmtor"; PASTA = sys.argv[1]
URL = f"https://api.supabase.com/v1/projects/{REF}/database/query"
def q(sql, tentativas=3):
    corpo = json.dumps({"query": sql}).encode()
    for t in range(tentativas):
        req = urllib.request.Request(URL, data=corpo, method="POST", headers={"Content-Type": "application/json", "Authorization": "Bearer x"})
        try:
            with urllib.request.urlopen(req, timeout=300) as r: return r.status, r.read().decode()
        except urllib.error.HTTPError as e: return e.code, e.read().decode()
        except Exception as e:
            if t == tentativas - 1: return 0, str(e)
            time.sleep(3 * (t + 1))
st, txt = q("CREATE SCHEMA IF NOT EXISTS supabase_migrations; CREATE TABLE IF NOT EXISTS supabase_migrations.schema_migrations (version text PRIMARY KEY, statements text[], name text); SELECT coalesce(json_agg(version), '[]') v FROM supabase_migrations.schema_migrations;")
assert st in (200, 201), (st, txt[:300])
feitas = set(json.loads(json.loads(txt)[0]["v"]) if isinstance(json.loads(txt)[0]["v"], str) else json.loads(txt)[0]["v"])
arquivos = sorted(f for f in os.listdir(PASTA) if f.endswith(".sql"))
ok = 0
for f in arquivos:
    versao, _, nome = f[:-4].partition("_")
    if versao in feitas: continue
    sql = open(os.path.join(PASTA, f), encoding="utf-8").read()
    dollar = "$migr$"; assert dollar not in sql
    reg = f"INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('{versao}', '{nome}', ARRAY[{dollar}{sql}{dollar}]);"
    st, txt = q(f"BEGIN;\n{sql}\n;\n{reg}\nCOMMIT;")
    if st not in (200, 201):
        print(f"PAROU em {f}: HTTP {st}: {txt[:800]}"); q("ROLLBACK;"); sys.exit(1)
    ok += 1; print(f"ok {ok:3d} {f}", flush=True)
print(f"FIM: {ok} aplicadas agora; {len(feitas)} já estavam; total de arquivos {len(arquivos)}")
