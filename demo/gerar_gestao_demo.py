#!/usr/bin/env python3
"""Gestão da pizzaria DEMO (Forno da Vila) sobre os MESMOS pedidos de gerar_dados_demo.py.

Gera: fornecedores, insumos, ficha técnica, compras, estoque (entradas, saídas, inventário), caixa (aberturas,
pagamentos em dinheiro, sangrias, fechamentos), contas a pagar e a receber (com taxas de cartão), extrato
bancário (com 2 lançamentos para conciliar), entregadores e entregas, mesas e comandas do salão, notas fiscais
de EXEMPLO (nada emitido) e a DRE mensal. Gabarito: demo/gabarito_gestao_<hoje>.txt (--verificar compara).

Uso: python demo/gerar_gestao_demo.py --hoje 2026-11-08 [--verificar]
Travas (docs/PILOTO-DEMO.md): is_demo, tenant próprio, telefones fictícios, nenhum MOVIMENTO no futuro
(vencimentos futuros de contas em aberto são permitidos: não são movimento), estoque nunca negativo,
caixa sempre contado, saldo bancário = saldo inicial + lançamentos.
"""
import argparse, contextlib, csv, io, math, os, random, sys
from collections import defaultdict
from datetime import date, datetime, time, timedelta

sys.stdout.reconfigure(errors="backslashreplace")
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import gerar_dados_demo as base  # noqa: E402

uid, TZ, brl = base.uid, base.TZ, base.brl

