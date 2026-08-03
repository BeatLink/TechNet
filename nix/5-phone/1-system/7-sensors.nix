# Accelerometer orientation
#
# The sensor is an InvenSense MPU6050 on i2c-1 at 0x68, driven by
# INV_MPU6050_I2C which megi's kernel builds in. iio-sensor-proxy finds it
# unaided and reports live orientation over net.hadess.SensorProxy -- confirmed
# by polling AccelerometerOrientation while turning the phone, which tracks
# through left-up / right-up / bottom-up.
#
# What it cannot know is how the part is physically mounted, so without a mount
# matrix it reports the chip's own axes and a phone held upright reads as
# "left-up". The kernel exposes the uncorrected identity:
#
#     $ cat /sys/bus/iio/devices/iio:device1/in_accel_mount_matrix
#     1, 0, 0; 0, 1, 0; 0, 0, 1
#
# WHITESPACE IS LOAD-BEARING BELOW. hwdb wants the match line at column 0 and
# each property line indented. Nix strips the common indentation from a ''
# string, so writing both at the same level puts *both* at column 0 and the
# entry is silently dropped: hwdb.bin ends up with no mention of the device and
#
#     udevadm test /sys/bus/iio/devices/iio:device1
#     iio:device1: No entry found from hwdb.
#
# The property line is therefore indented one space further than the match line,
# so exactly one space survives the strip. That was the bug here -- the rule was
# correct and never applied.
#
# Only the MPU6050 is declared. The st,lsm6dsl and st,lsm6ds3 entries that used
# to sit alongside it were for a sensor this phone does not have; the earlier
# note guessing at the ST part was wrong, and boot.kernelModules loading
# st_lsm6dsx was the thing that made it look plausible.
#
# If the screen is still wrong once a rule matches, the matrix is wrong rather
# than missing. The four quarter turns:
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
