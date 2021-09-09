# NV-Broadcast-Discord-Autotoggle

## Why you need this
- You use Nvidia Broadcast microphone Denoising option
- Your GPU never goes to IDLE mode (it consumes a lot of power, fans are ON, GPU is hot..) because Nvidia Broadcast is badly designed


## What it does
- Auto enable Nvidia Broadcast Denoising when Discord starts (more accurately, when the Update discord process starts)
- Auto disable Nvidia Broadcast Denoising if Discord is not running (maximum 10 mn after Discord was closed)


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
  - Modify the pre-built task (the xml file) with correct paths (Discord, utility's install path) as well as the .vbs file (see below)
  - Create a Scheduled Task "AutoToggleNvidiaBroadcast" that will execute NvidiaBroadcastController.ps1 when discord starts (and every 10mn to check if discord is still open)

- NvidiaBroadcastController.ps1 :
  - Send a POSTMESSAGE using Win32API to the Nvidia broadcast application, which enable/disable microphone's Denoising

- NvidiaBroadcastWrapper.vbs :
  - Start NvidiaBroadcastController.ps1
  - This .vbs file is required to the task scheduler. The task scheduler starts this .vbs file which will starts the ps1 file. Directly starting the .ps1 from the Task Scheduler would show a powershell pop-up for a second when the task is executed (even in hidden mode)


## What's next ?
- ~Auto disable Nvidia Broadcast Denoising when Discord stops : I'm still working on this to make sure this is more reliable than checking if discord is running (it might not be the case if you switch off your computer with discord left open)~ --> ~This cannot be done, because monitored events 4688 are based on the discord update process (and there is no termination event for this binary). We cannot use the "real" discord binary because its location can change based on binary's version~ --> *this might be fixed and is currently being tested*