FORNECEDORES = {  # chave: (nome, dias da semana de entrega 0=seg, prazo de pagamento em dias)
    "laticinios": ("Laticínios Serra Azul (DEMO)", [0, 3], 14), "frios": ("Frios Bom Corte (DEMO)", [0, 3], 14),
    "moinho": ("Moinho Campinas (DEMO)", [0], 21), "horti": ("Hortifruti Ceasa (DEMO)", [0, 2, 4], 7),
    "bebidas": ("Distribuidora de Bebidas (DEMO)", [1], 21), "embalagens": ("Pizza Box Embalagens (DEMO)", [1], 28),
}
INSUMOS = {  # nome: (unidade, custo em centavos por unidade, fornecedor)
    "Mussarela": ("kg", 3890, "laticinios"), "Catupiry": ("kg", 4290, "laticinios"), "Cheddar": ("kg", 3990, "laticinios"),
    "Provolone": ("kg", 5990, "laticinios"), "Parmesão": ("kg", 6990, "laticinios"), "Gorgonzola": ("kg", 6490, "laticinios"),
    "Creme de leite": ("kg", 1890, "laticinios"), "Calabresa": ("kg", 2890, "frios"), "Presunto": ("kg", 3190, "frios"),
    "Bacon": ("kg", 4190, "frios"), "Lombo canadense": ("kg", 4590, "frios"), "Pepperoni": ("kg", 6990, "frios"),
    "Frango desfiado": ("kg", 2490, "frios"), "Carne seca": ("kg", 6490, "frios"), "Atum": ("kg", 5990, "frios"),
    "Ovo": ("un", 75, "horti"), "Cebola": ("kg", 590, "horti"), "Tomate": ("kg", 790, "horti"), "Tomate seco": ("kg", 4990, "horti"),
    "Rúcula": ("kg", 1990, "horti"), "Manjericão": ("kg", 4990, "horti"), "Banana": ("kg", 590, "horti"),
    "Milho": ("kg", 1290, "horti"), "Azeitona": ("kg", 2590, "horti"), "Coco ralado": ("kg", 3590, "horti"),
    "Canela": ("kg", 4990, "horti"), "Goiabada": ("kg", 1590, "horti"), "Chocolate": ("kg", 4590, "horti"),
    "Farinha de trigo": ("kg", 380, "moinho"), "Fermento": ("kg", 2990, "moinho"), "Óleo": ("l", 890, "moinho"),
    "Molho de tomate": ("kg", 990, "moinho"),
    "Caixa Broto": ("un", 120, "embalagens"), "Caixa Média": ("un", 160, "embalagens"),
    "Caixa Grande": ("un", 210, "embalagens"), "Caixa Família": ("un", 290, "embalagens"),
    "Refrigerante 2L": ("un", 790, "bebidas"), "Refrigerante Lata": ("un", 320, "bebidas"),
    "Suco Natural 500ml": ("un", 450, "bebidas"), "Água 500ml": ("un", 150, "bebidas"), "Cerveja Long Neck": ("un", 520, "bebidas"),
}
RECEITA_GRANDE = {  # cobertura por sabor, para 1 pizza Grande inteira (kg ou un)
    "Mussarela": {"Mussarela": .35, "Azeitona": .02}, "Calabresa": {"Calabresa": .25, "Cebola": .08, "Azeitona": .02},
    "Calabresa com Mussarela": {"Calabresa": .2, "Mussarela": .25, "Cebola": .05},
    "Margherita": {"Mussarela": .3, "Tomate": .12, "Manjericão": .01},
    "Portuguesa": {"Mussarela": .25, "Presunto": .12, "Ovo": 2, "Cebola": .06, "Azeitona": .03},
    "Frango com Catupiry": {"Frango desfiado": .2, "Catupiry": .12, "Mussarela": .1},
    "Napolitana": {"Mussarela": .3, "Tomate": .12, "Parmesão": .03}, "Atum": {"Atum": .15, "Cebola": .08, "Mussarela": .15},
    "Baiana": {"Calabresa": .2, "Cebola": .06, "Mussarela": .15, "Ovo": 1},
    "Quatro Queijos": {"Mussarela": .18, "Provolone": .08, "Parmesão": .05, "Gorgonzola": .06},
    "Pepperoni": {"Pepperoni": .12, "Mussarela": .28}, "Lombo Canadense": {"Lombo canadense": .15, "Mussarela": .25, "Cebola": .04},
    "Carne Seca com Catupiry": {"Carne seca": .18, "Catupiry": .12, "Mussarela": .1},
    "Rúcula com Tomate Seco": {"Mussarela": .28, "Rúcula": .05, "Tomate seco": .06},
    "Bacon com Milho": {"Bacon": .12, "Milho": .1, "Mussarela": .25},
    "Strogonoff de Frango": {"Frango desfiado": .2, "Creme de leite": .12, "Mussarela": .15},
    "Chocolate": {"Chocolate": .25}, "Prestígio": {"Chocolate": .2, "Coco ralado": .08},
    "Banana com Canela": {"Banana": .25, "Canela": .005, "Mussarela": .1}, "Romeu e Julieta": {"Goiabada": .2, "Mussarela": .2},
}
MASSA = {"Farinha de trigo": .22, "Fermento": .004, "Óleo": .01}
BORDA = {"Borda Catupiry": {"Catupiry": .1}, "Borda Cheddar": {"Cheddar": .1}, "Borda Chocolate": {"Chocolate": .1}}
FATOR = {"Broto": .45, "Média": .72, "Grande": 1.0, "Família": 1.45}
DESPESAS_FIXAS = [  # (categoria, descrição, valor em centavos, dia do vencimento, variação ±)
    ("Aluguel", "Aluguel do ponto", 600000, 5, 0), ("Folha", "Salários (6 pessoas)", 1200000, 5, 0),
    ("Pró-labore", "Pró-labore do dono", 800000, 5, 0), ("Energia", "Energia elétrica", 125000, 10, .12),
    ("Água", "Água e esgoto", 32000, 12, .1), ("Internet", "Internet e telefone", 14990, 15, 0),
    ("Contabilidade", "Honorários contábeis", 60000, 10, 0), ("Sistema", "Pizzalia (plano Profissional)", 29900, 5, 0),
    ("Marketing", "Anúncios e impulsionamento", 150000, 20, .2), ("Gás", "Gás GLP (P45)", 168000, 25, .1),
    ("Folha", "FGTS e encargos", 110000, 7, 0), ("Manutenção", "Manutenção e limpeza", 150000, 15, .2),
    ("Seguro", "Seguro do estabelecimento", 30000, 10, 0),
]
TAXAS = {"debito": (149, 1), "credito": (319, 30), "vale": (550, 30)}  # (taxa em centésimos de %, prazo em dias)
SALDO_INICIAL = 1500000
FORMA = {"pix": "pix", "credit": "credito", "debit": "debito", "cash": "dinheiro"}  # pedidos guardam em inglês


