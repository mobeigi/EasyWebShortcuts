<p align="center">
<img src="https://i.imgur.com/uVemgWU.png" height="96px" width="96px"/>
<br/>
<h3 align="center">Easy Web Shortcuts</h3>
<p align="center">Web Shortcuts with chat triggers and commands</p>
<h2></h2>
</p>
<br />

<p align="center">
<a href="../../releases"><img src="https://img.shields.io/github/release/InvexByte/EasyWebShortcuts.svg?style=flat-square" /></a>
<a href="../../issues"><img src="https://img.shields.io/github/issues/InvexByte/EasyWebShortcuts.svg?style=flat-square" /></a>
<a href="../../pulls"><img src="https://img.shields.io/github/issues-pr/InvexByte/EasyWebShortcuts.svg?style=flat-square" /></a> 
<a href="LICENSE.md"><img src="https://img.shields.io/github/license/InvexByte/EasyWebShortcuts.svg?style=flat-square" /></a>
</p>

## Description
A web shortcuts plugin for CSGO.  
Supports multiple chat triggers and commands per URL. 

## Commands
**sm_web <target> <url>** - Open URL for a specific target (generic admins)  
**sm_ews_reload** - Reload Web Shortcuts (root admin)  

## Instructions
1. Download and setup VGUI URL Cache Buster (https://forums.alliedmods.net/showthread.php?t=302530) (https://github.com/nosoop/SM-VGUICacheBuster/) on your server
2. Compile **easywebshortcuts.sp**
3. Copy **easywebshortcuts.smx** to your server.
4. Copy **easywebshortcuts.txt** to **/addons/sourcemod/configs/**
5. Edit **easywebshortcuts.txt** with shortcuts you want (instructions inside the file)
6. Reload the plugin, change the map or use **sm_ews_reload** as a root admin to update changes

## Example easywebshortcuts.txt
```
// Easy Web Shortcuts
// Configuration File
//
// Enter your shortcuts in this file. One per line.
// Empty lines or lines begging with '//' are ignored
//
// Format: "triggers" "commands" "dimensions" "url"
//
// dimensions must either be "full" (for client max screen size), "hidden" (invisible window) or in "widthxheight" format (i.e. 1280x720)
// url should start with "http://", "https://" or be the exact string "about:blank"

//Triggers only (1280x720 resolution)
"!vip" "" "1280x720" "http://www.example.com/vip"

//Commands Only (full resolution)
"" "sm_wikipedia" "full" "http://www.wikipedia.org"

//Multiple triggers and commands
"!forums|!website|!home" "sm_forums|sm_website|sm_home" "full" "http://www.example.com"

//Play Hidden video in background
"!funnyvideo" "" "hidden" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

//Stop playing hidden video in background
"!stop" "" "hidden" "about:blank"

//Using string replacements
"!gametracker" "" "full" "https://www.gametracker.com/server_info/{SERVERIP}:{SERVERPORT}}/"
"!serverswiththismap" "" "full" "https://www.gametracker.com/search/csgo/?search_by=map&query={MAPNAME}"
"!mysteamprofile" "" "full" "http://steamcommunity.com/profiles/{STEAMID64}"
```

## URL String Replacements 
The following strings are replaced if they appear in the URLs specified in easywebshortcuts.txt:  

**{SERVERIP}** - Server IP Adress  
**{SERVERPORT}** - Server Port  
**{NAME}** - Client In-Game Name  
**{USERID}** - Client User ID  
**{STEAMID}** - Client Steam ID  
**{STEAMID64}** - Client Steam ID 64 (community id)  
**{IP}** - Client IP Address  
**{MAPNAME}** - The map name  
**{MAPDISPLAYNAME}** - Map name after last '/' (without workshop prefix etc)  

Need more replacements?  
Request some!  

## AlliedModders Plugin Thread
Link: [https://forums.alliedmods.net/showthread.php?t=302600](https://forums.alliedmods.net/showthread.php?t=302600)

## Contributions
Contributions are always welcome!
Just make a [pull request](../../pulls).

## Licence
GNU General Public License v3.0
