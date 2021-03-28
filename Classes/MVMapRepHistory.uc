//====================================================================
// Modification by Marco.
//====================================================================
class MVMapRepHistory extends Object
	  Config(KFMapVoteHistory);

struct RepHistory
{
	var config string M;
	var config int P,N;
};
var config array<RepHistory> H;  // array used to store map data

//------------------------------------------------------------------------------------------------
static final function int AddMap( string MapName )
{
	local int x;

	MapName = Caps(MapName);

	if( Default.H.Length==0 )  // brand new list
	{
		Default.H.Length = 1;
		Default.H[0].M = MapName;
		return 0;
	}

	// search list for map
	for(x=0; x<Default.H.Length; x++)
	{
		if( MapName==Default.H[x].M )  // found map
			return x;

		if( Default.H[x].M>MapName )  // MapName is not in array and should be inserted here
		{
			Default.H.Insert(x,1);
			Default.H[x].M = MapName;
			return x;
		}
	}

	// didnt find insertion point so add at end
	Default.H.Length = x+1;
	Default.H[x].M = MapName; 
	return x;
}
//------------------------------------------------------------------------------------------------
static final function GetMapHistoryRep( string MapName, out int Positive, out int Negative )
{
	local int i;

	i = FindIndex(MapName);
	if( i>=0 )
	{
		Positive = Default.H[i].P;
		Negative = Default.H[i].N;
	}
	else
	{
		Positive = 0;
		Negative = 0;
	}
}

static final function AddReputation( string MapName, int Positive, int Negative )
{
	local int i;

	i = FindIndex(MapName);
	if( i==-1 )
		i = AddMap(MapName);

	Default.H[i].P+=Positive;
	Default.H[i].N+=Negative;
	StaticSaveConfig();
}
//------------------------------------------------------------------------------------------------
static final function int FindIndex(string MapName)
{
	local int a,b,i;

	if( Default.H.Length==0 )
		return -1;

	a = 0;
	b = Default.H.Length-1;
	MapName = Caps(MapName);

	while(true)
	{
		if( a==b )
			i = a;
		else i = ((b-a)/2)+a;

		if( Default.H[i].M==MapName )
			return i;

		if( a==b )
			return -1;

		// check mid-way
		if( Default.H[i].M>MapName )
			b = i; // too high
		else if( a==i )
			a = b;
		else a = i;    // too low
	}
}

defaultproperties
{
}