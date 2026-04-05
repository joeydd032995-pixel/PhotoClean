---
name: platform-engineer
description: "Multi-domain platform engineering audit: orchestrates parallel passes for security (OWASP/JWT/injection/secrets), platform compliance (iOS HIG, WCAG), architecture quality (NestJS/React/Swift), domain logic (sports betting EV/odds/Kelly/arbitrage), and performance (N+1 queries, iOS main-thread). Use when asked for: comprehensive audit, platform engineering review, full-stack analysis, production readiness check, iOS compliance review, security audit, or when the codebase has 2+ quality dimensions to inspect."
---

# Platform Engineer

Multi-pass, multi-domain code audit. Token-efficient: read each file once, route to relevant passes only.

---

## Phase 1 — Discovery & Domain Detection

1. Read file structure and key config files (package.json, Podfile, go.mod, prisma/schema.prisma, etc.)
2. Detect domains present:

| Domain | Detection Signal |
|---|---|
| iOS (Swift/SwiftUI) | `.swift` files, `Podfile`, `.xcodeproj` |
| NestJS/Node backend | `nest-cli.json`, `@nestjs/` imports, `prisma/` directory |
| React/Web frontend | `src/App.tsx`, `vite.config`, React imports |
| Sports betting | EV/Kelly/odds/arbitrage in file names or code |
| AI/Agents | BullMQ, `anthropic`, `@anthropic-ai/sdk` imports |
| General TS/JS | any `tsconfig.json` / `package.json` |

3. **Confirm scope with user before proceeding.** Present detected domains and planned passes:

```
Detected: [list domains]

Passes I'll run:
1. Security (always)
2. [Platform compliance if iOS/web detected]
3. Architecture & Code Quality
4. [Domain Logic if betting/e-commerce/healthcare detected]
5. Performance

Proceed? (or adjust scope)
```

**Surface any Critical findings immediately** — don't wait for the full report.

---

## Phase 2 — Analysis Passes

Execute passes in parallel. Read each file ONCE; reuse that context across all passes.

### Pass 1: Security (always run)
Load `references/security.md`. Check auth, injection, secrets, rate limiting, prompt injection.

### Pass 2: Platform Compliance (if iOS or web detected)
- iOS: Load `references/platform-ios.md`. Check HIG touch targets, safe areas, Dynamic Type, Dark Mode, VoiceOver, navigation.
- Web/WCAG: Check color contrast ≥4.5:1, alt text, semantic HTML, keyboard navigation, ARIA labels.

### Pass 3: Architecture & Code Quality
Load the relevant reference for the detected stack:
- NestJS: Load `references/platform-nestjs.md`
- Swift/iOS: Check `@MainActor` usage, actor isolation, data race patterns, view model lifecycle
- React: Check unnecessary re-renders, missing memoization, error boundaries, state update patterns

Universal checks (all stacks): DRY violations, functions >50 lines, nesting >4 levels, magic strings/numbers, dead code, missing error handling.

### Pass 4: Domain Logic (if applicable)
- Sports betting: Load `references/domain-betting.md`. Validate EV formula, Kelly Criterion, odds conversion, arbitrage logic, edge cases.
- E-commerce: Inventory consistency, price calculation accuracy, payment security.
- Healthcare: PHI encryption, audit logging, consent validation.

### Pass 5: Performance
- Backend: N+1 queries, missing indexes, pagination, transaction boundaries, cache TTLs
- iOS: Main-thread blocking, image asset size, memory leaks (retain cycles, unclosed resources)
- Web: Bundle splitting, missing virtualization for large lists, expensive computations not memoized

---

## Phase 3 — Aggregation & Scoring

### Weighted Score Formula

```
Security:    50% weight (0–10)
  Single 🔴 Critical → caps at 3/10
  Two 🔴 Critical    → caps at 1–2/10

Code Quality: 30% weight (0–10)
  Silent error swallowing → caps at 4/10

Performance:  20% weight (0–10)

Platform Compliance modifier: ±1 (iOS HIG violations in prod app: −1; full a11y: +1)
Domain Logic modifier:        ±2 (incorrect EV/Kelly: −2; robust edge cases: +1)

Overall = (Security × 0.5) + (Quality × 0.3) + (Performance × 0.2) + modifiers
```

Deduplicate: same root cause flagged by multiple passes → one finding with cross-references.

---

## Output Format

Produce both sections:

### 1. Executive Report (markdown, inline)

```markdown
# Platform Engineering Report

## Summary
- **Files Analyzed**: N across M domains
- **Passes**: [list]
- **Findings**: X (🔴 C critical, 🟠 H high, 🟡 M medium, 🟢 L low)
- **Top Priority**: [one sentence]

## Scorecard
| Dimension       | Score | Rationale |
|----------------|-------|-----------|
| Security        | X/10  | ...       |
| Code Quality    | X/10  | ...       |
| Performance     | X/10  | ...       |
| iOS HIG         | X/10 or N/A | ... |
| Domain Logic    | X/10 or N/A | ... |
| **Overall**     | **X/10** | weighted avg + modifiers |

## Critical Issues (Fix Before Merge)
[Top 3–5 🔴 findings: file, line, impact, complete fix]

## High Priority
[Next 5–10 🟠 findings]

## Priority Action List
1. [fix + effort estimate]
...5.
```

### 2. JSON Artifact

```json
{
  "summary": { "files_analyzed": N, "domains": [], "findings": { "critical": 0, "high": 0, "medium": 0, "low": 0 } },
  "scores": { "security": 0, "code_quality": 0, "performance": 0, "overall": 0 },
  "findings": [
    { "id": "SEC-001", "pass": "security", "severity": "critical", "file": "...", "line": 0,
      "finding": "...", "impact": "...", "fix": "[complete code block]" }
  ],
  "recommendations": { "immediate": [], "short_term": [], "long_term": [] }
}
```

---

## Constraints

**MUST:**
- Confirm scope before running passes
- Surface Critical findings immediately (don't wait for full report)
- Provide complete, copy-pasteable fixes — never partial
- Include file path + line number for every finding
- Score honestly; don't inflate

**MUST NOT:**
- Re-read files between passes
- Load domain reference files for stacks not detected
- Proceed if user disputes detected scope
- Block on style issues when a linter is configured
