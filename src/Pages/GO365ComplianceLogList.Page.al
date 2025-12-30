/// <summary>
/// List page for viewing the FIFO/FEFO Compliance Audit Log.
/// </summary>
page 50411 "GO365 Compliance Log List"
{
    Caption = 'FIFO/FEFO Compliance Audit Log';
    PageType = List;
    ApplicationArea = Warehouse;
    UsageCategory = Lists;
    SourceTable = "GO365 Compliance Audit Log";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(AuditEntries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The unique entry number for this audit log record.';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The date and time this allocation was logged.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The type of source document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The source document number.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The item being picked.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Description of the item.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The warehouse location.';
                }
                field("Expected Lot No."; Rec."Expected Lot No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The lot number recommended by FIFO/FEFO rules.';
                }
                field("Allocated Lot No."; Rec."Allocated Lot No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The lot number actually allocated for picking.';
                    StyleExpr = LotStyleExpr;
                }
                field("Expected Bin Code"; Rec."Expected Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The bin code recommended by FIFO/FEFO rules.';
                }
                field("Allocated Bin Code"; Rec."Allocated Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The bin code actually allocated for picking.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The quantity allocated.';
                }
                field("Lot Rank"; Rec."Lot Rank")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The rank of this lot in the FIFO/FEFO queue (1 = oldest/expiring soonest).';
                }
                field("Compliance Mode"; Rec."Compliance Mode")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The compliance mode in effect (FIFO or FEFO).';
                }
                field("Was FIFO/FEFO Compliant"; Rec."Was FIFO/FEFO Compliant")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Indicates if this allocation followed FIFO/FEFO rules.';
                    StyleExpr = ComplianceStyleExpr;
                }
                field("Was Override"; Rec."Was Override")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Indicates if this was an override of the recommended lot/bin.';
                }
                field("Override Status"; Rec."Override Status")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The status of the override approval.';
                }
                field("Override Reason"; Rec."Override Reason")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The reason provided for overriding FIFO/FEFO rules.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'The user who created this pick line.';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = All;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportToExcel)
            {
                ApplicationArea = Warehouse;
                Caption = 'Export to Excel';
                Image = ExportToExcel;
                ToolTip = 'Export the audit log to Excel for reporting.';

                trigger OnAction()
                begin
                    // TODO: Implement Excel export using custom report or XMLPORT
                    Message('Excel export functionality will be implemented in a future version.');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report';

                actionref(ExportToExcel_Promoted; ExportToExcel) { }
            }
        }
    }

    var
        LotStyleExpr: Text;
        ComplianceStyleExpr: Text;

    trigger OnAfterGetRecord()
    begin
        // Style lot field based on compliance
        if Rec."Expected Lot No." <> Rec."Allocated Lot No." then
            LotStyleExpr := 'Unfavorable'
        else
            LotStyleExpr := 'Favorable';

        // Style compliance field
        if Rec."Was FIFO/FEFO Compliant" then
            ComplianceStyleExpr := 'Favorable'
        else
            ComplianceStyleExpr := 'Unfavorable';
    end;
}