def gerar(hoje, semente):
    dados = base.gerar(hoje, random.Random(semente))  # os MESMOS pedidos do CRM
    rng = random.Random(semente + 1000)
    t = base.TENANT["id"]
    out = defaultdict(list)
    for k, (nome, dias, prazo) in FORNECEDORES.items():
        out["fornecedores"].append(dict(id=uid("fornecedor", k), tenant_id=t, nome=nome, cnpj="00.000.000/0001-" + f"{len(out['fornecedores']):02d}",
                                        dias_entrega="/".join(map(str, dias)), prazo_dias=prazo, is_demo=True))
    for n, (un, custo, f) in INSUMOS.items():
        out["insumos"].append(dict(id=uid("insumo", n), tenant_id=t, nome=n, unidade=un, custo_cents=custo,
                                   fornecedor_id=uid("fornecedor", f), is_demo=True))
    # ficha técnica por sabor × tamanho (+ massa, molho, caixa) e por borda × tamanho
    def ficha_sabor(sabor, tam):
        doce = base.FLAVORS[sabor][0] == "Doces"
        r = {k: v * FATOR[tam] for k, v in {**RECEITA_GRANDE[sabor], **MASSA}.items()}
        if not doce:
            r["Molho de tomate"] = .12 * FATOR[tam]
        return r
    for s in base.FLAVORS:
        for tam in FATOR:
            for ins, q in ficha_sabor(s, tam).items():
                out["ficha_tecnica"].append(dict(tenant_id=t, sabor_id=uid("flavor", s), tamanho=tam, insumo_id=uid("insumo", ins), quantidade=round(q, 4)))
    custo = {n: v[1] for n, v in INSUMOS.items()}

    # consumo teórico por dia (pedidos concluídos + salão) e CMV por pedido
    consumo = defaultdict(lambda: defaultdict(float))
    cmv_dia = defaultdict(int)
    itens_por_pedido = defaultdict(list)
    for i in dados["order_items"]:
        itens_por_pedido[i["order_id"]].append(i)
    sabores_item = defaultdict(list)
    for f in dados["order_item_flavors"]:
        sabores_item[f["order_item_id"]].append(f)
    bordas_item = {a["order_item_id"]: a["name_snapshot"] for a in dados["order_item_addons"]}

    def consumir(d, itens):
        uso = defaultdict(float)
        for it in itens:
            if it["kind"] == "pizza":
                tam = it["size_snapshot"]
                for f in sabores_item[it["id"]]:
                    for ins, q in ficha_sabor(f["name_snapshot"], tam).items():
                        uso[ins] += q * f["fraction"] * it["qty"]
                uso["Caixa " + tam] += it["qty"]
                if it["id"] in bordas_item:
                    for ins, q in BORDA[bordas_item[it["id"]]].items():
                        uso[ins] += q * FATOR[tam] * it["qty"]
            else:
                uso[it["name_snapshot"]] += it["qty"]
        valor = 0
        for ins, q in uso.items():
            consumo[d][ins] += q
            valor += q * custo[ins]
        cmv_dia[d] += round(valor)
        return round(valor)

    receita = defaultdict(lambda: defaultdict(int))  # mês → linha → centavos
    pedidos_ok = [o for o in dados["orders"] if o["status"] == "concluded"]
    for o in pedidos_ok:
        d = date.fromisoformat(o["business_date"])
        consumir(d, itens_por_pedido[o["id"]])
        receita[d.strftime("%Y-%m")]["Vendas delivery e retirada"] += o["subtotal_cents"]
        receita[d.strftime("%Y-%m")]["Taxas de entrega"] += o["delivery_fee_cents"]

    # salão: 10 mesas, comandas de sexta a domingo
    for m in range(1, 11):
        out["mesas"].append(dict(id=uid("mesa", m), tenant_id=t, nome=f"Mesa {m}", lugares=[2, 4, 4, 6][m % 4], is_demo=True))
    preco = {(f["flavor_id"], f["size_id"]): f["price_cents"] for f in dados["flavor_prices"]}
    nomes = list(base.FLAVORS)
    inicio = min(date.fromisoformat(o["business_date"]) for o in dados["orders"])
    pagamentos = []  # (data, forma, valor, origem_id, hora)
    for o in pedidos_ok:
        h = datetime.fromisoformat(o["created_at"])
        pagamentos.append((date.fromisoformat(o["business_date"]), FORMA[o["payment_method"]], o["total_cents"], o["id"], h))
    d = inicio
    nc = 0
    while d < hoje:
        if d.weekday() in (4, 5, 6):
            for _ in range(rng.randint(3, 8)):
                nc += 1
                mesa = rng.randint(1, 10)
                ab = datetime.combine(d, time(rng.randint(19, 22), rng.randint(0, 59)), TZ)
                cid = uid("comanda", nc)
                itens, sub = [], 0
                for k in range(rng.randint(1, 3)):
                    tam = rng.choice(["Grande", "Família"])
                    fl = list(dict.fromkeys(rng.choice(nomes) for _ in range(rng.randint(1, 2))))
                    p = max(preco[(uid("flavor", f), uid("size", tam))] for f in fl)
                    iid = uid("comanda_item", nc, k)
                    itens.append(dict(id=iid, kind="pizza", size_snapshot=tam, qty=1, name_snapshot="Pizza " + tam))
                    for f in fl:
                        sabores_item[iid].append(dict(name_snapshot=f, fraction=round(1 / len(fl), 2)))
                    out["comanda_itens"].append(dict(comanda_id=cid, descricao=f"Pizza {tam} " + " / ".join(fl), quantidade=1, preco_cents=p))
                    sub += p
                for _ in range(rng.randint(1, 4)):
                    pn, _, pp = rng.choice(base.PRODUCTS)
                    itens.append(dict(id="", kind="product", name_snapshot=pn, qty=1, size_snapshot=""))
                    out["comanda_itens"].append(dict(comanda_id=cid, descricao=pn, quantidade=1, preco_cents=pp))
                    sub += pp
                servico = round(sub * .10)
                consumir(d, itens)
                forma = FORMA[base.wchoice(rng, base.PAY)]
                out["comandas"].append(dict(id=cid, tenant_id=t, mesa_id=uid("mesa", mesa), pessoas=rng.randint(1, 6),
                                            aberta_em=ab.isoformat(), fechada_em=(ab + timedelta(minutes=rng.randint(50, 110))).isoformat(),
                                            subtotal_cents=sub, taxa_servico_cents=servico, total_cents=sub + servico,
                                            forma_pagamento=forma, data_negocio=d.isoformat(), is_demo=True))
                receita[d.strftime("%Y-%m")]["Vendas no salão"] += sub
                receita[d.strftime("%Y-%m")]["Taxa de serviço (repassada à equipe)"] += servico
                pagamentos.append((d, forma, sub + servico, cid, ab + timedelta(minutes=60)))
        d += timedelta(days=1)

    # estoque: compras nos dias de entrega de cada fornecedor, saídas diárias, inventário no fim do mês
    media = {n: sum(consumo[x][n] for x in consumo) / max(1, len(consumo)) for n in INSUMOS}
    saldo = {n: media[n] * 10 for n in INSUMOS}
    for n in INSUMOS:
        out["estoque_movimentos"].append(dict(tenant_id=t, data=inicio.isoformat(), insumo_id=uid("insumo", n), tipo="saldo_inicial",
                                              quantidade=round(saldo[n], 3), custo_cents=round(saldo[n] * custo[n])))
    contas_pagar, ncompra = [], 0
    d = inicio
    while d < hoje:
        meses = (d.year - inicio.year) * 12 + d.month - inicio.month
        for fk, (fnome, dias, prazo) in FORNECEDORES.items():
            if d.weekday() not in dias:
                continue
            prox = min((x - d.weekday()) % 7 or 7 for x in dias)
            itens = []
            for n, (un, c, f) in INSUMOS.items():
                if f != fk:
                    continue
                # margem para picos: a média de 6 dias a mais OU 30% acima do que a cozinha vai usar até a próxima entrega
                # (o comprador conhece o movimento da casa). Só a média deixava insumo de pouco giro (ex.: carne seca) faltar
                # num fim de semana forte, dependendo da data de hoje (achado em 13/11 com --hoje 2026-11-13).
                prox_uso = sum(consumo.get(d + timedelta(days=k), {}).get(n, 0) for k in range(prox + 1))
                alvo = max(media[n] * (prox + 6), prox_uso * 1.3)
                q = max(0.0, alvo - saldo[n])
                q = math.ceil(q) if un != "kg" else math.ceil(q * 2) / 2
                if q > 0:
                    cu = round(c * (1 + .005 * meses) * rng.uniform(.97, 1.03))
                    itens.append((n, q, cu))
            if not itens:
                continue
            ncompra += 1
            cid = uid("compra", ncompra)
            total = sum(round(q * cu) for _, q, cu in itens)
            out["compras"].append(dict(id=cid, tenant_id=t, fornecedor_id=uid("fornecedor", fk), data=d.isoformat(),
                                       nota_numero=f"DEMO-{ncompra:05d}", total_cents=total, status="recebida", is_demo=True))
            for n, q, cu in itens:
                saldo[n] += q
                out["compra_itens"].append(dict(compra_id=cid, insumo_id=uid("insumo", n), quantidade=q, custo_unit_cents=cu, total_cents=round(q * cu)))
                out["estoque_movimentos"].append(dict(tenant_id=t, data=d.isoformat(), insumo_id=uid("insumo", n), tipo="entrada_compra",
                                                      quantidade=q, custo_cents=round(q * cu)))
            cat = {"bebidas": "Bebidas para revenda", "embalagens": "Embalagens"}.get(fk, "Insumos")
            contas_pagar.append((cat, f"Compra {fnome} (DEMO-{ncompra:05d})", total, d, d + timedelta(days=prazo), cid))
        for n, q in consumo[d].items():
            saldo[n] -= q
            assert saldo[n] > -1e-6, f"estoque negativo: {n} em {d}"
            out["estoque_movimentos"].append(dict(tenant_id=t, data=d.isoformat(), insumo_id=uid("insumo", n), tipo="saida_venda",
                                                  quantidade=-round(q, 3), custo_cents=-round(q * custo[n])))
        if (d + timedelta(days=1)).day == 1:  # inventário no último dia do mês: perdas de 0 a 3% nos perecíveis
            for n, (un, c, f) in INSUMOS.items():
                if f in ("horti", "laticinios", "frios") and saldo[n] > 0:
                    perda = round(saldo[n] * rng.uniform(0, .03), 3)
                    if perda > 0:
                        saldo[n] -= perda
                        out["estoque_movimentos"].append(dict(tenant_id=t, data=d.isoformat(), insumo_id=uid("insumo", n), tipo="ajuste_inventario",
                                                              quantidade=-perda, custo_cents=-round(perda * c)))
                        receita[d.strftime("%Y-%m")]["__perdas"] += round(perda * c)
        d += timedelta(days=1)
    for n in INSUMOS:
        out["estoque_saldos"].append(dict(tenant_id=t, insumo_id=uid("insumo", n), nome=n, saldo=round(saldo[n], 3),
                                          estoque_minimo=round(media[n] * 3, 3), abaixo_do_minimo=saldo[n] < media[n] * 3))

    # entregadores: 3 motoboys, R$ 6 por entrega + R$ 40 por noite trabalhada, acerto toda segunda
    for m in range(1, 4):
        out["entregadores"].append(dict(id=uid("entregador", m), tenant_id=t, nome=f"Motoboy {m} (DEMO)", telefone=f"+551990009{m:04d}",
                                        taxa_por_entrega_cents=600, diaria_cents=4000, is_demo=True))
    noites = defaultdict(set)
    acerto = defaultdict(int)
    for o in pedidos_ok:
        if o["type"] != "delivery":
            continue
        m = rng.randint(1, 3)
        saiu = datetime.fromisoformat(o["created_at"]) + timedelta(minutes=rng.randint(25, 45))
        out["entregas"].append(dict(pedido_id=o["id"], entregador_id=uid("entregador", m), saiu_em=saiu.isoformat(),
                                    entregue_em=(saiu + timedelta(minutes=rng.randint(8, 30))).isoformat(), taxa_entregador_cents=600))
        dn = date.fromisoformat(o["business_date"])
        noites[m].add(dn)
        semana = dn - timedelta(days=dn.weekday())
        acerto[(m, semana)] += 600
    for m, dias_ in noites.items():
        for dn in dias_:
            acerto[(m, dn - timedelta(days=dn.weekday()))] += 4000
    for (m, semana), v in sorted(acerto.items()):
        venc = semana + timedelta(days=7)
        contas_pagar.append(("Entregadores", f"Acerto semanal Motoboy {m} ({semana.strftime('%d/%m')})", v, semana + timedelta(days=6), venc, None))

    # despesas fixas do mês e DAS (Simples Nacional, 7% da receita do mês, vence dia 20 do mês seguinte)
    mes = date(inicio.year, inicio.month, 1)
    while mes <= hoje:
        prox_mes = (mes + timedelta(days=32)).replace(day=1)
        dias_mes = (prox_mes - mes).days                     # 1º mês: proporcional aos dias de operação
        fator = (dias_mes - (inicio - mes).days) / dias_mes if mes.year == inicio.year and mes.month == inicio.month else 1
        for cat, desc, v, dia, var in DESPESAS_FIXAS:
            valor = round(v * fator * (1 + rng.uniform(-var, var)))
            venc = (prox_mes if cat in ("Folha", "Pró-labore") else mes).replace(day=dia)
            contas_pagar.append((cat, f"{desc} ({mes.strftime('%m/%Y')})", valor, mes, venc, None))
        bruto = sum(v for k, v in receita[mes.strftime("%Y-%m")].items() if not k.startswith("__") and "serviço" not in k)
        servico = receita[mes.strftime("%Y-%m")]["Taxa de serviço (repassada à equipe)"]
        if servico:
            contas_pagar.append(("Repasse taxa de serviço", f"Taxa de serviço para a equipe ({mes.strftime('%m/%Y')})", servico, mes, prox_mes.replace(day=5), None))
        if mes < hoje.replace(day=1):
            contas_pagar.append(("Impostos (DAS)", f"DAS Simples Nacional ({mes.strftime('%m/%Y')})", round(bruto * .07), mes, prox_mes.replace(day=20), None))
        mes = prox_mes

    banco = []  # (data, descrição, valor ±, referência)
    for i, (cat, desc, v, comp, venc, ref) in enumerate(sorted(contas_pagar, key=lambda x: (x[4], x[1]))):
        pago = venc < hoje
        pid = uid("pagar", i)
        out["contas_pagar"].append(dict(id=pid, tenant_id=t, categoria=cat, descricao=desc, valor_cents=v, competencia=comp.isoformat(),
                                        vencimento=venc.isoformat(), status="paga" if pago else "aberta",
                                        pago_em=venc.isoformat() if pago else "", compra_id=ref or "", is_demo=True))
        if pago:
            banco.append((venc, f"Pagamento: {desc}", -v, pid))

    # contas a receber (cartão e vale), PIX e dinheiro; caixa diário com sangrias
    caixa_dia = defaultdict(list)
    for (d, forma, v, ref, quando) in sorted(pagamentos, key=lambda x: x[4]):
        if forma in TAXAS:
            taxa_pc, prazo = TAXAS[forma]
            taxa = round(v * taxa_pc / 10000)
            prev = d + timedelta(days=prazo)
            receb = prev < hoje
            rid = uid("receber", ref)
            out["contas_receber"].append(dict(id=rid, tenant_id=t, origem_id=ref, forma=forma, valor_bruto_cents=v, taxa_cents=taxa,
                                              valor_liquido_cents=v - taxa, previsto_para=prev.isoformat(),
                                              recebido_em=prev.isoformat() if receb else "", status="recebida" if receb else "a_receber"))
            receita[d.strftime("%Y-%m")]["__taxas_cartao"] += taxa
            if receb:
                banco.append((prev, f"Repasse maquininha ({forma})", v - taxa, rid))
        elif forma == "pix":
            banco.append((d, "PIX recebido (pedido)", v, ref))
        else:
            caixa_dia[d].append((quando, v, ref))
    for i, d in enumerate(sorted(caixa_dia)):
        sid = uid("caixa", d)
        abertura, gaveta, sangrias = 20000, 20000, 0
        for (quando, v, ref) in caixa_dia[d]:
            gaveta += v
            out["caixa_movimentos"].append(dict(sessao_id=sid, tipo="pagamento_dinheiro", valor_cents=v, origem_id=ref, em=quando.isoformat()))
            if gaveta > 80000:
                gaveta -= 50000
                sangrias += 50000
                out["caixa_movimentos"].append(dict(sessao_id=sid, tipo="sangria", valor_cents=-50000, origem_id="", em=(quando + timedelta(minutes=2)).isoformat()))
        esperado = gaveta
        dif = 0 if rng.random() < .85 else (rng.choice([-500, -300, -200, -100]) if rng.random() < .67 else rng.choice([100, 200, 300]))
        contado = esperado + dif
        out["caixa_sessoes"].append(dict(id=sid, tenant_id=t, data_negocio=d.isoformat(), operador="Caixa Demo",
                                         aberto_em=datetime.combine(d, time(18, 0), TZ).isoformat(),
                                         fechado_em=(datetime.combine(d, time(23, 50), TZ) + timedelta(minutes=50)).isoformat(),
                                         abertura_cents=abertura, entradas_dinheiro_cents=sum(v for _, v, _ in caixa_dia[d]),
                                         sangrias_cents=sangrias, esperado_cents=esperado, contado_cents=contado, diferenca_cents=dif, is_demo=True))
        deposito = sangrias + contado - abertura  # tudo menos o troco do dia seguinte vai para o banco no dia seguinte
        if d + timedelta(days=1) < hoje:
            banco.append((d + timedelta(days=1), "Depósito do caixa", deposito, sid))
    # 2 lançamentos para a conciliação mostrar (sem par no sistema)
    banco.append((hoje - timedelta(days=4), "Tarifa bancária do pacote", -4990, ""))
    banco.append((hoje - timedelta(days=2), "PIX recebido sem identificação", 8900, ""))
    s = SALDO_INICIAL
    for i, (d, desc, v, ref) in enumerate(sorted(banco, key=lambda x: (x[0], x[2] < 0, x[1]))):
        assert d < hoje, f"lançamento bancário no futuro: {d}"
        s += v
        out["extrato_bancario"].append(dict(id=uid("extrato", i), tenant_id=t, data=d.isoformat(), descricao=desc, valor_cents=v,
                                            saldo_cents=s, conciliado_com=ref, conciliado="sim" if ref else "nao", is_demo=True))

    # notas fiscais de EXEMPLO (nada emitido): pedidos e comandas dos últimos 3 dias
    for i, (d, forma, v, ref, _) in enumerate(sorted(x for x in pagamentos if (hoje - x[0]).days <= 3)):
        out["notas_fiscais_exemplo"].append(dict(tenant_id=t, origem_id=ref, modelo="65 (NFC-e)", serie=900, numero=i + 1,
                                                 chave="99" + f"{i + 1:042d}", valor_cents=v, csosn=102,
                                                 ambiente="EXEMPLO — NÃO EMITIDA", status="exemplo", data=d.isoformat()))
    for k, rows in out.items():
        for r in rows:
            for c in ("data", "em", "aberto_em", "aberta_em"):
                if c in r and r[c]:
                    assert str(r[c])[:10] < hoje.isoformat() or k in ("contas_pagar",), f"{k}.{c} no futuro"
    return dados, out, receita, cmv_dia


