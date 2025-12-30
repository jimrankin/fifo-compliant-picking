# FIFO/FEFO Picking Compliance Extension
## Executive Summary for Stakeholders

**Document Date:** 30 December 2024  
**Publisher:** GO365 Ltd  
**Status:** Development Complete – Ready for Sandbox Testing

---

## Business Problem

Warehouse pickers in Business Central often deviate from system-suggested lots and bins. The standard BC "Pick According to FEFO" toggle provides **suggestions** but does not **enforce** compliance. This leads to:

- ❌ Expired stock remaining in warehouse while fresher stock ships
- ❌ Audit failures for regulated industries (food, pharma, chemicals)
- ❌ Customer complaints about short shelf life on delivered goods
- ❌ Inventory accuracy issues and write-offs

---

## Our Solution

A Business Central extension that **proactively enforces** FIFO/FEFO picking compliance by intercepting the warehouse pick creation process. Instead of correcting mistakes after picks are created, we control the source of truth.

### Three-Layer Enforcement Model

```
┌─────────────────────────────────────────────┐
│  LAYER 1: PRE-FILTER                        │
│  Automatically rank lots by expiry/age      │
│  Exclude lots that don't meet shelf life    │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  LAYER 2: OVERRIDE                          │
│  BC only "sees" compliant lots/bins         │
│  Non-compliant options hidden from pickers  │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  LAYER 3: AUDIT + APPROVAL                  │
│  Every deviation logged for audit           │
│  Teams approval for supervisor overrides    │
└─────────────────────────────────────────────┘
```

---

## Key Features

### 1. Smart Item Detection
- **LOTEXP items** (with expiration tracking) → Automatic FEFO enforcement
- **LOTALL items** (lot-only) → Automatic FIFO enforcement
- No manual configuration needed per item

### 2. Customer Shelf Life Requirements
- Configurable **minimum remaining shelf life** (e.g., 6 months)
- Lots not meeting shelf life are **automatically flagged**
- Supervisor approval required before shipping near-expiry stock

### 3. Teams Integration
- Override requests sent to **Microsoft Teams** for supervisor approval
- Adaptive Cards with all context (item, lot, reason)
- Approve/Reject directly from Teams
- Configurable timeout (auto-reject if no response)

### 4. Complete Audit Trail
- Every allocation decision logged
- Every override tracked with approver and timestamp
- Exportable for compliance audits
- Configurable retention period

---

## Configuration Options

| Setting | Description |
|---------|-------------|
| **Mode** | FIFO (Oldest First) or FEFO (Expire First) |
| **Respect Item Tracking Code** | Auto-detect FIFO/FEFO per item |
| **Minimum Shelf Life** | e.g., "6M" for 6 months minimum |
| **Exclude Expired Lots** | Skip already-expired lots |
| **Strict Mode** | Block picks if no compliant lots available |
| **Allow Partial Lot Consumption** | Split across multiple lots |
| **Require Supervisor Approval** | Teams approval for deviations |

---

## Target Market

**SME Warehouses** with:
- 1-10 concurrent pickers
- Standard BC warehouse complexity
- Regulated industries requiring audit trails

> **Note:** For high-volume warehouses with frequent concurrent picks for identical items, standard BC reservation logic should be used alongside this extension.

---

## Technical Summary

| Metric | Value |
|--------|-------|
| Object Range | 50400-50499 |
| Tables | 5 |
| Pages | 5 |
| Codeunits | 4 |
| Page Extensions | 2 |
| Permission Sets | 2 |
| BC Runtime | 16.0 |
| Base Application | 27.0.0.0 |
| Code Protected | Yes |

---

## AppSource Readiness

- ✅ No direct table modifications (event subscribers only)
- ✅ Respects standard BC logic
- ✅ Code protection enabled
- ✅ Permission sets included
- ✅ Help URLs configured
- 🔲 Multi-language translations (pending)
- 🔲 Application Insights integration (hooks ready)
- 🔲 Automated test codeunits (pending)

---

## Next Steps

1. **Sandbox Testing** – Deploy to BC sandbox, test with real warehouse data
2. **User Acceptance Testing** – Warehouse supervisors validate workflow
3. **Teams Integration** – Configure Power Automate flow for approvals
4. **AppSource Submission** – Target Q1 2026 after Microsoft partnership discussions

---

## Contact

**GO365 Ltd**  
https://go365.solutions

---

*This extension ensures your warehouse operations comply with FIFO/FEFO best practices, reducing waste, improving audit readiness, and protecting your customer relationships.*
