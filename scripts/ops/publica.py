# Publica funções do servidor no projeto da Pizzalia pela API de administração (a chave entra sozinha pelo proxy).
# Envia a pasta da função + supabase/functions/_shared (sem arquivos de teste) e mantém o verify_jwt do supabase/config.toml.
import json, os, re, sys, uuid, urllib.request
REF = "tsidqofldtkkgexbmtor"; BASE = "supabase/functions"
cfg = open("supabase/config.toml").read()
def verify_jwt(slug):
    m = re.search(r"\[functions\.%s\]\s*\nverify_jwt\s*=\s*(true|false)" % re.escape(slug), cfg)
    assert m, f"sem verify_jwt para {slug}"; return m.group(1) == "true"
def arquivos(slug):
    for pasta in (slug, "_shared"):
        for raiz, _, fs in os.walk(os.path.join(BASE, pasta)):
            if "__tests__" in raiz: continue
            for f in fs:
                if re.search(r"(_test|\.test)\.ts$", f) or not f.endswith((".ts", ".js", ".json")): continue
                p = os.path.join(raiz, f); yield os.path.relpath(p, BASE), open(p, "rb").read()
def publica(slug):
    vj = verify_jwt(slug); b = uuid.uuid4().hex; partes = []
    meta = {"entrypoint_path": f"{slug}/index.ts", "name": slug, "verify_jwt": vj}
    partes.append(f'--{b}\r\nContent-Disposition: form-data; name="metadata"\r\nContent-Type: application/json\r\n\r\n{json.dumps(meta)}\r\n'.encode())
    for nome, dado in arquivos(slug):
        partes.append(f'--{b}\r\nContent-Disposition: form-data; name="file"; filename="{nome}"\r\nContent-Type: application/typescript\r\n\r\n'.encode() + dado + b"\r\n")
    partes.append(f"--{b}--\r\n".encode())
    req = urllib.request.Request(f"https://api.supabase.com/v1/projects/{REF}/functions/deploy?slug={slug}", data=b"".join(partes), method="POST",
          headers={"Content-Type": f"multipart/form-data; boundary={b}", "Authorization": "Bearer x"})
    try:
        with urllib.request.urlopen(req, timeout=300) as r: d = json.loads(r.read().decode()); return True, f"versão {d.get('version')} verify_jwt={d.get('verify_jwt')} (esperado {vj}) status={d.get('status')}"
    except urllib.error.HTTPError as e: return False, f"HTTP {e.code}: {e.read().decode()[:600]}"
falhas = 0
for slug in sys.argv[1:]:
    ok, msg = publica(slug); print(("ok   " if ok else "FALHA"), slug, msg, flush=True); falhas += not ok
sys.exit(1 if falhas else 0)
