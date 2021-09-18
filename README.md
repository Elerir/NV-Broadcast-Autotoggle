# NV-Broadcast-Autotoggle
(former NV-Broadcast-Discord-Autotoggle)
BRANCH IS IN DEV

## Why you need this
- You use Nvidia Broadcast microphone Denoising option
- Your GPU never goes to IDLE mode (it consumes a lot of power, fans are ON, GPU is hot..) because Nvidia Broadcast is badly designed


## What it does
- Auto enable Nvidia Broadcast Denoising when Discord or Zoom starts
- Auto disable Nvidia Broadcast Denoising when Discord or Zoom is closed OR if Discord AND Zoom are not running (check every 15mn, to make sure denoising is actually off if Discord and zoom are not running)


## How to install
- Clone the repository (or download/extract it)
- Move it where you want the utility to be installed
- Right click on "install.ps1" and select "execute with Powershell"
- The script will ask for administrator privileges (Why ? Look at [Requirements section](#requirements))
- You're done !


## Requirements
- Administrator privileges for installation (to enable process creation event logs and to be able to create a task that read these event logs)
- Powershell 4.0+ (to know your Powershell version, open powershell and type "$PSVersionTable")
- Nvidia Broadcast needs to be started (can be minimized)
- Tested with Nvidia Broadcast v1.2.0.49 and v1.3.0.45


## How it works
- install.ps1 :
  - Enable process creation and termination audit (it basically enables Windows Event ID 4688 and 4689 logging)
  - Modify the pre-built task (the xml file) with correct paths (Discord, Zoom, utility's install path) as well as the .vbs file (see below)
  - Create a Scheduled Task "AutoToggleNvidiaBroadcast" that will execute NvidiaBroadcastController.ps1 when Discord/Zoom starts, when Discord/zoom stops, (and every 15mn to make sure denoising is actually off if discord/zoom are not running)

- NvidiaBroadcastController.ps1 :
  - Send a POSTMESSAGE using Win32API to the Nvidia broadcast application, which enable/disable microphone's Denoising

- NvidiaBroadcastWrapper.vbs :
  - Start NvidiaBroadcastController.ps1
  - This .vbs file is required to the task scheduler. The task scheduler starts this .vbs file which will starts the ps1 file. Directly starting the .ps1 from the Task Scheduler would show a powershell pop-up for a second when the task is executed (even in hidden mode)

## What's next
- "Choose your software" to control Nvidia Broadcast

## Donations
- Any donation will be greatly appreciated to the following Ethereum address : 0xE75Ad8f2De7A67b20C90b8B6742B96B3CdECC0d8