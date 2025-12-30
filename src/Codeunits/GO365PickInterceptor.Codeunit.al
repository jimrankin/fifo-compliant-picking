/// <summary>
/// Pick Interceptor codeunit that hooks into BC's warehouse pick creation process.
/// Uses table-level events which are guaranteed to exist in all BC versions.
/// </summary>
codeunit 50421 "GO365 Pick Interceptor"
{
    Access = Public;
    SingleInstance = true;

    var
        FIFOSetup: Record "GO365 FIFO Setup";
        LotRanker: Codeunit "GO365 Lot Ranker";
        ComplianceAuditor: Codeunit "GO365 Compliance Auditor";
        // Session state for tracking current pick operation
        CurrentItemNo: Code[20];
        CurrentLocationCode: Code[10];
        TempLotQueue: Record "GO365 Lot Ranking" temporary;
        IsInitialized: Boolean;

    /// <summary>
    /// Event subscriber for Warehouse Activity Line - before insert.
    /// Validates that the lot being picked is compliant.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertWhseActivityLine(var Rec: Record "Warehouse Activity Line"; RunTrigger: Boolean)
    var
        LotRank: Integer;
        TopLot: Code[50];
    begin
        if not IsEnforcementActive() then
            exit;

        // Only process Pick activities
        if Rec."Activity Type" <> Rec."Activity Type"::Pick then
            exit;

        // Only process Take actions (not Place)
        if Rec."Action Type" <> Rec."Action Type"::Take then
            exit;

        // Skip if no lot tracking
        if Rec."Lot No." = '' then
            exit;

        // Get the top-ranked lot for this item/location
        TopLot := LotRanker.GetTopLot(Rec."Item No.", Rec."Location Code");
        if TopLot = '' then
            exit;

        // Get the rank of the assigned lot
        LotRank := LotRanker.GetLotRank(Rec."Item No.", Rec."Location Code", Rec."Lot No.");

        // In strict mode, block non-compliant lots
        if FIFOSetup."Strict Mode" and (LotRank > 1) then
            Error('FIFO/FEFO Compliance Error: Lot %1 is not the oldest available lot (Rank %2). Expected lot %3. Strict mode is enabled.',
                Rec."Lot No.", LotRank, TopLot);
    end;

    /// <summary>
    /// Event subscriber for Warehouse Activity Line - after insert.
    /// Logs the allocation decision to the audit trail.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertWhseActivityLine(var Rec: Record "Warehouse Activity Line"; RunTrigger: Boolean)
    var
        ExpectedLot: Code[50];
        LotRank: Integer;
        IsCompliant: Boolean;
    begin
        if not IsEnforcementActive() then
            exit;

        // Only process Pick activities
        if Rec."Activity Type" <> Rec."Activity Type"::Pick then
            exit;

        // Only process Take actions
        if Rec."Action Type" <> Rec."Action Type"::Take then
            exit;

        // Skip if audit trail is disabled
        if not FIFOSetup."Enable Full Audit Trail" then
            exit;

        // Skip if no lot
        if Rec."Lot No." = '' then
            exit;

        // Get expected lot and rank
        ExpectedLot := LotRanker.GetTopLot(Rec."Item No.", Rec."Location Code");
        LotRank := LotRanker.GetLotRank(Rec."Item No.", Rec."Location Code", Rec."Lot No.");
        IsCompliant := (Rec."Lot No." = ExpectedLot) or (LotRank = 1);

        // Log to audit trail
        ComplianceAuditor.LogPickAllocation(
            Rec."No.",
            Rec."Line No.",
            Rec."Item No.",
            Rec."Location Code",
            ExpectedLot,
            Rec."Lot No.",
            '', // Expected bin
            Rec."Bin Code",
            Rec.Quantity,
            LotRank,
            FIFOSetup.Mode,
            IsCompliant);
    end;

    /// <summary>
    /// Event subscriber for Warehouse Activity Line - before modify.
    /// Validates lot changes during pick modification.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyWhseActivityLine(var Rec: Record "Warehouse Activity Line"; var xRec: Record "Warehouse Activity Line"; RunTrigger: Boolean)
    var
        LotRank: Integer;
        TopLot: Code[50];
    begin
        if not IsEnforcementActive() then
            exit;

        // Only check if lot changed
        if Rec."Lot No." = xRec."Lot No." then
            exit;

        // Only process Pick activities
        if Rec."Activity Type" <> Rec."Activity Type"::Pick then
            exit;

        // Only process Take actions
        if Rec."Action Type" <> Rec."Action Type"::Take then
            exit;

        // Skip if no lot tracking
        if Rec."Lot No." = '' then
            exit;

        // Get the top-ranked lot
        TopLot := LotRanker.GetTopLot(Rec."Item No.", Rec."Location Code");
        if TopLot = '' then
            exit;

        // Get the rank of the new lot
        LotRank := LotRanker.GetLotRank(Rec."Item No.", Rec."Location Code", Rec."Lot No.");

        // In non-strict mode, log deviation; in strict mode, block if not approved
        if LotRank > 1 then begin
            if FIFOSetup."Strict Mode" and not HasApprovedOverride(Rec) then
                Error('FIFO/FEFO Compliance Error: Cannot change to lot %1. Expected lot %2. Override required.',
                    Rec."Lot No.", TopLot);

            // Log if not strict or if approved
            ComplianceAuditor.LogOverrideAtRegistration(
                Rec."Item No.",
                Rec."Location Code",
                TopLot,
                Rec."Lot No.",
                Rec."Bin Code",
                Rec.Quantity);
        end;
    end;

    local procedure IsEnforcementActive(): Boolean
    begin
        FIFOSetup.GetOrCreate();
        exit(FIFOSetup.Enabled);
    end;

    local procedure InitializeLotQueue(ItemNo: Code[20]; LocationCode: Code[10])
    begin
        CurrentItemNo := ItemNo;
        CurrentLocationCode := LocationCode;
        LotRanker.RankLotsForItem(ItemNo, LocationCode, TempLotQueue);
        IsInitialized := true;
    end;

    local procedure HasApprovedOverride(WhseActivityLine: Record "Warehouse Activity Line"): Boolean
    var
        OverrideRequest: Record "GO365 Override Request";
    begin
        // Check for approved override for this specific deviation
        OverrideRequest.Reset();
        OverrideRequest.SetRange("Item No.", WhseActivityLine."Item No.");
        OverrideRequest.SetRange("Location Code", WhseActivityLine."Location Code");
        OverrideRequest.SetRange("Requested Lot No.", WhseActivityLine."Lot No.");
        OverrideRequest.SetRange(Status, OverrideRequest.Status::Approved);
        exit(not OverrideRequest.IsEmpty);
    end;
}
