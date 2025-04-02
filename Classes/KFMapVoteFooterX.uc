class KFMapVoteFooterX extends MapVoteFooter;

var localized string strLiked, stdDisliked;

// C&P to fix trimming the first typed character
function InitComponent(GUIController InController, GUIComponent InOwner)
{
	local string str;
	local ExtendedConsole C;

	Super(GUIFooter).InitComponent(InController, InOwner);

	lb_Chat.MyScrollText.SetContent("");
	lb_Chat.MyScrollText.FontScale = FNS_Small;

	C = ExtendedConsole(Controller.ViewportOwner.Console);
	if (C != None) {
		C.OnChatMessage = ReceiveChat;
		if (C.bTyping) {
			str = C.TypedStr;
			C.TypingClose();
			if ( Left(str,4) ~= "say " ) {
				str = Mid(str, 4);
			}
			else if ( Left(str,8) ~= "teamsay " ) {
				str = "." $ Mid(str, 8);
			}
			ed_Chat.SetText(str);
		}
	}
	OnDraw=MyOnDraw;
}

function bool MyOnDraw(canvas C)
{
	local float l,t,w,xl,yl;
	// Reposition everything

	t = sb_Background.ActualTop() + sb_Background.ActualHeight() + 5;
	l = sb_Background.ActualLeft() + sb_Background.ActualWidth() - sb_Background.ImageOffset[3];

	b_Close.Style.TextSize(C,MSAT_Blurry,b_Close.Caption, XL,YL, b_Close.FontScale);
	w = XL;
	b_Submit.Style.TextSize(C,MSAT_Blurry,b_Close.Caption, XL,YL, b_Submit.FontScale);
	if (XL>w)
		w = XL;
	b_Accept.Style.TextSize(C,MSAT_Blurry,b_Close.Caption, XL,YL, b_Accept.FontScale);
	if (XL>w)
		w = XL;

	w = w*3;
	w = ActualWidth(w);

	l -= w;
	b_Close.WinWidth = w;
	b_Close.WinTop = t;
	b_Close.WinLeft = l;

	l -= w;
	b_Submit.WinWidth = w;
	b_Submit.WinTop = t;
	b_Submit.WinLeft = l;

	l -= w;
	b_Accept.WinWidth = w;
	b_Accept.WinTop = t;
	b_Accept.WinLeft = l;


	ed_Chat.WinLeft   = sb_Background.ActualLeft() + sb_Background.ImageOffset[0];
	ed_Chat.WinWidth  = L - ed_Chat.WinLeft;
	ed_Chat.WinHeight = 25;
	ed_Chat.WinTop    = t;

 	return false;
}

function ReceiveChat(string Msg)
{
	lb_Chat.AddText(Msg);
	lb_Chat.MyScrollText.End();
}

delegate bool OnSendChat( string Text )
{
	local string c;

	if (Text == "")
		return false;


	if (RecallQueue.Length == 0 || RecallQueue[RecallQueue.Length - 1] != Text) {
		RecallIdx = RecallQueue.Length;
		RecallQueue[RecallIdx] = Text;
	}

	c = Left(Text, 1);

	if (Text == "+") {
		if (KFVotingReplicationInfo(PlayerOwner().VoteReplicationInfo).SetMapLike(true)) {
			PlayerOwner().ClientMessage(strLiked);
		}
	}
	else if (Text == "-") {
		if (KFVotingReplicationInfo(PlayerOwner().VoteReplicationInfo).SetMapLike(false)) {
			PlayerOwner().ClientMessage(stdDisliked);
		}
	}
	else if (c == ".") {
		PlayerOwner().TeamSay(Mid(Text, 1));
	}
	else if (c == "/") {
		PlayerOwner().ConsoleCommand(Mid(Text, 1));
	}
	else if (c ~= "c" && Left(Text, 4) ~= "cmd ") {
		// legacy cmd
		PlayerOwner().ConsoleCommand(Mid(Text, 4));
	}
	else {
		PlayerOwner().Say(Text);
	}
	return true;
}

defaultproperties
{
	strLiked="Liked the current map"
	stdDisliked="Disliked the current map"

	Begin Object Class=AltSectionBackground Name=MapvoteFooterBackground
		bFillClient=True
		bNoCaption=True
		bAltCaption=False
		LeftPadding=0.010000
		RightPadding=0.010000
		WinHeight=0.81
		bBoundToParent=True
		bScaleToParent=True
		OnPreDraw=MapvoteFooterBackground.InternalPreDraw
	End Object
	sb_Background=MapvoteFooterBackground

	Begin Object Class=GUIScrollTextBox Name=ChatScrollBox
		bNoTeletype=True
		CharDelay=0.002500
		EOLDelay=0.000000
		bVisibleWhenEmpty=True
		OnCreateComponent=ChatScrollBox.InternalOnCreateComponent
		StyleName="ServerBrowserGrid"
		WinLeft=0.02
		WinWidth=0.96
		WinTop=0.02
		WinHeight=0.76
		TabOrder=2
		bBoundToParent=True
		bScaleToParent=True
		bNeverFocus=True
	End Object
	lb_Chat=ChatScrollBox

	Begin Object Class=moEditBox Name=ChatEditbox
		CaptionWidth=0.150000
		Caption="F2 Say"
		OnCreateComponent=ChatEditbox.InternalOnCreateComponent
		WinTop=0.868598
		WinLeft=0.007235
		WinWidth=0.700243
		WinHeight=0.106609
		TabOrder=0
		OnKeyEvent=MapVoteFooter.InternalOnKeyEvent
	End Object
	ed_Chat=ChatEditbox
}