#pragma semicolon 1
#pragma tabsize 0
#pragma newdecls required

#include <sourcemod>
#include <sdktools> 

public Plugin myinfo = 
{
	name        = "Map | Mod Configs",
	author      = "BOT Benson",
	description = "BOT Benson",
	version     = "v1.0",
	url         = "https://www.botbenson.com"
};

char smPath[128], pluginPath[128], temp[128];
ArrayList commandList, pluginsList, modsList;

/**
 *
 * Eklenti başlatıldığında tetiklenir.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
public void OnPluginStart() 
{ 
	BuildPath(Path_SM, smPath, 128, "configs/map-cfg/");
	BuildPath(Path_SM, pluginPath, 128, "plugins/");
} 

/**
 *
 * Harita başlamadan önce ayarları uygular
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
public void OnAutoConfigsBuffered()
{
	ExecuteMapSpecificConfigs();
}

/**
 *
 * Harita ayarlarını uygular.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
bool ExecuteMapSpecificConfigs() 
{
	commandList = new ArrayList(128);
	pluginsList = new ArrayList(196);
	modsList    = new ArrayList(96);

	setDefaultPlugins();

	FindMapConfigs();

	if(modsList.Length == 0) 
	{
		PluginsAllRelease();
		return true;
	}

	char path[196];
	for (int i = 0; i < modsList.Length; i++) 
	{
		modsList.GetString(i, temp, sizeof(temp));		

		Format(path, sizeof(path), "%s%s", smPath, temp);
		CommandAndPluginResult(path);
		
		PluginsAllRelease();
		ExecuteAllCommand();	
	}

	return true;
}

/**
 *
 * Varsayılan eklentileri belirler
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
void setDefaultPlugins()
{
	pluginsList.PushString("admin-flatfile");
	pluginsList.PushString("adminhelp");
	pluginsList.PushString("adminmenu");
	pluginsList.PushString("antiflood");
	pluginsList.PushString("basebans");
	pluginsList.PushString("basechat");
	pluginsList.PushString("basecomm");
	pluginsList.PushString("basecommands");
	pluginsList.PushString("basetriggers");
	pluginsList.PushString("basevotes");
	pluginsList.PushString("clientprefs");
	pluginsList.PushString("funcommands");
	pluginsList.PushString("funvotes");
	pluginsList.PushString("playercommands");
	pluginsList.PushString("mapconfigs");
}

/**
 *
 * Map/Mod Config dosyalarını Bulur.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
bool FindMapConfigs()
{

	char currentMap[128], configFile[128], file[2][64];
	GetCurrentMap(currentMap, sizeof(currentMap));

	int mapSepPos = FindCharInString(currentMap, '/', true);
	if (mapSepPos != -1) {
		strcopy(currentMap, sizeof(currentMap), currentMap[mapSepPos + 1]);
	}

	DirectoryListing directory = OpenDirectory(smPath);
	if (directory == null) {
		delete directory;
		return false;
	}

	FileType fileType;
	while (directory.GetNext(configFile, sizeof(configFile), fileType))
	{
		if (fileType == FileType_File) 
		{
			ExplodeString(configFile, ".", file, 2, sizeof(file[]));
			if (StrEqual(file[1], "cfg", false)) 
			{
				if (strncmp(currentMap, file[0], strlen(file[0]), false) == 0) 
				{
					modsList.PushString(configFile);
				}
			}
		}
	}

	delete directory;
	return true;
}

/**
 *
 * Config dosyasını bulur ve ayarları yükler.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
bool CommandAndPluginResult(char[] configFilePath)
{
	File file = OpenFile(configFilePath, "r");
	if(file == null)  {
		return false;
	}

	int len;
	char command[2][128];

    while (!file.EndOfFile() && file.ReadLine(temp, sizeof(temp)))
    {
		len = strlen(temp);
		if (temp[len - 1] == '\n'){
			temp[--len] = '\0';
		}

		TrimString(temp);
		if(temp[0] == 0) {
			continue;
		}

		ExplodeString(temp, " ", command, 2, sizeof(command[]));

		TrimString(command[0]);
		TrimString(command[1]);

		if(StrEqual(command[0], "sm_active_plugin"))
		{
			pluginsList.PushString(command[1]);
		}
		else if(command[0][0] != 0 && command[1][0] != 0)
		{
			commandList.PushString(temp);
		}
    }

    delete file;
    return true;
}

/**
 *
 * Komutların hepsini çalıştırır.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
void ExecuteAllCommand()
{
	char command[2][96];
	for(int i = 0; i < commandList.Length; i++)
	{
		commandList.GetString(i, temp, 96);		
		ExplodeString(temp, " ", command, 2, sizeof(command[]));
		
		if(!command[1][0]){
			continue;
		}
		
		TrimString(command[0]);
		TrimString(command[1]);
		
		if (!command[0][0] || !command[1][0]){
			continue;
		}
		
		SetCvarString(command[0], command[1]);
	}
}

/**
 *
 * Cvar Değerini değiştirir.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
bool SetCvarString(char[] cvarName, char[] value)
{

	ConVar cvar = FindConVar(cvarName);
	if(cvar == null){
		return false;
	}
	
	cvar.SetString(value, true, true);
	return true;
}

/**
 *
 * Pluginleri Gerekli klasörlere taşır ve aktif/pasif yapar.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
bool PluginsAllRelease() 
{
	DirectoryListing directory = OpenDirectory(pluginPath);
	if(directory == null) {
		return false;
	}

	char newPath[128], oldPath[128];

	FileType filetype;
	while (directory.GetNext(temp, sizeof(temp), filetype))
	{
		if(filetype != FileType_File || temp[0] == 0 || StrEqual(temp, "disabled") || StrEqual(temp, ".") ||  StrEqual(temp , "..")) {
			continue;
		}

		ReplaceString(temp, sizeof(temp), ".smx", "");

		int find = pluginsList.FindString(temp);
		if(find != -1) 
		{
			pluginsList.Erase(find);
		}
		else 
		{
			Format(newPath, sizeof(newPath), "%sdisabled/%s.smx", pluginPath, temp);
			Format(oldPath, sizeof(oldPath), "%s%s.smx", pluginPath, temp);		

			RenameFile(newPath, oldPath);
			ServerCommand("sm plugins unload %s.smx", temp);
		}
	}

	for(int i = 0; i < pluginsList.Length; i++)
	{

		pluginsList.GetString(i, temp, sizeof(temp));		
		Format(newPath, sizeof(newPath), "%s%s.smx", pluginPath, temp);
		Format(oldPath, sizeof(oldPath), "%sdisabled/%s.smx", pluginPath, temp);

		if(!FileExists(oldPath)) {
			continue;
		}

		RenameFile(newPath,oldPath);
		ServerCommand("sm plugins load %s.smx", temp);
	}

	return true;
}
