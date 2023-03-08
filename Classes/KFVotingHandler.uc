// ====================================================================
//  KFVotingHandler - Modification by Marco
// ====================================================================
class KFVotingHandler extends xVotingHandler
	Config(KFMapVote);

struct FMapRepType
{
	var int Positive,Negative;
};
var array<FMapRepType> RepArray; // Map reputation array, should be in sync with MapList array.

function PostBeginPlay()
{
	local int i;

	AddToPackageMap(); // Make sure in serverpackages.

	Super(VotingHandler).PostBeginPlay();

	// disable voting in single player mode
	if( Level.NetMode==NM_StandAlone )
		return;

	if(bKickVote)
		log("Kick Voting Enabled",'MapVote');
	else
		log("Kick Voting Disabled",'MapVote');

	if(bMapVote)
	{
		log("Map Voting Enabled",'MapVote');
		// check current game settings
		if( GameConfig.Length > 0 )
		{
			if( !(string(Level.Game.Class) ~= GameConfig[CurrentGameConfig].GameClass) )
			{
				CurrentGameConfig = 0;
				// find matching game type in game config
				for( i=0; i<GameConfig.Length; i++)
				{
					if(GameConfig[i].GameClass ~= string(Level.Game.Class))
					{
						CurrentGameConfig = i;
						break;
					}
				}
			}
		}
		else
			CurrentGameConfig = 0;
		LoadMapList();
	}
	else
		log("Map Voting Disabled",'MapVote');

	if(bMatchSetup)
	{
		log("MatchSetup Enabled",'MapVote');

		MatchProfile = CreateMatchProfile();
		MatchProfile.Init(Level);
		MatchProfile.LoadCurrentSettings();
	}
	else
		log("MatchSetup Disabled",'MapVote');
}

function SubmitMapVote(int MapIndex, int GameIndex, Actor Voter)
{
	local int Index, VoteCount, PrevMapVote, PrevGameVote;
	local MapHistoryInfo MapInfo;
	local bool bAdminForce;

	if(bLevelSwitchPending)
		return;

	Index = GetMVRIIndex(PlayerController(Voter));
	if( GameIndex<0 )
	{
		bAdminForce = true;
		GameIndex = (-GameIndex) - 1;
	}
	if( GameIndex>=GameConfig.Length || MapIndex<0 || MapIndex>=MapList.Length )
		return; // Something is wrong...

	// check for invalid vote from unpatch players
	if( !IsValidVote(MapIndex, GameIndex) )
		return;

	if( bAdminForce && (PlayerController(Voter).PlayerReplicationInfo.bAdmin || PlayerController(Voter).PlayerReplicationInfo.bSilentAdmin) )  // Administrator Vote
	{
		TextMessage = lmsgAdminMapChange;
		TextMessage = Repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")");
		Level.Game.Broadcast(self,TextMessage);

		log("Admin has forced map switch to " $ MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")",'MapVote');

		CloseAllVoteWindows();

		bLevelSwitchPending = true;

		MapInfo = History.PlayMap(MapList[MapIndex].MapName);

		ServerTravelString = SetupGameMap(MapList[MapIndex], GameIndex, MapInfo);
		log("ServerTravelString = " $ ServerTravelString ,'MapVoteDebug');

		Level.ServerTravel(ServerTravelString, false);    // change the map

		settimer(1,true);
		return;
	}

	// check for invalid map, invalid gametype, player isnt revoting same as previous vote, and map choosen isnt disabled
	if( !MapList[MapIndex].bEnabled || (MVRI[Index].MapVote==MapIndex && MVRI[Index].GameVote==GameIndex) )
		return;

	log("___" $ Index $ " - " $ PlayerController(Voter).PlayerReplicationInfo.PlayerName $ " voted for " $ MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")",'MapVote');

	PrevMapVote = MVRI[Index].MapVote;
	PrevGameVote = MVRI[Index].GameVote;
	MVRI[Index].MapVote = MapIndex;
	MVRI[Index].GameVote = GameIndex;

	if(bAccumulationMode)
	{
		if(bScoreMode)
		{
			VoteCount = GetAccVote(PlayerController(Voter)) + int(GetPlayerScore(PlayerController(Voter)));
			TextMessage = lmsgMapVotedForWithCount;
			TextMessage = repl(TextMessage, "%playername%", PlayerController(Voter).PlayerReplicationInfo.PlayerName );
			TextMessage = repl(TextMessage, "%votecount%", string(VoteCount) );
			TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
			Level.Game.Broadcast(self,TextMessage);
		}
		else
		{
			VoteCount = GetAccVote(PlayerController(Voter)) + 1;
			TextMessage = lmsgMapVotedForWithCount;
			TextMessage = repl(TextMessage, "%playername%", PlayerController(Voter).PlayerReplicationInfo.PlayerName );
			TextMessage = repl(TextMessage, "%votecount%", string(VoteCount) );
			TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
			Level.Game.Broadcast(self,TextMessage);
		}
	}
	else
	{
		if(bScoreMode)
		{
			VoteCount = int(GetPlayerScore(PlayerController(Voter)));
			TextMessage = lmsgMapVotedForWithCount;
			TextMessage = repl(TextMessage, "%playername%", PlayerController(Voter).PlayerReplicationInfo.PlayerName );
			TextMessage = repl(TextMessage, "%votecount%", string(VoteCount) );
			TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
			Level.Game.Broadcast(self,TextMessage);
		}
		else
		{
			VoteCount =  1;
			TextMessage = lmsgMapVotedFor;
			TextMessage = repl(TextMessage, "%playername%", PlayerController(Voter).PlayerReplicationInfo.PlayerName );
			TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
			Level.Game.Broadcast(self,TextMessage);
		}
	}
	UpdateVoteCount(MapIndex, GameIndex, VoteCount);
	if( PrevMapVote > -1 && PrevGameVote > -1 )
		UpdateVoteCount(PrevMapVote, PrevGameVote, -MVRI[Index].VoteCount); // undo previous vote
	MVRI[Index].VoteCount = VoteCount;
	TallyVotes(false);
}

