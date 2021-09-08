# NV-Broadcast-Discord-Autotoggle

**Why you need this**
- You use Nvidia Broadcast microphone Denoising option
- Your GPU never goes to IDLE mode (it consumes a lot of power, fans are ON, GPU is hot..) because Nvidia Broadcast is badly designed

**What it does**
- Auto enable Nvidia Broadcast Denoising when Discord starts
- Auto disable Nvidia Broadcast Denoising if Discord is not running

**Requirements**
- Powershell 4.0+ (to know your Powershell version, open powershell and type "$PSVersionTable")
- Nvidia Broadcast needs to be started (can be minimized)

**How to install**
- Clone the repository
- Move it where you want the utility to be installed
- Right click on "install.ps1" and select "execute with Powershell"
- You're done !

**How it works**

install.ps1 :
- Enable process creation and termination audit (it basically enables Windows Event ID 4688 and 4689 logging)
- Modify the pre-built task (the xml file) with correct paths (Discord, utility's install path) as well as the .vbs file (see below)
- Create a Scheduled Task "AutoToggleNvidiaBroadcast" that will execute NvidiaBroadcastController.ps1 when discord starts (and every 10mn to check if discord is still open)


NvidiaBroadcastController.ps1 :
- Sends a POSTMESSAGE using Win32API to the Nvidia broadcast application, which enable/disable microphone's Denoising


NvidiaBroadcastWrapper.vbs :
- Starts NvidiaBroadcastController.ps1


This .vbs file is required to the task scheduler. The task scheduler starts this .vbs file which will starts the ps1 file. Directly starting the .ps1 from the Task Scheduler would show a powershell pop-up for a second when the task is executed (even in hidden mode)

**What's next ?**
- Auto disable Nvidia Broadcast Denoising when Discord stops : I'm still working on this to make sure this is more reliable than checking if discord is running
