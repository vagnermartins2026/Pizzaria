#!/usr/bin/env python3
"""Pizzalia · monta a carga da pizzaria DEMO (Forno da Vila) nas tabelas da BASE (remix da MayFlower).

Lê os CSVs de demo/gerar_dados_demo.py e demo/gerar_gestao_demo.py (pasta demo/saida) e escreve arquivos SQL em ordem
(01_loja.sql, 02_cadastros.sql, ...), um por bloco, para rodar como administrador do banco (o papel "postgres": as travas
"só pela rotina" valem para quem usa o site, como nos testes da própria base).

Regras (docs/PILOTO-DEMO.md):
- tudo na loja demo (o id da loja = o id do login do dono de teste, como na base: stores.id = dona);
- idempotente: todo registro tem id fixo (uuid5) e ON CONFLICT DO NOTHING; rodar de novo não duplica;
- nada no futuro; valores em reais (numeric) como a base guarda; telefones e e-mails fictícios;
- remoção = pelo id da loja demo, nunca por filtro genérico.

Traduções (a base é de varejo; o que não tem tela na base fica para os módulos próprios da Pizzalia):
- pizza: um produto por sabor e tamanho ("Calabresa (Grande)"); feita na hora, estoque 999 (não controlado);
- insumo: produto de uso interno (categoria "Insumos (uso interno)", preço 0). Quilo e litro em unidades de 100 g/100 ml
  (a base conta estoque em números inteiros);
- pedido (link, telefone, balcão) e comanda do salão → venda; taxa de entrega e taxa de serviço viram itens da venda;
- custo do item = ficha técnica (insumos x custo), para os relatórios de lucro;
- cartão → conta a receber (valor líquido, com o bruto e a taxa na observação); despesas e compras → contas a pagar.
Uso: python3 db/seed/montar_carga_base.py --loja <uuid> --hoje 2026-11-13 [--entrada demo/saida] [--saida <pasta>]
"""
import argparse, csv, json, math, os, uuid
from collections import defaultdict
from datetime import date, datetime, timedelta, timezone

NS = uuid.UUID("6f1c3b0e-5d2a-4c1e-9a7b-2f0e1d3c4b5a")
TZ = timezone(timedelta(hours=-3))


def uid(*partes):
    return str(uuid.uuid5(NS, ":".join(str(p) for p in partes)))


def ler(pasta, nome):
    with open(os.path.join(pasta, nome + ".csv"), encoding="utf-8") as f:
        return list(csv.DictReader(f))


def q(v):
    """Literal SQL."""
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, (dict, list)):
        return "'" + json.dumps(v, ensure_ascii=False).replace("'", "''") + "'::jsonb"
    return "'" + str(v).replace("'", "''") + "'"


def reais(c):
    return round(int(c) / 100, 2)


def inserts(tabela, colunas, linhas, conflito="(id)", lote=500):
    out = []
    for i in range(0, len(linhas), lote):
        vals = ",\n".join("(" + ", ".join(q(l[c]) for c in colunas) + ")" for l in linhas[i:i + lote])
        out.append(f"INSERT INTO public.{tabela} ({', '.join(colunas)}) VALUES\n{vals}\nON CONFLICT {conflito} DO NOTHING;")
    return "\n".join(out)


