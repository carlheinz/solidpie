# Pi Presentation — SOLIDitech Team

A self-contained demo for introducing [Pi](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) to the team, with a custom skill built for our domain.

---

## What's in This Repo

```
├── README.md                     ← You're reading this (your talk script)
├── setup.sh                      ← One command: installs Node, Pi, and our skill
└── business-automation-devkit/   ← Custom skill with ISP/billing/CRM domain knowledge
    ├── SKILL.md                  ← Skill entry point
    └── references/
        ├── billing-patterns.md           ← Subscriptions, invoicing, proration, dunning
        ├── provisioning-workflows.md     ← Order fulfillment, RADIUS, fibre provisioning
        ├── crm-and-pipeline.md           ← Leads, sales pipeline, support, SLAs
        └── integration-patterns.md       ← Payment gateways, webhooks, notifications, APIs
```

---

## The Talk (5 Sections, ~20 Minutes)

---

### 1. What is Pi? (3 min)

**Key points to hit:**

- Pi is a **terminal-based coding agent** — think of it as a pair programmer in your terminal
- It can read files, write files, edit code, and run commands — that's the whole toolset
- It works with the AI provider **you choose**: Gemini, Claude, ChatGPT, Copilot, and more
- **Free to use** with Google Gemini CLI (just your Google account)
- It's **extensible** — you can teach it new things through Skills, without modifying Pi itself

**The pitch:**
> "Pi doesn't try to do everything. It gives you four tools and lets you shape it to how YOU work.
> The magic is in Skills — modular knowledge packs that make it an expert in YOUR domain."

**Resources:**
- GitHub: https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent
- Website: https://shittycodingagent.ai

---

### 2. Setup — Live Demo (5 min)

Do this live on a fresh terminal. If you're worried about network issues, pre-install but show the commands.

```bash
# Clone this repo (or have it ready)
git clone <this-repo-url>
cd JeanPresentation

# Run setup — installs Node (if needed), Pi, and our skill
./setup.sh
```

**What just happened (explain as it runs):**
1. ✅ Checked for Node.js (installed it if missing)
2. ✅ Installed Pi globally via npm
3. ✅ Copied our custom skill into `~/.pi/agent/skills/`

**Now start Pi and login:**
```bash
# Start Pi
pi

# Login with Gemini (opens browser for Google OAuth)
/login
# → Select "Google Gemini CLI"
# → Authorize in browser
# → Done!

# Select a model
/model
# → Pick a Gemini model
```

**Talking point:**
> "That's it. Three commands and you're up. The Gemini CLI login is free with any Google account —
> no API keys, no billing setup, no procurement approval needed."

---

### 3. What Are Skills? (2 min)

Before the demo, briefly explain what just happened with the skill install.

**Key points:**
- Skills are **knowledge packs** — they teach Pi about a specific domain
- Pi has a skills marketplace: https://skills.sh
- You can install community skills: `npx skills find java`
- Or build your own (like we did here)
- Skills only load into context **when relevant** — they don't slow Pi down

**Show the skill structure briefly:**
```bash
# Show what we installed
ls ~/.pi/agent/skills/business-automation-devkit/

# Show the trigger description
head -5 ~/.pi/agent/skills/business-automation-devkit/SKILL.md
```

**Talking point:**
> "This skill knows our business — billing cycles, RADIUS provisioning, dunning workflows,
> the whole ISP domain. We didn't have to teach Pi from scratch. We wrote it once, and now
> every developer on the team gets that knowledge instantly."

---

### 4. Live Demo — Watch Pi Work (7 min)

This is the moment. Pick 2-3 prompts that resonate with the team's daily work.

**Demo prompt suggestions (pick your favorites):**

**For the backend devs:**
```
Help me design a dunning workflow for overdue invoices.
I need escalating reminders that eventually suspend the service.
Show me the data model and the scheduler logic.
```

**For the frontend devs:**
```
I need to build a self-service portal page where customers can
view their invoices, see payment status, and make a payment.
What components do I need and what API endpoints should I call?
```

**For the full room (cross-cutting):**
```
We need to add a plan upgrade feature. When a customer upgrades
their fibre package mid-cycle, we need to handle proration on
the billing side, update the RADIUS profile for the new speed,
and show the change on the customer portal. Walk me through
the full flow.
```

**What to point out during the demo:**
- Pi loaded the relevant reference files automatically (billing, provisioning, etc.)
- It knows domain-specific terms: proration, dunning, RADIUS CoA, OLT, ONT
- It understands the relationships: billing ↔ provisioning ↔ CRM
- It gives practical advice, not generic "here's how REST works"

**If Pi makes a mistake or gives generic advice:**
> "This is version one of the skill. The beauty is we can iterate —
> add our actual database schema, our specific business rules, our API conventions.
> The skill grows with us."

---

### 5. Your Turn — Try It (3 min)

Get the room involved.

```bash
# Everyone runs:
./setup.sh
pi
/login   # → Google Gemini CLI
```

**Give them these starter prompts:**

1. `What data model would you use for a customer support ticketing system with SLA tracking?`
2. `How should we handle payment gateway failures and retries for debit order collections?`
3. `Design the provisioning workflow for a new fibre installation from order to activation.`

**Close with:**
> "This skill took an afternoon to build. Imagine what it looks like when we add
> our actual schemas, our coding conventions, our API standards. Every new developer
> gets onboarded instantly. Every feature starts with domain context already loaded."

---

## Tips for the Presenter

- **Pre-install everything** on your machine as backup. Network issues during live demos are real.
- **Have the demo prompts ready** to paste — don't type them live.
- **If Gemini rate-limits you**, switch to another model: `/model` (you can use Claude or Copilot as backup).
- **Keep it conversational** — this isn't a training session, it's a "look what's possible" moment.
- **The skill is the hook, not the destination** — the real value is the team building on top of this together.

---

## After the Presentation

Things the team can do next:
- **Explore more skills**: `npx skills find <topic>` (try: testing, spring boot, api design)
- **Add to our skill**: contribute actual schemas, code patterns, business rules
- **Build team-specific skills**: API conventions, code review checklist, deployment patterns
- **Read the Pi docs**: https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent

---

## Quick Reference

| Action | Command |
|--------|---------|
| Install everything | `./setup.sh` |
| Start Pi | `pi` |
| Login | `/login` → Google Gemini CLI |
| Switch model | `/model` or `Ctrl+L` |
| Find skills | `npx skills find <query>` |
| Reload skills | `/reload` |
| New session | `/new` |
| Quit | `/quit` or `Ctrl+C` twice |
