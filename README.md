# Powershell Snippets
 Powershell content that I've sourced or built over the years (2017-2019).

## BIOS Captures
This script I based it off of another [script](http://www.systanddeploy.com/2019/03/list-and-change-bios-settings-with.html) while I was trying to streamline BIOS configurations on a client. This sample currently has a Lenovo configuration setup for the purpose, where it would log in and then determine which models have a valid configuration. If there is no configuration for the particular machine, it generates a CSV file so that you can set up a master checklist later for that model so need be. I haven't tested it against Dell and HP machines at the time since most of the clients had Lenovo Products.

## Client_1
This script is used for basically checking and applying the host name on a machine, as well as applying a default license key. and to add the machine to the client's domain.

## Client_3
This script is sort of an extended version of Client_1, where we now have a list of various machines and specified users going to each particular machine.

Each user has a dedicated timezone and a specific computer name. This is usually checked via serial before configuration.

The script also has a switch statement of messages I've fitted in since I thought it would be more convienient to standardize prompt and error codes in one big switch statement (at the time).

This script also has components for connecting Cisco AnyConnect as well as Symantec.
