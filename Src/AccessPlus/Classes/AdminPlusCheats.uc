Class AdminPlusCheats extends CheatManager;

var vector LastTeleportPos;

var Object StringToClassRef;
var array<string> AllWeaponsList;
var int AdminIndex;
var string AdminName;
var AccessPlus AccessController;
var bool bGlobalAdmin,bSilentAdmin,bOldTelSet;
var const array<name> CommandList;
var array<byte> PrivelegedCommands; // Synced array size with CommandList!

`define CheckExecuteCheat(FuncName) if( !CanExec(`if(`FuncName)`FuncName `else GetFuncName()`endif) ) return

final function bool IsLoggedIn()
{
	return (AdminIndex>=-1);
}
final function string NetIDToStr( UniqueNetID I )
{
	return class'OnlineSubsystem'.Static.UniqueNetIdToString(I);
}
function Logout()
{
	AdminIndex = -2;
	PrivelegedCommands.Length = 0;
	bGlobalAdmin = false;
}

final function SetCommands( string CmdList, AccessData A )
{
	local array<string> SA;
	local array<byte> GR;
	local int i,j;

	ParseStringIntoArray(CmdList,SA,",",true);
	if( SA.Length==0 || (SA.Length==1 && SA[0]=="") )
		return;
	
	PrivelegedCommands.Length = CommandList.Length;
	if( SA[0]~="All" ) // All available!
	{
		for( i=0; i<PrivelegedCommands.Length; ++i )
			PrivelegedCommands[i] = 1;
		return;
	}

	GR.Length = A.CG.Length;
	
	// First mark all groups we have priveleges to.
	for( i=0; i<SA.Length; ++i )
	{
		j = A.CG.Find(SA[i]);
		if( j>=0 )
			GR[j] = 1;
	}
	
	// Then go through each command.
	for( i=0; i<PrivelegedCommands.Length; ++i )
	{
		j = A.AC.Find('CM',CommandList[i]);
		if( j>=0 )
		{
			j = A.AC[j].CG;
			if( j>=0 && j<GR.Length )
				PrivelegedCommands[i] = GR[j];
		}
	}
}

final function bool CanExec( name N )
{
	local int i;

	if( !IsLoggedIn() )
		return false;
	if( bGlobalAdmin )
		return true;
	if( PrivelegedCommands.Length==0 )
	{
		ClientMessage("You have no admin privileges at all, please re-login as admin or ask a Super Admin to fix your account.");
		return false;
	}
	if( N!='Global' )
	{
		i = CommandList.Find(N);
		if( i==-1 )
		{
			ClientMessage("Missing commandinfo for '"$N$"', contact the mod author: Marco");
			return false;
		}
	}
	if( N=='Global' || PrivelegedCommands[i]==0 )
	{
		ClientMessage("You don't have privileges to execute command '"$N$"'.");
		return false;
	}
	return true;
}

exec function Help( optional string C )
{
	switch( Caps(C) )
	{
	case "FLY":
		ClientMessage("Fly = Begin to fly.");
		break;
	case "GHOST":
		ClientMessage("Ghost = Begin to ghost.");
		break;
	case "WALK":
		ClientMessage("Walk = Return to normal walking state.");
		break;
	case "TELEP":
		ClientMessage("TeleP <ID> = Teleport a player infront of you.");
		break;
	case "GOTOP":
		ClientMessage("GotoP <ID> = Teleport yourself to a player.");
		break;
	case "RETURNTEL":
		ClientMessage("ReturnTel = Teleport yourself back to your original position before teleport.");
		break;
	case "TELEPORT":
		ClientMessage("Teleport = Teleport yourself at the point you are aiming at.");
		break;
	case "GETID":
		ClientMessage("GetID = List players and their ID values.");
		break;
	case "SETADMINPASSWORD":
		ClientMessage("SetAdminPassword <New password> = Change the current admin account you are logged into password.");
		break;
	case "CREATEACCOUNT":
		ClientMessage("CreateAccount <ID> = Create a new admin account for a player.");
		break;
	case "DELETEACCOUNT":
		ClientMessage("DeleteAccount <Index> = Delete a player's admin account.");
		break;
	case "SETACCOUNTGROUP":
		ClientMessage("SetAccountGroup <Index> <GroupID> = Change a player's admin account group ID.");
		ClientMessage("Use ListGroups to see currently available admin groups of the server.");
		break;
	case "LOADED":
		ClientMessage("Loaded = Give yourself all weapons + max ammo.");
		break;
	case "ALLWEAPONS":
	case "ALLWEAPONSID":
		ClientMessage("AllWeapons / AllWeaponsID <ID> = Give all weapons to yourself or someone else.");
		break;
	case "ALLAMMO":
	case "ALLAMMOID":
		ClientMessage("AllAmmo / AllAmmoID <ID> = Give max ammo to yourself or someone else.");
		break;
	case "KILLALL":
		ClientMessage("KillAll <Actor Class> = Kill all actors of specified type.");
		break;
	case "KILLPAWNS":
		ClientMessage("KillPawns = Kill all enemies from level.");
		break;
	case "SUMMON":
		ClientMessage("Summon <Actor Class> |Properties| = Summon a specified actor (optional properties may be set: Health=50/GroundSpeed=1).");
		break;
	case "SUMMONRADII":
		ClientMessage("SummonRadii <Actor Class> <count> |Properties| = Summon a bunch of actors in a circle around you with specified props.");
		break;
	case "LISTACTORS":
		ClientMessage("ListActors <Actor Class> |Radius| = Show a list of actors of type in level.");
		break;
	case "LISTPRIVS":
		ClientMessage("ListPrivs = List your account priveleges.");
		break;
	case "KILL":
		ClientMessage("Kill <ID> = Kill a player.");
		break;
	case "SET":
		ClientMessage("Set <Actor class> <Property name> <Property value> = Set a property value.");
		break;
	case "GET":
		ClientMessage("Get <Object class> <Property name> = Check a property default value.");
		break;
	case "SETAUTOADMIN":
		ClientMessage("SetAutoAdmin <Flag> = Sets whatever if you should automatically login as admin when entering the server.");
		break;
	case "MUTE":
		ClientMessage("Mute <ID> = Mute a player to prevent them from using text chat (use Unmute <ID> to unmute them again).");
		break;
	case "UNMUTE":
		ClientMessage("Unmute <ID> = Unmute a muted player to allow them use text chat again.");
		break;
	case "GAG":
		ClientMessage("Gag <ID> = Mute a player to prevent them from using voice chat (use Ungag <ID> to unmute them again).");
		break;
	case "UNGAG":
		ClientMessage("Ungag <ID> = Unmute a muted player to allow them use voice chat again.");
		break;
	case "READYUP":
		ClientMessage("ReadyUp = Forces all players to ready up.");
		break;
	case "ZEDTIME":
		ClientMessage("ZedTime = Forces Zed Time.");
		break;
	case "KILLZEDS":
		ClientMessage("KillZeds = Kills all living zeds. (Doesn't destroy turrets!)");
		break;
	case "ENDWAVE":
		ClientMessage("EndWave = Ends the current wave.");
		break;
	case "TELEPORTZEDS":
		ClientMessage("TeleportZeds = Teleports all living zeds to aiming location. Useful for stuck zeds.");
		break;
	case "RESTOREDOORS":
		ClientMessage("RestoreDoors = Retores all doors in level.");
		break;
	case "UNWELDDOORS":
		ClientMessage("UnWeldDoors = UnWelds all doors in level.");
		break;
	case "WELDDOORS":
		ClientMessage("WeldDoors = Closes any open doors and fully welds them.");
		break;
	default:
		ClientMessage("List of commands <> = required, || = optional params. Use Help <CMD> for more info:");
		ShowCommandList();
		if( bGlobalAdmin )
			ClientMessage("GLOBAL: ListGroups, ListAccounts, CreateAccount, DeleteAccount, SetAccountGroup");
	}
}
final function ShowCommandList()
{
	local string S;
	local int i;
	
	S = "";
	for( i=0; i<CommandList.Length; ++i )
	{
		if( bGlobalAdmin || (PrivelegedCommands.Length>i && PrivelegedCommands[i]!=0) )
		{
			if( Len(S)==0 )
				S = string(CommandList[i]);
			else S $= ", "$string(CommandList[i]);
			if( Len(S)>90 )
			{
				ClientMessage(S);
				S = "";
			}
		}
	}
	if( Len(S)!=0 )
		ClientMessage(S);
}

