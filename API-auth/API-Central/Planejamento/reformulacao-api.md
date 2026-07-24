# Planejamento da Reformulacao da API Central

## Objetivo

Reformular a API Central para separar a autenticacao de clientes da gestao de empresas.

Antes, a API trabalhava com uma tabela unica, onde a empresa tambem funcionava como usuario autenticavel. A nova arquitetura passa a ter entidades separadas:

- Cliente: pessoa/usuario que acessa o dashboard.
- Empresa: empresa sincronizada pela API Local e vinculavel a um ou mais clientes.
- Cliente_Empresa: tabela intermediaria para representar vinculos entre clientes e empresas.

## Modelo de Dados Alinhado

### CLIENTE

Representa o usuario do dashboard.

Campos principais:

- `CLI_ID`: identificador interno do cliente.
- `CLI_CPF`: CPF usado no login.
- `CLI_SALT`: salt gerado pela API.
- `CLI_PASSWORDHASH`: hash da senha gerado pela API.
- `CLI_NOME`: nome do cliente.
- `CLI_PLANO`: plano do cliente.

Regras:

- O login sera feito por CPF e senha.
- A senha nunca deve ser salva em texto puro.
- A API deve gerar salt e password hash.
- Novo cliente inicia com `CLI_PLANO = 0`.
- CPF deve ser unico.
- `CLI_ID` deve ser gerado por generator e trigger do Firebird.

### EMPRESA

Representa a empresa que possui API Local e pode ser acessada pelo dashboard.

Campos principais:

- `EMP_ID`: identificador interno da empresa.
- `EMP_CNPJ`: CNPJ da empresa.
- `EMP_URL`: URL atual da API Local.
- `EMP_NOME`: nome da empresa.
- `EMP_CLAIMHASH`: hash do codigo claim usado para validar vinculo.

Regras:

- `EMP_CID` foi removido da tabela `EMPRESA`.
- A empresa nao possui mais senha.
- A empresa nao e mais o usuario autenticavel da API.
- O vinculo com clientes fica na tabela intermediaria.
- `EMP_ESTADO` nao faz mais parte do modelo.
- `EMP_ID` deve ser gerado por generator e trigger do Firebird.

### CLIENTE_EMPRESA

Representa o vinculo entre clientes e empresas.

Essa tabela permite relacionamento muitos-para-muitos:

- Um cliente pode possuir/acessar varias empresas.
- Uma empresa pode possuir/acessar varios clientes.

Campos esperados:

- `CE_ID`: identificador interno do vinculo.
- `CE_CLI_ID`: cliente vinculado.
- `CE_EMP_ID`: empresa vinculada.

Regras:

- Deve existir uma constraint unica para impedir vinculo duplicado entre o mesmo cliente e a mesma empresa.
- A empresa poder estar vinculada a outro cliente nao impede novo vinculo.
- O claim correto continua sendo necessario para criar o vinculo.
- `CE_ID` deve ser gerado por generator e trigger do Firebird.

## Rotas Alinhadas

### POST /v1/register

Cria um novo cliente.

Entrada:

```json
{
  "nome": "Joao Silva",
  "cpf": "123.456.789-00",
  "password": "senha123"
}
```

Regras:

- Nome obrigatorio.
- CPF obrigatorio e unico.
- Senha obrigatoria.
- Confirmacao de senha deve ser tratada pelo dashboard, nao pela API.
- API gera `CLI_SALT`.
- API gera `CLI_PASSWORDHASH`.
- Cliente inicia com `CLI_PLANO = 0`.

### POST /v1/login

Autentica o cliente por CPF e senha.

Entrada:

```json
{
  "cpf": "123.456.789-00",
  "password": "senha123"
}
```

