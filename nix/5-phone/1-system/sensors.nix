# Accelerometer orientation
#
# The sensor is an InvenSense MPU6050 on i2c-1 at 0x68, driven by
# INV_MPU6050_I2C which megi's kernel builds in. iio-sensor-proxy finds it
# unaided and reports live orientation over net.hadess.SensorProxy.
#
# The chip cannot know how it is mounted, so a mount matrix maps chip axes to
# screen axes. The kernel's device tree carries the same matrix and mirrors it
# at /sys/bus/iio/devices/iio:device1/in_accel_mount_matrix, but
# iio-sensor-proxy prefers the udev ACCEL_MOUNT_MATRIX property, so the hwdb
# entry below is the one that counts. Verified end to end against raw chip
# readings with the phone held in a known pose: reported orientation matches
# physical orientation.
#
# WHITESPACE IS LOAD-BEARING BELOW. hwdb wants the match line at column 0 and
# each property line indented. Nix strips the common indentation from a ''
# string, so writing both at the same level puts *both* at column 0 and the
# entry is silently dropped: hwdb.bin ends up with no mention of the device and
# udevadm test then reports "No entry found from hwdb". The property line is
# therefore indented one space further than the match line, so exactly one
# space survives the strip.
#
# If the screen is ever wrong again, the matrix is wrong rather than missing.
# The four quarter turns:
#
#   none          1, 0, 0; 0, 1, 0; 0, 0, 1
#   90 clockwise  0, 1, 0; -1, 0, 0; 0, 0, 1
#   180          -1, 0, 0; 0, -1, 0; 0, 0, 1
#   90 counter    0, -1, 0; 1, 0, 0; 0, 0, 1
#
# To check a rule matched:
#
#   udevadm info --export-db | grep -i ACCEL_MOUNT_MATRIX
#
{
    hardware.sensor.iio.enable = true;

    services.udev.extraHwdb = ''
        sensor:modalias:of:NaccelerometerT_null_Cinvensense,mpu6050:*
         ACCEL_MOUNT_MATRIX=0, 1, 0; -1, 0, 0; 0, 0, 1
    '';
}
