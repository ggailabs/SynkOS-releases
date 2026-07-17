# Domain-Driven Design — Reference

> Based on "Implementing Domain-Driven Design" by Vaughn Vernon. This file rewrites the patterns as actionable instructions, not as a reading summary.

## Table of Contents
1. Strategic DDD: Subdomains, Bounded Context, Ubiquitous Language, Context Maps
2. Tactical DDD: Entities vs Value Objects
3. Domain Services
4. Domain Events
5. Aggregates
6. Factories and Repositories
7. Application Services (application layer)
8. Common mistakes

---

## 1. Strategic DDD — a prerequisite before any tactics

**Subdomain classification (where to invest modeling effort)**:
- **Core Domain**: where the business competes and differentiates itself. Deserves maximum modeling investment — full tactical DDD (rich Aggregates, Domain Events, careful language), the best developers, the most design attention.
- **Supporting Subdomain**: necessary for the business but not a differentiator. Custom-built, but with simpler modeling — don't over-invest.
- **Generic Subdomain**: a solved problem (authentication, email delivery, invoicing). Buy it, use an off-the-shelf solution, or implement it as plain CRUD — rich domain modeling here is wasted effort.

**Practical rule**: apply the full weight of tactical DDD only to the Core Domain. Applying rich Aggregates and Domain Events uniformly to everything — including generic subdomains — is a resource-allocation mistake, not thoroughness. Before modeling anything, ask: "is this Core, Supporting, or Generic?"

**Bounded Context**: an explicit linguistic and semantic boundary within which a specific domain model is valid and has exact meaning. The same term ("Customer", "Order") can mean different things in different contexts — this is expected and correct, not a naming bug.

**Ubiquitous Language**: the shared vocabulary between developers and business experts, used both in conversation and in code, within a Bounded Context. If the team speaks one way and the code names things another way, the language isn't actually being applied.

**Context Map**: a diagram/document showing how multiple Bounded Contexts relate to each other (e.g., Shared Kernel, Customer-Supplier, Anticorruption Layer, Conformist). Necessary before designing any integration between contexts.

**Most common relationship patterns in a Context Map**:
- **Partnership**: two teams coordinate closely, evolving the contexts together.
- **Shared Kernel**: part of the model is deliberately shared between two contexts — reduces duplication but increases coupling; use sparingly.
- **Customer-Supplier**: one context (supplier) serves the needs of another (customer), with defined priority between the teams.
- **Conformist**: the downstream context simply accepts the upstream model without translation, usually because there's no negotiating power.
- **Anticorruption Layer (ACL)**: when the external model is incompatible, poorly built, or outside your control, insert a translation layer that converts foreign objects into your own model before they enter your Bounded Context. This is the standard defense against third-party model "leakage" into your domain.

**When to apply a Context Map**: whenever two or more Bounded Contexts need to communicate — the map forces an explicit decision about what kind of power and translation relationship exists between them, instead of leaving it implicit in the code.

**When to apply**: always before any tactical pattern below. Applying Aggregates or Value Objects without first defining the Bounded Context is the anti-pattern known as "DDD-Lite" — using the tactical vocabulary without the strategic benefit of model isolation.

## 2. Entities vs Value Objects

**Entity**: has its own identity that persists over time, even if its attributes change. Two Entities with the same attributes are still different if they have different identities.

**Value Object**: defined entirely by its attributes, with no identity of its own. Two Value Objects with the same attributes are interchangeable. **Must be immutable** — any "change" creates a new Value Object.

**Decision guide**: ask "do I need to track this over time, even as its values change?" — if yes, Entity. If the object only describes a characteristic or a measurement (money, address, date range), it's a Value Object.

**Most common mistake from the book**: modeling almost everything as an Entity out of habit, losing the simplicity and immutability safety that Value Objects would provide.

**Minimal Value Object example:**
```java
// Immutable, defined by attributes, self-validating. No identity, no setters.
public final class Money {
    private final BigDecimal amount;
    private final Currency currency;

    public Money(BigDecimal amount, Currency currency) {
        if (amount.compareTo(BigDecimal.ZERO) < 0)
            throw new IllegalArgumentException("Amount cannot be negative");
        this.amount = amount;
        this.currency = currency;
    }

    public Money add(Money other) {
        requireSameCurrency(other);
        return new Money(this.amount.add(other.amount), this.currency); // returns a NEW object — never mutates
    }
}
```

## 3. Domain Services

