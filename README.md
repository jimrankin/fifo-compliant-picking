# FIFO Compliant Picking

Business Central extension for FIFO/FEFO picking compliance enforcement.

## Overview

This extension intercepts the Warehouse Pick creation process to ensure Business Central only suggests compliant lots and bins based on **FIFO** (First-In, First-Out) or **FEFO** (First-Expired, First-Out) rules.

## Features

- **Three-Layer Enforcement Model**
  - Layer 1: Pre-Filter (ranks lots by expiration/posting date)
  - Layer 2: Override (filters Bin Content to compliant bins only)
  - Layer 3: Audit + Approval (logs all decisions, Teams approval for overrides)

- **Configurable Setup**
  - FIFO or FEFO mode selection
  - Strict mode option (block non-compliant picks)
  - Multi-lot splitting for partial consumption
  - Bin and Zone sequence enforcement

- **Teams Integration**
  - Supervisor approval workflow via Adaptive Cards
  - Power Automate integration with External Business Events
  - Configurable timeout for approval requests

- **Full Audit Trail**
  - Logs every allocation decision
  - Tracks all overrides with approver and timestamp
  - Configurable retention period

## Installation

1. Open VS Code with this project
2. Configure `.vscode/launch.json` with your BC sandbox details
3. Press `Ctrl+Shift+P` → "AL: Publish without debugging"
4. Navigate to "FIFO/FEFO Picking Compliance Setup" in BC

## Configuration

### Setup Page Fields

| FastTab | Field | Description |
|---------|-------|-------------|
| General | Enabled | Master on/off toggle |
| General | Mode | FIFO (Oldest First) or FEFO (Expire First) |
| General | Respect BC Settings | Detect BC's "Pick According to FEFO" |
| Picking Rules | Enforce Bin Sequence | Respect Bin Ranking order |
| Picking Rules | Allow Partial Lot Consumption | Split across multiple lots |
| Picking Rules | Strict Mode | Block non-compliant picks entirely |
| Override Workflow | Require Supervisor Approval | Teams approval for deviations |
| Override Workflow | Teams Webhook URL | Power Automate trigger URL |
| Override Workflow | Approval Timeout | Minutes before auto-reject |
| Audit | Enable Full Audit Trail | Log all allocations |
| Audit | Retain Logs (Days) | Cleanup policy |

## Object ID Range

| ID | Type | Name |
|----|------|------|
| 50400-50404 | Tables | Setup, Audit Log, Override Request, Lot Ranking, Lot Allocation |
| 50400-50401 | Enums | Compliance Mode, Override Status |
| 50410-50413 | Pages | Setup Card, Log List, Override API, Override Reason Input |
| 50420-50423 | Codeunits | Lot Ranker, Pick Interceptor, Compliance Auditor, Teams Notifier |
| 50401-50402 | PageExt | Location Card, Warehouse Pick |
| 50400-50401 | PermSets | FIFO User, FIFO Admin |

## Known Limitations

**SME Focus**: This extension is optimized for SME warehouses (1-10 concurrent pickers) where simultaneous picks for identical items are infrequent. In high-concurrency environments, use standard BC reservation logic alongside this extension.

## Publisher

GO365 Ltd - https://go365.solutions

## License

Proprietary - All rights reserved
