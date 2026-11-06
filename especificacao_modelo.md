# Especificação de modelagem — Barbearia Ferrari

> Documento de apoio para desenhar os diagramas no brModelo. Não substitui os arquivos gráficos exigidos.

## Entidades e atributos conceituais

- BARBEARIA: id_barbearia (identificador), nome, endereco, telefone.
- CLIENTE: id_cliente (identificador), nome, telefone, data_cadastro.
- FUNCIONARIO: id_funcionario (identificador), nome, tipo_vinculo, percentual_comissao, status.
- SERVICO: id_servico (identificador), nome, descricao, categoria, preco_atual, ativo.
- ATENDIMENTO: id_atendimento (identificador), data_hora_inicio, data_hora_fim, status, observacao.
- ITEM_ATENDIMENTO (associativa): id_item_atendimento (identificador), quantidade, valor_unitario_praticado, desconto, percentual_comissao_aplicado.
- PAGAMENTO: id_pagamento (identificador), forma_pagamento, valor, data_hora, status.
- AGENDAMENTO: id_agendamento (identificador), data_hora_inicio, data_hora_fim, status, observacao.
- DESPESA: id_despesa (identificador), descricao, categoria, classificacao, valor, data_competencia, data_pagamento, status.
- MATERIAL: id_material (identificador), nome, unidade_medida, estoque_minimo, ativo.
- FORNECEDOR: id_fornecedor (identificador), nome, telefone, contato.
- COMPRA: id_compra (identificador), data_compra, status, observacao.
- ITEM_COMPRA: id_item_compra (identificador), quantidade, custo_unitario.
- MOVIMENTACAO_ESTOQUE: id_movimentacao (identificador), tipo, quantidade, data_hora, motivo.
- REPASSE_COMISSAO: id_repasse (identificador), data_inicio, data_fim, data_pagamento, status.
- ITEM_REPASSE_COMISSAO (associativa): id_repasse + id_item_atendimento (identificador composto), valor_comissao_pago.

## Relacionamentos e cardinalidades mínimas/máximas propostas

As cardinalidades do lado de participação são propostas para o desenho e precisam ser validadas com as regras reais:

| Entidade A | Relacionamento | Entidade B | Cardinalidade A | Cardinalidade B |
|---|---|---|---|---|
| BARBEARIA | cadastra | FUNCIONARIO | (1,1) para cada FUNCIONARIO | (0,n) para BARBEARIA |
| BARBEARIA | oferece | SERVICO | (1,1) para cada SERVICO | (0,n) para BARBEARIA |
| BARBEARIA | registra | DESPESA | (1,1) para cada DESPESA | (0,n) para BARBEARIA |
| BARBEARIA | controla | MATERIAL | (1,1) para cada MATERIAL | (0,n) para BARBEARIA |
| CLIENTE | realiza | ATENDIMENTO | (1,1) para cada ATENDIMENTO | (0,n) para CLIENTE |
| FUNCIONARIO | executa | ATENDIMENTO | (1,1) para cada ATENDIMENTO | (0,n) para FUNCIONARIO |
| ATENDIMENTO | contém | ITEM_ATENDIMENTO | (1,n) para cada ATENDIMENTO concluído | (1,1) para ITEM_ATENDIMENTO |
| SERVICO | compõe | ITEM_ATENDIMENTO | (1,1) para ITEM_ATENDIMENTO | (0,n) para SERVICO |
| ATENDIMENTO | recebe | PAGAMENTO | (0,n) enquanto aberto; mínimo 1 para quitado | (1,1) para PAGAMENTO |
| CLIENTE | solicita | AGENDAMENTO | (1,1) para AGENDAMENTO | (0,n) para CLIENTE |
| FUNCIONARIO | é reservado em | AGENDAMENTO | (0,1) para AGENDAMENTO, se houver profissional definido | (0,n) para FUNCIONARIO |
| FORNECEDOR | fornece | COMPRA | (1,1) para COMPRA | (0,n) para FORNECEDOR |
| COMPRA | possui | ITEM_COMPRA | (1,n) para COMPRA | (1,1) para ITEM_COMPRA |
| MATERIAL | aparece em | ITEM_COMPRA | (1,1) para ITEM_COMPRA | (0,n) para MATERIAL |
| MATERIAL | recebe/sofre | MOVIMENTACAO_ESTOQUE | (1,1) para MOVIMENTACAO | (0,n) para MATERIAL |
| FUNCIONARIO | recebe | REPASSE_COMISSAO | (1,1) para REPASSE | (0,n) para FUNCIONARIO |
| REPASSE_COMISSAO | quita | ITEM_REPASSE_COMISSAO | (1,n) para REPASSE pago | (1,1) para ITEM_REPASSE |
| ITEM_ATENDIMENTO | integra | ITEM_REPASSE_COMISSAO | (0,1) para ITEM_ATENDIMENTO | (1,1) para ITEM_REPASSE |

## Decisões que devem ser confirmadas

1. Se a barbearia aceita pagamentos divididos. O modelo PAGAMENTO 1:N suporta isso.
2. Se o agendamento sempre identifica funcionário ou se a escolha ocorre somente na chegada.
3. Se compra/estoque são efetivamente controlados e quais unidades de medida são utilizadas.
4. Se o proprietário também recebe comissão ou somente o funcionário contratado.
5. Como descontos/combos afetam a base dos 50%.
6. Qual periodicidade de repasse é praticada.
7. Se a entidade BARBEARIA deve permanecer, considerando que hoje foi informada apenas uma unidade.

## Conversão lógica

As relações 1:N são implementadas com FK no lado N. ATENDIMENTO–SERVICO é N:N e foi resolvida por ITEM_ATENDIMENTO. REPASSE_COMISSAO–ITEM_ATENDIMENTO também é N:N e foi resolvida por ITEM_REPASSE_COMISSAO. Não desenhar FKs no DER conceitual; elas pertencem ao modelo lógico.
