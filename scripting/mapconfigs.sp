#pragma semicolon 1
#pragma tabsize 0
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

char smPath[ 128 ] , pluginPath[ 128 ] , temp[ 128 ];
ArrayList commandArray , pluginsArray , modsArray;

public Plugin myinfo = {
	name        = "Map | Mod Configs",
	author      = "BOT Benson",
	description = "Map | Mod Configs",
	version     = "1.0.0",
	url 		= "https://www.botbenson.com"
};

public void OnPluginStart()
{

	BuildPath(Path_SM, smPath, 128, "configs/pluginler/map-cfg/");
	BuildPath(Path_SM, pluginPath, 128, "plugins/");

}

public void OnAutoConfigsBuffered()
{

	ExecuteMapSpecificConfigs();

}

bool ExecuteMapSpecificConfigs() 
{
	
	commandArray = new ArrayList( 196 );
	pluginsArray = new ArrayList( 196 );
	modsArray    = new ArrayList( 96 );

	setDefaultPlugins( );

	getMapConfigs();

	int size = modsArray.Length;

	char path[196];

	for (int i = 0; i < size; ++i) 
	{

		modsArray.GetString(i, temp, 128 );		

		Format( path , 196 , "%s%s" , smPath , temp );
		commandAndPluginResult( path );

		pluginsAllRelease( );
		executeAllCommand( );	

	}

	if( size == 0 )
		pluginsAllRelease();

	return true;
}

void pluginsAllRelease( ) 
{

	DirectoryListing directory = OpenDirectory( pluginPath );
	
	if( directory == null) 
		return;

	char buffer[128] , newPath[128] , oldPath[128];

	FileType filetype;
	while ( directory.GetNext(buffer, sizeof(buffer), filetype) )
	{

		if( filetype != FileType_File || buffer[0] == 0 || StrEqual( buffer , "disabled" ) || StrEqual( buffer , "." ) ||  StrEqual( buffer , ".." ))
			continue;

		ReplaceString(buffer, sizeof(buffer), ".smx", "");
		int find =  pluginsArray.FindString( buffer );
		if( find == -1 )
		{

			Format( newPath , 128 , "%sdisabled/%s.smx" , pluginPath , buffer );
			Format( oldPath , 128 , "%s%s.smx" , pluginPath , buffer );

			RenameFile( newPath , oldPath );
			ServerCommand("sm plugins unload %s.smx", buffer);

		}
		else
		{

			pluginsArray.Erase( find );

		}

	}
	int size = pluginsArray.Length;
	for( int i = 0; i < size; i++)
	{

		pluginsArray.GetString(i, temp, 128 );		
		Format( newPath , 128 , "%s%s.smx" , pluginPath , temp );
		Format( oldPath , 128 , "%sdisabled/%s.smx" , pluginPath , temp );

		if( !FileExists( oldPath )  )
			continue;

		RenameFile( newPath , oldPath );
		ServerCommand("sm plugins load %s.smx", temp);

	}

}

void setDefaultPlugins( )
{

	pluginsArray.PushString( "mapconfigs" );
	pluginsArray.PushString( "adminmenu" );
	pluginsArray.PushString( "admin-flatfile" );
	pluginsArray.PushString( "antiflood" );
	pluginsArray.PushString( "basebans" );
	pluginsArray.PushString( "basechat" );
	pluginsArray.PushString( "basecomm" );
	pluginsArray.PushString( "basecommands" );
	pluginsArray.PushString( "basevotes" );
	pluginsArray.PushString( "funcommands" );
	pluginsArray.PushString( "funvotes" );
	pluginsArray.PushString( "playercommands" );


}

void executeAllCommand( )
{

	char explode[2][96];

	int size = commandArray.Length;
	for( int i = 0; i < size; i++ )
	{

		commandArray.GetString(i, temp, 128 );		
		ExplodeString( temp , " ", explode, 2, sizeof(explode[]));
		SetCvarString( explode[0] , explode[1] );

	}

}

void SetCvarString(char[] cvarName, char[] value)
{

	SetConVarString( FindConVar( cvarName ) , value, true);

}


void getMapConfigs()
{

	char currentMap[256] , configFile[256] , explode[2][64];
	GetCurrentMap(currentMap, 256 );

	int mapSepPos = FindCharInString(currentMap, '/', true);
	if (mapSepPos != -1)
		strcopy(currentMap, 256 , currentMap[mapSepPos+1]);

	Handle dir = OpenDirectory(smPath);
	
	if (dir == INVALID_HANDLE)
		return;

	FileType fileType;
	
	while (ReadDirEntry(dir, configFile, 256 , fileType)) 
	{
		if (fileType == FileType_File) 
		{
			
			ExplodeString(configFile, ".", explode, 2, sizeof(explode[]));
			
			if (StrEqual(explode[1], "cfg", false)) 
			{
				
				if (strncmp(currentMap, explode[0], strlen(explode[0]), false) == 0) 
				{
					modsArray.PushString( configFile );
				}
			}
		}
	}
	
	CloseHandle(dir);
	
}

void commandAndPluginResult(char[] _file)
{

	char buffer[128] , explode[2][128];

	Handle fileh = OpenFile(_file, "r");
	
	if(fileh == INVALID_HANDLE) 
		return;

	int len;
	while (!IsEndOfFile(fileh) && ReadFileLine(fileh, buffer, sizeof(buffer)))
	{

		len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';

		TrimString(buffer);

		if( buffer[0] == 0 )
			continue;

		ExplodeString( buffer , " ", explode, 2, sizeof(explode[]));

		if( StrEqual( explode[0] , "sm_eklenti_aktif" ) )
		{

			pluginsArray.PushString( explode[1] );

		}
		else if( explode[0][0] != 0 && explode[1][0] != 0  )
		{

			commandArray.PushString( buffer );

		}

	}

	if(fileh != INVALID_HANDLE)
		CloseHandle(fileh);
}