def dre(receita, cmv_dia, contas, hoje):
    linhas = []
    meses = sorted(receita)
    cmv = defaultdict(int)
    for d, v in cmv_dia.items():
        cmv[d.strftime("%Y-%m")] += v
    desp = defaultdict(lambda: defaultdict(int))
    for c in contas:
        if c["categoria"] not in ("Insumos", "Bebidas para revenda", "Embalagens", "Repasse taxa de serviço"):  # compras viram CMV pelo consumo; repasse não é despesa
            desp[c["competencia"][:7]][c["categoria"]] += c["valor_cents"]
    for m in meses:
        r = receita[m]
        bruta = sum(v for k, v in r.items() if not k.startswith("__") and "serviço" not in k)
        das = round(bruta * .07)
        liquida = bruta - das
        c = cmv[m] + r["__perdas"]
        bruto = liquida - c
        dd = dict(desp[m])
        aviso = ""
        if m == hoje.strftime("%Y-%m"):                       # mês em andamento: fixas proporcionais aos dias corridos
            corridos = (hoje - hoje.replace(day=1)).days
            dias_mes = ((hoje.replace(day=1) + timedelta(days=32)).replace(day=1) - hoje.replace(day=1)).days
            dd = {k: round(v * corridos / dias_mes) for k, v in dd.items()}
            aviso = f"  (mês em andamento: despesas fixas proporcionais a {corridos} de {dias_mes} dias)"
        outras = sum(v for k, v in dd.items() if k != "Impostos (DAS)") + r["__taxas_cartao"]
        res = bruto - outras
        linhas.append(f"\n== DRE {m} =={aviso}")
        for k in sorted(k for k in r if not k.startswith("__")):
            linhas.append(f"  {k:<40} {brl(r[k]):>15}")
        linhas += [f"  {'(=) Receita bruta':<40} {brl(bruta):>15}", f"  {'(-) Impostos (DAS 7%)':<40} {brl(-das):>15}",
                   f"  {'(-) CMV (ficha técnica + perdas)':<40} {brl(-c):>15}  ({c / max(1, bruta):.1%} da receita)",
                   f"  {'(=) Lucro bruto':<40} {brl(bruto):>15}"]
        for k in sorted(k for k in dd if k != "Impostos (DAS)"):
            linhas.append(f"  {'(-) ' + k:<40} {brl(-dd[k]):>15}")
        linhas += [f"  {'(-) Taxas de cartão':<40} {brl(-r['__taxas_cartao']):>15}",
                   f"  {'(=) Resultado do mês':<40} {brl(res):>15}  (margem {res / max(1, bruta):.1%})"]
    return linhas


