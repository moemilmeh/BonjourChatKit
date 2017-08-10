"""
    publisher.py
    BonjourChatKit
    
    Created by MMM on 8/9/17.
    Copyright (c) 2017 MoeMilMeh. All rights reserved.
"""

from BonjourChatKit import *


## Publisher

server = BonjourChatServicePublisher.alloc().initWithServiceName_('Server')
server.publishChatService()


## Browser

browser = BonjourChatServiceBrowser.alloc().initWithServiceType_domainName_('_chat._tcp.', 'local')
browser.startBrowsing()
