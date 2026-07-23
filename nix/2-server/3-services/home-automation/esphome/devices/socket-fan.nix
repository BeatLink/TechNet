# Fan wall socket -- Athom smart plug v2.
#
# Polled once a second by `ir-fan`, which mirrors this socket's state, so the
# sensor interval is deliberately tighter than the default.
{
    substitutions = {
        name = "socket-fan";
        sensor_update_interval = "1s";
    };
    packages.common = "!include .2-base-socket.yaml";
}
