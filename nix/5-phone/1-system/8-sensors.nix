{
    hardware.sensor.iio.enable = true;
    services.udev.extraHwdb = ''
        # PinePhone MPU6050 accelerometer orientation fix (+90° clockwise)
        sensor:modalias:of:NaccelerometerT_null_Cinvensense,mpu6050:*
        ACCEL_MOUNT_MATRIX=0, 1, 0; -1, 0, 0; 0, 0, 1
    '';

}
