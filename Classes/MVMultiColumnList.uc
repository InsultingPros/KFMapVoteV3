// ====================================================================
//  Modified by Marco
// ====================================================================
class MVMultiColumnList extends MapVoteMultiColumnList;

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

	ColumnData[0] = left(Caps(VRI.MapList[MapVoteData[i]].MapName),20);
	ColumnData[1] = right("000000" $ VRI.MapList[MapVoteData[i]].PlayCount,6);
	ColumnData[2] = right("000000" $ VRI.MapList[MapVoteData[i]].Sequence,6);
	ColumnData[3] = KFVotingReplicationInfo(VRI).RepArray[MapVoteData[i]];
	if( Left(ColumnData[3],1)==Chr(0x1B) )
		ColumnData[3] = Mid(ColumnData[3],4); // Remove color code from sorting.

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

