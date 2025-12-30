/// <summary>
/// Table for tracking pending override requests awaiting supervisor approval via Teams.
/// </summary>
table 50402 "GO365 Override Request"
{
    Caption = 'GO365 Override Request';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(10; "Warehouse Activity No."; Code[20])
        {
            Caption = 'Warehouse Activity No.';
            DataClassification = CustomerContent;
        }
        field(11; "Warehouse Activity Line No."; Integer)
        {
            Caption = 'Warehouse Activity Line No.';
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
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }
        field(30; "Expected Lot No."; Code[50])
        {
            Caption = 'Expected Lot No.';
            DataClassification = CustomerContent;
        }
        field(31; "Requested Lot No."; Code[50])
        {
            Caption = 'Requested Lot No.';
            DataClassification = CustomerContent;
        }
        field(32; "Expected Bin Code"; Code[20])
        {
            Caption = 'Expected Bin Code';
            DataClassification = CustomerContent;
        }
        field(33; "Requested Bin Code"; Code[20])
        {
            Caption = 'Requested Bin Code';
            DataClassification = CustomerContent;
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(50; Status; Enum "GO365 Override Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(51; Reason; Text[250])
        {
            Caption = 'Reason';
            DataClassification = CustomerContent;
        }

        // Requestor
        field(60; "Requested By"; Code[50])
        {
            Caption = 'Requested By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(61; "Requested DateTime"; DateTime)
        {
            Caption = 'Requested DateTime';
            DataClassification = CustomerContent;
        }

        // Approver
        field(70; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(71; "Approved DateTime"; DateTime)
        {
            Caption = 'Approved DateTime';
            DataClassification = CustomerContent;
        }
        field(72; "Approval Response"; Text[250])
        {
            Caption = 'Approval Response';
            DataClassification = CustomerContent;
        }

        // Timeout tracking
        field(80; "Expires DateTime"; DateTime)
        {
            Caption = 'Expires DateTime';
            DataClassification = CustomerContent;
        }
        field(81; "Was Timed Out"; Boolean)
        {
            Caption = 'Was Timed Out';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Activity; "Warehouse Activity No.", "Warehouse Activity Line No.")
        {
        }
        key(Status; Status, "Requested DateTime")
        {
        }
    }

    trigger OnInsert()
    var
        FIFOSetup: Record "GO365 FIFO Setup";
    begin
        "Requested DateTime" := CurrentDateTime;
        "Requested By" := CopyStr(UserId, 1, MaxStrLen("Requested By"));

        // Set expiration based on setup
        FIFOSetup.GetOrCreate();
        "Expires DateTime" := CurrentDateTime + (FIFOSetup."Approval Timeout (Minutes)" * 60000);
    end;
}