final function bool FindPlayersByID( string ID, out array<Controller> Results, out string NM, optional bool bReqPawn, optional bool bNotSelf )
{
	local Controller C;
	local int i;
	
	if( ID~="All" )
	{
		NM = "everyone";
		foreach WorldInfo.AllControllers(class'Controller',C)
			if( C.bIsPlayer && !C.IsA('KFAIController_Monster') && C.PlayerReplicationInfo!=None && (!bReqPawn || (C.Pawn!=None && C.Pawn.Health>0)) && (!bNotSelf || C!=Outer) )
				Results.AddItem(C);
		return true;
	}
	if( ID~="Self" )
	{
		if( bNotSelf )
		{
			ClientMessage("Not yourself!!!");
			return false;
		}
		if( bReqPawn && (Pawn==None || Pawn.Health<=0) )
		{
			ClientMessage("You have no Pawn!");
			return false;
		}
		NM = "himself";
		Results.AddItem(C);
		return true;
	}
	
	i = int(ID);
	foreach WorldInfo.AllControllers(class'Controller',C)
		if( C.bIsPlayer && !C.IsA('KFAIController_Monster') && C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.PlayerID==i )
		{
			if( C==Outer )
			{
				ClientMessage("Not yourself!!!");
				return false;
			}
			if( bReqPawn && (C.Pawn==None || C.Pawn.Health<=0) )
			{
				ClientMessage(C.PlayerReplicationInfo.PlayerName$" has no Pawn!");
				return false;
			}
			NM = C.PlayerReplicationInfo.PlayerName;
			Results.AddItem(C);
			return true;
		}
	ClientMessage("Couldn't find player by that ID!");
	return false;
}
final function Controller FindPlayerByID( string ID, optional bool bNotSelf )
{
	local Controller C;
	local int i;
	
	if( ID~="All" )
	{
		ClientMessage("Can't do this for everyone!");
		return None;
	}
	if( ID~="Self" )
	{
		if( bNotSelf )
		{
			ClientMessage("Not yourself!!!");
			return None;
		}
		return Outer;
	}

	i = int(ID);
	foreach WorldInfo.AllControllers(class'Controller',C)
		if( C.bIsPlayer && !C.IsA('KFAIController_Monster') && C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.PlayerID==i )
		{
			if( C==Outer && bNotSelf )
			{
				ClientMessage("Not yourself!!!");
				return None;
			}
			return C;
		}
	ClientMessage("Couldn't find player by that ID!");
	return None;
}

final function Class StrToClass( string S )
{
	local Class Result;

	if( InStr(S,".")==-1 )
	{
		Result = Class( DynamicLoadObject( "KFGame."$S, class'Class', true ) );
		if( Result==None )
			Result = Class( DynamicLoadObject( "KFGameContent."$S, class'Class', true ) );
	}
	else Result = Class( DynamicLoadObject( S, class'Class' ) );
	if( Result==None )
	{
		ConsoleCommand("TextToCC "$S);
		Result = Class(StringToClassRef);
		StringToClassRef = None;
	}
	return Result;
}
final function Object StrToObject( string S )
{
	local Object Result;

	if( InStr(S,".")==-1 )
	{
		Result = DynamicLoadObject( "KFGame."$S, class'Object', true );
		if( Result==None )
			Result = DynamicLoadObject( "KFGameContent."$S, class'Object', true );
	}
	else Result = DynamicLoadObject( S, class'Object' );
	if( Result==None )
	{
		ConsoleCommand("TextToCC "$S);
		Result = StringToClassRef;
		StringToClassRef = None;
	}
	return Result;
}
exec function TextToCC( Object AC )
{
	StringToClassRef = AC;
}

final function vector GetVect( string S, vector In )
{
	local int i;

	// Chop ()
	if( Left(S,1)!="(" )
		return In;
	S = Mid(S,1);
	if( Right(S,1)==")" )
		S = Left(S,Len(S)-1);
	
	if( S=="" )
		return In;

	// Grab X
	i = InStr(S,",");
	if( i==-1 )
	{
		In.X = float(S);
		return In;
	}
	if( i>0 )
		In.X = float(Left(S,i));
	S = Mid(S,i+1);
	
	// Grab Y
	i = InStr(S,",");
	if( i==-1 )
	{
		if( S!="" )
			In.Y = float(S);
		return In;
	}
	if( i>0 )
		In.Y = float(Left(S,i));
	S = Mid(S,i+1);
	
	// Grab Z
	if( S!="" )
		In.Z = float(S);
	return In;
}
final function rotator GetRot( string S, rotator In )
{
	local int i;

	// Chop ()
	if( Left(S,1)!="(" )
		return In;
	S = Mid(S,1);
	if( Right(S,1)==")" )
		S = Left(S,Len(S)-1);
	
	if( S=="" )
		return In;

	// Grab Yaw
	i = InStr(S,",");
	if( i==-1 )
	{
		In.Yaw = int(S);
		return In;
	}
	if( i>0 )
		In.Yaw = int(Left(S,i));
	S = Mid(S,i+1);
	
	// Grab Pitch
	i = InStr(S,",");
	if( i==-1 )
	{
		if( S!="" )
			In.Pitch = int(S);
		return In;
	}
	if( i>0 )
		In.Pitch = int(Left(S,i));
	S = Mid(S,i+1);
	
	// Grab Roll
	if( S!="" )
		In.Roll = int(S);
	return In;
}
final function EPhysics StrToPhysics( string S )
{
	switch( Caps(S) )
	{
	case "PHYS_WALKING":
	case "1":
		return PHYS_Walking;
	case "PHYS_FALLING":
	case "2":
		return PHYS_Falling;
	case "PHYS_SWIMMING":
	case "3":
		return PHYS_Swimming;
	case "PHYS_FLYING":
	case "4":
		return PHYS_Flying;
	case "PHYS_ROTATING":
	case "5":
		return PHYS_Rotating;
	case "PHYS_PROJECTILE":
	case "6":
		return PHYS_Projectile;
	case "PHYS_SPIDER":
	case "7":
		return PHYS_Spider;
	default:
		return PHYS_None;
	}
}
final function ENetRole StrToNetRole( string S )
{
	switch( Caps(S) )
	{
	case "ROLE_SIMULATEDPROXY":
		return ROLE_SimulatedProxy;
	case "ROLE_AUTONOMOUSPROXY":
		return ROLE_AutonomousProxy;
	case "ROLE_AUTHORITY":
		return ROLE_Authority;
	default:
		return ROLE_None;
	}
}
final function GetActorSize( Actor A, out float ColR, out float ColH )
{
	local CylinderComponent C;

	foreach A.ComponentList(class'CylinderComponent',C)
		break;
	ColR = (C!=None ? C.CollisionRadius : 0.f);
	ColH = (C!=None ? C.CollisionHeight : 0.f);
}

