# Desktop Environment
#
# This file stores configuration settings on various desktop environments that can be used. 
#
# Cinnamon w/ Plank 
#   This is the current Desktop Environment. I've been using it for approximately 12 years.
# 
# KDE
#   Pretty, featureful and customizable. However, Nvidia Drivers on Wayland are broken which causes issues with system suspending and 
#   resuming. Also Present Screen does not sort windows by recently used which breaks my hot corner / window switching workflow
# 
# Budgie
#   Pretty and the Raven sidebar is an interesting concept. Not as feature rich as cinnamon (no hot corners)
# 

{
    imports = [              
        #./kde
        #./budgie
        ./cinnamon
        ./plank
    ];
}
