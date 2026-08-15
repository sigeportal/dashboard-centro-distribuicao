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

## 5. Mapeamento de Datas de Referência do Dashboard (`DATA_REF`)
- **Origem das Datas Locais (`api_dashboard`)**:
  - **Vendas / Grupos / Horas**: As datas de referência são extraídas dos lançamentos reais das tabelas locais `VENDAS` (campo `VEN_DATA`) ou `PED_FAT` com `PF_TABELA = 'VENDAS'` (campo `PF_DATA`).
  - **Recebimentos / Formas de Pagamento / Movimentações**: As datas utilizam os registros reais da tabela local `REC_PGM` (campo `RP_DATAPGM`).
- **Sincronização Cloud Central (`/v1/sync/dashboard`)**:
  - Toda estrutura do Dashboard (`DASHBOARD_DIARIO`, `DASHBOARD_PAGAMENTOS`, `DASHBOARD_VENDAS_GRUPO`, `DASHBOARD_CLIENTES_CIDADE`, `DASHBOARD_VENDAS_HORA`) preserva e filtra por `DATA_REF` (DATE).
  - No envio do sync, o servidor central apaga e substitui pontualmente apenas os registros pertencentes àquela `EMPRESA_ID` e `DATA_REF` específica de cada lançamento real, garantindo a fidelidade dos filtros por período (`De` / `Até`) no portal.

## 6. Diretrizes do Agente Especialista em Backend Delphi & PortalORM
- **Especialidade**: O agente backend Delphi é especialista em **PortalORM** (`G:\PROJETOS\CENTRO-DISTRIBUICAO\backend\ServidorConsole\modules\portalorm` ou `https://github.com/cachopaweb/PortalORM`).
- **Mapeamento de Entidades**:
  - Toda nova entidade ou tabela deve ser mapeada como classe herdando de `TTabela` (`UnitPortalORM.Model.pas`).
  - Usar os atributos:
    * `[TRecursoServidor('/recurso')]`
    * `[TNomeTabela('NOME_TABELA', 'CHAVE_PK')]`
    * `[TCampo('CAMPO_BD', 'TIPO_SQL')]`
    * `[TRelacionamento('TABELA_REL', 'PK_REL', 'FK_LOCAL', TClasseRel, TTipoRelacionamento.UmPraUm / UmPraMuitos)]`
- **Uso Máximo do PortalORM**:
  - Sempre priorizar métodos nativos: `CriaTabela`, `BuscaDadosTabela(id)`, `SalvaNoBanco(1)`, `Apagar(id)`, `ToJson`, `SetJson`.
  - **Regra de SQL Raw**: Somente utilizar SQL manual (`iQuery` / `TDatabase.Query`) caso o PortalORM não forneça a funcionalidade necessária (consultas analíticas agregadas complexas, joins analíticos customizados ou bulk updates de alta performance).
  - Ao usar `iQuery`, respeitar estritamente a execução sem parâmetros no `ExecSQL` (`LQuery.Clear; LQuery.Add('...'); LQuery.ExecSQL;`).

## 7. Diretrizes do Agente Especialista em Frontend React & Design System
- **Padrão Visual Unificado**:
  - Todas as telas e modais devem seguir estritamente o Design System da aplicação:
    * Containers e cards: `.crud-container`, `.glass`, `.list-card`, `border-radius: 1rem a 1.25rem`, bordas suaves e sombras refinadas.
    * Cores: Laranja institucional (`linear-gradient(135deg, #f97316 0%, #ea580c 100%)`) e Azul (`#2563eb`), fundo `#f8fafc` / `#ffffff`, tipografia Inter/Outfit.
    * Formulários & Ações: `.crud-input` e `.form-group` estruturados, botões com ícones da biblioteca `lucide-react`, espaçamento adequado (`.crud-form-actions` com `gap: 1rem` e `padding-top: 1.25rem`).
    * Listagens e Tabelas: `.data-table` responsiva, badges de status (`.badge-info`, `.badge-warning`, `.badge-success`), botões de ação (`.crud-row-btn edit/delete`).
- **Regra de Tradução de Telas e Imagens Legadas**:
  - Mesmo quando o usuário fornecer imagens, formulários Delphi (.dfm), relatórios ou telas de sistemas antigos (Madenorte, Confecções, PDV Desktop), o agente frontend **NUNCA deve reproduzir o visual retrô ou desatualizado**.
  - **SEMPRE traduzir os campos, regras de negócio e fluxos para o padrão visual moderno do React Dashboard Portal**.
- **Segurança de Dados**:
  - Tratar retornos relacionais (ex: objetos de cidades, fornecedores) para extrair strings limpas, evitando `[object Object]`.

