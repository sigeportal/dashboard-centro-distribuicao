# API-Central

API Central de autenticacao, cadastro de clientes e controle de empresas vinculadas ao Dashboard.

O projeto e desenvolvido em Delphi 10.2 Tokyo com Horse, Firebird e PortalORM.

## Visao Geral

A API Central separa a autenticacao do cliente da gestao das empresas.

- `CLIENTE`: usuario do Dashboard. Faz login por CPF e senha.
- `EMPRESA`: empresa sincronizada pela API Local. Nao possui senha.
- `CLIENTE_EMPRESA`: vinculo entre clientes e empresas.

O fluxo atual considera que a API Local tenta atualizar a URL da empresa. Se a empresa ainda nao existir na API Central, a API Local chama uma rota especifica de autocadastro.

## Stack

- Delphi 10.2 Tokyo
- Horse
- Horse CORS
- Jhonson
- Horse JWT / JOSE
- GBSwagger
- PortalORM
- Firebird 2.5

## Estrutura Principal

```text
src/
  controllers/
    AuthController.pas
    ClienteController.pas
    CompanyController.pas
  services/
    AuthService.pas
    ClienteService.pas
    CompanyService.pas
    HashService.pas
    TokenService.pas
  models/
    Cliente/UnitCliente.Model.pas
    Empresa/UnitEmpresa.Model.pas
    ClienteEmpresa/UnitClienteEmpresa.Model.pas
  middlewares/
    AuditMiddleware.pas
    AuthMiddleware.pas
  utils/
    UnitConstants.pas
    UnitFunctions.pas
```

## Autenticacao

### POST `/v1/register`

Cria um novo cliente.

Request:

```json
{
  "nome": "Joao Silva",
  "cpf": "123.456.789-09",
  "password": "senha123"
}
```

Regras:

- CPF pode vir com ou sem mascara.
- CPF e normalizado para apenas numeros.
- CPF deve ser valido e unico.
- A API gera salt e hash da senha.
- O cliente inicia com `CLI_PLANO = 0`.
- `confirm_password` nao e recebido pela API; essa validacao fica no Dashboard.

Resposta `201`:

```json
{
  "id": "1",
  "nome": "Joao Silva",
  "cpf": "12345678909",
  "plano": 0
}
```

Possiveis erros:

- `400`: dados invalidos.
- `409`: CPF ja cadastrado.

### POST `/v1/login`

Autentica o cliente por CPF e senha.

Request:

```json
{
  "cpf": "123.456.789-09",
  "password": "senha123"
}
```

Resposta `200`:

```json
{
  "access_token": "...",
  "refresh_token": "..."
}
```

Observacao: o token usa `CLI_ID` como subject.

### POST `/v1/refresh-token`

Gera novo access token a partir do refresh token.

Request:

```json
{
  "refresh_token": "..."
}
```

Resposta `200`:

```json
{
  "access_token": "..."
}
```

### POST `/v1/update-password`

Altera a senha do cliente autenticado.

Header:

```http
Authorization: Bearer <access_token>
```

Request:

```json
{
  "old_password": "senhaAtual",
  "new_password": "novaSenha"
}
```

Resposta `200`:

```json
{
  "status": "Senha alterada com sucesso"
}
```

## Empresas

### POST `/v1/update-url`

Atualiza a URL de uma empresa ja cadastrada.

Request:

```json
{
  "cnpj": "12.345.678/0001-90",
  "url": "https://empresa.ngrok.app/v1",
  "timestamp": "2026-07-10T10:00:00Z",
  "assinatura": "..."
}
```

Assinatura:

```text
cnpj + url + timestamp
```

Regras:

- O CNPJ e validado e normalizado para apenas numeros.
- A assinatura HMAC e calculada usando o CNPJ normalizado como chave.
- A rota nao faz autocadastro.
- Se a empresa nao existir, retorna `404`.

Resposta `200`:

```json
{
  "status": "URL atualizada com sucesso"
}
```

### POST `/v1/companies/self-register`

Autocadastra uma empresa quando `update-url` retornar `404`.

Request:

