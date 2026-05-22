# SynkOS Skill

**Skill de orquestração multi-agente para o SynkOS.** O SynkOS transforma uma sessão única do Claude num grid de painéis visíveis onde podes lançar agentes, delegar trabalho, executar modelos em paralelo e coordenar esquadrões especialistas — tudo sem sair do teu ambiente de desenvolvimento.

---

## O que é o SynkOS?

O SynkOS é uma camada de IDE multi-agente que expõe **ferramentas MCP** para orquestrar múltiplos agentes de IA em simultâneo. Cada sessão do Claude é um painel visível num grid de trabalho. Com ele podes:

- **Lançar novos painéis** e enviar-lhes tarefas independentes
- **Executar múltiplos modelos em paralelo** (Claude, Gemini, Codex, MIMO)
- **Coordenar esquadrões especialistas**
- **Acompanhar projetos com múltiplos marcos** através de uma lista de tarefas visível em tempo real

A ideia central: se uma tarefa é paralelizável, vai bloquear o painel atual por mais de 5 minutos, ou beneficia de modelos cognitivos diferentes em subtarefas distintas — o SynkOS torna essa orquestração explícita, visível e controlável.

---

## Estrutura do Repositório

```
synkos-skill/
├── SKILL.md                   # Skill principal — árvore de decisão e padrões base
└── references/
    ├── tools.md               # Referência completa das ferramentas de orquestração
    ├── recipes.md             # Exemplos práticos de orquestração do início ao fim
    ├── providers.md           # Guia de seleção de providers e modelos com matriz de trade-offs
    └── squads.md              # Esquadrões especialistas e padrões de ativação
```

`SKILL.md` é o ponto de entrada para o Claude Code. Os ficheiros de referência são carregados conforme necessário.

---

## As Ferramentas

| Ferramenta | Propósito | Quando usar |
|------------|-----------|-------------|
| `pane_list` | Descobrir painéis existentes e o seu estado | Antes de lançar — reutiliza painéis inativos sempre que possível |
| `pane_list_providers` | Listar providers de LLM configurados e os seus modelos | Antes de lançar qualquer painel com provider não predefinido |
| `pane_spawn` | Abrir um novo painel no grid de trabalho | Quando tens uma subtarefa paralelizável |
| `pane_write` | Enviar um prompt para um painel como se o tivesses digitado | Após lançar (ou para escrever num painel existente) |
| `pane_wait_idle` | Bloquear até o painel terminar | Sempre antes de ler — nunca leias um painel a correr |
| `pane_read` | Obter as últimas N linhas do output de um painel | Após `pane_wait_idle` confirmar que o painel terminou |
| `pane_set_identity` | Registar skill/role num painel | Ao lançar um painel para uma função específica |
| `pane_kill` | Matar um processo de painel | Limpeza quando um painel está preso ou não é mais necessário |
| `pane_open_browser` | Abrir um painel de navegador | Quando a tarefa precisa de interação web |
| `pane_open_terminal` | Abrir um terminal | Para comandos shell ou processos longos |
| `todo_manager` | Criar e atualizar uma lista de tarefas visível em tempo real | Projetos com 3 ou mais marcos distintos a nível de milestone |

Assinaturas completas, formatos de retorno e casos limite estão documentados em [`references/tools.md`](references/tools.md).

---

## Decisão Central: Quando Orquestrar

A maioria dos pedidos não precisa de orquestração. Por defeito, resolve tudo inline. Só recorre às ferramentas do SynkOS quando a tarefa satisfaz um destes critérios:

```
O trabalho é paralelizável?                  → lança painéis
Precisa de um modelo diferente?              → lança painel com esse modelo
Tem 3+ marcos distintos?                     → todo_manager
Vai bloquear este painel por mais de 5 min?  → lança painel, devolve controlo ao utilizador
O utilizador disse "em paralelo"?            → lança painéis, sem mais deliberação
Nenhuma das anteriores?                      → faz a tarefa inline
```

Lançar um painel custa ~5–10s de tempo de arranque, e o subpainel não tem memória da conversa atual. Se uma tarefa demora 2 minutos inline, delegar é mais lento.

---

## Os Três Padrões Principais

### Padrão A: Delegar ao Painel de Trabalho

Cada sessão de orquestrador tem um painel de trabalho pré-atribuído. O seu ID aparece no system prompt em `squadOrchestratorWorkerId`. Usa-o para trabalho de execução que bloquearia o orquestrador.

```
pane_write(paneId: <worker-id>, text: "<brief autossuficiente da tarefa>")
pane_wait_idle(paneId: <worker-id>, timeoutMs: 300000)
pane_read(paneId: <worker-id>, lastN: 200)
```

