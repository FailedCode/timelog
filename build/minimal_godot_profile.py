# see:
#   https://forum.godotengine.org/t/easy-to-follow-tutorial-for-encrypting-your-pck-file/50349
#   https://popcar.bearblog.dev/how-to-minify-godots-build-size/
# 
# A quick "how to build a minimal size executable":
# - install python and scons
#   - pip install scons
# - download and unzip *-msvcrt-x86_64.zip
#   - https://github.com/mstorsjo/llvm-mingw/releases/latest
#   - add the bin directory to your PATH environment variable
# - clone the godot repository and check out the version tag
#   - git clone https://github.com/godotengine/godot.git
# - Start the build process inside the godot project with this profile
#   scons platform=windows profile=minimal_godot_profile.py
# - Copy the compiled "godot.windows.template_release.x86_64.llvm.exe" from godot/bin back here
# - Now you can use the Minimal-Export
#
target="template_release"
debug_symbols="no"
optimize="size"
lto="full"
disable_3d="yes" # Disables 3D
deprecated="no"  # Disables deprecated features
vulkan="no"      # Disables the Vulkan driver (used in Forward+/Mobile Renderers)
use_volk="no"    # Disables more Vulkan stuff
openxr="no"      # Disables Virtual Reality/Augmented Reality stuff
minizip="no"     # Disables ZIP archive support