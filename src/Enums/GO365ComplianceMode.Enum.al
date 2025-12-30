/// <summary>
/// Defines the compliance mode for FIFO/FEFO picking enforcement.
/// </summary>
enum 50400 "GO365 Compliance Mode"
{
    Extensible = true;
    Caption = 'Compliance Mode';

    value(0; FIFO)
    {
        Caption = 'FIFO (Oldest First)';
    }
    value(1; FEFO)
    {
        Caption = 'FEFO (Expire First)';
    }
}
