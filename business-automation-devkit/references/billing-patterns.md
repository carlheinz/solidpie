# Billing & Subscription Patterns

## Table of Contents
- [Subscription Lifecycle](#subscription-lifecycle)
- [Billing Cycles](#billing-cycles)
- [Proration](#proration)
- [Invoice Generation](#invoice-generation)
- [Payment Processing](#payment-processing)
- [Dunning & Collections](#dunning--collections)
- [Credit Notes & Adjustments](#credit-notes--adjustments)
- [Usage-Based Billing](#usage-based-billing)

## Subscription Lifecycle

```
DRAFT → PENDING_ACTIVATION → ACTIVE → SUSPENDED → CANCELLED
                                 │                      ↑
                                 └── UPGRADING/DOWNGRADING
```

**Key rules:**
- A subscription always references a **PricePlan** (rate, frequency, included usage)
- Plan changes mid-cycle require proration (see below)
- Suspension freezes billing but does NOT cancel — service can be restored
- Cancellation is permanent; create a new subscription to reactivate

**Status transitions and who triggers them:**

| From | To | Trigger |
|------|----|---------|
| DRAFT | PENDING_ACTIVATION | Customer submits order |
| PENDING_ACTIVATION | ACTIVE | Provisioning succeeds |
| ACTIVE | SUSPENDED | Payment overdue (dunning) or admin action |
| SUSPENDED | ACTIVE | Payment received or admin lifts suspension |
| ACTIVE | CANCELLED | Customer request or end of contract |
| SUSPENDED | CANCELLED | Non-payment after grace period expires |

## Billing Cycles

Common patterns in ISP/telco:

- **Anniversary billing**: cycle starts on signup date (e.g., 15th to 14th)
- **Calendar billing**: all customers billed 1st of month (simpler, requires proration on first invoice)
- **Prepaid**: invoice generated BEFORE service period, payment required to activate
- **Postpaid**: invoice generated AFTER service period (common for usage-based)

**Implementation notes:**
- Store `billingAnchorDay` on the account (1-28, avoid 29-31 for month-end issues)
- Batch invoice generation as a scheduled job (e.g., nightly cron)
- Always calculate dates in the **account's timezone**, store as UTC

## Proration

When a customer changes plan mid-cycle:

```
Proration credit = (unused_days / total_days_in_period) × old_plan_price
Proration charge = (remaining_days / total_days_in_period) × new_plan_price
```

**Strategies:**
- **Immediate proration**: adjust on next invoice (most common)
- **Next-cycle**: old plan runs until end of cycle, new plan starts next cycle (simplest)
- **Credit + charge**: issue credit note for unused, charge for new immediately

**Edge cases to handle:**
- Plan change on the same day as billing — no proration needed
- Multiple plan changes in one cycle — prorate from last change only
- Downgrade with usage exceeding new plan — warn before confirming

## Invoice Generation

**Invoice data model:**

```
Invoice
├── invoiceNumber (unique, sequential, never reused)
├── accountId
├── status: DRAFT → FINALIZED → SENT → PAID → VOID
├── issueDate
├── dueDate (issueDate + paymentTermsDays)
├── currency
├── subtotal
├── taxAmount
├── total
├── lineItems[]
│   ├── description
│   ├── quantity
│   ├── unitPrice
│   ├── amount
│   ├── subscriptionId (nullable)
│   └── type: RECURRING | USAGE | ONE_TIME | PRORATION_CREDIT
└── payments[]
    ├── amount
    ├── method
    ├── reference
    └── date
```

**Rules:**
- Invoices are **immutable once FINALIZED** — corrections use credit notes
- Invoice numbers must be **sequential with no gaps** (tax compliance)
- Always store amounts as **integers in minor units** (cents, not dollars) to avoid floating-point errors
- Tax calculation depends on customer location — externalize tax rules

## Payment Processing

**Payment gateway integration flow:**

```
1. Generate invoice
2. Attempt auto-charge (if payment method on file)
3. Gateway returns: SUCCESS | DECLINED | ERROR
4. On SUCCESS → mark invoice PAID, emit PaymentReceived event
5. On DECLINED → enter dunning cycle
6. On ERROR → retry with exponential backoff (max 3 attempts)
```

**Idempotency is critical:**
- Generate a unique `paymentRequestId` before calling gateway
- Gateway should deduplicate on this ID
- Store gateway's `transactionId` for reconciliation

**Reconciliation:**
- Daily batch reconciliation: compare gateway settlement report against internal payment records
- Flag mismatches for manual review
- Handle chargebacks as a reversal event (re-open invoice, notify collections)

## Dunning & Collections

Escalation ladder for overdue invoices:

```
Day 0:  Invoice due
Day 1:  Friendly reminder email
Day 7:  Second reminder + SMS
Day 14: Warning — service suspension in 7 days
Day 21: Service SUSPENDED, send suspension notice
Day 30: Final notice — cancellation in 14 days
Day 44: Service CANCELLED, send to external collections
```

**Implementation:**
- Model as a `DunningPolicy` with configurable steps (days, action, notification template)
- Each account can override the default policy (VIP customers get longer grace periods)
- Dunning scheduler runs daily, checks all overdue invoices against policy steps
- **Never auto-cancel without the final notice step** — legal requirement in most jurisdictions
- Emit events at each step: `DunningEscalated`, `ServiceSuspended`, `ServiceCancelled`

## Credit Notes & Adjustments

- Credit notes reference the original invoice
- They reduce the customer's balance or generate a refund
- Types: **full reversal** (void entire invoice), **partial credit** (specific line items), **goodwill credit** (no invoice reference)
- Credit notes get their own sequential numbering (CN-0001, CN-0002)
- A credit balance on an account is applied automatically to the next invoice

## Usage-Based Billing

Common in ISP for bandwidth/data usage:

**Collection:**
- Usage records ingested from RADIUS/network equipment (see provisioning-workflows.md)
- Store raw usage events: `{accountId, meterId, quantity, unit, timestamp}`
- Aggregate into billing periods during invoice generation

**Rating:**
- **Tiered**: first 100GB at rate A, next 100GB at rate B (calculate per tier)
- **Volume**: total usage determines the rate for ALL usage (check thresholds)
- **Overage**: included amount free, then per-unit charge above threshold

**Metering pipeline:**
```
Raw events → Deduplication → Aggregation → Rating → Line items on invoice
```

Deduplicate on `{meterId, timestamp}` to handle duplicate submissions from network equipment.