final function bool SetProp( Actor A, string VarName, string Value )
{
	local float Diff,NewScale,ColH,ColR;

	switch( Caps(VarName) )
	{
	case "LOCATION":
		A.SetLocation(GetVect(Value,A.Location));
		return true;
	case "ROTATION":
		A.SetRotation(GetRot(Value,A.Rotation));
		return true;
	case "DRAWSCALE":
		NewScale = float(Value);
		if( A.DrawScale!=0 )
		{
			Diff = NewScale / A.DrawScale;
			GetActorSize(A,ColR,ColH);
			A.SetCollisionSize(ColR*Diff,ColH*Diff);
		}
		A.SetDrawScale(NewScale);
		return true;
	case "DRAWSCALE3D":
		A.SetDrawScale3D(GetVect(Value,A.DrawScale3D));
		return true;
	case "CUSTOMTIMEDILATION":
		A.CustomTimeDilation = float(Value);
		return true;
	case "PHYSICS":
		A.SetPhysics(StrToPhysics(Value));
		return true;
	case "BHIDDEN":
		A.SetHidden(bool(Value));
		return true;
	case "BWORLDGEOMETRY":
		A.bWorldGeometry = bool(Value);
		return true;
	case "BIGNOREENCROACHERS":
		A.SetCollision(,,bool(Value));
		return true;
	case "BCOLLIDEACTORS":
		A.SetCollision(bool(Value));
		return true;
	case "BBLOCKACTORS":
		A.bBlockActors = bool(Value);
		return true;
	case "BPROJTARGET":
		A.bProjTarget = bool(Value);
		return true;
	case "BCOLLIDECOMPLEX":
		A.bCollideComplex = bool(Value);
		return true;
	case "BBLOCKSTELEPORT":
		A.bBlocksTeleport = bool(Value);
		return true;
	case "BNOENCROACHCHECK":
		A.bNoEncroachCheck = bool(Value);
		return true;
	case "ROTATIONRATE":
		A.RotationRate = GetRot(Value,A.RotationRate);
		return true;
	case "VELOCITY":
		A.Velocity = GetVect(Value,A.Velocity);
		return true;
	case "ACCELERATION":
		A.Acceleration = GetVect(Value,A.Acceleration);
		return true;
	case "LIFESPAN":
		A.LifeSpan = float(Value);
		return true;
	case "NETUPDATEFREQUENCY":
		A.NetUpdateFrequency = float(Value);
		return true;
	case "NETPRIORITY":
		A.NetPriority = float(Value);
		return true;
	case "COLLISIONRADIUS":
		GetActorSize(A,ColR,ColH);
		A.SetCollisionSize(float(Value),ColH);
		return true;
	case "COLLISIONHEIGHT":
		GetActorSize(A,ColR,ColH);
		A.SetCollisionSize(ColR,float(Value));
		return true;
	case "BFORCENETUPDATE":
		A.bForceNetUpdate = bool(Value);
		return true;
	case "REMOTEROLE":
		A.RemoteRole = StrToNetRole(Value);
		return true;
	case "ROLE":
		A.Role = StrToNetRole(Value);
		return true;
	case "BALWAYSRELEVANT":
		A.bAlwaysRelevant = bool(Value);
		return true;
	case "BCRAWLER":
		if( Pawn(A)==None )
			return false;
		Pawn(A).bCrawler = bool(Value);
		return true;
	case "BCANJUMP":
		if( Pawn(A)==None )
			return false;
		Pawn(A).bCanJump = bool(Value);
		return true;
	case "BCANWALK":
		if( Pawn(A)==None )
			return false;
		Pawn(A).bCanWalk = bool(Value);
		return true;
	case "BCANSWIM":
		if( Pawn(A)==None )
			return false;
		Pawn(A).bCanSwim = bool(Value);
		return true;
	case "BCANFLY":
		if( Pawn(A)==None )
			return false;
		Pawn(A).bCanFly = bool(Value);
		return true;
	case "BCANCLIMBLADDERS":
		if( Pawn(A)==None )
			return false;
		Pawn(A).bCanClimbLadders = bool(Value);
		return true;
	case "BCANSTRAFE":
		if( Pawn(A)==None )
			return false;
		Pawn(A).bCanStrafe = bool(Value);
		return true;
	case "BCANBEBASEFORPAWNS":
		if( Pawn(A)==None )
			return false;
		Pawn(A).bCanBeBaseForPawns = bool(Value);
		return true;
	case "BCANPICKUPINVENTORY":
		if( Pawn(A)==None )
			return false;
		Pawn(A).bCanPickupInventory = bool(Value);
		return true;
	case "BAMBIENTCREATURE":
		if( Pawn(A)==None )
			return false;
		Pawn(A).bAmbientCreature = bool(Value);
		return true;
	case "SIGHTRADIUS":
		if( Pawn(A)==None )
			return false;
		Pawn(A).SightRadius = float(Value);
		return true;
	case "MASS":
		if( Pawn(A)==None )
			return false;
		Pawn(A).Mass = float(Value);
		return true;
	case "BUOYANCY":
		if( Pawn(A)==None )
			return false;
		Pawn(A).Buoyancy = float(Value);
		return true;
	case "MELEERANGE":
		if( Pawn(A)==None )
			return false;
		Pawn(A).MeleeRange = float(Value);
		return true;
	case "GROUNDSPEED":
		if( Pawn(A)==None )
			return false;
		Pawn(A).GroundSpeed = float(Value);
		return true;
	case "WATERSPEED":
		if( Pawn(A)==None )
			return false;
		Pawn(A).WaterSpeed = float(Value);
		return true;
	case "AIRSPEED":
		if( Pawn(A)==None )
			return false;
		Pawn(A).AirSpeed = float(Value);
		return true;
	case "LADDERSPEED":
		if( Pawn(A)==None )
			return false;
		Pawn(A).LadderSpeed = float(Value);
		return true;
	case "ACCELRATE":
		if( Pawn(A)==None )
			return false;
		Pawn(A).AccelRate = float(Value);
		return true;
	case "JUMPZ":
		if( Pawn(A)==None )
			return false;
		Pawn(A).JumpZ = float(Value);
		return true;
	case "AIRCONTROL":
		if( Pawn(A)==None )
			return false;
		Pawn(A).AirControl = float(Value);
		return true;
	case "HEALTH":
		if( Pawn(A)==None )
			return false;
		Pawn(A).Health = int(Value);
		return true;
	case "HEALTHMAX":
		if( Pawn(A)==None )
			return false;
		Pawn(A).HealthMax = int(Value);
		return true;
	case "DAMAGESCALING":
		if( Pawn(A)==None )
			return false;
		Pawn(A).DamageScaling = float(Value);
		return true;
	case "CONTROLLERCLASS":
		if( Pawn(A)==None )
			return false;
		Pawn(A).ControllerClass = Class<AIController>(StrToClass(Value));
		return true;
	case "CURRENTCARRYBLOCKS":
		if( Pawn(A)==None && KFInventoryManager(Pawn(A).InvManager)==None )
			return false;
		KFInventoryManager(Pawn(A).InvManager).CurrentCarryBlocks = byte(Value);
		return true;
	case "MAXCARRYBLOCKS":
		if( Pawn(A)==None && KFInventoryManager(Pawn(A).InvManager)==None )
			return false;
		KFInventoryManager(Pawn(A).InvManager).MaxCarryBlocks = byte(Value);
		return true;
	case "BINFINITEWEIGHT":
		if( Pawn(A)==None && KFInventoryManager(Pawn(A).InvManager)==None )
			return false;
		KFInventoryManager(Pawn(A).InvManager).bInfiniteWeight = bool(Value);
		return true;
	case "GRENADECOUNT":
		if( Pawn(A)==None && KFInventoryManager(Pawn(A).InvManager)==None )
			return false;
		KFInventoryManager(Pawn(A).InvManager).GrenadeCount = byte(Value);
		return true;
	case "TEAM":
		if( Pawn(A)==None || Pawn(A).Controller==None )
			return false;
		if( Value=="0" || Value=="1" )
		{
			if( Pawn(A).Controller.PlayerReplicationInfo==None )
			{
				Pawn(A).Controller.PlayerReplicationInfo = Spawn(class'PlayerReplicationInfo',Pawn(A).Controller);
				Pawn(A).PlayerReplicationInfo = Pawn(A).Controller.PlayerReplicationInfo;
			}
			if( KFPawn_Monster(A)!=None )
				Pawn(A).Controller.PlayerReplicationInfo.RemoteRole = ROLE_None;
			KFGameInfo(WorldInfo.Game).Teams[byte(Value)].AddToTeam(Pawn(A).Controller);
		}
		else if( Pawn(A).Controller.PlayerReplicationInfo!=None && Pawn(A).Controller.PlayerReplicationInfo.Team!=None )
			Pawn(A).Controller.PlayerReplicationInfo.Team.RemoveFromTeam(Pawn(A).Controller);
		return true;
	case "NUMPLAYERS":
		if( GameInfo(A)==None )
			return false;
		GameInfo(A).NumPlayers = int(Value);
		return true;
	case "MAXPLAYERS":
		if( GameInfo(A)==None )
			return false;
		GameInfo(A).MaxPlayers = int(Value);
		return true;
	default:
		return false; // TODO - Replace with SetPropertyText.
	}
}

