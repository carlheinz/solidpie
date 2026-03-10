---
name: business-automation-devkit
description: "Domain expertise for ISP, telco, and business automation software development. Use when building features for: billing & subscription management, service provisioning & order fulfillment, CRM & sales pipeline, customer self-service portals, support & ticketing, debtor management & collections, usage metering, RADIUS/network integration, or any business automation workflow. Covers both backend (Java/Spring) and frontend (Angular/Vue) patterns."
---

# Business Automation Dev Kit

Domain knowledge for teams building ISP, telco, and business automation platforms. Provides business rules, data models, workflow patterns, and integration guidance that accelerate feature development.

## When Triggered

Identify which domain the request falls into and load the relevant reference:

| Domain | Reference | Load When |
|--------|-----------|-----------|
| Billing, invoicing, subscriptions, payments, proration, credit notes | [billing-patterns.md](references/billing-patterns.md) | Any billing/payment/subscription feature |
| Provisioning, order fulfillment, service activation, RADIUS, bandwidth | [provisioning-workflows.md](references/provisioning-workflows.md) | Service lifecycle, network, ISP features |
| CRM, leads, sales pipeline, customer lifecycle, support, SLAs | [crm-and-pipeline.md](references/crm-and-pipeline.md) | Customer management, sales, support features |
| Webhooks, payment gateways, notifications, API design, retries | [integration-patterns.md](references/integration-patterns.md) | Third-party integrations, API design, events |

For cross-cutting features (e.g., "build a self-service billing portal"), load multiple references as needed.

## Core Principles

1. **Idempotency** — billing and provisioning operations must be safely retryable
2. **Audit trails** — every state change on accounts, invoices, and services must be logged with who/when/why
3. **Graceful degradation** — if a payment gateway or provisioning system is down, queue and retry rather than fail
4. **Tenant isolation** — business automation platforms are typically multi-tenant; enforce data boundaries
5. **Event-driven** — prefer domain events (InvoiceGenerated, ServiceActivated, PaymentFailed) to couple systems loosely

## Data Model Overview

Core entities and their relationships:

```
Customer ──┬── Account ──┬── Subscription ──── Service
            │             │
            │             ├── Invoice ──── LineItem
            │             │     │
            │             │     └── Payment
            │             │
            │             └── Ticket
            │
            ├── Lead ──── Opportunity
            │
            └── Contact
```

- **Customer**: top-level entity, may have multiple accounts
- **Account**: billing unit, holds subscriptions and invoices
- **Subscription**: links an account to a service plan with billing terms
- **Service**: the provisioned resource (internet line, VPN, cloud storage)
- **Invoice/Payment**: financial documents, always immutable once finalized