```json
{
  "cnpj": "12.345.678/0001-90",
  "nome": "Empresa A",
  "url": "https://empresa.ngrok.app/v1",
  "claim": "CODIGO-CLAIM-DA-EMPRESA",
  "timestamp": "2026-07-10T10:00:00Z",
  "assinatura": "..."
}
```

Assinatura:

```text
cnpj + nome + url + claim + timestamp
```

Regras:

- A empresa nao recebe senha.
- O claim nao e salvo em texto puro.
- A API salva apenas `EMP_CLAIMHASH`.
- A empresa criada ainda nao fica vinculada a nenhum cliente.

Resposta `201`:

```json
{
  "id": "1",
  "cnpj": "12345678000190",
  "nome": "Empresa A",
  "url": "https://empresa.ngrok.app/v1"
}
```

Possiveis erros:

- `400`: dados invalidos.
- `401`: assinatura invalida.
- `409`: empresa ja cadastrada.

### POST `/v1/companies/link`

Vincula uma empresa existente ao cliente autenticado.

Header:

```http
Authorization: Bearer <access_token>
```

Request:

```json
{
  "cnpj": "12.345.678/0001-90",
  "claim": "CODIGO-CLAIM-DA-EMPRESA"
}
```

Regras:

- A API pega o cliente pelo `CLI_ID` do JWT.
- A empresa deve existir.
- O claim informado deve bater com `EMP_CLAIMHASH`.
- O mesmo cliente nao pode vincular a mesma empresa duas vezes.
- Uma empresa pode ser vinculada a mais de um cliente.

Resposta `201`:

```json
{
  "empresa_id": "1",
  "cnpj": "12345678000190"
}
```

Possiveis erros:

- `400`: dados invalidos.
- `401`: token invalido ou claim invalido.
- `404`: empresa nao cadastrada.
- `409`: empresa ja vinculada ao cliente.

### GET `/v1/companies/linked`

Lista as empresas vinculadas ao cliente autenticado.

Header:

```http
Authorization: Bearer <access_token>
```

Regras:

- A API pega o cliente pelo `CLI_ID` do JWT.
- A rota nao recebe `cliente_id` por parametro ou body.
- Retorna somente empresas vinculadas ao cliente autenticado.
- Nao retorna `EMP_CLAIMHASH` ou qualquer dado sensivel interno da empresa.
- Se nao houver empresas vinculadas, retorna lista vazia.

Resposta `200`:

```json
{
  "companies": [
    {
      "id": "1",
      "cnpj": "12345678000190",
      "nome": "Empresa A",
      "url": "https://empresa.ngrok.app/v1"
    }
  ]
}
```

Resposta `200` sem vinculos:

```json
{
  "companies": []
}
```

Possiveis erros:

- `400`: cliente invalido.
- `401`: token invalido ou nao informado.
- `500`: erro interno do servidor.

## Fluxo da API Local

1. Chamar `POST /v1/update-url`.
2. Se retornar `200`, a URL foi atualizada.
3. Se retornar `404`, chamar `POST /v1/companies/self-register`.
4. Depois do autocadastro, continuar usando apenas `update-url`.

Esse fluxo evita enviar o claim em toda requisicao.

## Fluxo do Dashboard

1. Criar cliente com `POST /v1/register`.
2. Fazer login com `POST /v1/login`.
3. Usar `access_token` nas rotas autenticadas.
4. Vincular empresas com `POST /v1/companies/link`.
5. Listar empresas vinculadas com `GET /v1/companies/linked`.
6. Alterar senha com `POST /v1/update-password`.

## Health Check

### GET `/v1/ping`

Resposta:

```text
Pong
```

## Banco de Dados

Scripts principais:

- `DADOS/CRIAR_TABELA_CLIENTE.sql`
- `DADOS/CRIAR_TABELA_EMPRESA.sql`
- `DADOS/CRIAR_TABELA_CLIENTE_EMPRESA.sql`
- `DADOS/CONSULTAS_API.sql`

O banco alvo atual e Firebird 2.5.

## Swagger

Com a API rodando, acesse a documentacao Swagger conforme configuracao do GBSwagger no projeto.

Endpoint JSON documentado no projeto:

```http
/swagger/doc/json
```

Interface HTML:

```http
/swagger/doc/html
```