//=======================================================================================================
// Global admin commands.
exec function ListGroups()
{
	local int i;

	`CheckExecuteCheat('Global');
	
	ClientMessage("Admin Groups:");
	for( i=(AccessController.AdminData.AG.Length-1); i>=0; --i )
		ClientMessage("#"$i$": (Priveleges=\""$AccessController.AdminData.AG[i].PR$"\",GroupName=\""$AccessController.AdminData.AG[i].GN$"\",GroupID=\""$AccessController.AdminData.AG[i].ID$"\")");
}
exec function ListAccounts()
{
	local int i;

	`CheckExecuteCheat('Global');
	
	ClientMessage("Admin Users:");
	for( i=(AccessController.AdminData.AU.Length-1); i>=0; --i )
		ClientMessage("#"$i$": (Player=\""$AccessController.AdminData.AU[i].PL$"\",GroupID=\""$AccessController.AdminData.AU[i].ID$"\",ID=\""$AccessController.AdminData.AU[i].UID$"\",Password=\""$AccessController.AdminData.AU[i].PW$"\")");
}
exec function CreateAccount( string ID )
{
	local Controller C;

	`CheckExecuteCheat('Global');

	C = FindPlayerByID(ID);
	if( C==None )
		return;
	if( PlayerController(C)==None || PlayerController(C).Player==None )
	{
		ClientMessage("Admin account can only be created for live players.");
		return;
	}
	
	ClientMessage("Created a new admin account for "$C.PlayerReplicationInfo.PlayerName$" (you must specify a GroupID for it next!)");
	AccessController.CreateAdminAccount(C.PlayerReplicationInfo);
}
exec function DeleteAccount( int Index )
{
	`CheckExecuteCheat('Global');
	
	if( Index<0 || Index>=AccessController.AdminData.AU.Length )
	{
		ClientMessage("Invalid admin index to delete ("$Index$"/"$(AccessController.AdminData.AU.Length-1)$")");
		return;
	}
	ClientMessage("Deleted account #"$Index$" ("$AccessController.AdminData.AU[Index].PL$")");
	AccessController.DeleteAdminAccount(Index);
}
exec function SetAccountGroup( int Index, string GroupID )
{
	`CheckExecuteCheat('Global');

	AccessController.SetAdminGroup(Outer,Index,GroupID);
}

//=======================================================================================================
// Local admin settings.
exec function SetAdminPassword( string NewPass )
{
	AccessController.CheckAdminData();
	if( AdminIndex==-2 )
		return;
	if( AdminIndex==-1 )
	{
		if( NewPass=="" )
		{
			ClientMessage("You shouldn't blank out SuperAdmin password or you will be locked out from accessing it.");
			return;
		}
		ClientMessage("Changed server SuperAdmin password to "$NewPass);
		AccessController.AdminData.GPW = NewPass;
	}
	else
	{
		ClientMessage("Changed your local AdminPassword to "$NewPass);
		AccessController.AdminData.AU[AdminIndex].PW = NewPass;
	}
	AccessController.SaveAdminData();
}
exec function GetID()
{
	local Controller C;

	ClientMessage("Players:");
	foreach WorldInfo.AllControllers(class'Controller',C)
		if( C.bIsPlayer && !C.IsA('KFAIController_Monster') && C.PlayerReplicationInfo!=None )
			ClientMessage(C.PlayerReplicationInfo.PlayerName$": ID="$C.PlayerReplicationInfo.PlayerID);
}
exec function SetAutoAdmin( bool bEnable )
{
	AccessController.CheckAdminData();
	if( AdminIndex==-2 )
		return;
	if( AdminIndex==-1 )
	{
		ClientMessage("Can't do this as SuperAdmin.");
	}
	else
	{
		ClientMessage("Changed your local AutoAdmin to "$bEnable);
		AccessController.AdminData.AU[AdminIndex].NA = !bEnable;
		AccessController.SaveAdminData();
	}
}

//=======================================================================================================
// Admin cheats.
exec function Fly()
{
	`CheckExecuteCheat();
	if ( (Pawn != None) && Pawn.CheatFly() )
	{
		ClientMessage("You feel much lighter");
		bCheatFlying = true;
		Outer.GotoState('PlayerFlying');
	}
}

exec function Walk()
{
	`CheckExecuteCheat();
	bCheatFlying = false;
	if ( Pawn != None && Pawn.CheatWalk())
	{
		Restart(false);
	}
}

exec function Ghost()
{
	`CheckExecuteCheat();
	if ( (Pawn != None) && Pawn.CheatGhost() )
	{
		bCheatFlying = true;
		Outer.GotoState('PlayerFlying');
		ClientMessage("You feel ethereal");
	}
}

exec function TeleP( string ID )
{
	local array<Controller> C;
	local string N;
	local vector Pos;
	local int i;

	`CheckExecuteCheat();
	if ( !FindPlayersByID(ID,C,N,,true) )
		return;
	
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has teleport to "$N$" to themself!",'Event');
	if( Pawn!=None )
		Pos = Pawn.Location + vector(Pawn.Rotation)*80.f;
	else Pos = Location + vector(Rotation)*80.f;
	
	for( i=0; i<C.Length; ++i )
	{
		if( C[i].Pawn!=None )
			C[i].Pawn.SetLocation(Pos);
		else C[i].SetLocation(Pos);
	}
}
exec function GotoP( string ID )
{
	local Controller C;
	local vector Pos;

	`CheckExecuteCheat();

	C = FindPlayerByID(ID,true);
	if( C==None )
		return;

	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has teleported to "$C.PlayerReplicationInfo.PlayerName$"!",'Event');
	if( C.Pawn!=None )
		Pos = C.Pawn.Location - vector(C.Pawn.Rotation)*80.f;
	else Pos = C.Location;

	if( !bOldTelSet )
	{
		bOldTelSet = true;
		LastTeleportPos = (Pawn!=None ? Pawn.Location : Location);
	}
	if( Pawn!=None )
		Pawn.SetLocation(Pos);
	else SetLocation(Pos);
}
exec function ReturnTel()
{
	`CheckExecuteCheat();

	if( !bOldTelSet )
		ClientMessage("Can't return teleport!");
	else
	{
		WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has returned to their original position!",'Event');
		if( Pawn!=None )
			Pawn.SetLocation(LastTeleportPos);
		else SetLocation(LastTeleportPos);
		bOldTelSet = false;
	}
}
exec function Teleport()
{
	local vector HL,HN,End,Start;
	local Actor A;

	`CheckExecuteCheat();

	A = (Pawn!=None ? Pawn : Outer);
	if( !bOldTelSet )
	{
		bOldTelSet = true;
		LastTeleportPos = A.Location;
	}
	Start = A.Location;
	End = Start + vector(Rotation)*8000.f;
	
	if( A.Trace(HL,HN,End,Start,true)!=None )
		End = HL+HN*30;
	A.SetLocation(End);
}
exec function KillAll(class<actor> aClass)
{
	local Actor A;

	`CheckExecuteCheat();

	if( aClass==None )
		return;

	ClientMessage("Killed all "$aClass);
	ForEach DynamicActors(aClass, A)
	{
		if( Pawn(A)!=None && Pawn(A).Controller!=None && PlayerController(Pawn(A).Controller)==None )
			Pawn(A).Controller.Destroy();
		A.Destroy();
	}
}
exec function KillPawns()
{
	local Pawn P;

	`CheckExecuteCheat();

	ForEach WorldInfo.AllPawns(class'Pawn', P)
	{
		if( PlayerController(P.Controller)!=None )
			continue;
		if( P.Controller!=None )
			P.Controller.Destroy();
		P.Destroy();
	}
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has killed all NPC's!",'Event');
}

