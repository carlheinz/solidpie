# CRM, Sales Pipeline & Support

## Table of Contents
- [Customer Lifecycle](#customer-lifecycle)
- [Lead Management](#lead-management)
- [Sales Pipeline](#sales-pipeline)
- [Account Hierarchy](#account-hierarchy)
- [Support & Ticketing](#support--ticketing)
- [SLA Management](#sla-management)
- [Customer Self-Service Portal](#customer-self-service-portal)

## Customer Lifecycle

```
LEAD → PROSPECT → CUSTOMER → AT_RISK → CHURNED
                      │                    ↑
                      └── LOYAL ───────────┘ (win-back)
```

**Lifecycle events and triggers:**

| Transition | Trigger | Action |
|------------|---------|--------|
| Lead → Prospect | Responds to outreach / requests quote | Assign to sales rep |
| Prospect → Customer | Signs contract, first payment | Create account, begin onboarding |
| Customer → Loyal | 12+ months active, no support escalations | Unlock loyalty pricing |
| Customer → At Risk | Late payments, support complaints, usage drop | Alert account manager |
| At Risk → Churned | Cancels all services | Run offboarding, retention offer |
| Churned → Prospect | Win-back campaign response | Re-enter sales pipeline |

## Lead Management

**Lead data model:**

```
Lead
├── source: WEBSITE | REFERRAL | CAMPAIGN | WALK_IN | PARTNER | IMPORT
├── contactInfo (name, email, phone, company)
├── address (for serviceability check)
├── interestedProducts[]
├── score (qualification score 0-100)
├── assignedRepId
├── status: NEW → CONTACTED → QUALIFIED → CONVERTED → DISQUALIFIED
├── activities[] (calls, emails, meetings)
└── disqualifyReason (nullable)
```

**Lead scoring factors (ISP context):**
- Address in fibre coverage area: +30
- Business customer: +20
- Requested specific plan: +15
- Visited pricing page: +10
- Referred by existing customer: +25
- Unserviceable area: auto-disqualify (add to waiting list)

## Sales Pipeline

**Stages for ISP/telco:**

```
QUALIFICATION → NEEDS_ANALYSIS → PROPOSAL → NEGOTIATION → CLOSED_WON / CLOSED_LOST
```

**Opportunity data model:**

```
Opportunity
├── leadId
├── accountId (if existing customer upsell)
├── stage
├── products[] (services being quoted)
├── monthlyRecurringRevenue (MRR)
├── contractTermMonths
├── totalContractValue (MRR × term)
├── probability (% by stage)
├── expectedCloseDate
├── competitorNotes
└── lostReason (nullable)
```

**Default probabilities by stage:**

| Stage | Probability | Typical Duration |
|-------|------------|-----------------|
| Qualification | 10% | 1-3 days |
| Needs Analysis | 25% | 3-7 days |
| Proposal | 50% | 5-14 days |
| Negotiation | 75% | 3-10 days |
| Closed Won | 100% | — |
| Closed Lost | 0% | — |

**Pipeline metrics:**
- **Conversion rate**: opportunities won / total opportunities
- **Average deal size**: total MRR / deals closed
- **Sales cycle length**: average days from qualification to close
- **Pipeline coverage**: pipeline value / quota (target: 3x)

## Account Hierarchy

Business customers often need multi-level account structures:

```
MasterAccount (Company HQ)
├── SubAccount (Branch Office A)
│   ├── Subscription (100Mbps Fibre)
│   └── Subscription (VPN)
├── SubAccount (Branch Office B)
│   └── Subscription (50Mbps Fibre)
└── SubAccount (Data Center)
    ├── Subscription (1Gbps Dedicated)
    └── Subscription (Colocation)
```

**Rules:**
- Billing can be consolidated (one invoice for master) or per sub-account
- Discounts may apply at master level (volume pricing across all sub-accounts)
- Each sub-account has its own contacts and service addresses
- Support tickets can be raised by any contact in the hierarchy

## Support & Ticketing

**Ticket data model:**

```
Ticket
├── ticketNumber (auto-generated, e.g., TKT-20240315-0042)
├── accountId
├── contactId (who raised it)
├── channel: EMAIL | PHONE | PORTAL | CHAT | SOCIAL
├── category: TECHNICAL | BILLING | SALES | GENERAL
├── subcategory (e.g., "Slow speed", "Invoice query")
├── priority: LOW | MEDIUM | HIGH | CRITICAL
├── status: OPEN → IN_PROGRESS → WAITING_CUSTOMER → RESOLVED → CLOSED
├── assignedTeam
├── assignedAgentId
├── slaDeadline
├── entries[] (comments, status changes, attachments)
├── relatedTickets[]
└── resolution (nullable)
```

**Priority matrix (ISP context):**

| Priority | Example | Response SLA | Resolution SLA |
|----------|---------|-------------|----------------|
| CRITICAL | Total service outage, business customer | 15 min | 4 hours |
| HIGH | Intermittent connectivity, speed issues | 1 hour | 8 hours |
| MEDIUM | Billing dispute, plan change request | 4 hours | 24 hours |
| LOW | General inquiry, feature request | 8 hours | 72 hours |

**Auto-routing rules:**
- Billing keywords → Billing team
- Speed/connection keywords → Technical team (L1)
- Escalation after SLA breach → Team lead + notification

## SLA Management

**SLA data model:**

```
SLA
├── name (e.g., "Business Premium SLA")
├── applicablePlans[] (which service plans include this SLA)
├── uptimeGuarantee (e.g., 99.9%)
├── responseTargets[] (by priority)
├── resolutionTargets[] (by priority)
├── penalties[] (credit percentage per SLA breach)
├── exclusions[] (scheduled maintenance, force majeure)
└── reportingFrequency: MONTHLY | QUARTERLY
```

**SLA tracking:**
- Clock starts when ticket is created (response SLA) or acknowledged (resolution SLA)
- Clock pauses during WAITING_CUSTOMER status
- Breach triggers: escalation notification, automatic credit calculation
- Monthly SLA report per customer: uptime %, tickets raised, SLA met/breached

## Customer Self-Service Portal

Features the portal typically exposes:

**Account management:**
- View/edit contact details
- View account hierarchy (business customers)
- Download invoices and statements
- View payment history, make payments
- Update payment method

**Service management:**
- View active services and usage
- Request plan upgrade/downgrade
- Request new service (enters order workflow)
- View service status and planned outages

**Support:**
- Raise new ticket (auto-categorize from description)
- View open tickets and history
- Add comments/attachments to existing tickets
- Rate support experience after resolution

**Self-service reduces ticket volume** — expose real-time service status and network health to reduce "is it down?" calls.
