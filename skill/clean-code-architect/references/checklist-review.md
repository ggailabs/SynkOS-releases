# Checklist de Code Review Express

Use quando o usuário pedir análise rápida sem refatoração completa.
Responda com ✅ (ok) ou ⚠️ (problema encontrado) + breve justificativa.

## Legibilidade
- [ ] Nomes de variáveis/funções são autoexplicativos?
- [ ] Funções têm menos de 20 linhas?
- [ ] Comentários explicam o *porquê*, não o *o quê*?
- [ ] Não há "números mágicos" sem constante nomeada?

## KISS
- [ ] Lógica condicional com no máximo 3 níveis de aninhamento?
- [ ] Nenhuma abstração desnecessária para o problema em questão?

## DRY
- [ ] Zero duplicação de regras de negócio ou cálculos?
- [ ] Constantes e configurações em um único local?

## YAGNI
- [ ] Nenhum método/função sem chamador no código atual?
- [ ] Sem flags/parâmetros opcionais não utilizados?

## TDA
- [ ] Objetos encapsulam suas próprias decisões?
- [ ] Nenhum getter sendo usado externamente para lógica de negócio?

## SOLID
- [ ] (S) Cada classe tem uma única responsabilidade?
- [ ] (O) Novos tipos adicionados por extensão, não modificação?
- [ ] (L) Subclasses substituíveis sem surpresas?
- [ ] (I) Interfaces pequenas e focadas?
- [ ] (D) Dependências injetadas via abstração?

## Testabilidade
- [ ] É possível testar a função/classe em isolamento?
- [ ] Efeitos colaterais estão isolados e explícitos?

---

**Score sugerido:**
- 0-3 ⚠️: Refatoração urgente
- 4-7 ⚠️: Refatoração recomendada
- 8-11 ⚠️: Ajustes pontuais
- 12+ ✅: Código saudável (aponte o que poderia ser ainda melhor)
