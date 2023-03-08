// Created by Marco
class MVLikePage extends LargeWindow;

var automated GUILabel l_Text;
var automated GUIButton b_Like,b_Dislike;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
	b_Like.Caption = MakeColorCode(Class'Canvas'.Static.MakeColor(64,255,64))$b_Like.Caption;
	b_Dislike.Caption = MakeColorCode(Class'Canvas'.Static.MakeColor(255,64,64))$b_Dislike.Caption;
}

function bool LikeClick(GUIComponent Sender)
{
	KFVotingReplicationInfo(PlayerOwner().VoteReplicationInfo).SendMapLike(Sender==b_Like);
	Controller.CloseMenu();
	return false;
}

defaultproperties
{
	Begin Object Class=GUILabel Name=LikeInfo
		WinLeft=0.1
		WinTop=0.2
		WinWidth=0.8
		WinHeight=0.4
		Caption="Did you like this map?"
		TextColor=(R=255,G=255,B=64,A=255)
		TextAlign=TXTA_Center
	End Object
	l_Text=LikeInfo

	Begin Object Class=GUIButton Name=LikeButton
		WinLeft=0.38
		WinTop=0.53
		WinWidth=0.11
		WinHeight=0.075
		Caption="Like"
		OnClick=LikeClick
	End Object
	b_Like=LikeButton

	Begin Object Class=GUIButton Name=DislikeButton
		WinLeft=0.51
		WinTop=0.53
		WinWidth=0.11
		WinHeight=0.075
		Caption="Dislike"
		OnClick=LikeClick
	End Object
	b_Dislike=DislikeButton

	bAcceptsInput=false
	bPauseIfPossible=false

	WinLeft=0.3
	WinTop=0.35
	WinWidth=0.4
	WinHeight=0.3

	bRenderWorld=true
	bRequire640x480=false
	bAllowedAsLast=false
	bMoveAllowed=False
	WindowName="Map review"
}