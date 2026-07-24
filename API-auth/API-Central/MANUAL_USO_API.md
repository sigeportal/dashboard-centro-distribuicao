# Manual de Uso da API Central

Este manual descreve os fluxos principais para integrar o Dashboard e a API Local com a API Central.

## Convencoes

Base URL de exemplo:

```text
http://localhost:3333
```

Todos os endpoints usam o prefixo:

```text
/v1
```

CPF e CNPJ podem ser enviados com mascara, mas a API normaliza internamente para apenas numeros.

## 1. Cadastro de Cliente

Use este endpoint quando um usuario do Dashboard criar uma conta.

Endpoint:

```http
POST /v1/register
```

Body:

```json
{
  "nome": "Joao Silva",
  "cpf": "123.456.789-09",
  "password": "senha123"
}
```

Resposta esperada:

```json
{
  "id": "1",
  "nome": "Joao Silva",
  "cpf": "12345678909",
  "plano": 0
}
```

Observacoes:

- A confirmacao de senha deve ser validada pelo Dashboard.
- A API nunca salva a senha crua.
- O plano inicial e sempre `0`.

## 2. Login do Cliente

Endpoint:

```http
POST /v1/login
```

Body:

```json
{
  "cpf": "123.456.789-09",
  "password": "senha123"
}
```

Resposta:

```json
{
  "access_token": "...",
  "refresh_token": "..."
}
```

Use o `access_token` nas rotas autenticadas:

```http
Authorization: Bearer <access_token>
```

## 3. Renovar Token

Endpoint:

```http
POST /v1/refresh-token
```

Body:

```json
{
  "refresh_token": "..."
}
```

Resposta:

```json
{
  "access_token": "..."
}
```

## 4. Alterar Senha do Cliente

Endpoint:

```http
POST /v1/update-password
```

Headers:

```http
Authorization: Bearer <access_token>
```

Body:

```json
{
  "old_password": "senhaAtual",
  "new_password": "novaSenha"
}
```

Resposta:

```json
{
  "status": "Senha alterada com sucesso"
}
```

## 5. Atualizar URL da Empresa

Este endpoint e usado pela API Local.

Endpoint:

```http
POST /v1/update-url
```

Body:

```json
{
  "cnpj": "12.345.678/0001-90",
  "url": "https://empresa.ngrok.app/v1",
  "timestamp": "2026-07-10T10:00:00Z",
  "assinatura": "..."
}
```

Como montar a assinatura:

```text
cnpj_normalizado + url + timestamp
```

Chave do HMAC:

```text
cnpj_normalizado
```

Resposta se a empresa existir:

```json
{
  "status": "URL atualizada com sucesso"
}
```

Resposta se a empresa nao existir:

```json
{
  "error": "Empresa nao cadastrada"
}
```

Nesse caso, a API Local deve chamar o autocadastro.

## 6. Autocadastrar Empresa

Este endpoint deve ser chamado somente quando `POST /v1/update-url` retornar `404`.

Endpoint:

```http
POST /v1/companies/self-register
```

Body:

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

Como montar a assinatura:

```text
cnpj_normalizado + nome + url + claim + timestamp
```

Chave do HMAC:

```text
cnpj_normalizado
```

Resposta:

```json
{
  "id": "1",
  "cnpj": "12345678000190",
  "nome": "Empresa A",
  "url": "https://empresa.ngrok.app/v1"
}
```

Importante:

- O claim nao deve ser enviado em todo heartbeat.
- O claim e salvo apenas como hash em `EMP_CLAIMHASH`.
- A empresa autocadastrada ainda nao fica vinculada a nenhum cliente.

## 7. Vincular Empresa ao Cliente

Este endpoint e usado pelo Dashboard depois que o cliente esta autenticado.

Endpoint:

```http
POST /v1/companies/link
```

Headers:

```http
Authorization: Bearer <access_token>
```

Body:

```json
{
  "cnpj": "12.345.678/0001-90",
  "claim": "CODIGO-CLAIM-DA-EMPRESA"
}
```

Resposta:

```json
{
  "empresa_id": "1",
  "cnpj": "12345678000190"
}
```

Erros comuns:

- `401`: claim incorreto ou token invalido.
- `404`: empresa ainda nao cadastrada.
- `409`: empresa ja vinculada a este cliente.

## 8. Fluxo Completo da API Local

1. A API Local descobre sua URL publica atual.
2. A API Local chama `POST /v1/update-url`.
3. Se receber `200`, terminou.
4. Se receber `404`, chama `POST /v1/companies/self-register`.
5. Nos proximos ciclos, volta a chamar apenas `POST /v1/update-url`.

## 9. Fluxo Completo do Dashboard

1. Cliente cria conta em `POST /v1/register`.
2. Cliente faz login em `POST /v1/login`.
3. Dashboard guarda `access_token` e `refresh_token`.
4. Cliente informa CNPJ e claim da empresa.
5. Dashboard chama `POST /v1/companies/link`.
6. Rotas autenticadas usam `Authorization: Bearer <access_token>`.

## 10. Health Check

Endpoint:

```http
GET /v1/ping
```

Resposta:

```text
Pong
```
