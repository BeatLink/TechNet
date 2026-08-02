# Accelerometer orientation
#
# iio-sensor-proxy derives rotation from the raw accelerometer axes, which are
# aligned to how the chip sits on the board rather than to the screen. The mount
# matrix rotates them into screen space; with no matching one the display reports
# a rotation a quarter turn out and sits permanently on its side.
#
# The matrix is keyed on the sensor's modalias, so it only applies to the sensor
# it names. PinePhone batches shipped different accelerometers -- earlier ones an
# InvenSense MPU6050, later ones an ST LSM6DSx -- and a rule naming the wrong one
# silently does nothing at all. Both are declared so the correction lands either
# way. Note boot.kernelModules loads st_lsm6dsx, which suggests this device is
# the ST part; confirm on the device before trimming this back.
#
# To see which sensor is present and whether a rule matched:
#
#   udevadm info -a /sys/bus/iio/devices/iio:device0 | grep -i modalias
#   udevadm info --export-db | grep -i ACCEL_MOUNT_MATRIX
#
# A device showing ACCEL_MOUNT_MATRIX matched a rule below. If the screen is
# still wrong *after* one matches, the matrix is wrong rather than missing --
# the four quarter turns are:
#
#   none          1, 0, 0; 0, 1, 0; 0, 0, 1
#   90 clockwise  0, 1, 0; -1, 0, 0; 0, 0, 1
#   180          -1, 0, 0; 0, -1, 0; 0, 0, 1
#   90 counter    0, -1, 0; 1, 0, 0; 0, 0, 1
#
{
    hardware.sensor.iio.enable = true;

    services.udev.extraHwdb = ''
        sensor:modalias:of:NaccelerometerT_null_Cinvensense,mpu6050:*
        ACCEL_MOUNT_MATRIX=0, 1, 0; -1, 0, 0; 0, 0, 1

        sensor:modalias:of:NaccelerometerT_null_Cst,lsm6dsl:*
        ACCEL_MOUNT_MATRIX=0, 1, 0; -1, 0, 0; 0, 0, 1

        sensor:modalias:of:NaccelerometerT_null_Cst,lsm6ds3:*
        ACCEL_MOUNT_MATRIX=0, 1, 0; -1, 0, 0; 0, 0, 1
    '';
}