O worker não tem contexto da tua sessão. Faz o brief como se fosse um colega que acabou de entrar na sala: objetivo, ficheiros de entrada, output esperado, onde guardar, restrições.

**Verifica se o worker já existe antes de lançar um novo painel.** Chama `pane_list()` primeiro — o objeto do painel orquestrador tem um campo `squadOrchestratorWorkerId` que aponta diretamente para o painel certo.

---

### Padrão B: Fan-Out em Paralelo

Quando o trabalho se divide em N subtarefas independentes, lança N painéis e escreve para todos eles na **mesma turn**. Escrever sequencialmente (um painel por turn) elimina o paralelismo.

```
# Turn 1 — lançar e escrever na mesma turn (execução concorrente começa imediatamente)
a = pane_spawn(model: "claude-sonnet-4-6")
b = pane_spawn(model: "claude-sonnet-4-6")
pane_write(a, "<brief da tarefa A>")
pane_write(b, "<brief da tarefa B>")

# Turn 2 — esperar por ambos
pane_wait_idle(a, timeoutMs: 300000)
pane_wait_idle(b, timeoutMs: 300000)

# Turn 3 — ler ambos
pane_read(a, lastN: 200)
pane_read(b, lastN: 200)
```

Para outputs muito grandes, pede aos subpainéis que guardem em ficheiros e lê esses ficheiros com a ferramenta `Read` padrão — o buffer do painel tem limite de ~1000 linhas.

---

### Padrão C: Esquadrão Multi-Modelo

Modelos diferentes para trabalhos cognitivos diferentes na mesma tarefa. Por exemplo: Opus para crítica arquitetural (lento, raciocínio profundo), Sonnet para implementação (rápido, orientado à execução), Gemini para dados frescos da web.

**Chama sempre `pane_list_providers()` primeiro.** Os IDs dos providers são locais à máquina — variam entre instalações. Passar um ID desconhecido dá erro.

```
providers = pane_list_providers()
# verifica que gemini-cli, codex-cli, etc. estão presentes e anota os IDs exatos

opus    = pane_spawn(model: "claude-opus-4-7")
gemini  = pane_spawn(providerId: "gemini-cli", model: "gemini-2.5-flash")
mimo    = pane_spawn(providerId: "mimo-FxzXvc", model: "mimo-v2.5-pro")
```

---

## Providers e Seleção de Modelos

Guia completo em [`references/providers.md`](references/providers.md).

---

## todo_manager: Acompanhamento de Marcos

Usa `todo_manager` quando um projeto tem **3 ou mais tarefas distintas a nível de milestone**.

```
# Configura a lista de tarefas visível (máx. 7 tarefas)
todo_manager(action: "set_tasks", tasks: [
  "Atualizar schema da base de dados",
  "Refatorar rotas da API",
  "Atualizar handlers de webhooks",
  "Atualizar frontend",
  "Executar testes end-to-end"
])

# Avança a lista assim que cada marco termina
todo_manager(action: "move_to_task", moveToTask: "Refatorar rotas da API")

# Sinaliza o fim do projeto
todo_manager(action: "mark_all_done")
```

---

## Erros Comuns

1. **Ler antes de esperar** — `pane_read` num painel a correr devolve output parcial. Chama sempre `pane_wait_idle` primeiro.
2. **Fan-out sequencial** — múltiplas chamadas a `pane_write` têm de acontecer na mesma turn, não uma por turn.
3. **Briefs vagos para subpainéis** — os subpainéis não têm contexto da conversa atual.
4. **Lançar quando um worker já existe** — chama `pane_list()` primeiro.
5. **IDs de providers hardcoded** — chama sempre `pane_list_providers()` em tempo de execução.
6. **Todos em micro-passos** — `todo_manager` é para 3–7 milestones, não para cada ação.
7. **Acumular chamadas a `move_to_task`** — chama imediatamente quando cada milestone termina.
8. **Esquecer `pane_set_identity`** — marca o role/skill ao lançar painéis para workers.

---

## Quando NÃO Orquestrar

- Perguntas de conhecimento puro — responde inline
- Correções de bugs, refactors, edições de ficheiro único
- Qualquer coisa que uma resposta inline de dois minutos resolve

Em caso de dúvida, faz a tarefa diretamente.

---

## Aviso sobre o Painel de Trabalho

Podes ser o orquestrador, ou podes ser um painel de trabalho para o qual outro orquestrador está a delegar. Se o teu prompt inicial parece uma tarefa autossuficiente, és um worker — executa diretamente sem lançar mais painéis.
