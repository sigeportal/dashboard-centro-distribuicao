# 🚀 API Central & Portal de Gestão do Centro de Distribuição (CD)

Sistema centralizado de gestão multi-filial, sincronização incremental de dados (Delta Sync) e Portal Web Dashboard para o Centro de Distribuição e 5 filiais ativas.

---

## 📌 Arquitetura do Sistema

- **Frontend Web**: Portal Dashboard em React + Vite + Vanilla CSS.
- **Servidor Central REST**: API em Delphi + Horse + PortalORM (porta 9000).
- **Banco de Dados Central**: Firebird SQL aislados / centralizado (pi_centro_distribuicao.fdb).
- **Agente Local de Sincronização**: Engine em Delphi (pi_dashboard.exe) que roda em cada uma das 5 filiais (CD DOURADINA, ITAPORA, MARACAJU, NOVA ALVORADA, RIO BRILHANTE).

---

## ⭐ Principais Funcionalidades

### 1. 🔄 Sincronização Incremental (Delta Sync)
- Controle inteligente por flag CADASTRAR = 'S' em produtos, grupos, subgrupos e fornecedores.
- O endpoint /v1/sync/pending envia apenas alterações pendentes para as filiais.
- O endpoint /v1/sync/ack marca CADASTRAR = 'N' após a transmissão, eliminando redundâncias.

### 2. 🚚 Gestão de Transferências entre Unidades
- Transferências Fiscais (NF-e) e Não Fiscais.
- **Importação Automática de Nota Fiscal**: Ao informar a chave da NF-e ou o número dela, o botão **📥 Puxar Todos os Itens Desta Nota Fiscal** popula automaticamente os produtos e quantidades no lote de transferência.

### 3. 📦 Posição de Estoque Consolidada por Filial
- Visualização de estoque produto a produto por unidade.
- As quantidades das filiais em ESTOQUE_EMPRESA são alteradas **exclusivamente por transferências**, garantindo a integridade dos saldos locais.

### 4. 📊 Dashboard Analítico (Últimos 90 Dias)
- Gráficos de vendas diárias, vendas por hora, margem de lucro, movimentações financeiras e despesas por tipo de pagamento.
- Formatação universal de datas em padrão **pt-BR** e fuso **UTC-4** (America/Campo_Grande).

---

## 📝 Regras de Desenvolvimento (GEMINI.md)

1. **PortalORM (Delphi ORM)**:
   - A infraestrutura do PortalORM cria e gerencia automaticamente as tabelas e colunas DDL através das classes derivadas de TTabela.
   - **NÃO** executar instruções manuais ALTER TABLE via SQL no código.
2. **Execução SQL com iQuery**:
   - O método ExecSQL na interface iQuery do PortalORM é estritamente **sem argumentos** (procedure ExecSQL;).
   - Padrão obrigatório: LQuery.Clear; LQuery.Add('SQL'); LQuery.ExecSQL;
