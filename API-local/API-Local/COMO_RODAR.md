# Como Rodar a API Local - Guia Simples

Este guia vai te ajudar a configurar e rodar a API no seu computador de um jeito fácil. Siga os passos abaixo:

---

## 1. Pré-requisitos (O que você precisa ter instalado)

Antes de começar, certifique-se de que você tem:

1.  **Firebird SQL:** O banco de dados onde as informações ficam guardadas.
2.  **Ngrok:** Uma ferramenta que permite que o seu computador "fale" com a internet de forma segura.
    *   [Baixe aqui](https://ngrok.com/download) e crie uma conta gratuita.
    *   Após instalar, abra o terminal e digite: `ngrok config add-authtoken SEU_TOKEN_AQUI` (o token você pega no site do ngrok).
3.  **Delphi:** Necessário para abrir o projeto e rodar o código (caso vá rodar via código-fonte).

---

## 2. Configurações Iniciais (Variáveis de Ambiente)

A API precisa de uma configuração principal de ambiente no Windows:

*   `CAMINHO_BD`: Local exato do arquivo do banco de dados Firebird SQL (ex: `C:\Estagio\API-Local\Dados\PRINCIPAL.FDB`).

> [!NOTE]
> * A chave `JWT_SECRET` compartilhada com o servidor de autenticação está definida diretamente no código em `src/utils/UnitConstants.pas` (`TConstants.JWT_SECRET`).
> * A variável `URL_API_CENTRAL` não é mais necessária, pois a URL do servidor de autenticação central está embutida diretamente na API.

> **Como configurar no Windows:**
> 1. Pesquise por "Variáveis de Ambiente" no menu Iniciar.
> 2. Clique em "Variáveis de Ambiente...".
> 3. Em "Variáveis do sistema", clique em **Novo**.
> 4. Adicione a variável `CAMINHO_BD` com o caminho do banco de dados.

* [Link para API_CENTRAL](https://github.com/Nann-spec/API-Central): Repositório no GitHub contendo o código-fonte da API Central de autenticação.

---

## 3. Como Rodar a API

### Passo a Passo:

1.  **Abra o projeto:** No Delphi, abra o arquivo `api_dashboard.dproj`.
2.  **Compile e Rode:** Aperte a tecla `F9` ou clique no botão de "Play".
3.  **O que vai acontecer?**
    *   A janela da API vai abrir e se esconder automaticamente (ela roda em "segundo plano").
    *   O **ngrok** será iniciado sozinho para criar um link seguro.
    *   A API vai tentar se conectar com a "Central" para avisar que está online.

---

## 4. Como saber se está funcionando?

Você pode testar se a API está ok abrindo o navegador e digitando:
`http://localhost:9000/swagger/doc/html`

Se abrir uma página com a lista de funções da API, parabéns! Tudo está funcionando corretamente.

---

## 5. Resumo de Problemas Comuns

*   **Erro ao conectar no banco:** Verifique se o caminho na variável `CAMINHO_BD` está correto e se o Firebird está rodando.
*   **Ngrok não inicia:** Verifique se você instalou o ngrok e adicionou o seu "authtoken".
*   **API não aparece:** Ela foi feita para rodar escondida. Se precisar fechá-la, use o **Gerenciador de Tarefas** e procure por `api_dashboard.exe`.
