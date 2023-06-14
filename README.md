# Effective Power

Effective Power is a viewer for Apple's power logging diagnostics in PLSQL format.
As the name suggests, these files are SQLite databases with a wealth of power-related information spread across many tables. 
Effective Power is my attempt at making sense of some of this data and presenting it in a useful way.
The usual disclaimers apply: the files this tool works with have been reverse-engineered, 
so take a grain of salt when interpreting its results.

## Getting PLSQL files

iOS internally stores energy metrics as PLSQL files. 
If you have a jailbroken device, you can pull them directly off the filesystem. 
If your device is not jailbroken, the easiest way to pull these files is to take a sysdiagnose, extract it, then look in the logs/powerlogs folder. 

Alternatively, you can follow [Apple's instructions to enable battery life logging](https://download.developer.apple.com/iOS/iOS_Logs/Battery_Life_Logging_Instructions.pdf), 
which involve installing a [debugging profile](https://developer.apple.com/services-account/download?path=/iOS/iOS_Logs/BatteryLife.mobileconfig). 

The profile will be valid for 7 days, and will create day-by-day logs as you use your device. 
Once you have enough data, sync with your computer and the PLSQL files will be copied over, compressed, and placed in ~/Library/Logs/CrashReporter/MobileDevice/.

Once you decompress them, you can load them into Effective Power for analysis.
