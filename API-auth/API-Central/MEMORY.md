# Memória do Projeto: API-Central

## Restrições Técnicas
- **Versão do Delphi:** 10.2 (Tokyo). 
    - *Nota:* Evitar o uso de recursos de linguagem introduzidos em versões posteriores (como Inline Variables do 10.3+).
- **Framework Web:** Horse.
- **Banco de Dados:** Firebird.

## Decisões Arquiteturais
- **Segurança:** Fail-fast na inicialização se `SECRET_KEY` estiver ausente.
- **Versionamento:** Todas as rotas públicas devem estar sob o prefixo `/v1`.
- **Auditoria:** Logs de requisições salvos em arquivos `.log` diários.