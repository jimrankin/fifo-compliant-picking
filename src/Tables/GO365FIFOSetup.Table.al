/// <summary>
/// Singleton setup table for FIFO/FEFO Picking Compliance configuration.
/// Contains all toggles and settings for enforcement rules, override workflow, and auditing.
/// </summary>
table 50400 "GO365 FIFO Setup"
{
    Caption = 'GO365 FIFO Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }

        // General FastTab
        field(10; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
        }
        field(11; Mode; Enum "GO365 Compliance Mode")
        {
            Caption = 'Mode';
            DataClassification = CustomerContent;
        }
        field(12; "Respect BC Settings"; Boolean)
        {
            Caption = 'Respect BC Settings';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(13; "Respect Item Tracking Code"; Boolean)
        {
            Caption = 'Respect Item Tracking Code';
            DataClassification = CustomerContent;
            InitValue = true;
        }

        // Picking Rules FastTab
        field(20; "Enforce Bin Sequence"; Boolean)
        {
            Caption = 'Enforce Bin Sequence';
            DataClassification = CustomerContent;
        }
        field(21; "Enforce Zone Sequence"; Boolean)
        {
            Caption = 'Enforce Zone Sequence';
            DataClassification = CustomerContent;
        }
        field(22; "Allow Partial Lot Consumption"; Boolean)
        {
            Caption = 'Allow Partial Lot Consumption';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(23; "Strict Mode"; Boolean)
        {
            Caption = 'Strict Mode';
            DataClassification = CustomerContent;
        }
        field(24; "Minimum Shelf Life"; DateFormula)
        {
            Caption = 'Minimum Shelf Life';
            DataClassification = CustomerContent;
        }
        field(25; "Exclude Expired Lots"; Boolean)
        {
            Caption = 'Exclude Expired Lots';
            DataClassification = CustomerContent;
            InitValue = true;
        }

        // Override Workflow FastTab
        field(30; "Require Supervisor Approval"; Boolean)
        {
            Caption = 'Require Supervisor Approval';
            DataClassification = CustomerContent;
        }
        field(31; "Teams Webhook URL"; Text[250])
        {
            Caption = 'Teams Webhook URL';
            DataClassification = CustomerContent;
            ExtendedDatatype = URL;
        }
        field(32; "Approval Timeout (Minutes)"; Integer)
        {
            Caption = 'Approval Timeout (Minutes)';
            DataClassification = CustomerContent;
            InitValue = 30;
            MinValue = 1;
            MaxValue = 1440;
        }
        field(33; "Allow Approval Bypass"; Boolean)
        {
            Caption = 'Allow Approval Bypass';
            DataClassification = CustomerContent;
        }

        // Audit FastTab
        field(40; "Enable Full Audit Trail"; Boolean)
        {
            Caption = 'Enable Full Audit Trail';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(41; "Retain Logs (Days)"; Integer)
        {
            Caption = 'Retain Logs (Days)';
            DataClassification = CustomerContent;
            InitValue = 365;
            MinValue = 30;
            MaxValue = 3650;
        }

        // Application Insights
        field(50; "App Insights Connection String"; Text[250])
        {
            Caption = 'Application Insights Connection String';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Gets the singleton setup record, creating it if it doesn't exist.
    /// </summary>
    procedure GetOrCreate()
    begin
        if not Get() then begin
            Init();
            "Primary Key" := '';
            Insert();
        end;
    end;

    /// <summary>
    /// Returns whether FIFO/FEFO enforcement is currently active.
    /// </summary>
    procedure IsEnforcementActive(): Boolean
    begin
        GetOrCreate();
        exit(Enabled);
    end;

    /// <summary>
    /// Returns the current compliance mode (FIFO or FEFO).
    /// </summary>
    procedure GetComplianceMode(): Enum "GO365 Compliance Mode"
    begin
        GetOrCreate();
        exit(Mode);
    end;
}
