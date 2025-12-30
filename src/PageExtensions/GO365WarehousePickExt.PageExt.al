/// <summary>
/// Page extension for Warehouse Pick to add FIFO/FEFO compliance status and actions.
/// </summary>
pageextension 50402 "GO365 Warehouse Pick Ext" extends "Warehouse Pick"
{
    layout
    {
        addlast(General)
        {
            field("GO365 Compliance Status"; ComplianceStatusText)
            {
                ApplicationArea = Warehouse;
                Caption = 'FIFO/FEFO Status';
                Editable = false;
                ToolTip = 'Shows whether this pick complies with FIFO/FEFO rules.';
                StyleExpr = ComplianceStyleExpr;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action("GO365 Request Override")
            {
                ApplicationArea = Warehouse;
                Caption = 'Request Override';
                Image = ApplyEntries;
                ToolTip = 'Request supervisor approval to deviate from FIFO/FEFO rules for this pick.';
                Enabled = HasComplianceIssues;

                trigger OnAction()
                var
                    ComplianceAuditor: Codeunit "GO365 Compliance Auditor";
                    LotRanker: Codeunit "GO365 Lot Ranker";
                    OverrideReasonInput: Page "GO365 Override Reason Input";
                    OverrideReason: Text[250];
                begin
                    if OverrideReasonInput.RunModal() = Action::OK then begin
                        OverrideReason := OverrideReasonInput.GetReason();
                        if OverrideReason = '' then
                            Error('An override reason is required.');

                        // Create override request
                        ComplianceAuditor.CreateOverrideRequest(
                            Rec."No.",
                            0, // Line No
                            '', // Item No - filled from pick lines
                            Rec."Location Code",
                            '', // Expected Lot
                            '', // Requested Lot
                            '', // Expected Bin
                            '', // Requested Bin
                            0, // Qty
                            OverrideReason);

                        Message('Override request submitted for supervisor approval.');
                    end;
                end;
            }
            action("GO365 View Compliance Log")
            {
                ApplicationArea = Warehouse;
                Caption = 'View Compliance Log';
                Image = Log;
                ToolTip = 'View the compliance audit log for this pick.';
                RunObject = page "GO365 Compliance Log List";
                RunPageLink = "Document No." = field("No.");
            }
        }
    }

    var
        ComplianceStatusText: Text[50];
        ComplianceStyleExpr: Text;
        HasComplianceIssues: Boolean;

    trigger OnAfterGetRecord()
    begin
        UpdateComplianceStatus();
    end;

    local procedure UpdateComplianceStatus()
    var
        FIFOSetup: Record "GO365 FIFO Setup";
        AuditLog: Record "GO365 Compliance Audit Log";
    begin
        FIFOSetup.GetOrCreate();
        if not FIFOSetup.Enabled then begin
            ComplianceStatusText := 'Not Enabled';
            ComplianceStyleExpr := 'Standard';
            HasComplianceIssues := false;
            exit;
        end;

        // Check for any non-compliant entries
        AuditLog.SetRange("Document No.", Rec."No.");
        AuditLog.SetRange("Was FIFO/FEFO Compliant", false);
        if not AuditLog.IsEmpty then begin
            ComplianceStatusText := '⚠️ Deviations Found';
            ComplianceStyleExpr := 'Unfavorable';
            HasComplianceIssues := true;
        end else begin
            AuditLog.SetRange("Was FIFO/FEFO Compliant");
            if AuditLog.IsEmpty then begin
                ComplianceStatusText := 'Pending';
                ComplianceStyleExpr := 'Standard';
            end else begin
                ComplianceStatusText := '✓ Compliant';
                ComplianceStyleExpr := 'Favorable';
            end;
            HasComplianceIssues := false;
        end;
    end;
}
