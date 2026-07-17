# Clean Architecture — Reference

> Based on "Clean Architecture" by Robert C. Martin. This file rewrites the principles as actionable instructions, not as a reading summary.

## Table of Contents
1. Dependency Rule
2. SOLID Principles (applied to architecture)
3. Component Principles
4. The layers: Entities, Use Cases, Interface Adapters, Frameworks & Drivers
5. Boundaries and Humble Object
6. Common mistakes

---

## 1. Dependency Rule

**Definition**: source code dependencies can only point inward — an inner layer (policy, business rule) may never import, reference, or know anything about an outer layer (technical detail).

**When to apply**: always. It's the foundational rule; everything else in Clean Architecture exists to support it.

**Signs of violation**:
- A domain class imports an ORM, an HTTP client, or a UI library.
- A business rule needs to know the response format of an external API.
- Switching databases or frameworks requires changing domain code.

**How to fix**: invert the dependency with an interface defined in the inner layer, implemented in the outer layer (Dependency Inversion Principle).

**Example of correct structure:**
```java
// CORRECT: the interface is defined in the domain (inside).
package domain.repository;
public interface OrderRepository { void save(Order order); }

// The concrete implementation lives in infrastructure (outside), and depends on the domain — never the other way around.
package infrastructure.database;
import domain.repository.OrderRepository;
public class SqlOrderRepository implements OrderRepository { ... }
```

## 2. SOLID Principles (applied to architecture)

A prerequisite for everything that follows — the component principles (section 3) are SOLID applied at package/module scale.

- **SRP (Single Responsibility)**: a module should have a single reason to change — usually tied to a single actor/stakeholder, not "one function only."
- **OCP (Open-Closed)**: it should be possible to extend behavior without modifying existing code — typically via new classes implementing an interface, not editing the original class.
- **LSP (Liskov Substitution)**: subtypes must be substitutable for their base type without breaking the behavior expected by the consumer.
- **ISP (Interface Segregation)**: don't force a client to depend on methods it doesn't use — prefer smaller, specific interfaces.
- **DIP (Dependency Inversion)**: high-level modules should not depend on low-level modules; both should depend on abstractions. **This is the principle that makes the Dependency Rule possible in practice.**

## 3. Component Principles

Rules for packaging classes into cohesive components/modules with healthy coupling.

**Cohesion** (what should stay together):
- REP (Reuse/Release Equivalence): the granularity of reuse is the granularity of release — a component should be versionable as a unit.
- CCP (Common Closure): group classes that change for the same reasons, in the same release.
- CRP (Common Reuse): don't force a client to depend on things it doesn't reuse.

**Coupling** (how components relate to each other):
- ADP (Acyclic Dependencies): the dependency graph between components must not have cycles.
- SDP (Stable Dependencies): depend in the direction of stability — volatile components should depend on stable components, not the reverse.
- SAP (Stable Abstractions): a stable component should be abstract, so it doesn't lock down the system's evolution.

## 4. The layers

From center to edge:

- **Entities**: the enterprise's most critical and general business rules — independent of any specific application. The ones that change least.
- **Use Cases**: application-specific business rules; they orchestrate the flow of data to/from Entities to accomplish a user's goal. They change when the system's operational details change, but not when the UI or database changes.
- **Interface Adapters**: converters — controllers, presenters, gateways. They translate data from the format convenient for Use Cases/Entities to the format convenient for frameworks and the database (and vice versa).
- **Frameworks & Drivers**: the outermost layer — database, web framework, UI, devices. Everything here is a "detail" and should be replaceable without touching the inner layers.

Practical rule: at any layer crossing, the inner side must never know the name of any class on the outer side.

## 5. Boundaries and Humble Object

- **Boundaries**: crossing points between layers, implemented as interfaces defined on the inner side (Ports) and implemented on the outer side (Adapters).
- **Humble Object**: when a part of the system is hard to test (e.g., code that depends on UI or infrastructure), split it into two: a "humble" part that only does the hard-to-test integration (and is kept trivial enough not to need robust unit testing), and another part that holds all the testable logic, isolated from the external dependency.
- **Practical application of Humble Object at Boundaries**: a Controller receives the request and passes it through an `InputBoundary` to the Use Case Interactor; the Interactor returns the result through an `OutputBoundary` to a Presenter, which formats the data for the View. None of these edge pieces (Controller, Presenter, View) should contain business rules — they only translate format.

## 6. Common mistakes

- Confusing "layer" with "folder" — organizing directories as `controllers/`, `services/`, `models/` without ensuring dependencies actually point inward is not Clean Architecture, it's just naming.
- Putting business rule validation in a Controller or a framework DTO.
- Letting a Use Case return an ORM entity or a framework response object directly.
- Rigidly and literally applying all 4 layers to every small project — the number of layers is a consequence of system complexity, not a mandatory checklist.
- **Relaxed Layered Architecture**: letting Controllers access Repositories directly, skipping the Use Case "for convenience" — this destroys the business rule isolation the architecture exists to protect.
- **Data Model Leakage**: designing the Entity with the database table in mind (columns, column types) instead of thinking about the domain model first.
- **Polluting the domain with framework annotations**: using `@Autowired`, `@Entity`, `@Table`, or equivalents directly on Entity/Use Case classes. Even though it seems harmless, this couples the core to a specific dependency-injection or persistence framework.
