/// <summary>
/// Permission set for FIFO/FEFO Compliance administrators.
/// Full access to all extension objects.
/// </summary>
permissionset 50401 "GO365 FIFO Admin"
{
    Caption = 'GO365 FIFO Admin';
    Assignable = true;

    Permissions =
        tabledata "GO365 FIFO Setup" = RIMD,
        tabledata "GO365 Compliance Audit Log" = RIMD,
        tabledata "GO365 Override Request" = RIMD,
        tabledata "GO365 Lot Ranking" = RIMD,
        tabledata "GO365 Lot Allocation" = RIMD,
        table "GO365 FIFO Setup" = X,
        table "GO365 Compliance Audit Log" = X,
        table "GO365 Override Request" = X,
        table "GO365 Lot Ranking" = X,
        table "GO365 Lot Allocation" = X,
        page "GO365 FIFO Setup Card" = X,
        page "GO365 Compliance Log List" = X,
        page "GO365 Override API" = X,
        page "GO365 Override Reason Input" = X,
        codeunit "GO365 Lot Ranker" = X,
        codeunit "GO365 Pick Interceptor" = X,
        codeunit "GO365 Compliance Auditor" = X,
        codeunit "GO365 Teams Notifier" = X;
}
