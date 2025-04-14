// ====================================================================
//  Modified by Marco
// ====================================================================
class MVMultiColumnList extends MapVoteMultiColumnList;

var array<int> UnfilteredData;
var string OldFilter;
var eFontScale MyFontScale;  // soomebody is messing up with the self.FontScale


function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
	ScaleToResolution(MyController.ResX, MyController.ResY);
}

function ResolutionChanged(int ResX, int ResY)
{
	ScaleToResolution(ResX, ResY);
	Super.ResolutionChanged(ResX,ResY);
}

function ScaleToResolution(int ResX, int ResY)
{
	if (ResY < 1000) {
		MyFontScale = FNS_Small;
	}
	else {
		MyFontScale = FNS_Medium;
	}
}

function LoadList(VotingReplicationInfo LoadVRI, int GameTypeIndex)
{
	local int m,p,l;
	local array<string> PrefixList,SkipList;
	local string A,B,MP;

	VRI = LoadVRI;

	A = VRI.GameConfig[GameTypeIndex].Prefix;
	if( Divide(A,"|",A,B) )
		Split(B, ",", SkipList);
	Split(A, ",", PrefixList);

	for( m=0; m<VRI.MapList.Length; m++)
	{
		MP = VRI.MapList[m].MapName;
		for( p=0; p<PreFixList.Length; p++)
		{
			if( left(MP, len(PrefixList[p])) ~= PrefixList[p] )
			{
				for( l=(SkipList.Length-1); l>=0; --l )
					if( left(MP, len(SkipList[l])) ~= SkipList[l] )
						break;
				if( l!=-1 )
					continue;
				l = UnfilteredData.Length;
				UnfilteredData.Insert(l,1);
				UnfilteredData[l] = m;
				AddedItem();
				break;
			}
		} // p
	} // m
	MapVoteData = UnfilteredData;
	OldFilter = "";
	OnDrawItem  = DrawItem;
}

function ApplyFilter(string filter)
{
	local int i, j;

	if (len(filter) < 2 && OldFilter == "") {
		// require at least 2 letter to start filtering
		return;
	}

	filter = caps(filter);
	if (filter == OldFilter)
		return;

	// Since the developers were too retarded to use ItemCount from native code,
	// we cannot simply call Clear(), we need to call AddedItem/UpdatedItem/RemovedItem for each entry instead
	for (i = 0; i < UnfilteredData.Length; ++i) {
		if (filter == "" || InStr(caps(VRI.MapList[UnfilteredData[i]].MapName), filter) >= 0) {
			if (j < MapVoteData.length) {
				MapVoteData[j] = UnfilteredData[i];
				UpdatedItem(j);
			}
			else {
				MapVoteData[j] = UnfilteredData[i];
				AddedItem(j);
			}
			++j;
		}
	}
	for (i = MapVoteData.Length - 1; i >= j; --i) {
		MapVoteData.remove(i, 1);
		RemovedItem(i);
	}
	OldFilter = filter;
	Home();
	log("Map Filter: '"$filter$"'. Filtered map count: " $ MapVoteData.length);
	// Dump();
}

function Home()
{
	if (ItemCount < 1) return;

	SetIndex(0);
	if ( MyScrollBar != None )
		MyScrollBar.AlignThumb();
}

function float MyItemHeight(Canvas c)
{
	local float XL, YL;

	SelectedStyle.TextSize(C, MSAT_Blurry, "XXX,", XL, YL, MyFontScale);
	return YL + 2;
}

function DrawItem(Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
	local float CellLeft, CellWidth;
	local eMenuState MState;
	local GUIStyles DrawStyle;
	local string MapName;

	if (VRI == none)
		return;

	// Draw the selection border
	MapName = VRI.MapList[MapVoteData[SortData[i].SortItem]].MapName;
	if ( bSelected) {
		SelectedStyle.Draw(Canvas, MenuState, X, Y-1, W, H+2 );
		DrawStyle = SelectedStyle;
		MapName = "> " $ MapName;
		MState = MSAT_Focused;
	}
	else {
		DrawStyle = Style;
		MState = MenuState;
	}

	if (!VRI.MapList[MapVoteData[SortData[i].SortItem]].bEnabled) {
		MState = MSAT_Disabled;
	}

	GetCellLeftWidth(0, CellLeft, CellWidth);
	DrawStyle.DrawText(Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		MapName, MyFontScale);

	GetCellLeftWidth( 1, CellLeft, CellWidth );
	DrawStyle.DrawText(Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(VRI.MapList[MapVoteData[SortData[i].SortItem]].PlayCount), MyFontScale);

	GetCellLeftWidth( 2, CellLeft, CellWidth );
	DrawStyle.DrawText(Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(VRI.MapList[MapVoteData[SortData[i].SortItem]].Sequence), MyFontScale);

	GetCellLeftWidth( 3, CellLeft, CellWidth );
	DrawStyle.DrawText(Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		KFVotingReplicationInfo(VRI).RepArray[MapVoteData[SortData[i].SortItem]], MyFontScale);
}

function string GetSortString( int i )
{
	local string ColumnData[5];

	if (i >= MapVoteData.Length)
		return "";

	ColumnData[0] = Left(Caps(VRI.MapList[MapVoteData[i]].MapName),20);
	ColumnData[1] = Right("000000" $ VRI.MapList[MapVoteData[i]].PlayCount,6);
	ColumnData[2] = Right("000000" $ VRI.MapList[MapVoteData[i]].Sequence,6);
	ColumnData[3] = KFVotingReplicationInfo(VRI).SortedArray[MapVoteData[i]];

	return ColumnData[SortColumn] $ ColumnData[PrevSortColumn];
}


defaultproperties
{
	ColumnHeadings(3)="Rating"

	InitColumnPerc(0)=0.5
	InitColumnPerc(1)=0.15
	InitColumnPerc(2)=0.15
	InitColumnPerc(3)=0.2

	ColumnHeadingHints(3)="User rating for the maps."

	GetItemHeight=MyItemHeight
	MyFontScale=FNS_Medium
	FontScale=FNS_Medium
}