Resposta esperada:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "cliente": {
    "id": 1,
    "nome": "Joao Silva",
    "cpf": "123.456.789-00",
    "plano": 0
  },
  "empresas": [
    {
      "id": 10,
      "cnpj": "12.345.678/0001-90",
      "nome": "Empresa A",
      "url": "https://empresa-a.ngrok.app/v1"
    }
  ]
}
```

Regras:

- O token deve usar `CLI_ID` como subject.
- A resposta deve trazer a lista de empresas vinculadas ao cliente.
- A lista deve ser obtida pelo vinculo em `CLIENTE_EMPRESA`.

### POST /v1/refresh-token

Gera um novo access token a partir de um refresh token valido.

Regras:

- O refresh token deve continuar referenciando o cliente, usando `CLI_ID`.
- O novo access token tambem deve ser emitido para o cliente.

### POST /v1/update-password

Altera a senha do cliente autenticado.

Entrada:

```json
{
  "old_password": "senhaAtual",
  "new_password": "novaSenha"
}
```

Regras:

- Deve exigir JWT.
- Nao deve receber CPF no corpo.
- Nao deve exigir `confirm_password`.
- A API deve pegar o `CLI_ID` do JWT.
- Deve validar a senha antiga.
- Deve gerar novo salt e novo password hash.
- Deve atualizar a senha na tabela `CLIENTE`.

### POST /v1/companies/link

Vincula uma empresa existente ao cliente autenticado.

Entrada:

```json
{
  "cnpj": "12.345.678/0001-90",
  "claim": "CODIGO-CLAIM-DA-EMPRESA"
}
```

Regras:

- Deve exigir JWT.
- A API deve pegar o `CLI_ID` do JWT.
- Deve buscar a empresa pelo CNPJ.
- A empresa deve existir.
- Deve validar o claim informado contra `EMP_CLAIMHASH`.
- Deve verificar se o cliente ainda nao esta vinculado aquela empresa.
- Deve criar o vinculo na tabela `CLIENTE_EMPRESA`.
- Nao deve bloquear o vinculo apenas porque a empresa ja possui outro cliente vinculado.

### POST /v1/update-url

Atualiza a URL da empresa ja cadastrada.

Entrada:

```json
{
  "cnpj": "12345678000190",
  "url": "https://empresa.ngrok.app/v1",
  "timestamp": "2026-07-10T10:00:00Z",
  "assinatura": "..."
}
```

Regras:

- Nao deve realizar autocadastro.
- Deve validar CNPJ.
- Deve validar assinatura HMAC.
- Deve buscar a empresa pelo CNPJ.
- Se a empresa existir, atualiza `EMP_URL`.
- Se a empresa nao existir, retorna `404 Not Found`.

### POST /v1/companies/self-register

Autocadastra uma empresa na API Central.

Essa rota substitui a gambiarra de autocadastro que existia dentro de `update-url`.

Entrada:

```json
{
  "cnpj": "12345678000190",
  "nome": "Empresa A",
  "url": "https://empresa.ngrok.app/v1",
  "claim": "CODIGO-CLAIM-DA-EMPRESA",
  "timestamp": "2026-07-10T10:00:00Z",
  "assinatura": "..."
}
```

Regras:

- Deve validar CNPJ.
- Deve validar assinatura HMAC.
- Se a empresa ja existir, deve retornar conflito ou status equivalente.
- Se a empresa nao existir, deve criar a empresa.
- Deve salvar `EMP_CLAIMHASH`, nao o claim em texto puro.
- A empresa criada por autocadastro ainda nao fica vinculada a nenhum cliente; o vinculo ocorre depois em `/v1/companies/link`.

## Fluxo da API Local

O fluxo combinado para a API Local e:

1. Tentar primeiro `POST /v1/update-url`.
2. Se retornar `200`, a empresa ja existe e a URL foi atualizada.
3. Se retornar `404 Not Found`, a empresa ainda nao existe na API Central.
4. Somente nesse caso chamar `POST /v1/companies/self-register`.
5. Depois do autocadastro, os proximos envios passam a usar apenas `update-url`.

Motivo:

- Evita enviar dados sensiveis, como claim, em toda requisicao.
- O claim so trafega quando a empresa ainda precisa ser cadastrada.
- O fluxo comum fica restrito a CNPJ, URL e assinatura.

## Timestamp

Foi decidido manter `timestamp` nas rotas assinadas neste momento.

Motivo:

- A API Local ja consegue enviar esse campo junto com os dados assinados.
- Ele aumenta o contexto da assinatura e pode ajudar em validacoes futuras.

Cuidados:

- O timestamp deve ser enviado em UTC sempre que possivel.
- Se houver problema de fuso horario ou relogio entre servidores, a validacao pode ser revista.

Observacao futura:

- Caso o timestamp cause falso erro de requisicao invalida, pode ser avaliado uso de `nonce`, contador, token por empresa ou timestamp em UTC com tolerancia bem definida.

## Assinaturas HMAC

### update-url

A assinatura deve considerar os principais dados da requisicao.

Sugestao:

```text
cnpj + url + timestamp
```

### companies/self-register

A assinatura deve proteger tambem os dados sensiveis do cadastro.

Sugestao:

```text
cnpj + nome + url + claim + timestamp
```

## Claim

O claim e o codigo que permite comprovar que o cliente tem direito de vincular uma empresa.

Regras:

- O claim pode trafegar no autocadastro da empresa.
- O claim pode trafegar na rota de vinculo.
- O claim nao deve ser salvo em texto puro.
- A API deve salvar apenas `EMP_CLAIMHASH`.
- Na vinculacao, a API compara o claim informado com o hash salvo.

## Autorizacao do Dashboard

Para uma empresa aparecer no login e ser usada no dashboard, o cliente deve
estar vinculado a ela em `CLIENTE_EMPRESA`.

Em rotas futuras que recebam uma empresa especifica, a API tambem deve validar:

- O cliente autenticado possui vinculo com a empresa.

## Plano de Implementacao

1. Criar models separados para `CLIENTE`, `EMPRESA` e `CLIENTE_EMPRESA`.
2. Remover dependencia da tabela antiga `USERS`.
3. Adaptar autenticacao para CPF e senha do cliente.
4. Adaptar tokens para usarem `CLI_ID` como subject.
5. Criar registro de cliente em `/v1/register`.
6. Alterar login para retornar dados do cliente e empresas vinculadas.
7. Alterar `update-password` para exigir JWT e atualizar senha do cliente autenticado.
8. Refatorar `update-url` para somente atualizar empresa existente.
9. Criar `/v1/companies/self-register` para autocadastro de empresa.
10. Criar `/v1/companies/link` para vinculo cliente-empresa.
11. Atualizar Swagger e README com o novo contrato.
12. Testar os fluxos principais manualmente.

## Casos de Teste Principais

- Registrar cliente com sucesso.
- Bloquear registro com CPF duplicado.
- Validar confirmacao de senha no Dashboard antes de chamar o registro.
- Login com CPF e senha validos.
- Login deve retornar apenas empresas vinculadas ao cliente.
- Trocar senha autenticado via JWT.
- Bloquear troca de senha com senha antiga invalida.
- Atualizar URL de empresa existente.
- Retornar `404` no `update-url` quando empresa nao existir.
- Autocadastrar empresa via `companies/self-register`.
- Bloquear autocadastro de CNPJ ja existente.
- Vincular empresa ao cliente via claim correto.
- Bloquear vinculo com claim incorreto.
- Bloquear vinculo duplicado entre o mesmo cliente e a mesma empresa.
- Permitir que uma empresa seja vinculada a mais de um cliente.
