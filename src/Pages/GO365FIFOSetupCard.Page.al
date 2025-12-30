/// <summary>
/// Setup Card page for configuring FIFO/FEFO Picking Compliance settings.
/// </summary>
page 50410 "GO365 FIFO Setup Card"
{
    Caption = 'FIFO/FEFO Picking Compliance Setup';
    PageType = Card;
    ApplicationArea = Warehouse;
    UsageCategory = Administration;
    SourceTable = "GO365 FIFO Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Enable or disable FIFO/FEFO picking compliance enforcement.';
                }
                field(Mode; Rec.Mode)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Select FIFO (First-In, First-Out) to prioritize oldest stock, or FEFO (First-Expired, First-Out) to prioritize stock expiring soonest.';
                }
                field("Respect BC Settings"; Rec."Respect BC Settings")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'If enabled, the extension will detect BC''s "Pick According to FEFO" setting and add enforcement rather than conflicting with it.';
                }
                field("Respect Item Tracking Code"; Rec."Respect Item Tracking Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'If enabled, automatically detect FIFO vs FEFO per item based on Item Tracking Code. Items with expiration tracking (e.g., LOTEXP) use FEFO; items with lot-only tracking (e.g., LOTALL) use FIFO.';
                }
            }
            group(PickingRules)
            {
                Caption = 'Picking Rules';

                field("Enforce Bin Sequence"; Rec."Enforce Bin Sequence")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Require picks to respect Bin Ranking order within FIFO/FEFO compliance.';
                }
                field("Enforce Zone Sequence"; Rec."Enforce Zone Sequence")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Require picks to prioritize designated Pick zones before other zones.';
                }
                field("Allow Partial Lot Consumption"; Rec."Allow Partial Lot Consumption")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Allow splitting quantity across multiple lots when the oldest lot has insufficient quantity.';
                }
                field("Strict Mode"; Rec."Strict Mode")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Block pick creation entirely if no compliant lots are available. If disabled, non-compliant picks require override approval.';
                }
                field("Minimum Shelf Life"; Rec."Minimum Shelf Life")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Minimum remaining shelf life required for outbound picks. Use date formula format: 6M = 6 months, 90D = 90 days. Leave empty to disable.';
                }
                field("Exclude Expired Lots"; Rec."Exclude Expired Lots")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Automatically exclude expired lots from pick suggestions.';
                }
            }
            group(OverrideWorkflow)
            {
                Caption = 'Override Workflow';

                field("Require Supervisor Approval"; Rec."Require Supervisor Approval")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Require supervisor approval via Teams for any FIFO/FEFO deviation.';
                }
                field("Teams Webhook URL"; Rec."Teams Webhook URL")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'URL for the Teams channel Incoming Webhook connector to receive approval requests.';
                }
                field("Approval Timeout (Minutes)"; Rec."Approval Timeout (Minutes)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Minutes to wait for supervisor response before auto-rejecting the override request.';
                }
                field("Allow Approval Bypass"; Rec."Allow Approval Bypass")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Allow users with appropriate permissions to bypass the approval workflow.';
                }
            }
            group(Audit)
            {
                Caption = 'Audit';

                field("Enable Full Audit Trail"; Rec."Enable Full Audit Trail")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Log every allocation decision for audit purposes, not just overrides.';
                }
                field("Retain Logs (Days)"; Rec."Retain Logs (Days)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Number of days to retain audit logs before automatic cleanup.';
                }
            }
            group(Telemetry)
            {
                Caption = 'Telemetry';

                field("App Insights Connection String"; Rec."App Insights Connection String")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Azure Application Insights connection string for usage and error telemetry.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ViewAuditLog)
            {
                ApplicationArea = Warehouse;
                Caption = 'View Audit Log';
                Image = Log;
                ToolTip = 'View the compliance audit log for all allocation decisions and overrides.';
                RunObject = page "GO365 Compliance Log List";
            }
        }
        area(Processing)
        {
            action(CleanupOldLogs)
            {
                ApplicationArea = Warehouse;
                Caption = 'Cleanup Old Logs';
                Image = Delete;
                ToolTip = 'Delete audit log entries older than the retention period.';

                trigger OnAction()
                var
                    ComplianceAuditor: Codeunit "GO365 Compliance Auditor";
                begin
                    ComplianceAuditor.CleanupOldLogs();
                    Message('Old logs have been cleaned up.');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ViewAuditLog_Promoted; ViewAuditLog) { }
                actionref(CleanupOldLogs_Promoted; CleanupOldLogs) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetOrCreate();
    end;
}
