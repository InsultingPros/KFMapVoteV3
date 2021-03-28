class KFXMapListLoader extends DefaultMapListLoader;

//------------------------------------------------------------------------------------------------
function LoadMapList(xVotingHandler VotingHandler)
{
	local int p, i;
	local array<string> PrefixList;
	local class<GameInfo> GameClass;
	local string A,B;

	if( Class'DefaultMapListLoader'.Default.bUseMapList )
	{
		log("Loading Maps from the following MapLists",'MapVote');
		MapListTypeList = Class'DefaultMapListLoader'.Default.MapListTypeList;
		if(MapListTypeList.Length == 0)
		{
			// Use default MapLists from each of MapVotes GameConfig settings
			for(i=0; i < VotingHandler.GameConfig.Length; i++)
			{
				GameClass = class<GameInfo>(DynamicLoadObject(VotingHandler.GameConfig[i].GameClass, class'Class'));
				if(GameClass != none)
				{
					log(GameClass.default.MapListType,'MapVote');
					LoadFromMapList(GameClass.default.MapListType, VotingHandler);
				}
			}
		}
		else
		{
			// Use the listed MapList classes
			for(i=0; i<MapListTypeList.Length; i++)
			{
				log(MapListTypeList[i],'MapVote');
				LoadFromMapList(MapListTypeList[i], VotingHandler);
			}
		}
	}
	else
	{
		MapNamePrefixes = Class'DefaultMapListLoader'.Default.MapNamePrefixes;
		log("Loading Maps from Maps dir. " $ MapNamePrefixes,'MapVote');

		// Use the MapNamePrefixes to load all maps in maps directory
		if( MapNamePrefixes == "" ) // get map prefixes from GameConfig
		{
			for(i=0; i < VotingHandler.GameConfig.Length; i++)
			{
				A = VotingHandler.GameConfig[i].Prefix;
				Divide(A,"|",A,B);
				if( i>0 )
					A = ","$A;
				MapNamePrefixes $= A;
			}
		}

		PrefixList.Length = 0;
		p = Split(MapNamePrefixes, ",", PrefixList);
		if(p > 0)
		{
			for(i=0; i < PrefixList.Length; i++)
				LoadFromPrefix(PrefixList[i],VotingHandler);
		}
	}
}
//------------------------------------------------------------------------------------------------
function LoadFromPreFix(string Prefix, xVotingHandler VotingHandler)
{
	local string FirstMap,NextMap,MapName,TestMap;

	FirstMap = Level.GetMapName(PreFix, "", 0);
	NextMap = FirstMap;
	while(!(FirstMap ~= TestMap))
	{
		MapName = NextMap;
		if( Right(MapName,4)~=".rom" )
			MapName = Left(MapName,Len(MapName)-4); // remove ".rom"

		VotingHandler.AddMap(MapName, "", "");

		NextMap = Level.GetMapName(PreFix, NextMap, 1);
		TestMap = NextMap;
	}
}
//================================================================================================
//                                    Configuration
//================================================================================================
static function FillPlayInfo(PlayInfo PlayInfo)
{
	PlayInfo.AddClass(Class'DefaultMapListLoader');
	PlayInfo.AddSetting(default.MapVoteGroup,"bUseMapList",default.UseMapListPropsDisplayText,0,1,"Check",,,True,True);
}

defaultproperties
{
}