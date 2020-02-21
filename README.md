# Minecraft-Server
Single file automated script to host minecraft and perform daily backups.

While it does a lot of different things this script is the result of my first foray into powershell so it may not be as organized and neat as could be. I still would appreciate being credited if this is used elsewhere, and if any improvements are made that I be kept informed so I can provide better experience to my server's clients.

# Things this script does:

- Elevates to Admin automatically (necessary for the automation of scheduled tasks that warn clients the server is shutting down)
- Scrapes www.minecraft.net/en-us/download/server/ for current server jar version and download link
- Automatically installs updated server versions as soon as they are available, and stores old jar files in an archive
- Creates a jar archive folder if one does not already exist
- Sets a scheduled task for server alerts (e.g. /title @a "{"text":"Server shutting down"})
- Sets a scheduled job to run the actual backup in the background (copies \world data to \worldbackup\<date>\world)
- If the world backup folder doesn't exist, makes one.
- Allows for graceful restart of java crashes (server is on a while loop that just goes infinitely unless the server is stopped, powershell is closed, or ctrl+c is pressed)
- All paths are variables so even if you have your minecraft stored in a weird place like c:\Windows\System32\Drivers\etc\hosts\minecraft\server it will launch properly. No setup needed.

# How to use:

Literally just drop the two files where your "server.jar" file exists, double click "ServerStart.bat" and accept the uac prompt to elevate to admin, once (unless you restart your computer, the window never actually closes so you don't need to worry about it prompting again)
