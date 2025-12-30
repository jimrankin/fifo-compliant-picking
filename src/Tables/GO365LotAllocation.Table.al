/// <summary>
/// Temporary table for lot allocation results.
/// Used by the Lot Ranker codeunit when allocating across multiple lots.
/// </summary>
table 50404 "GO365 Lot Allocation"
{
    Caption = 'GO365 Lot Allocation';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
        }
        field(3; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            DataClassification = SystemMetadata;
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(11; Rank; Integer)
        {
            Caption = 'Rank';
            DataClassification = SystemMetadata;
        }
        field(12; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            DataClassification = SystemMetadata;
        }
        field(13; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Item No.", "Location Code", "Lot No.")
        {
            Clustered = true;
        }
        key(Rank; Rank)
        {
        }
    }
}
