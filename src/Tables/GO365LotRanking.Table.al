/// <summary>
/// Temporary table for lot ranking results.
/// Used by the Lot Ranker codeunit to return sorted lots.
/// </summary>
table 50403 "GO365 Lot Ranking"
{
    Caption = 'GO365 Lot Ranking';
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
        field(10; Rank; Integer)
        {
            Caption = 'Rank';
            DataClassification = SystemMetadata;
        }
        field(11; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            DataClassification = SystemMetadata;
        }
        field(12; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(13; "Available Qty"; Decimal)
        {
            Caption = 'Available Qty';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
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
