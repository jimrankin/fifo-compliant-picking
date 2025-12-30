/// <summary>
/// API page for receiving override approval/rejection callbacks from Power Automate or external systems.
/// </summary>
page 50412 "GO365 Override API"
{
    PageType = API;
    Caption = 'GO365 Override API';
    APIPublisher = 'go365';
    APIGroup = 'fifo';
    APIVersion = 'v1.0';
    EntityName = 'overrideRequest';
    EntitySetName = 'overrideRequests';
    SourceTable = "GO365 Override Request";
    DelayedInsert = true;
    ODataKeyFields = "Entry No.";

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    Editable = false;
                }
                field(warehouseActivityNo; Rec."Warehouse Activity No.")
                {
                    Caption = 'Warehouse Activity No.';
                }
                field(warehouseActivityLineNo; Rec."Warehouse Activity Line No.")
                {
                    Caption = 'Warehouse Activity Line No.';
                }
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(expectedLotNo; Rec."Expected Lot No.")
                {
                    Caption = 'Expected Lot No.';
                }
                field(requestedLotNo; Rec."Requested Lot No.")
                {
                    Caption = 'Requested Lot No.';
                }
                field(expectedBinCode; Rec."Expected Bin Code")
                {
                    Caption = 'Expected Bin Code';
                }
                field(requestedBinCode; Rec."Requested Bin Code")
                {
                    Caption = 'Requested Bin Code';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(reason; Rec.Reason)
                {
                    Caption = 'Reason';
                }
                field(requestedBy; Rec."Requested By")
                {
                    Caption = 'Requested By';
                }
                field(requestedDateTime; Rec."Requested DateTime")
                {
                    Caption = 'Requested DateTime';
                }
                field(approvedBy; Rec."Approved By")
                {
                    Caption = 'Approved By';
                }
                field(approvedDateTime; Rec."Approved DateTime")
                {
                    Caption = 'Approved DateTime';
                }
                field(approvalResponse; Rec."Approval Response")
                {
                    Caption = 'Approval Response';
                }
                field(expiresDateTime; Rec."Expires DateTime")
                {
                    Caption = 'Expires DateTime';
                }
                field(wasTimedOut; Rec."Was Timed Out")
                {
                    Caption = 'Was Timed Out';
                }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        ComplianceAuditor: Codeunit "GO365 Compliance Auditor";
        IsApproved: Boolean;
    begin
        // Auto-set approval metadata when status changes to Approved/Rejected
        if (Rec.Status = Rec.Status::Approved) or (Rec.Status = Rec.Status::Rejected) then begin
            if Rec."Approved By" = '' then
                Rec."Approved By" := CopyStr(UserId, 1, MaxStrLen(Rec."Approved By"));
            if Rec."Approved DateTime" = 0DT then
                Rec."Approved DateTime" := CurrentDateTime;

            // Update related audit log entries
            IsApproved := Rec.Status = Rec.Status::Approved;
            ComplianceAuditor.ProcessOverrideDecision(
                Rec."Entry No.",
                IsApproved,
                Rec."Approved By",
                Rec."Approval Response");
        end;

        exit(true);
    end;
}
