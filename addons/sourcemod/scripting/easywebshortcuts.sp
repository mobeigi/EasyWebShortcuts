#include <sourcemod>
#include <webfix>

#pragma semicolon 1
#pragma newdecls required

// Plugin Informaiton
#define VERSION "1.00"

//Definitions
#define MAX_SHORTCUTS 1000

//Globals
enum WebShortcutStruct
{
  String:triggerText[255],
  width,
  height,
  bool:hidden,
  String:destinationUrl[2000]
}

int g_WebShortcuts[MAX_SHORTCUTS][WebShortcutStruct];
int g_WebShortcutsCount = 0;

char g_ServerIp[16];
char g_ServerPort[6];

public Plugin myinfo =
{
  name = "Easy Web Shortcuts",
  author = "Invex | Byte",
  description = "Easy Web Shortcuts for CSGO",
  version = VERSION,
  url = "http://www.invexgaming.com.au"
};

public void OnPluginStart()
{
  RegAdminCmd("sm_web", Command_Web, ADMFLAG_GENERIC, "Open URL for a specific target");
  RegAdminCmd("sm_ews_reload", Command_ReloadWebShortcuts, ADMFLAG_ROOT, "Reload Web Shortcuts");
  
  //Store Server IP and Port globally
  int hostip = GetConVarInt(FindConVar("hostip"));
  Format(g_ServerIp, sizeof(g_ServerIp), "%u.%u.%u.%u",
  (hostip >> 24) & 0x000000FF, (hostip >> 16) & 0x000000FF, (hostip >> 8) & 0x000000FF, hostip & 0x000000FF);

  ConVar hostport = FindConVar("hostport");
  hostport.GetString(g_ServerPort, sizeof(g_ServerPort));
  
  //Load Shortcuts from config file
  LoadWebShortcutsFromConfig();
}

public void OnMapEnd()
{
	LoadWebShortcutsFromConfig();
}

