# Integration Patterns

## Table of Contents
- [Domain Events](#domain-events)
- [Payment Gateway Integration](#payment-gateway-integration)
- [Notification System](#notification-system)
- [Webhook Design](#webhook-design)
- [API Design for Business Automation](#api-design-for-business-automation)
- [Retry & Resilience](#retry--resilience)
- [Data Synchronization](#data-synchronization)

## Domain Events

Business automation platforms are event-driven. Core domain events:

**Billing events:**
- `InvoiceGenerated` — trigger: send to customer, update accounting
- `PaymentReceived` — trigger: mark invoice paid, update account balance, receipt
- `PaymentFailed` — trigger: enter dunning, notify customer
- `SubscriptionActivated` — trigger: start billing cycle
- `SubscriptionCancelled` — trigger: final invoice, stop billing

**Provisioning events:**
- `OrderCreated` — trigger: validate, start fulfillment
- `ServiceProvisioned` — trigger: activate billing, send welcome
- `ServiceSuspended` — trigger: block network access, notify customer
- `ServiceTerminated` — trigger: decommission resources, archive data

**CRM events:**
- `LeadCreated` — trigger: assign to rep, start scoring
- `TicketEscalated` — trigger: notify team lead, update SLA clock
- `CustomerChurned` — trigger: offboard, retention campaign

**Event structure:**

```json
{
  "eventId": "uuid",
  "eventType": "PaymentReceived",
  "timestamp": "2024-03-15T10:30:00Z",
  "aggregateType": "Invoice",
  "aggregateId": "INV-2024-0042",
  "payload": {
    "invoiceId": "INV-2024-0042",
    "accountId": "ACC-001",
    "amount": 99900,
    "currency": "ZAR",
    "method": "DEBIT_ORDER",
    "gatewayRef": "gw_abc123"
  },
  "metadata": {
    "correlationId": "uuid",
    "causationId": "uuid",
    "userId": "system"
  }
}
```

**Event handling rules:**
- Events are immutable facts — never modify published events
- Consumers must be idempotent (same event processed twice = same result)
- Use `eventId` for deduplication
- Use `correlationId` to trace a business process across events

## Payment Gateway Integration

**Common gateways in South African ISP/telco context:**
- Debit orders (Netcash, PayGate, Peach Payments)
- Credit card (PayGate, Stripe, Paystack)
- EFT/bank transfer (manual reconciliation or instant EFT via Stitch/Ozow)
- Mobile money (context dependent)

**Integration pattern:**

```
                    ┌─── Gateway A (debit orders)
Billing System ─── Payment Router ─── Gateway B (credit card)
                    └─── Gateway C (instant EFT)
```

**Payment router responsibilities:**
- Select gateway based on payment method type
- Format request per gateway's API
- Handle response normalization (each gateway has different formats)
- Store raw request/response for debugging
- Retry on transient failures (NOT on business declines)

**Debit order specifics (common in SA):**
- Batch file submission (usually 2 days before collection date)
- Result file received next business day
- Dispute period: customer can reverse within 40 days
- Track: submission date, collection date, result date, dispute window

**Reconciliation flow:**
```
1. Daily: fetch settlement report from each gateway
2. Match gateway transactions to internal payments by reference
3. Flag unmatched transactions (overpayments, missing records)
4. Auto-apply matched payments to invoices
5. Route exceptions to finance team queue
```

## Notification System

**Channels:**
- Email (transactional: invoices, receipts, tickets / marketing: campaigns)
- SMS (payment reminders, service status, OTP)
- Push notification (mobile app, if applicable)
- In-app (self-service portal notifications)
- WhatsApp Business API (growing channel in SA market)

**Notification architecture:**

```
Domain Event → Notification Engine → Template Resolver → Channel Router → Delivery
                                          │                                    │
                                     Template Store                     Delivery Log
                                   (per channel,                    (sent, delivered,
                                    per language)                    failed, opened)
```

**Template model:**
```
NotificationTemplate
├── eventType (e.g., "PaymentFailed")
├── channel (EMAIL | SMS | PUSH | WHATSAPP)
├── language (en, af, zu, etc.)
├── subject (email only)
├── body (with variable placeholders: {{customerName}}, {{amount}})
├── active (boolean)
└── version
```

**Rules:**
- Customer notification preferences must be respected (opt-out per channel)
- Rate limiting: max 3 SMS per day per customer (prevent spam on retry loops)
- Fallback chain: email fails → try SMS → try push
- All notifications logged for audit and dispute resolution

## Webhook Design

For third-party integrations and customer-facing webhook APIs:

**Outgoing webhooks (your platform → external systems):**

```
WebhookSubscription
├── subscriberId (customer or integration partner)
├── url (HTTPS endpoint)
├── events[] (subscribed event types)
├── secret (for HMAC signature verification)
├── status: ACTIVE | PAUSED | FAILED
├── failureCount
└── lastDelivery
```

**Delivery pattern:**
1. Event occurs → check matching webhook subscriptions
2. Build payload (filter sensitive fields per subscriber permissions)
3. Sign payload: `HMAC-SHA256(secret, JSON body)` → `X-Signature` header
4. POST to subscriber URL with timeout (10 seconds)
5. 2xx = success, anything else = retry
6. Retry schedule: 1min, 5min, 30min, 2hr, 12hr (then mark FAILED)
7. After 5 consecutive failures: pause subscription, notify subscriber

**Incoming webhooks (external → your platform):**
- Payment gateway callbacks (payment result notifications)
- Network equipment alerts (link down, high utilization)
- Partner system notifications (wholesale billing updates)
- Always validate: check signature, validate source IP, verify payload schema

## API Design for Business Automation

**REST conventions for ISP/business platforms:**

```
# Resources follow the domain model
GET    /api/v1/customers/{id}
GET    /api/v1/customers/{id}/accounts
GET    /api/v1/accounts/{id}/subscriptions
GET    /api/v1/accounts/{id}/invoices
POST   /api/v1/accounts/{id}/invoices          (generate invoice)
POST   /api/v1/orders                          (create order)
PATCH  /api/v1/tickets/{id}                    (update ticket)

# Actions that don't map to CRUD
POST   /api/v1/subscriptions/{id}/suspend
POST   /api/v1/subscriptions/{id}/reactivate
POST   /api/v1/invoices/{id}/send
POST   /api/v1/services/{id}/speed-test
```

**Pagination:**
- Use cursor-based pagination for large datasets (invoices, tickets)
- `GET /invoices?cursor=abc123&limit=50`
- Return `nextCursor` in response

**Filtering:**
- `GET /invoices?status=OVERDUE&from=2024-01-01&to=2024-03-31`
- `GET /tickets?priority=CRITICAL&assignedTeam=technical`

**API versioning:**
- URL path versioning (`/api/v1/`, `/api/v2/`) — simplest for ISP integrations
- Support previous version for minimum 12 months after new version release

## Retry & Resilience

**Circuit breaker pattern for external integrations:**

```
CLOSED (normal) → OPEN (failing) → HALF_OPEN (testing recovery)
```

- **Closed**: requests flow normally, track failure count
- **Open**: after threshold (e.g., 5 failures in 60s), stop calling, return fallback
- **Half-open**: after cooldown, allow one test request, if success → close, if fail → open

**Queue-based resilience:**
- All external calls (gateway, RADIUS, email) should go through a message queue
- Failed messages retry automatically with backoff
- Dead-letter queue for messages that exceed retry limit
- Operations dashboard to monitor queue depths and DLQ

**Timeout strategy:**
| Integration | Timeout | Retry |
|-------------|---------|-------|
| Payment gateway | 30s | 3x with backoff |
| RADIUS CoA | 5s | 2x immediate |
| Email sending | 10s | 5x with backoff |
| SMS sending | 10s | 3x with backoff |
| Network equipment API | 15s | 2x with backoff |

## Data Synchronization

**Between billing and accounting systems:**
- Generate journal entries from billing events
- Daily reconciliation batch: compare invoice totals, payment totals, outstanding balances
- Handle currency rounding differences (tolerance threshold)

**Between CRM and billing:**
- Customer master data lives in CRM, syncs to billing on change
- Avoid dual-master — one system owns each field
- Sync via domain events, not direct DB access

**Between provisioning and network:**
- Network equipment is source of truth for actual service state
- Periodic reconciliation: compare provisioned services against network config
- Flag mismatches: "billing says active, network says no session" → investigate
