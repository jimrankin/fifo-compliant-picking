/// <summary>
/// Permission set for standard FIFO/FEFO Compliance users (pickers).
/// </summary>
permissionset 50400 "GO365 FIFO User"
{
    Caption = 'GO365 FIFO User';
    Assignable = true;

    Permissions =
        tabledata "GO365 FIFO Setup" = R,
        tabledata "GO365 Compliance Audit Log" = RI,
        tabledata "GO365 Override Request" = RIMD,
        tabledata "GO365 Lot Ranking" = R,
        tabledata "GO365 Lot Allocation" = R,
        table "GO365 FIFO Setup" = X,
        table "GO365 Compliance Audit Log" = X,
        table "GO365 Override Request" = X,
        table "GO365 Lot Ranking" = X,
        table "GO365 Lot Allocation" = X,
        page "GO365 FIFO Setup Card" = X,
        page "GO365 Compliance Log List" = X,
        page "GO365 Override Reason Input" = X,
        codeunit "GO365 Lot Ranker" = X,
        codeunit "GO365 Pick Interceptor" = X,
        codeunit "GO365 Compliance Auditor" = X,
        codeunit "GO365 Teams Notifier" = X;
}
