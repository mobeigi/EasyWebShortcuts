#include <sourcemod>
#include <vgui_motd_stocks>

#pragma semicolon 1
#pragma newdecls required

/*********************************
 *  Plugin Information
 *********************************/
#define PLUGIN_VERSION "1.11"

public Plugin myinfo =
{
  name = "Easy Web Shortcuts",
  author = "Invex | Byte",
  description = "Easy Web Shortcuts for CSGO",
  version = PLUGIN_VERSION,
  url = "http://www.invexgaming.com.au"
};

/*********************************
 *  Definitions
 *********************************/
#define MAX_SHORTCUTS 1000
#define MAX_URL_LENGTH 2000
#define MAX_OPTION_GROUPS 4
#define VALUE_SEPARATOR "|"

/*********************************
 *  Enumerations
 *********************************/
enum WebShortcutStruct
{
  ArrayList:triggers,
  ArrayList:commands,
  width,
  height,
  bool:show,
  String:destinationUrl[MAX_URL_LENGTH],
}

/*********************************
 *  Globals
 *********************************/

 //Main
int g_WebShortcuts[MAX_SHORTCUTS][WebShortcutStruct];
int g_WebShortcutsCount = 0;

//Replace Variables
char g_ServerIp[16];
char g_ServerPort[6];
char g_CurrentMapName[64];
char g_CurrentMapDisplayName[64];

/*********************************
 *  Forwards
 *********************************/

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

  //Load config
  LoadWebShortcutsFromConfig();
}

public void OnMapStart()
{
  //Get map related replace values
  GetCurrentMap(g_CurrentMapName, sizeof(g_CurrentMapName));
  GetMapDisplayName(g_CurrentMapName, g_CurrentMapDisplayName, sizeof(g_CurrentMapDisplayName));
}

//Process triggers
public Action OnClientSayCommand(int client, const char[] command_t, const char[] command)
{
  for (int i = 0; i < g_WebShortcutsCount; ++i) {
    if (g_WebShortcuts[i][triggers].FindString(command) != -1) {
      char url[MAX_URL_LENGTH];
      strcopy(url, sizeof(url), g_WebShortcuts[i][destinationUrl]);
      
      ReplaceUrlParams(client, url, sizeof(url));

      CSGO_ShowMOTDPanel(client, "Easy Web Shortcuts", url, g_WebShortcuts[i][show], g_WebShortcuts[i][width], g_WebShortcuts[i][height]);
      break;
    }
  }
  
  return Plugin_Continue;
}

public void OnPluginEnd()
{
  RemoveAllCommandListeners();
}

/*********************************
 *  Commands
 *********************************/

public Action Command_Web(int client, int args)
{
  if (args < 2) {
    ReplyToCommand(client, "[SM] Usage: sm_web <target> <url>");
    return Plugin_Handled;
	}
  
  char target[64];
  GetCmdArg(1, target, sizeof(target));
  
  char url[MAX_URL_LENGTH];
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
    char finalurl[MAX_URL_LENGTH];
    strcopy(finalurl, sizeof(finalurl), url);
    ReplaceUrlParams(target_list[i], finalurl, sizeof(finalurl));
    CSGO_ShowMOTDPanel(target_list[i], "Easy Web Shortcuts", finalurl, true);
  }
  
  return Plugin_Handled;
}

public Action Command_OpenUrlListener(int client, const char[] command, int args)
{
  if (!(1 <= client <= MaxClients))
    return Plugin_Handled;

  if (!IsClientInGame(client))
    return Plugin_Handled;

  for (int i = 0; i < g_WebShortcutsCount; ++i) {
    if (g_WebShortcuts[i][commands].FindString(command) != -1) {
      char url[MAX_URL_LENGTH];
      strcopy(url, sizeof(url), g_WebShortcuts[i][destinationUrl]);
      
      ReplaceUrlParams(client, url, sizeof(url));

      CSGO_ShowMOTDPanel(client, "Easy Web Shortcuts", url, g_WebShortcuts[i][show]);
      break;
    }
  }
  
  return Plugin_Handled;
}

public Action Command_ReloadWebShortcuts(int client, int args)
{
  LoadWebShortcutsFromConfig();
  ReplyToCommand(client, "Easy Web Shortcuts list of shortcuts reloaded.");
  return Plugin_Handled;
}

/*********************************
 *  Helper Functions / Other
 *********************************/
