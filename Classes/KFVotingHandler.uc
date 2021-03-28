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

function LoadMapList()
{
	MapListLoaderType = string(Class'KFXMapListLoader');
	Super.LoadMapList();
}

static event bool AcceptPlayInfoProperty(string PropertyName)
{
	if( PropertyName=="bMatchSetup" )
		return true;
	return Super.AcceptPlayInfoProperty(PropertyName);
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

// Fixed a bug in vote count updater.
function PlayerExit(Controller Exiting)
{
	local int i;

	// disable voting in single player mode
	if( Level.NetMode == NM_StandAlone )
		return;

	log("____PlayerExit", 'MapVoteDebug');

	if( bMapVote || bKickVote || bMatchSetup )
	{
		// find the MVRI belonging to the exiting player
		for(i=0;i < MVRI.Length;i++)
		{
			// remove players vote from vote count
			if( MVRI[i] != none && (MVRI[i].PlayerOwner == none || MVRI[i].PlayerOwner == Exiting) )
			{
				log("exiting player MVRI found " $ i,'MapVoteDebug');
				if( bMapVote && MVRI[i].MapVote > -1 && MVRI[i].GameVote > -1 )
					UpdateVoteCount(MVRI[i].MapVote, MVRI[i].GameVote, -MVRI[i].VoteCount);

				if( bKickVote )
				{
					// decrease votecount for player that the exiting player voted against
					if( MVRI[i].KickVote>-1 )
						UpdateKickVoteCount( MVRI[MVRI[i].KickVote].PlayerID, -1);

					// clear votes for exiting player
					UpdateKickVoteCount( MVRI[i].PlayerID, 0 );
				}

				log("___Destroying VRI...",'MapVoteDebug');
				MVRI[i].Destroy();
				MVRI[i] = none;
				if( bKickVote )
					TallyKickVotes();
				if( bMapVote )
					TallyVotes(false);
			}
		}
	}
}

function bool IsValidVote(int MapIndex, int GameIndex)
{
	local string A,B;
	local array<string> PL;
	local int i;
	
	A = GameConfig[GameIndex].Prefix;
	Divide(A,"|",A,B);
	Split(A, ",", PL);
	
	for( i=(PL.Length-1); i>=0; --i )
		if( Left(MapList[MapIndex].MapName, len(PL[i]))~=PL[i] )
			break;
	if( i==-1 )
		return false;
	
	if( B!="" )
	{
		Split(B, ",", PL);
		for( i=(PL.Length-1); i>=0; --i )
			if( Left(MapList[MapIndex].MapName, len(PL[i]))~=PL[i] )
				return false;
	}
	return true;
}
function GetDefaultMap(out int mapidx, out int gameidx)
{
	local int i,x,y,r,GCIdx;
	local array<string> PL,SPL;
	local string A,B;
	local bool bLoop;

	if(MapCount <= 0)
		return;

	// set the default gametype
	if(bDefaultToCurrentGameType)
		GCIdx = CurrentGameConfig;
	else
		GCIdx = DefaultGameConfig;

	// Parse Prefix list for default game type
	A = GameConfig[GCIdx].Prefix;
	if( Divide(A,"|",A,B) )
		Split(B, ",", SPL);
	Split(A, ",", PL);
	if( PL.Length==0 )
	{
		gameidx = GCIdx;
		mapidx = 0;
		return;
	}

	// choose a map at random, check if it is enabled and the prefix is in the prefix list
	r=0;
	bLoop = True;
	while( bLoop )
	{
		i = Rand(MapCount);
		if( MapList[i].bEnabled )
		{
			for( x=(PL.Length-1); x>=0; --x )
			{
				if( left(MapList[i].MapName, Len(PL[x])) ~= PL[x] )
					break;
			}
			if( x>=0 )
			{
				for( x=(SPL.Length-1); x>=0; --x )
				{
					if( left(MapList[i].MapName, len(SPL[x])) ~= SPL[x] )
						break;
				}
				if( x==-1 )
					bLoop = false;
			}
		}

		if(bLoop && r++ > 100)
		{
			// give up after 100 unsuccessful attempts.
			// find the first map that matches up to default gametype
            for(i=0;i<=MapCount;i++)
			{
				if( MapList[i].bEnabled )
				{
					for( x=(PL.Length-1); x>=0; --x )
					{
						if( left(MapList[i].MapName, Len(PL[x])) ~= PL[x] )
							break;
					}
					if( x>=0 )
					{
						for( x=(SPL.Length-1); x>=0; --x )
						{
							if( left(MapList[i].MapName, len(SPL[x])) ~= SPL[x] )
								break;
						}
						if( x==-1 )
							bLoop = false;
					}
				}
			}

			if(bLoop) // still didnt find any, then find the first enabled map and find its gameconfig
			{
				for( i=0; (i<=MapCount && bLoop); i++ )
				{
					if( MapList[i].bEnabled )
					{
						// find prefix in GameConfigs
						for(y=0; (y<GameConfig.Length && bLoop); y++)
						{
							// Parse Prefix list for game type
							PL.Length = 0;
							SPL.Length = 0;

							A = GameConfig[y].Prefix;
							if( Divide(A,"|",A,B) )
								Split(B, ",", SPL);
							Split(A, ",", PL);

							if(PL.Length > 0)
							{
								for( x=(PL.Length-1); x>=0; --x )
								{
									if( left(MapList[i].MapName, Len(PL[x])) ~= PL[x] )
										break;
								}
								if( x>=0 )
								{
									for( x=(SPL.Length-1); x>=0; --x )
									{
										if( left(MapList[i].MapName, len(SPL[x])) ~= SPL[x] )
											break;
									}
									if( x==-1 )
									{
										GCIdx = y;
										bLoop = false;
									}
								}
							}
						}
					}
				}
			}
			break;
		}
	}
	gameidx = GCIdx;
	mapidx = i;
	log("Default Map Choosen = " $ MapList[mapidx].MapName $ "(" $ GameConfig[gameidx].Acronym $ ")",'MapVoteDebug');
}

function string GetConfigArrayData(string ConfigArrayName, int RowIndex, int ColumnIndex)
{
	local string B;

	if( ConfigArrayName~="GAMECONFIG" )
	{
		if( RowIndex > GameConfig.Length-1 || ColumnIndex > 5 )
			return "";

		switch( ColumnIndex )
		{
			case 0:
				return "GAMETYPE;50;" $ GameConfig[RowIndex].GameClass;
			case 1:
				if( !Divide(GameConfig[RowIndex].Prefix,"|",ConfigArrayName,B) )
					ConfigArrayName = GameConfig[RowIndex].Prefix;
				return "TEXT;50;" $ ConfigArrayName;
			case 2:
				if( !Divide(GameConfig[RowIndex].Prefix,"|",ConfigArrayName,B) )
					B = "";
				return "TEXT;50;" $ B;
			case 3:
				return "TEXT;20;" $ GameConfig[RowIndex].Acronym;
			case 4:
				return "TEXT;50;" $ GameConfig[RowIndex].GameName;
			case 5:
				return "MUTATORS;255;" $ GameConfig[RowIndex].Mutators;
			case 6:
				return "TEXT;255;" $ GameConfig[RowIndex].Options;
		}
	}
	return "";
}
function string GetConfigArrayColumnTitle(string ConfigArrayName, int ColumnIndex)
{
	if( ConfigArrayName~="GAMECONFIG" && ColumnIndex<=6 )
	{
		if( ColumnIndex==2 )
			return "Exl.Prefixes";
		else if( ColumnIndex>2 )
			--ColumnIndex;
   		return lmsgGameConfigColumnTitle[ColumnIndex];
	}
	return "";
}
function int AddConfigArrayItem(string ConfigArrayName)
{
	if( ConfigArrayName~="GAMECONFIG" )
	{
		GameConfig.Insert(GameConfig.Length,1);
		GameConfig[GameConfig.Length-1].GameClass = "KFMod.KFGameType";
		GameConfig[GameConfig.Length-1].Prefix = "KF-";
		GameConfig[GameConfig.Length-1].Acronym = "KF";
		GameConfig[GameConfig.Length-1].GameName = "New KillingFloor";
		GameConfig[GameConfig.Length-1].Mutators = "";
		GameConfig[GameConfig.Length-1].Options = "";
		return GameConfig.Length-1;
	}
	return 0;
}
function UpdateConfigArrayItem(string ConfigArrayName, int RowIndex, int ColumnIndex, string NewValue)
{
	local string B;

	if( ConfigArrayName~="GAMECONFIG" && RowIndex>=0 && RowIndex<GameConfig.Length && ColumnIndex<=6 )
	{
		switch( ColumnIndex )
		{
			case 0:
				GameConfig[RowIndex].GameClass = NewValue;
				break;
			case 1:
				if( !Divide(GameConfig[RowIndex].Prefix,"|",ConfigArrayName,B) )
					GameConfig[RowIndex].Prefix = NewValue;
				else GameConfig[RowIndex].Prefix = NewValue$"|"$B;
				break;
			case 2:
				if( !Divide(GameConfig[RowIndex].Prefix,"|",ConfigArrayName,B) )
				{
					if( NewValue!="" )
						GameConfig[RowIndex].Prefix $= "|"$NewValue;
				}
				else if( NewValue=="" )
					GameConfig[RowIndex].Prefix = ConfigArrayName;
				else GameConfig[RowIndex].Prefix = ConfigArrayName$"|"$NewValue;
				break;
			case 3:
				GameConfig[RowIndex].Acronym = NewValue;
				break;
			case 4:
				GameConfig[RowIndex].GameName = NewValue;
				break;
			case 5:
				GameConfig[RowIndex].Mutators = NewValue;
				break;
			case 6:
				GameConfig[RowIndex].Options = NewValue;
				break;
		}
	}
}

defaultproperties
{
	bMatchSetup=true
}