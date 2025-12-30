/// <summary>
/// Defines the status of an override request in the approval workflow.
/// </summary>
enum 50401 "GO365 Override Status"
{
    Extensible = true;
    Caption = 'Override Status';

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; "Pending Approval")
    {
        Caption = 'Pending Approval';
    }
    value(2; Approved)
    {
        Caption = 'Approved';
    }
    value(3; Rejected)
    {
        Caption = 'Rejected';
    }
    value(4; Bypassed)
    {
        Caption = 'Bypassed';
    }
}
