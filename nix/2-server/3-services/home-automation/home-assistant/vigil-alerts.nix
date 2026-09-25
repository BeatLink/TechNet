# Vigil alerts -- a Home Assistant package that forwards Vigil's notifications to the phone.
#
# Vigil posts each notification to a loopback-only webhook, and this pushes it to the companion app, tagged by monitor
# so a newer alert replaces the older one and a recovery clears it from the phone.
let
    webhookId = "vigil-alerts-nhl7efetwt6wbo139wfs";
    phone = "notify.mobile_app_thor";
    json = field: "{{ trigger.json.${field} }}";
in
{
    # Automations ------------------------------------------------------------------------------------------------------------------------------------
    automation = [
        {
            id = "vigil_alert_to_phone";
            alias = "Vigil Alert To Phone";
            mode = "queued";
            triggers = [
                {
                    trigger = "webhook";
                    webhook_id = webhookId;
                    local_only = true;
                    allowed_methods = [ "POST" ];
                }
            ];
            actions = [
                {
                    choose = [
                        {
                            conditions = [
                                {
                                    condition = "template";
                                    value_template = "{{ trigger.json.kind == 'recovered' and trigger.json.monitor.id }}";
                                }
                            ];
                            sequence = [
                                {
                                    action = phone;
                                    data = {
                                        message = "clear_notification";
                                        data.tag = json "monitor.id";
                                    };
                                }
                            ];
                        }
                    ];
                    default = [
                        {
                            action = phone;
                            data = {
                                title = json "title";
                                message = json "body";
                                data = {
                                    tag = "{{ trigger.json.monitor.id or 'vigil-group' }}";
                                    clickAction = json "url";
                                    priority = "{{ 'high' if trigger.json.status == 'failed' else 'normal' }}";
                                    ttl = 0;
                                };
                            };
                        }
                    ];
                }
            ];
        }
    ];
}
