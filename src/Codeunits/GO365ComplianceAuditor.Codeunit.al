/// <summary>
/// Compliance Auditor codeunit for logging all FIFO/FEFO allocation decisions.
/// </summary>
codeunit 50422 "GO365 Compliance Auditor"
{
    Access = Public;

    var
        FIFOSetup: Record "GO365 FIFO Setup";

    /// <summary>
    /// Logs a pick allocation decision to the audit trail.
    /// </summary>
    procedure LogPickAllocation(
        DocumentNo: Code[20];
        LineNo: Integer;
        ItemNo: Code[20];
        LocationCode: Code[10];
        ExpectedLot: Code[50];
        AllocatedLot: Code[50];
        ExpectedBin: Code[20];
        AllocatedBin: Code[20];
        Qty: Decimal;
        LotRank: Integer;
        ComplianceMode: Enum "GO365 Compliance Mode";
        IsCompliant: Boolean)
    var
        AuditLog: Record "GO365 Compliance Audit Log";
    begin
        FIFOSetup.GetOrCreate();
        if not FIFOSetup."Enable Full Audit Trail" then
            if IsCompliant then
                exit; // Only log non-compliant if audit trail disabled

        AuditLog.Init();
        AuditLog."Document Type" := AuditLog."Document Type"::"Warehouse Pick";
        AuditLog."Document No." := DocumentNo;
        AuditLog."Line No." := LineNo;
        AuditLog."Item No." := ItemNo;
        AuditLog."Location Code" := LocationCode;
        AuditLog."Expected Lot No." := ExpectedLot;
        AuditLog."Allocated Lot No." := AllocatedLot;
        AuditLog."Expected Bin Code" := ExpectedBin;
        AuditLog."Allocated Bin Code" := AllocatedBin;
        AuditLog.Quantity := Qty;
        AuditLog."Lot Rank" := LotRank;
        AuditLog."Compliance Mode" := ComplianceMode;
        AuditLog."Was FIFO/FEFO Compliant" := IsCompliant;
        AuditLog."Was Override" := not IsCompliant;

        if not IsCompliant then
            AuditLog."Override Status" := AuditLog."Override Status"::Open;

        AuditLog.Insert(true);
    end;

    /// <summary>
    /// Logs an override that occurred at pick registration (scanned different lot).
    /// </summary>
    procedure LogOverrideAtRegistration(
        ItemNo: Code[20];
        LocationCode: Code[10];
        ExpectedLot: Code[50];
        ScannedLot: Code[50];
        BinCode: Code[20];
        Qty: Decimal)
    var
        AuditLog: Record "GO365 Compliance Audit Log";
        LotRanker: Codeunit "GO365 Lot Ranker";
    begin
        FIFOSetup.GetOrCreate();

        AuditLog.Init();
        AuditLog."Document Type" := AuditLog."Document Type"::"Warehouse Pick";
        AuditLog."Item No." := ItemNo;
        AuditLog."Location Code" := LocationCode;
        AuditLog."Expected Lot No." := ExpectedLot;
        AuditLog."Allocated Lot No." := ScannedLot;
        AuditLog."Allocated Bin Code" := BinCode;
        AuditLog.Quantity := Qty;
        AuditLog."Lot Rank" := LotRanker.GetLotRank(ItemNo, LocationCode, ScannedLot);
        AuditLog."Compliance Mode" := FIFOSetup.Mode;
        AuditLog."Was FIFO/FEFO Compliant" := false;
        AuditLog."Was Override" := true;
        AuditLog."Override Status" := AuditLog."Override Status"::Open;
        AuditLog."Override Reason" := 'Scanned different lot at registration';
        AuditLog.Insert(true);
    end;

    /// <summary>
    /// Logs and creates approval request when a lot doesn't meet shelf life requirements.
    /// Called when creating a pick sheet and a required lot is near-expiry or expired.
    /// </summary>
    procedure LogShelfLifeViolation(
        DocumentNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        LotNo: Code[50];
        ExpirationDate: Date;
        MinRequiredDate: Date;
        Qty: Decimal;
        BinCode: Code[20]): Integer
    var
        AuditLog: Record "GO365 Compliance Audit Log";
        OverrideRequest: Record "GO365 Override Request";
        TeamsNotifier: Codeunit "GO365 Teams Notifier";
        ViolationReason: Text[250];
        DaysRemaining: Integer;
    begin
        FIFOSetup.GetOrCreate();

        // Determine violation reason
        if ExpirationDate < Today then
            ViolationReason := StrSubstNo('Lot %1 is expired (Exp: %2)', LotNo, ExpirationDate)
        else begin
            DaysRemaining := ExpirationDate - Today;
            ViolationReason := StrSubstNo('Lot %1 has only %2 days remaining (Exp: %3, Min Required: %4)',
                LotNo, DaysRemaining, ExpirationDate, MinRequiredDate);
        end;

        // Create audit log entry
        AuditLog.Init();
        AuditLog."Document Type" := AuditLog."Document Type"::"Warehouse Pick";
        AuditLog."Document No." := DocumentNo;
        AuditLog."Item No." := ItemNo;
        AuditLog."Location Code" := LocationCode;
        AuditLog."Expected Lot No." := ''; // No expected lot - this is a shelf life violation
        AuditLog."Allocated Lot No." := LotNo;
        AuditLog."Allocated Bin Code" := BinCode;
        AuditLog.Quantity := Qty;
        AuditLog."Compliance Mode" := FIFOSetup.Mode;
        AuditLog."Was FIFO/FEFO Compliant" := false;
        AuditLog."Was Override" := true;
        AuditLog."Override Status" := AuditLog."Override Status"::"Pending Approval";
        AuditLog."Override Reason" := ViolationReason;
        AuditLog.Insert(true);

        // Create override request for supervisor approval
        OverrideRequest.Init();
        OverrideRequest."Warehouse Activity No." := DocumentNo;
        OverrideRequest."Item No." := ItemNo;
        OverrideRequest."Location Code" := LocationCode;
        OverrideRequest."Expected Lot No." := ''; // No compliant lot available
        OverrideRequest."Requested Lot No." := LotNo;
        OverrideRequest."Requested Bin Code" := BinCode;
        OverrideRequest.Quantity := Qty;
        OverrideRequest.Reason := ViolationReason;
        OverrideRequest.Status := OverrideRequest.Status::"Pending Approval";
        OverrideRequest.Insert(true);

        // Trigger Teams notification if configured
        if FIFOSetup."Require Supervisor Approval" and (FIFOSetup."Teams Webhook URL" <> '') then
            TeamsNotifier.RaiseOverrideRequestEvent(OverrideRequest);

        exit(OverrideRequest."Entry No.");
    end;

    /// <summary>
    /// Creates an override request record and optionally triggers Teams notification.
    /// </summary>
    procedure CreateOverrideRequest(
        WarehouseActivityNo: Code[20];
        LineNo: Integer;
        ItemNo: Code[20];
        LocationCode: Code[10];
        ExpectedLot: Code[50];
        RequestedLot: Code[50];
        ExpectedBin: Code[20];
        RequestedBin: Code[20];
        Qty: Decimal;
        Reason: Text[250]): Integer
    var
        OverrideRequest: Record "GO365 Override Request";
        TeamsNotifier: Codeunit "GO365 Teams Notifier";
    begin
        FIFOSetup.GetOrCreate();

        OverrideRequest.Init();
        OverrideRequest."Warehouse Activity No." := WarehouseActivityNo;
        OverrideRequest."Warehouse Activity Line No." := LineNo;
        OverrideRequest."Item No." := ItemNo;
        OverrideRequest."Location Code" := LocationCode;
        OverrideRequest."Expected Lot No." := ExpectedLot;
        OverrideRequest."Requested Lot No." := RequestedLot;
        OverrideRequest."Expected Bin Code" := ExpectedBin;
        OverrideRequest."Requested Bin Code" := RequestedBin;
        OverrideRequest.Quantity := Qty;
        OverrideRequest.Reason := Reason;
        OverrideRequest.Status := OverrideRequest.Status::"Pending Approval";
        OverrideRequest.Insert(true);

        // Trigger Teams notification if configured
        if FIFOSetup."Require Supervisor Approval" and (FIFOSetup."Teams Webhook URL" <> '') then
            TeamsNotifier.RaiseOverrideRequestEvent(OverrideRequest);

        exit(OverrideRequest."Entry No.");
    end;

    /// <summary>
    /// Updates an override request with approval/rejection.
    /// </summary>
    procedure ProcessOverrideDecision(
        EntryNo: Integer;
        IsApproved: Boolean;
        ApprovedBy: Code[50];
        Response: Text[250])
    var
        OverrideRequest: Record "GO365 Override Request";
        AuditLog: Record "GO365 Compliance Audit Log";
    begin
        if not OverrideRequest.Get(EntryNo) then
            exit;

        OverrideRequest."Approved By" := ApprovedBy;
        OverrideRequest."Approved DateTime" := CurrentDateTime;
        OverrideRequest."Approval Response" := Response;

        if IsApproved then
            OverrideRequest.Status := OverrideRequest.Status::Approved
        else
            OverrideRequest.Status := OverrideRequest.Status::Rejected;

        OverrideRequest.Modify(true);

        // Update related audit log entries
        AuditLog.Reset();
        AuditLog.SetRange("Document No.", OverrideRequest."Warehouse Activity No.");
        AuditLog.SetRange("Item No.", OverrideRequest."Item No.");
        AuditLog.SetRange("Allocated Lot No.", OverrideRequest."Requested Lot No.");
        if AuditLog.FindFirst() then begin
            if IsApproved then
                AuditLog."Override Status" := AuditLog."Override Status"::Approved
            else
                AuditLog."Override Status" := AuditLog."Override Status"::Rejected;

            AuditLog."Approved By" := ApprovedBy;
            AuditLog."Approved DateTime" := CurrentDateTime;
            AuditLog."Override Reason" := OverrideRequest.Reason;
            AuditLog.Modify(true);
        end;
    end;

    /// <summary>
    /// Deletes audit log entries older than the retention period.
    /// </summary>
    procedure CleanupOldLogs()
    var
        AuditLog: Record "GO365 Compliance Audit Log";
        CutoffDate: DateTime;
        RetentionDays: Integer;
    begin
        FIFOSetup.GetOrCreate();
        RetentionDays := FIFOSetup."Retain Logs (Days)";

        // Handle case where retention is not set
        if RetentionDays <= 0 then begin
            Message('No retention period configured. Please set "Retain Logs (Days)" in Setup.');
            exit;
        end;

        // Calculate cutoff date using date arithmetic to avoid overflow
        CutoffDate := CreateDateTime(Today - RetentionDays, 0T);
        AuditLog.SetFilter("Created DateTime", '<%1', CutoffDate);

        if AuditLog.IsEmpty then
            Message('No logs older than %1 days found.', RetentionDays)
        else begin
            AuditLog.DeleteAll(true);
            Message('Old logs deleted successfully.');
        end;
    end;

    /// <summary>
    /// Checks and expires timed-out override requests.
    /// </summary>
    procedure ExpireTimedOutRequests()
    var
        OverrideRequest: Record "GO365 Override Request";
    begin
        OverrideRequest.Reset();
        OverrideRequest.SetRange(Status, OverrideRequest.Status::"Pending Approval");
        OverrideRequest.SetFilter("Expires DateTime", '<=%1', CurrentDateTime);
        if OverrideRequest.FindSet() then
            repeat
                OverrideRequest.Status := OverrideRequest.Status::Rejected;
                OverrideRequest."Was Timed Out" := true;
                OverrideRequest."Approval Response" := 'Auto-rejected: Approval timeout exceeded';
                OverrideRequest.Modify(true);
            until OverrideRequest.Next() = 0;
    end;
}
