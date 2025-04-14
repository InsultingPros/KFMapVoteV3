//-----------------------------------------------------------
// KFMapVotingPageX - Modification by Marco
//-----------------------------------------------------------
class KFMapVotingPageX extends ROMapVotingPage;

var automated moEditBox SearchEdit;
var localized string strHelp;

function InternalOnOpen()
{
	super.InternalOnOpen();

	if (!bHasFocus) {
		// fixes PreDraw errors
		lb_MapListBox.SetVisibility(false);
		lb_VoteCountListBox.SetVisibility(false);
		return;
	}

	lb_MapListBox.SetVisibility(true);
	lb_VoteCountListBox.SetVisibility(true);


	if (f_Chat.ed_Chat.GetText() != "") {
		f_Chat.ed_Chat.SetFocus(none);
		SetFocus(f_Chat.ed_Chat);
		// move the cursor to the end of the text
		f_Chat.ed_Chat.MyEditBox.CaretPos = len(f_Chat.ed_Chat.GetText());
		f_Chat.ed_Chat.MyEditBox.bAllSelected = false;
	}
	else {
		Controller.PlayInterfaceSound(CS_Edit);
		SearchEdit.SetFocus(none);
	}
	f_Chat.ReceiveChat(strHelp);
}

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

function GameTypeChanged(GUIComponent Sender)
{
	super.GameTypeChanged(Sender);
	SearchEdit.SetText("");
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
	local Interactions.EInputKey iKey;
	if (State != 3)
		return false;

	iKey = EInputKey(Key);
	if (iKey >= IK_F1 && iKey < IK_F12) {
		// F keys
		switch (iKey) {
			case IK_F1:
				Controller.PlayInterfaceSound(CS_Edit);
				f_Chat.ReceiveChat(strHelp);
				return true;
			case IK_F2:
				Controller.PlayInterfaceSound(CS_Edit);
				f_Chat.ed_Chat.SetFocus(none);
				SetFocus(f_Chat.ed_Chat);
				return true;
			case IK_F3:
				Controller.PlayInterfaceSound(CS_Edit);
				SearchEdit.SetFocus(none);
				SetFocus(SearchEdit);
				return true;
			case IK_F4:
				Controller.PlayInterfaceSound(CS_Edit);
				co_GameType.SetFocus(none);
				SetFocus(co_GameType);
				co_GameType.MyComboBox.ShowListBox(co_GameType.MyComboBox);
				return true;
		}
	}
	return false;
}

function bool OnGameTypeKey(out byte Key, out byte State, float delta)
{
	local Interactions.EInputKey iKey;

	if (State != 3)
		return false;

	iKey = EInputKey(Key);
	if (iKey == IK_Enter) {
		Controller.PlayInterfaceSound(CS_Edit);
		co_GameType.MyComboBox.ShowListBox(co_GameType.MyComboBox);
		if (!co_GameType.MyComboBox.MyListBox.bVisible) {
			SearchEdit.SetFocus(none);
			SetFocus(SearchEdit);
		}
		return true;
	}
	return false;
}


function bool OnSearchKey(out byte Key, out byte st, float delta)
{
	// PlayerOwner().ClientMessage("OnSearchKeyType Key="$Key @ "State="$State);
	if (st != 3)
		return false;  // not a key press

	// redirect Fn keys to BuyMenuTab
	if (Key >= 0x70 && Key < 0x7C) {
		return InternalOnKeyEvent(Key, st, delta);
	}

	switch (Key) {
		case 0x08: // IK_Backspace
			if (Controller.CtrlPressed) {
				SearchEdit.SetText("");
				Key = 0;
				st = 0;
				return true;
			}
			break;
		case 0x0D: // IK_Enter
			SendVote(lb_MapListBox.List);
			return true;
		case 0x26: // IK_Up
			lb_MapListBox.List.Up();
			return true;
		case 0x28: // IK_Down
			lb_MapListBox.List.Down();
			return true;
	}
	return SearchEdit.MyEditBox.InternalOnKeyEvent(Key, st, delta);
}

function bool OnSearchKeyType(out byte Key, optional string Unicode)
{
    // PlayerOwner().ClientMessage("OnSearchKeyType Key="$Key @ "Unicode="$Unicode);
    if (Key == 127) {
        return true;  // control characters
    }
    if (Unicode == "`" || Unicode == "~") {
        // ignore console key input
        return true;
    }
    return SearchEdit.MyEditBox.InternalOnKeyType(Key, Unicode);
}

