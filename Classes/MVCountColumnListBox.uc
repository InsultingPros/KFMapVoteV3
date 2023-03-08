// ====================================================================
//  Modified by Marco
// ====================================================================
class MVCountColumnListBox extends MapVoteCountMultiColumnListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(Class'MVCountColumnList');
	Super.InitComponent(MyController, MyOwner);
	if( PlayerOwner().PlayerReplicationInfo.bAdmin )
		ContextMenu.AddItem("Admin Force Map");
}

function InternalOnClick(GUIContextMenu Sender, int Index)
{
	if (Sender != None)
	{
		if ( NotifyContextSelect(Sender, Index) )
			return;

		switch (Index)
		{
		case 0:
			if( MapVotingPage(MenuOwner) != none )
				MapVotingPage(MenuOwner).SendVote(self);
			break;

		case 1:
			Controller.OpenMenu( string(Class'MVMapInfoPage'), MapVoteCountMultiColumnList(List).GetSelectedMapName() );
			break;
		case 2:
			if( KFMapVotingPageX(MenuOwner) != none )
				KFMapVotingPageX(MenuOwner).SendAdminSwitch(self);
			break;
		}
	}
}

defaultproperties
{
}