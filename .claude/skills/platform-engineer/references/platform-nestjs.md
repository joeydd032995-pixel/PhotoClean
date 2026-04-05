# NestJS Architecture Patterns

## Module Organization

```typescript
// CORRECT: Feature-based modules with explicit exports
@Module({
  imports: [TypeOrmModule.forFeature([User]), SharedModule],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService]  // only export what other modules actually need
})
export class UsersModule {}
```

**Red flags:**
- Circular dependencies: ModuleA imports ModuleB imports ModuleA → use `forwardRef(() => ModuleB)` as last resort; usually signals the need to extract a shared module
- `SharedModule` that exports everything → becomes a grab-bag; split by domain
- Services accessed via `ModuleRef.get()` instead of proper DI

## DTO Validation

Every controller endpoint that accepts a body must use `class-validator` + `ValidationPipe`:

```typescript
// CORRECT
export class CreateBetDto {
  @IsString()
  @IsNotEmpty()
  marketId: string;

  @IsNumber()
  @Min(0.01)
  stake: number;

  @IsEnum(OddsFormat)
  oddsFormat: OddsFormat;
}

// MISSING validation — flag as 🟠 High
export class CreateBetDto {
  marketId: string;  // no decorators
  stake: number;
}
```

Global `ValidationPipe` in `main.ts`:
```typescript
app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }));
```
`whitelist: true` strips unknown properties (prevents mass assignment attacks).

## Error Handling

```typescript
// CORRECT
throw new NotFoundException(`Market #${id} not found`);
throw new BadRequestException('Stake must be positive');
throw new UnauthorizedException('Invalid token');

// WRONG — leaks internals, wrong status code
throw new Error('User not found');
```

Global exception filter should be present to:
1. Catch unhandled `Error` instances and return 500
2. Sanitize error messages in production (no stack traces to client)
3. Log errors with correlation IDs

## Prisma Patterns

**N+1 Queries:**
```typescript
// BAD — N+1
const markets = await prisma.market.findMany();
for (const m of markets) {
  m.odds = await prisma.odds.findMany({ where: { marketId: m.id } });
}

// GOOD — single query
const markets = await prisma.market.findMany({ include: { odds: true } });
```

**Over-fetching:**
```typescript
// BAD — selects all columns including blobs
const user = await prisma.user.findUnique({ where: { id } });

// GOOD — select only needed fields
const user = await prisma.user.findUnique({ where: { id }, select: { id: true, email: true, name: true } });
```

**Missing indexes:** Check `WHERE` clauses in queries against schema; if a field is filtered/sorted but not indexed, flag it:
```prisma
model Odds {
  marketId  String
  timestamp DateTime
  // if queries filter by marketId + timestamp, add:
  @@index([marketId, timestamp])
}
```

**Raw query safety:** `prisma.$queryRaw` with template literals is safe; string concatenation is SQL injection.

## Redis / Caching

- Every cached value must have a TTL — no `set(key, value)` without expiry
- Cache stampede risk: multiple requests hitting DB simultaneously when cache expires → use lock or stale-while-revalidate
- TTL must align with data freshness requirements (odds data: 30s max; user profile: 5 min OK)
- Cache keys must be namespaced to avoid collisions across modules: `odds:${marketId}:${format}`

## BullMQ Job Design

```typescript
// CORRECT: idempotent job with deduplication
await queue.add('process-odds', { marketId }, {
  jobId: `odds-${marketId}`,  // deduplication key
  attempts: 3,
  backoff: { type: 'exponential', delay: 2000 },
  removeOnComplete: 100,
  removeOnFail: 50,
  timeout: 30_000,  // fail fast; don't let jobs hang indefinitely
});
```

**Red flags:**
- Jobs with no `timeout` → can block workers indefinitely
- Jobs with no retry config → single failure = data loss
- Passing full objects in job payload instead of IDs → bloats Redis memory
- No `removeOnComplete`/`removeOnFail` → Redis grows unbounded

## Type Safety

- Avoid `any` — use `unknown` + type narrowing or proper types
- Prisma-generated types: `import type { User } from '@prisma/client'` — use these, don't redefine
- Return type annotations on all public service methods
- `as SomeType` casts without validation are a code smell — use Zod or class-transformer

## Severity Classification

| Finding | Severity |
|---|---|
| No DTO validation on mutating endpoint | 🟠 High |
| N+1 queries in hot path (list endpoint) | 🟠 High |
| Circular module dependency | 🟡 Medium |
| BullMQ job with no timeout | 🟡 Medium |
| Redis cache with no TTL | 🟡 Medium |
| `throw new Error()` instead of HttpException | 🟡 Medium |
| Over-fetching (select *) | 🟢 Low |
| Missing index on filtered column | 🟡 Medium |
| `any` type in service layer | 🟢 Low |
