class KFXMapListLoader extends DefaultMapListLoader;

var array<string> LoadedPrefixes;
var string DefaultMapExt;

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
function LoadFromMapList(string MapListType, xVotingHandler VotingHandler)
{
	local string Mutators,GameOptions;
	local class<MapList> MapListClass;
	local string MapName;
	local array<string> Parts;
	local array<string> Maps;
	local int x,p,i;
	local int extlen;

	MapListClass = class<MapList>(DynamicLoadObject(MapListType, class'Class'));
	if(MapListClass == none)
	{
		Log("___Couldn't load maplist type:"$MaplistType,'MapVote');
		return;
	}

	extlen = len(DefaultMapExt);
	Maps = MapListClass.static.StaticGetMaps();
	for(i=0;i<Maps.Length;i++)
	{
		Mutators = "";
		GameOptions = "";

		MapName = Maps[i];

		// Parse map string incase there are mutator and game options in it
		// DOM-Aztec?Game=XGame.xDoubleDom?mutator=XGame.MutVampire,UTSecure.MutUTSecure?WeaponStay=True?Translocator=True?TimeLimit=15
		// p0       | p1                  | p2                                          | p3            | p4              | p5
		Parts.Length = 0;
		p = Split(MapName, "?", Parts);
		if(p > 1)
		{
			MapName = Parts[0];
			for(x=1;x<Parts.Length;x++)
			{
				if(left(Parts[x],8) ~= "mutator=")
				{
				Mutators = Mid(Parts[x],8);
				}
				else
				{
				// ignore the "game" option but add all others to GameOptions
				if(!(left(Parts[x],5) ~= "Game="))
				{
					if(GameOptions == "")
						GameOptions = Parts[x];
					else
						GameOptions = GameOptions $ "?" $ Parts[x];
				}
				}
			}
		}

		if (Right(MapName, extlen) ~= DefaultMapExt)
			MapName = Left(MapName, Len(MapName) - extlen); // remove file extension
		VotingHandler.AddMap(MapName, Mutators, GameOptions);
	}
}
//------------------------------------------------------------------------------------------------
function LoadFromPreFix(string Prefix, xVotingHandler VotingHandler)
{
	local string FirstMap,NextMap,MapName,TestMap;
	local int i, count;
	local int extlen;

	extlen = len(DefaultMapExt);
	for (i = 0; i < LoadedPrefixes.Length; ++i) {
		if (LoadedPrefixes[i] ~= Prefix)
			return;
	}
	LoadedPrefixes.insert(i,1);
	LoadedPrefixes[i] = Prefix;

	StopWatch(false); // reset timer
	FirstMap = Level.GetMapName(PreFix, "", 0);
	NextMap = FirstMap;
	while (!(FirstMap ~= TestMap)) {
		MapName = NextMap;
		if (Right(MapName, extlen) ~= DefaultMapExt)
			MapName = Left(MapName, Len(MapName) - extlen); // remove file extension
		VotingHandler.AddMap(MapName, "", "");

		NextMap = Level.GetMapName(PreFix, NextMap, 1);
		TestMap = NextMap;
		++count;
	}
	StopWatch(true); // log elapsed time
	log(string(count) $ " '"$Prefix$"' maps loaded", 'MapVote');
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
	DefaultMapExt=".rom"
}