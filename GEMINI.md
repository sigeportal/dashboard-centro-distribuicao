# Regras e Diretrizes do Projeto API Central (PortalORM / Delphi & React Frontend)

## 1. Regras do PortalORM (Delphi ORM)
- **Criação de Campos e Tabelas DDL**: O **PortalORM** cria e gerencia automaticamente as colunas e tabelas no banco de dados Firebird através das classes de modelo derivadas de `TTabela` (ex: `CriaTabela`).
- **NÃO Executar `ALTER TABLE` Manuais**: Não é necessário executar instruções manuais como `ALTER TABLE PRODUTOS ADD PRO_CADASTRAR...` via SQL, pois a infraestrutura do PortalORM realiza o mapeamento e a DDL automaticamente.

## 2. Execução de SQL com `iQuery` / `TDatabase.Query`
- O método `ExecSQL` na interface `iQuery` do PortalORM é estritamente **sem parâmetros** (`procedure ExecSQL;`).
- Toda execução SQL sem retorno de dataset deve seguir obrigatoriamente o padrão:
  ```pascal
  LQuery.Clear;
  LQuery.Add('SUA INSTRUÇÃO SQL AQUI');
  LQuery.ExecSQL;
  ```
- **NUNCA** chamar `LQuery.ExecSQL('STRING SQL')` diretamente com argumento string.

## 3. Modelo de Dados e Arquitetura do Centro de Distribuição (CD)
- **Banco Centralizador Isolado**: O banco do Centro de Distribuição (`api_centro_distribuicao`) é isolado na nuvem e centraliza cadastros das 5 filiais (`CD DOURADINA`, `ITAPORA`, `MARACAJU`, `NOVA ALVORADA`, `RIO BRILHANTE`).
- **Sincronização Incremental (Delta Sync)**:
  - Os itens possuem a flag `CADASTRAR = 'S'` quando são novos ou alterados no CD.
  - A rota `/v1/sync/pending` consulta apenas os itens com `CADASTRAR = 'S'` ou `NULL`.
  - Após a transmissão (ou via `/v1/sync/ack`), o status é alterado para `'N'` (`UPDATE ... SET CADASTRAR = 'N'`), evitando o envio de dados duplicados nos ciclos seguintes.
- **Tabela `ESTOQUE_EMPRESA`**:
  - Exige a chave primária `EE_ID`. Novas gravações geram a chave via `GeraCodigo('ESTOQUE_EMPRESA', 'EE_ID')`.

## 4. Integração com a NotaFiscal Online API (Emissão de NF-e / Modelo 55 - NT 2025.002)
- **Servidor REST Cloud**: `https://servidor-nota-fiscal-434040955537.southamerica-east1.run.app/v1`
- **Autenticação JWT**: `POST /v1/auth/login` com `username` e `password`. Toda requisição subsequente deve incluir o cabeçalho `Authorization: Bearer <token>`.
- **Emissão de Transferências (Modelo 55)**:
  - CFOP padrão para transferência interna de mercadorias entre matriz e filiais: **`5152`** (ou `6152` para interestadual).
  - Forma de pagamento: **`90` (Sem Pagamento)**.
  - CST ICMS: **`102` (Simples Nacional sem permissão de crédito)** ou conforme CRT do emitente.
- **Reforma Tributária (NT 2025.002 - IBS/CBS e Imposto Seletivo)**:
  - **Campos de Cabeçalho**: `finalidade_emissao` (`1` Normal, `5` Nota de Crédito, `6` Nota de Débito), `cmun_fg_ibs` (`5003801`), `cind_op` (`010104`), `tp_nf_credito` (`"01"`), `tp_nf_debito` (`"04"`).
  - **Campos por Item**: `cst_ibscbs` (`"01"`), `cclass_trib` (`"000000"` ou `"810001"`), `aliq_ibs_uf` (`0.1`), `aliq_ibs_mun` (`0.0`), `aliq_cbs` (`0.9`), `cst_is` (`"01"`), `cclass_trib_is` (`"000000"`), `aliq_is` (`0.0`).
- **Acompanhamento e Downloads**:
  - DANFE em PDF: `GET /v1/nfe/{chave}/danfe` (`Accept: application/pdf`).
  - XML Autorizado: `GET /v1/nfe/{chave}/xml` (`Accept: application/xml`).
  - Status SEFAZ: `GET /v1/nfe/{chave}`.
  - Cancelamento: `POST /v1/nfe/{chave}/cancelar` (`{ "protocolo": "...", "justificativa": "..." }`).
