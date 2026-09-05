# Monitors ###########################################################################################################################################
#
# Pins the two head layout that Cinnamon otherwise re-derives on every boot, since the rollback wipes this file.
#

{ ... }:
{
    home-manager.users.beatlink.xdg.configFile."cinnamon-monitors.xml" = {
        force = true; # The Display panel saves over this symlink, and the next activation would refuse to clobber the result
        text = ''
            <monitors version="2">
              <configuration>
                <!-- eDP-1 comes first because muffin numbers monitors in file order, and the dconf panels sit on monitor 0 -->
                <logicalmonitor>
                  <x>0</x>
                  <y>1080</y>
                  <scale>1</scale>
                  <primary>yes</primary>
                  <monitor>
                    <monitorspec>
                      <connector>eDP-1</connector>
                      <vendor>LEN</vendor>
                      <product>0x9059</product>
                      <serial>0x00000000</serial>
                    </monitorspec>
                    <mode>
                      <width>1920</width>
                      <height>1080</height>
                      <rate>120.21298980712891</rate>
                    </mode>
                  </monitor>
                </logicalmonitor>
                <logicalmonitor>
                  <x>0</x>
                  <y>0</y>
                  <scale>1</scale>
                  <monitor>
                    <monitorspec>
                      <connector>HDMI-1</connector>
                      <vendor>GSM</vendor>
                      <product>LG FULL HD</product>
                      <serial>0x00000000</serial>
                    </monitorspec>
                    <mode>
                      <width>1920</width>
                      <height>1080</height>
                      <rate>60</rate>
                    </mode>
                  </monitor>
                </logicalmonitor>
              </configuration>
              <!-- The undocked layout, without which muffin derives one and saves it over this file -->
              <configuration>
                <logicalmonitor>
                  <x>0</x>
                  <y>0</y>
                  <scale>1</scale>
                  <primary>yes</primary>
                  <monitor>
                    <monitorspec>
                      <connector>eDP-1</connector>
                      <vendor>LEN</vendor>
                      <product>0x9059</product>
                      <serial>0x00000000</serial>
                    </monitorspec>
                    <mode>
                      <width>1920</width>
                      <height>1080</height>
                      <rate>120.21298980712891</rate>
                    </mode>
                  </monitor>
                </logicalmonitor>
              </configuration>
            </monitors>
        '';
    };
}
