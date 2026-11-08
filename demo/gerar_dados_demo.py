#!/usr/bin/env python3
"""Gera a pizzaria piloto FICTÍCIA e roda uma prévia do motor de oportunidades (PRD §10).

Uso:
    python demo/gerar_dados_demo.py            # gera CSVs em demo/saida/ e imprime a prévia do CRM
    python demo/gerar_dados_demo.py --hoje 2026-11-08 --semente 42

Determinístico (mesma semente + mesma data = mesmos dados). Somente biblioteca padrão.
Todos os registros são de demonstração: telefones na faixa +55 19 900xx-xxxx, e-mails @demo.invalid.
Nenhuma data de pedido fica no futuro. Nunca enviar mensagens reais a partir destes dados.
"""
import argparse, csv, os, random, statistics, sys, uuid
from collections import Counter, defaultdict
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

sys.stdout.reconfigure(errors="backslashreplace")
TZ = ZoneInfo("America/Sao_Paulo")
NS = uuid.UUID("6f1d7c1e-0000-4000-8000-c0de0000beef")  # ids estáveis


def uid(*parts):
    return str(uuid.uuid5(NS, "/".join(map(str, parts))))


# ---------------------------------------------------------------- cardápio
TENANT = dict(id=uid("tenant"), name="Pizzaria Forno da Vila (DEMO)", slug="forno-da-vila-demo",
              city="Campinas", uf="SP", whatsapp="+5519900000000", is_demo=True)
SIZES = [("Broto", 4, 1, 0.55), ("Média", 6, 2, 0.80), ("Grande", 8, 2, 1.00), ("Família", 12, 3, 1.30)]
FLAVORS = {  # nome: (categoria, preço Grande em reais)
    "Mussarela": ("Tradicionais", 54), "Calabresa": ("Tradicionais", 54),
    "Calabresa com Mussarela": ("Tradicionais", 58), "Margherita": ("Tradicionais", 58),
    "Portuguesa": ("Tradicionais", 62), "Frango com Catupiry": ("Tradicionais", 62),
    "Napolitana": ("Tradicionais", 58), "Atum": ("Tradicionais", 64), "Baiana": ("Tradicionais", 60),
    "Quatro Queijos": ("Especiais", 68), "Pepperoni": ("Especiais", 72), "Lombo Canadense": ("Especiais", 70),
    "Carne Seca com Catupiry": ("Especiais", 76), "Rúcula com Tomate Seco": ("Especiais", 72),
    "Bacon com Milho": ("Especiais", 66), "Strogonoff de Frango": ("Especiais", 70),
    "Chocolate": ("Doces", 56), "Prestígio": ("Doces", 60), "Banana com Canela": ("Doces", 54),
    "Romeu e Julieta": ("Doces", 58),
}
POPULAR = ["Calabresa com Mussarela", "Mussarela", "Frango com Catupiry", "Portuguesa", "Calabresa",
           "Quatro Queijos", "Pepperoni", "Margherita"]
BORDERS = [("Borda Catupiry", 1200), ("Borda Cheddar", 1200), ("Borda Chocolate", 1400)]
PRODUCTS = [("Refrigerante 2L", "Bebidas", 1400), ("Refrigerante Lata", "Bebidas", 650),
            ("Suco Natural 500ml", "Bebidas", 1000), ("Água 500ml", "Bebidas", 450),
            ("Cerveja Long Neck", "Bebidas", 1100)]
ZONES = [("Cambuí", 600, 0), ("Centro", 600, 0), ("Taquaral", 700, 5), ("Castelo", 700, 5),
         ("Guanabara", 600, 0), ("Bosque", 600, 0), ("Nova Campinas", 800, 10), ("Jardim Proença", 700, 5),
         ("Botafogo", 600, 0), ("Vila Industrial", 800, 10), ("Ponte Preta", 800, 10), ("Barão Geraldo", 1200, 20)]
FIRST = ("Ana Maria João José Pedro Paulo Lucas Mateus Gabriel Rafael Bruno Felipe Juliana Fernanda Camila "
         "Larissa Beatriz Mariana Patrícia Aline Carla Renata Diego Rodrigo Thiago Marcelo André Vinícius "
         "Gustavo Leonardo Letícia Bianca Natália Vanessa Priscila Eduardo Ricardo Sérgio Helena Sofia").split()
LAST = ("Silva Santos Oliveira Souza Lima Pereira Costa Rodrigues Almeida Nascimento Carvalho Gomes Martins "
        "Araújo Ribeiro Barbosa Rocha Dias Teixeira Moreira Cardoso Correia Mendes Freitas").split()
# persona: (peso, intervalo médio em dias ou None, observação)
PERSONAS = {"semanal": (8, 7), "quinzenal": (15, 14), "mensal": (22, 30), "esporadico": (15, 55),
            "unico": (18, None), "sumiu": (10, 10), "novo": (12, 12)}
