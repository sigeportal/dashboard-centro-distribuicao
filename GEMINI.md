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
