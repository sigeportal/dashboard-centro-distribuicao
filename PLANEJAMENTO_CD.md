# Plano de Reestruturação: Centro de Distribuição e Frontend

Este documento registra a estratégia e as etapas para a evolução da arquitetura do ecossistema API Central. O objetivo principal é tornar o Dashboard (Frontend) independente da disponibilidade da API local (24/7) e introduzir a gestão de um Centro de Distribuição com sincronização de estoque entre 5 unidades (Matriz + 4 Filiais).

---

## 1. Contexto e Desafio Atual
Atualmente, o portal/dashboard consome dados providos pela `API-local`, que por sua vez se comunica com o banco de dados Firebird local. Para expor esta API à web, utiliza-se o `ngrok`.
*   **Problema:** Se o computador servidor local for desligado ou o sistema Delphi/Firebird parar, os usuários perdem o acesso aos dados no dashboard.
*   **Solução:** Migrar a leitura de dados do dashboard para um banco de dados online (em nuvem). A API `ServidorRESTConfeccoes` (localizada na pasta homônima) será reestruturada e hospedada para servir como ponte direta do dashboard para este banco de dados online.

---

## 2. Escopo e Impacto

### Backend (`ServidorRESTConfeccoes`)
*   Será conectado diretamente ao banco de dados online.
*   Proverá as APIs de leitura e escrita necessárias para o Dashboard.
*   Implementará rotas de sincronização de dados de alta performance em lote (padrão `/emLote`), permitindo que as instâncias locais (filiais) enviem seus dados de estoque/vendas de forma rápida e segura.

### Frontend (`Dashboard-Portal`)
*   Se comunicará diretamente com o banco de dados online (via `ServidorRESTConfeccoes`).
*   Será atualizado para suportar novas telas de cadastro (PRODUTOS, GRUPOS, SUB_GRUPOS, GRADES e TAMANHOS).
*   Ganhará o novo **Módulo de Transferências** (Centro de Distribuição), permitindo movimentar estoque e acompanhar saldos entre as 5 unidades configuradas.
*   Utilizará o `PortalORM` para estruturar, atualizar e manter as tabelas de dados necessárias.

---

## 3. Divisão de Features

### Feature 1: Modelagem do Banco de Dados Online e PortalORM
*   **Objetivo:** Estabelecer a estrutura relacional no banco online e espelhá-la no frontend.
*   **Ações:**
    1.  Estruturar as tabelas com base em `docs/METADATA.SQL` para comportar as entidades:
        *   `PRODUTOS` (Tabela `PRODUTOS`)
        *   `GRUPOS` (Tabela `GRUPO_1`)
        *   `SUB_GRUPOS` (Tabela `GRUPOS`)
        *   `GRADES` (Tabela `GRADES`)
        *   `TAMANHOS` (Tabela `TAMANHOS`)
    2.  Criar a tabela `TRANSFERENCIAS_ESTOQUE` para registrar o histórico de remessa de produtos entre unidades (Data, Origem, Destino, Produto, Quantidade, Status).
    3.  Atualizar as definições de schemas e models do `PortalORM` no projeto `Dashboard-Portal` para gerenciar essas tabelas de forma transparente.

### Feature 2: REST APIs e Sincronização em Lote (Backend)
*   **Objetivo:** Permitir inserções e consultas eficientes, adaptando o backend para cargas pesadas de dados.
*   **Ações:**
    1.  Configurar a conexão de banco de dados do `ServidorRESTConfeccoes` para apontar para o banco de dados online.
    2.  Criar endpoints CRUD básicos:
        *   `GET/POST/PUT/DELETE /produtos`
        *   `GET/POST/PUT/DELETE /grupos`
        *   `GET/POST/PUT/DELETE /subgrupos`
        *   `GET/POST/PUT/DELETE /grades`
        *   `GET/POST/PUT/DELETE /tamanhos`
        *   `GET/POST/PUT/DELETE /transferencias`
    3.  Implementar endpoints de processamento em lote `/emLote` para todos os cadastros essenciais, seguindo o padrão de alta performance implementado em `PedidoRemoto/Controller/UnitPedidoRemoto.Controller.pas`.
        *   *Exemplo:* O endpoint `/produtos/emLote` receberá uma lista compacta em JSON e realizará as inserções em lote utilizando transações otimizadas no Firebird online.

