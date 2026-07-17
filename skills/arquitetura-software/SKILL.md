---
name: software-architecture-clean-ddd
description: Guide for designing, reviewing, or refactoring software architecture applying Clean Architecture (Robert C. Martin) and Domain-Driven Design (Vaughn Vernon). ALWAYS use when the user mentions architecture layers, dependency rule, separation of concerns, decoupling from framework/database, bounded context, aggregates, entities vs value objects, ubiquitous language, domain events, repositories, or asks to review/design/critique a system's architecture — even if they don't explicitly say "clean architecture" or "DDD". Also use when the user asks where to place a business rule, how to isolate an external integration, or how to model a complex domain.
---

# Software Architecture: Clean Architecture & DDD

This skill combines two complementary bodies of knowledge:

- **Clean Architecture** — how to organize code into layers so business rules don't depend on technical details (framework, database, UI).
- **Domain-Driven Design (DDD)** — how to model the business domain itself: its language, its boundaries, and its tactical implementation rules.

They answer different questions: Clean Architecture organizes **where** code lives and **which direction** dependencies point. DDD defines **what** belongs inside the domain core and **how** to bound it. In practice, almost every non-trivial system ends up combining both.

## Decision table — which reference to consult

| If the question is about... | Consult |
|---|---|
| Layers, dependency direction, isolating framework/database/UI, SOLID applied to architecture, component packaging | `references/clean-architecture.md` |
| Domain modeling, business language, boundaries between subsystems, Entity vs Value Object, Aggregates, Domain Events, Repositories | `references/domain-driven-design.md` |
| Where an Aggregate fits within the layers, or any friction point between the two models | The "Integration" section below, in this file |

## How to use this skill

1. Identify whether the question is structural (layers/dependencies) or modeling-related (domain/language). Use the table above.
2. Read the corresponding reference before proposing a solution — don't answer from memory about the tactical patterns; they have specific naming and boundary rules that are easy to get wrong by approximation.
3. If the user asks for a review of existing code/design, look first for **Dependency Rule violations** (an inner reference depending on an outer detail) before any other critique — it's the most common and most expensive-to-fix-later mistake.
4. Whenever you suggest a structure, state the reasoning in terms of the underlying principle (e.g., "this violates SRP because..."), not just "this is more organized."

## Integration between Clean Architecture and DDD

The most common friction point: **where does an Aggregate live?**

- In Clean Architecture, the innermost layer ("Entities") holds critical, enterprise-wide business rules, independent of any specific application.
- In tactical DDD, an **Aggregate** is a transactional consistency boundary — an Aggregate Root plus the Entities and Value Objects it encapsulates, with the rule that changes outside the Aggregate only happen through its Root.
- In practice, the Aggregate Root and its internal members implement the Entities/Domain layer of Clean Architecture. The Dependency Rule is satisfied because the Aggregate doesn't know about Application Services, concrete Repositories, or infrastructure — it only exposes its behavior and is orchestrated from outside.
- **Common mistake**: treating each Entity inside an Aggregate as if it were, by itself, the Clean Architecture "Entity layer" — this breaks the Aggregate's consistency boundary and allows direct mutation of internal objects, violating the rule of single access through the Root.

Other points of overlap:

- **Use Cases (Clean Architecture) ≈ Application Services (DDD)**: both orchestrate; neither should contain business rules — only coordinate calls into the domain.
- **Repositories**: in both models, the repository interface lives in the domain/use case layer, and the concrete implementation (SQL, ORM) is isolated as an external detail — this is the Dependency Inversion Principle in action.
- **Bounded Contexts** typically define the boundaries between **multiple instances** of Clean Architecture — each Bounded Context can have its own independent layer stack, communicating via events or APIs, never sharing a domain model directly.

### Reference directory layout (one Bounded Context containing the Clean Architecture layers)

```
src/
└── billing/                          # Bounded Context (DDD strategic boundary)
    ├── domain/                       # Entities layer (Clean Architecture core)
    │   ├── model/                    #   Aggregates, Entities, Value Objects
    │   │   ├── Order.java            #   Aggregate Root
    │   │   ├── OrderItem.java        #   internal Entity (only reachable via Root)
    │   │   └── Money.java            #   Value Object
    │   ├── events/                   #   Domain Events
    │   ├── services/                 #   Domain Services (pure domain logic)
    │   └── repository/               #   Repository INTERFACES only
    ├── application/                  # Use Cases / Application Services (orchestration, no business rules)
    │   └── PlaceOrderUseCase.java
    ├── adapters/                     # Interface Adapters
    │   ├── in/rest/                  #   Controllers (input)
    │   └── out/persistence/          #   Repository implementations (output)
    └── infrastructure/               # Frameworks & Drivers (framework config, wiring)
```

This layout is illustrative — what matters is the **direction of dependencies** (everything points toward `domain/`), not the folder names. A project can use different names and still be correct, or use these exact names and still violate the Dependency Rule (see "common mistakes" in the Clean Architecture reference).

If the user is designing a system from scratch, recommend starting with the strategic side of DDD (subdomain classification, Bounded Contexts, ubiquitous language) before applying Clean Architecture's layers within each context — deciding on a layered architecture before understanding domain boundaries tends to produce over-engineering.