exec function Loaded()
{
	`CheckExecuteCheat();

	if( Pawn==None || Pawn.InvManager==None )
		return;
	
	GiveAllWeapons(Pawn);
	GiveAllAmmo(Pawn);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has given all weapons + max ammo for themself!",'Event');
}
exec function AllWeapons()
{
	`CheckExecuteCheat();

	if( Pawn==None || Pawn.InvManager==None )
		return;

	GiveAllWeapons(Pawn);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has given all weapons for themself!",'Event');
}
exec function AllWeaponsID( string ID )
{
	local array<Controller> C;
	local string N;
	local int i;

	`CheckExecuteCheat();

	if ( !FindPlayersByID(ID,C,N,true) )
		return;

	for( i=0; i<C.Length; ++i )
		if( C[i].Pawn!=none && C[i].Pawn.InvManager!=None )
			GiveAllWeapons(C[i].Pawn);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has given all weapons for "$N$"!",'Event');
}
final function GiveAllWeapons( Pawn Other )
{
	local int i;
	local class<Inventory> Inv;

	if( PlayerController(Other.Controller)!=None )
		PlayerController(Other.Controller).ClientMessage("You have been given all weapons.");
	if( KFInventoryManager(Other.InvManager)!=None )
		KFInventoryManager(Other.InvManager).bInfiniteWeight = true;
	for( i=0; i<AllWeaponsList.Length; ++i )
	{
		Inv = class<Inventory>(DynamicLoadObject(AllWeaponsList[i],Class'Class'));
		if( Inv==None )
			continue;
		if( Other.InvManager.FindInventoryType(Inv)==None )
			Other.InvManager.CreateInventory(Inv);
	}
	if( KFInventoryManager(Other.InvManager)!=None )
		KFInventoryManager(Other.InvManager).bInfiniteWeight = false;
}

exec function AllAmmo()
{
	`CheckExecuteCheat();

	if( Pawn==None || Pawn.InvManager==None )
		return;

	GiveAllAmmo(Pawn);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has given max ammo for themself!",'Event');
}
exec function AllAmmoID( string ID )
{
	local array<Controller> C;
	local string N;
	local int i;

	`CheckExecuteCheat();

	if ( !FindPlayersByID(ID,C,N,true) )
		return;

	for( i=0; i<C.Length; ++i )
		if( C[i].Pawn!=none && C[i].Pawn.InvManager!=None )
			GiveAllAmmo(C[i].Pawn);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has given max ammo for "$N$"!",'Event');
}
final function GiveAllAmmo( Pawn Other )
{
	local KFWeapon W;

	if( PlayerController(Other.Controller)!=None )
		PlayerController(Other.Controller).ClientMessage("You have been given max ammo.");
	foreach Other.InvManager.InventoryActors(class'KFWeapon',W)
	{
		W.AmmoCount[0] = W.MagazineCapacity[0];
		W.AmmoCount[1] = W.MagazineCapacity[1];
		W.SpareAmmoCount[0] = W.SpareAmmoCapacity[0];
		W.SpareAmmoCount[1] = W.SpareAmmoCapacity[1];
		W.ClientForceAmmoUpdate(W.AmmoCount[0],W.SpareAmmoCount[0]);
		W.ClientForceSecondaryAmmoUpdate(W.AmmoCount[1]);
	}
	if( KFInventoryManager(Other.InvManager)!=None )
		KFInventoryManager(Other.InvManager).GrenadeCount = 255;
}
exec function Summon( string ClassName )
{
	local class<actor> NewClass;
	local vector SpawnLoc;
	local float Dist;
	local Actor A;
	local int i,j;
	local array<string> Props;

	`CheckExecuteCheat();

	i = InStr(ClassName," ");
	if( i>0 )
	{
		ParseStringIntoArray(Mid(ClassName,i+1),Props,"/",true);
		ClassName = Left(ClassName,i);
	}
	NewClass = class<actor>(StrToClass(ClassName));
	if( NewClass!=None )
	{
		if ( Pawn != None )
		{
			SpawnLoc = Pawn.Location;
			Dist = Pawn.CylinderComponent.CollisionRadius+38;
		}
		else
		{
			SpawnLoc = Location;
			Dist = 50;
		}
		if( class<Pawn>(NewClass)!=None )
			Dist += class<Pawn>(NewClass).Default.CylinderComponent.CollisionRadius;
		else Dist+=48;
		A = Spawn( NewClass,,,SpawnLoc + Dist * Vector(Rotation) + vect(0,0,15) );
		if( A!=None )
		{
			ClientMessage( "Fabricate " $ A );
			if( Pawn(A)!=None && A.Physics==PHYS_None )
				A.SetPhysics(PHYS_Falling);
			if( KFPawn(A)!=None && Pawn(A).ControllerClass!=None && Pawn(A).Controller==None )
			{
				Pawn(A).Controller = Spawn(Pawn(A).ControllerClass);
				Pawn(A).Controller.Possess(Pawn(A),false);
			}
			
			for( i=0; i<Props.Length; ++i )
			{
				j = InStr(Props[i],"=");
				if( j==-1 )
					ClientMessage( "Set value failed (missing =): " $Props[i] );
				else if( !SetProp(A,Left(Props[i],j),Mid(Props[i],j+1)) )
					ClientMessage( "Set value failed (unknown property): " $Props[i] );
			}
		}
		else ClientMessage("Failed to spawn "$ClassName);
	}
	else ClientMessage("Failed to load class "$ClassName);
}
exec function SummonRadii( string ClassName )
{
	local class<actor> NewClass;
	local vector SpawnLoc;
	local float Dist,YawDelta;
	local Actor A;
	local int i,j,z,n;
	local string S;
	local array<string> Props;
	local rotator R;

	`CheckExecuteCheat();

	i = InStr(ClassName," ");
	if( i==-1 )
	{
		ClientMessage("Usage: SummonRadii <classname> <count> <variables>");
		return;
	}
	S = Mid(ClassName,i+1);
	ClassName = Left(ClassName,i);
	NewClass = class<actor>(StrToClass(ClassName));
	
	if( NewClass==None )
	{
		ClientMessage("Failed to load class "$ClassName);
		return;
	}
	
	i = InStr(S," ");
	if( i==-1 )
		n = int(S);
	else
	{
		ParseStringIntoArray(Mid(S,i+1),Props,"/",true);
		n = int(Left(S,i));
	}

	if ( Pawn != None )
	{
		SpawnLoc = Pawn.Location;
		Dist = Pawn.CylinderComponent.CollisionRadius+38;
	}
	else
	{
		SpawnLoc = Location;
		Dist = 50;
	}
	if( class<Pawn>(NewClass)!=None )
		Dist += class<Pawn>(NewClass).Default.CylinderComponent.CollisionRadius;
	else Dist+=48;
	Dist += 200;
	
	YawDelta = 65536.f / n;
	for( z=0; z<n; ++z )
	{
		R.Yaw = Rotation.Yaw + (YawDelta*z);

		A = Spawn( NewClass,,,SpawnLoc + Dist * Vector(R) + vect(0,0,15), R );
		if( A!=None )
		{
			if( Pawn(A)!=None && A.Physics==PHYS_None )
				A.SetPhysics(PHYS_Falling);
			if( KFPawn(A)!=None && Pawn(A).ControllerClass!=None && Pawn(A).Controller==None )
			{
				Pawn(A).Controller = Spawn(Pawn(A).ControllerClass);
				Pawn(A).Controller.Possess(Pawn(A),false);
			}

			for( i=0; i<Props.Length; ++i )
			{
				j = InStr(Props[i],"=");
				if( j==-1 )
				{
					if( z==0 )
						ClientMessage( "Set value failed (missing =): " $Props[i] );
				}
				else if( !SetProp(A,Left(Props[i],j),Mid(Props[i],j+1)) )
				{
					if( z==0 )
						ClientMessage( "Set value failed (unknown property): " $Props[i] );
				}
			}
		}
	}
}

exec function Set( string S )
{
	local int i,j;
	local class<actor> AC;
	local string VarN;
	local Actor A;
	
	`CheckExecuteCheat();

	i = InStr(S," ");
	if( i==-1 )
	{
		ClientMessage("Missing variable name to set");
		return;
	}
	AC = class<actor>(StrToClass(Left(S,i)));
	if( AC==None )
	{
		ClientMessage("Unknown class to set: "$Left(S,i));
		return;
	}
	S = Mid(S,i+1);
	i = InStr(S," ");
	if( i==-1 )
	{
		ClientMessage("Missing variable value to set to");
		return;
	}
	VarN = Left(S,i);
	S = Mid(S,i+1);
	i = 0;
	j = 0;
	foreach AllActors(AC,A)
	{
		if( SetProp(A,VarN,S) )
			++i;
		else ++j;
	}
	ClientMessage("Set actor '"$AC$"' property '"$VarN$"' value to '"$S$"', success: "$i$", failed: "$j);
}
exec function Get( string S )
{
	`CheckExecuteCheat();

	ClientMessage("Result: "$WorldInfo.ConsoleCommand("GET "$S));
}

//======================================================================================================
// GamePlay
exec function ListActors( class<Actor> BaseClass, optional float Radii )
{
	local Actor A;
	local byte c;
	local vector Spot;
	local float R;

	`CheckExecuteCheat();
	
	if( BaseClass==None )
		BaseClass = class'Actor';
	ClientMessage("Found actors of type "$BaseClass$" in radius "$(Radii<=0 ? "<unlimited>" : string(Radii))$":");
	Spot = (Pawn!=None ? Pawn.Location : Location);
	if( Radii<=0 )
	{
		foreach AllActors(BaseClass,A)
		{
			ClientMessage(A@PathName(A.Class)$" Tag: "$A.Tag$" Radii: "$VSize(A.Location-Spot));
			if( ++c>=100 )
				break;
		}
	}
	else
	{
		foreach AllActors(BaseClass,A)
		{
			R = VSize(A.Location-Spot);
			if( R>Radii )
				continue;
			ClientMessage(A@PathName(A.Class)$" Tag: "$A.Tag$" Radii: "$R);
			if( ++c>=100 )
				break;
		}
	}
}
exec function Kill( string ID )
{
	local array<Controller> C;
	local string N;
	local int i;

	`CheckExecuteCheat();

	if ( !FindPlayersByID(ID,C,N,true) )
		return;

	for( i=0; i<C.Length; ++i )
		if( C[i].Pawn!=None )
			C[i].Pawn.KilledBy(None);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has slain "$N$"!",'Event');
}
exec function PlaySoundFX( string SndName )
{
	local AkBaseSoundObject S;

	`CheckExecuteCheat();

	S = AkBaseSoundObject(StrToObject(SndName));
	if( S==None )
		ClientMessage("Couldn't load sound effect '"$SndName$"'.");
	else if( ViewTarget!=None )
		ViewTarget.PlaySoundBase(S,false,false,true,ViewTarget.Location);
	else PlaySoundBase(S,false,false,true,Location);
}
exec function RespawnPlayer( string ID )
{
	local array<Controller> C;
	local string N;
	local int i;
	local vector V;
	local rotator R;

	`CheckExecuteCheat();

	if ( !FindPlayersByID(ID,C,N) )
		return;

	if( ViewTarget!=None )
	{
		V = ViewTarget.Location;
		R.Yaw = ViewTarget.Rotation.Yaw;
	}
	else
	{
		V = Location;
		R.Yaw = Rotation.Yaw;
	}
	V += vector(R) * 100.f;

	for( i=0; i<C.Length; ++i )
		if( PlayerController(C[i])!=None && !C[i].PlayerReplicationInfo.bOnlySpectator && (C[i].Pawn==None || !C[i].Pawn.IsAliveAndWell()) )
			ForceRespawnPlayer(C[i],V,R);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has forced "$N$" to respawn!",'Event');
}
final function bool ForceRespawnPlayer( Controller NewPlayer, vector StartPos, rotator StartRot )
{
	local KFPlayerReplicationInfo KFPRI;
	local KFPlayerController KFPC;
	local int Idx;
	local array<SequenceObject> Events;
	local SeqEvent_PlayerSpawned SpawnedEvent;
	local LocalPlayer LP;

	if( NewPlayer.Pawn!=None )
		NewPlayer.Pawn.Destroy();

	// try to create a pawn to use of the default class for this player
	NewPlayer.Pawn = Spawn(WorldInfo.Game.GetDefaultPlayerClass(NewPlayer),,,StartPos,StartRot,,true);

	if (NewPlayer.Pawn == None)
	{
		NewPlayer.GotoState('Dead');
		if ( PlayerController(NewPlayer) != None )
			PlayerController(NewPlayer).ClientGotoState('Dead','Begin');
		return false;
	}
	else
	{
		// initialize and start it up
		if ( PlayerController(NewPlayer) != None )
			PlayerController(NewPlayer).TimeMargin = -0.1;
		NewPlayer.Pawn.LastStartTime = WorldInfo.TimeSeconds;
		NewPlayer.Possess(NewPlayer.Pawn, false);
		NewPlayer.Pawn.PlayTeleportEffect(true, true);
		NewPlayer.ClientSetRotation(NewPlayer.Pawn.Rotation, TRUE);

		if ( !WorldInfo.bNoDefaultInventoryForPlayer )
			WorldInfo.Game.AddDefaultInventory(NewPlayer.Pawn);
		WorldInfo.Game.SetPlayerDefaults(NewPlayer.Pawn);

		// activate spawned events
		if (WorldInfo.GetGameSequence() != None)
		{
			WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_PlayerSpawned',TRUE,Events);
			for (Idx = 0; Idx < Events.Length; Idx++)
			{
				SpawnedEvent = SeqEvent_PlayerSpawned(Events[Idx]);
				if (SpawnedEvent != None &&
					SpawnedEvent.CheckActivate(NewPlayer,NewPlayer))
				{
					SpawnedEvent.SpawnPoint = None;
					SpawnedEvent.PopulateLinkedVariableValues();
				}
			}
		}
	}

	KFPC = KFPlayerController(NewPlayer);
	KFPRI = KFPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo);

	// To fix custom post processing chain when not running in editor or PIE.
	if (KFPC != none)
	{
		LP = LocalPlayer(KFPC.Player); 
		if(LP != None) 
		{ 
			LP.RemoveAllPostProcessingChains(); 
			LP.InsertPostProcessingChain(LP.Outer.GetWorldPostProcessChain(),INDEX_NONE,true); 
			if(KFPC.myHUD != None)
			{
				KFPC.myHUD.NotifyBindPostProcessEffects();
			}
		} 
	}

	KFGameInfo(WorldInfo.Game).SetTeam( NewPlayer, KFGameInfo(WorldInfo.Game).Teams[0] );

	if( KFPC != none )
	{
		// Initialize game play post process effects such as damage, low health, etc.
		KFPC.InitGameplayPostProcessFX();
	}
	if( KFPRI!=None )
	{
		if( KFPRI.Deaths == 0 )
			KFPRI.Score = KFGameInfo(WorldInfo.Game).DifficultyInfo.GetAdjustedStartingCash();
		KFPRI.PlayerHealth = NewPlayer.Pawn.Health;
		KFPRI.PlayerHealthPercent = FloatToByte( float(NewPlayer.Pawn.Health) / float(NewPlayer.Pawn.HealthMax) );
	}
	return true;
}

//======================================================================================================
// Admin commands.
exec function KickBan( string S )
{
	local int i,t;
	local string R;
	local PlayerController PC;

	`CheckExecuteCheat();

	i = InStr(S," ");
	if( i==-1 )
	{
		R = "";
		t = 2;
	}
	else
	{
		R = Mid(S,i+1);
		S = Left(S,i);

		i = InStr(R," ");
		if( i==-1 )
		{
			t = int(R);
			R = "";
		}
		else
		{
			t = int(Left(R,i));
			R = Mid(R,i+1);
		}
	}
	PC = PlayerController(FindPlayerByID(S,true));
	if( PC!=None )
	{
		AccessController.AddPlayerBan(AdminName,PC,R,t);
		WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has banned player "$PC.PlayerReplicationInfo.PlayerName$"!",'Event');
		PC.Destroy();
	}
}
exec function Mute( string ID )
{
	local array<Controller> C;
	local string N;
	local int i;

	`CheckExecuteCheat();

	if ( !FindPlayersByID(ID,C,N) )
		return;

	for( i=0; i<C.Length; ++i )
		if( PlayerController(C[i])!=None )
			AccessController.SetPlayerMute(PlayerController(C[i]),true);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has muted "$N$"!",'Event');
}
exec function Unmute( string ID )
{
	local array<Controller> C;
	local string N;
	local int i;

	`CheckExecuteCheat('Mute');

	if ( !FindPlayersByID(ID,C,N) )
		return;

	for( i=0; i<C.Length; ++i )
		if( PlayerController(C[i])!=None )
			AccessController.SetPlayerMute(PlayerController(C[i]),false);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has unmuted "$N$"!",'Event');
}
exec function Gag( string ID )
{
	local array<Controller> C;
	local string N;
	local int i;

	`CheckExecuteCheat();

	if ( !FindPlayersByID(ID,C,N) )
		return;

	for( i=0; i<C.Length; ++i )
		if( PlayerController(C[i])!=None )
			AccessController.SetPlayerVoiceMute(PlayerController(C[i]),true);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has gagged "$N$"!",'Event');
}
exec function Ungag( string ID )
{
	local array<Controller> C;
	local string N;
	local int i;

	`CheckExecuteCheat('Gag');

	if ( !FindPlayersByID(ID,C,N) )
		return;

	for( i=0; i<C.Length; ++i )
		if( PlayerController(C[i])!=None )
			AccessController.SetPlayerVoiceMute(PlayerController(C[i]),false);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has ungagged "$N$"!",'Event');
}