### Feature 3: Telas de Cadastro no Frontend (Dashboard)
*   **Objetivo:** Autonomia completa no gerenciamento do catálogo de produtos a partir da nuvem.
*   **Ações:**
    1.  Criar interfaces administrativas ricas e de alta usabilidade (seguindo o guia visual em `DESIGN.md`) para:
        *   **Produtos:** Detalhamento, associação de código de barras, preços e estoque básico.
        *   **Grupos e Subgrupos:** Árvore de categorias.
        *   **Grades e Tamanhos:** Gerenciamento das variações físicas dos produtos para confecção.
    2.  Integrar todas as telas ao `PortalORM` para persistência local em cache (se aplicável) e sincronização ativa com a API online.

### Feature 4: Módulo de Centro de Distribuição (Transferências)
*   **Objetivo:** Permitir a transferência física e lógica de mercadorias entre as filiais e a matriz, mantendo os estoques sincronizados em tempo real.
*   **Ações:**
    1.  **Dashboard de Estoque Unificado:** Painel onde o gestor visualiza a quantidade em estoque de qualquer produto de forma comparativa entre a Matriz e as 4 Filiais.
    2.  **Fluxo de Nova Transferência:**
        *   Seleção de Unidade de Origem (onde o estoque será debitado).
        *   Seleção de Unidade de Destino (onde o estoque será creditado).
        *   Seleção de produtos, com suporte à digitação de quantidades por grade/tamanho.
        *   Validação em tempo real para impedir transferências que excedam o estoque disponível na origem.
    3.  **Processamento da Transferência:** Envio da requisição para `/transferencias`, onde o backend atualizará os saldos no banco online dentro de uma transação isolada (Garantindo atomicidade: débito na origem + crédito no destino + registro da transferência).

### Feature 5: Recepção, Conferência, Aprovação e Notificações
*   **Objetivo:** Permitir que o gestor ou Admin da unidade destino confira e aprove a transferência física de mercadorias recebidas, disparando notificações de status e mantendo a matriz informada.
*   **Ações:**
    1.  **Status da Transferência:** Adicionar controle de status nas transferências: `Pendente`, `Em Trânsito`, `Conferido/Aprovado`, `Rejeitado`.
    2.  **Painel de Recepção (Unidade Destino):**
        *   Telas exclusivas para usuários Admin/Gerentes da unidade destino visualizarem as transferências destinadas a eles com status `Em Trânsito`.
        *   Interface de Conferência: Permite conferir item a item (quantidade enviada vs. quantidade recebida).
        *   Aprovação do Recebimento: Ao aprovar, o estoque é oficialmente incrementado na unidade destino (ou ajustado de acordo com a conferência), mudando o status para `Conferido/Aprovado`.
    3.  **Gestão de Notificações:**
        *   **Novas Transferências:** Quando uma transferência é criada na origem, uma notificação visual/push é gerada no dashboard para o Admin/Gerente da filial destino.
        *   **Aprovação e Conferência:** Quando o destino aprova e finaliza a conferência, uma notificação em tempo real é enviada para os usuários da Matriz informando o sucesso ou as divergências encontradas.

---

## 4. Estratégia de Validação e Testes
1.  **Testes de Integração da API:** Utilização de ferramentas como Postman/Insomnia para testar os endpoints de lote (`/emLote`), simulando o upload de grandes volumes de produtos (ex: lotes de 50 a 100 itens) e medindo o tempo de resposta e integridade dos dados.
2.  **Validação de Concorrência e Transação:** Testar exaustivamente o fluxo de transferências para certificar que os saldos de estoque permaneçam íntegros mesmo sob tentativas de transferências simultâneas do mesmo lote de produtos.
3.  **Modo de Contingência (Local/Online):** Testar o comportamento do frontend caso a internet falhe, garantindo feedback visual adequado para o usuário (ex: alertando sobre a indisponibilidade momentânea do banco online).