function OnSearchChange(GUIComponent Sender)
{
    local string s;

    s = SearchEdit.GetText();
	MVMultiColumnList(lb_MapListBox.List).ApplyFilter(s);
}

function bool AlignBK(Canvas C)
{

	if (lb_VoteCountListbox.MyList != none) {
		i_MapCountListBackground.WinWidth  = lb_VoteCountListbox.MyList.ActualWidth();
		i_MapCountListBackground.WinHeight = lb_VoteCountListbox.MyList.ActualHeight();
		i_MapCountListBackground.WinLeft   = lb_VoteCountListbox.MyList.ActualLeft();
		i_MapCountListBackground.WinTop    = lb_VoteCountListbox.MyList.ActualTop();
	}

	if (lb_MapListBox.MyList != none) {
		i_MapListBackground.WinWidth  	= lb_MapListBox.MyList.ActualWidth();
		i_MapListBackground.WinHeight 	= lb_MapListBox.MyList.ActualHeight();
		i_MapListBackground.WinLeft  	= lb_MapListBox.MyList.ActualLeft();
		i_MapListBackground.WinTop	 	= lb_MapListBox.MyList.ActualTop();
	}

	return false;
}

DefaultProperties
{
	OnKeyEvent=InternalOnKeyEvent
	strHelp=". TeamSay|/ Console command|+ Like the current map|- Dislike the current map| "

	Begin Object Class=MVCountColumnListBox Name=VoteCountListBox
		TabOrder=0
		WinLeft=0.02
		WinWidth=0.96
		WinTop=0.05
		WinHeight=0.22
		bVisibleWhenEmpty=true
		bScaleToParent=True
		bBoundToParent=True
		FontScale=Font_Medium
		HeaderColumnPerc(0)=0.3
		HeaderColumnPerc(1)=0.3
		HeaderColumnPerc(2)=0.2
		HeaderColumnPerc(3)=0.2
	End Object
	lb_VoteCountListBox=VoteCountListBox

	Begin Object class=moComboBox Name=GameTypeCombo
		TabOrder=1
		WinLeft=0.20
		WinWidth=0.60
		WinTop=0.275
		WinHeight=0.0375
		Caption="F4 Select Game Type:"
		CaptionWidth=0.35
		bScaleToParent=True
		bBoundToParent=True
		bReadOnly=True
		OnKeyEvent=OnGameTypeKey
	End Object
	co_GameType=GameTypeCombo

	Begin Object Class=moEditBox Name=SearchEditbox
		TabOrder=2
		WinLeft=0.20
		WinWidth=0.60
		WinTop=0.315
		WinHeight=0.0375
		Caption="F3 Map Search:"
		CaptionWidth=0.35
		bScaleToParent=True
		bBoundToParent=True
		OnChange=OnSearchChange
		OnKeyEvent=OnSearchKey
		OnKeyType=OnSearchKeyType
	End Object
	SearchEdit=SearchEditbox

	Begin Object Class=MVMultiColumnListBox Name=MapListBox
		TabOrder=3
		WinLeft=0.02
		WinWidth=0.96
		WinTop=0.37
		WinHeight=0.33
		bVisibleWhenEmpty=true
		StyleName="ServerBrowserGrid"
		bScaleToParent=True
		bBoundToParent=True
		FontScale=Font_Medium
		HeaderColumnPerc(0)=0.5
		HeaderColumnPerc(1)=0.15
		HeaderColumnPerc(2)=0.15
		HeaderColumnPerc(3)=0.2
	End Object
	lb_MapListBox=MapListBox

	Begin Object Class=GUIImage Name=MapListBackground
		Image=Texture'KF_InterfaceArt_tex.Menu.Thin_border_SlightTransparent'
		ImageStyle=ISTY_Stretched
		OnDraw=AlignBK
	End Object
	i_MapListBackground=MapListBackground

	Begin Object Class=KFMapVoteFooterX Name=ChatFooter
		WinTop=0.705
		WinLeft=0.02
		WinWidth=0.96
		WinHeight=0.275
		TabOrder=10
	End Object
	f_Chat=ChatFooter
}