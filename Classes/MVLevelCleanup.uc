Class MVLevelCleanup extends Interaction;

function NotifyLevelChange()
{
	local int i;

	// Reset the voting menu back.
	GUIController(ViewportOwner.GUIController).MapVotingMenu = "KFGUI.KFMapVotingPage";

	// Make sure GUI controller leaves no menus referenced.
	GUIController(ViewportOwner.GUIController).ResetFocus();
	GUIController(ViewportOwner.GUIController).FocusedControl = None;

	for( i=(ViewportOwner.LocalInteractions.Length-1); i>=0; --i )
		if( ViewportOwner.LocalInteractions[i]==Self )
			ViewportOwner.LocalInteractions.Remove(i,1);
}

static final function AddVotingReplacement( PlayerController PC )
{
	local int i;
	local MVLevelCleanup C;

	for( i=(PC.Player.LocalInteractions.Length-1); i>=0; --i )
		if( PC.Player.LocalInteractions[i].Class==Default.Class )
			return;
	C = new(None) Class'MVLevelCleanup';
	C.ViewportOwner = PC.Player;
	C.Master = PC.Player.InteractionMaster;
	i = PC.Player.LocalInteractions.Length;
	PC.Player.LocalInteractions.Length = i+1;
	PC.Player.LocalInteractions[i] = C;
	C.Initialize();
	GUIController(PC.Player.GUIController).MapVotingMenu = string(Class'KFMapVotingPageX');
}