exec function ReadyUp()
{
	local PlayerController PC;
	
	`CheckExecuteCheat();

	ForEach WorldInfo.AllControllers(class'PlayerController', PC)
	{
		if( PC.bIsPlayer )
		{
			PC.PlayerReplicationInfo.bReadyToPlay = true;
		}
	}
}

exec function ZedTime()
{
	local KFGameInfo KFGID;
	
	KFGID = KFGameInfo(WorldInfo.Game);
	
	`CheckExecuteCheat();
	KFGID.DramaticEvent(1.f);
}

exec function KillZeds()
{
	local KFPawn_Monster AIP;
	
	`CheckExecuteCheat();

	ForEach WorldInfo.AllPawns(class'KFPawn_Monster', AIP)
	{
		if( AIP.Health>0 )
		{
		   AIP.Died(None, None, AIP.Location);
		}
	}
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has killed all zeds.",'Event');
}

exec function EndWave()
{
	local KFGameInfo_Survival KFGIS;
	local KFPawn_Monster AIP;
	KFGIS = KFGameInfo_Survival(WorldInfo.Game);
	
	`CheckExecuteCheat();

	if (!KFGIS.IsWaveActive())
		return;

	ForEach WorldInfo.AllPawns(class'KFPawn_Monster', AIP)
	{
		if( AIP.Health>0 )
		{
		   AIP.Died(None , None, AIP.Location);
		}
	}

	KFGIS.CheckWaveEnd(true);
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has ended the wave.",'Event');
}