void LoadWebShortcutsFromConfig()
{ 
  //Remove any previous command listeners
  RemoveAllCommandListeners();

  //Delete any previous arraylists
  for (int i = 0; i < g_WebShortcutsCount; ++i) {
    delete g_WebShortcuts[i][triggers];
    delete g_WebShortcuts[i][commands];
  }

  //Reset counter
  g_WebShortcutsCount = 0;

  //Build config path
  char configFilePath[PLATFORM_MAX_PATH];
  strcopy(configFilePath, sizeof(configFilePath), "configs/easywebshortcuts.txt");
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
        char part[MAX_OPTION_GROUPS][MAX_URL_LENGTH];
        int index = ExplodeString(buffer, " ", part, sizeof(part), sizeof(part[]), true);
        
        //Ensure we have all config options
        if (index == MAX_OPTION_GROUPS) {
          //Strip Quotes
          StripQuotes(part[0]);
          StripQuotes(part[1]);
          StripQuotes(part[2]);
          StripQuotes(part[3]);

          //Set default values
          g_WebShortcuts[g_WebShortcutsCount][triggers] = new ArrayList(ByteCountToCells(64));
          g_WebShortcuts[g_WebShortcutsCount][commands] = new ArrayList(ByteCountToCells(64));
          g_WebShortcuts[g_WebShortcutsCount][show] = true;
          g_WebShortcuts[g_WebShortcutsCount][width] = CSGO_POPUP_FULL;
          g_WebShortcuts[g_WebShortcutsCount][height] = CSGO_POPUP_FULL;
        
          //Process triggers
          if (strlen(part[0]) != 0) {
            char triggersPart[32][64];
            int numTriggers = ExplodeString(part[0], VALUE_SEPARATOR, triggersPart, sizeof(triggersPart), sizeof(triggersPart[]), true);

            for (int i = 0; i < numTriggers; ++i)
              g_WebShortcuts[g_WebShortcutsCount][triggers].PushString(triggersPart[i]);
          }

          //Process commands
          if (strlen(part[1]) != 0) {
            char commandsPart[32][64];
            int numCommands = ExplodeString(part[1], VALUE_SEPARATOR, commandsPart, sizeof(commandsPart), sizeof(commandsPart[]), true);

            for (int i = 0; i < numCommands; ++i) {
              StringToLower(commandsPart[i], sizeof(commandsPart[]));
              g_WebShortcuts[g_WebShortcutsCount][commands].PushString(commandsPart[i]);
              AddCommandListener(Command_OpenUrlListener, commandsPart[i]);
            }
          }

          //Process width/height
          if (StrEqual(part[2], "full", false)) {
            g_WebShortcuts[g_WebShortcutsCount][width] = CSGO_POPUP_FULL;
            g_WebShortcuts[g_WebShortcutsCount][height] = CSGO_POPUP_FULL;
          }
          else if (StrEqual(part[2], "hidden", false)) {
            g_WebShortcuts[g_WebShortcutsCount][show] = false;
          }
          else {
            char dimensions[2][32];
            ExplodeString(part[2], "x", dimensions, sizeof(dimensions), sizeof(dimensions[]), true);
            
            g_WebShortcuts[g_WebShortcutsCount][width] = StringToInt(dimensions[0]);
            g_WebShortcuts[g_WebShortcutsCount][height] = StringToInt(dimensions[1]);
          }

          //Process destination URL
          strcopy(g_WebShortcuts[g_WebShortcutsCount][destinationUrl], 2000, part[3]);

          ++g_WebShortcutsCount;
        }
      }
      
      file.Close();
    }
  } else {
    LogError("Missing required config file: '%s'", configFilePath);
  }
}

void ReplaceUrlParams(int client, char[] url, int maxlen)
{
  if (!IsClientInGame(client))
    return;
  
  char name[64], userid[16], steamid[32], steamid64[18], clientip[16];

  //Get Required information
  GetClientName(client, name, sizeof(name));
  FormatEx(userid, sizeof(userid), "%u", GetClientUserId(client));
  GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
  GetClientAuthId(client, AuthId_SteamID64, steamid64, sizeof(steamid64));
  GetClientIP(client, clientip, sizeof(clientip));
  
  //Replace various tags in url
  ReplaceString(url, maxlen, "{SERVERIP}", g_ServerIp);
  ReplaceString(url, maxlen, "{SERVERPORT}", g_ServerPort);
  ReplaceString(url, maxlen, "{NAME}", name);
  ReplaceString(url, maxlen, "{USERID}", userid);
  ReplaceString(url, maxlen, "{STEAMID}", steamid);
  ReplaceString(url, maxlen, "{STEAMID64}", steamid64);
  ReplaceString(url, maxlen, "{IP}", clientip);
  ReplaceString(url, maxlen, "{MAPNAME}", g_CurrentMapName);
  ReplaceString(url, maxlen, "{MAPDISPLAYNAME}", g_CurrentMapDisplayName);
}

void RemoveAllCommandListeners()
{
  char command[64];
  for (int i = 0; i < g_WebShortcutsCount; ++i) {
    for (int j = 0; j < g_WebShortcuts[i][commands].Length; ++j) {
      g_WebShortcuts[i][commands].GetString(j, command, sizeof(command));
      RemoveCommandListener(Command_OpenUrlListener, command);
    }
  }
}

/*********************************
 *  Stocks
 *********************************/

//Inplace transformation of string to lower case
stock void StringToLower(char[] string, int len)
{
  for (int i = 0; i < len; ++i)
    string[i] = CharToLower(string[i]);
}