public Action Command_Web(int client, int args)
{
  if (args < 2) {
    ReplyToCommand(client, "[SM] Usage: sm_web <target> <url>");
    return Plugin_Handled;
	}
  
  char target[64];
  GetCmdArg(1, target, sizeof(target));
  
  char url[2000];
  GetCmdArg(2, url, sizeof(url));
  StripQuotes(url);
  
  //Add http:// protocol if no protocol was provided
  if (StrContains(url, "http://", false) != 0 && StrContains(url, "https://", false) != 0 && !StrEqual(url, "about:blank")) {
    Format(url, sizeof(url), "http://%s", url);
  }
  
  char target_name[MAX_TARGET_LENGTH];
  int target_list[MAXPLAYERS], target_count;
  bool tn_is_ml;
  
  if ((target_count = ProcessTargetString(
      target,
      client,
      target_list,
      MAXPLAYERS,
      0,
      target_name,
      sizeof(target_name),
      tn_is_ml)) <= 0)
  {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

  for (int i = 0; i < target_count; ++i) {
    WebFix_OpenUrl(target_list[i], "Easy Web Shortcuts", url);
  }
  
  return Plugin_Handled;
}

public Action Command_ReloadWebShortcuts(int client, int args)
{
  LoadWebShortcutsFromConfig();
  ReplyToCommand(client, "Easy Web Shortcuts list of shortcuts reloaded.");
  return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command_t, const char[] command)
{
  for (int i = 0; i < g_WebShortcutsCount; ++i) {
    if (StrContains(command, g_WebShortcuts[i][triggerText], false) == 0) {
      char url[2000];
      Format(url, sizeof(url), g_WebShortcuts[i][destinationUrl]);
      
      //Get Required information
      char name[64];
      char userid[16];
      char steamid[32];
      char steamid64[18];
      char clientip[16];
      
      GetClientName(client, name, sizeof(name));
      FormatEx(userid, sizeof(userid), "%u", GetClientUserId(client));
      GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
      GetClientAuthId(client, AuthId_SteamID64, steamid64, sizeof(steamid64));
      GetClientIP(client, clientip, sizeof(clientip));
      
      //Replace various tags in url
      ReplaceString(url, sizeof(url), "{SERVERIP}", g_ServerIp);
      ReplaceString(url, sizeof(url), "{SERVERPORT}", g_ServerPort);
      ReplaceString(url, sizeof(url), "{NAME}", name);
      ReplaceString(url, sizeof(url), "{USERID}", userid);
      ReplaceString(url, sizeof(url), "{STEAMID}", steamid);
      ReplaceString(url, sizeof(url), "{STEAMID64}", steamid64);
      ReplaceString(url, sizeof(url), "{IP}", clientip);
      
      WebFix_OpenUrl(client, "Easy Web Shortcuts", url, g_WebShortcuts[i][hidden], g_WebShortcuts[i][width], g_WebShortcuts[i][height]);
      break;
    }
  }
  
  return Plugin_Continue;
}

void LoadWebShortcutsFromConfig()
{
  //Reset counter
  g_WebShortcutsCount = 0;
  
  //Build config path
  char configFilePath[PLATFORM_MAX_PATH];
  Format(configFilePath, sizeof(configFilePath), "configs/easywebshortcuts.txt");
  BuildPath(Path_SM, configFilePath, PLATFORM_MAX_PATH, configFilePath);
  
  if (FileExists(configFilePath)) {
    //Open config file
    File file = OpenFile(configFilePath, "r");
    
    if (file != null) {
      char buffer[PLATFORM_MAX_PATH];
      
      //For each file in the text file
      while (file.ReadLine(buffer, sizeof(buffer))) {
        //Remove final new line
        //buffer length > 0 check needed in case file is completely empty and there is no new line '\n' char after empty string ""
        if (strlen(buffer) > 0 && buffer[strlen(buffer) - 1] == '\n')
          buffer[strlen(buffer) - 1] = '\0';
        
        //Remove any whitespace at either end
        TrimString(buffer);
        
        //Ignore empty lines
        if (strlen(buffer) == 0)
          continue;
          
        //Ignore comment lines
        if (StrContains(buffer, "//") == 0)
          continue; 
        
        //Parse line into g_WebShortcuts array
        char part[3][2000];
        int index = ExplodeString(buffer, " ", part, sizeof(part), sizeof(part[]), true);
        
        //Ensure we have 3 components in line (trigger, dimensions, url)
        if (index == 3) {
          //Strip Quotes
          StripQuotes(part[0]);
          StripQuotes(part[1]);
          StripQuotes(part[2]);
          
          //Set some default values
          g_WebShortcuts[g_WebShortcutsCount][hidden] = false;
          g_WebShortcuts[g_WebShortcutsCount][width] = 0;
          g_WebShortcuts[g_WebShortcutsCount][height] = 0;
        
          //Store trigger text and url
          Format(g_WebShortcuts[g_WebShortcutsCount][triggerText], 255, part[0]);
          Format(g_WebShortcuts[g_WebShortcutsCount][destinationUrl], 255, part[2]);
          
          //Process width/height
          if (StrEqual(part[1], "full", false)) {
            g_WebShortcuts[g_WebShortcutsCount][width] = 0;
            g_WebShortcuts[g_WebShortcutsCount][height] = 0;
          }
          else if (StrEqual(part[1], "hidden", false)) {
            g_WebShortcuts[g_WebShortcutsCount][hidden] = true;
          }
          else {
            char dimensions[2][32];
            ExplodeString(part[1], "x", dimensions, sizeof(dimensions), sizeof(dimensions[]), true);
            
            g_WebShortcuts[g_WebShortcutsCount][width] = StringToInt(dimensions[0]);
            g_WebShortcuts[g_WebShortcutsCount][height] = StringToInt(dimensions[1]);
          }
          
          ++g_WebShortcutsCount;
        }
      }
      
      file.Close();
    }
  } else {
    LogError("Missing required config file: '%s'", configFilePath);
  }
}