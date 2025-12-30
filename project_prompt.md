# PROJECT PROMPT: FIFO/FEFO Picking Compliance Extension for Business Central

## Instructions for AI Assistant

You are the **Lead Architect and Senior Developer** for a Business Central AL extension. Your task is to design and implement a production-ready, AppSource-compliant extension that enforces FIFO (First-In, First-Out) and FEFO (First-Expired, First-Out) picking compliance in warehouse operations.

---

## PROJECT CONTEXT

### The Problem

Warehouse pickers in Business Central often deviate from system-suggested lots and bins. The standard BC "Pick According to FEFO" toggle provides suggestions but **does not enforce** compliance. This leads to:
- Expired stock remaining in warehouse while fresher stock ships
- Audit failures for regulated industries (food, pharma)
- Inventory accuracy issues

### The Solution

Build an extension that **intercepts the Warehouse Pick creation process** to ensure BC can only suggest compliant lots and bins. This is proactive enforcement at the source, not reactive correction after picks are created.

### Key Insight

> **"If you wait until the Pick is already generated, you're performing corrective surgery on committed data. By intercepting the Create Pick logic in Codeunit 7312, you control the source of truth."**

---

## TECHNICAL ARCHITECTURE

### Core Strategy: Three-Layer Enforcement

```
┌─────────────────────────────────────────────────────────┐
│  LAYER 1: PRE-FILTER                                    │
│  Query Item Ledger Entry → Rank lots by Expiration      │
│  (FEFO) or Posting Date/Entry No (FIFO)                 │
│  Store "Target Lot Queue" in memory                     │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  LAYER 2: OVERRIDE                                      │
│  When Codeunit 7312 searches Bin Content, inject filter:│
│  BinContent.SetRange("Lot No.", TargetLot)              │
│  BC only "sees" bins containing compliant lots          │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  LAYER 3: AUDIT + APPROVAL                              │
│  After line creation, log allocation decision           │
│  At registration, validate scanned lot matches          │
│  Any deviation → Teams approval from Supervisor         │
└─────────────────────────────────────────────────────────┘
```

### Event Subscribers

Focus on these BC codeunits:

| Codeunit | Event | Purpose |
|----------|-------|---------|
| **5773** | `OnBeforeCreateWhsePickLines` | Entry point - initialize lot ranking |
| **7312** | `OnAfterFindBinContent` | Filter BinContent to only compliant bins |
| **7312** | `OnBeforeCreateTempActivityLine` | Validate lot is #1 in FIFO/FEFO queue |
| **7312** | `OnAfterCreateWhseActivLine` | Log to audit table |
| **7307** | `OnBeforeRegisterWhseJnlLine` | Final validation at registration |

### Multi-Lot "Top-Up" Algorithm

When the oldest lot has insufficient quantity:

```
1. Order needs 100 units
2. Query all lots sorted by FEFO/FIFO:
   ┌──────────┬────────────┬───────────┐
   │ Lot No.  │ Exp. Date  │ Available │
   ├──────────┼────────────┼───────────┤
   │ LOT-001  │ 2025-01-15 │ 40        │
   │ LOT-002  │ 2025-02-20 │ 80        │
   └──────────┴────────────┴───────────┘
3. Allocate: 40 from LOT-001, then 60 from LOT-002
4. Result: Two pick lines, both FEFO-compliant

### Case Study: 600-Unit Pick
**Scenario**: User requires 600 units. "Lot Numbers by Bin" factbox shows:
- Lot 552146 (131 units)
- Lot 554011 (469 units)
**Extension Goal**: Automatically split the pick into 131 units from the first lot and 469 units from the second, ensuring the older stock is purged.
```

---

## SETUP PAGE DESIGN

Create a Setup page with these toggles:

### General FastTab
| Field | Type | Description |
|-------|------|-------------|
| `Enabled` | Boolean | Master on/off |
| `Mode` | Option | "FIFO (Oldest First)" / "FEFO (Expire First)" |
| `Respect BC Settings` | Boolean | If ON, detect BC's "Pick According to FEFO" and add enforcement layer rather than conflicting |

### Picking Rules FastTab
| Field | Type | Description |
|-------|------|-------------|
| `Enforce Bin Sequence` | Boolean | Must respect Bin Ranking order |
| `Enforce Zone Sequence` | Boolean | Must pick from designated Pick zones first |
| `Allow Partial Lot Consumption` | Boolean | Can split quantity across multiple lots |
| `Strict Mode` | Boolean | Block pick entirely if non-compliant (vs. allowing override) |

### Override Workflow FastTab
| Field | Type | Description |
|-------|------|-------------|
| `Require Supervisor Approval` | Boolean | All overrides need Teams approval |
| `Teams Webhook URL` | Text[250] | Incoming webhook for approval cards |
| `Approval Timeout (Minutes)` | Integer | Auto-reject after timeout |

### Audit FastTab
| Field | Type | Description |
|-------|------|-------------|
| `Enable Full Audit Trail` | Boolean | Log every allocation decision |
| `Retain Logs (Days)` | Integer | Cleanup policy |

---

## OVERRIDE WORKFLOW

**Every deviation requires Teams approval from a Supervisor. Every override is audited and logged.**

