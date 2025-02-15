# EarlyOom ################################################################################################################################
#
# Prevents Out Of Memory Conditions by killing the largest process if memory drops below 2% free
#
###########################################################################################################################################

{
    services.earlyoom = {
        enable = true;
        enableNotifications = true;
        freeMemThreshold = 2;
    };
}