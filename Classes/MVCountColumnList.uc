// ====================================================================
//  Modified by Marco
// ====================================================================
class MVCountColumnList extends MapVoteCountMultiColumnList;

//------------------------------------------------------------------------------------------------
function DrawItem(Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
	local float CellLeft, CellWidth;
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

	GetCellLeftWidth( 0, CellLeft, CellWidth );
	DrawStyle.DrawText( Canvas, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
		VRI.GameConfig[VRI.MapVoteCount[SortData[i].SortItem].GameConfigIndex].GameName, FontScale );

	GetCellLeftWidth( 1, CellLeft, CellWidth );
	DrawStyle.DrawText( Canvas, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
		VRI.MapList[VRI.MapVoteCount[SortData[i].SortItem].MapIndex].MapName, FontScale );

	GetCellLeftWidth( 2, CellLeft, CellWidth );
	DrawStyle.DrawText( Canvas, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(VRI.MapVoteCount[SortData[i].SortItem].VoteCount), FontScale );

	GetCellLeftWidth( 3, CellLeft, CellWidth );
	DrawStyle.DrawText( Canvas, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
		KFVotingReplicationInfo(VRI).RepArray[VRI.MapVoteCount[SortData[i].SortItem].MapIndex], FontScale );
}
//------------------------------------------------------------------------------------------------
function string GetSortString( int i )
{
	local string ColumnData[5];

	ColumnData[0] = left(Caps(VRI.GameConfig[VRI.MapVoteCount[i].GameConfigIndex].GameName),15);
	ColumnData[1] = left(Caps(VRI.MapList[VRI.MapVoteCount[i].MapIndex].MapName),20);
	ColumnData[2] = right("0000" $ VRI.MapVoteCount[i].VoteCount,4);
	ColumnData[3] = KFVotingReplicationInfo(VRI).RepArray[VRI.MapVoteCount[i].MapIndex];
	if( Left(ColumnData[3],1)==Chr(0x1B) )
		ColumnData[3] = Mid(ColumnData[3],4); // Remove color code from sorting.

	return ColumnData[SortColumn] $ ColumnData[PrevSortColumn];
}

defaultproperties
{
	ColumnHeadings(3)="Rating"
	InitColumnPerc(0)=0.3
	InitColumnPerc(1)=0.3
	InitColumnPerc(2)=0.2
	InitColumnPerc(3)=0.2
	ColumnHeadingHints(3)="User rating of the map."
}