PAY = [("pix", 40), ("credit", 25), ("debit", 20), ("cash", 15)]


def price_cents(base_reais, mult):
    v = round(base_reais * mult)  # arredonda e termina em ,90
    return v * 100 - 10


def wchoice(rng, pairs):
    return rng.choices([p[0] for p in pairs], weights=[p[1] for p in pairs])[0]


# ---------------------------------------------------------------- geração
def gerar(hoje, rng):
    t = TENANT["id"]
    data = defaultdict(list)
    data["tenants"].append(TENANT)
    for i, (role, nome) in enumerate([("owner", "Dono Demo"), ("attendant", "Caixa Demo"),
                                      ("attendant", "Atendente Demo"), ("attendant", "Cozinha Demo")]):
        data["users"].append(dict(id=uid("user", i), tenant_id=t, name=nome, role=role,
                                  email=f"{nome.split()[0].lower()}@demo.invalid"))
    for i, (n, slices, mx, mult) in enumerate(SIZES):
        data["pizza_sizes"].append(dict(id=uid("size", n), tenant_id=t, name=n, slices=slices, max_flavors=mx, sort_order=i))
    for n, (cat, base) in FLAVORS.items():
        data["flavors"].append(dict(id=uid("flavor", n), tenant_id=t, name=n, category=cat, active=True))
        for s, _, _, mult in SIZES:
            data["flavor_prices"].append(dict(flavor_id=uid("flavor", n), size_id=uid("size", s),
                                              price_cents=price_cents(base, mult)))
    for n, p in BORDERS:
        data["addons"].append(dict(id=uid("addon", n), tenant_id=t, group="Bordas", name=n, price_cents=p))
    for n, cat, p in PRODUCTS:
        data["products"].append(dict(id=uid("product", n), tenant_id=t, name=n, category=cat, price_cents=p))
    for n, fee, extra in ZONES:
        data["delivery_zones"].append(dict(id=uid("zone", n), tenant_id=t, neighborhood=n, fee_cents=fee, extra_minutes=extra))
    price = {(r["flavor_id"], r["size_id"]): r["price_cents"] for r in data["flavor_prices"]}

    seq, n_customers = 0, 900
    names = list(FLAVORS)
    for ci in range(n_customers):
        persona = rng.choices(list(PERSONAS), weights=[v[0] for v in PERSONAS.values()])[0]
        interval = PERSONAS[persona][1]
        cid = uid("customer", ci)
        bday = None
        if rng.random() < 0.4:
            bday = date(rng.randint(1960, 2005), rng.randint(1, 12), rng.randint(1, 28))
        if ci < 6:  # garante aniversariantes nos próximos dias
            d = hoje + timedelta(days=ci % 4)
            bday = date(1985 + ci, d.month, d.day)
        consent = rng.random() < 0.55
        optout = consent and rng.random() < 0.05
        zone = rng.choice(ZONES)[0]
        data["customers"].append(dict(
            id=cid, tenant_id=t, name=f"{rng.choice(FIRST)} {rng.choice(LAST)}",
            phone_e164=f"+5519900{ci:06d}",
            birth_date=bday.isoformat() if bday else "", neighborhood=zone, persona_demo=persona,
            marketing_consent="revoked" if optout else ("granted" if consent else "none"), is_demo=True))
        favs = rng.sample(POPULAR if rng.random() < 0.7 else names, 2)
        pref_wd = rng.choice([4, 5, 6, 4, 5, 6, 3, 0])  # sex/sáb/dom mais comuns
        # linha do tempo da persona
        if persona == "unico":
            dates = [hoje - timedelta(days=rng.randint(3, 170))]
        else:
            if persona == "novo":
                start = hoje - timedelta(days=rng.randint(10, 40))
            else:
                start = hoje - timedelta(days=rng.randint(120, 182))
            end = hoje - timedelta(days=1)
            if persona == "sumiu":
                end = hoje - timedelta(days=rng.randint(24, 50))
            elif rng.random() < 0.25:  # parte dos clientes esfria naturalmente
                end = hoje - timedelta(days=rng.randint(20, 120))
            dates, d = [], start
            while d <= end:
                dates.append(d)
                gap = max(2, round(rng.gauss(interval, interval * 0.25)))
                d = d + timedelta(days=gap)
                shift = (pref_wd - d.weekday()) % 7  # puxa para o dia preferido às vezes
                if shift <= 2 and rng.random() < 0.6:
                    d += timedelta(days=shift)
        for od in dates:
            if od >= hoje:
                continue
            seq += 1
            hh = rng.choices([18, 19, 20, 21, 22, 23], weights=[5, 20, 30, 25, 15, 5])[0]
            created = datetime(od.year, od.month, od.day, hh, rng.randint(0, 59), tzinfo=TZ)
            oid = uid("order", seq)
            channel = wchoice(rng, [("link", 60), ("phone", 25), ("counter", 15)])
            otype = wchoice(rng, [("delivery", 75), ("pickup", 25)])
            subtotal = 0
            for k in range(1 if rng.random() < 0.7 else 2):
                size = wchoice(rng, [("Grande", 60), ("Família", 20), ("Média", 15), ("Broto", 5)])
                sz = next(s for s in SIZES if s[0] == size)
                nfl = rng.randint(1, sz[2]) if rng.random() < 0.6 else 1
                fl = [rng.choice(favs) if rng.random() < 0.65 else rng.choice(names) for _ in range(nfl)]
                fl = list(dict.fromkeys(fl))
                unit = max(price[(uid("flavor", f), uid("size", size))] for f in fl)  # RN-03 maior preço
                iid = uid("item", seq, k)
                border = rng.choice(BORDERS) if rng.random() < 0.25 else None
                unit += border[1] if border else 0
                subtotal += unit
                data["order_items"].append(dict(id=iid, order_id=oid, kind="pizza", name_snapshot=f"Pizza {size}",
                                                size_snapshot=size, unit_price_cents=unit, qty=1,
                                                addons=border[0] if border else ""))
                for f in fl:
                    data["order_item_flavors"].append(dict(order_item_id=iid, flavor_id=uid("flavor", f),
                                                           name_snapshot=f, fraction=round(1 / len(fl), 2)))
            if rng.random() < 0.55:
                pn, _, pp = rng.choice(PRODUCTS)
                subtotal += pp
                data["order_items"].append(dict(id=uid("item", seq, "b"), order_id=oid, kind="product",
                                                name_snapshot=pn, size_snapshot="", unit_price_cents=pp, qty=1, addons=""))
            fee = next(z[1] for z in ZONES if z[0] == zone) if otype == "delivery" else 0
            status = "cancelled" if rng.random() < 0.03 else "concluded"
            data["orders"].append(dict(id=oid, tenant_id=t, number=seq, customer_id=cid, channel=channel, type=otype,
                                       status=status, subtotal_cents=subtotal, delivery_fee_cents=fee,
                                       total_cents=subtotal + fee, payment_method=wchoice(rng, PAY),
                                       created_at=created.isoformat(), business_date=od.isoformat(), is_demo=True))
    data["orders"].sort(key=lambda o: o["created_at"])
    return data