exec function TeleportZeds()
{
	local Actor	HitActor;
	local vector HitNormal, HitLocation;
	local vector ViewLocation;
	local rotator ViewRotation;
	local KFPawn_Monster AIP;
	
	`CheckExecuteCheat();

	GetPlayerViewPoint( ViewLocation, ViewRotation );

	HitActor = Trace(HitLocation, HitNormal, ViewLocation + 1000000 * vector(ViewRotation), ViewLocation, true);
	if ( HitActor != None)
		HitLocation += HitNormal * 4.0;

	ForEach WorldInfo.AllPawns(class'KFPawn_Monster', AIP)
	{
		if( AIP.Health>0 )
		{
		   AIP.SetLocation( HitLocation );
		}
	}
	WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has teleported all zeds.",'Event');
}

exec function RestoreDoors()
{
	local KFDoorActor KFDA;
	
	`CheckExecuteCheat();

	ForEach WorldInfo.AllActors( class'KFDoorActor', KFDA )
	{
		KFDA.ResetDoor();
	}
	ClientMessage("All doors have been restored");
}

exec function UnWeldDoors()
{
	local KFDoorActor KFDA;
	
	`CheckExecuteCheat();

	ForEach WorldInfo.AllActors( class'KFDoorActor', KFDA )
	{
		if (KFDA.WeldIntegrity > 0)
		{
			KFDA.WeldIntegrity = 0;
			KFDA.bForceNetUpdate = true; //Force an update to display weld
		}
	}
	ClientMessage("All doors have been unwelded");
}

exec function WeldDoors()
{
	local KFDoorActor KFDA;
	
	`CheckExecuteCheat();

	foreach WorldInfo.AllActors( class'KFDoorActor', KFDA )
	{
		if (KFDA.bIsDoorOpen)
				KFDA.UseDoor(Pawn);  //CloseDoor is a private function. Get around this by faking a user closing the door

		if (!KFDA.bIsDoorOpen && !KFDA.bIsDestroyed) //Don't weld open/destroyed doors.
		{
			KFDA.WeldIntegrity = KFDA.MaxWeldIntegrity;
			KFDA.bForceNetUpdate = true; //Force update to display weld
		}
	}
	ClientMessage("All doors have been welded");
}

exec function Rich( string ID )
{
	local array<Controller> C;
	local string N;
	local int i;
	local int Dosh;

	`CheckExecuteCheat();
	if ( !FindPlayersByID(ID,C,N,true) )
		return;
	Dosh = 300000;
	for( i=0; i<C.Length; ++i )
	{
		C[i].PlayerReplicationInfo.Score = Dosh;
		//WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has made "$N$" rich!",'Event');
	}
}
exec function Poor( string ID )
{
	local array<Controller> C;
	local string N;
	local int i;
	local int Dosh;

	`CheckExecuteCheat();
	if ( !FindPlayersByID(ID,C,N,true) )
		return;
	Dosh = 0;
	for( i=0; i<C.Length; ++i )
	{
		C[i].PlayerReplicationInfo.Score = Dosh;
		//WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has made "$N$" poor!",'Event');
	}
}

