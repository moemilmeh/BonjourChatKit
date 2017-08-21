#!/bin/sh

#  PythonBridgeScriptSetup.sh
#  BonjourChatKit
#
#  Created by MMM on 8/9/17.
#  Copyright © 2017 MoeMilMeh. All rights reserved.

SCRIPT_PATH="/Library/Frameworks/BonjourChatKit.framework/Versions/Current/Resources/"
INSTALL_PATH=`python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()"`
sudo rm -rf "${INSTALL_PATH}/BonjourChatKit.py"
sudo ln -fs "${SCRIPT_PATH}/BonjourChatKit.py" "${INSTALL_PATH}/BonjourChatKit.py"
echo "Python installed BonjourChatKit in '${INSTALL_PATH}'"