def telefone(e164):
    d = e164.replace("+55", "")
    return f"({d[:2]}) {d[2:7]}-{d[7:]}" if len(d) == 11 else d


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--loja", required=True)
    ap.add_argument("--hoje", required=True)
    ap.add_argument("--entrada", default=os.path.join(os.path.dirname(__file__), "..", "..", "demo", "saida"))
    ap.add_argument("--saida", required=True)
    a = ap.parse_args()
    L = str(uuid.UUID(a.loja)); hoje = date.fromisoformat(a.hoje); E = a.entrada
    os.makedirs(a.saida, exist_ok=True)
    blocos = {}

    # ---------------- cadastros ----------------
    cats = {r["id"]: r["name"] for r in ler(E, "categories")}
    tamanhos = {r["id"]: r["name"] for r in ler(E, "pizza_sizes")}
    sabores = {r["id"]: r for r in ler(E, "flavors")}
    insumos = {r["id"]: r for r in ler(E, "gestao_insumos")}
    fornecedores = ler(E, "gestao_fornecedores")
    # custo de cada sabor x tamanho pela ficha técnica (insumo.custo_cents é por kg/l/un)
    custo_ficha = defaultdict(float)
    for r in ler(E, "gestao_ficha_tecnica"):
        custo_ficha[(r["sabor_id"], r["tamanho"])] += float(r["quantidade"]) * int(insumos[r["insumo_id"]]["custo_cents"]) / 100
    fator = lambda un: 10 if un in ("kg", "l") else 1                       # 100 g / 100 ml
    rotulo = lambda un: {"kg": "100 g", "l": "100 ml"}.get(un, "un")

    pcats = [{"id": uid(L, "categoria", n), "user_id": L, "name": n} for n in
             sorted(set(cats.values()) | {"Bebidas", "Bordas", "Insumos (uso interno)", "Taxas"})]
    produtos, pizza_de = [], {}
    for fp in ler(E, "flavor_prices"):
        s = sabores[fp["flavor_id"]]; t = tamanhos[fp["size_id"]]
        pid = uid(L, "pizza", fp["flavor_id"], fp["size_id"]); pizza_de[(fp["flavor_id"], t)] = pid
        # estoque = a produção de uma noite (a base não vende sem estoque); 999 inflava o "Valor em estoque" do Início
        produtos.append(dict(id=pid, user_id=L, name=f"{s['name']} ({t})", description="Pizza feita na hora (DEMO)",
                             price=reais(fp["price_cents"]), cost=round(custo_ficha[(fp["flavor_id"], t)], 2), stock=10, min_stock=0,
                             category=cats[s["category_id"]], size=t, active=True))
    produto_item = {}
    for p in ler(E, "products"):
        pid = uid(L, "produto", p["id"]); produto_item[p["name"]] = pid
        produtos.append(dict(id=pid, user_id=L, name=p["name"], description="Bebida/produto (DEMO)", price=reais(p["price_cents"]),
                             cost=round(reais(p["price_cents"]) * .45, 2), stock=48, min_stock=0, category="Bebidas", size=None, active=True))
    for ad in ler(E, "addons"):
        produtos.append(dict(id=uid(L, "borda", ad["id"]), user_id=L, name=ad["name"], description="Borda recheada (DEMO)",
                             price=reais(ad["price_cents"]), cost=round(reais(ad["price_cents"]) * .35, 2), stock=30, min_stock=0,
                             category="Bordas", size=None, active=True))
    insumo_produto = {}
    for i in insumos.values():
        pid = uid(L, "insumo", i["id"]); insumo_produto[i["id"]] = pid
        produtos.append(dict(id=pid, user_id=L, name=f"{i['nome']} ({rotulo(i['unidade'])})", description="Insumo de uso interno (DEMO)",
                             price=0.0, cost=round(int(i["custo_cents"]) / 100 / fator(i["unidade"]), 4), stock=0, min_stock=0,
                             category="Insumos (uso interno)", size=None, active=True, supplier=uid(L, "fornecedor", i["fornecedor_id"])))

    clientes = []
    ends = {r["customer_id"]: r for r in ler(E, "customer_addresses")}
    # data de cadastro = a do 1º pedido (sem pedido: 6 meses antes de hoje), e não o dia da carga
    primeiro = {}
    for o in ler(E, "orders"):
        if o["customer_id"] and (o["customer_id"] not in primeiro or o["created_at"] < primeiro[o["customer_id"]]):
            primeiro[o["customer_id"]] = o["created_at"]
    for c in ler(E, "customers"):
        e = ends.get(c["id"], {})
        clientes.append(dict(id=c["id"], user_id=L, name=c["name"], phone=telefone(c["phone_e164"]), birthday=c["birth_date"] or None,
                             street=e.get("street"), neighborhood=e.get("neighborhood"), city="Campinas", state="SP", cep=e.get("cep") or None,
                             notes="Cliente fictício (DEMO)",
                             created_at=primeiro.get(c["id"], f"{hoje - timedelta(days=182)}T12:00:00-03:00")))
    forn = [dict(id=uid(L, "fornecedor", f["id"]), user_id=L, name=f["nome"], cnpj=f["cnpj"], notes=f"Fornecedor fictício. Entrega: {f['dias_entrega']}; prazo {f['prazo_dias']} dias") for f in fornecedores]
    forn_de = {f["id"]: uid(L, "fornecedor", f["id"]) for f in fornecedores}
    for p in produtos:
        p["supplier_id"] = p.pop("supplier", None)

    # ---------------- vendas (pedidos + comandas) ----------------
    sessoes = ler(E, "gestao_caixa_sessoes")
    sessao_do_dia = {s["data_negocio"]: s["id"] for s in sessoes}
    taxa_de = {}; receber = ler(E, "gestao_contas_receber")
    for r in receber:
        taxa_de[r["origem_id"]] = r
    itens_por_pedido = defaultdict(list)
    for it in ler(E, "order_items"):
        itens_por_pedido[it["order_id"]].append(it)
    sab_por_item = defaultdict(list)
    for f in ler(E, "order_item_flavors"):
        sab_por_item[f["order_item_id"]].append(f)
    add_por_item = defaultdict(list)
    for x in ler(E, "order_item_addons"):
        add_por_item[x["order_item_id"]].append(x)
    # comanda do salão: "Pizza <tamanho> <sabor> / <sabor>" → custo pela ficha técnica (frações iguais); bebida → o produto
    sabor_por_nome = {v["name"]: k for k, v in sabores.items()}
    def custo_da_comanda(desc, preco):
        if desc in produto_item:
            return produto_item[desc], round(preco / 100 * .45, 2)
        if desc.startswith("Pizza "):
            for t in sorted(tamanhos.values(), key=len, reverse=True):
                if desc.startswith(f"Pizza {t} "):
                    nomes = desc[len(f"Pizza {t} "):].split(" / ")
                    ids = [sabor_por_nome[n] for n in nomes]
                    return (pizza_de.get((ids[0], t)) if len(ids) == 1 else None), round(sum(custo_ficha[(i, t)] for i in ids) / len(ids), 2)
        raise AssertionError(f"item de comanda sem custo conhecido: {desc}")
    METODO = {"pix": "pix", "credit": "credito_1x", "credito": "credito_1x", "debit": "debito", "debito": "debito",
              "cash": "dinheiro", "dinheiro": "dinheiro"}
    vendas, vitens, vpag = [], [], []
    brutos = []
    for o in ler(E, "orders"):
        criado = datetime.fromisoformat(o["created_at"])
        brutos.append((criado, "pedido", o))
    comandas = {c["id"]: c for c in ler(E, "gestao_comandas")}
    citens = defaultdict(list)
    for it in ler(E, "gestao_comanda_itens"):
        citens[it["comanda_id"]].append(it)
    for c in comandas.values():
        brutos.append((datetime.fromisoformat(c["fechada_em"]), "comanda", c))
    brutos.sort(key=lambda x: (x[0], x[2]["id"]))
    for n, (criado, tipo, o) in enumerate(brutos, 1):
        assert criado.date() <= hoje, f"venda no futuro: {o['id']}"
        sid = o["id"]; itens = []
        if tipo == "pedido":
            for it in itens_por_pedido[sid]:
                sab = sab_por_item[it["id"]]; tam = it["size_snapshot"]
                if it["kind"] == "pizza":
                    nomes = " / ".join(f["name_snapshot"] for f in sab)
                    bordas = " + ".join(x["name_snapshot"] for x in add_por_item[it["id"]])
                    nome = f"{it['name_snapshot']} — {nomes}" + (f" + {bordas}" if bordas else "")
                    custo = sum(float(f["fraction"]) * custo_ficha[(f["flavor_id"], tam)] for f in sab)
                    prod = pizza_de.get((sab[0]["flavor_id"], tam)) if len(sab) == 1 else None
                else:
                    nome = it["name_snapshot"]; prod = produto_item.get(nome); custo = int(it["unit_price_cents"]) / 100 * .45
                itens.append(dict(nome=nome, prod=prod, qtd=int(it["qty"]), unit=int(it["unit_price_cents"]), custo=round(custo, 2)))
            assert sum(i["unit"] * i["qtd"] for i in itens) == int(o["subtotal_cents"]), f"itens ≠ subtotal no pedido {sid}"
            if int(o["delivery_fee_cents"]):
                itens.append(dict(nome="Taxa de entrega", prod=None, qtd=1, unit=int(o["delivery_fee_cents"]), custo=0.0))
            bruto = int(o["total_cents"]); metodo = METODO[o["payment_method"]]
            status = "concluida" if o["status"] == "concluded" else "cancelada"
            canal = "online" if o["channel"] == "link" else "loja"; cliente = o["customer_id"]
            nota = {"link": "Pedido pelo link", "phone": "Pedido por telefone", "counter": "Pedido no balcão"}[o["channel"]] + \
                   (" · entrega" if o["type"] == "delivery" else " · retirada") + " (DEMO)"
            dia = o["business_date"]
        else:
            for it in citens[sid]:
                prod, custo = custo_da_comanda(it["descricao"], int(it["preco_cents"]))
                itens.append(dict(nome=it["descricao"], prod=prod, qtd=int(it["quantidade"]), unit=int(it["preco_cents"]), custo=custo))
            assert sum(i["unit"] * i["qtd"] for i in itens) == int(o["subtotal_cents"]), f"itens ≠ subtotal na comanda {sid}"
            if int(o["taxa_servico_cents"]):
                itens.append(dict(nome="Taxa de serviço (10%)", prod=None, qtd=1, unit=int(o["taxa_servico_cents"]), custo=0.0))
            bruto = int(o["total_cents"]); metodo = METODO[o["forma_pagamento"]]; status = "concluida"; canal = "loja"; cliente = None
            nota = f"Salão · mesa · {o['pessoas']} pessoa(s) (DEMO)"; dia = o["data_negocio"]
        assert sum(i["unit"] * i["qtd"] for i in itens) == bruto, f"itens ≠ total em {sid}"
        rec = taxa_de.get(sid); taxa = int(rec["taxa_cents"]) if rec and status == "concluida" else 0
        vendas.append(dict(id=sid, user_id=L, customer_id=cliente, customer_unidentified=cliente is None, payment_method=metodo,
                           gross_total=reais(bruto), discount=0.0, fee=reais(taxa), net_total=reais(bruto - taxa), status=status,
                           notes=nota, created_at=criado.isoformat(), updated_at=(criado + timedelta(minutes=50)).isoformat(),
                           idempotency_key=f"demo-{sid}", cash_register_id=sessao_do_dia.get(dia), channel=canal, sold_by=L, sale_number=n))
        for k, i in enumerate(itens):
            vitens.append(dict(id=uid(L, "item", sid, k), sale_id=sid, product_id=i["prod"], product_name=i["nome"], quantity=i["qtd"],
                               unit_price=reais(i["unit"]), subtotal=reais(i["unit"] * i["qtd"]), discount=0.0, unit_cost=i["custo"], user_id=L))
        vpag.append(dict(id=uid(L, "pagamento", sid), sale_id=sid, method=metodo, amount=reais(bruto), fee=reais(taxa), user_id=L))

    # ---------------- caixa ----------------
    caixas, cmov = [], []
    vendas_ids = {v["id"] for v in vendas}
    for s in sessoes:
        caixas.append(dict(id=s["id"], user_id=L, status="closed", opening_balance=reais(s["abertura_cents"]),
                           closing_balance=reais(s["contado_cents"]), expected_balance=reais(s["esperado_cents"]),
                           difference=reais(s["diferenca_cents"]), opened_at=s["aberto_em"], closed_at=s["fechado_em"],
                           notes=f"Operador: {s['operador']} (DEMO)", created_at=s["aberto_em"]))
        cmov.append(dict(id=uid(L, "abertura", s["id"]), user_id=L, cash_register_id=s["id"], type="abertura",
                         amount=reais(s["abertura_cents"]), description="Troco inicial", sale_id=None, created_at=s["aberto_em"]))
    for k, m in enumerate(ler(E, "gestao_caixa_movimentos")):
        venda = m["origem_id"] if m["tipo"] == "pagamento_dinheiro" and m["origem_id"] in vendas_ids else None
        cmov.append(dict(id=uid(L, "movimento", k), user_id=L, cash_register_id=m["sessao_id"],
                         type="venda" if m["tipo"] == "pagamento_dinheiro" else "sangria", amount=reais(abs(int(m["valor_cents"]))),
                         description="Venda em dinheiro" if venda else ("Sangria para o cofre" if m["tipo"] == "sangria" else "Pagamento em dinheiro"),
                         sale_id=venda, created_at=m["em"]))

    # ---------------- financeiro ----------------
    def tipo_cat(n):
        return "custo" if n in ("Insumos", "Bebidas para revenda", "Embalagens") else "despesa"
    pagar = ler(E, "gestao_contas_pagar")
    fcats = [dict(id=uid(L, "fincat", "Vendas"), user_id=L, name="Vendas", type="receita")] + \
            [dict(id=uid(L, "fincat", n), user_id=L, name=n, type=tipo_cat(n)) for n in sorted({p["categoria"] for p in pagar})]
    compras = {c["id"]: c for c in ler(E, "gestao_compras")}
    conta_da_compra = {}
    contas_pagar = []
    FIXAS = {"Aluguel", "Energia", "Água", "Internet", "Gás", "Sistema", "Contabilidade", "Seguro", "Folha", "Pró-labore", "Marketing", "Manutenção"}
    for p in pagar:
        venc = date.fromisoformat(p["vencimento"]); pago = p["status"] == "paga"
        status = "pago" if pago else ("vencido" if venc < hoje else "pendente")
        valor = reais(p["valor_cents"])
        assert not pago or date.fromisoformat(p["pago_em"]) <= hoje
        contas_pagar.append(dict(id=p["id"], user_id=L, description=p["descricao"], category_id=uid(L, "fincat", p["categoria"]),
                                 supplier_id=forn_de.get(compras[p["compra_id"]]["fornecedor_id"]) if p["compra_id"] else None,
                                 amount=valor, due_date=p["vencimento"], paid_date=p["pago_em"] if pago else None,
                                 paid_amount=valor if pago else None, payment_method="pix" if pago else None, status=status,
                                 recurrence="mensal" if p["categoria"] in FIXAS else "unica",
                                 pagamentos=[{"valor": valor, "data": p["pago_em"]}] if pago else [],
                                 notes="Conta fictícia (DEMO)", created_at=f"{p['competencia']}T09:00:00-03:00"))
        if p["compra_id"]:
            conta_da_compra[p["compra_id"]] = p["id"]
    criado_venda = {v["id"]: v["created_at"] for v in vendas}
    numero_venda = {v["id"]: v["sale_number"] for v in vendas}
    contas_receber = []
    for r in receber:
        if r["origem_id"] not in criado_venda:
            continue
        ok = r["status"] == "recebida"; liquido = reais(r["valor_liquido_cents"])
        assert not ok or date.fromisoformat(r["recebido_em"]) <= hoje
        contas_receber.append(dict(id=r["id"], user_id=L, description=f"Cartão de {r['forma']} — venda nº {numero_venda[r['origem_id']]}",
                                   category_id=uid(L, "fincat", "Vendas"), sale_id=r["origem_id"], amount=liquido, due_date=r["previsto_para"],
                                   received_date=r["recebido_em"] if ok else None, received_amount=liquido if ok else None,
                                   payment_method="credito_1x" if r["forma"] == "credito" else "debito", status="recebido" if ok else "pendente",
                                   notes=f"Bruto R$ {reais(r['valor_bruto_cents']):.2f} · taxa R$ {reais(r['taxa_cents']):.2f} (DEMO)",
                                   created_at=criado_venda[r["origem_id"]]))
    # taxas reais da maquininha (média ponderada dos dados)
    soma = defaultdict(lambda: [0, 0])
    for r in receber:
        soma[r["forma"]][0] += int(r["taxa_cents"]); soma[r["forma"]][1] += int(r["valor_bruto_cents"])
    taxa_pct = {k: round(100 * t / b, 2) for k, (t, b) in soma.items()}
    maquinas = [dict(id=uid(L, "maquininha"), user_id=L, name="Maquininha (DEMO)", debit_fee=taxa_pct.get("debito", 0),
                     credit_fee=taxa_pct.get("credito", 0), active=True, is_default=True)]

    # ---------------- compras e estoque ----------------
    compras_l, citens_l = [], []
    for c in compras.values():
        assert c["id"] in conta_da_compra, f"compra sem conta a pagar: {c['id']}"
        compras_l.append(dict(id=c["id"], user_id=L, supplier_id=forn_de[c["fornecedor_id"]], invoice_number=c["nota_numero"],
                              purchase_date=c["data"], total_amount=reais(c["total_cents"]), freight=0.0, payment_condition="a_prazo",
                              notes="Compra fictícia (DEMO)", accounts_payable_id=conta_da_compra[c["id"]], idempotency_key=f"demo-{c['id']}",
                              created_at=f"{c['data']}T10:00:00-03:00"))
    for k, it in enumerate(ler(E, "gestao_compra_itens")):
        ins = insumos[it["insumo_id"]]; qtd = round(float(it["quantidade"]) * fator(ins["unidade"]))
        assert qtd > 0
        citens_l.append(dict(id=uid(L, "compra_item", k), purchase_id=it["compra_id"], product_id=insumo_produto[it["insumo_id"]], quantity=qtd,
                             unit_cost=round(int(it["total_cents"]) / 100 / qtd, 4), subtotal=reais(it["total_cents"]), user_id=L))
    estoque, saldo = [], defaultdict(int)
    TIPO = {"saldo_inicial": ("entrada", "Saldo inicial"), "entrada_compra": ("entrada", "Entrada de compra"),
            "saida_venda": ("saida", "Consumo da cozinha (ficha técnica)"), "ajuste_inventario": ("ajuste_negativo", "Inventário do mês (perda)")}
    for k, m in enumerate(ler(E, "gestao_estoque_movimentos")):
        ins = insumos[m["insumo_id"]]; qtd = round(abs(float(m["quantidade"])) * fator(ins["unidade"]))
        if qtd == 0:
            continue
        tipo, motivo = TIPO[m["tipo"]]
        saldo[m["insumo_id"]] += qtd if tipo == "entrada" else -qtd
        estoque.append(dict(id=uid(L, "estoque", k), user_id=L, product_id=insumo_produto[m["insumo_id"]], type=tipo, quantity=qtd,
                            reason=motivo, notes="DEMO", created_at=f"{m['data']}T23:30:00-03:00"))
    for p in produtos:
        for iid, pid in insumo_produto.items():
            if p["id"] == pid:
                p["stock"] = max(0, saldo[iid])
    banco = ler(E, "gestao_extrato_bancario")
    saldo_banco = reais(banco[-1]["saldo_cents"]) if banco else 0

    # ---------------- arquivos ----------------
    C = lambda *c: list(c)
    # planos da Pizzalia (docs/PLANO-DE-NEGOCIO.md §4, aprovados pelo dono): nascem DESLIGADOS (active = false), como no modelo da
    # base (docs/auditoria/saas06-planos-lucra.sql); anual = 10 mensalidades. Módulos da base em cada plano:
    #   Essencial = básico + loja online (cardápio digital e link em todos) · Profissional = + clube (cupons e fidelidade)
    #   Premium = + financeiro completo + metas e relatórios
    blocos["00_planos_e_loja"] = f"""
INSERT INTO public.subscription_plans (code, name, price_cents, interval_months, active)
SELECT v.code, v.name, v.price_cents, v.interval_months, false
  FROM (VALUES ('pizzalia-essencial-mensal', 'Essencial (mensal)', 14900, 1), ('pizzalia-essencial-anual', 'Essencial (anual)', 149000, 12),
               ('pizzalia-profissional-mensal', 'Profissional (mensal)', 29900, 1), ('pizzalia-profissional-anual', 'Profissional (anual)', 299000, 12),
               ('pizzalia-premium-mensal', 'Premium (mensal)', 54900, 1), ('pizzalia-premium-anual', 'Premium (anual)', 549000, 12))
       AS v(code, name, price_cents, interval_months)
 WHERE NOT EXISTS (SELECT 1 FROM public.subscription_plans p WHERE p.code = v.code);
INSERT INTO public.plan_modules (plan_id, module_codigo)
SELECT p.id, m.codigo FROM public.subscription_plans p
  JOIN (VALUES ('essencial', 'base'), ('essencial', 'loja_online'),
               ('profissional', 'base'), ('profissional', 'loja_online'), ('profissional', 'clube'),
               ('premium', 'base'), ('premium', 'loja_online'), ('premium', 'clube'), ('premium', 'financeiro'), ('premium', 'metas_e_relatorios'))
       AS m(plano, codigo) ON p.code IN ('pizzalia-' || m.plano || '-mensal', 'pizzalia-' || m.plano || '-anual')
ON CONFLICT DO NOTHING;

-- a loja demo, pelos MESMOS passos do cadastro da base (cadastro_confirmar): o login já existe (id = loja); o perfil de
-- administradora cria a loja e o vínculo de Dona(o) (gatilho trg_user_profiles_loja_da_dona); depois o nome, a marca e a assinatura.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = {q(L)}) THEN RAISE EXCEPTION 'login de teste ausente: crie antes o usuário {L}'; END IF;
END $$;
INSERT INTO public.user_profiles (user_id, role, force_password_change, display_name)
SELECT {q(L)}, 'admin', false, 'Dono (DEMO)' WHERE NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = {q(L)});
UPDATE public.stores SET nome = 'Pizzaria Forno da Vila (DEMO)', status = 'ativa' WHERE id = {q(L)};
INSERT INTO public.store_settings (user_id, store_name, nome_de_exibicao, cor_da_marca, tratamento_da_clientela, email, phone, whatsapp,
                                   city, state, neighborhood, street, street_number, receipt_message)
SELECT {q(L)}, 'Pizzaria Forno da Vila (DEMO)', 'Forno da Vila (DEMO)', '#B91C1C', 'neutro', 'contato@forno-da-vila.invalid',
       '(19) 90000-0000', '(19) 90000-0000', 'Campinas', 'SP', 'Centro', 'Rua Demonstração', '100', 'Obrigado pela preferência! (DEMO)'
 WHERE NOT EXISTS (SELECT 1 FROM public.store_settings WHERE user_id = {q(L)});
INSERT INTO public.subscriptions (store_owner_id, plan_id, current_period_start, current_period_end)
SELECT {q(L)}, p.id, {q(hoje.isoformat())}, '2027-12-31' FROM public.subscription_plans p
 WHERE p.code = 'pizzalia-premium-mensal' AND NOT EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.store_owner_id = {q(L)});
"""
    blocos["10_cadastros"] = "\n".join([
        inserts("product_categories", C("id", "user_id", "name"), pcats),
        inserts("suppliers", C("id", "user_id", "name", "cnpj", "notes"), forn),
        inserts("products", C("id", "user_id", "name", "description", "price", "cost", "stock", "min_stock", "category", "size", "active", "supplier_id"), produtos),
        inserts("customers", C("id", "user_id", "name", "phone", "birthday", "street", "neighborhood", "city", "state", "cep", "notes", "created_at"), clientes),
        inserts("financial_categories", C("id", "user_id", "name", "type"), fcats),
        inserts("card_machines", C("id", "user_id", "name", "debit_fee", "credit_fee", "active", "is_default"), maquinas),
        f"UPDATE public.store_settings SET bank_balance = {saldo_banco} WHERE user_id = {q(L)} AND bank_balance = 0;",
    ])
    blocos["20_caixa"] = inserts("cash_registers", C("id", "user_id", "status", "opening_balance", "closing_balance", "expected_balance", "difference", "opened_at", "closed_at", "notes", "created_at"), caixas)
    blocos["30_vendas"] = inserts("sales", C("id", "user_id", "customer_id", "customer_unidentified", "payment_method", "gross_total", "discount", "fee", "net_total", "status", "notes", "created_at", "updated_at", "idempotency_key", "cash_register_id", "channel", "sold_by", "sale_number"), vendas)
    blocos["31_itens"] = inserts("sale_items", C("id", "sale_id", "product_id", "product_name", "quantity", "unit_price", "subtotal", "discount", "unit_cost", "user_id"), vitens)
    blocos["32_pagamentos"] = inserts("sale_payments", C("id", "sale_id", "method", "amount", "fee", "user_id"), vpag) + \
        f"\nINSERT INTO public.document_counters (user_id, doc_type, last_number) VALUES ({q(L)}, 'sale', {len(vendas)})\n" \
        "ON CONFLICT (user_id, doc_type) DO UPDATE SET last_number = GREATEST(public.document_counters.last_number, EXCLUDED.last_number);"
    blocos["33_caixa_movimentos"] = inserts("cash_movements", C("id", "user_id", "cash_register_id", "type", "amount", "description", "sale_id", "created_at"), cmov)
    blocos["40_contas"] = "\n".join([
        inserts("accounts_payable", C("id", "user_id", "description", "category_id", "supplier_id", "amount", "due_date", "paid_date", "paid_amount", "payment_method", "status", "recurrence", "pagamentos", "notes", "created_at"), contas_pagar),
        inserts("accounts_receivable", C("id", "user_id", "description", "category_id", "sale_id", "amount", "due_date", "received_date", "received_amount", "payment_method", "status", "notes", "created_at"), contas_receber),
    ])
    blocos["50_compras"] = "\n".join([
        inserts("purchases", C("id", "user_id", "supplier_id", "invoice_number", "purchase_date", "total_amount", "freight", "payment_condition", "notes", "accounts_payable_id", "idempotency_key", "created_at"), compras_l),
        inserts("purchase_items", C("id", "purchase_id", "product_id", "quantity", "unit_cost", "subtotal", "user_id"), citens_l),
    ])
    blocos["51_estoque"] = inserts("stock_movements", C("id", "user_id", "product_id", "type", "quantity", "reason", "notes", "created_at"), estoque)

    # ---------------- clube, metas, cupons e despesas fixas (as telas que ficavam vazias) ----------------
    # clube: 1 ponto por real, como a rotina de venda da base (FLOOR(base x points_per_brl)); validade de 365 dias
    pontos = [dict(id=uid(L, "pontos", v["id"]), user_id=L, customer_id=v["customer_id"], sale_id=v["id"], type="ganho",
                   points=int(v["gross_total"]), created_at=v["created_at"],
                   expires_at=(datetime.fromisoformat(v["created_at"]) + timedelta(days=365)).isoformat())
              for v in vendas if v["status"] == "concluida" and v["customer_id"] and int(v["gross_total"]) > 0]
    premios = [dict(id=uid(L, "premio", n), user_id=L, title=t, description=d, points_cost=c, voucher_valid_days=30, active=True, sort_order=n)
               for n, (t, d, c) in enumerate([("Borda recheada grátis", "Uma borda recheada em qualquer pizza grande ou família.", 200),
                                              ("Refrigerante 2 L grátis", "Um refrigerante de 2 litros no próximo pedido.", 300),
                                              ("Pizza broto grátis", "Uma pizza broto de qualquer sabor salgado.", 600)])]
    # metas: faturamento de cada mês (10% acima do mês anterior, arredondado) e ticket médio do mês atual
    por_mes = defaultdict(float)
    for v in vendas:
        if v["status"] == "concluida":
            por_mes[v["created_at"][:7]] += v["gross_total"]
    meses = sorted(por_mes)
    metas = []
    for i, m in enumerate(meses):
        base_m = por_mes[meses[i - 1]] if i else por_mes[m]
        metas.append(dict(id=uid(L, "meta", m), user_id=L, name=f"Faturamento de {m[5:]}/{m[:4]}", type="faturamento",
                          target_value=float(round(base_m * 1.1, -3)), month=int(m[5:]), year=int(m[:4]), active=True))
    metas.append(dict(id=uid(L, "meta", "ticket", meses[-1]), user_id=L, name="Ticket médio do mês", type="ticket_medio",
                      target_value=105.0, month=int(meses[-1][5:]), year=int(meses[-1][:4]), active=True))
    cupons = [dict(id=uid(L, "cupom", c), user_id=L, name=n, type="percent", value=v, applies_to="all", min_purchase=mn, coupon_code=c,
                   start_date=(hoje - timedelta(days=30)).isoformat(), end_date=(hoje + timedelta(days=60)).isoformat(), active=True, max_uses=None)
              for n, v, mn, c in [("Boas-vindas: 10% no 1º pedido", 10.0, 60.0, "BEMVINDO10"), ("Família: 15% acima de R$ 120", 15.0, 120.0, "FAMILIA15")]]
    # despesas fixas: as contas mensais (o valor e o dia de vencimento do último mês de cada uma)
    ultima = {}
    for p in pagar:
        if p["categoria"] in FIXAS and (p["categoria"] not in ultima or p["vencimento"] > ultima[p["categoria"]]["vencimento"]):
            ultima[p["categoria"]] = p
    fixas = [dict(id=uid(L, "fixa", c), user_id=L, description=c, category_id=uid(L, "fincat", c), amount=reais(p["valor_cents"]),
                  due_day=int(p["vencimento"][8:]), active=True, start_date=min(x["vencimento"] for x in pagar if x["categoria"] == c),
                  notes="Despesa fixa fictícia (DEMO)") for c, p in sorted(ultima.items())]
    # cardápio de pizza (módulo M02 da Pizzalia: tabelas cardapio_*, migration 20261124010000); só entra se as tabelas existirem
    cat_rows = ler(E, "categories")
    ccats = [dict(id=c["id"], user_id=L, nome=c["name"], ordem=int(c["sort_order"]), ativo=c["active"] == "True") for c in cat_rows]
    ctams = [dict(id=t["id"], user_id=L, nome=t["name"], fatias=int(t["slices"]), max_sabores=int(t["max_flavors"]), ordem=int(t["sort_order"]))
             for t in ler(E, "pizza_sizes")]
    csabs = [dict(id=sid, user_id=L, categoria_id=v["category_id"], nome=v["name"], ordem=k, ativo=v["active"] == "True")
             for k, (sid, v) in enumerate(sabores.items())]
    cprecos = [dict(id=uid(L, "cardapio_preco", fp["flavor_id"], fp["size_id"]), user_id=L, sabor_id=fp["flavor_id"], tamanho_id=fp["size_id"],
                    preco=reais(fp["price_cents"])) for fp in ler(E, "flavor_prices")]
    cgrupos = [dict(id=g["id"], user_id=L, nome=g["name"], tipo="borda" if "orda" in g["name"] else "adicional",
                    min_escolhas=int(g["min_choices"]), max_escolhas=int(g["max_choices"])) for g in ler(E, "addon_groups")]
    cadds = [dict(id=x["id"], user_id=L, grupo_id=x["group_id"], nome=x["name"], preco=reais(x["price_cents"]), ordem=k)
             for k, x in enumerate(ler(E, "addons"))]
    citens_c = [dict(id=x["id"], user_id=L, categoria_id=x["category_id"], nome=x["name"], preco=reais(x["price_cents"]), ordem=k, ativo=x["active"] == "True")
                for k, x in enumerate(ler(E, "products"))]
    corpo = "\n".join([
        inserts("cardapio_categorias", C("id", "user_id", "nome", "ordem", "ativo"), ccats),
        inserts("cardapio_tamanhos", C("id", "user_id", "nome", "fatias", "max_sabores", "ordem"), ctams),
        inserts("cardapio_sabores", C("id", "user_id", "categoria_id", "nome", "ordem", "ativo"), csabs),
        inserts("cardapio_sabor_precos", C("id", "user_id", "sabor_id", "tamanho_id", "preco"), cprecos),
        inserts("cardapio_grupos_adicionais", C("id", "user_id", "nome", "tipo", "min_escolhas", "max_escolhas"), cgrupos),
        inserts("cardapio_adicionais", C("id", "user_id", "grupo_id", "nome", "preco", "ordem"), cadds),
        inserts("cardapio_itens", C("id", "user_id", "categoria_id", "nome", "preco", "ordem", "ativo"), citens_c),
    ])
    blocos["70_cardapio"] = f"DO $cardapio$ BEGIN IF to_regclass('public.cardapio_sabores') IS NULL THEN RAISE NOTICE 'cardápio (M02) ainda não instalado: pulado'; RETURN; END IF;\nEXECUTE {q(corpo)};\nEND $cardapio$;"
    # link de pedidos (módulo M03 da Pizzalia: pedido_link_*, migration 20261125010000); só entra se as tabelas existirem
    tenant = ler(E, "tenants")[0]
    bairros = [dict(id=z["id"], user_id=L, nome=z["neighborhood"], taxa_centavos=int(z["fee_cents"]), minutos_extra=int(z["extra_minutes"]))
               for z in ler(E, "delivery_zones")]
    corpo_link = "\n".join([
        f"""INSERT INTO public.pedido_link_config (user_id, slug, ativo, pedido_minimo_centavos, tempo_preparo_min)
VALUES ({q(L)}, {q(tenant["slug"])}, true, 3000, 40) ON CONFLICT (user_id) DO NOTHING;""",
        inserts("pedido_link_bairros", C("id", "user_id", "nome", "taxa_centavos", "minutos_extra"), bairros),
    ])
    blocos["80_pedido_link"] = f"DO $link$ BEGIN IF to_regclass('public.pedido_link_config') IS NULL THEN RAISE NOTICE 'link de pedidos (M03) ainda não instalado: pulado'; RETURN; END IF;\nEXECUTE {q(corpo_link)};\nEND $link$;"
    # CRM (módulo M07 da Pizzalia: crm_*, migration 20261126010000): as autorizações de marketing dos clientes demo (LGPD), como a prova
    # do gabarito (docs/auditoria/provas/prova-crm-gabarito.sh do pizzalia); o link das mensagens vem do link de pedidos (M03)
    ORIGEM = {"counter": "balcao", "phone": "telefone", "link": "link", "whatsapp": "whatsapp"}
    consent = [dict(id=uid(L, "consentimento", k), user_id=L, customer_id=m["customer_id"], canal=m["channel"],
                    situacao="concedido" if m["status"] == "granted" else "revogado", origem=ORIGEM.get(m["source"], "importacao"),
                    versao_texto=m["text_version"], registrado_em=m["recorded_at"]) for k, m in enumerate(ler(E, "marketing_consents"))]
    corpo_crm = inserts("crm_consentimentos", C("id", "user_id", "customer_id", "canal", "situacao", "origem", "versao_texto", "registrado_em"), consent)
    blocos["90_crm"] = f"DO $crm$ BEGIN IF to_regclass('public.crm_consentimentos') IS NULL THEN RAISE NOTICE 'CRM (M07) ainda não instalado: pulado'; RETURN; END IF;\nEXECUTE {q(corpo_crm)};\nEND $crm$;"
    blocos["60_extras"] = "\n".join([
        f"""INSERT INTO public.loyalty_config (user_id, points_per_brl, brl_per_point, active, validity_days, birthday_bonus_points)
SELECT {q(L)}, 1, 0.05, true, 365, 50 WHERE NOT EXISTS (SELECT 1 FROM public.loyalty_config WHERE user_id = {q(L)});""",
        inserts("loyalty_transactions", C("id", "user_id", "customer_id", "sale_id", "type", "points", "created_at", "expires_at"), pontos),
        inserts("loyalty_rewards", C("id", "user_id", "title", "description", "points_cost", "voucher_valid_days", "active", "sort_order"), premios),
        inserts("goals", C("id", "user_id", "name", "type", "target_value", "month", "year", "active"), metas),
        inserts("promotions", C("id", "user_id", "name", "type", "value", "applies_to", "min_purchase", "coupon_code", "start_date", "end_date", "active", "max_uses"), cupons),
        inserts("fixed_expenses", C("id", "user_id", "description", "category_id", "amount", "due_day", "active", "start_date", "notes"), fixas),
    ])
    for nome, sql in blocos.items():
        with open(os.path.join(a.saida, nome + ".sql"), "w", encoding="utf-8") as f:
            f.write(f"-- Pizzalia · carga DEMO na base ({nome}) · loja {L} · gerado por db/seed/montar_carga_base.py\n{sql}\n")
    resumo = dict(produtos=len(produtos), clientes=len(clientes), fornecedores=len(forn), vendas=len(vendas),
                  vendas_concluidas=sum(v["status"] == "concluida" for v in vendas), itens=len(vitens), caixas=len(caixas),
                  movimentos_caixa=len(cmov), contas_pagar=len(contas_pagar), contas_receber=len(contas_receber), compras=len(compras_l),
                  itens_compra=len(citens_l), movimentos_estoque=len(estoque),
                  receita_concluida=round(sum(v["gross_total"] for v in vendas if v["status"] == "concluida"), 2),
                  pontos=len(pontos), metas=len(metas), cupons=len(cupons), despesas_fixas=len(fixas),
                  cardapio_sabores=len(csabs), cardapio_precos=len(cprecos), cardapio_itens=len(citens_c))
    with open(os.path.join(a.saida, "resumo.json"), "w", encoding="utf-8") as f:
        json.dump(resumo, f, ensure_ascii=False, indent=1)
    print(json.dumps(resumo, ensure_ascii=False))


if __name__ == "__main__":
    main()
