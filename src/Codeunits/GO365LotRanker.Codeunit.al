/// <summary>
/// Codeunit for ranking lots by FIFO (Oldest First) or FEFO (Expire First) rules.
/// Queries Item Ledger Entry to build a prioritized queue of lots for picking.
/// </summary>
codeunit 50420 "GO365 Lot Ranker"
{
    Access = Public;

    var
        FIFOSetup: Record "GO365 FIFO Setup";
        SetupLoaded: Boolean;

    /// <summary>
    /// Ranks all available lots for an item at a location based on FIFO/FEFO rules.
    /// Returns a temporary table with lots sorted by priority (rank 1 = pick first).
    /// </summary>
    procedure RankLotsForItem(ItemNo: Code[20]; LocationCode: Code[10]; var TempLotRanking: Record "GO365 Lot Ranking" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        EffectiveMode: Enum "GO365 Compliance Mode";
        MinExpirationDate: Date;
        RankNo: Integer;
    begin
        LoadSetup();
        TempLotRanking.Reset();
        TempLotRanking.DeleteAll();

        // Determine effective mode for this specific item
        EffectiveMode := GetEffectiveComplianceMode(ItemNo);

        // Calculate minimum expiration date based on shelf life requirement
        MinExpirationDate := CalcMinimumExpirationDate();

        // Query Item Ledger Entry for lots with remaining quantity
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
        ItemLedgerEntry.SetFilter("Lot No.", '<>%1', '');

        // Sort based on effective compliance mode for THIS item
        case EffectiveMode of
            EffectiveMode::FEFO:
                begin
                    ItemLedgerEntry.SetCurrentKey("Item No.", "Location Code", "Expiration Date");
                    ItemLedgerEntry.SetAscending("Expiration Date", true);
                end;
            EffectiveMode::FIFO:
                begin
                    ItemLedgerEntry.SetCurrentKey("Item No.", "Location Code", "Posting Date", "Entry No.");
                    ItemLedgerEntry.SetAscending("Posting Date", true);
                    ItemLedgerEntry.SetAscending("Entry No.", true);
                end;
        end;

        RankNo := 0;
        if ItemLedgerEntry.FindSet() then
            repeat
                // Only process lots that meet shelf life requirements
                if MeetsShelfLifeRequirement(ItemLedgerEntry."Expiration Date", MinExpirationDate, EffectiveMode) then begin
                    // Aggregate by lot (multiple ILEs may exist for the same lot)
                    if not TempLotRanking.Get(ItemNo, LocationCode, ItemLedgerEntry."Lot No.") then begin
                        RankNo += 1;
                        TempLotRanking.Init();
                        TempLotRanking."Item No." := ItemNo;
                        TempLotRanking."Location Code" := LocationCode;
                        TempLotRanking."Lot No." := ItemLedgerEntry."Lot No.";
                        TempLotRanking.Rank := RankNo;
                        TempLotRanking."Expiration Date" := ItemLedgerEntry."Expiration Date";
                        TempLotRanking."Posting Date" := ItemLedgerEntry."Posting Date";
                        TempLotRanking."Available Qty" := ItemLedgerEntry."Remaining Quantity";
                        TempLotRanking.Insert();
                    end else begin
                        // Aggregate quantity for same lot
                        TempLotRanking."Available Qty" += ItemLedgerEntry."Remaining Quantity";
                        TempLotRanking.Modify();
                    end;
                end;
            until ItemLedgerEntry.Next() = 0;
    end;

    /// <summary>
    /// Determines the effective FIFO/FEFO mode for a specific item.
    /// If "Respect Item Tracking Code" is enabled:
    ///   - Items with Item Tracking Code that has expiration tracking → FEFO
    ///   - Items with lot-only tracking (no expiration) → FIFO
    /// Otherwise uses the global Setup.Mode setting.
    /// </summary>
    procedure GetEffectiveComplianceMode(ItemNo: Code[20]): Enum "GO365 Compliance Mode"
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LoadSetup();

        // If not respecting item tracking code, use global mode
        if not FIFOSetup."Respect Item Tracking Code" then
            exit(FIFOSetup.Mode);

        // Get Item and its tracking code
        if not Item.Get(ItemNo) then
            exit(FIFOSetup.Mode);

        if Item."Item Tracking Code" = '' then
            exit(FIFOSetup.Mode);

        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            exit(FIFOSetup.Mode);

        // Check if Item Tracking Code requires expiration date
        // If it has expiration tracking, use FEFO; otherwise use FIFO
        if ItemTrackingCode."Man. Expir. Date Entry Reqd." or
           ItemTrackingCode."Strict Expiration Posting" then
            exit(Enum::"GO365 Compliance Mode"::FEFO)
        else
            exit(Enum::"GO365 Compliance Mode"::FIFO);
    end;

    /// <summary>
    /// Checks all lots for an item and logs violations for those not meeting shelf life.
    /// Called during pick creation to log and request approval for near-expiry lots.
    /// Returns number of violations logged.
    /// </summary>
    procedure CheckAndLogShelfLifeViolations(
        DocumentNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        RequiredQty: Decimal): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ComplianceAuditor: Codeunit "GO365 Compliance Auditor";
        EffectiveMode: Enum "GO365 Compliance Mode";
        MinExpirationDate: Date;
        ViolationCount: Integer;
    begin
        LoadSetup();
        EffectiveMode := GetEffectiveComplianceMode(ItemNo);
        MinExpirationDate := CalcMinimumExpirationDate();
        ViolationCount := 0;

        // Only check FEFO items
        if EffectiveMode <> Enum::"GO365 Compliance Mode"::FEFO then
            exit(0);

        // Query all lots with remaining quantity
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
        ItemLedgerEntry.SetFilter("Lot No.", '<>%1', '');
        ItemLedgerEntry.SetCurrentKey("Item No.", "Location Code", "Expiration Date");

        if ItemLedgerEntry.FindSet() then
            repeat
                // Check if this lot violates shelf life requirements
                if not MeetsShelfLifeRequirement(ItemLedgerEntry."Expiration Date", MinExpirationDate, EffectiveMode) then begin
                    // Log the violation and request approval
                    ComplianceAuditor.LogShelfLifeViolation(
                        DocumentNo,
                        ItemNo,
                        LocationCode,
                        ItemLedgerEntry."Lot No.",
                        ItemLedgerEntry."Expiration Date",
                        MinExpirationDate,
                        ItemLedgerEntry."Remaining Quantity",
                        ''); // Bin code determined later

                    ViolationCount += 1;
                end;
            until ItemLedgerEntry.Next() = 0;

        exit(ViolationCount);
    end;

    /// <summary>
    /// Gets the top-ranked lot for an item at a location.
    /// Returns empty if no lots are available.
    /// </summary>
    procedure GetTopLot(ItemNo: Code[20]; LocationCode: Code[10]): Code[50]
    var
        TempLotRanking: Record "GO365 Lot Ranking" temporary;
    begin
        RankLotsForItem(ItemNo, LocationCode, TempLotRanking);
        TempLotRanking.Reset();
        TempLotRanking.SetCurrentKey(Rank);
        if TempLotRanking.FindFirst() then
            exit(TempLotRanking."Lot No.");
        exit('');
    end;

    /// <summary>
    /// Checks if a given lot is the top-ranked (most compliant) lot.
    /// </summary>
    procedure IsTopLot(ItemNo: Code[20]; LocationCode: Code[10]; LotNo: Code[50]): Boolean
    begin
        exit(GetTopLot(ItemNo, LocationCode) = LotNo);
    end;

    /// <summary>
    /// Gets the rank of a specific lot (1 = top priority).
    /// Returns 0 if lot is not found in the ranking.
    /// </summary>
    procedure GetLotRank(ItemNo: Code[20]; LocationCode: Code[10]; LotNo: Code[50]): Integer
    var
        TempLotRanking: Record "GO365 Lot Ranking" temporary;
    begin
        RankLotsForItem(ItemNo, LocationCode, TempLotRanking);
        if TempLotRanking.Get(ItemNo, LocationCode, LotNo) then
            exit(TempLotRanking.Rank);
        exit(0);
    end;

    /// <summary>
    /// Allocates lots for a required quantity using FIFO/FEFO rules.
    /// Handles multi-lot "top-up" when the oldest lot has insufficient quantity.
    /// </summary>
    procedure AllocateLotsForQuantity(ItemNo: Code[20]; LocationCode: Code[10]; RequiredQty: Decimal; var TempAllocation: Record "GO365 Lot Allocation" temporary)
    var
        TempLotRanking: Record "GO365 Lot Ranking" temporary;
        RemainingQty: Decimal;
        AllocQty: Decimal;
    begin
        LoadSetup();
        TempAllocation.Reset();
        TempAllocation.DeleteAll();

        if not FIFOSetup."Allow Partial Lot Consumption" then begin
            // Single lot only - return top lot
            TempAllocation.Init();
            TempAllocation."Item No." := ItemNo;
            TempAllocation."Location Code" := LocationCode;
            TempAllocation."Lot No." := GetTopLot(ItemNo, LocationCode);
            TempAllocation.Quantity := RequiredQty;
            TempAllocation.Rank := 1;
            TempAllocation.Insert();
            exit;
        end;

        // Multi-lot allocation
        RankLotsForItem(ItemNo, LocationCode, TempLotRanking);
        TempLotRanking.Reset();
        TempLotRanking.SetCurrentKey(Rank);

        RemainingQty := RequiredQty;
        if TempLotRanking.FindSet() then
            repeat
                if RemainingQty <= 0 then
                    exit;

                AllocQty := MinDecimal(TempLotRanking."Available Qty", RemainingQty);
                if AllocQty > 0 then begin
                    TempAllocation.Init();
                    TempAllocation."Item No." := ItemNo;
                    TempAllocation."Location Code" := LocationCode;
                    TempAllocation."Lot No." := TempLotRanking."Lot No.";
                    TempAllocation.Quantity := AllocQty;
                    TempAllocation.Rank := TempLotRanking.Rank;
                    TempAllocation."Expiration Date" := TempLotRanking."Expiration Date";
                    TempAllocation.Insert();

                    RemainingQty -= AllocQty;
                end;
            until (TempLotRanking.Next() = 0) or (RemainingQty <= 0);
    end;

    local procedure LoadSetup()
    begin
        if not SetupLoaded then begin
            FIFOSetup.GetOrCreate();
            SetupLoaded := true;
        end;
    end;

    local procedure MinDecimal(Val1: Decimal; Val2: Decimal): Decimal
    begin
        if Val1 < Val2 then
            exit(Val1);
        exit(Val2);
    end;

    /// <summary>
    /// Calculates the minimum expiration date based on the Minimum Shelf Life setting.
    /// For example, if Minimum Shelf Life is "6M", returns today + 6 months.
    /// </summary>
    local procedure CalcMinimumExpirationDate(): Date
    begin
        LoadSetup();
        if Format(FIFOSetup."Minimum Shelf Life") = '' then
            exit(0D); // No minimum shelf life requirement

        exit(CalcDate(FIFOSetup."Minimum Shelf Life", Today));
    end;

    /// <summary>
    /// Checks if a lot meets the shelf life requirements.
    /// Returns TRUE if the lot can be picked.
    /// </summary>
    local procedure MeetsShelfLifeRequirement(ExpirationDate: Date; MinExpirationDate: Date; ComplianceMode: Enum "GO365 Compliance Mode"): Boolean
    begin
        LoadSetup();

        // For FIFO mode (no expiration tracking), always allow
        if ComplianceMode = Enum::"GO365 Compliance Mode"::FIFO then
            exit(true);

        // Skip exclusion logic if disabled
        if not FIFOSetup."Exclude Expired Lots" then
            exit(true);

        // If no expiration date on lot, check setup behavior
        if ExpirationDate = 0D then
            exit(true); // Allow lots without expiration dates

        // Check if already expired
        if ExpirationDate < Today then
            exit(false);

        // Check minimum shelf life (if configured)
        if MinExpirationDate <> 0D then
            if ExpirationDate < MinExpirationDate then
                exit(false);

        exit(true);
    end;
}