function TallyVotes(bool bForceMapSwitch)
{
	local int C;

	C = Level.Game.NumPlayers;
	Level.Game.NumPlayers+=Level.Game.NumSpectators;
	Super.TallyVotes(bForceMapSwitch);
	Level.Game.NumPlayers = C;
}

function AddMapVoteReplicationInfo(PlayerController Player)
{
	local KFVotingReplicationInfo M;

	M = Spawn(class'KFVotingReplicationInfo',Player,,Player.Location);
	if(M == None)
	{
		Log("___Failed to spawn VotingReplicationInfo",'MapVote');
		return;
	}

	M.PlayerID = Player.PlayerReplicationInfo.PlayerID;
	MVRI[MVRI.Length] = M;
}

function Timer()
{
	local int mapidx,gameidx,i;
	local MapHistoryInfo MapInfo;

	if(bLevelSwitchPending)
	{
		if( Level.NextURL == "" )
		{
			if(Level.NextSwitchCountdown < 0)  // if negative then level switch failed
			{
				Log("___Map change Failed, bad or missing map file.",'MapVote');
				GetDefaultMap(mapidx, gameidx);
				MapInfo = History.PlayMap(MapList[mapidx].MapName);
				ServerTravelString = SetupGameMap(MapList[mapidx], gameidx, MapInfo);
				log("ServerTravelString = " $ ServerTravelString ,'MapVoteDebug');
				History.Save();
				Level.ServerTravel(ServerTravelString, false);    // change the map
			}
		}
		return;
	}

	if(ScoreBoardTime > -1)
	{
		if(ScoreBoardTime == 0)
			OpenAllVoteWindows();
		ScoreBoardTime--;
		return;
	}
	TimeLeft--;

	if( TimeLeft==60 || TimeLeft==30 || TimeLeft==20 || (TimeLeft<=10 && TimeLeft>0) )  // play announcer count down voice
	{
		for( i=0; i<MVRI.Length; i++)
			if(MVRI[i] != none && MVRI[i].PlayerOwner != none )
				MVRI[i].PlayCountDown(TimeLeft);
	}
	if(TimeLeft == -1)  // force level switch if time limit is up
		TallyVotes(true);   // if no-one has voted a random map will be choosen
}

