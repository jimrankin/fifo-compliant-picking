/// <summary>
/// Audit log table for tracking all FIFO/FEFO allocation decisions and overrides.
/// </summary>
table 50401 "GO365 Compliance Audit Log"
{
    Caption = 'GO365 Compliance Audit Log';
    DataClassification = CustomerContent;
    DrillDownPageId = "GO365 Compliance Log List";
    LookupPageId = "GO365 Compliance Log List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(10; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
            OptionMembers = " ","Warehouse Pick","Warehouse Shipment","Sales Order";
            OptionCaption = ' ,Warehouse Pick,Warehouse Shipment,Sales Order';
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(12; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
        }
        field(21; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
        }
        field(30; "Expected Lot No."; Code[50])
        {
            Caption = 'Expected Lot No.';
            DataClassification = CustomerContent;
        }
        field(31; "Allocated Lot No."; Code[50])
        {
            Caption = 'Allocated Lot No.';
            DataClassification = CustomerContent;
        }
        field(32; "Expected Bin Code"; Code[20])
        {
            Caption = 'Expected Bin Code';
            DataClassification = CustomerContent;
        }
        field(33; "Allocated Bin Code"; Code[20])
        {
            Caption = 'Allocated Bin Code';
            DataClassification = CustomerContent;
        }
        field(34; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(41; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = CustomerContent;
        }
        field(50; "Lot Rank"; Integer)
        {
            Caption = 'Lot Rank';
            DataClassification = CustomerContent;
        }
        field(51; "Compliance Mode"; Enum "GO365 Compliance Mode")
        {
            Caption = 'Compliance Mode';
            DataClassification = CustomerContent;
        }
        field(52; "Was FIFO/FEFO Compliant"; Boolean)
        {
            Caption = 'Was FIFO/FEFO Compliant';
            DataClassification = CustomerContent;
        }

        // Override tracking
        field(60; "Was Override"; Boolean)
        {
            Caption = 'Was Override';
            DataClassification = CustomerContent;
        }
        field(61; "Override Status"; Enum "GO365 Override Status")
        {
            Caption = 'Override Status';
            DataClassification = CustomerContent;
        }
        field(62; "Override Reason"; Text[250])
        {
            Caption = 'Override Reason';
            DataClassification = CustomerContent;
        }
        field(63; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(64; "Approved DateTime"; DateTime)
        {
            Caption = 'Approved DateTime';
            DataClassification = CustomerContent;
        }

        // Audit metadata
        field(70; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(71; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Document; "Document Type", "Document No.", "Line No.")
        {
        }
        key(Item; "Item No.", "Created DateTime")
        {
        }
        key(User; "User ID", "Created DateTime")
        {
        }
    }

    trigger OnInsert()
    begin
        "Created DateTime" := CurrentDateTime;
        "User ID" := CopyStr(UserId, 1, MaxStrLen("User ID"));
    end;
}
