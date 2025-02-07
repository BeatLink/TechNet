# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

let
  mkTuple = lib.hm.gvariant.mkTuple;
in
{
    dconf.settings = {
        "org/gnome/clocks" = {
            alarms = [
                { 
                    name' =  "Wake Up"; 
                    id' = "f5e0c757eb036361ecc802a367a62192"; 
                    hour = 6; 
                    minute = 0;
                    days = [1 2 3 4 5 6 7];
                    snooze_minutes = 5;
                    ring_minutes = 5;
                }
                {
                    name = "Wind Down";
                    id = "b1fe9e8a5f9ba10d5165fee567a621b3";
                    hour = 21;
                    minute = 45;
                    days = [1 2 3 4 5 6 7];
                    snooze_minutes = 1;
                    ring_minutes = 5;
                }
                {
                    name = "Sleep";
                    id = "dcc6d7d3473f40632692a73767a621ff";
                    hour = 22;
                    minute = 0;
                    days = [1 2 3 4 5 6 7];
                    snooze_minutes = 1;
                    ring_minutes = 5;
                }
            ];
            /*world-clocks = [
                {
                    location = (uint32 2);('Tokyo', 'RJTI', true, [(0.62191898430954862, 2.4408429589140699)], [(0.62282074357417661, 2.4391218722853854)])>)>}]
            */
    };


  };
}
