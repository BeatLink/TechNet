# Fan wall socket -- Athom smart plug v2.
#
# Powers the bedroom ceiling fan; the Home Assistant `bedroom-fan` package
# switches it as part of setting a speed.
{
    substitutions.name = "socket-fan";
    packages.common = "!include .base-socket.yaml";
}
