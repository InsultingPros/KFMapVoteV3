//====================================================================
// Modified by Marco
// ====================================================================
class MVMapInfoPage extends MapInfoPage;

function ReadMapInfo(string MapName)
{
	local string mDesc;
	local int Index;
	local Material Screenie;
	local LevelSummary LS;

	if(MapName == "")
		return;

	if (!Controller.bCurMenuInitialized)
		return;

	MapName = StripMapName(MapName);

	Index = FindCacheRecordIndex(MapName);

	if( Index==-1 )
	{
		LS = LevelSummary(DynamicLoadObject(MapName$".LevelSummary",Class'LevelSummary'));

		if( LS==None )
		{
			sb_Main.Caption = MapName;
			l_NoPreview.SetVisibility(true);
			i_MapImage.SetVisibility(false);
			lb_MapDesc.SetContent("Map not found.");
			l_MapAuthor.Caption = "";
			return;
		}
		sb_Main.Caption = LS.Title;
		Screenie = LS.Screenshot;
		l_MapPlayers.Caption = LS.IdealPlayerCountMin@"-"@LS.IdealPlayerCountMax;
		mDesc = LS.Description;
		l_MapAuthor.Caption = AuthorText$":"@LS.Author;
	}
	else
	{
		if (Maps[Index].FriendlyName != "")
			sb_Main.Caption = Maps[Index].FriendlyName;
		else sb_Main.Caption = MapName;

		if ( Maps[Index].ScreenshotRef != "" )
			Screenie = Material(DynamicLoadObject(Maps[Index].ScreenshotRef, class'Material'));

		l_MapPlayers.Caption = Maps[Index].PlayerCountMin@"-"@Maps[Index].PlayerCountMax@PlayerText;
		mDesc = Maps[Index].Description;
	}
	i_MapImage.Image = Screenie;

	l_NoPreview.SetVisibility( Screenie == None );
	i_MapImage.SetVisibility( Screenie != None );

	if (mDesc == "")
		mDesc = MessageNoInfo;

	lb_MapDesc.SetContent( mDesc );
	if (Maps[Index].Author != "")
		l_MapAuthor.Caption = AuthorText$":"@Maps[Index].Author;
	else l_MapAuthor.Caption = "";
}

defaultproperties
{
}