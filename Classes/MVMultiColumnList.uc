// ====================================================================
//  Modified by Marco
// ====================================================================
class MVMultiColumnList extends MapVoteMultiColumnList;

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
				l = MapVoteData.Length;
				MapVoteData.Insert(l,1);
				MapVoteData[l] = m;
				AddedItem();
				break;
			}
		} // p
	} // m
	OnDrawItem  = DrawItem;
}
//------------------------------------------------------------------------------------------------
function DrawItem(Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
	local float CellLeft, CellWidth;
	local eMenuState MState;
	local GUIStyles DrawStyle;

	if( VRI == none )
		return;

	// Draw the selection border
	if( bSelected )
	{
		SelectedStyle.Draw(Canvas,MenuState, X, Y-2, W, H+2 );
		DrawStyle = SelectedStyle;
	}
	else DrawStyle = Style;

	if( !VRI.MapList[MapVoteData[SortData[i].SortItem]].bEnabled )
		MState = MSAT_Disabled;
	else MState = MenuState;

	GetCellLeftWidth( 0, CellLeft, CellWidth );
	DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		VRI.MapList[MapVoteData[SortData[i].SortItem]].MapName, FontScale );

	GetCellLeftWidth( 1, CellLeft, CellWidth );
	DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(VRI.MapList[MapVoteData[SortData[i].SortItem]].PlayCount), FontScale );

	GetCellLeftWidth( 2, CellLeft, CellWidth );
	DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(VRI.MapList[MapVoteData[SortData[i].SortItem]].Sequence), FontScale );

	GetCellLeftWidth( 3, CellLeft, CellWidth );
	DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		KFVotingReplicationInfo(VRI).RepArray[MapVoteData[SortData[i].SortItem]], FontScale );
}
//------------------------------------------------------------------------------------------------
function string GetSortString( int i )
{
	local string ColumnData[5];

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
}

