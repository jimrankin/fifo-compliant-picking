/// <summary>
/// Teams Notifier codeunit for sending notifications to Microsoft Teams.
/// Uses direct HTTP webhook integration for Adaptive Card approval workflows.
/// Note: Power Automate integration using External Business Events can be added
/// when the target BC environment supports it.
/// </summary>
codeunit 50423 "GO365 Teams Notifier"
{
    Access = Public;

    var
        FIFOSetup: Record "GO365 FIFO Setup";

    /// <summary>
    /// Main entry point for raising an override request notification.
    /// Sends an Adaptive Card to Teams via webhook.
    /// </summary>
    procedure RaiseOverrideRequestEvent(OverrideRequest: Record "GO365 Override Request")
    begin
        SendDirectToTeams(OverrideRequest);
    end;

    /// <summary>
    /// Wrapper to notify with all necessary context parameters.
    /// </summary>
    procedure NotifyOverrideRequest(
        EntryNo: Integer;
        WarehouseActivityNo: Code[20];
        ItemNo: Code[20];
        ItemDescription: Text[100];
        LocationCode: Code[10];
        ExpectedLot: Code[50];
        RequestedLot: Code[50];
        Quantity: Decimal;
        RequestedBy: Code[50];
        Reason: Text[250])
    var
        OverrideRequest: Record "GO365 Override Request";
    begin
        if OverrideRequest.Get(EntryNo) then
            RaiseOverrideRequestEvent(OverrideRequest);
    end;

    /// <summary>
    /// Builds the Adaptive Card JSON for Teams.
    /// </summary>
    procedure BuildAdaptiveCardJson(OverrideRequest: Record "GO365 Override Request"): Text
    var
        Item: Record Item;
        CardJson: TextBuilder;
        ItemDescription: Text[100];
    begin
        // Get item description
        if Item.Get(OverrideRequest."Item No.") then
            ItemDescription := Item.Description;

        CardJson.AppendLine('{');
        CardJson.AppendLine('  "type": "message",');
        CardJson.AppendLine('  "attachments": [{');
        CardJson.AppendLine('    "contentType": "application/vnd.microsoft.card.adaptive",');
        CardJson.AppendLine('    "content": {');
        CardJson.AppendLine('      "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",');
        CardJson.AppendLine('      "type": "AdaptiveCard",');
        CardJson.AppendLine('      "version": "1.4",');
        CardJson.AppendLine('      "body": [');
        CardJson.AppendLine('        {');
        CardJson.AppendLine('          "type": "TextBlock",');
        CardJson.AppendLine('          "size": "Large",');
        CardJson.AppendLine('          "weight": "Bolder",');
        CardJson.AppendLine('          "text": "⚠️ FIFO/FEFO Override Request",');
        CardJson.AppendLine('          "wrap": true');
        CardJson.AppendLine('        },');
        CardJson.AppendLine('        {');
        CardJson.AppendLine('          "type": "FactSet",');
        CardJson.AppendLine('          "facts": [');
        CardJson.AppendLine('            { "title": "Picker:", "value": "' + Format(OverrideRequest."Requested By") + '" },');
        CardJson.AppendLine('            { "title": "Document:", "value": "' + Format(OverrideRequest."Warehouse Activity No.") + '" },');
        CardJson.AppendLine('            { "title": "Item:", "value": "' + Format(OverrideRequest."Item No.") + ' - ' + ItemDescription + '" },');
        CardJson.AppendLine('            { "title": "Location:", "value": "' + Format(OverrideRequest."Location Code") + '" },');
        CardJson.AppendLine('            { "title": "Expected Lot:", "value": "' + Format(OverrideRequest."Expected Lot No.") + '" },');
        CardJson.AppendLine('            { "title": "Requested Lot:", "value": "' + Format(OverrideRequest."Requested Lot No.") + '" },');
        CardJson.AppendLine('            { "title": "Quantity:", "value": "' + Format(OverrideRequest.Quantity) + '" },');
        CardJson.AppendLine('            { "title": "Reason:", "value": "' + Format(OverrideRequest.Reason) + '" }');
        CardJson.AppendLine('          ]');
        CardJson.AppendLine('        }');
        CardJson.AppendLine('      ],');
        CardJson.AppendLine('      "actions": [');
        CardJson.AppendLine('        {');
        CardJson.AppendLine('          "type": "Action.Submit",');
        CardJson.AppendLine('          "title": "✅ Approve",');
        CardJson.AppendLine('          "style": "positive",');
        CardJson.AppendLine('          "data": { "action": "approve", "entryNo": ' + Format(OverrideRequest."Entry No.") + ' }');
        CardJson.AppendLine('        },');
        CardJson.AppendLine('        {');
        CardJson.AppendLine('          "type": "Action.Submit",');
        CardJson.AppendLine('          "title": "❌ Reject",');
        CardJson.AppendLine('          "style": "destructive",');
        CardJson.AppendLine('          "data": { "action": "reject", "entryNo": ' + Format(OverrideRequest."Entry No.") + ' }');
        CardJson.AppendLine('        }');
        CardJson.AppendLine('      ]');
        CardJson.AppendLine('    }');
        CardJson.AppendLine('  }]');
        CardJson.AppendLine('}');

        exit(CardJson.ToText());
    end;

    /// <summary>
    /// Sends an Adaptive Card directly to Teams via webhook.
    /// </summary>
    procedure SendDirectToTeams(OverrideRequest: Record "GO365 Override Request")
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        CardJson: Text;
        Headers: HttpHeaders;
    begin
        FIFOSetup.GetOrCreate();
        if FIFOSetup."Teams Webhook URL" = '' then
            exit;

        CardJson := BuildAdaptiveCardJson(OverrideRequest);

        HttpContent.WriteFrom(CardJson);
        HttpContent.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        HttpRequestMessage.Method := 'POST';
        HttpRequestMessage.SetRequestUri(FIFOSetup."Teams Webhook URL");
        HttpRequestMessage.Content := HttpContent;

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error('Failed to send Teams notification');

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error('Teams webhook returned error: %1', HttpResponseMessage.ReasonPhrase);
    end;
}
