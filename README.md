#  SwiftUI: AccessorySetupKit + BLE

A demo of sharing WiFi Network Information(Credentials) between devices and connected accessories using Wi-Fi Infrastructure framework.

Specifically, this repository includes 
- a simple app that act as a BLE accessory (peripheral side), and 
- an app for setting up the accessory and communicating with it using AccessorySetUpKit and Core Bluetooth (Central Side).

To test out the sample app for sharing wifi credentials, 

1. get two real devices, one running the BLE accessory app, and another one running the main app.
2. Pair the device and make a connect 
3. Share wifi network credentials


For more details on AccessorySetupKit: 
- [SwiftUI: Pair BLE Accessory in an Easy BUT Secure Way!](https://medium.com/@itsuki.enjoy/swiftui-share-wi-fi-network-credentials-with-paired-accessories-30004a4bf8f9)
- [SwiftUI: Share Wi-Fi Network Credentials With Paired Accessories!](https://medium.com/@itsuki.enjoy/swiftui-pair-ble-accessory-in-an-easy-but-secure-way-a9e88b5e2f07)


For more details on Bluetooth Low energy: 
- [SwiftUI: Low Energy Bluetooth (Part1: Peripheral Side)](https://medium.com/@itsuki.enjoy/swiftui-low-energy-bluetooth-part1-peripheral-side-0c772ef478d0)
- [SwiftUI: Low Energy Bluetooth (Part2: Central Side)](https://medium.com/@itsuki.enjoy/swiftui-low-energy-bluetooth-part2-central-side-1f3148217334)


![](./demo.gif)
