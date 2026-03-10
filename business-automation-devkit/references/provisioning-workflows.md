# Provisioning & Order Fulfillment

## Table of Contents
- [Order Lifecycle](#order-lifecycle)
- [Provisioning Pipeline](#provisioning-pipeline)
- [Service Status Lifecycle](#service-status-lifecycle)
- [ISP-Specific: RADIUS & Network](#isp-specific-radius--network)
- [Fibre Network Provisioning](#fibre-network-provisioning)
- [Rollback & Error Handling](#rollback--error-handling)
- [Field Agent Management](#field-agent-management)

## Order Lifecycle

```
CREATED → VALIDATED → PAYMENT_CONFIRMED → PROVISIONING → ACTIVE → COMPLETED
                                              │
                                              ├── PROVISIONING_FAILED → RETRY / MANUAL_REVIEW
                                              └── CANCELLED (at any stage before ACTIVE)
```

**Order data model:**

```
Order
├── orderId
├── customerId
├── type: NEW | UPGRADE | DOWNGRADE | CANCELLATION | RELOCATION
├── status
├── lineItems[]  (services/products being ordered)
├── tasks[]      (provisioning steps to execute)
├── paymentReference
├── assignedAgent (nullable, for field work)
├── scheduledDate (nullable)
├── completedDate
└── notes[]
```

**Rules:**
- Validate order before accepting: credit check, address serviceability, plan availability
- Payment confirmation before provisioning (prepaid) or post-provisioning (postpaid)
- Each order type has its own provisioning task template

## Provisioning Pipeline

Break provisioning into discrete, ordered tasks:

```
Order accepted
  ├── Task 1: Create/update account in billing system
  ├── Task 2: Configure RADIUS profile
  ├── Task 3: Provision on network equipment (router/switch/OLT)
  ├── Task 4: Activate service on monitoring system
  ├── Task 5: Send welcome email/SMS
  └── Task 6: Schedule installation (if field work needed)
```

**Each task has:**
- `taskType`, `status` (PENDING → IN_PROGRESS → COMPLETED → FAILED)
- `dependsOn[]` — predecessor tasks that must complete first
- `retryCount`, `maxRetries`, `lastError`
- `executedBy` — system (automated) or agent (manual)

**Execution patterns:**
- **Sequential**: each task waits for predecessor (simple, slow)
- **Parallel where possible**: tasks without dependencies run concurrently
- **Saga pattern**: if any task fails, run compensating actions for completed tasks

## Service Status Lifecycle

```
PENDING_PROVISION → PROVISIONING → ACTIVE → SUSPENDED → TERMINATED
                                      │         ↑
                                      └─────────┘ (reactivation)
```

| Status | Billing | Network Access | Visible to Customer |
|--------|---------|----------------|---------------------|
| PENDING_PROVISION | No | No | Yes (as "setting up") |
| PROVISIONING | No | No | Yes (as "activating") |
| ACTIVE | Yes | Yes | Yes |
| SUSPENDED | Paused/continues* | No | Yes (as "suspended") |
| TERMINATED | Stops | No | No (archived) |

*Suspension billing depends on business rules: some ISPs continue billing during suspension, others pause.

## ISP-Specific: RADIUS & Network

**RADIUS (Remote Authentication Dial-In User Service):**
- Central authentication for PPPoE/IPoE connections
- Attributes control bandwidth, IP assignment, session limits

**Key RADIUS attributes for ISPs:**

| Attribute | Purpose |
|-----------|---------|
| `Framed-IP-Address` | Static IP assignment |
| `Framed-Pool` | Dynamic IP pool |
| `Mikrotik-Rate-Limit` | Bandwidth shaping (upload/download) |
| `Session-Timeout` | Max session duration |
| `WISPr-Bandwidth-Max-Up/Down` | Standard bandwidth control |
| `Reply-Message` | Redirect to captive portal on suspension |

**Bandwidth shaping pattern:**
```
Plan "Fibre 100Mbps" → RADIUS profile:
  - Download: 100M
  - Upload: 50M
  - Burst: 120M/60M for first 30 seconds (CIR/MIR)
  - FUP: After 500GB, shape to 10M/5M until cycle reset
```

**Integration approach:**
- Store RADIUS profiles linked to service plans
- On provisioning: create RADIUS user with plan's profile attributes
- On plan change: update RADIUS attributes, send CoA (Change of Authorization) to NAS
- On suspension: change profile to redirect/block, send CoA disconnect

## Fibre Network Provisioning

**Fibre-specific workflow:**
```
1. Coverage check (is address in fibre footprint?)
2. Survey (confirm drop cable route)
3. Schedule installation
4. Field agent installs ONT at premises
5. Configure OLT port → link to ONT serial
6. RADIUS profile activation
7. Speed test verification
8. Customer sign-off
```

**Data model additions for fibre:**
```
ServicePoint
├── address
├── gpsCoordinates
├── oltName / oltPort / onuId
├── ontSerialNumber
├── splitterNode
└── dropCableLength
```

## Rollback & Error Handling

When provisioning fails mid-pipeline:

**Compensating actions (saga pattern):**

| Failed Step | Compensating Action |
|-------------|---------------------|
| Network config failed | Remove RADIUS user, reverse billing setup |
| RADIUS failed | Reverse billing setup |
| Billing setup failed | No compensation needed (nothing done yet) |
| OLT config failed | Remove RADIUS user, remove billing, notify field agent |

**Retry strategy:**
- Automated retry for transient failures (network timeout, equipment busy)
- Exponential backoff: 1min → 5min → 15min → 1hr
- After max retries: flag for manual review, notify operations team
- **Never retry payment-related steps automatically** — risk of double-charging

## Field Agent Management

For installations requiring physical work:

**Work order model:**
```
WorkOrder
├── orderId (parent order)
├── assignedAgentId
├── scheduledDate / timeSlot
├── type: INSTALLATION | REPAIR | RELOCATION | DECOMMISSION
├── status: SCHEDULED → EN_ROUTE → ON_SITE → COMPLETED → FAILED
├── location (address, GPS, access instructions)
├── equipment[] (ONT, router, cables to bring)
├── checklistItems[] (steps agent must complete)
├── photos[] (proof of installation)
└── customerSignature
```

**Scheduling rules:**
- Respect agent skills (fibre splicing, wireless, etc.)
- Geographic clustering to minimize travel
- Customer-preferred time slots with buffer between appointments
- Automatic SMS to customer: confirmation, en-route notification, completion