function string SetupGameMap(MapVoteMapList MapInfo, int GameIndex, MapHistoryInfo MapHistoryInfo)
{
	local string ReturnString;
	local string MutatorString;
	local string OptionString;
	local array<string> MapsInRotation;
	local int i;

	// Add Per-GameType Mutators
	if( Len(GameConfig[GameIndex].Mutators)!=0 )
		MutatorString = MutatorString $ GameConfig[GameIndex].Mutators;

	// Add Per-Map Mutators
	if( Len(MapHistoryInfo.U)!=0 )
		MutatorString = MutatorString $ "," $ MapHistoryInfo.U;

	// Add Per-GameType Game Options
	if(GameConfig[GameIndex].Options != "")
		OptionString = OptionString $ Repl(Repl(GameConfig[GameIndex].Options,",","?")," ","");

	// Add Per-Map Game Options
	if(MapHistoryInfo.G != "")
		OptionString = OptionString $ "?" $ MapHistoryInfo.G;

	//if _RO_
	// Remove the .rom off of the map name, if it exists
	if ( Right(MapInfo.MapName, 4) == ".rom" )
		ReturnString = Left(MapInfo.MapName, Len(MapInfo.MapName) - 4);
	else
		ReturnString = MapInfo.MapName;

	MapsInRotation = Level.Game.MaplistHandler.GetCurrentMapRotation();
	for ( i = 0; i < MapsInRotation.Length; i++ )
	{
		if ( InStr(MapsInRotation[i], ReturnString) != -1 )
		{
			ReturnString = MapsInRotation[i];
			break;
		}
	}

	ReturnString = ReturnString $ "?Game=" $ GameConfig[GameIndex].GameClass;

	if( MutatorString=="" )
		MutatorString = "None"; // Don't allow previous mutator options to override this then.
	ReturnString = ReturnString $ "?Mutator=" $ MutatorString;

	if(OptionString != "")
		ReturnString = ReturnString $ "?" $ OptionString;

	return ReturnString;
}

function AddMap(string MapName, string Mutators, string GameOptions) // called from the MapListLoader
{
	local MapHistoryInfo MapInfo;
	local bool bUpdate;
	local int i;

	if( Right(MapName,4)~=".rom" )
		MapName = Left(MapName,Len(MapName)-4);

	if( MapName~="KFintro" )
		return; // Unplayable map.

	for(i=0; i < MapList.Length; i++)  // dont add duplicate map names
		if(MapName ~= MapList[i].MapName)
			return;

	RepArray.Length = MapCount + 1;
	Class'MVMapRepHistory'.Static.GetMapHistoryRep(MapName,RepArray[MapCount].Positive,RepArray[MapCount].Negative);

	MapInfo = History.GetMapHistory(MapName);

	MapList.Length = MapCount + 1;
	MapList[MapCount].MapName = MapName;
	MapList[MapCount].PlayCount = MapInfo.P;
	MapList[MapCount].Sequence = MapInfo.S;
	if(MapInfo.S <= RepeatLimit && MapInfo.S != 0)
		MapList[MapCount].bEnabled = false; // dont allow players to vote for this one
	else
		MapList[MapCount].bEnabled = true;
	MapCount++;

	if(Mutators != "" && Mutators != MapInfo.U)
	{
		MapInfo.U = Mutators;
		bUpdate = True;
	}

	if(GameOptions != "" && GameOptions != MapInfo.G)
	{
		MapInfo.G = GameOptions;
		bUpdate = True;
	}

	if(MapInfo.M == "") // if map not found in MapVoteHistory then add it
	{
		MapInfo.M = MapName;
		bUpdate = True;
	}

	if(bUpdate)
		History.AddMap(MapInfo);
}

// Using this function to save map reputation aswell.
function CloseAllVoteWindows()
{
	local int i,Pos,Neg;
	local KFVotingReplicationInfo R;

	for(i=0; i < MVRI.Length;i++)
	{
		R = KFVotingReplicationInfo(MVRI[i]);
		if( R!=none )
		{
			switch( R.MapRepVote )
			{
			case 1:
				++Pos;
				break;
			case 2:
				++Neg;
				break;
			}
			R.CloseWindow();
		}
	}
	if( Pos!=0 || Neg!=0 )
		Class'MVMapRepHistory'.Static.AddReputation(string(Outer.Name),Pos,Neg);
}

defaultproperties
{
}