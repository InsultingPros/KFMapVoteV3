//-----------------------------------------------------------
// KFMapVotingPageX - Modification by Marco
//-----------------------------------------------------------
class KFMapVotingPageX extends ROMapVotingPage;

// Also allow admins force mapswitch.
final function SendAdminSwitch(GUIComponent Sender)
{
	local int MapIndex,GameConfigIndex;

	if( Sender == lb_VoteCountListBox.List )
	{
		MapIndex = MapVoteCountMultiColumnList(lb_VoteCountListBox.List).GetSelectedMapIndex();
		if( MapIndex>=0 )
			GameConfigIndex = MapVoteCountMultiColumnList(lb_VoteCountListBox.List).GetSelectedGameConfigIndex();
	}
	else
	{
		MapIndex = MapVoteMultiColumnList(lb_MapListBox.List).GetSelectedMapIndex();
		if( MapIndex>=0 )
			GameConfigIndex = int(co_GameType.GetExtra());
	}
	if( MapIndex>=0 )
		MVRI.SendMapVote(MapIndex,-(GameConfigIndex+1)); // Send with negative game index to indicate admin switch.
}

// Allow admins vote like all other players.
function SendVote(GUIComponent Sender)
{
	local int MapIndex,GameConfigIndex;

	if( Sender == lb_VoteCountListBox.List )
	{
		MapIndex = MapVoteCountMultiColumnList(lb_VoteCountListBox.List).GetSelectedMapIndex();
		if( MapIndex>=0 )
			GameConfigIndex = MapVoteCountMultiColumnList(lb_VoteCountListBox.List).GetSelectedGameConfigIndex();
	}
	else
	{
		MapIndex = MapVoteMultiColumnList(lb_MapListBox.List).GetSelectedMapIndex();
		if( MapIndex>=0 )
			GameConfigIndex = int(co_GameType.GetExtra());
	}
	if( MapIndex>=0 )
	{
		if( MVRI.MapList[MapIndex].bEnabled )
			MVRI.SendMapVote(MapIndex,GameConfigIndex);
		else PlayerOwner().ClientMessage(lmsgMapDisabled);
	}
}

DefaultProperties
{
	Begin Object Class=MVCountColumnListBox Name=VoteCountListBox
		WinWidth=0.96
		WinHeight=0.223770
		WinLeft=0.02
		WinTop=0.052930
		bVisibleWhenEmpty=true
		bScaleToParent=True
		bBoundToParent=True
		FontScale=FNS_Small
		HeaderColumnPerc(0)=0.3
		HeaderColumnPerc(1)=0.3
		HeaderColumnPerc(2)=0.2
		HeaderColumnPerc(3)=0.2
	End Object
	lb_VoteCountListBox=VoteCountListBox

	Begin Object Class=MVMultiColumnListBox Name=MapListBox
		WinWidth=0.96
		WinHeight=0.293104
		WinLeft=0.02
		WinTop=0.371020
		bVisibleWhenEmpty=true
		StyleName="ServerBrowserGrid"
		bScaleToParent=True
		bBoundToParent=True
		FontScale=FNS_Small
		HeaderColumnPerc(0)=0.5
		HeaderColumnPerc(1)=0.15
		HeaderColumnPerc(2)=0.15
		HeaderColumnPerc(3)=0.2
	End Object
	lb_MapListBox=MapListBox

	Begin Object class=moComboBox Name=GameTypeCombo
		WinWidth=0.757809
		WinHeight=0.037500
		WinLeft=0.199219
		WinTop=0.334309
		Caption="Select Game Type:"
		CaptionWidth=0.35
		bScaleToParent=True
	End Object
	co_GameType=GameTypeCombo
}