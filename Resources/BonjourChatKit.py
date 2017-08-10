"""
    BonjourChatKit.py
    BonjourChatKit
    
    Created by MMM on 8/9/17.
    Copyright (c) 2017 MoeMilMeh. All rights reserved.
"""

import objc
import os
import sys

#######################################################################
# Function to load the bundle for creating a library wrapper
#
# Source: https://pythonhosted.org/pyobjc/metadata/bridgesupport.html
#
#######################################################################

def loadBundle(frameworkPath):
    
    if frameworkPath != None:

        framework = 'BonjourChatKit.framework'
        identifier = 'com.MoeMilMeh.BonjourChatKit'
        if framework in frameworkPath:
            if os.path.exists(frameworkPath):
                __bundle__ = objc.initFrameworkWrapper(framework, frameworkIdentifier=identifier, frameworkPath=objc.pathForFramework(frameworkPath), globals=globals())
                return True

    return False

frameworkPath = None
argumentsCount = len(sys.argv)

if argumentsCount > 2:
    print "\nUsage: python " + sys.argv[0] + " PathToFramework \n"
    sys.exit()

elif argumentsCount == 2:
    frameworkPath = sys.argv[1]

else:
    frameworkPath = '/Library/Frameworks/BonjourChatKit.framework'
    print "Using default frameworkPath: " + frameworkPath

# Check if bundle is loaded
if loadBundle(frameworkPath):
    print "Successfully loaded BonjourChatKit"
else:
    print "ERROR: Failed to load BonjourChatKit from " + frameworkPath

del objc, os, sys
