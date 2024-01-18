WiTapNW
 
===========================================================================

## DESCRIPTION:
 
The WiTapNW sample application demonstrates how to achieve network communication between applications. Using Bonjour, the application both advertises itself on the local network and displays a list of other instances of this application on the network.
 
Simply build the sample using Xcode and run it in the simulator or on the device. Wait for another player to connect or select a game to connect to. Once connected, tap one or more colored pads on a device to see them highlighted simultaneously on the remote device.
 
This version of WiTapNW works over Bluetooth and Wi-Fi, courtesy of the Network.framework peer-to-peer support in iOS 12. While NWBrowser, the object you use to browse for available network services, requires iOS 13.
 
Note: For more information about peer-to-peer support in Network.framework, see WWDC18 session 715 "Introducing Network.framework: A modern alternative to Sockets" and WWDC19 session 712 "Advances in Networking".

===========================================================================

## SCREENSHOTS:

![](https://raw.githubusercontent.com/Mamong/WiTapNW/main/screenshots/1.gif)

 
 
===========================================================================

## BUILD REQUIREMENTS:
 
OS X 12.7.2, Xcode 14.2, iOS 16.2 SDK
 
===========================================================================
## RUNTIME REQUIREMENTS:
 
iOS 13.0 or later
 
===========================================================================
## CHANGES FROM PREVIOUS VERSIONS:
 
Version 1.0
- Rewrite in Swift 5 and base on Network.framework.

 

