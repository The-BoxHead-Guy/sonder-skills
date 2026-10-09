---
name: nodejs
description: Node.js backend development — framework selection, architecture, async patterns, error handling, security, validation, and production patterns. Use when building or reviewing Node.js services, REST/GraphQL APIs, microservices, or middleware.
---

# Node.js

Single entry point for Node.js backend work. Two deep references carry the detail; read the one that matches the task.

> Principles over copy-paste: choose framework and patterns from the actual context (deployment target, team familiarity, existing code) instead of defaulting to the same stack every time.

## When to use

- Building or reviewing REST/GraphQL APIs, microservices, or WebSocket backends
- Choosing a framework (Hono / Fastify / Express / NestJS / Next.js / tRPC)
- Designing layers, middleware, error handling, auth, validation, or caching
- Production concerns: security, rate limiting, logging, graceful shutdown, connection pooling

## References

- [references/best-practices.md](references/best-practices.md) — decision-making: framework selection, runtime/module choices, architecture, error-handling philosophy, async/event-loop, validation, security checklist, testing strategy, anti-patterns, pre-implementation checklist.
- [references/backend-patterns.md](references/backend-patterns.md) — concrete code: Express/Fastify setup, layered controller/service/repository, auth + validation + rate-limit + logging middleware, custom error classes and global handler, database and API response patterns.
- [references/advanced-patterns.md](references/advanced-patterns.md) — advanced implementations: dependency-injection container, PostgreSQL/MongoDB/transaction patterns, JWT auth service, Redis caching + `@Cacheable`.

## Quick decisions

| Need | Start from |
|---|---|
| Pick a framework | best-practices.md → §1 Framework Selection |
| Structure an API | backend-patterns.md → Layered Architecture |
| Central error handling | backend-patterns.md → Custom Error Classes + Global Error Handler |
| Auth + validation | backend-patterns.md → Middleware Patterns |
| Async / event loop | best-practices.md → §5 Async Patterns |
| Security checklist | best-practices.md → §7 Security |
| DB / transactions / caching | advanced-patterns.md |