# ---------------------------------------------------------------- motor (PRD §10)
def motor(data, hoje):
    cust = {c["id"]: c for c in data["customers"]}
    orders = defaultdict(list)
    for o in data["orders"]:
        if o["status"] == "concluded":
            orders[o["customer_id"]].append(o)
    flav_by_order = defaultdict(list)
    item_order = {i["id"]: i["order_id"] for i in data["order_items"]}
    for f in data["order_item_flavors"]:
        flav_by_order[item_order[f["order_item_id"]]].append(f)
    stats = {}
    for cid, os_ in orders.items():
        ds = sorted(date.fromisoformat(o["business_date"]) for o in os_)
        last12 = [d for d in ds if (hoje - d).days <= 365]
        gaps = [(b - a).days for a, b in zip(last12, last12[1:])]
        fl = Counter()
        orders_with = Counter()
        for o in os_:
            seen = set()
            for f in flav_by_order[o["id"]]:
                fl[f["name_snapshot"]] += f["fraction"]
                seen.add(f["name_snapshot"])
            orders_with.update(seen)
        favs = [n for n, _ in fl.most_common(2) if orders_with[n] >= 2]
        wd = Counter(d.weekday() for d in ds)
        top_wd, top_n = wd.most_common(1)[0]
        g180 = sum(o["total_cents"] for o in os_ if (hoje - date.fromisoformat(o["business_date"])).days <= 180)
        stats[cid] = dict(n=len(ds), last=ds[-1], dias=(hoje - ds[-1]).days,
                          intervalo=statistics.median(gaps) if len(last12) >= 3 else None,
                          total=sum(o["total_cents"] for o in os_), g180=g180,
                          n90=sum(1 for d in ds if (hoje - d).days <= 90),
                          n180=sum(1 for d in ds if (hoje - d).days <= 180),
                          favs=favs, dia_pref=top_wd if len(ds) >= 4 and top_n / len(ds) >= 0.5 else None)
    g180s = sorted((s["g180"] for s in stats.values()), reverse=True)
    corte_vip = g180s[max(0, len(g180s) // 10 - 1)] if g180s else 0
    for s in stats.values():
        s["vip"] = s["g180"] >= corte_vip and s["n180"] >= 5

    def gatilho(c, s):
        iv, dd = s["intervalo"], s["dias"]
        if iv and iv <= 21 and dd >= max(2 * iv, iv + 7) and dd < 60:
            return "G2"
        if 25 <= dd <= 30 and s["n"] >= 2:
            return "G1"
        if s["n"] == 1 and 10 <= dd <= 30:
            return "G3"
        if 60 <= dd <= 180:
            return "G4"
        return None

    cards, bloqueados = defaultdict(list), Counter()
    for cid, s in stats.items():
        c = cust[cid]
        g = gatilho(c, s)
        if not g and c["birth_date"]:
            b = date.fromisoformat(c["birth_date"])
            prox = b.replace(year=hoje.year)
            if 0 <= (prox - hoje).days <= 3:
                g = "G5"
        if not g:
            continue
        if c["marketing_consent"] != "granted":
            bloqueados[g] += 1
            continue
        cards[g].append((c, s))
    return stats, cards, bloqueados


def brl(cents):
    return "R$ " + f"{cents / 100:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")


WD = ["segunda", "terça", "quarta", "quinta", "sexta", "sábado", "domingo"]
TITULOS = {"G2": "{n} clientes frequentes saíram do ritmo",
           "G1": "{n} clientes estão quase completando 30 dias sem pedir",
           "G3": "{n} clientes pediram uma vez e não voltaram",
           "G4": "{n} clientes não pedem há mais de 60 dias",
           "G5": "{n} cliente(s) fazem aniversário nos próximos dias"}


def frase(c, s, g):
    nome = c["name"].split()[0]
    p = [f"{'[VIP] ' if s['vip'] else ''}{c['name']} não pede há {s['dias']} dias."]
    if s["intervalo"]:
        p.append(f"Antes pedia a cada ~{round(s['intervalo'])} dias.")
    if s["favs"]:
        p.append(f"Favorita: {s['favs'][0]}.")
    if s["dia_pref"] is not None:
        p.append(f"Costuma pedir às {WD[s['dia_pref']]}s.")
    if g == "G5":
        return " ".join(p), (f"Feliz aniversário, {nome}! A equipe do Forno da Vila deseja um dia incrível. "
                             "Se quiser comemorar com pizza, é só pedir por aqui: forno-da-vila-demo.app")
    msg = f"Oi, {nome}! Faz um tempinho que você não pede com a gente."
    if s["favs"]:
        msg += f" Vimos que a {s['favs'][0]} é uma das suas favoritas."
    msg += " Que tal hoje? Peça por aqui: forno-da-vila-demo.app"
    return " ".join(p), msg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hoje", default=datetime.now(TZ).date().isoformat())
    ap.add_argument("--semente", type=int, default=42)
    ap.add_argument("--saida", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "saida"))
    a = ap.parse_args()
    hoje = date.fromisoformat(a.hoje)
    data = gerar(hoje, random.Random(a.semente))
    os.makedirs(a.saida, exist_ok=True)
    for name, rows in data.items():
        with open(os.path.join(a.saida, f"{name}.csv"), "w", newline="", encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(rows)
    assert all(o["business_date"] < hoje.isoformat() for o in data["orders"]), "pedido com data futura"

    conc = [o for o in data["orders"] if o["status"] == "concluded"]
    ult30 = [o for o in conc if (hoje - date.fromisoformat(o["business_date"])).days <= 30]
    fat30 = sum(o["total_cents"] for o in ult30)
    print(f"== {TENANT['name']} | hoje = {hoje.isoformat()} ==")
    print(f"Clientes: {len(data['customers'])} | Pedidos: {len(data['orders'])} "
          f"({len(data['orders']) - len(conc)} cancelados) | Arquivos em {os.path.relpath(a.saida).replace(os.sep, '/')}")
    print(f"Últimos 30 dias: {len(ult30)} pedidos ({len(ult30) / 30:.0f}/dia), {brl(fat30)}, "
          f"valor médio {brl(fat30 // max(1, len(ult30)))}")

    stats, cards, bloq = motor(data, hoje)
    print("\n== OPORTUNIDADES DE HOJE (prévia do motor, PRD §10) ==")
    for g in ["G2", "G1", "G3", "G4", "G5"]:
        todos = sorted(cards.get(g, []), key=lambda cs: (not cs[1]["vip"], -cs[1]["g180"]))
        if not todos and not bloq[g]:
            continue
        print(f"\n> {TITULOS[g].format(n=len(todos))}"
              + (f" (lista de hoje: os {min(30, len(todos))} mais importantes)" if len(todos) > 30 else "")
              + (f"  [+{bloq[g]} sem autorização para mensagens]" if bloq[g] else ""))
        for c, s in todos[:2]:
            ctx, msg = frase(c, s, g)
            print(f"   - {ctx}\n     Mensagem: \"{msg}\"")


if __name__ == "__main__":
    main()
