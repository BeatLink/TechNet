# Fn lock for the keyboard case
#
# The case has no Fn lock of its own: FN is a hold-to-use modifier, so anything
# on the orange layer -- F1-F10, Home, End, PageUp/Down, the arrows -- needs two
# hands or a claw. This makes tapping FN twice latch that layer until it is
# tapped again.
#
# Why keyd rather than xkb, which is how the Pine key was solved in
# 19-keyboard-layout: the two keys reach userspace differently. The driver maps
# Pine to a bare KEY_LEFTMETA with no layer behind it, which leaves xkb free to
# make it the level 3 switch. FN it resolves itself -- measured with evtest,
# holding FN and pressing 7 emits KEY_F7 directly, not KEY_7 with a modifier
# xkb could act on. There is no level for xkb to select, so the layer has to be
# built below it, on the evdev stream.
#
# What the capture showed, and what this configuration depends on:
#
#   FN down          code 464 (KEY_FN) value 1
#   FN+7 while held  code  65 (KEY_F7) value 1     <- already translated
#   FN up            code 464 (KEY_FN) value 0
#   7 alone          code   8 (KEY_7)  value 1
#
# So KEY_FN is a real key with its own press and release, delivered alongside
# the translated result rather than instead of it. That is what makes this
# possible at all: keyd can bind FN as a layer trigger while the hardware keeps
# doing its own translation underneath.
#
# Tap FN to latch the layer, tap again to release. Holding FN is unchanged and
# still reaches the whole orange layer, because the hardware keeps doing that
# itself -- see the note on the fnlock layer for why the latched case cannot
# rely on the same mechanism and remaps the number row explicitly.
#
# The id is not a name and not a glob. keyd matches vendor:product, optionally
# with a k: or m: prefix, and silently ignores anything that does not parse as
# one -- a name pattern produces no error, just a daemon that starts, reports
# "DEVICE: ignoring ... (PinePhone Keyboard)" and does nothing.
#
# This keyboard is on i2c and has no USB ids, so vendor and product are both
# 0000. That alone is not enough: `keyd monitor` shows the codec jack and the
# power button are also 0000:0000, and matching those would put keyd in front of
# unrelated devices. The third field is keyd's own hash of the device, which is
# what makes the match specific, so the full three-part id is used.
#
# Read it back with `sudo keyd monitor` if the case is ever replaced -- the hash
# is derived from the device, not stored anywhere in this repo.
{
    services.keyd = {
        enable = true;

        keyboards.pinephone = {
            ids = [ "0000:0000:c5d1e542" ];

            settings = {
                main = {
                    # Hold FN and it is still FN, unchanged. Tap it -- press and
                    # release inside the timeout without another key -- and the
                    # fnlock layer toggles on.
                    #
                    # overloadt2 rather than overload: the plain form decides
                    # tap-versus-hold on whether another key was pressed, which
                    # on this keyboard means holding FN alone and waiting would
                    # eventually count as a tap. The t2 form commits to the hold
                    # after the timeout regardless, so FN held down is FN.
                    fn = "overloadt2(fnlock, toggle(fnlock), 200)";
                };

                # The layer has to do the mapping itself. The tempting version of
                # this file declares only the toggle and expects the keyboard to
                # apply its own orange layer, on the theory that latching holds
                # FN down -- it does not work, and `keyd listen` plus evtest on
                # the virtual device is what shows why. keyd grabs the device and
                # re-emits synthetic events, so the MCU never learns that keyd
                # considers FN held; the hardware only translates while the
                # physical key is really down, which keyd has just intercepted.
                # Latched, the number row still emitted KEY_7.
                #
                # So the digits are mapped here explicitly. Only the number row:
                # everything else on the orange layer -- Home, End, PageUp/Down,
                # the arrows on ; , . / ' [ ] -- is reached by holding FN, which
                # still behaves exactly as it always did.
                fnlock = {
                    "1" = "f1";
                    "2" = "f2";
                    "3" = "f3";
                    "4" = "f4";
                    "5" = "f5";
                    "6" = "f6";
                    "7" = "f7";
                    "8" = "f8";
                    "9" = "f9";
                    "0" = "f10";

                    fn = "toggle(fnlock)";
                };
            };
        };
    };
}