### Flow
1. Picker scans a lot different from recommendation
2. Extension detects deviation
3. Adaptive Card sent to Teams (Supervisor channel)
4. Card shows: Picker, Document, Item, Expected Lot, Scanned Lot, Reason field
5. Supervisor clicks Approve/Reject
6. Webhook callback updates BC
7. Audit log records decision with timestamp and approver

---

## OBJECT ID RANGES

Use ID range 50400-50499:

| ID | Type | Name |
|----|------|------|
| 50400 | Table | GO365 FIFO Setup |
| 50401 | Table | GO365 Compliance Audit Log |
| 50410 | Page | GO365 FIFO Setup Card |
| 50411 | Page | GO365 Compliance Log List |
| 50420 | Codeunit | GO365 Lot Ranker |
| 50421 | Codeunit | GO365 Pick Interceptor |
| 50422 | Codeunit | GO365 Compliance Auditor |
| 50423 | Codeunit | GO365 Teams Notifier |
| 50401 | PageExt | Location Card Extension |
| 50402 | PageExt | Warehouse Pick Extension |

---

## APPSOURCE REQUIREMENTS

- [ ] No direct table modifications (Event Subscribers only)
- [ ] Respects standard BC logic (filters, doesn't replace)
- [ ] Multi-language support (Caption ML properties)
- [ ] Help URLs pointing to documentation
- [ ] Application Insights telemetry
- [ ] Permission Sets (FIFO User, FIFO Admin)
- [ ] Automated test codeunits

---

## SCOPE FOR V1 (MVP)

**Pick-Only Enforcement**
- Hook into Codeunit 7312 at "Create Pick"
- Enforce FIFO/FEFO on outbound picks
- Teams approval for overrides
- Full audit logging

**Deferred to V2:**
- Put-away enforcement (ensure stock placed in FEFO-sortable locations)
- Cross-dock FEFO respect (check aging before bypassing storage)

---

## CROSS-DOCKING NOTE

Cross-docking = goods go directly from receiving to shipping without entering storage.

**FIFO/FEFO Risk**: New shipment with long expiration could "jump the queue" over older stock in storage. The extension should eventually include a toggle "Cross-dock FEFO Respect" to check aging before allowing cross-dock bypass. This is V2 scope.

---

## KEY BC TABLES TO QUERY

| Table | Purpose |
|-------|---------|
| `Item Ledger Entry` | Lot numbers, expiration dates, posting dates, remaining qty |
| `Bin Content` | What's in each bin right now |
| `Warehouse Entry` | Movement history |
| `Bin` | Bin rankings and zone assignments |
| `Zone` | Zone rankings |
| `Location` | "Pick According to FEFO" toggle, "Directed Put-away and Pick" |
| `Item Tracking Code` | Lot/Serial tracking requirements |

---

## IMPLEMENTATION ORDER

1. **Setup Table + Page** - Configuration first
2. **Lot Ranker Codeunit** - Query ILE, sort by FEFO/FIFO
3. **Pick Interceptor Codeunit** - Event subscribers for Codeunit 7312
4. **Audit Log Table + Page** - Compliance logging
5. **Teams Notifier Codeunit** - Adaptive Card integration
6. **Page Extensions** - Location Card, Warehouse Pick
7. **Test Codeunits** - Automated testing

---

## SUCCESS CRITERIA

1. When "Create Pick" runs, the Pick Sheet shows **only** compliant lots/bins
2. Pickers cannot see non-compliant options on their Pick Sheet
3. If a picker scans a different lot at registration, they are blocked pending approval
4. All allocations and overrides are logged for audit
5. Extension respects BC's existing FEFO toggle without conflicting

---

## KNOWN LIMITATIONS (SME SCOPE)

### Target Market

This extension is designed for **SME warehouses** (Small and Medium Enterprises) with:
- 1-10 concurrent pickers
- Low frequency of simultaneous picks for identical items
- Standard BC warehouse complexity

### Concurrency Limitation

**The Problem**: When multiple pickers create Pick Sheets for the same item simultaneously, there is a race condition:

```
Time 0:00 - Picker A runs "Create Pick" for Item X
           → Extension queries: LOT-001 has 100 available
           → Pick Sheet A suggests LOT-001

Time 0:01 - Picker B runs "Create Pick" for Item X  
           → Extension queries: LOT-001 still shows 100 (not yet reserved!)
           → Pick Sheet B also suggests LOT-001

Time 0:05 - Both pickers arrive at LOT-001
           → Physical conflict
```

**Why It's Acceptable for SME**: In SME warehouses, concurrent picks for identical items are rare. Solving this would require real-time reservation systems that add significant complexity and cost.

### Documentation Requirement

Include this note in marketing materials and user documentation:

> **Note for High-Volume Warehouses**: This extension is optimized for SME warehouses where concurrent picks for identical items are infrequent. In high-concurrency environments, standard BC reservation logic should be used alongside this extension to prevent double-allocation.

---

## START HERE

Begin by creating the `app.json` and folder structure for an AL extension project. Then implement the Setup Table and Page before moving to the core enforcement logic.

Use this prompt as your architectural guide throughout development.
