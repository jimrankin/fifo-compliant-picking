/// <summary>
/// StandardDialog page for entering override reason and requested lot.
/// </summary>
page 50413 "GO365 Override Reason Input"
{
    PageType = StandardDialog;
    Caption = 'Request FIFO/FEFO Override';

    layout
    {
        area(Content)
        {
            group(OverrideRequest)
            {
                Caption = 'Override Details';

                field(RequestedLotNo; RequestedLotNo)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Requested Lot No.';
                    ShowMandatory = true;
                    ToolTip = 'Enter the lot number you want to pick instead of the FIFO/FEFO recommended lot.';
                }
                field(OverrideReason; OverrideReason)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Reason for Override';
                    MultiLine = true;
                    ShowMandatory = true;
                    ToolTip = 'Provide a detailed reason for requesting this FIFO/FEFO deviation. This will be sent to the supervisor for approval.';
                }
            }
        }
    }

    var
        RequestedLotNo: Code[50];
        OverrideReason: Text[250];

    procedure GetRequestedLot(): Code[50]
    begin
        exit(RequestedLotNo);
    end;

    procedure GetReason(): Text[250]
    begin
        exit(OverrideReason);
    end;

    procedure SetInitialValues(InitialLot: Code[50]; InitialReason: Text[250])
    begin
        RequestedLotNo := InitialLot;
        OverrideReason := InitialReason;
    end;
}
