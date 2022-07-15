from just.airy.api import Pkg, cp, ln

# [_] TODO: gather everything related to single HW into single copy-paste folder

Pkg("mesa")
# Pkg("lib32-mesa")  # BAD: pulls 20+ many pkgs
# Pkg("xf86-video-intel")  # BAD: laggy input as hell
Pkg("vulkan-intel")
Pkg("intel-media-driver")  # offloading media decoding HEVC/H.265 micro (HuC)

# OPT:DEBUG:
# Pkg("mesa-utils")  # glxgears
# Pkg("libva-utils")  # vainfo
# Pkg("intel-gpu-tools")  # intel_gpu_top


# cp("20-intel.conf", under="/etc/X11/xorg.conf.d")

# [_] TODO:DEV: if change in cp() occured -- WARN user should rebuild
# NEED: rebuild $ sudo mkinitcpio -p linux
cp("i915.conf", under="/etc/modprobe.d")