Use when a meaningful domain operation doesn't naturally belong to any specific Entity or Value Object — usually because it involves more than one domain object or represents a process, not a thing.

**Sign you need one**: the method you want to write doesn't seem to belong to any existing class without forcing an unnatural responsibility onto it.

**Caution**: a Domain Service is not where application logic (orchestration, transactions, external calls) goes — that's an Application Service (section 7). A Domain Service is still pure domain rule.

**Additional caution**: don't use Domain Services for simple CRUD operations that would naturally fit inside an Aggregate — overusing this pattern tends to drain behavior out of domain objects and push the design toward an Anemic Domain Model (see common mistakes section).

## 4. Domain Events

Represent something meaningful that happened in the domain (e.g., "OrderConfirmed"). Used to propagate consequences asynchronously, including across different Bounded Contexts, maintaining eventual consistency instead of distributed transactions.

**When to model a Domain Event**: when a state change needs to trigger a reaction in another Aggregate or Bounded Context, and that reaction doesn't need to be synchronous/immediate.

**Minimum structure**: a past-tense name (it already happened), a timestamp, the identifier of the originating Aggregate, and the relevant data — not the entire domain object.

## 5. Aggregates

**Definition**: a cluster of Entities and Value Objects treated as a single transactional consistency unit, with a single Entity designated as the **Aggregate Root**.

**Golden rules**:
- Every external reference to the Aggregate goes through the Root — no internal object is accessed or modified directly from outside.
- A transaction should modify, at most, one Aggregate at a time.
- Aggregates should be **small** — prefer referencing other Aggregates by identity (ID), not by full object.
- Consistency between multiple Aggregates is **eventual**, not transactional — use Domain Events to propagate it.

**Prerequisite**: understand Entity vs Value Object well (section 2) before designing Aggregates — deciding poorly what's an Entity inside the Aggregate breaks the consistency boundary.

**Minimal Aggregate Root example:**
```java
// External code never touches OrderItem directly — every change goes through the Root,
// which is where the invariants are enforced.
public class Order {
    private final OrderId id;
    private final List<OrderItem> items = new ArrayList<>();
    private OrderStatus status;

    public void addItem(ProductId productId, int quantity, Money unitPrice) {
        if (status != OrderStatus.DRAFT)
            throw new DomainException("Cannot modify a confirmed order"); // invariant lives here
        items.add(new OrderItem(productId, quantity, unitPrice));
    }

    public List<OrderItem> items() {
        return List.copyOf(items); // read-only view — internal collection is never exposed for mutation
    }
}
```

## 6. Factories and Repositories

**Factory**: encapsulates the creation of complex Entities/Aggregates, ensuring the object is born in a valid and complete state — prevents construction logic from leaking outside the domain.

**Repository**: gives the illusion of an in-memory collection for accessing and persisting Aggregates, hiding database details. The Repository interface lives in the domain layer; the concrete implementation is an external detail (the same Dependency Inversion principle from Clean Architecture).

**Practical rule**: a Repository works with whole Aggregates, never with internal fragments of them.

## 7. Application Services (application layer)

Orchestrate use cases: receive a command, load the Aggregate(s) via Repository, invoke domain behavior, and persist the result. **They contain no business rules** — only coordination.

**Sign of violation**: if an Application Service has conditional logic based on a business rule (not on orchestration flow), that logic should live in the Aggregate or in a Domain Service.

## 8. Common mistakes

- Jumping straight to Aggregates/Repositories without first defining Bounded Context and ubiquitous language ("DDD-Lite").
- Aggregates that are too large, referencing other Aggregates by full object instead of by ID — this hurts performance and breaks the transactional boundary.
- Putting business logic in the Application Service layer.
- Modifying an Aggregate's internal objects directly, without going through the Root.
- Using an Entity where a Value Object would solve it with less complexity and more safety (unnecessary mutability).
- **Anemic Domain Model**: domain classes reduced to getters/setters with no behavior — all logic migrates to external "services," hollowing out the purpose of the domain model. It's a fatal anti-pattern, often disguised as "good separation of concerns."
- **Modifying multiple Aggregates in a single transaction**: if a use case seems to require this, either the Aggregate design is wrong (they should be one), or consistency between them should be eventual, via Domain Events — not transactional.
- **Big Ball of Mud between subdomains**: mixing two distinct subdomains (e.g., authentication and billing) inside the same Bounded Context, without clear linguistic separation, producing a tangled model where changes in one area break the other.
