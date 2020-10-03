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
	version     = "v2.0.2",
	url         = "https://www.botbenson.com"
};

char smPath[128], pluginPath[128], temp[128], subTemp[128], subFolder[128],  newPath[128], oldPath[128];
ArrayList commandList, pluginsList, modsList, folderList;

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
 * Varsayılan eklentileri belirler
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
void SetDefaultPlugins()
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
	pluginsList.PushString("mapconfigs-v2");
}

/**
 *
 * Varsayılan modları belirler
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
void SetDefaultFolders()
{
	
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
 * Dosyanın geçerlilğini kontrol eder.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
stock bool CheckIsContinueFile(char[] name, int length, bool isPlugin = false)
{
	if(name[0] == 0 || StrEqual(name, ".") ||  StrEqual(name , "..")) 
	{
		return false;
	}

	if(isPlugin && !StrContains(name, ".smx")) 
	{
		return false;
	}

	ReplaceString(name, length, ".smx", "");
	return true;
}

/**
 *
 * Eklentiyi Aktif Yapar
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
bool PluginSetActive(char[] name, bool moveFile = true)
{
	Format(newPath, sizeof(newPath), "%s%s.smx", pluginPath, name);
	Format(oldPath, sizeof(oldPath), "%sdisabled/%s.smx", pluginPath, name);

	if(!FileExists(oldPath)) 
	{
		return false;
	}

	if(moveFile)
	{
		RenameFile(newPath, oldPath);
	}
	ServerCommand("sm plugins load %s.smx", name);
	return true;
}

/**
 *
 * Eklentiyi pasif yapar.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
bool PluginSetPassive(char[] name, bool moveFile = true)
{
	Format(newPath, sizeof(newPath), "%sdisabled/%s.smx", pluginPath, name);
	Format(oldPath, sizeof(oldPath), "%s%s.smx", pluginPath, name);		

	if(!FileExists(oldPath)) 
	{
		return false;
	}

	ServerCommand("sm plugins unload %s.smx", name);
	if(moveFile)
	{
		RenameFile(newPath, oldPath);
	}
	return true;
}
	
/**
 *
 * Eklenti klasörünü pasif yapar.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
void PluginFolderSetPassive(char[] folder)
{
	Format(subFolder, sizeof(subFolder), "%s%s", pluginPath, folder);

	DirectoryListing directory = OpenDirectory(subFolder);
	if(directory != null) 
	{
		FileType filetype;
		while (directory.GetNext(subTemp, sizeof(subTemp), filetype))
		{
			if(CheckIsContinueFile(subTemp, sizeof(temp), true)) 
			{
				Format(subTemp, sizeof(subTemp), "%s/%s", folder, subTemp);
				ServerCommand("sm plugins unload %s.smx", subTemp);
			}
		}

		Format(newPath, sizeof(newPath), "%sdisabled/%s", pluginPath, folder);
		RenameFile(newPath, subFolder);

		delete directory;
	}
}

/**
 *
 * Eklenti klasörünü aktif yapar.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
void PluginFolderSetActive(char[] folder)
{
	Format(oldPath, sizeof(oldPath), "%sdisabled/%s/", pluginPath, folder);
	Format(newPath, sizeof(newPath), "%s%s/", pluginPath, folder);
	if(DirExists(oldPath))
	{
		RenameFile(newPath, oldPath);

		DirectoryListing directory = OpenDirectory(newPath);
		if(directory != null) 
		{
			FileType filetype;
			while (directory.GetNext(subTemp, sizeof(subTemp), filetype))
			{
				if(CheckIsContinueFile(subTemp, sizeof(temp), true)) 
				{
					Format(newPath, sizeof(newPath), "%s/%s", folder, subTemp);
					ServerCommand("sm plugins load %s.smx", newPath);
				}
			}

			delete directory;
		}	
	}
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
	folderList  = new ArrayList(96);

	SetDefaultPlugins();
	SetDefaultFolders();

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
		if(temp[0] == 0) 
		{
			continue;
		}

		if(temp[0] == '/' || temp[1] == '/')
		{
			continue;
		}

		ExplodeString(temp, " ", command, 2, sizeof(command[]));

		TrimString(command[0]);
		TrimString(command[1]);

		if(StrEqual(command[0], "sm_active_plugin"))
		{
			pluginsList.PushString(command[1]);
		}
		else if(StrEqual(command[0], "sm_active_mode"))
		{
			folderList.PushString(command[1]);
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
 * Pluginleri Gerekli klasörlere taşır ve aktif/pasif yapar.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
bool PluginsAllRelease() 
{
	DirectoryListing directory = OpenDirectory(pluginPath);
	if(directory == null) 
	{
		return false;
	}

	FileType filetype;
	while (directory.GetNext(temp, sizeof(temp), filetype))
	{
		if(StrEqual(temp, "disabled")) 
		{
			continue;
		}

		if(filetype == FileType_Directory)
		{
			if(CheckIsContinueFile(temp, sizeof(temp)))
			{
				int folderIndex = folderList.FindString(temp);
				if(folderIndex != -1)
				{
					folderList.Erase(folderIndex);
	
				}
				else
				{
					PluginFolderSetPassive(temp);
	
				}
			}
		}
		else if(filetype == FileType_File)
		{
			if(CheckIsContinueFile(temp, sizeof(temp), true))
			{
				int pluginIndex = pluginsList.FindString(temp);
				if(pluginIndex != -1) 
				{
					pluginsList.Erase(pluginIndex);
	
				}
				else 
				{
					PluginSetPassive(temp);
	
				}
			}
			else
			{

			}
		}
	}

	for(int i = 0; i < pluginsList.Length; i++)
	{
		pluginsList.GetString(i, temp, sizeof(temp));
		PluginSetActive(temp);
	}

	for(int i = 0; i < folderList.Length; i++)
	{
		folderList.GetString(i, temp, sizeof(temp));
		PluginFolderSetActive(temp);
	}

	delete directory;
	return true;
}