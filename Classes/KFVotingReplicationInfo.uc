// ====================================================================
//  KFVotingReplicationInfo - Modification by Marco
// ====================================================================
class KFVotingReplicationInfo extends VotingReplicationInfo
	DependsOn(KFVotingHandler);

#exec obj load file="KFAnnounc.uax" package="KFMapVoteV3"

var array<string> RepArray,SortedArray; // Displayed rep string

var sound AnnounceSnds[13];
var byte MapRepVote;
var bool bClientHasInit;

replication
{
	reliable if( Role==ROLE_Authority )
		ReceiveMapInfoRep;
	reliable if( Role<ROLE_Authority )
		SendMapLike;
}

simulated final function InitClient()
{
	local PlayerController PC;

	bClientHasInit = true;
	PC = Level.GetLocalPlayerController();
	if( PC!=None )
		Class'MVLevelCleanup'.Static.AddVotingReplacement(PC);
}
simulated function Tick(float DeltaTime)
{
	if( !bClientHasInit )
		InitClient();
	Super.Tick(DeltaTime);
}
simulated function PlayCountDown(int Count)
{
	local byte Idx;

	if( PlayerOwner==None )
		return;
	switch( Count )
	{
	case 60:
		Idx = 12;
		break;
	case 30:
		Idx = 11;
		break;
	case 20:
		Idx = 10;
		break;
	default:
		Idx = Min(Count-1,9);
		break;
	}
	PlayerOwner.ClientPlaySound(AnnounceSnds[Idx],true,2.f,SLOT_Talk);
	PlayerOwner.ReceiveLocalizedMessage(Class'KFVoteTimeMessage',Idx);
}
simulated function OpenWindow()
{
	if( GetController().FindMenuByClass(Class'KFMapVotingPageX')==None ) // Only open when aren't already open.
	{
		GetController().OpenMenu(string(Class'KFMapVotingPageX'));
		GetController().OpenMenu(string(Class'MVLikePage'));
	}
}
function TickedReplication_MapList(int Index, bool bDedicated)
{
 	local VotingHandler.MapVoteMapList MapInfo;

	MapInfo = VH.GetMapList(Index);
	DebugLog("___Sending " $ Index $ " - " $ MapInfo.MapName);

	if( bDedicated )
	{
		ReceiveMapInfoRep(MapInfo,KFVotingHandler(VH).RepArray[Index]); // replicate one map each tick until all maps are replicated.
		bWaitingForReply = True;
	}
	else
	{
		MapList[MapList.Length] = MapInfo;
		InitRepStr(MapList.Length-1,KFVotingHandler(VH).RepArray[Index]);
	}
}

simulated function ReceiveMapInfoRep( VotingHandler.MapVoteMapList MapInfo, KFVotingHandler.FMapRepType Rep )
{
	MapList[MapList.Length] = MapInfo;
	InitRepStr(MapList.Length-1,Rep);
	ReplicationReply();
}

simulated final function InitRepStr( int i, KFVotingHandler.FMapRepType Rep )
{
	local float Rating;
	local byte R,G;

	RepArray.Length = i+1;
	SortedArray.Length = i+1;

	// Map not yet rated.
	if( Rep.Positive==0 && Rep.Negative==0 )
	{
		SortedArray[i] = "0000";

		// Map never played.
		if( MapList[i].PlayCount==0 )
			RepArray[i] = "**NEW**";
		else RepArray[i] = "N/A";
	}
	else
	{
		Rating = float(Rep.Positive) / float(Rep.Positive + Rep.Negative); // Scaled 0-1 (0 = negative, 1 = positive)

		if( Rating<0.5f )
		{
			R = 255;
			G = 510.f*Rating;
			if( G==0 || G==10 )
				++G;
		}
		else
		{
			R = 510.f*(1.f-Rating);
			G = 255;
			if( R==0 || R==10 )
				++R;
		}
		RepArray[i] = Chr(0x1B)$Chr(R)$Chr(G)$Chr(1)$(Rating*100.f)@"% ("$Rep.Positive$"/"$(Rep.Positive+Rep.Negative)@"likes)";
		SortedArray[i] = string(int(Rating*100.f));
		SortedArray[i] = Right("0000"$SortedArray[i],4);
	}
}

function SendMapLike( bool bLiked )
{
	if( bLiked )
		MapRepVote = 1;
	else MapRepVote = 2;
}

defaultproperties
{
	AnnounceSnds(0)=one
	AnnounceSnds(1)=two
	AnnounceSnds(2)=three
	AnnounceSnds(3)=four
	AnnounceSnds(4)=five
	AnnounceSnds(5)=six
	AnnounceSnds(6)=seven
	AnnounceSnds(7)=eight
	AnnounceSnds(8)=nine
	AnnounceSnds(9)=ten
	AnnounceSnds(10)=20_seconds
	AnnounceSnds(11)=30_seconds_remain
	AnnounceSnds(12)=1_minute_remains
}