def executar(hoje, semente, saida):
    dados, out, receita, cmv_dia = gerar(hoje, semente)
    os.makedirs(saida, exist_ok=True)
    for nome, rows in out.items():
        with open(os.path.join(saida, f"gestao_{nome}.csv"), "w", newline="", encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()), lineterminator="\n")
            w.writeheader()
            w.writerows(rows)
    print(f"== Gestão da {base.TENANT['name']} | hoje = {hoje.isoformat()} ==")
    for nome in sorted(out):
        print(f"  {nome:<24} {len(out[nome]):>6} linhas")
    ult = out["extrato_bancario"][-1]["saldo_cents"]
    abaixo = [r["nome"] for r in out["estoque_saldos"] if r["abaixo_do_minimo"]]
    print(f"  saldo bancário final: {brl(ult)} | caixas com diferença: "
          f"{sum(1 for c in out['caixa_sessoes'] if c['diferenca_cents'])} de {len(out['caixa_sessoes'])}"
          f" | insumos abaixo do mínimo: {len(abaixo)} | contas a pagar em aberto: "
          f"{brl(sum(c['valor_cents'] for c in out['contas_pagar'] if c['status'] == 'aberta'))}")
    for linha in dre(receita, cmv_dia, out["contas_pagar"], hoje):
        print(linha)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hoje", default=datetime.now(TZ).date().isoformat())
    ap.add_argument("--semente", type=int, default=42)
    ap.add_argument("--saida", default=os.path.join(AQUI, "saida"))
    ap.add_argument("--verificar", action="store_true")
    a = ap.parse_args()
    hoje = date.fromisoformat(a.hoje)
    if a.verificar:
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            executar(hoje, a.semente, a.saida)
        gab = os.path.join(AQUI, f"gabarito_gestao_{a.hoje}.txt")
        if buf.getvalue() != open(gab, encoding="utf-8").read():
            print(f"DIVERGE do gabarito {os.path.basename(gab)}"); sys.exit(1)
        print(f"OK: gestão idêntica ao gabarito {os.path.basename(gab)}")
        return
    executar(hoje, a.semente, a.saida)


if __name__ == "__main__":
    main()
