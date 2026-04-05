# Sports Betting Domain Validation

## Odds Conversion Formulas

**American → Decimal:**
```typescript
function americanToDecimal(american: number): number {
  if (american > 0) return (american / 100) + 1;
  if (american < 0) return (100 / Math.abs(american)) + 1;
  throw new Error('Odds cannot be 0');
}
// americanToDecimal(+150) → 2.50
// americanToDecimal(-110) → 1.909...
```

**Decimal → Implied Probability:**
```typescript
function decimalToImpliedProb(decimal: number): number {
  if (decimal <= 1) throw new Error('Decimal odds must be > 1');
  return 1 / decimal;
}
```

**American → Implied Probability (accounts for vig):**
```typescript
function americanToImpliedProb(american: number): number {
  const decimal = americanToDecimal(american);
  return 1 / decimal;
}
// To get TRUE probability, strip vig from both sides of a market.
```

**Fractional → Decimal:**
```typescript
function fractionalToDecimal(num: number, den: number): number {
  return (num / den) + 1;
}
```

## Expected Value (EV) Calculation

```typescript
// stake = amount wagered (default 1 unit for EV%)
// trueProb = your estimated win probability (0–1), NOT implied prob (which includes vig)
// decimalOdds = book's offered decimal odds

function calculateEV(trueProb: number, decimalOdds: number, stake = 1): number {
  const winAmount = stake * (decimalOdds - 1);
  const loseAmount = stake;
  return (trueProb * winAmount) - ((1 - trueProb) * loseAmount);
}

// EV% = EV / stake * 100
// Positive EV means +edge over the book
```

**Common mistake:** using implied probability as true probability — this always yields EV = 0 (or negative after vig).

## Kelly Criterion

```typescript
// f* = fraction of bankroll to wager
// b = decimal odds - 1 (net odds on 1 unit bet)
// p = true win probability
// q = 1 - p

function kellyCriterion(trueProb: number, decimalOdds: number): number {
  const b = decimalOdds - 1;
  const p = trueProb;
  const q = 1 - p;
  const kelly = (b * p - q) / b;
  return Math.max(0, kelly);  // negative Kelly = no bet
}

// fractional Kelly (e.g., half-Kelly) is common in practice:
const halfKelly = kellyCriterion(prob, odds) * 0.5;
```

**Validation checks:**
- Kelly returning negative → no bet (never size negatively)
- Kelly > 0.25 (25% of bankroll) → likely a data error; cap at 0.25 for safety
- Inputs must satisfy: `decimalOdds > 1`, `0 < trueProb < 1`

## Vig (Juice) Calculation

```typescript
// Total implied probability of all outcomes > 1.0 — the excess is the vig
function calculateVig(impliedProbs: number[]): number {
  const total = impliedProbs.reduce((sum, p) => sum + p, 0);
  return total - 1;  // e.g., 0.045 = 4.5% vig
}

// To remove vig and get true probabilities:
function removeVig(impliedProbs: number[]): number[] {
  const total = impliedProbs.reduce((sum, p) => sum + p, 0);
  return impliedProbs.map(p => p / total);
}
```

## Arbitrage Detection

```typescript
// Arbitrage exists when sum of (1/odds) across all outcomes < 1
function isArbitrage(decimalOdds: number[]): boolean {
  const sum = decimalOdds.reduce((acc, o) => acc + (1 / o), 0);
  return sum < 1;
}

// Arb profit % = (1 - sum) * 100
// Stake on outcome i = (totalStake / oddsI) / sum
```

**False positive filters:**
- Odds must be from different books (same-book arb is a pricing error, usually corrected before settlement)
- Check odds timestamp freshness — stale odds invalidate arb calculation
- Account for maximum stake limits per book

## Line Movement & Reverse Line Movement

```typescript
type LineMovement = {
  openingOdds: number;     // american
  currentOdds: number;     // american
  direction: 'toward' | 'against' | 'neutral';
  bettingPercentage: number;  // % of bets on this side (0–100)
};

// Reverse Line Movement (RLM): majority of bets on one side but line moves against them
function isReverseLineMovement(movement: LineMovement): boolean {
  const majorityOnSide = movement.bettingPercentage > 55;
  // For favorite (negative american): line moving toward -EV (more negative) = moved against bettor
  const lineMoved = movement.direction === 'against';
  return majorityOnSide && lineMoved;
}
```

## Odds Freshness Validation

```typescript
const ODDS_MAX_AGE_MS = 30_000;  // 30 seconds

function isOddsStale(timestamp: Date): boolean {
  return Date.now() - timestamp.getTime() > ODDS_MAX_AGE_MS;
}
// Always check before using odds in EV/arb calculations
```

## Edge Case Checklist

| Case | Expected Behavior |
|---|---|
| `american = 0` | Throw — invalid odds |
| `american = +100` | Decimal = 2.0, implied prob = 50% |
| `american = -100` | Decimal = 2.0, implied prob = 50% (same as +100) |
| `decimalOdds = 1.0` | Throw — no return on stake |
| `trueProb = 0` | Kelly = 0 (no bet) |
| `trueProb = 1` | Kelly = 1 (all-in) — cap at 0.25 |
| Very large odds (+10000) | Must not overflow float; test `1/decimal` precision |
| Fractional `0/1` or `1/0` | Throw — undefined odds |

## Severity Classification

| Finding | Severity |
|---|---|
| EV formula uses implied prob instead of true prob | 🔴 Critical |
| Kelly can return negative (unsanitized) | 🟠 High |
| No odds freshness check before arb/EV calc | 🟠 High |
| Missing `american = 0` guard | 🟡 Medium |
| Arb detection doesn't filter same-book odds | 🟡 Medium |
| No vig stripping before true probability calc | 🟠 High |
| Kelly not capped at reasonable max (e.g., 0.25) | 🟡 Medium |
| Missing edge case: `decimalOdds ≤ 1` | 🟡 Medium |
