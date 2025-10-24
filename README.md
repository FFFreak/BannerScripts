Goto Customer Center -> Expirence Setup (Non-prod, until the endpoint is up in prod)
Hit F12 or your preferred method to bring up dev mode in browser
* Goto the NETWORK Tab
Click permissions in Expirence Setup
Right click an endpoint like "preferred name"
* Copy -> Copy as Powershell

Run powershell (as normal user)
goto to location you have the script (cd ~\Downloads ?)
paste your copied data from above, and hit enter - output does not matter

Run script
output will be CSV in Format: InsightsInheritencePermissions_(instance)_(date).csv