exec function EpicRich( string ID )
{
	local array<Controller> C;
	local string N;
	local int i;
	local int Dosh;

	`CheckExecuteCheat();
	if ( !FindPlayersByID(ID,C,N,true) )
		return;
	Dosh = 1000000000;
	for( i=0; i<C.Length; ++i )
	{
		C[i].PlayerReplicationInfo.Score = Dosh;
		//WorldInfo.Game.Broadcast(Outer,PlayerReplicationInfo.PlayerName$" has made "$N$" rich!",'Event');
	}
}

/*exec function ABCDEFGH( optional string NewPass )
{
	if( NewPass=="" )
		ClientMessage("'"$AccessController.AdminData.GPW$"'");
	else
	{
		AccessController.CheckAdminData();
		AccessController.AdminData.GPW = NewPass;
		AccessController.SaveAdminData();
	}
}*/

exec function DebugVersion()
{
	ClientMessage("AdminVer "$AccessController.AdminData.STG$", BanVer "$AccessController.BansData.STG);
}

defaultproperties
{
	AllWeaponsList.Add("KFGameContent.KFWeap_AssaultRifle_AK12")
	AllWeaponsList.Add("KFGameContent.KFWeap_AssaultRifle_AR15")
	AllWeaponsList.Add("KFGameContent.KFWeap_AssaultRifle_Bullpup")
	AllWeaponsList.Add("KFGameContent.KFWeap_AssaultRifle_Medic")
	AllWeaponsList.Add("KFGameContent.KFWeap_AssaultRifle_SCAR")
	AllWeaponsList.Add("KFGameContent.KFWeap_Blunt_Crovel")
	AllWeaponsList.Add("KFGameContent.KFWeap_Blunt_Pulverizer")
	AllWeaponsList.Add("KFGameContent.KFWeap_Edged_Katana")
	AllWeaponsList.Add("KFGameContent.KFWeap_Edged_Knife")
	AllWeaponsList.Add("KFGameContent.KFWeap_Flame_Flamethrower")
	AllWeaponsList.Add("KFGameContent.KFWeap_Healer_Syringe")
	AllWeaponsList.Add("KFGameContent.KFWeap_Knife_Berserker")
	AllWeaponsList.Add("KFGameContent.KFWeap_Knife_Commando")
	AllWeaponsList.Add("KFGameContent.KFWeap_Knife_FieldMedic")
	AllWeaponsList.Add("KFGameContent.KFWeap_Knife_Support")
	AllWeaponsList.Add("KFGameContent.KFWeap_Knife_Demolitionist")
	AllWeaponsList.Add("KFGameContent.KFWeap_Knife_Sharpshooter")
	AllWeaponsList.Add("KFGameContent.KFWeap_Knife_Gunslinger")
	AllWeaponsList.Add("KFGameContent.KFWeap_Knife_Firebug")
	AllWeaponsList.Add("KFGameContent.KFWeap_Knife_SWAT")
	AllWeaponsList.Add("KFGameContent.KFWeap_Pistol_9mm")
	AllWeaponsList.Add("KFGameContent.KFWeap_Pistol_Medic")
	AllWeaponsList.Add("KFGameContent.KFWeap_SawbladeShooter")
	AllWeaponsList.Add("KFGameContent.KFWeap_Shotgun_AA12")
	AllWeaponsList.Add("KFGameContent.KFWeap_Shotgun_DoubleBarrel")
	AllWeaponsList.Add("KFGameContent.KFWeap_Shotgun_M4")
	AllWeaponsList.Add("KFGameContent.KFWeap_Shotgun_MB500")
	AllWeaponsList.Add("KFGameContent.KFWeap_Shotgun_Medic")
	AllWeaponsList.Add("KFGameContent.KFWeap_Shotgun_Nailgun")
	AllWeaponsList.Add("KFGameContent.KFWeap_SMG_Medic")
	AllWeaponsList.Add("KFGameContent.KFWeap_Welder")
	AllWeaponsList.Add("KFGameContent.KFWeap_Beam_Microwave")
	AllWeaponsList.Add("KFGameContent.KFWeap_Bow_Crossbow")
	AllWeaponsList.Add("KFGameContent.KFWeap_Blunt_MaceAndShield")
	AllWeaponsList.Add("KFGameContent.KFWeap_Edged_Zweihander")
	AllWeaponsList.Add("KFGameContent.KFWeap_GrenadeLauncher_M79")
	AllWeaponsList.Add("KFGameContent.KFWeap_GrenadeLauncher_HX25")
	AllWeaponsList.Add("KFGameContent.KFWeap_Pistol_Deagle")
	AllWeaponsList.Add("KFGameContent.KFWeap_Pistol_Colt1911")
	AllWeaponsList.Add("KFGameContent.KFWeap_Pistol_DualDeagle")
	AllWeaponsList.Add("KFGameContent.KFWeap_Pistol_DualColt1911")
	AllWeaponsList.Add("KFGameContent.KFWeap_Rifle_M14EBR")
	AllWeaponsList.Add("KFGameContent.KFWeap_Shotgun_DragonsBreath")
	AllWeaponsList.Add("KFGameContent.KFWeap_RocketLauncher_RPG7")
	AllWeaponsList.Add("KFGameContent.KFWeap_SMG_Kriss")
	AllWeaponsList.Add("KFGameContent.KFWeap_SMG_MP7")
	AllWeaponsList.Add("KFGameContent.KFWeap_SMG_MP5RAS")
	AllWeaponsList.Add("KFGameContent.KFWeap_SMG_P90")
	AllWeaponsList.Add("KFGameContent.KFWeap_Rifle_Winchester1894")
	AllWeaponsList.Add("KFGameContent.KFWeap_Pistol_Flare")
	AllWeaponsList.Add("KFGameContent.KFWeap_Pistol_Dual9mm")
	AllWeaponsList.Add("KFGameContent.KFWeap_Pistol_DualFlare")
	AllWeaponsList.Add("KFGameContent.KFWeap_Rifle_RailGun")
	AllWeaponsList.Add("KFGameContent.KFWeap_Shotgun_HZ12")
	AllWeaponsList.Add("KFGameContent.KFWeap_Rifle_CenterfireMB464")
	AllWeaponsList.Add("KFGameContent.KFWeap_LMG_Stoner63A")
	AllWeaponsList.Add("KFGameContent.KFWeap_Revolver_Rem1858")
	AllWeaponsList.Add("KFGameContent.KFWeap_Eviscerator")
	AllWeaponsList.Add("KFGameContent.KFWeap_Flame_CaulkBurn")
	AllWeaponsList.Add("KFGameContent.KFWeap_Revolver_DualSW500")
	AllWeaponsList.Add("KFGameContent.KFWeap_Revolver_DualRem1858")
	AllWeaponsList.Add("KFGameContent.KFWeap_Revolver_SW500")
	AllWeaponsList.Add("KFGameContent.KFWeap_Rifle_Hemogoblin")
	AllWeaponsList.Add("KFGameContent.KFWeap_RocketLauncher_Seeker6")
	AllWeaponsList.Add("KFGameContent.KFWeap_Thrown_C4")
	AllWeaponsList.Add("KFGameContent.KFWeap_SMG_HK_UMP")
	AllWeaponsList.Add("KFGameContent.KFWeap_AssaultRifle_M16M203")
	AllWeaponsList.Add("KFGameContent.KFWeap_Ice_FreezeThrower")

	CommandList.Add("Fly")
	CommandList.Add("Walk")
	CommandList.Add("Ghost")
	CommandList.Add("TeleP")
	CommandList.Add("GotoP")
	CommandList.Add("ReturnTel")
	CommandList.Add("Teleport")
	CommandList.Add("KillAll")
	CommandList.Add("KillPawns")
	CommandList.Add("Loaded")
	CommandList.Add("AllWeapons")
	CommandList.Add("AllWeaponsID")
	CommandList.Add("AllAmmo")
	CommandList.Add("AllAmmoID")
	CommandList.Add("Summon")
	CommandList.Add("SummonRadii")
	CommandList.Add("Set")
	CommandList.Add("Get")
	CommandList.Add("ListActors")
	CommandList.Add("PlaySoundFX")
	CommandList.Add("Kill")
	CommandList.Add("KickBan")
	CommandList.Add("Mute")
	CommandList.Add("Gag")
	CommandList.Add("RespawnPlayer")
	CommandList.Add("ReadyUp")
	CommandList.Add("ZedTime")
	CommandList.Add("KillZeds")
	CommandList.Add("EndWave")
	CommandList.Add("TeleportZeds")
	CommandList.Add("RestoreDoors")
	CommandList.Add("UnWeldDoors")
	CommandList.Add("WeldDoors")
	CommandList.Add("Rich")
	CommandList.Add("EpicRich")
	CommandList.Add("Poor")
}