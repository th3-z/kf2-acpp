Class AccessPlus extends KFAccessControl
	Config(AccessPlus);

var array<UniqueNetId> MutedPlayers,VoiceMutedPlayers;

`if(`isdefined(SUPPORT_RESERVED_SLOTS))
struct FReservedEntry
{
	var float TimeOut;
	var string Opt;
};
var array<FReservedEntry> ReservedUsers;
var int ReservedIndex;

var globalconfig bool bNoReservedSlots;
`endif
var globalconfig bool bLogGlobalPW;
var globalconfig string AccessDataPath;
var AccessData AdminData,SecDataRef;
var AccessPlusBans BansData,SecBansData;
var AccessBroadcast MessageFilter;
var AccessMutator AccessMut;
var array<name> AdminLevels;

var transient int OldMaxPL,OldMaxSpec;

final function string GetFilePath( bool bBans )
{
	return AccessDataPath$(bBans ? "AC_ServerBans.usa" : "AC_Admins.usa");
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	if( AccessDataPath=="" )
	{
		AccessDataPath = "../../";
		SaveConfig();
	}
	AdminData = new(None)class'AccessData';
	SecDataRef = new(None)class'AccessData';
	class'Engine'.Static.BasicLoadObject(AdminData,GetFilePath(false),false,0);
	AdminData.ParseUIDs();
	BansData = new(None)class'AccessPlusBans';
	SecBansData = new(None)class'AccessPlusBans';
	class'Engine'.Static.BasicLoadObject(BansData,GetFilePath(true),false,0);
	BansData.InitStartTime();
	if( WorldInfo.NetMode!=NM_StandAlone )
		SetTimer(0.1,false,'SetupWebadmin');
	if( bLogGlobalPW )
		`Log("Current GlobalAdmin password is '"$AdminData.GPW$"'");
}
function NotifyServerTravel(bool bSeamless)
{
	CheckBanData();
	if( BansData.AdvanceBans() )
		SaveBanData();
	Super.NotifyServerTravel(bSeamless);
}
function SetupWebadmin()
{
	local WebServer W;
	local WebAdmin A;
	local AccessPlusWebApp xW;
	local byte i;

	foreach AllActors(class'WebServer',W)
		break;
	if( W!=None )
	{
		for( i=0; (i<10 && A==None); ++i )
			A = WebAdmin(W.ApplicationObjects[i]);
		if( A!=None )
		{
			xW = new (None) class'AccessPlusWebApp';
			xW.AccessControl = Self;
			A.addQueryHandler(xW);
		}
		else `Log("AccessPlusWebAdmin ERROR: No valid WebAdmin application found!");
	}
	else `Log("AccessPlusWebAdmin ERROR: No WebServer object found!");
}
final function bool CheckAdminData()
{
	class'Engine'.Static.BasicLoadObject(SecDataRef,GetFilePath(false),false,0);
	if( SecDataRef.STG!=AdminData.STG )
	{
		SaveDataUpdated();
		return true;
	}
	return false;
}
final function SaveAdminData()
{
	++AdminData.STG;
	class'Engine'.Static.BasicSaveObject(AdminData,GetFilePath(false),false,0,true);
}
final function SaveDataUpdated()
{
	local PlayerController P;
	local AdminPlusCheats A;
	local AccessData T;
	
	// Swap.
	T = AdminData;
	AdminData = SecDataRef;
	SecDataRef = T;

	AdminData.ParseUIDs();
	foreach WorldInfo.AllControllers(class'PlayerController',P)
	{
		A = AdminPlusCheats(P.CheatManager);
		if( A!=None && A.AdminIndex>=0 && AdminLogOut(P) )
		{
			AdminExited(P);
			P.ClientMessage("Admin accounts were modified in another server, please relogin.");
		}
	}
}
final function bool CheckBanData()
{
	local AccessPlusBans T;

	class'Engine'.Static.BasicLoadObject(SecBansData,GetFilePath(true),false,0);
	if( SecBansData.STG!=BansData.STG )
	{
		// Swap.
		T = BansData;
		BansData = SecBansData;
		SecBansData = T;

		// Sync time.
		BansData.StartTime = SecBansData.StartTime;
		return true;
	}
	return false;
}
final function SaveBanData()
{
	++BansData.STG;
	BansData.bDirty = false;
	class'Engine'.Static.BasicSaveObject(BansData,GetFilePath(true),false,0);
}

// Webadmin login.
function bool ValidLogin(string UserName, string Password)
{
	local int i;
	
	for( i=0; i<AdminData.AU.Length; ++i )
	{
		if( UserName~=AdminData.AU[i].PL && AdminData.AU[i].PW!="" && Password==AdminData.AU[i].PW )
			return (AdminData.GetAdminType(i)<=1);
	}
	return (UserName~="Admin" && Password==AdminData.GPW);
}

final function LoginAdmin( PlayerController P, int AccIndex, bool bSilent, optional bool bLogin )
{
	local int i;
	local AdminPlusCheats A;
	local string S;
	local byte t;
	
	if( bLogin && AdminData.AU[AccIndex].NA )
		return;
	P.PlayerReplicationInfo.bAdmin = true;
	A = AdminPlusCheats(P.CheatManager);
	if( A==None )
	{
		A = new(P)class'AdminPlusCheats';
		P.CheatManager = A;
		A.InitCheatManager();
	}
	else A.Logout();
	A.AccessController = Self;
	
	if( AccIndex==-1 )
	{
		S = "Super Admin";
		t = 0;
	}
	else
	{
		i = AdminData.FindAdminGroup(AdminData.AU[AccIndex].ID);
		t = 1;
		if( i==-1 )
		{
			P.PlayerReplicationInfo.bAdmin = false;
			P.ClientMessage("Can't login as admin: Broken admin account.");
			return;
		}
		else
		{
			S = AdminData.AG[i].GN;
			A.SetCommands(AdminData.AG[i].PR,AdminData);
			t = AdminData.AG[i].AT+1;
			if( t>=4 ) // VIP.
			{
				bSilent = true;
				P.PlayerReplicationInfo.bAdmin = false;
			}
		}
	}
	P.PlayerReplicationInfo.BeginState(AdminLevels[Min(t,AdminLevels.Length-1)]);

	if( bLogin )
	{
		if( !bSilent )
			WorldInfo.Game.Broadcast(Self,P.PlayerReplicationInfo.PlayerName$" is an "$S$".",'Priority');
	}
	else
	{
		if( !bSilent )
			WorldInfo.Game.Broadcast(Self,P.PlayerReplicationInfo.PlayerName$" logged in as "$S$".",'Priority');
		P.ClientMessage("You have logged in as "$S$", use 'Admin Help' to see command list.");
	}

	A.bSilentAdmin = bSilent;
	A.bGlobalAdmin = (AccIndex==-1);
	A.AdminIndex = AccIndex;
	A.AdminName = (A.bGlobalAdmin ? P.PlayerReplicationInfo.PlayerName$" (SA)" : AdminData.AU[AccIndex].PL);
}
function bool AdminLogin( PlayerController P, string Password )
{
	local bool bSilent;
	local int i;
	local AdminPlusCheats A;
	
	A = AdminPlusCheats(P.CheatManager);
	if( A!=None && A.IsLoggedIn() )
	{
		P.ClientMessage("Can't login as admin: You already are an admin.");
		return false;
	}
	if( Password=="" ) // During login.
	{
		i = AdminData.FindAdminUser(P.PlayerReplicationInfo.UniqueId);
		if( i>=0 )
		{
			LoginAdmin(P,i,false,true);
			return true;
		}
		return false;
	}

	bSilent = (Right(Password,7)~=" silent");
	if( bSilent )
		Password = Left(Password,Len(Password)-7);
	else
	{
		bSilent = (Password~="silent");
		if( bSilent )
			Password = "";
	}

	// Check if super admin.
	if( AdminData.GPW!="" && Password==AdminData.GPW )
	{
		LoginAdmin(P,-1,bSilent);
		return true;
	}

	// first check for matching password
	if( Password!="" )
	{
		i = AdminData.FindAdminPW(Password);
		if( i>=0 )
		{
			LoginAdmin(P,i,bSilent);
			return true;
		}
	}
	// Then check for matching ID.
	i = AdminData.FindAdminUser(P.PlayerReplicationInfo.UniqueId);
	if( i>=0 )
	{
		LoginAdmin(P,i,bSilent);
		return true;
	}
	P.ClientMessage("Invalid password!");
	return false;
}
function AdminEntered( PlayerController P );

function AdminExited( PlayerController P )
{
	local AdminPlusCheats A;
	
	A = AdminPlusCheats(P.CheatManager);
	if( A!=None )
	{
		if( !A.bSilentAdmin )
			WorldInfo.Game.Broadcast(Self,P.PlayerReplicationInfo.PlayerName$" gave up their administrative abilities.",'Priority');
	}
}

function bool AdminLogout(PlayerController P)
{
	local AdminPlusCheats A;
	
	A = AdminPlusCheats(P.CheatManager);
	if ( P.PlayerReplicationInfo.bAdmin || (A!=None && A.IsLoggedIn()) )
	{
		P.PlayerReplicationInfo.BeginState('User');
		P.PlayerReplicationInfo.bAdmin = false;
		P.bGodMode = false;
		A.Logout();
		return true;
	}
	return false;
}

final function int CreateAdminAccount( PlayerReplicationInfo PRI )
{
	local int i;

	CheckAdminData();
	
	i = AdminData.FindAdminUser(PRI.UniqueId);
	if( i>=0 )
		return -1;
	i = AdminData.AU.Length;
	AdminData.AU.Length = i+1;
	AdminData.AU[i].PL = PRI.PlayerName;
	AdminData.AU[i].ID = "";
	AdminData.AU[i].UID = class'OnlineSubsystem'.Static.UniqueNetIdToString(PRI.UniqueId);
	AdminData.AU[i].AdminID = PRI.UniqueId;
	AdminData.AU[i].PW = "";
	
	SaveAdminData();
	return i;
}
final function DeleteAdminAccount( int Index )
{
	local PlayerController PC;
	local AdminPlusCheats A;
	local UniqueNetID ID;

	ID = AdminData.AU[Index].AdminID;
	if( CheckAdminData() )
	{
		Index = AdminData.FindAdminUser(ID);
		if( Index==-1 )
			return;
	}
	AdminData.AU.Remove(Index,1);
	SaveAdminData();

	// Update live admins if needed.
	foreach WorldInfo.AllControllers(class'PlayerController',PC)
	{
		if( !PC.PlayerReplicationInfo.bAdmin )
			continue;
		A = AdminPlusCheats(PC.CheatManager);
		if( A.AdminIndex==Index )
		{
			// Kick em out.
			if ( AdminLogOut(PC) )
			{
				AdminExited(PC);
				PC.ClientMessage("Your admin account was deleted.");
			}
		}
		else if( A.AdminIndex>Index )
			--A.AdminIndex;
	}
}
final function SetAdminGroup( PlayerController P, int Index, string NewGroup )
{
	local int i;
	local PlayerController PC;
	local AdminPlusCheats A;
	local UniqueNetID UID;

	if( Index<0 || Index>=AdminData.AU.Length )
	{
		P.ClientMessage("Invalid admin index to edit ("$Index$"/"$(AdminData.AU.Length-1)$")");
		return;
	}
	NewGroup = Caps(NewGroup);
	UID = AdminData.AU[Index].AdminID; // Store this info incase it gets changed.
	if( CheckAdminData() )
	{
		Index = AdminData.FindAdminUser(UID);
		if( Index==-1 )
		{
			P.ClientMessage("Invalid GroupID change: Admin account was deleted.");
			return;
		}
	}
	i = AdminData.FindAdminGroup(NewGroup);
	if( i==-1 )
	{
		P.ClientMessage("Invalid GroupID: "$NewGroup$" (use ListGroups to see which ones there are)");
		return;
	}
	P.ClientMessage("Modified account #"$Index$" ("$AdminData.AU[Index].PL$") GroupID to "$NewGroup);
	AdminData.AU[Index].ID = NewGroup;
	SaveAdminData();
	
	// Update live admins if needed.
	foreach WorldInfo.AllControllers(class'PlayerController',PC)
	{
		if( !PC.PlayerReplicationInfo.bAdmin )
			continue;
		A = AdminPlusCheats(PC.CheatManager);
		if( A.AdminIndex==Index )
		{
			// Kick em out.
			if ( AdminLogOut(PC) )
			{
				AdminExited(PC);
				PC.ClientMessage("Your admin account was modified, please relogin as admin.");
			}
		}
	}
}

final function WebDeleteGroup( int Index )
{
	local string S;
	
	// First cache current group ID before updating.
	S = AdminData.AG[Index].ID;
	if( CheckAdminData() )
	{
		if( Index>=AdminData.AG.Length || S!=AdminData.AG[Index].ID ) // Got changed.
			return;
	}
	
	AdminData.AG.Remove(Index,1);
	SaveAdminData();
}
final function int WebAddGroup()
{
	local int i;
	
	CheckAdminData();
	
	i = AdminData.AG.Length;
	AdminData.AG.Length = i+1;
	AdminData.AG[i].PR = "Cheat,GamePlay,Admin";
	AdminData.AG[i].GN = "New Group";
	AdminData.AG[i].ID = "ADMIN_"$i;
	SaveAdminData();
	
	return i;
}
final function WebEditGroup( int Index, string Privs, string GroupID, string GroupName, byte AdminType )
{
	local string S;
	
	// First cache current group ID before updating.
	S = AdminData.AG[Index].ID;
	if( CheckAdminData() )
	{
		if( Index>=AdminData.AG.Length || S!=AdminData.AG[Index].ID ) // Got changed.
			return;
	}
	
	AdminData.AG[Index].PR = Privs;
	AdminData.AG[Index].GN = GroupName;
	AdminData.AG[Index].ID = Caps(GroupID);
	AdminData.AG[Index].AT = AdminType;
	SaveAdminData();
}
final function WebDeleteUser( int Index )
{
	local UniqueNetID ID;
	
	// First cache current group ID before updating.
	ID = AdminData.AU[Index].AdminID;
	if( CheckAdminData() )
	{
		Index = AdminData.FindAdminUser(ID);
		if( Index==-1 )
			return;
	}
	
	AdminData.AU.Remove(Index,1);
	SaveAdminData();
}
final function WebUpdateUser( int Index, string PL, string GID, string PW, string UID, bool bAA )
{
	local UniqueNetID ID;
	
	// First cache current group ID before updating.
	ID = AdminData.AU[Index].AdminID;
	
	if( CheckAdminData() )
	{	
		Index = AdminData.FindAdminUser(ID);
		if( Index==-1 )
			return;
	}
	
	AdminData.AU[Index].PL = PL;
	AdminData.AU[Index].ID = Caps(GID);
	AdminData.AU[Index].PW = PW;
	AdminData.AU[Index].UID = UID;
	AdminData.AU[Index].NA = !bAA;
	SaveAdminData();
	
	// Update AdminID if needed.
	class'OnlineSubsystem'.Static.StringToUniqueNetId(AdminData.AU[Index].UID,ID);
	AdminData.AU[Index].AdminID = ID;
}
final function WebAddCommands()
{
	local int i,j;

	j = -1;
	CheckAdminData();
	for( i=0; i<class'AdminPlusCheats'.Default.CommandList.Length; ++i )
	{
		if( AdminData.AC.Find('CM',class'AdminPlusCheats'.Default.CommandList[i])==-1 )
		{
			j = AdminData.AC.Length;
			AdminData.AC.Length = j+1;
			AdminData.AC[j].CM = class'AdminPlusCheats'.Default.CommandList[i];
			AdminData.AC[j].CG = -1;
		}
	}
	if( j!=-1 )
		SaveAdminData();
}
final function WebUpdateCommand( int Index, string NewCmd, int NewIndex, string NewGroup )
{
	local name CM;
	local string GN;

	// First cache current group ID before updating.
	CM = AdminData.AC[Index].CM;
	if( NewIndex>=0 && NewIndex<AdminData.CG.Length )
		GN = AdminData.CG[NewIndex];

	if( CheckAdminData() )
	{
		// Verify if deleted/modified.
		Index = AdminData.AC.Find('CM',CM);
		if( Index==-1 )
			return;
		if( GN!="" )
		{
			NewIndex = AdminData.CG.Find(GN);
			if( NewIndex==-1 )
				return;
		}
	}
	
	if( GN=="" )
	{
		if( NewGroup=="" )
			return;
		GN = NewGroup;
		NewIndex = AdminData.CG.Find(GN);
		if( NewIndex==-1 )
		{
			NewIndex = AdminData.CG.Length;
			AdminData.CG.AddItem(GN);
		}
	}
	
	AdminData.AC[Index].CM = name(NewCmd);
	AdminData.AC[Index].CG = NewIndex;
	SaveAdminData();
}
final function WebDeleteCommand( int Index )
{
	local name CM;
	
	// First cache current group ID before updating.
	CM = AdminData.AC[Index].CM;
	if( CheckAdminData() )
	{
		Index = AdminData.AC.Find('CM',CM);
		if( Index==-1 )
			return;
	}
	
	AdminData.AC.Remove(Index,1);
	SaveAdminData();
}
final function WebDeleteBan( string WebUser, int Index )
{
	local string OldID;
	
	OldID = BansData.BE[Index].ID;
	if( CheckBanData() )
	{
		if( OldID!=BansData.BE[Index].ID ) // Bans were changed, ignore this.
			return;
	}
	
	BansData.AddLogLine(WebUser$" (WEB): Removed ban #"$BansData.BE[Index].IX$" ("$BansData.BE[Index].N$","$BansData.BE[Index].ID$"), expires in: "$BansData.WEBGetBanTimeStr(Index));
	BansData.BE.Remove(Index,1);
	SaveBanData();
}
final function WebEditBan( string WebUser, int Index, string N, string IP, string R, int T, string NT )
{
	local string OldID;
	
	OldID = BansData.BE[Index].ID;
	if( CheckBanData() )
	{
		if( OldID!=BansData.BE[Index].ID ) // Bans were changed, ignore this.
			return;
	}
	
	BansData.UpdateTempTime();
	BansData.AddLogLine(WebUser$" (WEB): Edit ban #"$BansData.BE[Index].IX$" (IP:"$BansData.BE[Index].IP$"->"$IP$", Time:"$BansData.WEBGetBanTime(Index)$"->"$T$"h)");
	BansData.BE[Index].N = N;
	BansData.BE[Index].IP = IP;
	BansData.BE[Index].R = R;
	BansData.SetBanTime(Index,T);
	BansData.BE[Index].NT = NT;
	SaveBanData();
}
final function int WebAddBan( string WebUser, string ID )
{
	local int i;

	CheckBanData();
	BansData.AddLogLine(WebUser$" (WEB): Add NEW ban #"$BansData.BID@ID);
	
	i = BansData.BE.Length;
	BansData.BE.Length = i+1;
	BansData.BE[i].IX = BansData.BID++;
	BansData.BE[i].ID = ID;
	BansData.BE[i].IP = "0.0.0.0";
	BansData.BE[i].N = "Player";
	BansData.BE[i].R = "No reason given";
	BansData.BE[i].T = -1;
	BansData.BE[i].A = WebUser$" (WEB)";
	SaveBanData();
	return i;
}
final function AddPlayerBan( string User, PlayerController P, optional string Reason, optional int Time=24 )
{
	local string UID,UIP;
	local int i;

	if ( P.PlayerReplicationInfo.UniqueId==P.PlayerReplicationInfo.default.UniqueId )
		return;
	if( Reason=="" )
		Reason = "No reason given";
	UID = class'OnlineSubsystem'.Static.UniqueNetIdToString(P.PlayerReplicationInfo.UniqueId);
	UIP = P.GetPlayerNetworkAddress();
	CheckBanData();
	
	i = BansData.BE.Find('ID',UID);
	if( i>=0 )
		return;
	if( Time==0 )
		Time = 1;
	WorldInfo.Game.Broadcast(Self,User$": Banned "$P.PlayerReplicationInfo.PlayerName$" for "$(Time<0 ? "forever" : Time$" hours")$", reason: "$Reason);
	BansData.AddLogLine(User$": Banned "$P.PlayerReplicationInfo.PlayerName$" (#"$BansData.BID@UID@UIP$") for "$Time$" hours, reason: "$Reason);
	i = BansData.BE.Length;
	BansData.BE.Length = i+1;
	BansData.BE[i].IX = BansData.BID++;
	BansData.BE[i].ID = UID;
	BansData.BE[i].IP = UIP;
	BansData.BE[i].N = P.PlayerReplicationInfo.PlayerName;
	BansData.BE[i].R = Reason;
	BansData.BE[i].A = User;
	BansData.SetBanTime(i,Time);
	SaveBanData();
}

function KickBan( string Target )
{
	local PlayerController P;

	P = PlayerController( GetControllerFromString(Target) );
	if ( NetConnection(P.Player) != None )
	{
		AddPlayerBan("Console",P);
		P.Destroy();
	}
}

function bool CheckIPPolicy(string Address)
{
	return true;
}

`if(`isdefined(SUPPORT_RESERVED_SLOTS))
function ClearReserved()
{
	local int i;
	
	for( i=(ReservedUsers.Length-1); i>=0; --i )
		if( ReservedUsers[i].TimeOut<WorldInfo.TimeSeconds )
			ReservedUsers.Remove(i,1);
	if( ReservedUsers.Length==0 )
		ClearTimer('ClearReserved');
}
`endif
event PreLogin(string Options, string Address, const UniqueNetId UniqueId, bool bSupportsAuth, out string OutError, bool bSpectator)
{
	local string UID,InName;
	local int i,j;

`if(`isdefined(SUPPORT_RESERVED_SLOTS))
	local bool bReserved;

	bReserved = false;
	if( !bNoReservedSlots )
	{
		if( AdminData.FindAdminUser(UniqueId)>=0 )
		{
			i = ReservedUsers.Find('Opt',Options);
			if( i==-1 )
			{
				i = ReservedUsers.Length;
				ReservedUsers.Length = i+1;
				ReservedUsers[i].Opt = Options;
			}
			ReservedUsers[i].TimeOut = WorldInfo.TimeSeconds+60.f;
			bReserved = true;
			OldMaxPL = WorldInfo.Game.MaxPlayers;
			OldMaxSpec = WorldInfo.Game.MaxSpectators;
			SetTimer(10,true,'ClearReserved');
			WorldInfo.Game.MaxPlayers = 999;
			WorldInfo.Game.MaxSpectators = 999;
		}
	}
`endif

	Super.PreLogin(Options,Address,UniqueId,bSupportsAuth,OutError,bSpectator);
	`Log("PreLogin"@Options@Address@bSpectator@OutError);
	
`if(`isdefined(SUPPORT_RESERVED_SLOTS))
	if( bReserved )
	{
		WorldInfo.Game.MaxPlayers = OldMaxPL;
		WorldInfo.Game.MaxSpectators = OldMaxSpec;
	}
`endif
	
	InName = WorldInfo.Game.ParseOption( Options, "Name" );
	if( OutError=="" )
	{
		UID = class'OnlineSubsystem'.Static.UniqueNetIdToString(UniqueId);
		
		i = BansData.BE.Find('ID',UID);
		if( i>=0 && BansData.CheckBanActive(i) )
		{
MsgBan:
			OutError = "You are banned (#"$BansData.BE[i].IX$", reason: '"$BansData.BE[i].R$"', ban duration: "$BansData.GetBanTimeStr(i)$")";
			if( class'KFGameInfo'.Default.WebsiteLink!="" )
				OutError $= ". Ban appeals at: "$class'KFGameInfo'.Default.WebsiteLink;
			AdminMessage(InName$" failed to login: "$OutError);
			return;
		}

		if( BansData.bDirty && !CheckBanData() )
			SaveBanData();

		i = InStr(Address,":");
		if( i>0 )
			Address = Left(Address,i);
		i = BansData.BE.Find('IP',Address);
		if( i>=0 )
		{
			j = BansData.BE[i].IX;
			if( CheckBanData() )
			{
				i = BansData.BE.Find('IP',Address);
				if( i==-1 )
					return; // Ban was actually removed.
			}
			BansData.AddLogLine("Console: Banned "$InName$" (#"$BansData.BID@UID@Address$") for forever, reason: Had an pre-excisting ban entry #"$j);
			i = BansData.BE.Length;
			BansData.BE.Length = i+1;
			BansData.BE[i].IX = BansData.BID++;
			BansData.BE[i].ID = UID;
			BansData.BE[i].IP = Address;
			BansData.BE[i].N = InName;
			BansData.BE[i].R = "Other ban entry #"$j;
			BansData.BE[i].A = "Console";
			BansData.SetBanTime(i,-1);
			SaveBanData();
			GoTo'MsgBan';
		}
		
		// Msg prelogin.
		WorldInfo.Game.Broadcast(Self,InName$" is connecting");
	}
	else AdminMessage(InName$" failed to login: "$OutError);
}
final function AdminMessage( string S )
{
	local PlayerController PC;
	
	S = "*ADMIN*: "$S;
	foreach WorldInfo.AllControllers(class'PlayerController',PC)
	{
		if( Admin(PC)!=None )
			PC.ClientMessage(S);
		else if( PC.PlayerReplicationInfo!=None && PC.PlayerReplicationInfo.bAdmin )
			PC.ClientMessage(S,'Priority');
	}
}
function bool ParseAdminOptions( string Options )
{
`if(`isdefined(SUPPORT_RESERVED_SLOTS))
	ReservedIndex = ReservedUsers.Find('Opt',Options);
	if( ReservedIndex>=0 )
	{
		OldMaxPL = WorldInfo.Game.MaxPlayers;
		OldMaxSpec = WorldInfo.Game.MaxSpectators;
		WorldInfo.Game.MaxPlayers = 999;
		WorldInfo.Game.MaxSpectators = 999;
	}
`endif
	
	return false;
}

`if(`isdefined(SUPPORT_RESERVED_SLOTS))
function bool IsPendingAuth(UniqueNetId PlayerUID)
{
	if( ReservedIndex>=0 )
	{
		ReservedUsers.Remove(ReservedIndex,1);
		ReservedIndex = -1;
		WorldInfo.Game.MaxPlayers = OldMaxPL;
		WorldInfo.Game.MaxSpectators = OldMaxSpec;
	}
	return Super.IsPendingAuth(PlayerUID);
}
`endif

final function SetPlayerMute( PlayerController PC, bool bMute )
{
	local int i;

	if( bMute )
	{
		if( MutedPlayers.Find('Uid',PC.PlayerReplicationInfo.UniqueId.Uid)==-1 )
		{
			PC.ClientMessage("You have been muted from using chat.",'Priority');
			MutedPlayers.AddItem(PC.PlayerReplicationInfo.UniqueId);
		}
		if( MessageFilter==None )
		{
			MessageFilter = Spawn(class'AccessBroadcast');
			MessageFilter.AccessController = Self;
		}
	}
	else
	{
		i = MutedPlayers.Find('Uid',PC.PlayerReplicationInfo.UniqueId.Uid);
		if( i>=0 )
		{
			MutedPlayers.Remove(i,1);
			PC.ClientMessage("You have been unmuted from using chat.",'Priority');
		}
	}
}
final function SetPlayerVoiceMute( PlayerController PC, bool bMute )
{
	local int i;

	if( bMute )
	{
		if( VoiceMutedPlayers.Find('Uid',PC.PlayerReplicationInfo.UniqueId.Uid)==-1 )
		{
			PC.ClientMessage("You have been muted from using voice chat.",'Priority');
			VoiceMutedPlayers.AddItem(PC.PlayerReplicationInfo.UniqueId);
			FilterVoices(PC,true);
		}
		if( AccessMut==None )
		{
			AccessMut = Spawn(class'AccessMutator');
			if( AccessMut==None )
			{
				// Mutator was already present.
				foreach DynamicActors(class'AccessMutator',AccessMut)
					break;
			}
			if( AccessMut!=None )
				AccessMut.AccessController = Self;
		}
	}
	else
	{
		i = VoiceMutedPlayers.Find('Uid',PC.PlayerReplicationInfo.UniqueId.Uid);
		if( i>=0 )
		{
			VoiceMutedPlayers.Remove(i,1);
			PC.ClientMessage("You have been unmuted from using voice chat.",'Priority');
			FilterVoices(PC,false);
		}
	}
}
final function FilterVoices( PlayerController PC, bool bMute )
{
	local KFPlayerController C;
	local UniqueNetId ZeroUniqueNetId;
	
	// Check all players
	foreach WorldInfo.AllControllers( class'KFPlayerController', C )
	{
		if( C!=PC && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.UniqueId!=ZeroUniqueNetId )
		{
			if( bMute )
			{
				PC.GameplayMutePlayer( C.PlayerReplicationInfo.UniqueId );
				C.GameplayMutePlayer( PC.PlayerReplicationInfo.UniqueId );
			}
			else
			{
				PC.GameplayUnmutePlayer( C.PlayerReplicationInfo.UniqueId );
				C.GameplayUnmutePlayer( PC.PlayerReplicationInfo.UniqueId );
			}
		}
	}
}
final function CheckMutedPlayers( PlayerController PC )
{
	local KFPlayerController C;
	local UniqueNetId ZeroUniqueNetId;

	if( VoiceMutedPlayers.Find('Uid',PC.PlayerReplicationInfo.UniqueId.Uid)>=0 )
	{
		// This player is muted.
		foreach WorldInfo.AllControllers( class'KFPlayerController', C )
		{
			if( C!=PC && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.UniqueId!=ZeroUniqueNetId )
			{
				PC.GameplayMutePlayer( C.PlayerReplicationInfo.UniqueId );
				C.GameplayMutePlayer( PC.PlayerReplicationInfo.UniqueId );
			}
		}
	}
	else
	{
		// See if other players are muted.
		foreach WorldInfo.AllControllers( class'KFPlayerController', C )
		{
			if( C!=PC && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.UniqueId!=ZeroUniqueNetId && VoiceMutedPlayers.Find('Uid',C.PlayerReplicationInfo.UniqueId.Uid)>=0 )
			{
				PC.GameplayMutePlayer( C.PlayerReplicationInfo.UniqueId );
				C.GameplayMutePlayer( PC.PlayerReplicationInfo.UniqueId );
			}
		}
	}
}

defaultproperties
{
	Components.Empty()
`if(`isdefined(SUPPORT_RESERVED_SLOTS))
	ReservedIndex=-1
`endif
	
	AdminLevels(0)="Global"
	AdminLevels(1)="Admin"
	AdminLevels(2)="Mod"
	AdminLevels(3)="TMem"
	AdminLevels(4)="VIP"
}