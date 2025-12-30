/// <summary>
/// Page extension for Location Card to add navigation to FIFO/FEFO Setup.
/// </summary>
pageextension 50401 "GO365 Location Card Ext" extends "Location Card"
{
    actions
    {
        addafter("&Bins")
        {
            action("GO365 FIFO Setup")
            {
                ApplicationArea = Warehouse;
                Caption = 'FIFO/FEFO Compliance Setup';
                Image = Setup;
                ToolTip = 'Configure FIFO/FEFO picking compliance enforcement settings.';
                RunObject = page "GO365 FIFO Setup Card";
            }
        }
        addlast(Category_Category4)
        {
            actionref("GO365 FIFO Setup_Promoted"; "GO365 FIFO Setup") { }
        }
    }
}
