unit ClMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, PsAPI, Clipbrd,
  DirectX, DrawScrn, IntroScn, PlayScn, MapUnit, WIL, Grobal2, Actor, HumanActor, DIB,
  StdCtrls, cliUtil, ExtCtrls, HUtil32, EDcode, DWinCtl, GList, MMSystem, MaketSystem, CDClientSDK,
  ClFunc, magiceff, SoundUtil, clEvent, IniFiles, HashList, MShare, MD5, uSMBIOS, //123456
  D7ScktComp, DXClass, DXDraws, DCPcrypt, Mars, StallSystem, CPUInfoMin, VCLUnZip, zlib,
  Unit123, jpeg, shellApi;

type
  LPDYNCODE = function(Ptr: PByte; Len: DWORD): BOOL; stdcall;
  LPGETDYNCODE = function(ID: Integer): LPDYNCODE; stdcall;

  //下面函数好象没有被调用过
  TLoadLibraryExW = function(lpLibFileName: PWideChar; hFile: THandle; dwFlags: DWORD): HMODULE; stdcall;


type TJX_Vtable = record
    m_GetVersion: function(buff: PChar; len: Integer): Integer; stdcall;
    m_GetStringSign: function(buf: Pchar; len: Integer): Cardinal; stdcall;
    m_CheckPe: function(buf: PChar): Cardinal; stdcall;
  end;
  PJX_Vtable = ^TJX_Vtable;
const PACKETSIG = $33333333;


type TJX_PACKET = record
    signature: Cardinal;
    totoallen: Integer;
    curOffset: Integer;
    curLen: Integer;
    Crc: Cardinal;
  end;
  PJX_PACKET = ^TJX_PACKET;

var
  g_ClientVersion: String = '版本:2019-12-27';
  g_ShowClientVersion : Boolean =False;

  g_MoveBusy: Boolean = False;
  g_PathBusy: Boolean = False;
  g_MoveStep: Integer = 0;
  g_MoveErr: Integer = 0;
  g_MoveErrTick: LongWord;
  g_bCanDraw: Boolean = True;

  
  g_bReIntMap: Boolean = False;
  g_InitTime: DWORD = 0;
  g_dwSendCDCheckTick: LongWord;

const
{$IFDEF DEBUG_LOGIN}
  CHECKPACKED = False;
{$ELSE}
  CHECKPACKED = True;
{$ENDIF}

  CONFIGTEST = not CHECKPACKED;
  EnglishVersion = True;
  boNeedPatch = True;

  g_LocalLanguage: TImeMode = imDontCare;
  NEARESTPALETTEINDEXFILE = '.\Data\npal.idx';
  NEARESTPALETTEINDEXFILE_16 = '.\Data\npal-16.idx';

  MonImageDir = '.\Data\';
  NpcImageDir = '.\Data\';
  ItemImageDir = '.\Data\';
  WeaponImageDir = '.\Data\Weapon';
  HumImageDir = '.\Data\Hum';

  WM_GraphNotify = WM_App + 1;
  EC_COMPLETE = $01;
  AM_SEEKING_NoPositioning = 0;
  AM_SEEKING_AbsolutePositioning = $1;
  AM_SEEKING_RelativePositioning = $2;
  AM_SEEKING_IncrementalPositioning = $3;
  AM_SEEKING_PositioningBitsMask = $3;
  AM_SEEKING_SeekToKeyFrame = $4;
  AM_SEEKING_ReturnTime = $8;
  AM_SEEKING_Segment = $10;
  AM_SEEKING_NoFlush = $20;

  AM_SEEKING_CanSeekAbsolute = $1;
  AM_SEEKING_CanSeekForwards = $2;
  AM_SEEKING_CanSeekBackwards = $4;
  AM_SEEKING_CanGetCurrentPos = $8;
  AM_SEEKING_CanGetStopPos = $10;
  AM_SEEKING_CanGetDuration = $20;
  AM_SEEKING_CanPlayBackwards = $40;
  AM_SEEKING_CanDoSegments = $80;
  AM_SEEKING_Source = $100;

{$IF FAKELOADLIB}
  m_dwUser32: ULONG = 0;
  m_dwUser32Low: DWORD = 0; //user32.dll 的加载基址
  m_dwUser32Hi: DWORD = 0; //user32.dll 的加载基址＋ImageSize
  fakeLoadLibraryExW: array[0..11] of BYTE = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); //save first bytes of the raw function,and jmp back to that function
  rawLoadLibraryExW: TLoadLibraryExW = nil;
{$IFEND FAKELOADLIB}

type
  TOneClickMode = (toNone, toKornetWorld);

  IStrings = class(TStringlist)
  protected
    procedure SetTextStr(const Value: string); override;
  end;

  TfrmMain = class(TDXForm)
    MouseTimer: TTimer;
    WaitMsgTimer: TTimer;
    SelChrWaitTimer: TTimer;
    CmdTimer: TTimer;
    MinTimer: TTimer;
    TimerAutoMagic: TTimer;
    TimerHeroActor: TTimer;
    TimerAutoMove: TTimer;
    TimerAutoPlay: TTimer;
    TimerPacket: TTimer;
    Timer1: TTimer;
    Timer2: TTimer;
    DXDraw: TDXDraw;
    Panel1: TPanel;
    Image1: TImage;
    CloseLogoTimer: TTimer;
    timerRefresh: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DXDrawMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure DXDrawMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure CSocketConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure CSocketDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure CSocketError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure CSocketRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure CSocketReadA(Sender: TObject; Socket: TCustomWinSocket);

    procedure CSocket1Read(Sender: TObject; Socket: TCustomWinSocket);
    procedure CSocket1Connect(Sender: TObject; Socket: TCustomWinSocket);
    procedure CSocket1Error(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure CSocket1Disconnect(Sender: TObject; Socket: TCustomWinSocket);

    procedure DXDrawMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseTimerTimer(Sender: TObject);
    procedure DXDrawDblClick(Sender: TObject);
    procedure DXDrawonWindowMove(Sender: TObject);
    procedure WaitMsgTimerTimer(Sender: TObject);
    procedure SelChrWaitTimerTimer(Sender: TObject);
    procedure DXDrawClick(Sender: TObject);
    procedure CmdTimerTimer(Sender: TObject);
    procedure MinTimerTimer(Sender: TObject);
    procedure CheckHackTimerTimer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TimerHeroActorTimer(Sender: TObject);
    procedure DXDrawInitialize(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure TimerAutoMagicTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TimerAutoMoveTimer(Sender: TObject);
    function DirToDX(Direction, tdir: Integer): Integer;
    function DirToDY(Direction, tdir: Integer): Integer;
    procedure TimerAutoPlayTimer(Sender: TObject);
    procedure TimerPacketTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure CloseLogoTimerTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure timerRefreshTimer(Sender: TObject);
  private
    FPrintScreenNow: Boolean;
    FExchgScreen: Boolean;
    SocStr, BufferStr: string;

    testSocStr, testBufferStr: string;

    TimerCmd: TTimerCommand;
    MakeNewId: string;
    ActionLockTime: LongWord;
    ActionKey: Word;
    m_dwMouseDownTime: LongWord;
    m_boMouseUpEnAble: Boolean;
    WaitingMsg: TDefaultMessage;
    WaitingStr: string;
    WhisperName: string;
    FVCLUnZip: TVCLUnZip;
    m_dwProcUseMagicTick: LongWord;
    m_rungatemod: array of BYTE;
    m_loadcount: Integer;
    m_notice: string;
    m_noticewidth: Integer;
    m_NoticeOk: Boolean;
    m_vtable: PJX_Vtable;

    procedure AutoPickUpItem();
    procedure ProcessMagic;
    procedure ProcessKeyMessages;
    procedure ProcessActionMessages;
    procedure CheckSpeedHack(rtime: LongWord);
    procedure RecalcAutoMovePath();
    procedure DecodeMessagePacket(datablock: string; btPacket: Integer);
    procedure ProcessActMsg(datablock: string);
    procedure ActionFailed;

    procedure UseMagicSpell(who, effnum, targetx, targety, magic_id: Integer);
    procedure UseMagicFire(who, efftype, effnum, targetx, targety, target, maglv: Integer);
    procedure UseMagicFireFail(who: Integer);

    procedure CloseAllWindows;
    procedure ClearDropItems;
    procedure ResetGameVariables;
    procedure ChangeServerClearGameVariables;
    procedure _DXDrawMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; boClick: Boolean);

    function CheckDoorAction(dx, dy: Integer): Boolean;

    procedure ClientGetServerTitles(Len: Integer; S: string);
    procedure ClientGetPositionMove(msg: TDefaultMessage; Buff: string);
    procedure ClientGetPasswdSuccess(body: string);
    procedure ClientGetNeedUpdateAccount(body: string);
    procedure ClientGetSelectServer;
    procedure ClientGetPasswordOK(msg: TDefaultMessage; sBody: string);
    procedure ClientGetReceiveChrs(body: string);
    procedure ClientGetStartPlay(body: string);
    procedure ClientGetReconnect(body: string);
    procedure ClientGetServerConfig(msg: TDefaultMessage; sBody: string);
    procedure ClientGetMapDescription(msg: TDefaultMessage; sBody: string);
    procedure ClientGetGameGoldName(msg: TDefaultMessage; sBody: string);
    procedure ClientOpenBook(msg: TDefaultMessage; sBody: string);
    procedure ClientGetAdjustBonus(bonus: Integer; body: string);

    procedure ClientGetAddItem(Hint: Integer; body: string);
    procedure ClientHeroGetAddItem(body: string);

    procedure ClientGetUpdateItem(body: string);
    procedure ClientHeroGetUpdateItem(body: string);

    procedure ClientGetDelItem(body: string);
    procedure ClientHeroGetDelItem(body: string);

    procedure ClientGetDelItems(body: string; wOnlyBag: Word);
    procedure ClientHeroGetDelItems(body: string; wOnlyBag: Word);

    procedure ClientGetBagItmes(body: string);
    procedure ClientGetSafeZoneEffectCustom(body: String);
    procedure ClientGetNpcCustom(body: String);
    procedure ClientHeroGetBagItmes(body: string; nBagSize: Integer);
    procedure ClientGetDropItemFail(iname: string; sindex: Integer);
    procedure ClientHeroGetDropItemFail(iname: string; sindex: Integer);

    procedure ClientGetShowItem(itemid, X, Y, looks: Integer; itmname: string);
    procedure ClientGetHideItem(itemid, X, Y: Integer);
    procedure ClientGetSendUseItems(body: string);
    procedure ClientGetSendHeroUseItems(body: string);

    procedure ClientGetAddMagic(body: string);
    procedure ClientHeroGetAddMagic(body: string);
    procedure ClientGetDelMagic(magid, btclass: Integer);
    procedure ClientHeroGetDelMagic(magid, btclass: Integer);

    procedure ClientConvertMagic(t1, t2, id1, id2: Integer; S: string);
    procedure hClientConvertMagic(t1, t2, id1, id2: Integer; S: string);

    procedure ClientGetMyMagics(body: string);
    procedure ClientGetHeroMagics(body: string);
    procedure ClientGetShopItems(body: string; Int: Integer);
    procedure ClientGetMagicLvExp(magid, maglv, magtrain: Integer);
    procedure ClientGetMagicMaxLv(magid, magMaxlv, hero: Integer);
    procedure ClientHeroGetMagicLvExp(magid, maglv, magtrain: Integer);
    procedure ClientGetDuraChange(uidx, newdura, newduramax: Integer);
    procedure ClientGetBagDuraChange(MakeIndex: Integer; NewDura: Word; isHero: Boolean; WaitItemToBag: boolean);
    procedure ClientHeroGetDuraChange(uidx, newdura, newduramax: Integer);
    procedure ClientGetMerchantSay(merchant, face: Integer; saying: string);
    procedure ClientGetSendGoodsList(merchant, count, Model: Integer; body: string);
    procedure ClientGetDelCharList(count: Integer; body: string);

    procedure ClientGetSendUserExchgBook(merchant: Integer);
    procedure ClientGetSendMakeDrugList(merchant: Integer; body: string);
    procedure ClientGetSendUserSell(merchant: Integer);
    procedure ClientGetSendItemDlg(merchant: Integer; Str: string);
    procedure ClientGetSendBindItem(merchant: Integer);
    procedure ClientGetSendUnBindItem(merchant: Integer);

    procedure ClientGetSendUserRepair(merchant: Integer);
    procedure ClientGetSendUserStorage(merchant: Integer);
    procedure ClientGetSendUserStorageView(merchant: Integer);
    procedure ClientGetSendUserMaketSell(merchant: Integer);
    procedure ClientGetSaveItemList(merchant: Integer; bodystr: string);
    procedure ClientGetStorageItemList(merchant: Integer; bodystr: string);
    procedure ClientGetSendDetailGoodsList(merchant, count, topline: Integer; bodystr: string);
    procedure ClientGetSendNotice(body: string);
    procedure ClientGetImageFileListCustom(body: string);
    procedure ClientGetGroupMembers(bodystr: string);
    procedure ClientGetOpenGuildDlg(bodystr: string);
    procedure ClientGetSendGuildMemberList(body: string);
    procedure ClientGetDealRemoteAddItem(body: string);
    procedure ClientGetDealRemoteDelItem(body: string);
    procedure ClientGetReadMiniMap(mapindex: Integer);
    procedure ClientGetChangeGuildName(body: string);
    procedure ClientGetSendUserState(body: string);
    procedure DrawEffectHum(nType, nX, nY: Integer);
    procedure DrawEffectHumEx(nID, nType, tag: Integer);
    procedure ClientGetPasswordStatus(msg: pTDefaultMessage; body: string);
    // procedure ClientGetRegInfo(msg: pTDefaultMessage; body: string);    私有成员函数未调用  2019-10-07 18:01:33
    procedure ClientGetFoxState(msg: TDefaultMessage; Buff: string);

    procedure ClientGetMyTitles(nHero: Integer; Buff: string);

    procedure SetInputStatus();
    procedure CmdShowHumanMsg(sParam1, sParam2, sParam3, sParam4, sParam5: string);
    // procedure SendPowerBlock;                        私有成员函数未调用   2019-10-07 18:01:33
    procedure DrawGameNotice_Ex;

    procedure DecodeMessagePacketTest(datablock: string);
    // procedure ProcssRunModule;                        私有成员函数未调用   2019-10-07 18:01:33
    // procedure SendItemSumCoundt(OrgItemIndex, ExItemIndex, hero: Integer;
    //  StrOrgItem, StrExItem: string);                  私有成员函数未调用   2019-10-07 18:01:33

    procedure ReInitUserSateUI();                          //  六格用户状态Ui
  protected
    procedure WMGraphNotify(var msg: TMessage); message WM_GraphNotify;
  public
    canReDraw: boolean;
    DCP_mars: TDCP_mars;
    DDClipper: TDirectDrawClipper;
    ActionFailLock: Boolean;
    ActionFailLockTime: LongWord;
    LastHitTick: LongWord;
    FOldTime: DWORD;
    LoginID, LoginPasswd: string;
    m_sCharName, m_sHeroCharName: string;
    Certification: Integer;
    m_nEatRetIdx: Integer;
    ActionLock, m_boSupplyItem: Boolean;

    NpcImageList: TList;
    ItemImageList: TList;
    WeaponImageList: TList;
    HumImageList: TList;

    m_dwDuraWarningTick: LongWord;
    dwIPTick: LongWord;
    dwhIPTick: LongWord;

    FEncodeFunc: LPDYNCODE;
    FDecodeFunc: LPDYNCODE;

    FEndeBuffer: Pointer;
    FTempBuffer: array[0..16 * 1024 - 1] of Char;
    FSendBuffer: array[0..16 * 1024 - 1] of Char;

    CSocket: TClientSocket;
    FRecvBuffer: array[0..16 * 1024 - 1] of Char;
    pRecvBuffer: PChar;
    RecvBufLen: Integer;
    CSocket1: TClientSocket;
    procedure SendFireSerieSkill();
    function GetMagicByKey(Key: Char): PTClientMagic;
    function HeroGetMagicByID(magid: Integer): PTClientMagic;

    procedure UseMagic(tx, ty: Integer; pcm: PTClientMagic; boReacll: Boolean = False; boContinue: Boolean = False);
    function AttackTarget(target: TActor): Boolean;

    function IsRegisteredHotKey(HotKey: Cardinal): Boolean;
    function SurfaceCanFill(): Boolean;
    procedure ProcOnIdle;
    procedure AppOnIdle(Sender: TObject; var Done: Boolean);
    procedure DoFade();
    procedure QueryDynCode();
    procedure DrawGameNotice();
    procedure DrawMovingObject();
    procedure ReleaseImageCache();
    procedure ReleaseAllImageCache();
    procedure AppLogout;
    procedure AppLogoutEx;
    procedure AppExit;
    procedure SaveBagsData;
    procedure LoadBagsData;
    procedure PrintScreenNow;
    procedure ExchgScreen();
    procedure EatItem(idx: Integer);
    function EatItemName(Str: string): Boolean;
    procedure ActorAutoEat(Actor: THumActor);
    procedure HeroActorAutoEat(Actor: THumActor);
    procedure ActorCheckHealth(bNeedSP: Boolean);
    procedure HeroActorCheckHealth(bNeedSP: Boolean);
    procedure AutoSupplyBeltItem(nType, idx: Integer; sItem: string);
    procedure AutoSupplyBagItem(nType: Integer; sItem: string);
    procedure AutoUnBindItem(nType: Integer; sItem: string);
    procedure HeroEatItem(idx: Integer);
    procedure SmartChangePoison(pcm: PTClientMagic);
    procedure SendShoping(sItemName: string);
    procedure SendCDCheck();
    procedure SendPresend(sPlayer, sItemName: string);
    procedure SendQueryLevelRank(nPage, nType: Integer);
    procedure SendClientMessage(msg, Recog, param, tag, series: Integer);
    procedure SendNewAccount(ue: TUserEntry; ua: TUserEntryAdd);
    procedure SendBuildAcus(cr: TClientBuildAcus);
    procedure SendSelectServer(svname: string);
    procedure SendChgPw(ID, passwd, newpasswd: string);
    procedure SendNewChr(uid, uname, shair, sjob, ssex: string);
    procedure SendQueryChr;
    procedure SendDelChr(chrname: string);
    procedure SendSelChr(chrname: string);
    procedure SendRunLogin;
    procedure SendSay(Str: string);
    procedure SendActMsg(ident, X, Y, dir: Integer);
    procedure SendSpellMsg(ident, X, Y, dir, target: Integer; bLock: Boolean = True);
    procedure SendQueryUserName(targetid, X, Y: Integer);

    procedure SendDropItem(Name: string; itemserverindex, dropcnt: Integer);
    procedure SendHeroDropItem(Name: string; itemserverindex, dropcnt: Integer);
    procedure SendDismantleItem(Name: string; itemserverindex, dropcnt, hero: Integer);

    procedure SendPickup;
    procedure SendHeroSetTarget;
    procedure SendHeroSetGuard;
    procedure SendHeroJoinAttack;
    procedure SendItemSumCount(OrgItemIndex, ExItemIndex, hero: Integer; StrOrgItem, StrExItem: string);

    procedure SendOpenBox(OpenBoxItem: TOpenBoxItem);
    procedure SendSetSeriesSkill(Index, magid, hero: Integer);
    procedure SendTakeOnItem(where: BYTE; itmindex: Integer; itmname: string);
    procedure HeroSendTakeOnItem(where: BYTE; itmindex: Integer; itmname: string);
    procedure SendTakeOffItem(where: BYTE; itmindex: Integer; itmname: string);
    procedure HeroSendTakeOffItem(where: BYTE; itmindex: Integer; itmname: string);
    procedure SendEat(itmindex: Integer; itmname: string; nUnBindItem: Integer = 0);
    procedure SendHeroEat(itmindex: Integer; itmname: string; nType: Integer = 0; nUnBindItem: Integer = 0);
    procedure SendButchAnimal(X, Y, dir, actorid: Integer);
    procedure SendMagicKeyChange(magid: Integer; keych: Char);
    procedure SendHeroMagicKeyChange(magid: Integer; keych: Char);
    procedure SendMerchantDlgSelect(merchant: Integer; rstr: string);
    procedure SendQueryPrice(merchant, itemindex: Integer; itemname: string);
    procedure SendQueryRepairCost(merchant, itemindex: Integer; itemname: string);
    procedure SendQueryExchgBook(merchant, itemindex: Integer; itemname: string);

    procedure SendExchgBook(merchant, itemindex: Integer; itemname: string; count: Word);
    procedure SendSellItem(merchant, itemindex: Integer; itemname: string; count: Word);
    procedure SendSellItemList(merchant: Integer; ItemList: String);
    procedure SendRepairItem(merchant, itemindex: Integer; itemname: string);
    procedure SendStorageItem(merchant, itemindex: Integer; itemname: string; count: Word);
    procedure SendStorageItemView(merchant, itemindex: Integer; itemname: string; count: Word);
    procedure SendSelectItem(merchant, itemindex: Integer; itemname: string);
    procedure SendMaketSellItem(merchant, itemindex: Integer; price: string; count: Word);
    procedure SendGetDetailItem(merchant, menuindex: Integer; itemname: string; model: integer = 0);
    procedure SendBindItem(merchant, itemindex: Integer; itemname: string; idx: Word);

    procedure SendGetMarketPageList(merchant, pagetype: Integer; itemname: string);
    procedure SendBuyMarket(merchant, sellindex: Integer);
    procedure SendCancelMarket(merchant, sellindex: Integer);
    procedure SendGetPayMarket(merchant, sellindex: Integer);
    procedure SendMarketClose;

    procedure SendBuyItem(merchant, itemserverindex: Integer; itemname: string; conut: Word);
    procedure SendTakeBackStorageItem(merchant, itemserverindex: Integer; itemname: string; count: Word);
    procedure SendTakeBackStorageItemView(merchant, itemserverindex: Integer; itemname: string; count: Word);
    procedure SendMakeDrugItem(merchant: Integer; itemname: string);
    procedure SendDropGold(dropgold: Integer);
    procedure SendGroupMode(onoff: Boolean);
    procedure SendCreateGroup(withwho: string);
    procedure SendWantMiniMap;
    procedure SendGuildDlg;
    procedure SendDealTry;
    procedure SendCancelDeal;
    procedure SendAddDealItem(ci: TClientItem);
    procedure SendDelDealItem(ci: TClientItem);
    procedure SendChangeDealGold(gold: Integer);
    procedure SendDealEnd;
    procedure SendAddGroupMember(withwho: string);
    procedure SendDelGroupMember(withwho: string);
    procedure SendGuildHome;
    procedure SendGuildMemberList;
    procedure SendGuildAddMem(who: string);
    procedure SendGuildDelMem(who: string);
    procedure SendGuildUpdateNotice(notices: string);
    procedure SendGuildUpdateGrade(rankinfo: string);
    procedure SendSpeedHackUser;
    procedure SendAdjustBonus(remain: Integer; babil: TNakedAbility);
    procedure SendPassword(sPassword: string; nIdent: Integer);
    procedure SendRefineItems(cr: TClientRefineItems);
    procedure SendStallInfo(cr: TClientStallItems; cnt: Integer);

    procedure SendGetbackDelCharName(sName: string);
    procedure SendHeroItemToMasterBag(nMakeIdx: Integer; sItemName: string);
    procedure SendMasterItemToHeroBag(nMakeIdx: Integer; sItemName: string);
    function TargetInSwordLongAttackRange(ndir: Integer): Boolean;
    function TargetInSwordLongAttackRange2(sx, sy, dx, dy: Integer): Boolean;
    function TargetInSwordLongAttackRangeA(ndir: Integer): Boolean;
    function TargetInSwordLongAttackRangeX(ndir: Integer): Boolean;
    function TargetInSwordWideAttackRange(ndir: Integer): Boolean;
    function TargetInSwordCrsAttackRange(ndir: Integer): Boolean;
    procedure OnProgramException(Sender: TObject; E: Exception);
    procedure OnProgramRestore(Sender: TObject);
    procedure SendSocket(sendstr: string);
    procedure SendSocketCD(sendstr: string);
    function ServerAcceptNextAction: Boolean;
    function CanNextAction: Boolean;
    function CanNextHit(settime: Boolean = True): Boolean;
    function IsUnLockAction({Action, adir: Integer}): Boolean;
    procedure ActiveCmdTimer(cmd: TTimerCommand);
    function IsGroupMember(uname: string): Boolean;
    procedure SelectChr(sChrName: string);
    procedure OpenConfigDlg(boStatus: Boolean);

    function GetNpcImg(wAppr: Word; var WMImage: TWMImages): Boolean;
    function GetWStateImg(idx: Integer): TDirectDrawSurface; overload;
    function GetWStateImg(idx: Integer; var ax, ay: Integer): TDirectDrawSurface; overload;

    function GetWDnItemImg(idx: Integer): TDirectDrawSurface;
    function GetWBagItemImg(idx: Integer): TDirectDrawSurface; overload;
    function GetWBagItemImg(idx: Integer; var ax, ay: Integer): TDirectDrawSurface; overload;

    function GetWWeaponImg(Weapon, m_btSex, nFrame: Integer; var ax, ay: Integer; boUseCboLib: Boolean): TDirectDrawSurface;
    function GetWWeaponEffectImg(Actor: THumActor; Weapon, wShape, m_btSex, nFrame: Integer; var ax, ay: Integer; boUseCboLib: Boolean): TDirectDrawSurface;

    function GetWHumImg(Dress, m_btSex, nFrame: Integer; var ax, ay: Integer; boUseCboLib: Boolean): TDirectDrawSurface;
    procedure ProcessCommand(sData: string);
    function GetMagicByID(magid: Integer): PTClientMagic;
    procedure SwitchMiniMap();
    procedure AutoMove(TagX,TagY:  Integer); // 寻路
{$IF SERIESSKILL}procedure SeriesSkillFire();
{$IFEND SERIESSKILL}
    procedure InitSuiteStrs(Len: Integer; S: string);
    procedure DXDrawReInit();
    procedure ChgDisplayMode();
    function ProcessSmuggleData(pData: PChar; len: Integer): Boolean;
    procedure ProcessRunModule;
    procedure SendLoadModOk;
    procedure SendGateTick;
    procedure SendCaptchaRes(res: string);
  end;

  TSockMgr = class
  private
  protected
  public
    constructor Create(AOwner: TfrmMain);

  end;

procedure PomiTextOut(dsurface: TDirectDrawSurface; X, Y: Integer; Str: string);
procedure WaitAndPass(msec: LongWord);
function GetRGB(c256: BYTE): Integer;
procedure DebugOutStr(msg: string);
function GetMagicLv(Actor: TActor; magid: Integer): Integer;
function GetNextPosition(sx, sy, ndir, nFlag: Integer; var snx: Integer; var sny: Integer): Boolean;
function CheckMagPassThrough(sx, sy, tx, ty, ndir: Integer): Integer;
procedure GetNearPoint;
procedure LoadWayPoint;
procedure SaveWayPoint;
procedure ProcessMessagePacket();

var
  SockMgr: TSockMgr;
  frmMain: TfrmMain;

  g_boShowMemoLog: Boolean = False;
  g_boShowRecog: Integer = 0;
  DScreen: TDrawScreen;
  IntroScene: TIntroScene;
  LoginScene: TLoginScene;
  SelectChrScene: TSelectChrScene;
  g_PlayScene: TPlayScene;
  g_ShakeScreen: TShakeScreen;
  LoginNoticeScene: TLoginNotice;

  //MP3                       : TMPEG;
  EventMan: TClEventManager;
  Map: TMap;
  OneClickMode: TOneClickMode;
  m_boPasswordIntputStatus: Boolean = False;
  ShowMsgActor: TActor;

const
  g_Debugflname = '.\!debug.txt';

implementation

uses FState, wmUtil, CnHashTable, frmWebBroser, HeroActor, DxHint,
  MirThread, uThreadEx, VMProtectSDK, PatchUnit {, jwaWinCrypt, uWinTrust},
  MemLibrary, uFrmCaptcha;

{$R *.DFM}

function DecrypStr(Src, Key: string): string; //字符串解密函数
var
  KeyLen: Integer;
  KeyPos: Integer;
  offset: Integer;
  Dest: string;
  SrcPos: Integer;
  SrcAsc: Integer;
  TmpSrcAsc: Integer;
begin
  KeyLen := Length(Key);
  if KeyLen = 0 then
    Key := VMProtectDecryptStringA('legendsoft');
  KeyPos := 0;
  offset := StrToInt('$' + Copy(Src, 1, 2));
  SrcPos := 3;
  repeat
    SrcAsc := StrToInt('$' + Copy(Src, SrcPos, 2));
    if KeyPos < KeyLen then
      KeyPos := KeyPos + 1
    else
      KeyPos := 1;
    TmpSrcAsc := SrcAsc xor Ord(Key[KeyPos]);
    if TmpSrcAsc <= offset then
      TmpSrcAsc := 255 + TmpSrcAsc - offset
    else
      TmpSrcAsc := TmpSrcAsc - offset;
    Dest := Dest + Chr(TmpSrcAsc);
    offset := SrcAsc;
    SrcPos := SrcPos + 2;
  until SrcPos >= Length(Src);
  Result := Dest;
end;

constructor TSockMgr.Create(AOwner: TfrmMain);
begin
  with AOwner do
  begin
    tag := Random(High(Word));
    CSocket := TClientSocket.Create(AOwner);
    if isIPAddr(g_psServerAddr^) then
      CSocket.Address := g_psServerAddr^
    else
      CSocket.Host := g_psServerAddr^;
    CSocket.Port := g_pnServerPort^;

    CSocket.OnConnect := CSocketConnect;
    CSocket.OnDisconnect := CSocketDisconnect;
    CSocket.OnError := CSocketError;
    CSocket.OnRead := CSocketRead;

    CSocket1 := TClientSocket.Create(AOwner);
    CSocket1.OnConnect := CSocket1Connect;
    CSocket1.OnDisconnect := CSocket1Disconnect;
    CSocket1.OnError := CSocket1Error;
    CSocket1.OnRead := CSocket1Read;

    FEndeBuffer := VirtualAlloc(nil, 16 * 1024, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    pRecvBuffer := FRecvBuffer;
    RecvBufLen := 0;
  end;
end;

procedure DebugOutStr(msg: string);
var
  fhandle: TextFile;
begin
  g_csWriteLog.Enter;
  try
    try
      AssignFile(fhandle, g_Debugflname);
      if FileExists(g_Debugflname) then
      begin
        Append(fhandle);
      end
      else
      begin
        Rewrite(fhandle);
      end;
      Writeln(fhandle, DateTimeToStr(Now) + ' ' + msg);
      CloseFile(fhandle);
    except
  
    end;
  finally
    g_csWriteLog.Leave;
  end;
end;

procedure IStrings.SetTextStr(const Value: string);
var
  P, Start, pEnd: PChar;
  S: string;
begin
  BeginUpdate;
  try
    Clear;
    P := Pointer(Value);
    if P <> nil then
    begin
      pEnd := P + Length(Value);
      while P < pEnd do
      begin
        Start := P;
        while (P < pEnd) and not (P^ in [#10, #13]) do
          Inc(P);
        SetString(S, Start, P - Start);
        Add(S);
        if P^ = #13 then
          Inc(P);
        if P^ = #10 then
          Inc(P);
      end;
    end;
  finally
    EndUpdate;
  end;
end;

procedure PomiTextOut(dsurface: TDirectDrawSurface; X, Y: Integer; Str: string);
var
  i, n: Integer;
  d: TDirectDrawSurface;
begin
  for i := 1 to Length(Str) do
  begin
    n := BYTE(Str[i]) - BYTE('0');
    if n in [0..9] then
    begin
      d := g_WMainImages.Images[30 + n];
      if d <> nil then
        dsurface.Draw(X + i * 8, Y, d.ClientRect, d, True);
    end
    else
    begin
      if Str[i] = '-' then
      begin
        d := g_WMainImages.Images[40];
        if d <> nil then
          dsurface.Draw(X + i * 8, Y, d.ClientRect, d, True);
      end;
    end;
  end;
end;

procedure WaitAndPass(msec: LongWord);
var
  Start: LongWord;
begin
  Start := GetTickCount;
  while GetTickCount - Start < msec do
    Application.ProcessMessages;
end;

function GetRGB(c256: BYTE): Integer;
var
  iColor: Integer;
begin
  iColor := 0;
  with frmMain.DXDraw do
  begin
    iColor := RGB(DefColorTable[c256].rgbRed,
      DefColorTable[c256].rgbGreen,                      
      DefColorTable[c256].rgbBlue);
  end;
  if iColor = clFuchsia then  // 修改文字绘制错误 替换$FF00FF色  2019-11-30
  begin
    iColor := CONVERT_COLOR;
  end;
  Result := iColor;
end;

function KeyboardHookProc(Code: Integer; wParam: Integer; lParam: Integer): Longint; stdcall;
begin
  if ((wParam = VK_TAB) or (wParam = VK_F10)) then
  begin
    if (Code = HC_ACTION) and (lParam shr 31 = 0) then
    begin
      if (wParam = VK_TAB) then
      begin
        if FrmDlg.DLogin.Visible then
        begin
          if FocusedControl = FrmDlg.DxEditLoginID then
            SetDFocus(FrmDlg.DxEditPassword)
          else if FocusedControl = FrmDlg.DxEditPassword then
            SetDFocus(FrmDlg.DxEditLoginID);
        end
        else if FrmDlg.DNewAccount.Visible then
        begin
            if FocusedControl = FrmDlg.m_EdNewId then
              SetDFocus(FrmDlg.m_EdNewPasswd)
            else if FocusedControl = FrmDlg.m_EdNewPasswd then
              SetDFocus(FrmDlg.m_EdConfirm)
            else if FocusedControl = FrmDlg.m_EdConfirm then
              SetDFocus(FrmDlg.m_EdYourName)
            else if FocusedControl = FrmDlg.m_EdYourName then
            //  SetDFocus(FrmDlg.m_EdSSNo);
           // if FocusedControl = FrmDlg.m_EdSSNo then
              SetDFocus(FrmDlg.m_EdBirthDay)
            else if FocusedControl = FrmDlg.m_EdBirthDay then
              SetDFocus(FrmDlg.m_EdQuiz1)
            else if FocusedControl = FrmDlg.m_EdQuiz1 then
              SetDFocus(FrmDlg.m_EdAnswer1)
            else if FocusedControl = FrmDlg.m_EdAnswer1 then
              SetDFocus(FrmDlg.m_EdQuiz2)
            else if FocusedControl = FrmDlg.m_EdQuiz2 then
              SetDFocus(FrmDlg.m_EdAnswer2)
            else if FocusedControl = FrmDlg.m_EdAnswer2 then
              SetDFocus(FrmDlg.m_EdPhone)
            else if FocusedControl = FrmDlg.m_EdPhone then
              SetDFocus(FrmDlg.m_EdMobPhone)
            else if FocusedControl = FrmDlg.m_EdMobPhone then
              SetDFocus(FrmDlg.m_EdEMail)
            else if FocusedControl = FrmDlg.m_EdEMail then
            begin
              if FrmDlg.m_EdNewId.Enabled then
                SetDFocus(FrmDlg.m_EdNewId)
              else if FrmDlg.m_EdNewPasswd.Enabled then
                SetDFocus(FrmDlg.m_EdNewPasswd);
            end; 
        end
        else if FrmDlg.DChgPw.Visible then
        begin
            if FocusedControl = FrmDlg.m_EdChgId then
              SetDFocus(FrmDlg.m_EdChgCurrentpw)
            else if FocusedControl = FrmDlg.m_EdChgCurrentpw then
              SetDFocus(FrmDlg.m_EdChgNewPw)
            else if FocusedControl = FrmDlg.m_EdChgNewPw then
              SetDFocus(FrmDlg.m_EdChgRepeat)
            else if FocusedControl = FrmDlg.m_EdChgRepeat then
              SetDFocus(FrmDlg.m_EdChgId);
        end
        else if g_MySelf <> nil then
        begin
          frmMain.SwitchMiniMap();
        end;
      end;
      if (wParam = VK_F10) then
      begin
        if (g_MySelf <> nil) then
        begin
          FrmDlg.StatePage := 0;
          FrmDlg.OpenMyStatus;
          frmMain.SetFocus;
        end;
        Result := 1;
        Exit;
      end;
    end;
  end;
  Result := CallNextHookEx(g_ToolMenuHook, Code, wParam, lParam);
end;

procedure TfrmMain.ChgDisplayMode();
var
  DeviceMode: TDeviceMode;
  DisplayFrequency: Integer;
begin
  if g_boFullScreen then  Exit;

  if GetDeviceCaps(GetDC(0), BITSPIXEL) = 16 then
    Exit;

  DisplayFrequency := GetDeviceCaps(GetDC(0), VREFRESH);
  with DeviceMode do
  begin
    dmSize := SizeOf(DeviceMode);
    dmBitsPerPel := 16;
    dmFields := DM_BITSPERPEL or DM_DISPLAYFREQUENCY;
    dmDisplayFrequency := DisplayFrequency;
  end;
  ChangeDisplaySettings(DeviceMode, 0);
end;


procedure TfrmMain.FormCreate(Sender: TObject);
var
  n: Integer;
  flib: string;
  ini: TIniFile;
  fhandle: Integer;
  tempRcHeader: TRcHeader;
  S: IStrings;
  CPU: TCPUInfo;

  DllModule: THandle;

  PFunc: Pointer;
  pf: PChar;

  {boFileTrust               : Boolean;
  hCatAdminContext          : HCatAdmin;
  WTrustData                : WINTRUST_DATA;
  WTDCatalogInfo            : WINTRUST_CATALOG_INFO;
  WTDFileInfo               : WINTRUST_FILE_INFO;
  CatalogInfo               : CATALOG_INFO;

  hFile                     : THandle;
  hCatalogContext           : THandle;

  swFilename                : WideString;
  swMemberTag               : WideString;

  ilRet                     : Longint;
  X                         : Integer;}

begin
  canReDraw := True;

//    OutputDebugString('xxxx');

{$I '..\Common\Macros\VMPBU.inc'}
{$IFNDEF DEBUG_LOGIN}


  {boFileTrust := False;

  sFilename := ParamStr(0);

  //String in Widestring wandeln
  swFilename := sFilename;

  ZeroMemory(@CatalogInfo, SizeOf(CatalogInfo));
  ZeroMemory(@WTDFileInfo, SizeOf(WTDFileInfo));
  ZeroMemory(@WTDCatalogInfo, SizeOf(WTDCatalogInfo));
  ZeroMemory(@WTrustData, SizeOf(WTrustData));

  try
    //Catalog Admin Kontext &ouml;ffnen und falls nicht m&ouml;glich Prozedur verlassen
    if CryptCATAdminAcquireContext(@hCatAdminContext, nil, 0) = False then
      Exit;

    //Filehandle auf die zu prüfende Datei holen
    hFile := CreateFile(PChar(string(sFilename)), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

    //Wenn das Handle nicht erhalten wurde Prozedur verlassen
    if hFile = INVALID_HANDLE_VALUE then Exit;

    //iaBytescount nach gr&ouml;&szlig;e des Arrays setzen
    iByteCount := SizeOf(aByteHash);

    //ByteArray mit Hash füllen lassen und die Gr&ouml;&szlig;e in iByteCount bekommen
    CryptCATAdminCalcHashFromFileHandle(hFile, @iByteCount, @aByteHash, 0);

    // MemberTag brechnen (vom ByteArray auf HEX)
    for X := 0 to iByteCount - 1 do begin
      swMemberTag := swMemberTag + IntToHex(aByteHash[X], 2);
    end;

    //FileHandle schlie&szlig;en - wird nicht mehr gebraucht
    CloseHandle(hFile);

    //Erste Prüfung erfolgt mit WINTRUST_DATA.dwUnionChoice := WTD_CHOICE_CATALOG;
    //also muss WINTRUST_CATALOG_INFO gefüllt werden
    //
    //Handle auf den Katalog Kontext holen
    hCatalogContext := CryptCATAdminEnumCatalogFromHash(hCatAdminContext, @aByteHash, iByteCount, 0, nil);

    //Wenn das Handle 0 ist muss die Prüfung mit der
    //WINTRUST_DATA.dwUnionChoice := WTD_CHOICE_FILE; Struktur durchgeführt werden
    if hCatalogContext = 0 then begin
      //CatalogContext = 0 also
      //
      //WINTRUST_FILE_INFO Struktur initialisieren und füllen
      WTDFileInfo.cbStruct := SizeOf(WTDFileInfo);
      WTDFileInfo.pcwszFilePath := PWideChar(swFilename);
      WTDFileInfo.pgKnownSubject := nil;
      WTDFileInfo.hFile := 0;

      //WINTRUST_DATA Struktur initialisieren und füllen
      WTrustData.cbStruct := SizeOf(WTrustData);
      WTrustData.dwUnionChoice := WTD_CHOICE_FILE; //WINTRUST_FILE_INFO Struktur w&auml;hlen
      WTrustData.pWTDINFO := @WTDFileInfo; //Pointer zu WINTRUST_FILE_INFO
      WTrustData.dwUIChoice := WTD_UI_NONE;
      WTrustData.fdwRevocationChecks := WTD_REVOKE_NONE;
      WTrustData.dwStateAction := WTD_STATEACTION_IGNORE;
      WTrustData.dwProvFlags := WTD_SAFER_FLAG; //UI bei XP SP2 unterbinden
      WTrustData.hWVTStateData := 0;
      WTrustData.pwszURLReference := nil;
    end
    else begin
      //CatalogContext <> 0 also CATALOG_INFO benutzen
      //
      //CATALOG_INFO Struktur füllen
      CryptCATCatalogInfoFromContext(hCatalogContext, @CatalogInfo, 0);

      //WINTRUST_CATALOG_INFO Struktur initialisieren und füllen
      WTDCatalogInfo.cbStruct := SizeOf(WTDCatalogInfo);
      WTDCatalogInfo.pcwszCatalogFilePath := CatalogInfo.sCatalogFile;
      WTDCatalogInfo.pcwszMemberFilePath := PWideChar(swFilename);
      WTDCatalogInfo.pcwszMemberTag := PWideChar(swMemberTag);

      //WINTRUST_DATA Struktur initialisieren und füllen
      WTrustData.cbStruct := SizeOf(WTrustData);
      WTrustData.dwUnionChoice := WTD_CHOICE_CATALOG; //WINTRUST_CATALOG_INFO Struktur w&auml;hlen
      WTrustData.pWTDINFO := @WTDCatalogInfo; //Pointer zu WINTRUST_CATALOG_INFO
      WTrustData.dwUIChoice := WTD_UI_NONE;
      WTrustData.fdwRevocationChecks := WTD_REVOKE_NONE;
      WTrustData.pPolicyCallbackData := nil;
      WTrustData.pSIPClientData := nil;
      WTrustData.dwStateAction := WTD_STATEACTION_VERIFY;
      WTrustData.dwProvFlags := 0;      //WTD_SAFER_FLAG; //UI bei XP SP2 unterbinden
      WTrustData.hWVTStateData := 0;
      WTrustData.pwszURLReference := nil;
    end;

    //WinVerifyTrust aufrufen um die Prüfung durchzuführen
    ilRet := WinVerifyTrust(INVALID_HANDLE_VALUE, @WINTRUST_ACTION_GENERIC_VERIFY_V2, @WTrustData);

    //Wenn Erg. 0 ist dann ist das File Trusted - alle anderen Werte sind Fehlercodes
    boFileTrust := ilRet = 0;

    // 释放
    WTrustData.dwStateAction := WTD_STATEACTION_CLOSE;
    WinVerifyTrust(INVALID_HANDLE_VALUE,
      @WINTRUST_ACTION_GENERIC_VERIFY_V2,
      @WTrustData);
  finally
    if hCatAdminContext > 0 then begin
      if hCatalogContext > 0 then       //Handle zum Catalogfile schlie&szlig;en
        CryptCATAdminReleaseCatalogContext(hCatAdminContext, hCatalogContext, 0);

      //Catalog Admin Kontext schlie&szlig;en
      CryptCATAdminReleaseContext(hCatAdminContext, 0);
    end;
  end;

  if not boFileTrust then begin
    MouseTimer.Free;
    WaitMsgTimer.Free;
    SelChrWaitTimer.Free;
    CmdTimer.Free;
    MinTimer.Free;
    DXDraw.Free;
    TimerAutoMagic.Free;
    TimerHeroActor.Free;
    TimerAutoMove.Free;
    TimerAutoPlay.Free;
    TimerPacket.Free;
    Self.Free;
    ExitProcess(0);
    Exit;
  end;}
{$ENDIF}

{$IFNDEF CD}

  m_NoticeOk := False;
  m_loadcount := 0;
  SetLength(m_rungatemod, 1024 * 1024);
{$ENDIF}

  FVCLUnZip := TVCLUnZip.Create(nil);
  InitScreenConfig();
  DCP_mars := TDCP_mars.Create(nil);
  DllModule := LoadLibrary(VMProtectDecryptStringA('WS2_32.dll'));
  if DllModule > 32 then
  begin
    PFunc := GetProcAddress(DllModule, VMProtectDecryptStringA('send'));
    //8B FF 55 8B EC
    if PFunc <> nil then
    begin
      pf := PChar(PFunc);
      for n := 0 to 4 do
        g_pWsockAddr[n] := BYTE(pf[n]);
    end;
    FreeLibrary(DllModule);
  end;

{$IF FAKELOADLIB}
  DllModule := LoadLibrary(VMProtectDecryptStringA('kernel32.dll'));
  if DllModule <> 0 then
  begin
    rawLoadLibraryExW := GetProcAddress(DllModule, VMProtectDecryptStringA('LoadLibraryExW'));
  end;

  FillChar(user32ModInfo, SizeOf(user32ModInfo), 0);
  GetModuleInformation(GetCurrentProcess(), GetModuleHandle(VMProtectDecryptStringA('user32.dll')), @user32ModInfo, SizeOf(user32ModInfo));
  m_dwUser32Low := DWORD(user32ModInfo.lpBaseOfDll);
  m_dwUser32Hi := DWORD(user32ModInfo.lpBaseOfDll) + user32ModInfo.SizeOfImage;
  m_dwUser32 := ULONG(GetModuleHandle(VMProtectDecryptStringA('user32.dll')));
{$IFEND FAKELOADLIB}

  g_pkeywords := NewStr(''); // ++++++++ 2019-09-20

  g_bLoginKey^ := True; // false->ture 2019-09-20
  g_pbInitSock^ := False;
  //g_FilePath := Trim(ExtractFilePath(ParamStr(1)));
  //MessageBox(0, PChar(g_FilePath), nil, 0);

  ScreenChanged();

  S := IStrings.Create;
  try
    Sleep(60);
    //S.LoadFromFile(Application.ExeName);
{$IF CHECKPACKED}
    {if Pos('FontName', S.Text) <> 0 then begin
      ExitProcess(0);
      self.free;
end else}{$IFEND CHECKPACKED}begin
      g_APPathList := TList.Create;

      flib := ChangeFileExt('.\' + ExtractFileName(ParamStr(0)), '.lib');
{$IFDEF TEST}
      fhandle := FileOpen(ExtractFilePath(ParamStr(0)) + '\XX.LIB', fmOpenRead or fmShareDenyNone);
{$ELSE}
      fhandle := FileOpen(flib, fmOpenRead or fmShareDenyNone);
{$ENDIF }
      FileSeek(fhandle, -SizeOf(TRcHeader), 2);
      FileRead(fhandle, tempRcHeader, SizeOf(TRcHeader));

      DCP_mars.InitStr(VMProtectDecryptStringA('mir2'));
      FillChar(g_pRcHeader^, SizeOf(TRcHeader), #0);
      DCP_mars.DecryptCFB8bit(tempRcHeader, g_pRcHeader^, SizeOf(TRcHeader));

{$IFDEF TEST}
      // add 2019-09-27
      g_pRcHeader^.sCompany := 'qhs';
      g_pRcHeader^.sFileName := '';
      g_pRcHeader^.sWebLink := '';
      g_pRcHeader^.sWebSite := 'www.qhs.com';
      g_pRcHeader^.sBbsSite := '';
      g_pRcHeader^.sSiteUrl := '';

      DCP_mars.InitStr(VMProtectDecryptStringA('sWebSite'));
      g_pRcHeader^.sWebSite := DCP_mars.EncryptString(g_pRcHeader.sWebSite);
{$ELSE}
      // add 2019-09-27
      g_pRcHeader^.sCompany := 'qhs';
      g_pRcHeader^.sFileName := '';
      g_pRcHeader^.sWebLink := '';
      g_pRcHeader^.sWebSite := 'www.qhs.com';
      g_pRcHeader^.sBbsSite := '';
      g_pRcHeader^.sSiteUrl := '';

      DCP_mars.InitStr(VMProtectDecryptStringA('sWebSite'));
      g_pRcHeader^.sWebSite := DCP_mars.EncryptString(g_pRcHeader.sWebSite);
{$ENDIF }

{$IF CHECKPACKED}
      DCP_mars.InitStr(VMProtectDecryptStringA('Purple'));

      if True then // zzzz CompareText(DCP_mars.DecryptString(g_pRcHeader^.sPathAdress[3]), VMProtectDecryptStringA('B585F03430A40F200A')) = 0
      begin
{$IFEND CHECKPACKED}
        g_pbInitSock^ := True;
        FileClose(fhandle);

        g_ShowItemList := THStringList.Create;
        g_DWinMan := TDWinManager.Create(Self);

        InitIPNeedExps();

        Randomize;
        ini := TIniFile.Create('.\lscfg.ini');
        g_sCurFontName := ini.ReadString('Setup', 'FontName', g_sCurFontName);
        g_sCurFontName := '宋体';
{$IFNDEF TEST}
        g_boFullScreen := ini.ReadBool('Setup', 'FullScreen', g_boFullScreen);
{$ENDIF}
        g_gcGeneral[11] := ini.ReadBool('Setup', 'EffectSound', True);
        g_gcGeneral[12] := ini.ReadBool('Setup', 'EffectBKGSound', g_gcGeneral[12]);
        g_lWavMaxVol := ini.ReadInteger('Setup', 'EffectSoundLevel', g_lWavMaxVol);

        MICRO_ADDRESS := ini.ReadString('Setup', 'MicroAddress', '');
        MICRO_PORT := ini.ReadInteger('Setup', 'MicroPort', 0);
        g_ShowClientVersion := Ini.ReadBool('Setup', 'ShowCoreVersion', False);

{$IF MIR2EX}
        ChgDisplayMode();
{$IFEND MIR2EX}
        //LoadC16BitPalette();

        SSE_AVAILABLE := False;
        try
          CPU := CPUInfoMin.GetCPUInfo();
          if CPU.MMX and CPU.SSE and CPU.SSE2 then
            SSE_AVAILABLE := True;
        except
          SSE_AVAILABLE := False;
        end;

        if g_boFullScreen then
        begin
          Self.BorderStyle := bsNone;
          Self.Left := 0;
          Self.Top := 0;
          DXDraw.Options := DXDraw.Options + [doFullScreen];
          DXDraw.Options := DXDraw.Options - [doFlip];
        end
        else
        begin
          Self.BorderStyle := bsSingle;
          Self.Left := ini.ReadInteger('Positions', 'Left', 100);
          Self.Top := ini.ReadInteger('Positions', 'Top', 100);

          Self.ClientWidth := SCREENWIDTH;
          Self.ClientHeight := SCREENHEIGHT;

          DXDraw.Options := DXDraw.Options - [doFullScreen];
          DXDraw.Options := DXDraw.Options - [doFlip];
        end;

        ini.Free;


        {FHardwareSwitch := False;
        if FHardwareSwitch then begin
          if not (doDirectX7Mode in DXDraw.Options) then
            DXDraw.Options := DXDraw.Options + [doDirectX7Mode];
          if not (doHardware in DXDraw.Options) then
            DXDraw.Options := DXDraw.Options + [doHardware];
          if not (do3D in DXDraw.Options) then
            DXDraw.Options := DXDraw.Options + [do3D];
          if doSystemMemory in DXDraw.Options then
            DXDraw.Options := DXDraw.Options - [doSystemMemory];
        end else begin
          if do3D in DXDraw.Options then
            DXDraw.Options := DXDraw.Options - [do3D];
          if doHardware in DXDraw.Options then
            DXDraw.Options := DXDraw.Options - [doHardware];
          if not (doSystemMemory in DXDraw.Options) then
            DXDraw.Options := DXDraw.Options + [doSystemMemory];
          if doDirectX7Mode in DXDraw.Options then
            DXDraw.Options := DXDraw.Options - [doDirectX7Mode];
        end;}



        g_DXDraw := DXDraw;

        g_ToolMenuHook := SetWindowsHookEx(WH_KEYBOARD, @KeyboardHookProc, 0, GetCurrentThreadId);

        DScreen := TDrawScreen.Create;
        IntroScene := TIntroScene.Create;
        LoginScene := TLoginScene.Create;
        SelectChrScene := TSelectChrScene.Create;
        g_PlayScene := TPlayScene.Create;
        g_ShakeScreen := TShakeScreen.Create;
        LoginNoticeScene := TLoginNotice.Create;


        DXDraw.Display.Width := SCREENWIDTH;
        DXDraw.Display.Height := SCREENHEIGHT;
        DXDraw.SurfaceWidth := SCREENWIDTH;
        DXDraw.SurfaceHeight := SCREENHEIGHT;



        LoadWMImagesLib(nil);

        NpcImageList := TList.Create;
        ItemImageList := TList.Create;
        WeaponImageList := TList.Create;
        HumImageList := TList.Create;
        g_FileCustomList_Client := TStringList.Create;
        g_SafeZoneEffectCustomList := TList.Create;
        g_NpcCustomList := TList.Create;
        {try
          g_DXSound := TDXSound.Create(Self); //g_DXSound.Options := [soGlobalFocus];
          g_DXSound.Initialize;
          if g_DXSound.Initialized then begin
            g_Sound := TSoundEngine.Create(g_DXSound.DSound);
            MP3 := TMPEG.Create(Self);
          end else begin
            g_Sound := nil;
            MP3 := nil;
          end;
        except
        end;}

        //g_SoundList := TStringlist.Create;
        //BGMusicList := TStringlist.Create;
        //flname := '.\wav\sound2.lst';
        //LoadSoundList(flname);
        //flname := '.\wav\BGList.lst';
        //LoadBGMusicList(flname);

        g_SndMgr := TSoundMgr.Create(Self.Handle);
        g_SndMgr.volume := Round(g_lWavMaxVol / 68 * 100);
        g_SndMgr.Silent := not g_gcGeneral[11];

        Map := TMap.Create;
        SockMgr := TSockMgr.Create(Self);
        g_DropedItemList := TList.Create;
        g_MagicList := TList.Create;
{$IF SERIESSKILL}
        g_MagicList2 := TList.Create;
        g_hMagicList2 := TList.Create;
{$IFEND SERIESSKILL}
        g_IPMagicList := TList.Create;
        g_HeroMagicList := TList.Create;
        g_HeroIPMagicList := TList.Create;
        for n := Low(g_ShopListArr) to High(g_ShopListArr) do
          g_ShopListArr[n] := TList.Create;
        g_FreeActorList := TList.Create;

        EventMan := TClEventManager.Create;
        g_ChangeFaceReadyList := TList.Create;
        g_ServerList := TStringlist.Create;
        g_SendSayList := TStringlist.Create;
        if g_MySelf <> nil then
        begin
          g_MySelf.m_HeroObject := nil;
          g_MySelf.m_SlaveObject.Clear;
          g_MySelf := nil;
        end;
        g_ItemSell := TList.Create;

        InitClientItems();

        g_DetectItemMineID := 0;
        g_BAFirstShape := -1;
        g_BuildAcusesSuc := -1;
        g_BuildAcusesStep := 0;
        g_BuildAcusesProc := 0;
        g_BuildAcusesRate := 0;

        g_SaveItemList := TList.Create;
        g_MenuItemList := TList.Create;
        g_DetectItem.S.Name := '';
        g_WaitingUseItem.Item.S.Name := '';
        g_WaitingDetectItem.Item.S.Name := '';
        g_WaitingStallItem.Item.S.Name := '';
        g_OpenBoxItem.Item.S.Name := '';
        g_EatingItem.S.Name := '';
        FPrintScreenNow := False;
        FExchgScreen := False;

        g_nLastMapMusic := -1;
        g_nTargetX := -1;
        g_nTargetY := -1;
        g_TargetCret := nil;
        g_FocusCret := nil;
        g_FocusItem := nil;
        g_MagicTarget := nil;
        g_nDebugCount := 0;
        g_nDebugCount1 := 0;
        g_nDebugCount2 := 0;
        g_nTestSendCount := 0;
        g_nTestReceiveCount := 0;
        g_boServerChanging := False;
        g_boBagLoaded := False;
        g_nHeroBagSize := 10;
        g_boAutoDig := False;
        g_boAutoSit := False;

        g_dwLatestClientTime2 := 0;
        g_dwFirstClientTime := 0;
        g_dwFirstServerTime := 0;
        g_dwFirstClientTimerTime := 0;
        g_dwLatestClientTimerTime := 0;
        g_dwFirstClientGetTime := 0;
        g_dwLatestClientGetTime := 0;

        g_nTimeFakeDetectCount := 0;
        g_nTimeFakeDetectTimer := 0;
        g_nTimeFakeDetectSum := 0;
        g_nDayBright := 3;
        g_nAreaStateValue := 0;
        g_ConnectionStep := cnsIntro;
        g_boSendLogin := False;
        g_boServerConnected := False;
        SocStr := '';
        ActionFailLock := False;
        g_boMapMoving := False;
        g_boMapMovingWait := False;
        g_boCheckBadMapMode := False;
        g_boCheckSpeedHackDisplay := False;
        g_boViewMiniMap := False;
        //FailDir := 0;
        //FailAction := 0;
        g_nDupSelection := 0;

        g_dwLastAttackTick := GetTickCount;
        g_dwLastMoveTick := GetTickCount;
        g_dwLatestSpellTick := GetTickCount;

        g_dwAutoPickupTick := GetTickCount;
        g_boFirstTime := True;
        g_boItemMoving := False;
        g_boDoFadeIn := False;
        g_boDoFadeOut := False;
        g_boDoFastFadeOut := False;
        g_boNextTimePowerHit := False;
        g_boCanLongHit := False;
        g_boCanWideHit := False;
        g_boCanCrsHit := False;
        g_boNextTimeFireHit := False;
        g_boCanSLonHit := False;
        g_boNextTimeTwinHit := False;
        g_boNextTimePursueHit := False;

        g_boNextTimeRushHit := False;
        g_boNextTimeSmiteHit := False;
        g_boNextTimeSmiteLongHit := False;
        g_boNextTimeSmiteLongHit3 := False;
        g_boNextTimeSmiteLongHit2 := False;
        g_boNextTimeSmiteWideHit := False;
        g_boNextTimeSmiteWideHit2 := False;

        g_boNoDarkness := False;
        g_boQueryPrice := False;
        g_sSellPriceStr := '';

        g_boAllowGroup := False;
        g_GroupMembers := THStringList.Create;
        g_SeriesSkillSelList := TStringlist.Create;
        g_hSeriesSkillSelList := TStringlist.Create;

        g_ItemDesc := THStringList.Create;
        LoadItemDesc();

        LoadItemFilter();
        LoadMapDesc();
        g_MainHWnd := Self.Handle;
        MainWinHandle := DXDraw.Handle;

        OneClickMode := toNone;

{$IF CHECKPACKED}
      end;
{$IFEND CHECKPACKED}
      FileClose(fhandle);
{$IF CHECKPACKED}
      try
        DeleteFile(flib);
      except
      end;
{$IFEND CHECKPACKED}
    end;
  finally
    S.Free;
  end;
{$I '..\Common\Macros\VMPE.inc'}

{$IF MIR2EX}
  DXDraw.Display.BitCount := 16;
{$ELSE}
  DXDraw.Display.BitCount := 8;
{$IFEND MIR2EX}

{$I '..\Common\Macros\VMPB.inc'}
  m_dwMouseDownTime := 0;
  m_boMouseUpEnAble := True;
  g_Market := TMarketItemManager.Create;
  g_DXFontsManager := TDXFontsManager.Create;

  {
  nPort := -1;
  szIP := '';
  ini := TIniFile.Create('.\lscfg.ini');
  try
    szParamStr := ini.ReadString(VMProtectDecryptStringA('Setup'), VMProtectDecryptStringA('LoginHost'), '');
    if szParamStr <> '' then begin
      szParamStr := DecrypStr(szParamStr, '');
      if szParamStr <> '' then begin
        szParamStr := GetValidStr3(szParamStr, szLine, ['|']);
        if szLine <> '' then begin
          szLine := GetValidStr3(szLine, szIP, [':']);
          szLine := GetValidStr3(szLine, szPort, [':']);
          nPort := Str_ToInt(szPort, -1);
        end;
      end;
    end;
  finally
    ini.Free;
  end;
  if (nPort >= 0) and (nPort <= 65535) and IsIPaddr(szIP) then begin
    CSocket.Address := szIP;
    CSocket.Port := nPort;
  end else begin
    CSocket.Address := g_psServerAddr^;
    CSocket.Port := g_pnServerPort^;
  end;
  }
{$IFDEF TEST}
  if isIPAddr(TEST_MODE_SERVER) then
    CSocket.Address := TEST_MODE_SERVER       // 127.0.0.1
  else
    CSocket.Host := TEST_MODE_SERVER;
  CSocket.Port := TEST_MODE_PORT;
{$ELSE}
  if (ParamStr(1) = '') or (ParamStr(2) = '') then
  begin
    halt; //没有读出参数就强退 
  end;
  //outputDebugString(pchar('ParamStr[1]:'+ParamStr(1)));
  //outputDebugString(pchar('ParamStr[2]:'+ParamStr(2)));
  if isIPAddr(ParamStr(1)) then
    CSocket.Address := ParamStr(1)
  else
    CSocket.host := ParamStr(1);
  CSocket.Port := strtoint(ParamStr(2));
{$ENDIF}
  if g_pbInitSock^ then
  begin
    CSocket.Active := True;

    try
      g_ModuleDetect := TModuleDetect.Create();
    finally
      g_ModuleDetect.Resume;
    end;
  end
  else if CSocket.Active then
    CSocket.Active := False;

  {if g_pbInitSock^ then begin
    g_GameGuard := TGameGuard.Create();

    DScreen.ChangeScene(stIntro);
    DXDraw.Cursor := crDefault;
    MouseTimer.Enabled := True;
    g_boProcMessagePacket := True;

    CSocket.Active := True;
  end else if CSocket.Active then
    CSocket.Active := False;}

  Application.OnException := OnProgramException;
  Application.OnIdle := AppOnIdle;
  Application.OnRestore := OnProgramRestore;

{$I '..\Common\Macros\VMPE.inc'}

end;

procedure TfrmMain.OnProgramException(Sender: TObject; E: Exception);
begin
  DebugOutStr(E.Message);
end;

procedure TfrmMain.OnProgramRestore(Sender: TObject);
begin
  if frmMain.WindowState <> wsNormal then
    frmMain.WindowState := wsNormal;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
var
  i: Integer;
  p: pTClientSafeZoneEffectCustomPackage;
  p1: pTClientNpcCustomPackage;
begin
  //try
{$IF MIR2EX}
  //if not g_boFullScreen and g_BitSperpelChanged then
  //  g_BitSperpelChanged := ChangeDisplaySettings(DEVMODE(nil^), 0) = DISP_CHANGE_SUCCESSFUL;
{$IFEND}

  //UnInitPreHook();

  {if g_ModuleDetect <> nil then begin
    g_ModuleDetect.Terminate;
    g_ModuleDetect.Free;
  end;}

  {if g_DXImageRun <> nil then begin
    g_DXImageRun.Terminate;
    g_DXImageRun.Free;
  end;}
  g_ShowItemList.Free;

  if g_ToolMenuHook > 0 then
    UnhookWindowsHookEx(g_ToolMenuHook);
  //if g_ToolMenuHookLL <> 0 then UnhookWindowsHookEx(g_ToolMenuHookLL);

  TimerPacket.Enabled := False;
  MinTimer.Enabled := False;

  UnLoadWMImagesLib();

  for i := 0 to NpcImageList.count - 1 do
    TWMImages(NpcImageList.Items[i]).Finalize;
  for i := 0 to ItemImageList.count - 1 do
    TWMImages(ItemImageList.Items[i]).Finalize;
  for i := 0 to WeaponImageList.count - 1 do
    TWMImages(WeaponImageList.Items[i]).Finalize;
  for i := 0 to HumImageList.count - 1 do
    TWMImages(HumImageList.Items[i]).Finalize;

  DScreen.Finalize;
  g_PlayScene.Finalize;
  LoginNoticeScene.Finalize;
  if Dscreen <> nil then
    DScreen.Free;
  IntroScene.Free;
  LoginScene.Free;
  SelectChrScene.Free;
  g_PlayScene.Free;
  g_ShakeScreen.Free;
  LoginNoticeScene.Free;
  g_SaveItemList.Free;
  g_MenuItemList.Free;

  Map.Free;
  g_DropedItemList.Free;
  g_MagicList.Free;
  g_IPMagicList.Free;
{$IF SERIESSKILL}
  g_MagicList2.Free;
  g_hMagicList2.Free;
{$IFEND SERIESSKILL}
  g_HeroMagicList.Free;
  g_HeroIPMagicList.Free;
  for i := Low(g_ShopListArr) to High(g_ShopListArr) do
    g_ShopListArr[i].Free;
  g_FreeActorList.Free;
  g_ChangeFaceReadyList.Free;
  g_Market.Free;

  //g_DXImageManager.Free;
  g_DXFontsManager.Free;

  g_GroupMembers.Free;
  g_SeriesSkillSelList.Free;
  g_hSeriesSkillSelList.Free;

  g_ServerList.Free;
  g_SendSayList.Free;
  //g_Sound.Free;
  //g_SoundList.Free;
  //BGMusicList.Free;

  g_SndMgr.Terminate;
  g_SndMgr.WaitFor;
  g_SndMgr.Free;

  EventMan.Free;
  NpcImageList.Free;
  ItemImageList.Free;
  WeaponImageList.Free;
  HumImageList.Free;
  if g_FileCustomList_Client <> nil then
  begin
    g_FileCustomList_Client.Clear;
    g_FileCustomList_Client.Free;
    g_FileCustomList_Client := nil;
  end;

  if g_SafeZoneEffectCustomList <> nil then
  begin
    for i := 0 to (g_SafeZoneEffectCustomList.Count - 1) do
    begin
      P := g_SafeZoneEffectCustomList.Items[i];
      Dispose(P);
    end;
    g_SafeZoneEffectCustomList.Clear;
    g_SafeZoneEffectCustomList := nil;
  end;

  if g_NpcCustomList <> nil then
  begin
    for i := 0 to (g_NpcCustomList.Count - 1) do
    begin
      P1 := g_NpcCustomList.Items[i];
      Dispose(P1);
    end;
    g_NpcCustomList.Clear;
    g_NpcCustomList := nil;
  end;
  g_ItemSell.Free;
  //g_DXSound.Free;
  g_DWinMan.Free;
  {except
    on E: Exception do
      DebugOutStr(E.Message);
  end;}
  DDClipper.Free;
end;

{$IF FAKELOADLIB}

function newLoadLibraryExW(lpLibFileName: PWideChar; hFile: THandle; dwFlags: DWORD): HMODULE; stdcall;
var
  dwCaller: DWORD;
begin
  asm
    push dword ptr [ebp+4]
    pop  dword ptr [dwCaller]
  end;
{$I '..\Common\Macros\VMPB.inc'}
  if (dwCaller > m_dwUser32Low) and (dwCaller < m_dwUser32Hi) then
  begin
    //if s <> '' then DebugOutStr('-----: ' + s);
    Result := 0;
    Exit;
  end;
  //if s <> '' then DebugOutStr(s);

  Result := rawLoadLibraryExW(lpLibFileName, hFile, dwFlags);
{$I '..\Common\Macros\VMPE.inc'}
end;
{$IFEND FAKELOADLIB}

function ComposeColor(Dest, Src: TRGBQuad; Percent: Integer): TRGBQuad;
begin
  with Result do
  begin
    rgbRed := Src.rgbRed + ((Dest.rgbRed - Src.rgbRed) * Percent div 256);
    rgbGreen := Src.rgbGreen + ((Dest.rgbGreen - Src.rgbGreen) * Percent div 256);
    rgbBlue := Src.rgbBlue + ((Dest.rgbBlue - Src.rgbBlue) * Percent div 256);
    rgbReserved := 0;
  end;
end;

{function TfrmMain.CreateGameFontA(szFontName: PChar;
  nHeight: Integer;
  nWidth: Integer;
  nWeight: Integer;
  bItalic: DWORD;
  bULine: DWORD;
  bStrikeOut: DWORD;
  dwCharSet: DWORD): HFONT;
var
  lf                        : TLogFont;
  DC                        : HDC;
begin
  DC := GetDC(0);
  FillChar(lf, SizeOf(lf), #0);
  lf.lfHeight := -MulDiv(nHeight, GetDeviceCaps(DC, LOGPIXELSY), 72);
  lf.lfWidth := 0;
  lf.lfCharSet := dwCharSet;
  lf.lfFaceName := '宋体';
  ReleaseDC(0, DC);
  Result := CreateFontIndirect(lf);
end;}

procedure TfrmMain.DXDrawonWindowMove(Sender: TObject);
begin
  {with frmWebBrowser do
    if Showing then begin
      Left := frmMain.Width - frmMain.ClientWidth + frmMain.Left - 3;
      Top := frmMain.Height - frmMain.ClientHeight + frmMain.Top - 3;
    end;}
end;

procedure LoadNearestIndexThread;
begin
{$IF MIR2EX}
{$IF VIEWFOG}
  if not LoadNearestIndex_16(NEARESTPALETTEINDEXFILE_16) then
  begin
    BuildNearestIndex_16(frmMain.DXDraw.ColorTable);
    SaveNearestIndex_16(NEARESTPALETTEINDEXFILE_16);
  end;
  if not LoadNearestIndex(NEARESTPALETTEINDEXFILE) then
  begin
    BuildNearestIndex(frmMain.DXDraw.ColorTable);
    SaveNearestIndex(NEARESTPALETTEINDEXFILE);
  end;
{$IFEND VIEWFOG}
{$ELSE}
  if not LoadNearestIndex(NEARESTPALETTEINDEXFILE) then
  begin
    BuildNearestIndex(frmMain.DXDraw.ColorTable);
    SaveNearestIndex(NEARESTPALETTEINDEXFILE);
  end;
{$IFEND MIR2EX}
  BuildColorLevels(frmMain.DXDraw.ColorTable);
end;

procedure TfrmMain.DXDrawInitialize(Sender: TObject);
const
  nFirstBytes: Integer = 7;
var
  nPort: Integer;
  szParamStr: string;
  szLine, szIP, szPort: string;
  ini: TIniFile;
begin                           
  if g_boFirstTime then
  begin
    g_boFirstTime := False;

    if not DirectoryExists('.\Sound\') then
      ForceDirectories('.\Sound\');

    //dwStackSize := timegettime;
    DXDraw.AutoInitialize := False;
    DXDraw.Surface.Canvas.Font.Assign(frmMain.Font);
    frmMain.Font.Name := g_sCurFontName;
    frmMain.Canvas.Font.Name := g_sCurFontName;
    DXDraw.Surface.Canvas.Font.Name := g_sCurFontName;
    FrmDlg.DEdChat.Font.Name := g_sCurFontName;

    //123456
    DDClipper := TDirectDrawClipper.Create(DXDraw.DDraw);
{$IFDEF DEBUG_LOGIN}
    g_PatchClientManager := TPatchClientManager.Create;
    g_PatchClientManager.AddClientSocket('127.0.0.1', 8200);
{$ELSE}
    //待调整 
    try
      g_PatchClientManager := TPatchClientManager.Create;
      g_PatchClientManager.AddClientSocket(MICRO_ADDRESS,MICRO_PORT);
    except
    end;
{$ENDIF}

    InitWMImagesLib(DXDraw, True);

    DXDraw.DefColorTable := g_MainPalette; //g_WMainImages.m_MainPalette;
    DXDraw.ColorTable := DXDraw.DefColorTable;
    DXDraw.UpdatePalette;

    cliUtil.BuildPal_8to16(g_MainPalette);

    LoadNearestIndexThread();

    InitWMImagesLib(DXDraw, False);

{$IF not VIEWFOG}
    if doFullScreen in DXDraw.Options then
    begin
      g_boNoDarkness := True;
      g_boUseDIBSurface := False;
    end
    else
    begin
      ClientWidth := SCREENWIDTH;
      ClientHeight := SCREENHEIGHT;
      g_boNoDarkness := True;
      g_boUseDIBSurface := True;
    end;
{$ELSE}
    if doFullScreen in DXDraw.Options then
    begin
      g_boNoDarkness := False;
      g_boUseDIBSurface := False;
    end
    else
    begin
      ClientWidth := SCREENWIDTH;
      ClientHeight := SCREENHEIGHT;
      g_boNoDarkness := False;
      g_boUseDIBSurface := True;
    end;
{$IFEND VIEWFOG}

{$I '..\Common\Macros\VMPB.inc'}
    DScreen.Initialize;
    g_PlayScene.Initialize;
    //DXDraw.OnWindowMove := DXDrawonWindowMove;

    FrmDlg.Initialize(True);

    g_DlgInitialize := True;

    ////////////////////// 防止LoadLibrayExW部分 /////////////////
{$IF FAKELOADLIB}
    pfnRaw := Pointer(@rawLoadLibraryExW);
    fnNew := @newLoadLibraryExW;

    //1 save the first 7 bytes
    fnRaw := Pointer(DWORD(@rawLoadLibraryExW));
    fnFake := @fakeLoadLibraryExW[0];
    CopyMemory(fnFake, pfnRaw, nFirstBytes);
    fnFake[nFirstBytes] := $E9;
    PInteger(@fnFake[nFirstBytes + 1])^ := UINT(fnRaw) - UINT(fnFake) - 5;

    //2 modify the raw to jmp to fnNew
    dwOldProtect := 0;
    VirtualProtect(fnRaw, nFirstBytes, PAGE_READWRITE, @dwOldProtect); //修改该代码段的属性为可写
    try
      PByte(fnRaw)^ := $E9;
      PInteger(Integer(fnRaw) + 1)^ := UINT(fnNew) - UINT(UINT(fnRaw) + 5);
    finally
      VirtualProtect(fnRaw, nFirstBytes, dwOldProtect, nil);
    end;

    //3 change the rawPointer
    rawLoadLibraryExW := @fnFake[0];
{$IFEND FAKELOADLIB}

    //dwStackSize := timegettime;
    //FrmDlg.InitializeNext();
    //messagebox(0, PChar(IntToStr(timegettime - dwStackSize)), nil,0);


    InitMainImagesSecond(nil);
    //g_hImagesThread := CreateThread(nil, 0, @InitMainImagesSecond, nil, 0, g_dwImgThreadId);

    //MessageBox(0, PChar(InttoStr(timegettime - dwStackSize)), '', 0);

{$I '..\Common\Macros\VMPE.inc'}
  end;
end;

procedure TfrmMain.DXDrawReInit();
begin
  DXDraw.AutoInitialize := False;
  DXDraw.Surface.Canvas.Font.Assign(frmMain.Font);
  frmMain.Font.Name := g_sCurFontName;
  frmMain.Canvas.Font.Name := g_sCurFontName;
  DXDraw.Surface.Canvas.Font.Name := g_sCurFontName;
  FrmDlg.DEdChat.Font.Name := g_sCurFontName;

{$IF not VIEWFOG}
  if doFullScreen in DXDraw.Options then
  begin
    g_boNoDarkness := True;
    g_boUseDIBSurface := False;
  end
  else
  begin
    ClientWidth := SCREENWIDTH;
    ClientHeight := SCREENHEIGHT;
    g_boNoDarkness := True;
    g_boUseDIBSurface := True;
  end;
{$ELSE}
  if doFullScreen in DXDraw.Options then
  begin
    g_boNoDarkness := False;
    g_boUseDIBSurface := False;
  end
  else
  begin
    ClientWidth := SCREENWIDTH;
    ClientHeight := SCREENHEIGHT;
    g_boNoDarkness := False;
    g_boUseDIBSurface := True;
  end;
{$IFEND VIEWFOG}
end;

function TfrmMain.SurfaceCanFill(): Boolean;
begin
  Result := True;
  if (g_MySelf <> nil) then
    Result := False;
end;

procedure TfrmMain.ProcOnIdle;
var
  Done: Boolean;
begin
  AppOnIdle(Self, Done);
end;
{
procedure TfrmMain.ProcssRunModule;
begin

end;
 }
procedure TfrmMain.AppOnIdle(Sender: TObject; var Done: Boolean);
var
  boCanDraw: Boolean;
  tTime: DWORD;
const
  ProcOnIdleTime = 15;
  ProcOnIdleTime2 = ProcOnIdleTime * 2 - 1;
  ProcOnIdleTime3 = ProcOnIdleTime * 3 - 1;
  ProcOnIdleTime4 = ProcOnIdleTime * 4 - 1;
begin
  //g_dwCurrentTick^ := GetTickCount;

  Done := True;
  g_ProcCanDraw := False;

  if not g_bCanDraw {or IsIconic(Application.Handle)} then
    Exit;

  if canReDraw = False then exit;

  boCanDraw := DXDraw.CanDraw;
  if boCanDraw then
  begin

    Done := False;

    if g_boProcMessagePacket then
    begin
      ProcessMessagePacket();
    end;

    tTime := timeGetTime();

    if tTime - g_ProcOnIdleTick >= ProcOnIdleTime then
    begin
      g_ProcOnIdleTick := tTime;

      if tTime - g_ProcOnDrawTick >= ProcOnIdleTime3 then
      begin
        g_ProcOnDrawTick := tTime;
        g_ProcCanDraw := True;
      end;

      ProcessKeyMessages;
      ProcessActionMessages;
      ProcessMagic;

      if (g_MySelf = nil) then
        DXDraw.Surface.Fill(0);

      DScreen.DrawScreen(DXDraw.Surface);

      if g_ProcCanDraw or (g_MySelf = nil) then
      begin //single fps

        if g_gcGeneral[4] then
          g_PlayScene.DropItemsShow;

        DScreen.DrawScreenTop(DXDraw.Surface);
        DScreen.DrawScreenBottom(DXDraw.Surface);

        g_DWinMan.DirectPaint(DXDraw.Surface);

        DScreen.DrawHint(DXDraw.Surface);

        DrawMovingObject();

        if FPrintScreenNow then
        begin
          FPrintScreenNow := False;
          PrintScreenNow();
        end;

        DrawGameNotice();
        DrawGameNotice_Ex();

        DoFade();

        if g_boFullScreen then
          DXDraw.Primary.Draw(0, 0, DXDraw.Surface.ClientRect, DXDraw.Surface, False)
        else
        begin
          DXDraw.Flip;
        end;
      end;
      QueryDynCode();
      Exit;
    end;
    ReleaseImageCache(); //PruneAll
    //123456
    g_PatchClientManager.ExecSendBuffer();

    g_PatchClientManager.ExecRecvBuffer();

    if g_BuildBotTex = 1 then //no hero
      FrmDlg.InitializeNext2();

    FrmDlg.InitializeNext3();

    Sleep(1);
  end;
end;

procedure TfrmMain.DrawMovingObject();
var
  bitem: Boolean;
  n: Integer;
  P: TPoint;
  //S                         : string;
  d: TDirectDrawSurface;
begin
  if g_boItemMoving then
  begin

    if (g_MovingItem.Item.S.Name <> g_sGoldName) then
    begin
      d := frmMain.GetWBagItemImg(g_MovingItem.Item.S.looks);
      bitem := True;
    end
    else
    begin
      bitem := False;
      d := g_WBagItemImages.Images[115];
    end;

    if d <> nil then
    begin
      GetCursorPos(P);
      Windows.ScreenToClient(frmMain.Handle, P);
      DXDraw.Surface.Draw(P.X - (d.ClientRect.Right div 2), P.Y - (d.ClientRect.Bottom div 2), d.ClientRect, d, True);

      if (g_MovingItem.Item.S.Overlap > 0) and bitem then
      begin
        BoldTextOut(DXDraw.Surface, P.X + 14, P.Y + 2, clLime, clblack, Format('%d', [g_MovingItem.Item.Dura]));
      end;

      if (g_MovingItem.Item.S.StdMode in [15..24, 26..30]) then
      begin
        if (g_MovingItem.Item.S.Shape = 190) or (g_MovingItem.Item.S.reserve[3] = 4) then
        begin
          if GetTickCount - g_MovingItemShine.tick > 60 then
          begin
            g_MovingItemShine.tick := GetTickCount;
            Inc(g_MovingItemShine.idx);
            if g_MovingItemShine.idx > 31 then
              g_MovingItemShine.idx := 0;
          end;
          n := -1;
          d := nil;
          case g_MovingItem.Item.S.StdMode of
            30: n := 6;
            19, 20, 21: n := 2;
            15: n := 3;
            24, 25, 26: n := 0;
            22, 23: n := 1;
            27: n := 5;
            28: n := 4
          end;
          if n >= 0 then
            d := g_Wui.Images[100 + n * 40 + g_MovingItemShine.idx];
          //d := g_Wui.Images[100 + (g_MovingItem.Item.S.looks - 2130) * 40 + g_MovingItemShine.idx];
          if d <> nil then
            DrawBlend(DXDraw.Surface,
              P.X - (d.ClientRect.Right div 2),
              P.Y - (d.ClientRect.Bottom div 2),
              d, 1);
        end
        else if g_MovingItem.Item.S.reserve[3] = 1 then
        begin
          n := 0;
          if g_MovingItem.Item.S.StdMode in [15, 16] then
            n := 2;
          if GetTickCount - g_MovingItemShine.tick > 100 then
          begin
            g_MovingItemShine.tick := GetTickCount;
            Inc(g_MovingItemShine.idx);
            if g_MovingItemShine.idx > (8 + n) then
              g_MovingItemShine.idx := 0;
          end;
          d := g_WMainImages.Images[(640 - n * 10) + g_MovingItemShine.idx];
          if d <> nil then
            DrawBlend(DXDraw.Surface,
              P.X - (d.ClientRect.Right div 2),
              P.Y - (d.ClientRect.Bottom div 2),
              d, 1);
        end
        else if g_MovingItem.Item.S.reserve[3] = 2 then
        begin
          if GetTickCount - g_MovingItemShine.tick > 100 then
          begin
            g_MovingItemShine.tick := GetTickCount;
            Inc(g_MovingItemShine.idx);
            if g_MovingItemShine.idx > 5 then
              g_MovingItemShine.idx := 0;
          end;
          d := g_WMain2Images.Images[260 + g_MovingItemShine.idx];
          if d <> nil then
            DrawBlend(DXDraw.Surface,
              P.X - (d.ClientRect.Right div 2),
              P.Y - (d.ClientRect.Bottom div 2),
              d, 1);
        end
        else if g_MovingItem.Item.S.reserve[3] = 3 then
        begin
          if GetTickCount - g_MovingItemShine.tick > 100 then
          begin
            g_MovingItemShine.tick := GetTickCount;
            Inc(g_MovingItemShine.idx);
            if g_MovingItemShine.idx > 9 then
              g_MovingItemShine.idx := 0;
          end;
          n := -1;
          d := nil;
          case g_MovingItem.Item.S.StdMode of
            30: n := 6;
            19, 20, 21: n := 2;
            15: n := 5;
            24, 25, 26: n := 1;
            22, 23: n := 0;
            27: n := 4;
            28: n := 3;
          end;
          if n >= 0 then
            d := g_StateEffect.Images[530 + n * 10 + g_MovingItemShine.idx];
          if d <> nil then
            DrawBlend(DXDraw.Surface,
              P.X - (d.ClientRect.Right div 2),
              P.Y - (d.ClientRect.Bottom div 2),
              d, 1);
        end
        else if g_MovingItem.Item.S.reserve[3] = 5 then
        begin
          if GetTickCount - g_MovingItemShine.tick > 100 then
          begin
            g_MovingItemShine.tick := GetTickCount;
            Inc(g_MovingItemShine.idx);
            if g_MovingItemShine.idx > 9 then
              g_MovingItemShine.idx := 0;
          end;
          d := g_WStateItemImages.Images[3910 + g_MovingItemShine.idx];
          if d <> nil then
            DrawBlend(DXDraw.Surface,
              P.X - (d.Width div 2),
              P.Y - (d.Height div 2),
              d, 1);
        end
        else if g_MovingItem.Item.S.reserve[3] in [6..10] then
        begin
          d := g_WMain3Images.Images[750 + (g_MovingItem.Item.S.reserve[3] - 6) * 2];
          if d <> nil then
            DrawBlend(DXDraw.Surface,
              P.X - (d.Width div 2),
              P.Y - (d.Height div 2),
              d, 1);
        end;

      end;

    end;
  end;
end;

procedure TfrmMain.DoFade();
var
  dd: TDirectDrawSurface;
begin
  if g_boDoFadeOut then
  begin
    if g_nFadeIndex < 1 then
      g_nFadeIndex := 1;

    dd := TDirectDrawSurface.Create(frmMain.DXDraw.DDraw);
    try
      dd.SetSize(DXDraw.Surface.Width, DXDraw.Surface.Height);
      dd.Draw(0, 0, DXDraw.Surface.ClientRect, DXDraw.Surface, False);
      MakeDark(dd, g_nFadeIndex);
      DXDraw.Surface.Draw(0, 0, dd.ClientRect, dd, False);
    finally
      dd.Free;
    end;

    //MakeDark(DXDraw.Surface, g_nFadeIndex);
    if g_nFadeIndex <= 1 then
      g_boDoFadeOut := False
    else
      Dec(g_nFadeIndex, 2);
  end
  else if g_boDoFadeIn then
  begin
    if g_nFadeIndex > 29 then
      g_nFadeIndex := 29;

    dd := TDirectDrawSurface.Create(frmMain.DXDraw.DDraw);
    try
      dd.SetSize(DXDraw.Surface.Width, DXDraw.Surface.Height);
      dd.Draw(0, 0, DXDraw.Surface.ClientRect, DXDraw.Surface, False);
      MakeDark(dd, g_nFadeIndex);
      DXDraw.Surface.Draw(0, 0, dd.ClientRect, dd, False);
    finally
      dd.Free;
    end;
    //MakeDark(DXDraw.Surface, g_nFadeIndex);
    if g_nFadeIndex >= 29 then
      g_boDoFadeIn := False
    else
      Inc(g_nFadeIndex, 1);
  end
  else if g_boDoFastFadeOut then
  begin
    if g_nFadeIndex < 1 then
      g_nFadeIndex := 1;

    dd := TDirectDrawSurface.Create(frmMain.DXDraw.DDraw);
    try
      dd.SetSize(DXDraw.Surface.Width, DXDraw.Surface.Height);
      dd.Draw(0, 0, DXDraw.Surface.ClientRect, DXDraw.Surface, False);
      MakeDark(dd, g_nFadeIndex);
      DXDraw.Surface.Draw(0, 0, dd.ClientRect, dd, False);
    finally
      dd.Free;
    end;
    //MakeDark(DXDraw.Surface, g_nFadeIndex);
    if g_nFadeIndex > 1 then
      Dec(g_nFadeIndex, 4);
  end;
end;



procedure TfrmMain.QueryDynCode();
var
  S: string;
  dMsg: TDefaultMessage;
begin
  if CSocket.Active then
  begin
    case g_ConnectionStep of
      cnsIntro:
        begin
          if not g_boQueryDynCode then
          begin
            g_boQueryDynCode := True;
{$I '..\Common\Macros\VMPBM.inc'}
{$IFDEF DEBUG_LOGIN}
            SendSocket('ddhkd=]hddhkddhkxwuvpu]zaaYvrqQz{awwc`=yonCgv{={ybBsrlyyaa<');
{$ELSE}
            dMsg := MakeDefaultMsg(CM_QUERYDYNCODE, 0, 0, 0, 0);
            DCP_mars.InitStr(VMProtectDecryptStringA('sWebSite'));
            S := DCP_mars.DecryptString(g_pRcHeader.sWebSite);
            DCP_mars.InitStr(S);
            S := DCP_mars.EncryptString(S);
            SendSocket(EncodeMessage(dMsg) + EncodeString(S));
{$ENDIF}
{$I '..\Common\Macros\VMPE.inc'}
          end;
        end;
      cnsSelChr, cnsReSelChr:
        begin
          if g_boQuerySelChar then
          begin
            g_boQuerySelChar := False;
            dMsg := MakeDefaultMsg(CM_QUERYSELCHARCODE, 0, 0, 0, 0);
            SendSocket(EncodeMessage(dMsg));
          end;
        end;
    end; //case
  end;
end;

const
 // g_sChgWindowMsg = 'ALT + ENTER 切换窗口模式';
    g_sChgWindowMsg = '';

procedure TfrmMain.DrawGameNotice();
begin
  if not g_boDoFadeOut and (DScreen.CurrentScene = LoginScene) then
  begin
    DXDraw.Surface.Canvas.Font.Color := GetRGB(150);
    if g_ShowClientVersion then
    begin
      DXDraw.Surface.Canvas.TextOutA((SCREENWIDTH - DXDraw.Surface.Canvas.TextWidth(g_ClientVersion, False) - 20), 10, g_ClientVersion); //加入版本显示 2019-11-23
    end;
    DXDraw.Surface.Canvas.TextOutA((SCREENWIDTH - DXDraw.Surface.Canvas.TextWidth(g_affiche1, False)) div 2, SCREENHEIGHT - 70, g_affiche1);
    DXDraw.Surface.Canvas.TextOutA((SCREENWIDTH - DXDraw.Surface.Canvas.TextWidth(g_affiche2, False)) div 2, SCREENHEIGHT - 50, g_affiche2);
    DXDraw.Surface.Canvas.TextOutA((SCREENWIDTH - DXDraw.Surface.Canvas.TextWidth(g_affiche3, False)) div 2, SCREENHEIGHT - 35, g_affiche3);
    DXDraw.Surface.Canvas.Font.Color := clLime;
    if not g_gcGeneral[11] then
      DXDraw.Surface.Canvas.TextOutA((SCREENWIDTH - DXDraw.Surface.Canvas.TextWidth(g_affiche0, False)) - 10, SCREENHEIGHT - 50, g_affiche0);
    DXDraw.Surface.Canvas.TextOutA(SCREENWIDTH - DXDraw.Surface.Canvas.TextWidth(g_sChgWindowMsg, False) - 10, SCREENHEIGHT - 20, g_sChgWindowMsg);
    DXDraw.Surface.Canvas.Release;
  end;
end;

//const
//  g_sChgWindowMsg_ex = '反外挂模块(20150327)已启动!';

procedure TfrmMain.DrawGameNotice_Ex();
begin

  Exit;
  if not m_NoticeOk then
    Exit;

  if not g_boDoFadeOut and (DScreen.CurrentScene = g_PlayScene) then
  begin
    with DXDraw.Surface.Canvas do
    begin

      Font.Color := clblack;
      DxBoldTextOut(DXDraw.Surface,
        (SCREENWIDTH - m_noticewidth) div 2,
      //  427,
        (SCREENHEIGHT - 160),
        clLime,
        clblack,
        m_notice);
      Release;
    end;
  end;
end;

procedure TfrmMain.ReleaseAllImageCache();
var
  i, ii: Integer;
  pImage: PTDxImage;
  CnBucket: TCnBucket;
begin
  for i := g_ImageManager.m_ImagesList.count - 1 downto 0 do
  begin
    pImage := g_ImageManager.m_ImagesList[i];
    if pImage.Surface <> nil then
    begin
      pImage.nW := 0;
      pImage.nH := 0;
      FreeAndNil(pImage.Surface);
    end;
  end;
  g_ImageManager.m_ImagesList.Clear;

  for i := g_DXFontsManager.FBucketCount - 1 downto 0 do
  begin
    CnBucket := g_DXFontsManager.Buckets[i];
    for ii := 0 to CnBucket.count - 1 do
    begin
      FreeAndNil(PTDXFont(CnBucket.Objects[ii]).pSurface);
      Dispose(PTDXFont(CnBucket.Objects[ii]));
    end;
  end;
  g_DXFontsManager.Clear;

  {with FrmDlg do begin
    if m_HintStrs.Strs <> nil then begin
      for ii := 0 to m_HintStrs.Strs.count - 1 do
        Dispose(pTHintTextSegment(m_HintStrs.Strs[ii]));
      m_HintStrs.Strs.Clear;
    end;
  end;}
end;

procedure TfrmMain.ReleaseImageCache();
var
  n: Integer;
  pImage: PTDxImage;
begin
  if (g_ImageManager.m_ImagesList.count > 5000) or (g_ImageManager.m_ImagesMemory > 65 * 1024 * 1024) then
  begin
    if GetTickCount - g_ImageManager.m_CheckTick > 100 then
    begin
      g_ImageManager.m_CheckTick := GetTickCount;
      n := 32;
      while n > 0 do
      begin
        if g_ImageManager.m_ImagesList.count <= 0 then
          Break;
        pImage := g_ImageManager.m_ImagesList[0];
        if GetTickCount - pImage.dwLatestTime > g_dwLoadSurfaceTime4 then
        begin
          if pImage.Surface <> nil then
          begin
            pImage.nW := 0;
            pImage.nH := 0;
            Dec(g_ImageManager.m_ImagesMemory, pImage.Surface.Width * pImage.Surface.Height);
            FreeAndNil(pImage.Surface);
          end;
          g_ImageManager.m_ImagesList.Delete(0);
        end
        else
        begin
          g_ImageManager.m_ImagesList.Move(0, g_ImageManager.m_ImagesList.count - 1);
        end;
        Dec(n);
      end;
    end;
  end;
end;

procedure TfrmMain.AppLogout;
begin
  if frmCaptcha.Visible then
  begin
    FrmDlg.DMessageDlg('输入验证码期间禁止小退', [mbOk]);
    Exit;
  end;
  if mrOk = FrmDlg.DMessageDlg('确认退出到选择角色界面吗？', [mbOk, mbCancel]) then
  begin
    AppLogoutEx;
  end;
end;

procedure TfrmMain.AppLogoutEx;
begin
  if frmCaptcha.Visible then
  begin
    FrmDlg.DMessageDlg('输入验证码期间禁止小退', [mbOk]);
    Exit;
  end;
  if FrmDlg.WinFindPathBack.Visible = True then
  begin
     FrmDlg.WinFindPathBack.Visible := False;
  end;
  try
    SendClientMessage(CM_SOFTCLOSE, 0, 0, 0, 0);
    CloseAllWindows;
//    frmCaptcha.CancelCap;
    if g_PlayScene <> nil then
       g_PlayScene.ClearActors;
    FrmDlg.WinMerchandiseDlg.Visible := False;
    FrmDlg.ItemMerchandiseDlg.Visible := False;
    FrmDlg.ResetMerchandiseList;
    //CmdTimer.Interval := 300;
    ActiveCmdTimer(tcSoftClose);

    SaveBagsData();
    SaveItemFilter();
    timer2.Enabled := False;
  finally

  end;
end;

procedure TfrmMain.AppExit;
begin
  Close;
end;

procedure TfrmMain.LoadBagsData;
begin
  if g_boBagLoaded then
    Loadbagsdat('.\Config\' + g_sServerName + '.' + m_sCharName + '.itm-plus', @g_ItemArr);
  g_boBagLoaded := False;
end;

procedure TfrmMain.SaveBagsData;
begin
  if g_boBagLoaded then
  begin
    FillBagStallItem(0);
    Savebagsdat('.\Config\' + g_sServerName + '.' + m_sCharName + '.itm-plus', @g_ItemArr);
  end;
  g_boBagLoaded := False;
end;

procedure TfrmMain.PrintScreenNow;

  function IntToStr2(n: Integer): string;
  begin
    if n < 10 then
      Result := '0' + IntToStr(n)
    else
      Result := IntToStr(n);
  end;

var
  i, k, n, CheckSum: Integer;
  flname, flname2: string;
  ddsd: TDDSurfaceDesc;
  sptr: PByte;
  bmp: TBitMap;
  pt: TPoint;
  Dest: TRect;
begin
  if not DXDraw.CanDraw then
    Exit;

  if not DirectoryExists('.\Images\') then
    if not ForceDirectories('.\Images\') then
      Exit;
  while True do
  begin
    flname := '.\Images\Images' + IntToStr2(g_nCaptureSerial) + '.bmp';
    if not FileExists(flname) then
    begin
      flname2 := Copy(flname, 1, Length(flname) - 4) + '.jpg';
      Break;
    end;
    Inc(g_nCaptureSerial);
  end;

  ddsd.dwSize := SizeOf(ddsd);
  CheckSum := 0;
  try
    DXDraw.Primary.Lock(ddsd);
    for i := (600 - 120) to SCREENHEIGHT - 10 do
    begin
      sptr := PByte(Integer(ddsd.lpSurface) + (SCREENHEIGHT - 1 - i) * ddsd.lPitch + 200);
      for k := 0 to 400 - 1 do
        CheckSum := CheckSum + BYTE(PByte(Integer(sptr) + k)^);
    end;
  finally
    DXDraw.Primary.Unlock();
  end;

  pt := DXDraw.ClientToScreen(Point(0, 0));
  if doStretch in DXDraw.NowOptions then
  begin
    Dest := Bounds(pt.X, pt.Y, DXDraw.Width, DXDraw.Height);
  end
  else
  begin
    if doCenter in DXDraw.NowOptions then
    begin
      Inc(pt.X, (DXDraw.Width - DXDraw.Surface.Width) div 2);
      Inc(pt.Y, (DXDraw.Height - DXDraw.Surface.Height) div 2);
    end;
    Dest := Bounds(pt.X, pt.Y, DXDraw.Surface.Width, DXDraw.Surface.Height);
  end;

  SetBkMode(DXDraw.Primary.Canvas.Handle, Transparent);
  try
    DXDraw.Primary.Canvas.Font.Color := clWhite;
    n := 0;
    if g_MySelf <> nil then
    begin
      DXDraw.Primary.Canvas.TextOut(pt.X + 1, pt.Y + 1, g_sServerName + ' ' + g_MySelf.m_sUserName);
      Inc(n);
    end;
    DXDraw.Primary.Canvas.TextOut(pt.X + 1, pt.Y + 1 + (n + 0) * 12, 'CheckSum=' + IntToStr(CheckSum));
    DXDraw.Primary.Canvas.TextOut(pt.X + 1, pt.Y + 1 + (n + 1) * 12, DateToStr(Date));
    DXDraw.Primary.Canvas.TextOut(pt.X + 1, pt.Y + 1 + (n + 2) * 12, TimeToStr(Time));
  finally
    DXDraw.Primary.Canvas.Release;
  end;

  bmp := TBitMap.Create;
  bmp.Width := SCREENWIDTH;
  bmp.Height := SCREENHEIGHT;
  bmp.PixelFormat := pf16bit;
  bmp.Canvas.CopyRect(Bounds(0, 0, SCREENWIDTH, SCREENHEIGHT), DXDraw.Primary.Canvas, Bounds(pt.X, pt.Y, SCREENWIDTH, SCREENHEIGHT));
  DXDraw.Primary.Canvas.Release;
  {jp := TJpegImage.Create;
  jp.Assign(bmp);
  jp.SaveToFile(flname2);
  jp.Free;}
  bmp.SaveToFile(flname);
  bmp.Free;
  if g_MySelf <> nil then
    DScreen.AddChatBoardString(Format('[屏幕截图: %s]', [ExtractFileName(flname)]), clGreen, clWhite);
end;

procedure TfrmMain.ProcessMagic;
var
  nSX, nSY: Integer;
  tdir, targid, targx, targy: Integer;
  pmag: PTUseMagicInfo;
begin
  if (g_PlayScene.ProcMagic.nTargetX < 0) or (g_MySelf = nil) then
    Exit;

  if GetTickCount - g_PlayScene.ProcMagic.dwTick > 5000 then
  begin
    g_PlayScene.ProcMagic.dwTick := GetTickCount;
    g_PlayScene.ProcMagic.nTargetX := -1;
    Exit;
  end;

  if GetTickCount - m_dwProcUseMagicTick > 28 then
  begin
    m_dwProcUseMagicTick := GetTickCount;

    if g_PlayScene.ProcMagic.fUnLockMagic then
    begin
      targid := 0;
      targx := g_PlayScene.ProcMagic.nTargetX;
      targy := g_PlayScene.ProcMagic.nTargetY;
    end
    else if (g_PlayScene.ProcMagic.xTarget <> nil) and not g_PlayScene.ProcMagic.xTarget.m_boDeath then
    begin
      targid := g_PlayScene.ProcMagic.xTarget.m_nRecogId;
      targx := g_PlayScene.ProcMagic.xTarget.m_nCurrX;
      targy := g_PlayScene.ProcMagic.xTarget.m_nCurrY;
    end
    else
    begin
      g_PlayScene.ProcMagic.nTargetX := -1;
      Exit;
    end;

    nSX := abs(g_MySelf.m_nCurrX - targx);
    nSY := abs(g_MySelf.m_nCurrY - targy);
    if (nSX <= g_nMagicRange) and (nSY <= g_nMagicRange) then
    begin
      if g_PlayScene.ProcMagic.fContinue or (CanNextAction() and ServerAcceptNextAction) then
      begin
        g_dwLatestSpellTick := GetTickCount;
        tdir := GetFlyDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, targx, targy);

        New(pmag);
        FillChar(pmag^, SizeOf(TUseMagicInfo), #0);
        pmag.EffectNumber := g_PlayScene.ProcMagic.xMagic.Def.btEffect;
        pmag.MagicSerial := g_PlayScene.ProcMagic.xMagic.Def.wMagicid;
        pmag.ServerMagicCode := 0;
        g_dwMagicDelayTime := 200 + g_PlayScene.ProcMagic.xMagic.Def.dwDelayTime;

        g_dwMagicPKDelayTime := 0;
        if (g_MagicTarget <> nil) then
        begin
          if g_MagicTarget.m_btRace = 0 then
            g_dwMagicPKDelayTime := 300 + Random(1100);
        end;
        g_MySelf.SendMsg(CM_SPELL, targx, targy, tdir, string(pmag), targid, '', 0);

        g_PlayScene.ProcMagic.nTargetX := -1;
      end;
    end
    else
    begin
      g_ChrAction := caRun;
      g_nTargetX := targx;
      g_nTargetY := targy;
    end;
  end;
end;

procedure TfrmMain.ProcessRunModule;
var dllmain: pfnDllMain;
  hMou: Cardinal;
  sznotice: array[0..1023] of Char;
begin
  try
    dllmain := nil;
//    OutputDebugString('aa');
    hMou := memLoadLibrary(@m_rungatemod[0], dllmain);
//    OutputDebugString('bb');
    if Pointer(@dllmain) <> nil then
    begin
//      OutputDebugString('cc');
      dllmain(hMou, 5, Dword(@m_Vtable));
//      OutputDebugString('dd');
      if m_vtable <> nil then
      begin
//        OutputDebugString('ee');
        m_vtable.m_GetVersion(sznotice, sizeof(sznotice));
//        OutputDebugString('ff');
//        m_notice := sznotice;
        m_NoticeOk := True;
//        m_noticewidth := DXDraw.Surface.Canvas.TextWidth(m_notice, True);
        DScreen.AddChatBoardString(sznotice, clWhite, clBlue);
        SendLoadModOk;
        Timer2.Enabled := True;
      end;
    end;
  except
  end;

end;



function CalcBufferCRC(Buffer: PChar; nSize: Integer): Cardinal;
var
  I: Integer;
  Int: ^Integer;
  nCrc: Cardinal;
begin
  Int := Pointer(Buffer);
  nCrc := 0;
  for I := 0 to nSize div 4 - 1 do
  begin
    nCrc := nCrc xor Int^;
    Int := Pointer(Integer(Int) + 4);
  end;
  Result := nCrc;
end;


function TfrmMain.ProcessSmuggleData(pData: PChar; len: Integer): Boolean;
var
  packet: PJX_PACKET;
  sendmsg: TDefaultMessage;
  log: string;
  ncrc: Cardinal;
begin
  Result := False;
  if len < SizeOf(TJX_PACKET) then
    Exit;
  packet := PJX_PACKET(@pData[0]);
  if (SizeOf(TJX_PACKET) + packet.curLen) > len then
  begin
//    OutputDebugString('packet.curLen err!');
    Exit;
  end;

  if packet.curOffset > 1024 * 1000 then
  begin // 文件包太大了。
    Exit;
  end;


  CopyMemory(@m_rungatemod[packet.curOffset], @pData[sizeof(TJX_PACKET)], packet.curLen);
  sendmsg := MakeDefaultMsg(SM_SMUGGLE_SUCESS, 0, 0, 0, packet.curOffset);

  SendSocket(EncodeMessage(sendmsg));
{$IFDEF TEST}
  log := Format('ProcessSmuggleData %d,%d', [packet.curOffset, packet.curLen]);
 // OutputDebugString(pchar(log));
{$ENDIF }
  if packet.totoallen = (packet.curOffset + packet.curLen) then
  begin
    ncrc := CalcBufferCRC(@m_rungatemod[0], packet.totoallen);
{$IFDEF TEST}
    log := Format('crc:%d,%d', [ncrc, packet.crc]);
 //   OutputDebugString(pchar(log));
{$ENDIF }
    if packet.Crc = ncrc then
    begin
//      OutputDebugString('ProcessRunModule');
      ProcessRunModule;
      ZeroMemory(m_rungatemod, Length(m_rungatemod));
    end
    else
    begin
     // OutputDebugString('反外挂模块下载失败');
    end;
  end;

  Result := True;
end;

procedure TfrmMain.ProcessKeyMessages;
begin
  if ActionKey = 0 then
    Exit;
  if (g_MySelf <> nil) and g_MySelf.m_StallMgr.OnSale then
  begin
    Exit;
  end;

  case ActionKey of
    VK_F1, VK_F2, VK_F3, VK_F4, VK_F5, VK_F6, VK_F7, VK_F8:
      begin
        if g_MySelf.m_btHorse = 0 then
          UseMagic(g_nMouseX, g_nMouseY, GetMagicByKey(Char((ActionKey - VK_F1) + BYTE('1'))));
        ActionKey := 0;
        g_nTargetX := -1;
        Exit;
      end;
    12..19:
      begin
        if g_MySelf.m_btHorse = 0 then
          UseMagic(g_nMouseX, g_nMouseY, GetMagicByKey(Char((ActionKey - 12) + BYTE('1') + BYTE($14))));
        ActionKey := 0;
        g_nTargetX := -1;
        Exit;
      end;
  end;
end;

procedure TfrmMain.ProcessActionMessages;
var
  mx, my, dx, dy, crun: Integer;
  ndir, adir, mdir: BYTE;
  bowalk, bostop: Boolean;
label
  LB_WALK, TTTT, MMMM;
begin
  if g_MySelf = nil then Exit;

  if (g_nTargetX >= 0) and CanNextAction and ServerAcceptNextAction then
  begin

    /////////////////////////////////////////////////
    if g_boOpenAutoPlay and (g_APMapPath <> nil) and (g_APStep >= 0) and (0 < High(g_APMapPath)) then
    begin
      if (abs(g_APMapPath[g_APStep].X - g_MySelf.m_nCurrX) <= 3) and (abs(g_APMapPath[g_APStep].Y - g_MySelf.m_nCurrY) <= 3) then
      begin
        if High(g_APMapPath) >= 2 then
        begin //3点以上

          if g_APStep >= High(g_APMapPath) then
          begin //当前点在终点...
            //终点 <-> 起点 距离过远...
            if (abs(g_APMapPath[High(g_APMapPath)].X - g_APMapPath[0].X) >= 36) or (abs(g_APMapPath[High(g_APMapPath)].Y - g_APMapPath[0].Y) >= 36) then
            begin
              g_APGoBack := True; //原路返回
              g_APLastPoint := g_APMapPath[g_APStep];
              Dec(g_APStep);
            end
            else
            begin //循环到起点...
              g_APGoBack := False;
              g_APLastPoint := g_APMapPath[g_APStep];
              g_APStep := 0;
            end;
          end
          else
          begin
            if g_APGoBack then
            begin //原路返回
              g_APLastPoint := g_APMapPath[g_APStep];
              Dec(g_APStep);
              if g_APStep <= 0 then
              begin //已回到起点
                g_APStep := 0;
                g_APGoBack := False;
              end;
            end
            else
            begin //循环...
              g_APLastPoint := g_APMapPath[g_APStep];
              Inc(g_APStep);
            end;
          end;
        end
        else
        begin //2点,循环...
          g_APLastPoint := g_APMapPath[g_APStep];
          Inc(g_APStep);
          if g_APStep > High(g_APMapPath) then
            g_APStep := 0;
        end;

      end;
    end;

    if (g_nTargetX <> g_MySelf.m_nCurrX) or (g_nTargetY <> g_MySelf.m_nCurrY) then
    begin

      if (g_MySelf.m_nTagX > 0) and (g_MySelf.m_nTagY > 0) then
      begin
        if g_MoveBusy then
        begin
          if GetTickCount - g_MoveErrTick > 60 then
          begin
            g_MoveErrTick := GetTickCount;
            Inc(g_MoveErr);
          end;
        end
        else
          g_MoveErr := 0;

        if (g_MoveErr > 10) then
        begin
          g_MoveErr := 0;
          g_MoveBusy := False;
          TimerAutoMove.Enabled := False;
          if (g_MySelf.m_nTagX > 0) and (g_MySelf.m_nTagY > 0) then
          begin
            if not g_PathBusy then
            begin
              g_PathBusy := True;
              try
                Map.ReLoadMapData();
                g_MapPath := Map.FindPath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_MySelf.m_nTagX, g_MySelf.m_nTagY, 0);
                if g_MapPath <> nil then
                begin
                  g_MoveStep := 1;
                  TimerAutoMove.Enabled := True;
                end
                else
                begin
                  g_MySelf.m_nTagX := 0;
                  g_MySelf.m_nTagY := 0;
                  DScreen.AddChatBoardString('自动移动出错，停止移动', GetRGB(5), clWhite);
                end;
              finally
                g_PathBusy := False;
              end;
            end;
          end;
        end;
      end;

      //if TimerAutoPlay.Enabled and (g_APTagget <> nil) and (abs(g_MySelf.m_nCurrX - g_APTagget.m_nCurrX) <= 1) and (abs(g_MySelf.m_nCurrY - g_APTagget.m_nCurrY) <= 1) and (not g_APTagget.m_boDeath) then begin
      //  goto MMMM;
      //end;
      TTTT:
      mx := g_MySelf.m_nCurrX;
      my := g_MySelf.m_nCurrY;
      dx := g_nTargetX;
      dy := g_nTargetY;
      ndir := GetNextDirection(mx, my, dx, dy);
      case g_ChrAction of
        caWalk:
          begin
            LB_WALK:
            crun := g_MySelf.CanWalk;
            if IsUnLockAction() and (crun > 0) then
            begin
              GetNextPosXY(ndir, mx, my);

              bostop := False;
              if not g_PlayScene.CanWalk(mx, my) then
              begin
                if g_boOpenAutoPlay and g_boAPAutoMove and (g_APPathList.count > 0) then
                begin
                  Init_Queue2();
                  g_nTargetX := -1;
                end;
                bowalk := False;
                adir := 0;
                if not bowalk then
                begin
                  mx := g_MySelf.m_nCurrX;
                  my := g_MySelf.m_nCurrY;
                  GetNextPosXY(ndir, mx, my);
                  if CheckDoorAction(mx, my) then
                    bostop := True;
                end;
                if not bostop and {not}(g_PlayScene.CrashMan(mx, my) or not Map.CanMove(mx, my)) then
                begin
                  mx := g_MySelf.m_nCurrX;
                  my := g_MySelf.m_nCurrY;
                  adir := PrivDir(ndir);
                  GetNextPosXY(adir, mx, my);
                  if not Map.CanMove(mx, my) then
                  begin
                    mx := g_MySelf.m_nCurrX;
                    my := g_MySelf.m_nCurrY;
                    adir := NextDir(ndir);
                    GetNextPosXY(adir, mx, my);
                    if Map.CanMove(mx, my) then
                      bowalk := True;
                  end
                  else
                    bowalk := True;
                end;
                if bowalk then
                begin
                  g_MySelf.UpdateMsg(CM_WALK, mx, my, adir, '', 0, '', 0);
                  g_dwLastMoveTick := GetTickCount;
                  if g_nOverAPZone > 0 then
                    Dec(g_nOverAPZone);
                end
                else
                begin
                  mdir := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, dx, dy);
                  if mdir <> g_MySelf.m_btDir then
                    g_MySelf.SendMsg(CM_TURN, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, mdir, '', 0, '', 0);
                  g_nTargetX := -1;
                end;
              end
              else
              begin
                g_MySelf.UpdateMsg(CM_WALK, mx, my, ndir, '', 0, '', 0);
                g_dwLastMoveTick := GetTickCount;
              end;
            end
            else
            begin
              g_nTargetX := -1;
            end;
          end;
        caRun:
          begin
            //免助跑
            if g_boCanStartRun or (g_nRunReadyCount >= 1) then
            begin
              crun := g_MySelf.CanRun;
              //骑马开始
              if (g_MySelf.m_btHorse <> 0) and (GetDistance(mx, my, dx, dy) >= 3) and (crun > 0) and IsUnLockAction() then
              begin
                GetNextHorseRunXY(ndir, mx, my);
                if g_PlayScene.CanRun(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, mx, my) then
                begin
                  g_MySelf.UpdateMsg(CM_HORSERUN, mx, my, ndir, '', 0, '', 0);
                  g_dwLastMoveTick := GetTickCount;
                  if g_nOverAPZone > 0 then
                    Dec(g_nOverAPZone);
                end
                else
                begin //如果跑失败则跳回去走
                  g_ChrAction := caWalk;
                  goto TTTT;
                end;
              end
              else
              begin
                if (GetDistance(mx, my, dx, dy) >= 2) and (crun > 0) then
                begin
                  if IsUnLockAction() then
                  begin
                    GetNextRunXY(ndir, mx, my);
                    if g_PlayScene.CanRun(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, mx, my)  then
                    begin
                      g_MySelf.UpdateMsg(CM_RUN, mx, my, ndir, '', 0, '', 0);
                      g_dwLastMoveTick := GetTickCount;
                      if g_nOverAPZone > 0 then Dec(g_nOverAPZone);
                    end
                    else
                    begin //如果跑失败则跳回去走
                      {if TimerAutoPlay.Enabled and (g_APTagget <> nil) then begin
                        if (abs(g_MySelf.m_nCurrX - g_APTagget.m_nCurrX) <= 1) and (abs(g_MySelf.m_nCurrY - g_APTagget.m_nCurrY) <= 1) and (not g_APTagget.m_boDeath) then
                          g_ChrAction := caWalk
                        else
                          g_ChrAction := caRun;
                        g_nTargetX := -1;
                        goto LB_WALK;
                      end;}
                      g_ChrAction := caWalk;
                      goto TTTT;
                    end;
                  end
                  else                           
                    g_nTargetX := -1;
                end
                else
                begin
                  mdir := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, dx, dy);
                  if mdir <> g_MySelf.m_btDir then
                    g_MySelf.SendMsg(CM_TURN, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, mdir, '', 0, '', 0);
                  g_nTargetX := -1;
                  goto LB_WALK;
                end;
              end; //骑马结束
            end
            else
            begin
              Inc(g_nRunReadyCount);
              goto LB_WALK;
            end;
          end;
      end;
    end
    else if g_boOpenAutoPlay and g_boAPAutoMove and (g_AutoPicupItem <> nil) then
    begin
      frmMain.SendPickup;
      g_sAPStr := '拾取物品';
      if g_boAPAutoMove and (g_APPathList.count > 0) then
      begin
        Init_Queue2();
        g_nTargetX := -1;
      end;
    end;
  end;

  g_nTargetX := -1;

  MMMM:
  if g_MySelf.RealActionMsg.ident > 0 then
  begin
    //FailAction := g_MySelf.RealActionMsg.ident;
    //FailDir := g_MySelf.RealActionMsg.dir;
    if g_MySelf.RealActionMsg.ident = CM_SPELL then
    begin
      SendSpellMsg(g_MySelf.RealActionMsg.ident,
        g_MySelf.RealActionMsg.X,
        g_MySelf.RealActionMsg.Y,
        g_MySelf.RealActionMsg.dir,
        g_MySelf.RealActionMsg.State);
    end
    else
      SendActMsg(g_MySelf.RealActionMsg.ident,
        g_MySelf.RealActionMsg.X,
        g_MySelf.RealActionMsg.Y,
        g_MySelf.RealActionMsg.dir);
    g_MySelf.RealActionMsg.ident := 0;

    if g_nMDlgX <> -1 then
    begin
      if (abs(g_nMDlgX - g_MySelf.m_nCurrX) >= 8) or (abs(g_nMDlgY - g_MySelf.m_nCurrY) >= 8) then
      begin
        g_nMDlgX := -1;
        FrmDlg.CloseMDlg;
      end;
    end;

    //stall dis
    if g_nStallX <> -1 then
    begin
      if (abs(g_nStallX - g_MySelf.m_nCurrX) >= 8) or (abs(g_nStallY - g_MySelf.m_nCurrY) >= 8) then
      begin
        g_nStallX := -1;
        FrmDlg.DBUserStallCloseClick(nil, 0, 0);
      end;
    end;
  end;
end;

procedure TfrmMain.SwitchMiniMap();
var
  i: Integer;
  szMapTitle: string;
  pMapDescInfo: pTMapDescInfo;
begin
  if not g_boViewMiniMap then
  begin
    if GetTickCount > g_dwQueryMsgTick then
    begin
      g_dwQueryMsgTick := GetTickCount + 3000;
      frmMain.SendWantMiniMap;
      g_nViewMinMapLv := 1;
      g_boViewMiniMap := True;  //   tab键立即绘制小地图置为True;   2019-12-23
    end;
  end
  else
  begin
    if g_nViewMinMapLv >= 2 then
    begin
      g_nViewMinMapLv := 0;
      g_boViewMiniMap := False;
    end
    else
      Inc(g_nViewMinMapLv);
  end;
  //123456
  g_xCurMapDescList.Clear;
  for i := 0 to g_xMapDescList.count - 1 do
  begin
    szMapTitle := g_xMapDescList[i];
    pMapDescInfo := pTMapDescInfo(g_xMapDescList.Objects[i]);
    if (CompareText(g_xMapDescList[i], g_sMapTitle) = 0) and
      (((pMapDescInfo.nFullMap = g_nViewMinMapLv) and (pMapDescInfo.nFullMap = 1)) or
      ((g_nViewMinMapLv <> 1) and (pMapDescInfo.nFullMap = 0))) then
    begin
      g_xCurMapDescList.AddObject(g_xMapDescList[i], TObject(pMapDescInfo));
    end;
  end;
end;

{$IF SERIESSKILL}

procedure TfrmMain.SeriesSkillFire();
begin
  if (g_MySelf = nil) or (g_MagicList2.count = 0) or g_SeriesSkillFire or (g_MySelf.m_nIPowerLvl <= 0) then Exit;
  
  if g_MySelf.m_btJob = 0 then
  begin
    if g_MagicArr[0][g_SeriesSkillArr[0]].Def.wMagicid = 100 then
    begin
      g_SeriesSkillFire_100 := True;
    end
    else
    begin
      g_nCurrentMagic2 := 1;
      g_nCurrentMagic := 888;
      UseMagic(g_nMouseX, g_nMouseY, g_MagicArr[0][g_SeriesSkillArr[0]], False, True);
    end;
  end
  else if g_SeriesSkillStep <= _MIN(High(g_SeriesSkillArr) + 1, g_MagicList2.count)  then
  begin
    // g_MagicLockActor := g_TargetCret;
    g_nCurrentMagic2 := 888;
    g_SeriesSkillFire := True;
    g_nCurrentMagic := 1;
    UseMagic(g_nMouseX, g_nMouseY, g_MagicArr[0][g_SeriesSkillArr[0]], False, True);
  end;
end;
{$IFEND SERIESSKILL}

procedure GetNearPoint;
var
  i, nC, n10, n14: Integer;
begin
  if (g_APMapPath <> nil) and (High(g_APMapPath) > 0) then
  begin
    n14 := 0;
    g_APLastPoint.X := -1;
    n10 := 999;
    for i := Low(g_APMapPath) to High(g_APMapPath) do
    begin
      nC := abs(g_APMapPath[i].X - g_MySelf.m_nCurrX) + abs(g_APMapPath[i].Y - g_MySelf.m_nCurrY);
      if nC < n10 then
      begin
        n10 := nC;
        n14 := i;
      end;
    end;
    g_APStep := n14;
  end;
end;

procedure TfrmMain.ExchgScreen();
var
  k: Integer;
  Actor: TActor;
begin
  g_bCanDraw := False;
  g_InitTime := timeGetTime;
  ReleaseAllImageCache();
  g_PlayScene.UnInitSurface;
  FrmDlg.UnInitGrobalSurface();
  try
    DXDraw.Finalize;
    if doFullScreen in DXDraw.Options then
    begin
      RestoreWindow;

      BorderStyle := bsSingle;
      DXDraw.Options := DXDraw.Options - [doFullScreen];
    end
    else
    begin
      StoreWindow;

      BorderStyle := bsNone;
      DXDraw.Options := DXDraw.Options + [doFullScreen];
    end;
    g_boFullScreen := doFullScreen in DXDraw.Options;
    ChgDisplayMode();
    DXDraw.Initialize;
  finally
    DXDrawReInit();

    g_PlayScene.InitSurface;
    for k := 0 to g_PlayScene.m_ActorList.count - 1 do
    begin
      Actor := g_PlayScene.m_ActorList[k];
      Actor.m_dwLoadSurfaceTime := GetTickCount;
      Actor.LoadSurface;
    end;

    FrmDlg.InitGrobalSurface();
    FrmDlg.BuildBottomWinSurface(g_boHero);

    g_bReIntMap := True;
    g_InitTime := timeGetTime;
    g_bCanDraw := True;
    if not g_boFullScreen then
    begin
      SendToBack();
      BringToFront();
    end;
  end;
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  M, k, MD: Word;
  wc: Integer;
  ini: TIniFile;
begin
  case Key of
//    VK_F2: begin
//        frmCaptcha.Parent := self;
//        frmCaptcha.BorderStyle := bsSizeToolWin;
//        frmCaptcha.Position := poMainFormCenter;
//        frmCaptcha.Show;
//      end;
//    VK_F3: begin
//        ExitProcess(0);
//      end  ;
    VK_PAUSE:
      begin
        Key := 0;
        FPrintScreenNow := True;
      end;
    VK_RETURN: if (ssAlt in Shift) then
      begin
        //取消游戏内切换窗口模式功能 2019-11-15
        {
        if not g_DlgInitialize then
        begin
          Key := 0;
          ExchgScreen();
        end;  }

      end;
  end;

  case Key of
    VK_UP:
      if ssCtrl in Shift  then                                  // and FrmDlg.DEdChat.Visible
      begin
        if  g_SendSayList.count = 0 then Exit;
        if not FrmDlg.DEdChat.Visible then
          g_SendSayListIdx := g_SendSayList.count - 1           //  ctrl + 下 显示最后一行
        else if g_SendSayListIdx > 0 then
          Dec(g_SendSayListIdx);

        FrmDlg.DEdChat.Visible := True;
        FrmDlg.DEdChat.SetFocus;                                //   上下键换行光标定到行尾  2019-11-12 20:56:34
        if g_SendSayListIdx < g_SendSayList.count then
          FrmDlg.DEdChat.Text := g_SendSayList[g_SendSayListIdx];
        Key := 0;
        FrmDlg.DEdChat.ChangeCurPos(Length(FrmDlg.DEdChat.Text), True);
        FrmDlg.DEdChat.SelLength := 0;
      end;
    VK_DOWN:
      if ssCtrl in Shift  then                                  // and FrmDlg.DEdChat.Visible
      begin
        if  g_SendSayList.count = 0 then Exit;
        if not FrmDlg.DEdChat.Visible then
          g_SendSayListIdx := g_SendSayList.count - 1          //  ctrl + 下 显示最后一行
        else if g_SendSayListIdx < g_SendSayList.count - 1 then
          Inc(g_SendSayListIdx);

        FrmDlg.DEdChat.Visible := True;
        FrmDlg.DEdChat.SetFocus;                                //   上下键换行光标定到行尾  2019-11-12 20:56:34

        if g_SendSayListIdx < g_SendSayList.count then
          FrmDlg.DEdChat.Text := g_SendSayList[g_SendSayListIdx];
        Key := 0;
        FrmDlg.DEdChat.ChangeCurPos(Length(FrmDlg.DEdChat.Text), True);
        FrmDlg.DEdChat.SelLength := 0;
      end;
  end;

  if (g_MySelf = nil) or (DScreen.CurrentScene <> g_PlayScene) then Exit;

  if g_gcHotkey[0] then
  begin
    MD := 0;
    if ssCtrl in Shift then
      MD := MD or MOD_CONTROL;
    if ssAlt in Shift then
      MD := MD or MOD_ALT;
    if ssShift in Shift then
      MD := MD or MOD_SHIFT;
    if (MD <> 0) or ((MD = 0) and not FrmDlg.DEdChat.Visible) then
    begin
{$I '..\Common\Macros\VMPBM.inc'}
      if FrmDlg.DEHeroCallHero.HotKey <> 0 then
      begin
        SeparateHotKey(FrmDlg.DEHeroCallHero.HotKey, M, k);
        if (MD = M) and (Key = k) then
        begin
          g_pbRecallHero^ := True;
          FrmDlg.ClientCallHero();
          Exit;
        end;
      end;
{$I '..\Common\Macros\VMPE.inc'}
      if FrmDlg.DEHeroSetTarget.HotKey <> 0 then
      begin
        SeparateHotKey(FrmDlg.DEHeroSetTarget.HotKey, M, k);
        if (MD = M) and (Key = k) then
        begin
          if (g_MySelf <> nil) and (g_MySelf.m_HeroObject <> nil) and (g_FocusCret <> nil) then
          begin
            SendHeroSetTarget();
            Exit;
          end;
        end;
      end;
      if FrmDlg.DEHeroUnionHit.HotKey <> 0 then
      begin
        SeparateHotKey(FrmDlg.DEHeroUnionHit.HotKey, M, k);
        if (MD = M) and (Key = k) then
        begin
          if (g_MySelf <> nil) and (g_MySelf.m_HeroObject <> nil) then
          begin
            SendHeroJoinAttack();
            Exit;
          end;
        end;
      end;
      if FrmDlg.DEHeroSetAttackState.HotKey <> 0 then
      begin
        SeparateHotKey(FrmDlg.DEHeroSetAttackState.HotKey, M, k);
        if (MD = M) and (Key = k) then
        begin
          if (g_MySelf <> nil) and (g_MySelf.m_HeroObject <> nil) then
          begin
            SendSay('@RestHero');
            Exit;
          end;
        end;
      end;
      if FrmDlg.DEHeroSetGuard.HotKey <> 0 then
      begin
        SeparateHotKey(FrmDlg.DEHeroSetGuard.HotKey, M, k);
        if (MD = M) and (Key = k) then
        begin
          if (g_MySelf <> nil) and (g_MySelf.m_HeroObject <> nil) and (g_FocusCret = nil) then
          begin
            SendHeroSetGuard;
            Exit;
          end;
        end;
      end;
      if FrmDlg.DESwitchAttackMode.HotKey <> 0 then
      begin
        SeparateHotKey(FrmDlg.DESwitchAttackMode.HotKey, M, k);
        if (MD = M) and (Key = k) then
        begin
          if (g_MySelf <> nil) then
          begin
            SendSay('@AttackMode');
            Exit;
          end;
        end;
      end;
      if FrmDlg.DESwitchMiniMap.HotKey <> 0 then
      begin
        SeparateHotKey(FrmDlg.DESwitchMiniMap.HotKey, M, k);
        if (MD = M) and (Key = k) then
        begin
          if (g_MySelf <> nil) then
          begin
            SwitchMiniMap();
            Exit;
          end;
        end;
      end;
      if FrmDlg.DxEditSSkill.HotKey <> 0 then
      begin
        SeparateHotKey(FrmDlg.DxEditSSkill.HotKey, M, k);
        if (MD = M) and (Key = k) then
        begin
          if (g_MySelf <> nil) then
          begin
            SendFireSerieSkill();
            //SeriesSkillFire();
            Exit;
          end;
        end;
      end;
    end;
  end;

  case Key of
    VK_F1, VK_F2, VK_F3, VK_F4, VK_F5, VK_F6, VK_F7, VK_F8:
      begin
        if g_boSpeedRate then
        begin
          if GetTickCount - g_dwLatestSpellTick > (g_dwSpellTime + g_dwMagicDelayTime - g_MagSpeedRate * 20) then
          begin
            if ssCtrl in Shift then
              ActionKey := Key - 100
            else
              ActionKey := Key;
          end;
        end
        else
        begin
          if GetTickCount - g_dwLatestSpellTick > (g_dwSpellTime + g_dwMagicDelayTime) then
          begin
            if ssCtrl in Shift then
              ActionKey := Key - 100
            else
              ActionKey := Key;
          end;
        end;
        Key := 0;
      end;
    VK_F9:
      begin
        FrmDlg.OpenItemBag;
      end;
    VK_F10:
      begin
        FrmDlg.StatePage := 0;
        FrmDlg.OpenMyStatus;
      end;
    VK_F11:
      begin
        if g_MySelf <> nil then
          g_MySelf.n_boState := False;
          if g_boUI0508 then
            FrmDlg.StatePage := 3
          else
            FrmDlg.StatePage := 5;
        FrmDlg.OpenMyStatus;
      end;
    VK_F12:
      begin
        FrmDlg.DOptionClick;
      end;
    VK_ESCAPE:
      begin
        g_gcGeneral[4] := not g_gcGeneral[4];
        if g_gcGeneral[4] then
          DScreen.AddChatBoardString('[物品显示打开]', clWhite, clblack)
        else
          DScreen.AddChatBoardString('[物品显示关闭]', clWhite, clblack);
      end;
    Word('B'):
      begin
      end;
    Word('N'): FrmDlg.ClientHeroState();
    Word('H'): if ssCtrl in Shift then
        SendSay('@AttackMode');
    Word('A'): if ssCtrl in Shift then
        SendSay('@rest');
    Word('D'):
      begin
        if ssCtrl in Shift then
        begin
          SendFireSerieSkill();
          //SeriesSkillFire();
        end
        else if ssAlt in Shift then
        begin
          {if (g_FocusCret <> nil) and (g_FocusCret <> g_MySelf) and (g_FocusCret.m_btRace = 0) and (not g_FocusCret.m_boIsHero) then begin
            wc := FrmDlg.m_BlockList.IndexOf(g_FocusCret.m_sUserName);
            if wc >= 0 then begin
              FrmDlg.m_BlockList.Delete(wc);
              FrmDlg.DFrdSave();
            end;
          end;}
        end;
      end;
    Word('E'): if ssCtrl in Shift then
        SendSay('@RestHero')
      else if ssAlt in Shift then
      begin
        if (g_FocusCret <> nil) and (g_FocusCret <> g_MySelf) and (g_FocusCret.m_btRace = 0) and (g_FocusCret.m_btIsHero = 0) then
          SendDelGroupMember(g_FocusCret.m_sUserName)
      end;
    Word('S'): if ssCtrl in Shift then
      begin
        if (g_MySelf.m_HeroObject <> nil) then
          SendHeroJoinAttack();
      end
      else if ssAlt in Shift then
      begin
        if (g_FocusCret <> nil) and (g_FocusCret <> g_MySelf) and (g_FocusCret.m_btRace = 0) and (g_FocusCret.m_btIsHero = 0) then
        begin
          wc := FrmDlg.m_BlockList.IndexOf(g_FocusCret.m_sUserName);
          if wc >= 0 then
          begin
            FrmDlg.m_BlockList.Delete(wc);
            FrmDlg.DFrdSave();
            DScreen.AddChatBoardString('您已经将' + g_FocusCret.m_sUserName + '从黑名单清除', GetRGB(219), clWhite);
          end
          else
          begin
            FrmDlg.m_BlockList.Add(g_FocusCret.m_sUserName);
            FrmDlg.DFrdSave();
            DScreen.AddChatBoardString('您已经将' + g_FocusCret.m_sUserName + '放入黑名单', GetRGB(219), clWhite);
          end;
        end;
      end;
    Word('W'):
      begin
        if ssCtrl in Shift then
        begin
          SendHeroSetTarget;
        end
        else if ssAlt in Shift then
        begin
          if (g_FocusCret <> nil) and (g_FocusCret <> g_MySelf) and (g_FocusCret.m_btRace = 0) and (g_FocusCret.m_btIsHero = 0) then
          begin
            if g_GroupMembers.count = 0 then
              SendCreateGroup(g_FocusCret.m_sUserName)
            else
              SendAddGroupMember(g_FocusCret.m_sUserName);
            FrmDlg.DEdChat.Text := g_FocusCret.m_sUserName;
          end;
        end;
      end;
    Word('F'):
      begin
        if ssCtrl in Shift then
        begin
          {if g_nCurFont < MAXFONT - 1 then
            Inc(g_nCurFont)
          else
            g_nCurFont := 0;
          g_sCurFontName := g_FontArr[g_nCurFont];
          frmMain.Font.Name := g_sCurFontName;
          frmMain.Canvas.Font.Name := g_sCurFontName;
          DXDraw.Surface.Canvas.Font.Name := g_sCurFontName;
          FrmDlg.DEdChat.Font.Name := g_sCurFontName;
          ini := TIniFile.Create('.\lscfg.ini');
          if ini <> nil then begin
            ini.WriteString('Setup', 'FontName', g_sCurFontName);
            ini.Free;
          end;}
        end;
      end;
    Word('M'):
      begin
        if g_boFindpathMyMap then
        begin
          if not FrmDlg.DEdChat.Visible  and g_boFindpathMyMap then
          begin
            SendWantMiniMap;
            Frmdlg.WinFindPathBack.Visible := not Frmdlg.WinFindPathBack.Visible;
          end;
        end;
      end;
    Word('Z'):
      begin
        if ssCtrl in Shift then
        begin
          g_gcAss[0] := not g_gcAss[0];
          frmMain.TimerAutoPlay.Enabled := g_gcAss[0];
          if frmMain.TimerAutoPlay.Enabled then
          begin
            g_APTagget := nil;
            g_AutoPicupItem := nil;
            g_nAPStatus := -1;
            g_nTargetX := -1;
            g_APGoBack := False;
            DScreen.AddChatBoardString('[挂机] 开始自动挂机...', clWhite, clRed);
            SaveWayPoint;
            if (g_APMapPath <> nil) then
            begin
              g_APStep := 0;
              g_APLastPoint.X := -1;
              GetNearPoint();
            end;
            if (g_MySelf.m_HeroObject = nil) then
            begin
              FrmDlg.m_dwUnRecallHeroTick := GetTickCount - 58000;
            end;
          end
          else
          begin
            //SetLength(g_APMapPath, 0);
            //SetLength(g_APMapPath2, 0);
            //g_APStep := -1;
            //g_APLastPoint.X := -1;
            DScreen.AddChatBoardString('[挂机] 停止自动挂机...', clWhite, clRed);
          end;
          Exit;
        end;
        if not FrmDlg.DEdChat.Visible then
        begin
          //if CanNextAction and ServerAcceptNextAction then
          g_gcGeneral[0] := not g_gcGeneral[0];
          if g_gcGeneral[0] then
            DScreen.AddChatBoardString('[显示人物名字]', clWhite, clblack)
          else
            DScreen.AddChatBoardString('[隐藏人物名字]', clWhite, clblack);
          ini := TIniFile.Create('.\Config\' + g_sServerName + '.' + frmMain.m_sCharName + '.Set');
          ini.WriteBool('Basic', 'ShowActorName', g_gcGeneral[0]);
          ini.Free;
        end;
      end;
    Word('X'):
      begin
        if g_MySelf = nil then
          Exit;
        if g_boOpenAutoPlay and (Shift = [ssCtrl, ssAlt]) then
        begin
          g_gcAss[0] := not g_gcAss[0];
          frmMain.TimerAutoPlay.Enabled := g_gcAss[0];
          if frmMain.TimerAutoPlay.Enabled then
          begin
            g_APTagget := nil;
            g_AutoPicupItem := nil;
            g_nAPStatus := -1;
            g_nTargetX := -1;
            g_APGoBack := False;
            DScreen.AddChatBoardString('[挂机] 开始自动挂机...', clWhite, clRed);
            SaveWayPoint;
            if (g_APMapPath <> nil) then
            begin
              g_APStep := 0;
              g_APLastPoint.X := -1;
              GetNearPoint();
            end;
            if (g_MySelf.m_HeroObject = nil) then
            begin
              FrmDlg.m_dwUnRecallHeroTick := GetTickCount - 58000;
            end;
          end
          else
          begin
            //SetLength(g_APMapPath, 0);
            //SetLength(g_APMapPath2, 0);
            //g_APStep := -1;
            //g_APLastPoint.X := -1;
            DScreen.AddChatBoardString('[挂机] 停止自动挂机...', clWhite, clRed);
          end;
          Exit;
        end;
        if (Shift = [ssCtrl]) then
        begin
          FrmDlg.DBDetectBoxDblClick(nil);
          Exit;
        end;
        if ssAlt in Shift then
          AppLogout
        else if not FrmDlg.DEdChat.Visible then
        begin
          g_gcGeneral[1] := not g_gcGeneral[1];
          ini := TIniFile.Create('.\Config\' + g_sServerName + '.' + frmMain.m_sCharName + '.Set');
          ini.WriteBool('Basic', 'DuraWarning', g_gcGeneral[1]);
          ini.Free;
        end;
      end;
    Word('C'):
      begin
        if not FrmDlg.DEdChat.Visible then
        begin
          g_gcGeneral[2] := not g_gcGeneral[2];
          if g_gcGeneral[2] then
            DScreen.AddChatBoardString('[免Shift 开]', clWhite, clblack)
          else
            DScreen.AddChatBoardString('[免Shift 关]', clWhite, clblack);
          ini := TIniFile.Create('.\Config\' + g_sServerName + '.' + frmMain.m_sCharName + '.Set');
          ini.WriteBool('Basic', 'AutoAttack', g_gcGeneral[2]);
          ini.Free;
        end;
      end;
    Word('V'):
      begin
        {if ssCtrl in Shift then begin
          if g_MySelf.m_HeroObject <> nil then
            SendClientMessage(CM_QUERYHEROBAGITEMS, 0, 0, 0, 0);
        end else}
        if not FrmDlg.DEdChat.Visible then
        begin
          g_gcGeneral[8] := not g_gcGeneral[8];
          if g_gcGeneral[8] then
            DScreen.AddChatBoardString('[隐藏怪物尸体]', clWhite, clblack)
          else
            DScreen.AddChatBoardString('[显示怪物尸体]', clWhite, clblack);
          ini := TIniFile.Create('.\Config\' + g_sServerName + '.' + frmMain.m_sCharName + '.Set');
          ini.WriteBool('Basic', 'HideDeathBody', g_gcGeneral[2]);
          ini.Free;
          SendClientMessage(CM_HIDEDEATHBODY, g_MySelf.m_nRecogId, Integer(g_gcGeneral[8]), 0, 0);
        end;
      end;
    Word('Q'):
      begin
        if g_MySelf = nil then
          Exit;
        if ssAlt in Shift then
          AppExit;
        if ssCtrl in Shift then
        begin
          if (g_MySelf.m_HeroObject <> nil) and (g_FocusCret = nil) then
            SendHeroSetGuard;
        end;
      end;
    Word('T'):
      begin
        if not FrmDlg.DEdChat.Visible then
        begin
          if GetTickCount > g_dwQueryMsgTick then
          begin
            g_dwQueryMsgTick := GetTickCount + 3000;
            frmMain.SendDealTry;
          end;
        end;
      end;
    Word('R'): if not FrmDlg.DEdChat.Visible then
      begin
        // FrmDlg.DMyStateClick(FrmDlg.DBotBelt, 0, 0);
        if ssCtrl in Shift then
          SendClientMessage(CM_QUERYBAGITEMS, 0, 0, 0, 0)
        else if (g_MySelf.m_HeroObject <> nil) and (ssAlt in Shift) then
          SendClientMessage(CM_QUERYHEROBAGITEMS, 0, 0, 0, 0)
        else
          FrmDlg.DButtonHeroBagClick(nil, 0, 0);
      end;
    Word('O'): if not FrmDlg.DEdChat.Visible then
      begin
        FrmDlg.DBMissionOpenClick(nil, 0, 0);
      end;
    Word('G'):
      begin
        if not FrmDlg.DEdChat.Visible then
        begin
          if FrmDlg.DGuildDlg.Visible then
          begin
            FrmDlg.DGuildDlg.Visible := False;
          end
          else if GetTickCount > g_dwQueryMsgTick then
          begin
            g_dwQueryMsgTick := GetTickCount + 3000;
            frmMain.SendGuildDlg;
          end;
        end;
      end;
    Word('P'):
      begin
        if not FrmDlg.DEdChat.Visible then
          FrmDlg.ToggleShowGroupDlg;
      end;
     13:                                                // enter键触发输入框确定按钮  
      begin
        if FrmDlg.DMsgDlg.Visible and FrmDlg.DMsgDlgOk.Visible then
        begin
          FrmDlg.DMsgDlgOkClick(FrmDlg.DMsgDlgOk,0,0);
        end;

        if FrmDlg.DEdChat.Visible and (FrmDlg.DEdChat.Text <> '') and
        (g_SendSayListIdx <= g_SendSayList.Count - 1) and (FrmDlg.DEdChat.Text = g_SendSayList[g_SendSayListIdx]) then
        begin
          g_SendSayList.Delete(g_SendSayListIdx);
          g_SendSayList.Add(FrmDlg.DEdChat.Text);
          g_SendSayListIdx := g_SendSayList.Count - 1;
        end;
      end;
  end;

  if g_DWinMan.KeyDown(Key, Shift) then  Exit;

  case Key of
    VK_UP:
      begin
        if  ssCtrl in Shift  then                       // and FrmDlg.DEdChat.Visible    回到最上面
        begin
          FrmDlg.DEdChat.Visible := True;
          FrmDlg.DEdChat.SetFocus;                     //   上下键换行光标定到行尾  2019-11-12 20:56:34
          if g_SendSayListIdx < g_SendSayList.count then FrmDlg.DEdChat.Text := g_SendSayList[g_SendSayListIdx];
          Key := 0;
          FrmDlg.DEdChat.ChangeCurPos(Length(FrmDlg.DEdChat.Text), True);
          FrmDlg.DEdChat.SelLength := Length(FrmDlg.DEdChat.Text);
        end
        else
        begin
          with DScreen do
          begin
            if ChatBoardTop > 0 then
            begin
              Dec(ChatBoardTop);
            end;
          end;
        end;
      end;
    VK_DOWN:
      if ssCtrl in Shift  then  // and FrmDlg.DEdChat.Visible   回到底部
      begin
        FrmDlg.DEdChat.Visible := True;
        FrmDlg.DEdChat.SetFocus;                    //   上下键换行光标定到行尾  2019-11-12 20:56:34
        if g_SendSayListIdx < g_SendSayList.count - 1 then
          Inc(g_SendSayListIdx);
        if g_SendSayListIdx < g_SendSayList.count then
          FrmDlg.DEdChat.Text := g_SendSayList[g_SendSayListIdx];
        Key := 0;
        FrmDlg.DEdChat.ChangeCurPos(Length(FrmDlg.DEdChat.Text), True);
        FrmDlg.DEdChat.SelLength := 0;
      end
      else
      begin
        with DScreen do
        begin
          if ChatBoardTop < ChatStrs.count - 1 then
          begin
            Inc(ChatBoardTop);
          end;
        end;
      end;
    VK_PRIOR:
      with DScreen do
      begin
        if ChatBoardTop > VIEWCHATLINE then
          ChatBoardTop := ChatBoardTop - VIEWCHATLINE
        else
          ChatBoardTop := 0;
      end;
    VK_NEXT:
      with DScreen do
      begin
        if ChatBoardTop + VIEWCHATLINE < ChatStrs.count - 1 then
          ChatBoardTop := ChatBoardTop + VIEWCHATLINE
        else
          ChatBoardTop := ChatStrs.count - 1;
        if ChatBoardTop < 0 then
          ChatBoardTop := 0;
      end;

    VK_HOME:
      with DScreen do
      begin
        ChatBoardTop := 0;
      end;
    VK_END:
      with DScreen do
      begin
        ChatBoardTop := ChatStrs.count - 1;
      end;
  end;
  FrmDlg.DMBChat.UpdatePos(DScreen.ChatBoardTop);
end;

procedure TfrmMain.FormKeyPress(Sender: TObject; var Key: Char);
begin

  if not IntroScene.m_boOnClick then
  begin
    IntroScene.m_boOnClick := True;
    IntroScene.m_dwStartTime := GetTickCount + 100;
    Exit;
  end;
  if g_DWinMan.KeyPress(Key) then
    Exit;
  if DScreen.CurrentScene = g_PlayScene then
  begin
    if FrmDlg.DEdChat.Visible and (FrmDlg.DEdChat <> MouseCaptureControl) then
    begin
      frmMain.SendSay(FrmDlg.DEdChat.Text);
      FrmDlg.DEdChat.Text := '';
      FrmDlg.DEdChat.Visible := False;
      if not g_ChatStatusLarge then
        FrmDlg.DBChat.Visible := False;
      Key := #0;
      Exit;
    end;
    
    case BYTE(Key) of
      BYTE('`'):
        begin
          if not FrmDlg.DEdChat.Visible then
            if CanNextAction and ServerAcceptNextAction then
              SendPickup;
        end;
      BYTE('1')..BYTE('6'): EatItem(BYTE(Key) - BYTE('1'));
      //27: Close;
      BYTE(' '), 13:
        begin
          FrmDlg.DEdChat.Visible := True;
          FrmDlg.DEdChat.SetFocus;
          //SetImeMode(FrmDlg.DEdChat.Handle, g_LocalLanguage);
          if FrmDlg.BoGuildChat then
          begin
            FrmDlg.DEdChat.Text := '!~';
            FrmDlg.DEdChat.ChangeCurPos(Length(FrmDlg.DEdChat.Text), True);
            FrmDlg.DEdChat.SelLength := 0;
          end
          else
          begin
            FrmDlg.DEdChat.Text := '';
          end;
        end;
      BYTE('@'), BYTE('!'), BYTE('/'):
        begin
          FrmDlg.DEdChat.Visible := True;
          FrmDlg.DEdChat.SetFocus;
          //SetImeMode(FrmDlg.DEdChat.Handle, g_LocalLanguage);
          if Key = '/' then
          begin
            if WhisperName = '' then
              FrmDlg.DEdChat.Text := Key
            else if Length(WhisperName) > 2 then
              FrmDlg.DEdChat.Text := '/' + WhisperName + ' '
            else
              FrmDlg.DEdChat.Text := Key;
            FrmDlg.DEdChat.ChangeCurPos(Length(FrmDlg.DEdChat.Text), True);
            FrmDlg.DEdChat.SelLength := 0;
          end
          else
          begin
            FrmDlg.DEdChat.Text := Key;
            //FrmDlg.DEdChat.SelStart := 1;
            FrmDlg.DEdChat.ChangeCurPos(Length(FrmDlg.DEdChat.Text), True);
            FrmDlg.DEdChat.SelLength := 0;
          end;
        end;
    end;
    Key := #0;
  end;
end;

function TfrmMain.GetMagicByKey(Key: Char): PTClientMagic;
var
  i: Integer;
  pm: PTClientMagic;
begin
  Result := nil;
  for i := 0 to g_MagicList.count - 1 do
  begin
    pm := PTClientMagic(g_MagicList[i]);
    if pm.Key = Key then
    begin
      Result := pm;
      Break;
    end;
  end;
end;

var
  g_dwOverSpaceWarningTick: LongWord;

procedure TfrmMain.UseMagic(tx, ty: Integer; pcm: PTClientMagic; boReacll: Boolean; boContinue: Boolean);
var
  boSeriesSkill: Boolean;
  defSpellSpend: Integer;
  tdir, targx, targy, targid: Integer;
  pmag: PTUseMagicInfo;
  SpellSpend: Word;
  fUnLockMagic: Boolean;
label
  labSpell;
begin
  if (g_MySelf <> nil) and g_MySelf.m_StallMgr.OnSale then
  begin
    Exit;
  end;
  if pcm = nil then
    Exit;
  if pcm.Def.wMagicid = 0 then
    Exit;

  SpellSpend := Round(pcm.Def.wSpell / (pcm.Def.btTrainLv + 1) * (pcm.level + 1)) + pcm.Def.btDefSpell;

  if pcm.Def.wMagicid = 114 then
  begin
    if g_boSkill_114_MP then
      boSeriesSkill := False
    else
      boSeriesSkill := True;
  end
  else if pcm.Def.wMagicid in [68, 78] then
  begin
    if g_boSkill_68_MP then
      boSeriesSkill := False
    else
      boSeriesSkill := True;
  end
  else
    boSeriesSkill := pcm.Def.wMagicid in [100..111];

  if boSeriesSkill then
  begin
    defSpellSpend := g_MySelf.m_nIPower
  end
  else
  begin
    defSpellSpend := g_MySelf.m_Abil.MP;
  end;

  if (SpellSpend <= defSpellSpend) then
  begin
    if pcm.Def.btEffectType = 0 then
    begin
      if pcm.Def.wMagicid in [68, 78] then
      begin
        boContinue := True;
        goto labSpell;
      end;

      if pcm.Def.wMagicid = 26 then
      begin //烈火时间间隔
        if g_boNextTimeFireHit or (GetTickCount - g_dwLatestFireHitTick <= 10 * 1000) then
          Exit;
      end;
      if pcm.Def.wMagicid = 66 then
      begin
        if g_boCanSLonHit or (GetTickCount - g_dwLatestSLonHitTick <= 8 * 1000) then
          Exit;
      end;
      if pcm.Def.wMagicid = 43 then
      begin
        if g_boNextTimeTwinHit or (GetTickCount - g_dwLatestTwinHitTick <= 15 * 1000) then
          Exit;
      end;
      if pcm.Def.wMagicid = 56 then
      begin
        if g_boNextTimePursueHit or (GetTickCount - g_dwLatestPursueHitTick <= 10 * 1000) then
          Exit;
      end;
      if (pcm.Def.wMagicid in [27]) then
      begin //野蛮时间间隔
        if (GetTickCount - g_dwLatestRushRushTick <= 3 * 1000) then
          Exit;
      end;

      ///////////////////////////////////////////////
      if pcm.Def.wMagicid = 100 then
      begin
        if boContinue or (CanNextAction and ServerAcceptNextAction and CanNextHit) then
        begin

        end
        else
          Exit;
      end;

      if pcm.Def.wMagicid = 101 then
      begin
        if g_boNextTimeSmiteHit or (GetTickCount - g_dwLatestSmiteHitTick <= 1 * 100) then
          Exit;
      end;
      if pcm.Def.wMagicid = 102 then
      begin
        if g_boNextTimeSmiteLongHit or (GetTickCount - g_dwLatestSmiteLongHitTick <= 1 * 100) then
          Exit;
      end;
      if pcm.Def.wMagicid = 103 then
      begin
        if g_boNextTimeSmiteWideHit or (GetTickCount - g_dwLatestSmiteWideHitTick <= 1 * 100) then
          Exit;
      end;
      if pcm.Def.wMagicid = 113 then
      begin
        if g_boNextTimeSmiteLongHit2 or (GetTickCount - g_dwLatestSmiteLongHitTick2 <= 10 * 1000) then
          Exit;
      end;
      if pcm.Def.wMagicid = 114 then
      begin
        if g_boNextTimeSmiteWideHit2 or (GetTickCount - g_dwLatestSmiteWideHitTick2 <= 2 * 1000) then
          Exit;
      end;
      if pcm.Def.wMagicid = 115 then
      begin
        if g_boNextTimeSmiteLongHit3 or (GetTickCount - g_dwLatestSmiteLongHitTick3 <= 2 * 1000) then
          Exit;
      end;
      if g_boSpeedRate then
      begin
        if boContinue or (GetTickCount - g_dwLatestSpellTick > g_dwSpellTime - g_MagSpeedRate * 20) then
        begin
          g_dwLatestSpellTick := GetTickCount;
          g_dwMagicDelayTime := 0;

          SendSpellMsg(CM_SPELL, g_MySelf.m_btDir {x}, 0, pcm.Def.wMagicid, 0, False);
        end;
      end
      else
      begin
        if boContinue or (GetTickCount - g_dwLatestSpellTick > g_dwSpellTime) then
        begin
          g_dwLatestSpellTick := GetTickCount;
          g_dwMagicDelayTime := 0;
          SendSpellMsg(CM_SPELL, g_MySelf.m_btDir {x}, 0, pcm.Def.wMagicid, 0, False);
        end;
      end;
      //g_MySelf.SendMsg(CM_SPELL, targx, targy, tdir, Integer(pmag), targid, '', 0);

      //DScreen.AddChatBoardString(Format('%d:%d', [pcm.Def.wMagicid, SpellSpend]), GetRGB(5), clWhite);

    end
    else
    begin
      labSpell:
      fUnLockMagic := (pcm.Def.wMagicid in [2, 9, 10, 14..19, 21..31, 33..35, 37..39, 41, 46..48, 50..55, 58, 70, 72, 75..103]);
      if fUnLockMagic then
        g_MagicTarget := g_FocusCret
      else
      begin
        if g_boMagicLock and (g_PlayScene.IsValidActor(g_FocusCret) and not g_FocusCret.m_boDeath) then
          g_MagicLockActor := g_FocusCret;
        g_MagicTarget := g_MagicLockActor;
      end;
      if g_MagicTarget <> nil then
      begin
        if not g_boMagicLock or
          g_MagicTarget.m_boDeath or
          (g_MagicTarget.m_btRace = RCC_MERCHANT) or
          not g_PlayScene.IsValidActor(g_MagicTarget) then
        begin
          g_MagicTarget := nil;
          g_MagicLockActor := nil;
        end;
      end;
      if (g_MagicTarget <> nil) and (g_MagicTarget is THumActor) then
      begin
        if THumActor(g_MagicTarget).m_StallMgr.OnSale then
        begin
          g_MagicTarget := nil;
          g_MagicLockActor := nil;
        end;
      end;
      SmartChangePoison(pcm);

      if g_MagicTarget = nil then
      begin
        g_nCurrentMagic := 888;
        if not boReacll then
          g_PlayScene.CXYfromMouseXY(tx, ty, targx, targy)
        else
        begin
          targx := tx;
          targy := ty;
        end;
        targid := 0;
      end
      else
      begin
        if not boReacll then
        begin
          targx := g_MagicTarget.m_nCurrX;
          targy := g_MagicTarget.m_nCurrY;
        end
        else
        begin
          targx := tx;
          targy := ty;
        end;
        targid := g_MagicTarget.m_nRecogId;
      end;
      if (abs(g_MySelf.m_nCurrX - targx) > g_nMagicRange) or (abs(g_MySelf.m_nCurrY - targy) > g_nMagicRange) then
      begin
        if g_gcTec[14] and (fUnLockMagic or (targid <> 0)) then
        begin
          g_PlayScene.ProcMagic.nTargetX := targx;
          g_PlayScene.ProcMagic.nTargetY := targy;
          g_PlayScene.ProcMagic.xMagic := pcm^;
          g_PlayScene.ProcMagic.xTarget := g_MagicLockActor;
          g_PlayScene.ProcMagic.fReacll := boReacll;
          g_PlayScene.ProcMagic.fContinue := boContinue;
          g_PlayScene.ProcMagic.fUnLockMagic := fUnLockMagic;
          g_PlayScene.ProcMagic.dwTick := GetTickCount;
        end
        else
        begin
          if GetTickCount - g_dwOverSpaceWarningTick > 1000 then
          begin
            g_dwOverSpaceWarningTick := GetTickCount;
            DScreen.AddSysMsg('目标太远了，施展魔法失败！！！');
          end;
          g_PlayScene.ProcMagic.nTargetX := -1;
        end;
        Exit;
      end;

      g_PlayScene.ProcMagic.nTargetX := -1;
      if boContinue or (CanNextAction and ServerAcceptNextAction) then
      begin

        g_dwLatestSpellTick := GetTickCount;

        tdir := GetFlyDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, targx, targy);

        New(pmag);
        FillChar(pmag^, SizeOf(TUseMagicInfo), #0);
        pmag.EffectNumber := pcm.Def.btEffect;
        pmag.MagicSerial := pcm.Def.wMagicid;
        pmag.ServerMagicCode := 0;
        g_dwMagicDelayTime := 200 + pcm.Def.dwDelayTime;

        g_dwMagicPKDelayTime := 0;
        if (g_MagicTarget <> nil) then
        begin
          if g_MagicTarget.m_btRace = 0 then
            g_dwMagicPKDelayTime := 300 + Random(1100); //blue
        end;

        g_MySelf.SendMsg(CM_SPELL, targx, targy, tdir, string(pmag), targid, '', 0);

      end;
    end;
  end
  else
  begin
    if boSeriesSkill then
    begin
      if GetTickCount - g_IPointLessHintTick > 5000 then
      begin
        g_IPointLessHintTick := GetTickCount;
        DScreen.AddSysMsg(Format('需要 %d 内力值才能释放 %s', [SpellSpend, pcm.Def.sMagicName]));
      end;
    end
    else if GetTickCount - g_MPLessHintTick > 1000 then
    begin
      g_MPLessHintTick := GetTickCount;
      DScreen.AddSysMsg(Format('需要 %d 魔法值才能释放 %s', [SpellSpend, pcm.Def.sMagicName]));
    end;
  end;
end;

procedure TfrmMain.UseMagicSpell(who, effnum, targetx, targety, magic_id: Integer);
var
  Actor: TActor;
  adir: Integer;
  UseMagic: PTUseMagicInfo;
begin
  Actor := g_PlayScene.FindActor(who);
  if Actor <> nil then
  begin
    adir := GetFlyDirection(Actor.m_nCurrX, Actor.m_nCurrY, targetx, targety);
    New(UseMagic);
    FillChar(UseMagic^, SizeOf(TUseMagicInfo), #0);
    UseMagic.EffectNumber := effnum mod 255;
    UseMagic.ServerMagicCode := 0;
    UseMagic.MagicSerial := magic_id mod 300;
    Actor.SendMsg(SM_SPELL, effnum div 255, magic_id div 300, adir, string(UseMagic), 0, '', 0);
    Inc(g_nSpellCount);
  end
  else
    Inc(g_nSpellFailCount);
end;

procedure TfrmMain.UseMagicFire(who, efftype, effnum, targetx, targety, target, maglv: Integer);
var
  Actor: TActor;
  Sound: Integer;
begin
  Sound := 0;
  Actor := g_PlayScene.FindActor(who);
  if Actor <> nil then
  begin
    Actor.SendMsg(SM_MAGICFIRE, target, efftype, effnum, string(targetx), targety, IntToStr(maglv), Sound);
    if g_nFireCount < g_nSpellCount then
      Inc(g_nFireCount);
  end;
  g_MagicTarget := nil;
end;

procedure TfrmMain.UseMagicFireFail(who: Integer);
var
  Actor: TActor;
begin
  Actor := g_PlayScene.FindActor(who);
  if Actor <> nil then
    Actor.SendMsg(SM_MAGICFIRE_FAIL, 0, 0, 0, '', 0, '', 0);
  g_MagicTarget := nil;
end;

procedure TfrmMain.ActorAutoEat(Actor: THumActor);
begin
  if not Actor.m_boDeath then
  begin
    ActorCheckHealth(False);
    if g_EatingItem.S.Name = '' then
    begin
      if IsPersentSpc(Actor.m_Abil.HP, Actor.m_Abil.MaxHP) then
        ActorCheckHealth(True);
    end;
  end;
end;

procedure TfrmMain.HeroActorAutoEat(Actor: THumActor);
begin
  if (Actor.m_HeroObject <> nil) and not Actor.m_HeroObject.m_boDeath then
  begin
    HeroActorCheckHealth(False);
    if g_EatingItem.S.Name = '' then
    begin
      if IsPersentSpcHero(Actor.m_HeroObject.m_Abil.HP, Actor.m_HeroObject.m_Abil.MaxHP) then
        HeroActorCheckHealth(True);
    end;
  end;
end;

procedure TfrmMain.ActorCheckHealth(bNeedSP: Boolean);
var
  i, nCount: Integer;
  MaxHP, MaxMP, MaxSP: Integer;
  hidx, midx, sidx, bidx: Integer;
  uhidx, umidx, usidx, ubidx: Integer;
  bHint, bEatOK, bEatSp: Boolean;
begin
  nCount := 0;
  hidx := -1;
  midx := -1;
  sidx := -1;
  bidx := -1;
  uhidx := -1;
  umidx := -1;
  usidx := -1;
  ubidx := -1;
  MaxHP := High(Integer) div 2 - 1;
  MaxMP := High(Integer) div 2 - 1;
  MaxSP := High(Integer) div 2 - 1;
  for i := MAXBAGITEM - (1 + 0) downto 0 do
  begin
    if (g_ItemArr[i].S.Name <> '') and (g_ItemArr[i].S.NeedIdentify < 4) then
    begin
      case g_ItemArr[i].S.StdMode of
        00: case g_ItemArr[i].S.Shape of
            0:
              begin //普通药
                if g_gcProtect[0] and (g_ItemArr[i].S.AC > 0) and (g_ItemArr[i].S.AC < MaxHP) then
                begin
                  MaxHP := g_ItemArr[i].S.AC;
                  hidx := i;
                end;
                if g_gcProtect[1] and (g_ItemArr[i].S.MAC > 0) and (g_ItemArr[i].S.MAC < MaxMP) then
                begin
                  MaxMP := g_ItemArr[i].S.MAC;
                  midx := i;
                end;
              end;
            1:
              begin //速效药
                if g_gcProtect[3] and (g_ItemArr[i].S.AC > 0) and (g_ItemArr[i].S.AC < MaxSP) then
                begin
                  MaxSP := g_ItemArr[i].S.AC;
                  sidx := i;
                end;
              end;
          end;
        2, 3: if g_gcProtect[5] then
          begin
            if CompareText(g_ItemArr[i].S.Name, g_sRenewBooks[g_gnProtectPercent[6]]) = 0 then
              bidx := i;
          end;
        31: case g_ItemArr[i].S.AniCount of
            1: if g_gcProtect[0] then
                uhidx := i;
            2: if g_gcProtect[1] then
                umidx := i;
            3: if g_gcProtect[3] then
                usidx := i;
          else if g_gcProtect[5] and (CompareText(g_ItemArr[i].S.Name, g_sRenewBooks[g_gnProtectPercent[6]] + '包') = 0) then
            ubidx := i;
          end;
      end;
    end
    else
      Inc(nCount);
  end;
  bHint := False;
  bEatSp := False;
  bEatOK := False;
  if GetTickCount - g_MySelf.m_dwMsgHint > 15 * 1000 then
  begin
    g_MySelf.m_dwMsgHint := GetTickCount;
    bHint := True;
  end;
  if not bNeedSP then
  begin
    if g_gcProtect[0] and IsPersentHP(g_MySelf.m_Abil.HP, g_MySelf.m_Abil.MaxHP) then
    begin
      if GetTickCount - g_MySelf.m_dwHealthHP > g_gnProtectTime[0] then
      begin
        g_MySelf.m_dwHealthHP := GetTickCount;
        if hidx > -1 then
        begin
          EatItem(hidx);
          bEatOK := True;
        end
        else if (nCount > 4) and (uhidx > -1) then
        begin
          EatItem(uhidx);
          bEatOK := True;
        end
        else
        begin
          bEatSp := True;
          if bHint then //DScreen.AddChatBoardString('你的金创药已经用完！', clWhite, clBlue);
            DScreen.AddSysMsgCenter('你的金创药已经用完！', clLime, clblack, 10);
          bEatOK := False;
        end;
      end;
    end;
  end;
  if not bNeedSP then
  begin
    if g_gcProtect[1] and IsPersentMP(g_MySelf.m_Abil.MP, g_MySelf.m_Abil.MaxMP) then
    begin
      if GetTickCount - g_MySelf.m_dwHealthMP > g_gnProtectTime[1] then
      begin
        g_MySelf.m_dwHealthMP := GetTickCount;
        if midx > -1 then
        begin
          EatItem(midx);
          bEatOK := True;
        end
        else if (nCount > 4) and (umidx > -1) then
        begin
          EatItem(umidx);
          bEatOK := True;
        end
        else
        begin
          if g_gcProtect[11] then
            bEatSp := True;
          if bHint then // DScreen.AddChatBoardString('你的魔法药已经用完！', clWhite, clBlue);
            DScreen.AddSysMsgCenter('你的魔法药已经用完！', clLime, clblack, 10);
          bEatOK := False;
        end;
      end;
    end;
  end;
  if not bEatOK then
  begin
    if g_gcProtect[3] and (bNeedSP or bEatSp or (g_gcProtect[11] and IsPersentSpc(g_MySelf.m_Abil.MP, g_MySelf.m_Abil.MaxMP))) then
    begin
      if GetTickCount - g_MySelf.m_dwHealthSP > g_gnProtectTime[3] then
      begin
        g_MySelf.m_dwHealthSP := GetTickCount;
        if sidx > -1 then
          EatItem(sidx)
        else if (nCount > 4) and (usidx > -1) then
          EatItem(usidx)
        else if bHint {and not bSH} then
          //DScreen.AddChatBoardString('你的特殊药品已经用完！', clWhite, clBlue);
          DScreen.AddSysMsgCenter('你的特殊药品已经用完！', clLime, clblack, 10);
      end;
    end;
  end;
  if g_gcProtect[5] and IsPersentBook(g_MySelf.m_Abil.HP, g_MySelf.m_Abil.MaxHP) then
  begin
    if GetTickCount - g_MySelf.m_dwHealthBK > g_gnProtectTime[5] then
    begin
      g_MySelf.m_dwHealthBK := GetTickCount;
      if bidx > -1 then
        EatItem(bidx)
      else if (nCount > 4) and (ubidx > -1) then
        EatItem(ubidx)
      else if bHint {and not bSH} then
        //DScreen.AddChatBoardString('你的' + g_sRenewBooks[g_gnProtectPercent[6]] + '已经用完！', clWhite, clBlue);
        DScreen.AddSysMsgCenter('你的' + g_sRenewBooks[g_gnProtectPercent[6]] + '已经用完！', clLime, clblack, 10);
    end;
  end;
end;

procedure TfrmMain.HeroActorCheckHealth(bNeedSP: Boolean);
var
  i, nCount: Integer;
  MaxHP, MaxMP, MaxSP: Integer;
  hidx, midx, sidx: Integer;
  uhidx, umidx, usidx: Integer;
  bHint, bEatOK, bEatSp: Boolean;
begin
  nCount := 0;
  hidx := -1;
  midx := -1;
  sidx := -1;
  uhidx := -1;
  umidx := -1;
  usidx := -1;
  MaxHP := High(Integer) div 2 - 1;
  MaxMP := High(Integer) div 2 - 1;
  MaxSP := High(Integer) div 2 - 1;
  for i := g_nHeroBagSize - 1 {MAXBAGITEM - (1 + 6)} downto 0 do
  begin
    if g_HeroItemArr[i].S.Name <> '' then
    begin
      case g_HeroItemArr[i].S.StdMode of
        00: case g_HeroItemArr[i].S.Shape of
            0:
              begin //普通药
                if (g_HeroItemArr[i].S.AC > 0) and (g_HeroItemArr[i].S.AC < MaxHP) then
                begin
                  MaxHP := g_HeroItemArr[i].S.AC;
                  hidx := i;
                end;
                if (g_HeroItemArr[i].S.MAC > 0) and (g_HeroItemArr[i].S.MAC < MaxMP) then
                begin
                  MaxMP := g_HeroItemArr[i].S.MAC;
                  midx := i;
                end;
              end;
            1:
              begin //速效药
                if (g_HeroItemArr[i].S.AC > 0) and (g_HeroItemArr[i].S.AC < MaxSP) then
                begin
                  MaxSP := g_HeroItemArr[i].S.AC;
                  sidx := i;
                end;
              end;
          end;
        31: case g_HeroItemArr[i].S.AniCount of
            1: uhidx := i;
            2: umidx := i;
            3: usidx := i;
          end;
      end;
    end
    else
      Inc(nCount);
  end;
  bHint := False;
  bEatSp := False;
  bEatOK := False;
  if GetTickCount - g_MySelf.m_HeroObject.m_dwMsgHint > 15 * 1000 then
  begin
    g_MySelf.m_HeroObject.m_dwMsgHint := GetTickCount;
    bHint := True;
  end;
  if not bNeedSP then
  begin
    if g_gcProtect[7] and IsPersentHPHero(g_MySelf.m_HeroObject.m_Abil.HP, g_MySelf.m_HeroObject.m_Abil.MaxHP) then
    begin
      if GetTickCount - g_MySelf.m_HeroObject.m_dwHealthHP > g_gnProtectTime[7] then
      begin
        g_MySelf.m_HeroObject.m_dwHealthHP := GetTickCount;
        if hidx > -1 then
        begin
          HeroEatItem(hidx);
          bEatOK := True;
        end
        else if (nCount > 4) and (uhidx > -1) then
        begin
          HeroEatItem(uhidx);
          bEatOK := True;
        end
        else
        begin
          bEatSp := True;
          if bHint then
            //DScreen.AddChatBoardString(Format('英雄[%s]的金创药已经用完！', [g_MySelf.m_HeroObject.m_sUserName]), clWhite, clBlue);
            DScreen.AddSysMsgCenter(Format('英雄[%s]的金创药已经用完！', [g_MySelf.m_HeroObject.m_sUserName]), clLime, clblack, 10);
          bEatOK := False;
        end;
      end;
    end;
  end;
  if not bNeedSP then
  begin
    if g_gcProtect[8] and IsPersentMPHero(g_MySelf.m_HeroObject.m_Abil.MP, g_MySelf.m_HeroObject.m_Abil.MaxMP) then
    begin
      if GetTickCount - g_MySelf.m_HeroObject.m_dwHealthMP > g_gnProtectTime[8] then
      begin
        g_MySelf.m_HeroObject.m_dwHealthMP := GetTickCount;
        if midx > -1 then
        begin
          HeroEatItem(midx);
          bEatOK := True;
        end
        else if (nCount > 4) and (umidx > -1) then
        begin
          HeroEatItem(umidx);
          bEatOK := True;
        end
        else
        begin
          if g_gcProtect[11] then
            bEatSp := True;
          if bHint then
            //DScreen.AddChatBoardString(Format('英雄[%s]的魔法药已经用完！', [g_MySelf.m_HeroObject.m_sUserName]), clWhite, clBlue);
            DScreen.AddSysMsgCenter(Format('英雄[%s]的魔法药已经用完！', [g_MySelf.m_HeroObject.m_sUserName]), clLime, clblack, 10);
          bEatOK := False;
        end;
      end;
    end;
  end;
  if not bEatOK then
  begin
    if g_gcProtect[9] and (bNeedSP or bEatSp or (g_gcProtect[11] and IsPersentSpcHero(g_MySelf.m_HeroObject.m_Abil.MP, g_MySelf.m_HeroObject.m_Abil.MaxMP))) then
    begin
      if GetTickCount - g_MySelf.m_HeroObject.m_dwHealthSP >= g_gnProtectTime[9] then
      begin
        g_MySelf.m_HeroObject.m_dwHealthSP := GetTickCount;
        if sidx > -1 then
          HeroEatItem(sidx)
        else if (nCount > 4) and (usidx > -1) then
          HeroEatItem(usidx)
        else if bHint {and not bSH} then
          //DScreen.AddChatBoardString(Format('英雄[%s]的特殊药品已经用完！', [g_MySelf.m_HeroObject.m_sUserName]), clWhite, clBlue);
          DScreen.AddSysMsgCenter(Format('英雄[%s]的特殊药品已经用完！', [g_MySelf.m_HeroObject.m_sUserName]), clLime, clblack, 10);
      end;
    end;
  end;
end;

procedure TfrmMain.AutoSupplyBeltItem(nType, idx: Integer; sItem: string);
var
  i: Integer;
begin
  if (idx in [0..5]) and (sItem <> '') then
  begin
    if g_ItemArr[idx].S.Name = '' then
    begin
      for i := MAXBAGITEMCL - 1 downto 6 do
      begin
        if g_ItemArr[i].S.Name = sItem then
        begin
          g_ItemArr[idx] := g_ItemArr[i];
          g_ItemArr[i].S.Name := '';
          Exit;
        end;
      end;
      AutoUnBindItem(nType, sItem);
    end;
  end;
end;

procedure TfrmMain.AutoSupplyBagItem(nType: Integer; sItem: string);
var
  i: Integer;
begin
  for i := MAXBAGITEMCL - 1 downto 6 do
    if g_ItemArr[i].S.Name = sItem then
      Exit;
  AutoUnBindItem(nType, sItem);
end;

procedure TfrmMain.AutoUnBindItem(nType: Integer; sItem: string);
var
  i, n, idx: Integer;
  boUnBindAble: Boolean;
  boIsUnBindItem: Boolean;
begin
  if (sItem <> '') and (nType <> 0) then
  begin
    boIsUnBindItem := False;
    for i := Low(g_UnBindItems) to High(g_UnBindItems) do
    begin
      if sItem = g_UnBindItems[i] then
      begin
        boIsUnBindItem := True;
        Break;
      end;
    end;
    if not boIsUnBindItem then
      Exit;
    n := 0;
    boUnBindAble := False;
    for i := 0 to MAXBAGITEMCL - 1 - 6 do
    begin
      if g_ItemArr[i].S.Name = '' then
      begin
        Inc(n);
        if n >= 5 then
        begin
          boUnBindAble := True;
          Break;
        end;
      end;
    end;
    if not boUnBindAble then
      Exit;
    idx := -1;
    for i := MAXBAGITEMCL - 1 downto 6 do
    begin
      if g_ItemArr[i].S.StdMode = 31 then
      begin
        if g_ItemArr[i].S.Name <> '' then
        begin
          if g_ItemArr[i].S.Shape = nType then
          begin
            idx := i;
            Break;
          end;
        end;
      end;
    end;
    if idx > -1 then
    begin
      SendEat(g_ItemArr[idx].MakeIndex, '', g_ItemArr[idx].S.StdMode);
      if (g_ItemArr[idx].S.Overlap >= 1) and (g_ItemArr[idx].Dura > 1) then
      begin
        g_ItemArr[idx].Dura := g_ItemArr[idx].Dura - 1;
        g_EatingItem := g_ItemArr[idx];
        //g_ItemArr[idx].S.Name := '';
        m_nEatRetIdx := -1; //0905
      end
      else
      begin
        g_ItemArr[idx].Dura := g_ItemArr[idx].Dura - 1;
        g_EatingItem := g_ItemArr[idx];
        g_ItemArr[idx].S.Name := '';
        m_nEatRetIdx := -1; //0905
      end;
    end;
  end;
end;

function TfrmMain.EatItemName(Str: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  if (Str = '小退') and (g_MySelf.m_nHiterCode > 0) then
  begin
    AppLogoutEx();
    Exit;
  end;
  if (Str = '大退') and (g_MySelf.m_nHiterCode > 0) then
  begin
    DScreen.ClearHint;
    Application.Terminate;
    Exit;
  end;
  for i := 0 to MAXBAGITEMCL - 1 do
  begin
    if (g_ItemArr[i].S.Name = Str) and (g_ItemArr[i].S.NeedIdentify < 4) then
    begin
      EatItem(i);
      Result := True;
      Exit;
    end;
  end;
end;

procedure TfrmMain.EatItem(idx: Integer);
var
  i, where: Integer;
  takeon, eatable: Boolean;
label
  lab1, lab2;
begin
  eatable := False;
  takeon := False;
  if idx in [0..MAXBAGITEMCL - 1] then
  begin
    if (g_EatingItem.S.Name <> '') and (GetTickCount - g_dwEatTime > 5 * 1000) then
      g_EatingItem.S.Name := '';

    if (g_EatingItem.S.Name = '') and (g_ItemArr[idx].S.Name <> '') and (g_ItemArr[idx].S.NeedIdentify < 4) then
    begin
      if (g_ItemArr[idx].S.StdMode <= 3) or (g_ItemArr[idx].S.StdMode = 31) then
      begin
        if (g_ItemArr[idx].S.Overlap >= 1) and (g_ItemArr[idx].Dura > 1) then
        begin
          g_ItemArr[idx].Dura := g_ItemArr[idx].Dura - 1;
          g_EatingItem := g_ItemArr[idx];
          g_ItemArr[idx].S.Name := '';
          eatable := True;
        end
        else
        begin
          g_EatingItem := g_ItemArr[idx];
          g_ItemArr[idx].S.Name := '';
          eatable := True;
        end;
      end
      else
      begin
        //if g_WaitingUseItem.Item.S.Name = '' then begin
        if (g_ItemArr[idx].S.Overlap >= 1) then
        begin
          if (g_ItemArr[idx].Dura > 1) then
          begin
            frmMain.SendDismantleItem(g_ItemArr[idx].S.Name, g_ItemArr[idx].MakeIndex, 1, 0);
            g_SndMgr.ItemUseSound(g_ItemArr[idx].S.StdMode);
            g_dwEatTime := GetTickCount;
            Exit;
          end
          else
            goto lab1;
        end
        else
        begin
          lab1:
          if (g_ItemArr[idx].S.StdMode = 46) and (g_ItemArr[idx].S.Shape in [2..6]) then
          begin
            if not g_RareBoxWindow.m_boKeyAvail and (g_OpenBoxItem.Item.S.Name = '') and not FrmDlg.DWBoxBKGnd.Visible then
            begin
              g_OpenBoxItem.Index := idx;
              g_OpenBoxItem.Item := g_ItemArr[idx];
              g_ItemArr[idx].S.Name := '';
              FrmDlg.DWBoxBKGnd.Visible := True;
            end;
            Exit;
          end;
          if (g_ItemArr[idx].S.StdMode = 41) and
            (g_ItemArr[idx].S.Shape in [10..14, 30..34]) and
            (g_BuildAcusesStep <> 1) and
            FrmDlg.DWBuildAcus.Visible and
            (FrmDlg.DWBuildAcus.tag in [1, 2]) then
          begin
            for i := 0 to 7 do
            begin
              if g_BuildAcuses[i].Item.S.Name = '' then
              begin
                if ((g_ItemArr[idx].S.Shape in [30..34]) and (i in [5..7])) or
                  ((g_ItemArr[idx].S.Shape in [10..14]) and (i in [0..4])) then
                begin
                  Break;
                end;
              end;
            end;
            if i in [0..7] then
            begin
              g_boItemMoving := True;
              g_MovingItem.Index := idx;
              g_MovingItem.Item := g_ItemArr[idx];
              g_ItemArr[idx].S.Name := '';
            end;
            case i of
              0: FrmDlg.DBAcus1Click(FrmDlg.DBAcus1, 0, 0);
              1: FrmDlg.DBAcus1Click(FrmDlg.DBAcus2, 0, 0);
              2: FrmDlg.DBAcus1Click(FrmDlg.DBAcus3, 0, 0);
              3: FrmDlg.DBAcus1Click(FrmDlg.DBAcus4, 0, 0);
              4: FrmDlg.DBAcus1Click(FrmDlg.DBAcus5, 0, 0);
              5: FrmDlg.DBAcus1Click(FrmDlg.DBCharm1, 0, 0);
              6: FrmDlg.DBAcus1Click(FrmDlg.DBCharm2, 0, 0);
              7: FrmDlg.DBAcus1Click(FrmDlg.DBCharm3, 0, 0);
            end;
            Exit;
          end;
        end;
        where := GetTakeOnPosition(g_ItemArr[idx].S, g_UseItems, True);
        if where in [0..U_FASHION] then
        begin //takeon...
          takeon := True;
          g_EatingItem := g_ItemArr[idx];
          g_ItemArr[idx].S.Name := '';
        end;
        //end;
      end;
    end;
  end
  else if (idx = -1) and g_boItemMoving then
  begin
    //if g_WaitingUseItem.Item.S.Name = '' then begin
    //end;

    if (g_MovingItem.Item.S.StdMode <= 4) or (g_MovingItem.Item.S.StdMode = 31) and (g_MovingItem.Item.S.NeedIdentify < 4) then
    begin
      if ((g_MovingItem.Item.S.StdMode <= 3) or (g_MovingItem.Item.S.StdMode = 31)) and (g_MovingItem.Item.S.Overlap >= 1) and (g_MovingItem.Item.Dura > 1) then
      begin
        g_MovingItem.Item.Dura := g_MovingItem.Item.Dura - 1;
        g_boItemMoving := False;
        g_EatingItem := g_MovingItem.Item;
        g_MovingItem.Item.S.Name := '';
      end
      else
      begin
        g_boItemMoving := False;
        g_EatingItem := g_MovingItem.Item;
        g_MovingItem.Item.S.Name := '';
      end;
      if (g_EatingItem.S.StdMode = 4) and (g_EatingItem.S.Shape < 50) then
      begin
        if mrYes <> FrmDlg.DMessageDlg('是否确认开始练习 "' + g_EatingItem.S.Name + '"？', [mbYes, mbNo]) then
        begin
          AddItemBag(g_EatingItem);
          Exit;
        end;
      end;
      idx := frmMain.m_nEatRetIdx;
      eatable := True;

    end
    else
    begin
      if (g_MovingItem.Item.S.Overlap >= 1) then
      begin
        if (g_MovingItem.Item.Dura > 1) then
        begin
          frmMain.SendDismantleItem(g_MovingItem.Item.S.Name, g_MovingItem.Item.MakeIndex, 1, 0);
          g_SndMgr.ItemUseSound(g_MovingItem.Item.S.StdMode);
          g_dwEatTime := GetTickCount;
          Exit;
        end
        else
          goto lab2;
      end
      else
      begin
        lab2:
        if (g_MovingItem.Item.S.StdMode = 46) and (g_MovingItem.Item.S.Shape in [2..6]) then
        begin
          if not g_RareBoxWindow.m_boKeyAvail and (g_OpenBoxItem.Item.S.Name = '') and not FrmDlg.DWBoxBKGnd.Visible then
          begin
            g_OpenBoxItem.Index := frmMain.m_nEatRetIdx;
            g_OpenBoxItem.Item := g_MovingItem.Item;
            g_boItemMoving := False;
            g_MovingItem.Item.S.Name := '';
            FrmDlg.DWBoxBKGnd.Visible := True;
          end;
          Exit;
        end;
        if (g_MovingItem.Item.S.StdMode = 41) and
          (g_MovingItem.Item.S.Shape in [10..14, 30..34]) and
          (g_BuildAcusesStep <> 1) and
          FrmDlg.DWBuildAcus.Visible and
          (FrmDlg.DWBuildAcus.tag in [1, 2]) then
        begin

          for i := 0 to 7 do
          begin
            if g_BuildAcuses[i].Item.S.Name = '' then
            begin
              if ((g_MovingItem.Item.S.Shape in [30..34]) and (i in [5..7])) or
                ((g_MovingItem.Item.S.Shape in [10..14]) and (i in [0..4])) then
              begin
                Break;
              end;
            end;
          end;
          case i of
            0: FrmDlg.DBAcus1Click(FrmDlg.DBAcus1, 0, 0);
            1: FrmDlg.DBAcus1Click(FrmDlg.DBAcus2, 0, 0);
            2: FrmDlg.DBAcus1Click(FrmDlg.DBAcus3, 0, 0);
            3: FrmDlg.DBAcus1Click(FrmDlg.DBAcus4, 0, 0);
            4: FrmDlg.DBAcus1Click(FrmDlg.DBAcus5, 0, 0);
            5: FrmDlg.DBAcus1Click(FrmDlg.DBCharm1, 0, 0);
            6: FrmDlg.DBAcus1Click(FrmDlg.DBCharm2, 0, 0);
            7: FrmDlg.DBAcus1Click(FrmDlg.DBCharm3, 0, 0);
          end;
          Exit;
        end;
      end;
      where := GetTakeOnPosition(g_MovingItem.Item.S, g_UseItems, True);
      if where in [0..U_FASHION] then
      begin
        takeon := True;
        g_boItemMoving := False;
        g_EatingItem := g_MovingItem.Item;
        g_MovingItem.Item.S.Name := '';
        idx := frmMain.m_nEatRetIdx;
      end
      else {if g_WaitingUseItem.Item.S.Name = '' then}
      begin
        //
      end;
    end;
  end;
  if eatable then
  begin
    m_nEatRetIdx := idx;
    m_boSupplyItem := True;
    g_dwEatTime := GetTickCount;
    SendEat(g_EatingItem.MakeIndex, g_EatingItem.S.Name, g_EatingItem.S.StdMode);
    g_SndMgr.ItemUseSound(g_EatingItem.S.StdMode);
  end
  else if takeon then
  begin
    m_nEatRetIdx := idx;
    g_dwEatTime := GetTickCount;
    g_WaitingUseItem.Item := g_EatingItem;
    g_WaitingUseItem.Index := where;
    SendTakeOnItem(where, g_EatingItem.MakeIndex, g_EatingItem.S.Name);
    g_SndMgr.ItemUseSound(g_EatingItem.S.StdMode);
    g_EatingItem.S.Name := '';
  end;
end;

procedure TfrmMain.HeroEatItem(idx: Integer);
var
  where: Integer;
  takeon, eatable: Boolean;
begin
  takeon := False;
  eatable := False;
  if idx in [0..MAXBAGITEMCL - 1 - 6] then
  begin
    if (g_EatingItem.S.Name <> '') and (GetTickCount - g_dwHeroEatTime > 5000) then
      g_EatingItem.S.Name := '';
    if (g_EatingItem.S.Name = '') and (g_HeroItemArr[idx].S.Name <> '') then
    begin
      if (g_HeroItemArr[idx].S.StdMode <= 3) or (g_HeroItemArr[idx].S.StdMode = 31) then
      begin
        if (g_HeroItemArr[idx].S.Overlap >= 1) and (g_HeroItemArr[idx].Dura > 1) then
        begin
          g_HeroItemArr[idx].Dura := g_HeroItemArr[idx].Dura - 1;
          g_EatingItem := g_HeroItemArr[idx];
          g_HeroItemArr[idx].S.Name := '';
          eatable := True;
        end
        else
        begin
          g_EatingItem := g_HeroItemArr[idx];
          g_HeroItemArr[idx].S.Name := '';
          eatable := True;
        end;
      end
      else
      begin
        where := GetTakeOnPosition(g_HeroItemArr[idx].S, g_HeroUseItems, True);
        if where in [0..U_FASHION] then
        begin
          takeon := True;
          g_EatingItem := g_HeroItemArr[idx];
          g_HeroItemArr[idx].S.Name := '';
        end
        else
        begin
          if (g_ItemArr[idx].S.Overlap >= 1) then
          begin
            if (g_ItemArr[idx].Dura > 1) then
            begin
              frmMain.SendDismantleItem(g_ItemArr[idx].S.Name, g_ItemArr[idx].MakeIndex, 1, 1);
              g_SndMgr.ItemUseSound(g_ItemArr[idx].S.StdMode);
              g_dwEatTime := GetTickCount;
              Exit;
            end;
          end;
        end;
      end;
    end;
  end
  else if (idx = -1) and g_boItemMoving then
  begin
    if (g_MovingItem.Item.S.StdMode <= 4) or (g_MovingItem.Item.S.StdMode in [31, 42]) then
    begin
      if ((g_MovingItem.Item.S.StdMode <= 3) or (g_MovingItem.Item.S.StdMode = 31)) and (g_MovingItem.Item.S.Overlap >= 1) and (g_MovingItem.Item.Dura > 1) then
      begin
        g_MovingItem.Item.Dura := g_MovingItem.Item.Dura - 1;
        g_boItemMoving := False;
        g_EatingItem := g_MovingItem.Item;
        g_MovingItem.Item.S.Name := '';
      end
      else
      begin
        g_boItemMoving := False;
        g_EatingItem := g_MovingItem.Item;
        g_MovingItem.Item.S.Name := '';
      end;
      if (g_EatingItem.S.StdMode = 4) and (g_EatingItem.S.Shape < 50) then
      begin
        if mrYes <> FrmDlg.DMessageDlg(Format('英雄[%s]是否确认开始练习 "' + g_EatingItem.S.Name + '"？', [g_MySelf.m_HeroObject.m_sUserName]), [mbYes, mbNo]) then
        begin
          HeroAddItemBag(g_EatingItem);
          Exit;
        end;
      end;
      eatable := True;
    end
    else {if (g_WaitingUseItem.Item.S.Name = '') then}
    begin
      where := GetTakeOnPosition(g_MovingItem.Item.S, g_HeroUseItems, True);
      if where in [0..U_FASHION] then
      begin
        takeon := True;
        g_boItemMoving := False;
        g_EatingItem := g_MovingItem.Item;
        g_MovingItem.Item.S.Name := '';
      end
      else
      begin
        if (g_MovingItem.Item.S.Overlap >= 1) then
        begin
          if (g_MovingItem.Item.Dura > 1) then
          begin
            frmMain.SendDismantleItem(g_MovingItem.Item.S.Name, g_MovingItem.Item.MakeIndex, 1, 1);
            g_SndMgr.ItemUseSound(g_MovingItem.Item.S.StdMode);
            g_dwEatTime := GetTickCount;
            Exit;
          end;
        end;
      end;
    end;
  end;
  if eatable then
  begin
    g_dwHeroEatTime := GetTickCount;
    if g_EatingItem.S.StdMode = 42 then
      SendHeroEat(g_EatingItem.MakeIndex, g_EatingItem.S.Name, 1, g_EatingItem.S.StdMode)
    else
      SendHeroEat(g_EatingItem.MakeIndex, g_EatingItem.S.Name, 0, g_EatingItem.S.StdMode);
    g_SndMgr.ItemUseSound(g_EatingItem.S.StdMode);
  end
  else if takeon then
  begin
    g_dwHeroEatTime := GetTickCount;
    g_WaitingUseItem.Item := g_EatingItem;
    g_WaitingUseItem.Index := where;
    HeroSendTakeOnItem(where, g_EatingItem.MakeIndex, g_EatingItem.S.Name);
    g_SndMgr.ItemUseSound(g_EatingItem.S.StdMode);
    g_EatingItem.S.Name := '';
  end;
end;

function TfrmMain.TargetInSwordLongAttackRange(ndir: Integer): Boolean;
var
  nX, nY: Integer;
  Actor: TActor;
begin
  if g_gcTec[0] then
  begin
    Result := True;
    Exit;
  end;
  Result := False;
  GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, ndir, nX, nY);
  GetFrontPosition(nX, nY, ndir, nX, nY);
  if (abs(g_MySelf.m_nCurrX - nX) = 2) or (abs(g_MySelf.m_nCurrY - nY) = 2) then
  begin
    Actor := g_PlayScene.FindActorXY(nX, nY);
    if Actor <> nil then
      if not Actor.m_boDeath then
        Result := True;
  end;
end;

function TfrmMain.TargetInSwordLongAttackRange2(sx, sy, dx, dy: Integer): Boolean;
begin
  Result := False;
  if (abs(sx - dx) = 2) and (abs(sy - dy) = 0) then
  begin
    Result := True;
    Exit;
  end;
  if (abs(sx - dx) = 0) and (abs(sy - dy) = 2) then
  begin
    Result := True;
    Exit;
  end;
  if (abs(sx - dx) = 2) and (abs(sy - dy) = 2) then
  begin
    Result := True;
    Exit;
  end;
end;

function TfrmMain.TargetInSwordWideAttackRange(ndir: Integer): Boolean;
var
  nX, nY, rx, ry, mdir: Integer;
  Actor, ractor: TActor;
begin
  Result := False;
  GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, ndir, nX, nY);
  Actor := g_PlayScene.FindActorXY(nX, nY);

  mdir := (ndir + 1) mod 8;
  GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, mdir, rx, ry);
  ractor := g_PlayScene.FindActorXY(rx, ry);
  if ractor = nil then
  begin
    mdir := (ndir + 2) mod 8;
    GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, mdir, rx, ry);
    ractor := g_PlayScene.FindActorXY(rx, ry);
  end;
  if ractor = nil then
  begin
    mdir := (ndir + 7) mod 8;
    GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, mdir, rx, ry);
    ractor := g_PlayScene.FindActorXY(rx, ry);
  end;

  if (Actor <> nil) and (ractor <> nil) then
    if not Actor.m_boDeath and not ractor.m_boDeath then
      Result := True;
end;

function GetNextPosition(sx, sy, ndir, nFlag: Integer; var snx: Integer; var sny: Integer): Boolean;
begin
  snx := sx;
  sny := sy;
  case ndir of
    DR_UP: if sny > nFlag - 1 then
        Dec(sny, nFlag);
    DR_DOWN: if sny < (Map.m_MapHeader.wHeight - nFlag) then
        Inc(sny, nFlag);
    DR_LEFT: if snx > nFlag - 1 then
        Dec(snx, nFlag);
    DR_RIGHT: if snx < (Map.m_MapHeader.wWidth - nFlag) then
        Inc(snx, nFlag);
    DR_UPLEFT:
      begin
        if (snx > nFlag - 1) and (sny > nFlag - 1) then
        begin
          Dec(snx, nFlag);
          Dec(sny, nFlag);
        end;
      end;
    DR_UPRIGHT:
      begin
        if (snx > nFlag - 1) and (sny < (Map.m_MapHeader.wHeight - nFlag)) then
        begin
          Inc(snx, nFlag);
          Dec(sny, nFlag);
        end;
      end;
    DR_DOWNLEFT:
      begin
        if (snx < (Map.m_MapHeader.wWidth - nFlag)) and (sny > nFlag - 1) then
        begin
          Dec(snx, nFlag);
          Inc(sny, nFlag);
        end;
      end;
    DR_DOWNRIGHT:
      begin
        if (snx < (Map.m_MapHeader.wWidth - nFlag)) and (sny < (Map.m_MapHeader.wHeight - nFlag)) then
        begin
          Inc(snx, nFlag);
          Inc(sny, nFlag);
        end;
      end;
  end;
  if (snx = sx) and (sny = sy) then
    Result := False
  else
    Result := True;
end;

function CheckMagPassThrough(sx, sy, tx, ty, ndir: Integer): Integer;
var
  i, tCount: Integer;
  Actor: TActor;
begin
  tCount := 0;
  for i := 0 to 12 do
  begin
    Actor := g_PlayScene.FindActorXY(sx, sy);
    if Actor <> nil then
    begin
      if IsProperTarget(Actor) then
      begin
        Inc(tCount);
      end;
    end;
    if not ((abs(sx - tx) <= 0) and (abs(sy - ty) <= 0)) then
    begin
      ndir := GetNextDirection(sx, sy, tx, ty);
      if not GetNextPosition(sx, sy, ndir, 1, sx, sy) then
        Break;
    end
    else
      Break;
  end;
  Result := tCount;
end;

function TfrmMain.TargetInSwordLongAttackRangeX(ndir: Integer): Boolean;
var
  nC, nX, nY: Integer;
  Actor: TActor;
begin
  Result := False;
  nC := 1;
  while True do
  begin
    if GetNextPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, ndir, nC, nX, nY) then
    begin
      Actor := g_PlayScene.FindActorXY(nX, nY);
      if (Actor <> nil) and not Actor.m_boDeath then
      begin
        Result := True;
        Break;
      end;
    end;
    Inc(nC);
    if nC >= 5 then
      Break;
  end;
end;

function TfrmMain.TargetInSwordLongAttackRangeA(ndir: Integer): Boolean;
var
  nC, nX, nY: Integer;
  Actor: TActor;
begin
  Result := False;
  nC := 1;
  while True do
  begin
    if GetNextPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, ndir, nC, nX, nY) then
    begin
      Actor := g_PlayScene.FindActorXY(nX, nY);
      if (Actor <> nil) and not Actor.m_boDeath then
      begin
        Result := True;
        Break;
      end;
    end;
    Inc(nC);
    if nC >= 4 then
      Break;
  end;
end;

function TfrmMain.TargetInSwordCrsAttackRange(ndir: Integer): Boolean;
var
  nX, nY, rx, ry, mdir: Integer;
  Actor, ractor: TActor;
begin
  Result := False;
  GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, ndir, nX, nY);
  Actor := g_PlayScene.FindActorXY(nX, nY);

  mdir := (ndir + 1) mod 8;
  GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, mdir, rx, ry);
  ractor := g_PlayScene.FindActorXY(rx, ry);
  if ractor = nil then
  begin
    mdir := (ndir + 2) mod 8;
    GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, mdir, rx, ry);
    ractor := g_PlayScene.FindActorXY(rx, ry);
  end;
  if ractor = nil then
  begin
    mdir := (ndir + 7) mod 8;
    GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, mdir, rx, ry);
    ractor := g_PlayScene.FindActorXY(rx, ry);
  end;

  if (Actor <> nil) and (ractor <> nil) then
    if not Actor.m_boDeath and not ractor.m_boDeath then
      Result := True;
end;

procedure TfrmMain.DXDrawMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  mx, my, sel: Integer;
  target: TActor;
  itemnames: string;
  P: TPoint;
  RC: TRect;
begin
  //DScreen.ShowHint(X, Y, IntToStr(X) + '/' + IntToStr(Y), clWhite, True); //blue Hint

  g_nMouseX := X;
  g_nMouseY := Y;
  if g_DWinMan.MouseMove(Shift, X, Y) then
    Exit;

  if (g_MySelf = nil) or (DScreen.CurrentScene <> g_PlayScene) then
    Exit;

  g_boSelectMyself := g_PlayScene.IsSelectMyself(X, Y);

  target := g_PlayScene.GetAttackFocusCharacter(X, Y, g_nDupSelection, sel, False);
  if g_nDupSelection <> sel then
    g_nDupSelection := 0;
  if target <> nil then
  begin
    if (target.m_sUserName = '') and (GetTickCount - target.m_dwSendQueryUserNameTime > 10 * 1000) then
    begin
      target.m_dwSendQueryUserNameTime := GetTickCount;
      SendQueryUserName(target.m_nRecogId, target.m_nCurrX, target.m_nCurrY);
    end;
    g_FocusCret := target;
  end
  else
    g_FocusCret := nil;

  g_FocusItem := g_PlayScene.GetDropItems(X, Y, itemnames);
  if g_FocusItem <> nil then
  begin
    g_PlayScene.ScreenXYfromMCXY(g_FocusItem.X, g_FocusItem.Y, mx, my);
    DScreen.ShowHint(mx, my - 2, itemnames, clWhite, True);
  end
  else
    DScreen.ClearHint;

  g_PlayScene.CXYfromMouseXY(X, Y, g_nMouseCurrX, g_nMouseCurrY);
  g_nMouseX := X;
  g_nMouseY := Y;
  g_MouseItem.S.Name := '';
  g_HeroMouseItem.S.Name := '';
  g_MouseStateItem.S.Name := '';
  g_HeroMouseStateItem.S.Name := '';
  g_MouseUserStateItem.S.Name := '';

  if g_boViewMiniMap and g_DrawingMiniMap then
  begin
    P.X := X;
    P.Y := Y;
    if g_nViewMinMapLv = 1 then
    begin
      RC.Left := SCREENWIDTH - 120;
      RC.Top := 0;
      RC.Right := SCREENWIDTH;
      RC.Bottom := g_MiniMapRC.Bottom - g_MiniMapRC.Top;
    end
    else
    begin
      RC := g_MiniMapRC;
    end;
    g_ShowMiniMapXY := False;
    if PtInRect(RC, P) then
    begin
      g_ShowMiniMapXY := True;
      //Exit;
    end;
  end;

  if ((ssLeft in Shift) or (ssRight in Shift)) and (GetTickCount - m_dwMouseDownTime >= 300) then
  begin
    m_boMouseUpEnAble := True;
    _DXDrawMouseDown(Self, mbLeft, Shift, X, Y, False);
  end;
end;

procedure TfrmMain.DXDrawMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  g_nRunReadyCount := 0;
  if not IntroScene.m_boOnClick then
  begin
    IntroScene.m_boOnClick := True;
    IntroScene.m_dwStartTime := GetTickCount + 100;
    Exit;
  end;
  if GetTickCount - m_dwMouseDownTime > 120 then
  begin
    m_dwMouseDownTime := GetTickCount;
    m_boMouseUpEnAble := True;
    _DXDrawMouseDown(Sender, Button, Shift, X, Y, True);
  end;
end;

procedure TfrmMain.DXDrawMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if m_boMouseUpEnAble then
  begin
    m_boMouseUpEnAble := False;
    if g_DWinMan.MouseUp(Button, Shift, X, Y) then
      Exit;
    g_nTargetX := -1;
  end;
end;

procedure TfrmMain.DXDrawDblClick(Sender: TObject);
var
  pt: TPoint;
begin
  GetCursorPos(pt);
  Windows.ScreenToClient(frmMain.Handle, pt);
  if g_DWinMan.DblClick(pt.X, pt.Y) then
    Exit;
end;

function GetAdvPosition(TargetCret: TActor; var nX, nY: Integer): Boolean;
var
  btDir: BYTE;
begin
  Result := False;
  //boTagWarr := (m_btJob <> 0) and (m_TargetCret.m_btRaceServer in [RC_PLAYOBJECT, RC_HERO]) and (m_TargetCret.m_btJob = 0);
  //if not boTagWarr then begin
  //  GetBackPositionEx(nX, nY);
  //  Exit;
  //end;
  nX := g_MySelf.m_nCurrX;
  nY := g_MySelf.m_nCurrY;
  btDir := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, TargetCret.m_nCurrX, TargetCret.m_nCurrY);
  Randomize;
  with g_MySelf do
    case btDir of
      DR_UP:
        begin
          if Random(2) = 0 then
          begin
            Inc(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Dec(nY);
            Inc(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Dec(nX);
          end
          else
          begin
            Inc(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Dec(nY);
            Dec(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Inc(nX);
          end;
          if not g_PlayScene.CanWalk(nX, nY) then
          begin
            nY := m_nCurrY + 2;
          end;
        end;
      DR_DOWN:
        begin
          if Random(2) = 0 then
          begin
            Dec(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Inc(nY);
            Inc(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Dec(nX);
          end
          else
          begin
            Dec(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Inc(nY);
            Dec(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Inc(nX);
          end;
          if not g_PlayScene.CanWalk(nX, nY) then
          begin
            nY := m_nCurrY - 2;
          end;
        end;
      DR_LEFT:
        begin
          if Random(2) = 0 then
          begin
            Inc(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Dec(nX);
            Inc(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Dec(nY);
          end
          else
          begin
            Inc(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Dec(nX);
            Dec(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Inc(nY);
          end;
          if not g_PlayScene.CanWalk(nX, nY) then
          begin
            nX := m_nCurrX + 2;
          end;
        end;
      DR_RIGHT:
        begin
          if Random(2) = 0 then
          begin
            Dec(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Inc(nX);
            Inc(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Dec(nY);
          end
          else
          begin
            Dec(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Inc(nX);
            Dec(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Inc(nY);
          end;
          if not g_PlayScene.CanWalk(nX, nY) then
          begin
            nX := m_nCurrX - 2;
          end;
        end;
      DR_UPLEFT:
        begin
          if Random(2) = 0 then
          begin
            Inc(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Dec(nX);
          end
          else
          begin
            Inc(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then
            Dec(nY);
          end;
          if not g_PlayScene.CanWalk(nX, nY) then
          begin
            nX := m_nCurrX + 2;
            nY := m_nCurrY + 2;
          end;
        end;
      DR_UPRIGHT:
        begin
          if Random(2) = 0 then
          begin
            Inc(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then
            Dec(nY);
          end
          else
          begin
            Dec(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then
            Inc(nX);
          end;
          if not g_PlayScene.CanWalk(nX, nY) then
          begin
            nX := m_nCurrX - 2;
            nY := m_nCurrY + 2;
          end;
        end;
      DR_DOWNLEFT:
        begin
          if Random(2) = 0 then
          begin
            Inc(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Dec(nX);
          end
          else
          begin
            Dec(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Inc(nY);
          end;
          if not g_PlayScene.CanWalk(nX, nY) then
          begin
            nX := m_nCurrX + 2;
            nY := m_nCurrY - 2;
          end;
        end;
      DR_DOWNRIGHT:
        begin
          if Random(2) = 0 then
          begin
            Dec(nX, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Inc(nX);
          end
          else
          begin
            Dec(nY, 2);
            //if not g_PlayScene.CanWalk(nX, nY) then Inc(nY);
          end;
          if not g_PlayScene.CanWalk(nX, nY) then
          begin
            nX := m_nCurrX - 2;
            nY := m_nCurrY - 2;
          end;
        end;
    end;
end;

function TfrmMain.AttackTarget(target: TActor): Boolean;
var
  tdir, dx, dy, nHitMsg: Integer;
label
  lab;
begin
  Result := False;
  nHitMsg := CM_HIT;
  if g_UseItems[U_WEAPON].S.StdMode = 6 then
    nHitMsg := CM_HEAVYHIT;
  tdir := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, target.m_nCurrX, target.m_nCurrY);
  if (abs(g_MySelf.m_nCurrX - target.m_nCurrX) <= 1) and (abs(g_MySelf.m_nCurrY - target.m_nCurrY) <= 1) and (not target.m_boDeath) then
  begin
    if TimerAutoPlay.Enabled then
    begin
      g_boAPAutoMove := False;
      if g_APTagget <> nil then
        g_sAPStr := Format('[挂机] 怪物目标：%s (%d,%d) 正在使用普通攻击', [g_APTagget.m_sUserName, g_APTagget.m_nCurrX, g_APTagget.m_nCurrY]);
    end;

    if CanNextAction and ServerAcceptNextAction {and (CanNextHit or (g_NextSeriesSkill))} then
    begin

      if CanNextHit(False) or g_NextSeriesSkill then
      begin
        g_NextSeriesSkill := False;
        if g_boNextTimeSmiteHit and (g_MySelf.m_Abil.MP >= 7) then
        begin
          g_boNextTimeSmiteHit := False;
          nHitMsg := CM_SMITEHIT;
          g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
          goto lab;
        end
        else if g_boNextTimeSmiteLongHit and (g_MySelf.m_Abil.MP >= 7) then
        begin
          g_boNextTimeSmiteLongHit := False;
          nHitMsg := CM_SMITELONGHIT;
          g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
          goto lab;
        end
        else if g_boNextTimeSmiteWideHit and (g_MySelf.m_Abil.MP >= 7) then
        begin
          g_boNextTimeSmiteWideHit := False;
          nHitMsg := CM_SMITEWIDEHIT;
          g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
          goto lab;
        end
        else if g_boNextTimeSmiteLongHit2 and (g_MySelf.m_Abil.MP >= 7) then
        begin
          g_boNextTimeSmiteLongHit2 := False;
          nHitMsg := CM_SMITELONGHIT2;
          g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
          goto lab;
        end;
      end;

      if CanNextHit then
      begin
        if g_boNextTimeSmiteWideHit2 and (g_MySelf.m_Abil.MP >= 1) then
        begin
          g_boNextTimeSmiteWideHit2 := False;
          nHitMsg := CM_SMITEWIDEHIT2;
        end
        else if g_boNextTimeSmiteLongHit3 and (g_MySelf.m_Abil.MP >= 1) then
        begin
          g_boNextTimeSmiteLongHit3 := False;
          nHitMsg := CM_SMITELONGHIT3;
        end
        else if g_boNextTimeTwinHit and (g_MySelf.m_Abil.MP >= 10) then
        begin
          g_boNextTimeTwinHit := False;
          nHitMsg := CM_TWNHIT;
        end
        else if g_boNextTimePursueHit and (g_MySelf.m_Abil.MP >= 7) then
        begin
          g_boNextTimePursueHit := False;
          nHitMsg := CM_PURSUEHIT;
        end
        else if g_boNextTimeFireHit and (g_MySelf.m_Abil.MP >= 7) then
        begin
          g_boNextTimeFireHit := False;
          nHitMsg := CM_FIREHIT;
        end
        else if g_boCanSLonHit and (g_MySelf.m_Abil.MP >= 7) then
        begin
          g_boCanSLonHit := False;
          nHitMsg := CM_HERO_LONGHIT2;
        end
        else if g_boNextTimePowerHit then
        begin
          g_boNextTimePowerHit := False;
          nHitMsg := CM_POWERHIT;
        end
        else if g_boCanSquHit and (g_MySelf.m_Abil.MP >= 3) and (g_nSquHitPoint > 0) then
        begin
          nHitMsg := CM_SQUHIT;
        end
        else if (g_MySelf.m_Abil.MP >= 3) and (g_boCanWideHit or (g_gcTec[1] and (GetMagicByID(25) <> nil) and TargetInSwordWideAttackRange(tdir))) then
        begin
          nHitMsg := CM_WIDEHIT;
        end
        else if g_boCanCrsHit and (g_MySelf.m_Abil.MP >= 6) then
        begin
          nHitMsg := CM_CRSHIT;
        end
        else if g_boCanLongHit and (TargetInSwordLongAttackRange(tdir)) then
        begin
          nHitMsg := CM_LONGHIT;
        end;
        g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
      end;
      lab:
    end;
    Result := True;
    g_dwLastAttackTick := GetTickCount;
  end
  else
  begin
    if g_boNextTimeSmiteWideHit2 and (g_MySelf.m_Abil.MP >= 1) then
    begin
      if CanNextAction and ServerAcceptNextAction and CanNextHit then
      begin
        if (abs(g_MySelf.m_nCurrX - target.m_nCurrX) <= 5) and
          (abs(g_MySelf.m_nCurrY - target.m_nCurrY) <= 5) then
        begin
          g_boNextTimeSmiteWideHit2 := False;
          nHitMsg := CM_SMITEWIDEHIT2;
          g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
          g_dwLatestSmiteWideHitTick2 := GetTickCount;
          Exit;
        end;
      end;
    end;

    if g_boNextTimeSmiteLongHit3 and (g_MySelf.m_Abil.MP >= 1) and TargetInSwordLongAttackRangeA(tdir) then
    begin
      if CanNextAction and ServerAcceptNextAction and CanNextHit then
      begin
        g_boNextTimeSmiteLongHit3 := False;
        nHitMsg := CM_SMITELONGHIT3;
        g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
        g_dwLastAttackTick := GetTickCount;
        g_dwLatestSmiteLongHitTick3 := GetTickCount;
        Exit;
      end;
    end;

    if g_boNextTimeSmiteLongHit and (g_MySelf.m_Abil.MP >= 7) and TargetInSwordLongAttackRangeA(tdir) then
    begin
      if CanNextAction and ServerAcceptNextAction and CanNextHit then
      begin
        g_boNextTimeSmiteLongHit := False;
        nHitMsg := CM_SMITELONGHIT;
        g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
        g_dwLastAttackTick := GetTickCount;
        Exit;
      end;
    end;

    if g_boNextTimeSmiteLongHit2 and (g_MySelf.m_Abil.MP >= 7) and TargetInSwordLongAttackRangeX(tdir) then
    begin
      if CanNextAction and ServerAcceptNextAction and CanNextHit then
      begin
        g_boNextTimeSmiteLongHit2 := False;
        nHitMsg := CM_SMITELONGHIT2;
        g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
        g_dwLastAttackTick := GetTickCount;
        Exit;
      end;
    end;

    if g_boNextTimePursueHit and (g_MySelf.m_Abil.MP >= 7) and TargetInSwordLongAttackRangeX(tdir) then
    begin
      if CanNextAction and ServerAcceptNextAction and CanNextHit then
      begin
        g_boNextTimePursueHit := False;
        nHitMsg := CM_PURSUEHIT;
        g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
        g_dwLastAttackTick := GetTickCount;
        Exit;
      end;
    end;

    if g_boCanSLonHit and (g_MySelf.m_Abil.MP >= 7) and TargetInSwordLongAttackRangeX(tdir) then
    begin
      if CanNextAction and ServerAcceptNextAction and CanNextHit then
      begin
        g_boCanSLonHit := False;
        nHitMsg := CM_HERO_LONGHIT2;
        g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
        g_dwLastAttackTick := GetTickCount;
        Exit;
      end;
    end;

    if g_boCanLongHit and (g_MySelf.m_btJob = 0) and (not target.m_boDeath) and g_boAutoLongAttack and g_gcTec[10] and (g_MagicArr[0][12] <> nil) and
      TargetInSwordLongAttackRange2(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, target.m_nCurrX, target.m_nCurrY) then
    begin
      if CanNextAction and ServerAcceptNextAction and CanNextHit then
      begin
        nHitMsg := CM_LONGHIT;
        g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
        g_dwLastAttackTick := GetTickCount;
      end
      else if g_boAutoLongAttack and g_gcTec[10] and TimerAutoPlay.Enabled then
      begin //走刺杀位
        Result := True;
        Exit;
      end;
    end
    else
    begin
      dx := g_MySelf.m_nCurrX;
      dy := g_MySelf.m_nCurrY;
      if (g_MySelf.m_btJob = 0) and g_boAutoLongAttack and g_gcTec[10] and (g_MagicArr[0][12] <> nil) then
      begin
        GetNextHitPosition(target.m_nCurrX, target.m_nCurrY, dx, dy);
        if not g_PlayScene.CanWalk(dx, dy) then
          GetBackPosition(target.m_nCurrX, target.m_nCurrY, tdir, dx, dy);
      end
      else
        GetBackPosition(target.m_nCurrX, target.m_nCurrY, tdir, dx, dy);
      g_nTargetX := dx;
      g_nTargetY := dy;
      g_ChrAction := caRun;
      //end;
    end;

    if TimerAutoPlay.Enabled then
    begin
      g_boAPAutoMove := True;
      if target <> nil then
        g_sAPStr := Format('[挂机] 怪物目标：%s (%d,%d) 正在跑向', [target.m_sUserName, target.m_nCurrX, target.m_nCurrY]);
    end;
  end;
end;

procedure TfrmMain._DXDrawMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; boClick: Boolean);
var
  tdir, nX, nY: Integer;
  nHitMsg, sel: Integer;
  target: TActor;
  itemnames: string;
  P: TPoint;
  RC: TRect;
  rx, ry: Real;
  Actor: TActor;
  i: Integer;

  szMapTitle: string;
  pMapDescInfo: pTMapDescInfo;
label
  lexit, lexit2;
begin
  ActionKey := 0;
  g_nMouseX := X;
  g_nMouseY := Y;
  if boClick then
  begin
    if (Button = mbRight) and (g_OpenBoxItem.Item.S.Name <> '') and not g_RareBoxWindow.m_boRareBoxShow and (FrmDlg.DWBoxBKGnd.Visible) then
    begin
      AddItemBag(g_OpenBoxItem.Item, g_OpenBoxItem.Index);
      DScreen.AddSysMsg(g_OpenBoxItem.Item.S.Name + '被发现');
      g_OpenBoxItem.Item.S.Name := '';
      FrmDlg.DWBoxBKGnd.Visible := False;
    end;
    if (Button = mbRight) and g_boItemMoving then
    begin //当前是否在移动物品
      FrmDlg.CancelItemMoving;
      Exit;
    end;
    if g_DWinMan.MouseDown(Button, Shift, X, Y) then //鼠标移到窗口上了则跳过
      Exit;
  end;
  if (g_MySelf = nil) or (DScreen.CurrentScene <> g_PlayScene) then
    Exit;

  if (ssMiddle in Shift) then
  begin
    if boClick then
    begin
      if g_boViewMiniMap and g_DrawingMiniMap then
      begin
        P.X := X;
        P.Y := Y;
        if g_nViewMinMapLv = 1 then
        begin
          RC.Left := SCREENWIDTH - 120;
          RC.Top := 0;
          RC.Right := SCREENWIDTH;
          RC.Bottom := g_MiniMapRC.Bottom - g_MiniMapRC.Top;
        end
        else
          RC := g_MiniMapRC;
        if PtInRect(RC, P) then
        begin
          if g_nViewMinMapLv = 1 then
          begin
            rx := g_MySelf.m_nCurrX + (g_nMouseX - (SCREENWIDTH - (g_MiniMapRC.Right - g_MiniMapRC.Left)) - ((g_MiniMapRC.Right - g_MiniMapRC.Left) div 2)) * 2 / 3;
            ry := g_MySelf.m_nCurrY + (g_nMouseY - (g_MiniMapRC.Bottom - g_MiniMapRC.Top) div 2);
          end
          else
          begin
            rx := (g_nMouseX - g_MiniMapRC.Left) * (Map.m_MapHeader.wWidth / MINIMAPSIZE);
            ry := g_nMouseY * (Map.m_MapHeader.wHeight / MINIMAPSIZE);
          end;
          if (rx > 0) and (ry > 0) then
          begin
            frmMain.AutoMove(Round(rx), Round(ry));
            {g_MySelf.m_nTagX := Round(rx);
            g_MySelf.m_nTagY := Round(ry);
            //if g_PlayScene.CanWalk(g_MySelf.m_nTagX, g_MySelf.m_nTagY) then begin
            if not g_PathBusy then
            begin
              g_PathBusy := True;
              try
                Map.LoadMapData();
                g_MapPath := Map.FindPath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_MySelf.m_nTagX, g_MySelf.m_nTagY, 0);
                //g_MapPath := Map.FindPath(g_MySelf.m_nTagX, g_MySelf.m_nTagY, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, 0);
                if g_MapPath <> nil then
                begin
                  g_MoveStep := 1;
                  TimerAutoMove.Enabled := True;
                  DScreen.AddChatBoardString(Format('自动移动至坐标(%d:%d)，点击鼠标任意键停止……', [g_MySelf.m_nTagX, g_MySelf.m_nTagY]), GetRGB(5), clWhite);
                end
                else
                begin
                  TimerAutoMove.Enabled := False;
                  DScreen.AddChatBoardString(Format('自动移动坐标点(%d:%d)不可到达', [g_MySelf.m_nTagX, g_MySelf.m_nTagY]), GetRGB(5), clWhite);
                  g_MySelf.m_nTagX := 0;
                  g_MySelf.m_nTagY := 0;
                end;
              finally
                g_PathBusy := False;
              end;
            end;}
          end;
          Exit;
        end;
      end;
    end;
  end;

  if (ssRight in Shift) then
  begin
    if boClick then
    begin
      g_PlayScene.ProcMagic.nTargetX := -1;
      g_boAutoDig := False;
      g_boAutoSit := False;
      if g_boViewMiniMap and g_DrawingMiniMap then
      begin //swich Mini Map Blend
        P.X := X;
        P.Y := Y;
        if g_nViewMinMapLv = 1 then
        begin
          RC.Left := SCREENWIDTH - 120;
          RC.Top := 0;
          RC.Right := SCREENWIDTH;
          RC.Bottom := g_MiniMapRC.Bottom - g_MiniMapRC.Top;
        end
        else
        begin
          RC := g_MiniMapRC;
        end;
        if PtInRect(RC, P) then
        begin
          g_DrawMiniBlend := not g_DrawMiniBlend;
          Exit;
        end;
      end;
      if TimerAutoMove.Enabled then
      begin
        if (ssRight in Shift) or (ssLeft in Shift) then
        begin
          g_MySelf.m_nTagX := 0;
          g_MySelf.m_nTagY := 0;
          TimerAutoMove.Enabled := False;
          SetLength(g_MapPath, 0);
          g_MapPath := nil;
          DScreen.AddChatBoardString('停止自动移动', GetRGB(5), clWhite);
        end;
      end;
      if Shift = [ssRight] then
        Inc(g_nDupSelection);
      target := g_PlayScene.GetAttackFocusCharacter(X, Y, g_nDupSelection, sel, False);
      if g_nDupSelection <> sel then
        g_nDupSelection := 0;

      if target <> nil then
      begin //query  user name
        if ssCtrl in Shift then
        begin
          if GetTickCount - g_dwLastMoveTick > 500 then
          begin
            if (target.m_btRace = 0) then
            begin
              SendClientMessage(CM_QUERYUSERSTATE, target.m_nRecogId, target.m_nCurrX, target.m_nCurrY, 0);
              Exit;
            end;
          end;
        end;
        if ssAlt in Shift then
        begin //get user name to chat
          if GetTickCount - g_dwLastMoveTick > 500 then
          begin
            if (target.m_btRace = 0) then
            begin
              FrmDlg.DEdChat.Visible := True;
              FrmDlg.DEdChat.SetFocus;
              FrmDlg.DEdChat.Text := '/' + target.m_sUserName + ' ';
              FrmDlg.DEdChat.ChangeCurPos(Length(FrmDlg.DEdChat.Text), True);
              FrmDlg.DEdChat.SelLength := 0;
              Exit;
            end;
          end;
        end;
      end
      else
        g_nDupSelection := 0;

      g_FocusItem2 := g_PlayScene.GetDropItems(X, Y, itemnames);
      if g_FocusItem2 <> nil then
      begin
        if itemnames[Length(itemnames)] = '\' then
          itemnames := Copy(itemnames, 1, Length(itemnames) - 1);

        if ssAlt in Shift then
        begin //get user name to chat
          if GetTickCount - g_dwLastMoveTick > 500 then
          begin
            DScreen.AddChatBoardString(itemnames, clBlue, clWhite);
            Exit;
          end;
        end;
      end;
    end;
{$I '..\Common\Macros\VMPBM.inc'}
    g_PlayScene.CXYfromMouseXY(X, Y, g_nMouseCurrX, g_nMouseCurrY); //按鼠标右键，并且鼠标指向空位置

    // 去掉检测  2019-10-16 14:27:42
    (*
    if GetTickCount - g_dwThreadExit > 5000 then
    begin
      g_dwThreadExit := GetTickCount;
      dwExit := 0;
      try
        Windows.GetExitCodeThread(g_ModuleDetect.Handle, dwExit);
      except
      end;
      if dwExit <> STILL_ACTIVE then
      begin
        goto lexit;
      end;

      if (ZwQuerySystemInformation(5, nil, 0, @size) = STATUS_INFO_LENGTH_MISMATCH) and (size > 0) then
      begin
        L := 0;
        spi := AllocMem(size);
        try
          if ZwQuerySystemInformation(5, spi, size, @size) = 0 then
          begin
            crt := spi;
            Offset_ProcessTables := 0;
            repeat
              crt := Pointer(DWORD(spi) + Offset_ProcessTables);
              if crt^.Process_NT5.Process.UniqueProcessId = GetCurrentProcessId then
              begin
                for j := 0 to crt^.Process_NT5.Process.ThreadCount - 1 do
                begin
                  if (crt^.Process_NT5.Threads[j].Cid.UniqueThread = g_ModuleDetect.ThreadID) then
                  begin
                    if (crt^.Process_NT5.Threads[j].ThreadState = 5) and
                      (crt^.Process_NT5.Threads[j].WaitReason = 5) then
                    begin //winlogon.exe
                      //ShellAPI.ShellExecute(0, 'open', VMProtectDecryptStringA('ntsd.exe'), VMProtectDecryptStringA(' -c q -pn notepad.exe'), nil, sw_hide);
                      L := 1;
                      //end else if (crt^.Process_NT5.Threads[j].ThreadState = 4)
                      //{or (crt^.Process_NT5.Threads[j].WaitReason = 5)}then begin //StateTerminated or Suspended
                      //L := 2;
                    end;
                    Break;
                  end;
                end;
                Break;
              end;
              Offset_ProcessTables := Offset_ProcessTables + crt^.Process_NT5.Process.uNext;
            until (crt^.Process_NT5.Process.uNext = 0);
          end;
        finally
          FreeMem(spi);
        end;
        if L <> 0 then
        begin
          lexit:
          ExitProcess(0);
          frmMain.Close;
          FrmDlg.Free;
          frmMain.Free;
          g_MySelf.Free;

          UnLoadWMImagesLib();

          DScreen.Finalize;
          g_PlayScene.Finalize;
          LoginNoticeScene.Finalize;

          DScreen.Free;
          IntroScene.Free;
          LoginScene.Free;
          SelectChrScene.Free;
          g_PlayScene.Free;
          g_ShakeScreen.Free;
          LoginNoticeScene.Free;
          g_SaveItemList.Free;
          g_MenuItemList.Free;
          Exit;
        end;
      end;
    end;
    *)
    // if not g_boCanRunOrWork then Exit; // 右键飞的时候不应该再跑      2019-12-24
    if FrmDlg.WinFindPathBack.Visible then
    begin
      if (X >= FrmDlg.WinFindPathBack.Left) and (X <= FrmDlg.WinFindPathBack.Left + FrmDlg.WinFindPathBack.Width) and
         (Y >= FrmDlg.WinFindPathBack.Top) and (Y <= FrmDlg.WinFindPathBack.Top + FrmDlg.WinFindPathBack.Height) then
      begin
        Exit;
      end;
    end;

    if (abs(g_MySelf.m_nCurrX - g_nMouseCurrX) <= 1) and (abs(g_MySelf.m_nCurrY - g_nMouseCurrY) <= 1) then
    begin //目标座标
      if boClick then
      begin
        tdir := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nMouseCurrX, g_nMouseCurrY);
        if CanNextAction and ServerAcceptNextAction then
          g_MySelf.SendMsg(CM_TURN, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
      end;
    end
    else
    begin
      g_ChrAction := caRun;
      g_nTargetX := g_nMouseCurrX;
      g_nTargetY := g_nMouseCurrY;
      Exit;
    end;
{$I '..\Common\Macros\VMPE.inc'}
  end;

  if ssLeft in Shift then
  begin
    g_PlayScene.ProcMagic.nTargetX := -1;
    g_boAutoDig := False;
    g_boAutoSit := False;
    if g_boViewMiniMap and g_DrawingMiniMap then
    begin
      if boClick then
      begin
        P.X := X;
        P.Y := Y;
        if g_nViewMinMapLv = 1 then
        begin
          RC.Left := SCREENWIDTH - 120;
          RC.Top := 0;
          RC.Right := SCREENWIDTH;
          RC.Bottom := g_MiniMapRC.Bottom - g_MiniMapRC.Top;
        end
        else
        begin
          RC := g_MiniMapRC;
        end;
        if PtInRect(RC, P) then
        begin
          if g_nViewMinMapLv >= 1 then
            Dec(g_nViewMinMapLv)
          else
            Inc(g_nViewMinMapLv);
          //123456
          g_xCurMapDescList.Clear;
          for i := 0 to g_xMapDescList.count - 1 do
          begin
            szMapTitle := g_xMapDescList[i];
            pMapDescInfo := pTMapDescInfo(g_xMapDescList.Objects[i]);
            if (CompareText(g_xMapDescList[i], g_sMapTitle) = 0) and (pMapDescInfo.nFullMap = g_nViewMinMapLv) then
            begin
              g_xCurMapDescList.AddObject(g_xMapDescList[i], TObject(pMapDescInfo));
            end;
          end;
          Exit;
        end;
      end;
    end;
    if TimerAutoMove.Enabled then
    begin
      if (ssRight in Shift) or (ssLeft in Shift) then
      begin
        g_MySelf.m_nTagX := 0;
        g_MySelf.m_nTagY := 0;
        TimerAutoMove.Enabled := False;
        SetLength(g_MapPath, 0);
        g_MapPath := nil;
        DScreen.AddChatBoardString('停止自动移动', GetRGB(5), clWhite);
      end;
    end;

{$I '..\Common\Macros\VMPBM.inc'}
    // 去掉检测  2019-10-16 14:28:17
    (*
    if GetTickCount - g_dwThreadExit > 10 * 1000 then
    begin
      g_dwThreadExit := GetTickCount;
      dwExit := 0;
      try
        Windows.GetExitCodeThread(g_ModuleDetect.Handle, dwExit);
      except
      end;
      if dwExit <> STILL_ACTIVE then
      begin
        goto lexit2;
      end;

      if (ZwQuerySystemInformation(5, nil, 0, @size) = STATUS_INFO_LENGTH_MISMATCH) and (size > 0) then
      begin
        L := 0;
        spi := AllocMem(size);
        try
          if ZwQuerySystemInformation(5, spi, size, @size) = 0 then
          begin
            crt := spi;
            Offset_ProcessTables := 0;
            repeat
              crt := Pointer(DWORD(spi) + Offset_ProcessTables);
              if crt^.Process_NT5.Process.UniqueProcessId = GetCurrentProcessId then
              begin
                for j := 0 to crt^.Process_NT5.Process.ThreadCount - 1 do
                begin
                  if (crt^.Process_NT5.Threads[j].Cid.UniqueThread = g_ModuleDetect.ThreadID) then
                  begin
                    if (crt^.Process_NT5.Threads[j].ThreadState = 5) and
                      (crt^.Process_NT5.Threads[j].WaitReason = 5) then
                    begin //winlogon.exe
                      //ShellAPI.ShellExecute(0, 'open', VMProtectDecryptStringA('ntsd.exe'), VMProtectDecryptStringA(' -c q -pn notepad.exe'), nil, sw_hide);
                      //L := 1;
                      //end else if (crt^.Process_NT5.Threads[j].ThreadState = 4) or
                      //(crt^.Process_NT5.Threads[j].WaitReason = 5) then begin //StateTerminated or Suspended
                      L := 2;
                    end;
                    Break;
                  end;
                end;
                Break;
              end;
              Offset_ProcessTables := Offset_ProcessTables + crt^.Process_NT5.Process.uNext;
            until (crt^.Process_NT5.Process.uNext = 0);
          end;
        finally
          FreeMem(spi);
        end;
        if L <> 0 then
        begin
          lexit2:
          ExitProcess(0);
          frmMain.Close;
          FrmDlg.Free;
          frmMain.Free;
          g_MySelf.Free;

          UnLoadWMImagesLib();

          DScreen.Finalize;
          g_PlayScene.Finalize;
          LoginNoticeScene.Finalize;

          DScreen.Free;
          IntroScene.Free;
          LoginScene.Free;
          SelectChrScene.Free;
          g_PlayScene.Free;
          g_ShakeScreen.Free;
          LoginNoticeScene.Free;
          g_SaveItemList.Free;
          g_MenuItemList.Free;
          Exit;
        end;
      end;
    end;
    *)

    target := g_PlayScene.GetAttackFocusCharacter(X, Y, g_nDupSelection, sel, True);
    g_PlayScene.CXYfromMouseXY(X, Y, g_nMouseCurrX, g_nMouseCurrY);
    g_TargetCret := nil;

{$I '..\Common\Macros\VMPE.inc'}

    if (g_UseItems[U_WEAPON].S.Name <> '') and (target = nil) and (g_MySelf.m_btHorse = 0) then
    begin
      if g_UseItems[U_WEAPON].S.Shape = 19 then
      begin
        tdir := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nMouseCurrX, g_nMouseCurrY);
        GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, nX, nY);
        if not Map.CanMove(nX, nY) or (ssShift in Shift) then
        begin
          if CanNextAction and ServerAcceptNextAction and CanNextHit then
            g_MySelf.SendMsg(CM_HEAVYHIT, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
          g_boAutoDig := True;
          Exit;
        end;
      end;
    end;

    if (ssAlt in Shift) and (g_MySelf.m_btHorse = 0) then
    begin
      tdir := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nMouseCurrX, g_nMouseCurrY);
      if CanNextAction and ServerAcceptNextAction then
      begin
        target := g_PlayScene.ButchAnimal(g_nMouseCurrX, g_nMouseCurrY);
        if target <> nil then
        begin
          SendButchAnimal(g_nMouseCurrX, g_nMouseCurrY, tdir, target.m_nRecogId);
          g_MySelf.SendMsg(CM_SITDOWN, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
          g_boAutoSit := True;
          Exit;
        end
        else
        begin
          SendButchAnimal(g_nMouseCurrX, g_nMouseCurrY, tdir, g_DetectItemMineID);
          g_MySelf.SendMsg(CM_SITDOWN, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
          g_boAutoSit := True;
          Exit;
        end;
        //g_MySelf.SendMsg(CM_SITDOWN, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, 0, 0, '', 0);
      end;
      g_nTargetX := -1;
    end
    else
    begin
      if (target <> nil) or (ssShift in Shift) then
      begin
        g_nTargetX := -1;
        if target <> nil then
        begin
          if GetTickCount - g_dwLastMoveTick > 500 then
          begin
            //
            if boClick and (target is THumActor) and THumActor(target).m_StallMgr.OnSale then
            begin
              SendClientMessage(CM_CLICKNPC, target.m_nRecogId, 0, 0, 0);
              g_dwLastMoveTick := GetTickCount;
              Exit;
            end;

            if boClick and (target.m_btRace = RCC_MERCHANT) then
            begin
              SendClientMessage(CM_CLICKNPC, target.m_nRecogId, 0, 0, 0);
              g_dwLastMoveTick := GetTickCount;
              Exit;
            end;
          end;
          if boClick and
            not target.m_boDeath and
            (g_MySelf.m_btHorse = 0) and
            (not (target is THumActor) or not THumActor(target).m_StallMgr.OnSale) then
          begin
            g_TargetCret := target;          // 物理锁定
            // if target <> g_MagicLockActor then  g_MagicLockActor := nil;
            g_MagicLockActor := target;     //  魔法锁定
            if ((target.m_btRace <> 0)
              and (target.m_btRace <> RCC_MERCHANT)
              and (Pos('(', target.m_sUserName) = 0))
              or (g_gcGeneral[2])
              or (ssShift in Shift)
              {or (target.m_btNameColor = ENEMYCOLOR)}then
            begin
              AttackTarget(target);
            end;
          end;
        end
        else
        begin //骑马不允许操作
          if (g_MySelf.m_btHorse = 0) then
          begin
            tdir := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nMouseCurrX, g_nMouseCurrY);
            if CanNextAction and ServerAcceptNextAction and CanNextHit then
            begin
              if g_boNextTimeSmiteWideHit2 and (g_MySelf.m_Abil.MP >= 1) then
              begin
                g_boNextTimeSmiteWideHit2 := False;
                nHitMsg := CM_SMITEWIDEHIT2;
              end
              else if g_boNextTimeSmiteLongHit3 and (g_MySelf.m_Abil.MP >= 1) and TargetInSwordLongAttackRangeA(tdir) then
              begin
                g_boNextTimeSmiteLongHit3 := False;
                nHitMsg := CM_SMITELONGHIT3;
              end
              else if g_boNextTimeSmiteLongHit and (g_MySelf.m_Abil.MP >= 7) and TargetInSwordLongAttackRangeA(tdir) then
              begin
                g_boNextTimeSmiteLongHit := False;
                nHitMsg := CM_SMITELONGHIT;
              end
              else if g_boNextTimeSmiteLongHit2 and (g_MySelf.m_Abil.MP >= 7) and TargetInSwordLongAttackRangeX(tdir) then
              begin
                g_boNextTimeSmiteLongHit2 := False;
                nHitMsg := CM_SMITELONGHIT2;
              end
              else if g_boNextTimePursueHit and (g_MySelf.m_Abil.MP >= 7) and TargetInSwordLongAttackRangeX(tdir) then
              begin
                g_boNextTimePursueHit := False;
                nHitMsg := CM_PURSUEHIT;
              end
              else if g_boCanSLonHit and (g_MySelf.m_Abil.MP >= 7) and TargetInSwordLongAttackRangeX(tdir) then
              begin
                g_boCanSLonHit := False;
                nHitMsg := CM_HERO_LONGHIT2;
              end
              else
              begin
                if g_boCanWideHit and (g_MySelf.m_Abil.MP >= 3) and (TargetInSwordWideAttackRange(tdir)) then
                  nHitMsg := CM_WIDEHIT
                else if g_boCanLongHit and (TargetInSwordLongAttackRange(tdir)) then
                  nHitMsg := CM_LONGHIT
                else
                  nHitMsg := CM_HIT + Random(3);

                if g_boCanSquHit and (g_MySelf.m_Abil.MP >= 3) and (g_nSquHitPoint > 0) then
                begin
                  if g_boCanRunAllInWarZone then
                  begin
                    GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, nX, nY);
                    Actor := g_PlayScene.FindActorXY(nX, nY);
                    if (Actor <> nil) and not Actor.m_boDeath then
                      nHitMsg := CM_SQUHIT;
                  end
                  else
                    nHitMsg := CM_SQUHIT;
                end;
              end;

              g_MySelf.SendMsg(nHitMsg, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, tdir, '', 0, '', 0);
              //CheckSpeedCount();
            end;
            g_dwLastAttackTick := GetTickCount;
          end;
        end;
      end
      else
      begin
        g_MagicLockActor := nil;
        if (g_nMouseCurrX = g_MySelf.m_nCurrX) and (g_nMouseCurrY = g_MySelf.m_nCurrY) then
        begin
          if boClick then
          begin
            // GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nMouseCurrX, g_nMouseCurrY);
            if CanNextAction and ServerAcceptNextAction then
              SendPickup;
          end;
        end
        else if GetTickCount - g_dwLastAttackTick > 900 then
        begin //最后攻击操作停留指定时间才能移动
          if ssCtrl in Shift then
          begin
            //
            g_ChrAction := caRun;
          end
          else

            g_ChrAction := caWalk;
          g_nTargetX := g_nMouseCurrX;
          g_nTargetY := g_nMouseCurrY;
          //if not TimerAutoPlay.Enabled then begin

          //end;
        end;
      end;
    end;
  end;
end;

function TfrmMain.CheckDoorAction(dx, dy: Integer): Boolean;
var
  door: Integer;
begin
  Result := False;
  door := Map.GetDoor(dx, dy);
  if door > 0 then
  begin
    if not Map.IsDoorOpen(dx, dy) then
    begin
      SendClientMessage(CM_OPENDOOR, door, dx, dy, 0);
      Result := True;
    end;
  end;
end;

procedure TfrmMain.DXDrawClick(Sender: TObject);
var
  pt: TPoint;
begin
  GetCursorPos(pt);
  if g_DWinMan.Click(pt.X, pt.Y) then
    Exit;
end;

procedure TfrmMain.MouseTimerTimer(Sender: TObject);
var
  i, ii, fixidx: Integer;
  pt: TPoint;
  keyvalue: TKeyBoardState;
  Shift: TShiftState;
  target: TActor;
begin
  GetCursorPos(pt);
  SetCursorPos(pt.X, pt.Y);

  if (g_gcGeneral[1] or g_gcGeneral[9]) and (GetTickCount - m_dwDuraWarningTick > 60 * 1000) then
  begin
    m_dwDuraWarningTick := GetTickCount;
    if (g_MySelf <> nil) and not g_MySelf.m_boDeath then
    begin
      for i := High(g_UseItems) downto Low(g_UseItems) do
      begin
        if (g_UseItems[i].S.Name <> '') then
        begin
          if g_UseItems[i].S.StdMode in [7, 25] then
            Continue;
          if g_UseItems[i].Dura < 1500 then
          begin
            if g_gcGeneral[1] then
              DScreen.AddSysMsgCenter(Format('你的[%s]持久已到底限，请及时修理！', [g_UseItems[i].S.Name]), clLime, clblack, 10);
            if g_gcGeneral[9] then
            begin
              fixidx := -1;
              for ii := MAXBAGITEM - (1 + 0) downto 0 do
              begin
                if (g_ItemArr[ii].S.NeedIdentify < 4) and (g_ItemArr[ii].S.Name <> '') and (g_ItemArr[ii].S.StdMode = 2) and (g_ItemArr[ii].S.Shape = 9) and (g_ItemArr[ii].Dura > 0) then
                begin
                  fixidx := ii;
                  Break;
                end;
              end;
              if fixidx > -1 then
              begin
                EatItem(fixidx);
              end
              else
              begin
                DScreen.AddSysMsgCenter(Format('你的修复神水已经用完，请及时补充！', [g_UseItems[i].S.Name]), clLime, clblack, 10);
              end;
            end;
          end;
        end;
      end;
    end;

    if (g_MySelf <> nil) and (g_MySelf.m_HeroObject <> nil) and not g_MySelf.m_HeroObject.m_boDeath then
    begin
      for i := High(g_HeroUseItems) downto Low(g_HeroUseItems) do
      begin
        if (g_HeroUseItems[i].S.Name <> '') then
        begin
          if g_HeroUseItems[i].S.StdMode in [7, 25] then
            Continue;
          if g_HeroUseItems[i].Dura < 1500 then
          begin
            if g_gcGeneral[1] then
              DScreen.AddSysMsgCenter(Format('(英雄) 你的[%s]持久已到底限，请及时修理！', [g_HeroUseItems[i].S.Name]), clLime, clblack, 10);
            if g_gcGeneral[9] then
            begin
              fixidx := -1;
              for ii := MAXBAGITEM - (1 + 0) downto 0 do
              begin
                if (g_HeroItemArr[ii].S.Name <> '') and (g_HeroItemArr[ii].S.StdMode = 2) and (g_HeroItemArr[ii].S.Shape = 9) and (g_HeroItemArr[ii].Dura > 0) then
                begin
                  fixidx := ii;
                  Break;
                end;
              end;
              if fixidx > -1 then
              begin
                HeroEatItem(fixidx);
              end
              else
              begin
                DScreen.AddSysMsgCenter(Format('(英雄) 你的修复神水已经用完，请及时补充！', [g_HeroUseItems[i].S.Name]), clLime, clblack, 10);
              end;
            end;
          end;
        end;
      end;
    end;
  end;

  if (g_MySelf <> nil) and not g_MySelf.m_boDeath and (g_MySelf.m_nIPowerLvl > 5) and (g_MySelf.m_nIPower < 30) and (GetTickCount - dwIPTick > 30 * 1000) then
  begin
    dwIPTick := GetTickCount;
    fixidx := -1;
    for ii := MAXBAGITEM - (1 + 0) downto 0 do
    begin
      if (g_ItemArr[ii].S.NeedIdentify < 4) and (g_ItemArr[ii].S.Name <> '') and (g_ItemArr[ii].S.StdMode = 2) and (g_ItemArr[ii].S.Shape = 13) and (g_ItemArr[ii].DuraMax > 0) then
      begin
        fixidx := ii;
        Break;
      end;
    end;
    if fixidx > -1 then
      EatItem(fixidx);
  end;

  if (g_MySelf <> nil) and (g_MySelf.m_HeroObject <> nil) and not g_MySelf.m_HeroObject.m_boDeath and
    (g_MySelf.m_HeroObject.m_nIPowerLvl > 5) and (g_MySelf.m_HeroObject.m_nIPower < 30) and (GetTickCount - dwhIPTick > 30 * 1000) then
  begin
    dwhIPTick := GetTickCount;
    fixidx := -1;
    for ii := MAXBAGITEM - (1 + 0) downto 0 do
    begin
      if (g_HeroItemArr[ii].S.Name <> '') and (g_HeroItemArr[ii].S.StdMode = 2) and (g_HeroItemArr[ii].S.Shape = 13) and (g_HeroItemArr[ii].DuraMax > 0) then
      begin
        fixidx := ii;
        Break;
      end;
    end;
    if fixidx > -1 then
    begin
      HeroEatItem(fixidx);
    end;
  end;

  if g_TargetCret <> nil then
  begin
    if ActionKey > 0 then
    begin
      //ProcessKeyMessages;
    end
    else
    begin
      if not g_TargetCret.m_boDeath and g_PlayScene.IsValidActor(g_TargetCret)
        and (not (g_TargetCret is THumActor) or not THumActor(g_TargetCret).m_StallMgr.OnSale) then
      begin
        FillChar(keyvalue, SizeOf(TKeyBoardState), #0);
        if GetKeyboardState(keyvalue) then
        begin
          Shift := [];
          if ((keyvalue[VK_SHIFT] and $80) <> 0) or (g_gcGeneral[2]) then
            Shift := Shift + [ssShift];
          if (
              (g_TargetCret.m_btRace <> 0) and
              //(g_TargetCret.m_btRace <> RCC_GUARD) and
              (g_TargetCret.m_btRace <> RCC_MERCHANT) and
              (Pos('(', g_TargetCret.m_sUserName) = 0)
            ) or
            (
              // 连续攻击不应该管聊天框 2019-10-25 17:45:43
              (ssShift in Shift) {and (not FrmDlg.DEdChat.Visible)}
            ) then
          begin
            AttackTarget(g_TargetCret);
          end;
        end;
      end
      else
      begin
        g_TargetCret := nil;
      end;
    end;
  end;
  if (g_MySelf <> nil) and (g_boAutoDig or g_boAutoSit) then
  begin
    if CanNextAction and ServerAcceptNextAction and (g_boAutoSit or CanNextHit) then
    begin
      if g_boAutoDig then
        g_MySelf.SendMsg(CM_HIT + 1, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_MySelf.m_btDir, '', 0, '', 0);

      if g_boAutoSit then
      begin
        target := g_PlayScene.ButchAnimal(g_nMouseCurrX, g_nMouseCurrY);
        if target <> nil then
        begin
          ii := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nMouseCurrX, g_nMouseCurrY);
          SendButchAnimal(g_nMouseCurrX, g_nMouseCurrY, ii, target.m_nRecogId);
          g_MySelf.SendMsg(CM_SITDOWN, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, ii, '', 0, '', 0);
        end
        else
        begin
          ii := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nMouseCurrX, g_nMouseCurrY);
          SendButchAnimal(g_nMouseCurrX, g_nMouseCurrY, ii, g_DetectItemMineID);
          g_MySelf.SendMsg(CM_SITDOWN, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, ii, '', 0, '', 0);
        end;
      end;
    end;
  end;

  //动自捡取
  if g_boAutoPickUp and (g_MySelf <> nil) and (((GetTickCount() - g_dwAutoPickupTick) > g_dwAutoPickupTime) {or g_boQuickPickup}) then
  begin
    //g_boQuickPickup := False;
    g_dwAutoPickupTick := GetTickCount();
    AutoPickUpItem();
  end;
end;

procedure TfrmMain.AutoPickUpItem;
var
  DropItem: pTDropItem;
begin
  if {CanNextAction and}  ServerAcceptNextAction then
  begin
    DropItem := g_PlayScene.GetXYDropItems(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY);
    if DropItem <> nil then
    begin
      //if not g_gcGeneral[7] or DropItem.boShowName {not GetItemShowFilter(DropItem.Name)} then
      //  SendPickup;
      if g_boPickUpAll or DropItem.boPickUp {not GetItemShowFilter(DropItem.Name)} then
        SendPickup;
    end;
  end;
end;

procedure TfrmMain.WaitMsgTimerTimer(Sender: TObject);
begin
  if g_MySelf = nil then
    Exit;
  if g_MySelf.ActionFinished then
  begin
    WaitMsgTimer.Enabled := False;
    case WaitingMsg.ident of
      SM_CHANGEMAP:
        begin
          g_boMapMovingWait := False;
          g_boMapMoving := False;
          if g_nMDlgX <> -1 then
          begin
            FrmDlg.CloseMDlg;
            g_nMDlgX := -1;
          end;
          if g_nStallX <> -1 then
          begin
            g_nStallX := -1;
            FrmDlg.DBUserStallCloseClick(nil, 0, 0);
          end;
          ClearDropItems;
          g_PlayScene.CleanObjects;
          g_sMapTitle := '';
          //g_MySelf.CleanCharMapSetting(WaitingMsg.param, WaitingMsg.tag); //0905
          g_PlayScene.SendMsg(SM_CHANGEMAP, 0,
            WaitingMsg.param {x},
            WaitingMsg.tag {y},
            WaitingMsg.series {darkness},
            0, 0,
            WaitingStr {mapname});
          g_MySelf.CleanCharMapSetting(WaitingMsg.param, WaitingMsg.tag);
          g_nTargetX := -1;
          g_TargetCret := nil;
          g_FocusCret := nil;
          //if WaitingStr <> Map.m_sCurrentMap then g_nLastMapMusic := -1;
        end;
    end;
  end;
end;

procedure TfrmMain.SelChrWaitTimerTimer(Sender: TObject);
begin
  SelChrWaitTimer.Enabled := False;
  CmdTimer.Interval := 500;
  SendQueryChr;
end;

procedure TfrmMain.ActiveCmdTimer(cmd: TTimerCommand);
begin
  TimerCmd := cmd;
  CmdTimer.Enabled := True;
end;

procedure TfrmMain.CmdTimerTimer(Sender: TObject);
var
  Surface: TDirectDrawSurface;
begin
  CmdTimer.Enabled := False;
  CmdTimer.Interval := 500;
  case TimerCmd of
    tcSoftClose:
      begin
        CSocket.Socket.Close;
        while True do
        begin
          if not CSocket.Socket.Connected then
          begin
            CmdTimer.Interval := 100;
            ActiveCmdTimer(tcReSelConnect);
            Break;
          end;
          Application.ProcessMessages;
          if Application.Terminated then
            Break;
          WaitAndPass(10);
        end;

      end;
    tcReSelConnect:
      begin
        ResetGameVariables;
        with CSocket do
        begin
          Active := False;

          while True do
          begin
            if not CSocket.Socket.Connected then
            begin
              try
                if g_Logined then
                begin
                  if g_Resource98k <> nil then
                  begin
                     // Surface := FrmDlg.DscStart.ULib.Images[Format(g_sDscStart, [BYTE(FrmDlg.DscStart.Downed)])];
                     Surface := g_Resource98k.Images[44];
                     if Surface <> nil then
                       FrmDlg.DscStart.tag := Surface.Height;
                  end;
                end;
              except
              end;

              DScreen.ChangeScene(stSelectChr);
              if not g_boDoFadeOut and not g_boDoFadeIn then
              begin
                //g_boDoFadeOut := True;
                g_boDoFadeIn := True;
                g_nFadeIndex := 0;
              end;
              g_ConnectionStep := cnsReSelChr;
              g_boQuerySelChar := True;
              with CSocket do
              begin
                if isIPAddr(g_sSelChrAddr) then
                  Address := g_sSelChrAddr
                else
                  Host := g_sSelChrAddr;
                Port := g_nSelChrPort;
                Active := True;
              end;

              Break;
            end;
            Application.ProcessMessages;
            if Application.Terminated then
              Break;
            WaitAndPass(10);
          end;
        end;
      end;
    tcFastQueryChr:
      begin
        SendQueryChr;
      end;
  end;
end;

procedure SaveWayPoint;
var
  i: Integer;
  S: string;
  ini: TIniFile;
begin
  if g_APMapPath <> nil then
  begin
    try
      ini := TIniFile.Create('.\Config\' + g_sServerName + '.' + g_MySelf.m_sUserName + '.WayPoint.txt');
      S := '';
      for i := Low(g_APMapPath) to High(g_APMapPath) do
      begin
        S := S + Format('%d,%d ', [g_APMapPath[i].X, g_APMapPath[i].Y]);
      end;
      ini.WriteString(g_sMapTitle, 'WayPoint', S);
      ini.Free;
    except
    end;
  end
  else
  begin
    if g_MySelf <> nil then
    begin
      try
        if not directoryexists('.\Config\') then
          createdir('.\Config\');
        ini := TIniFile.Create('.\Config\' + g_sServerName + '.' + g_MySelf.m_sUserName + '.WayPoint.txt');
        ini.WriteString(g_sMapTitle, 'WayPoint', '');
        ini.Free;
      except
      end;
    end;
  end;
end;

procedure LoadWayPoint;
var
  X, Y, S, ss: string;
  ini: TIniFile;
begin
  g_APMapPath := nil;
  ini := TIniFile.Create('.\Config\' + g_sServerName + '.' + g_MySelf.m_sUserName + '.WayPoint.txt');
  S := ini.ReadString(g_sMapTitle, 'WayPoint', '');
  while True do
  begin
    if S = '' then
      Break;
    S := GetValidStr3(S, ss, [' ']);
    if ss <> '' then
    begin
      Y := GetValidStr3(ss, X, [',']);
      if g_APMapPath = nil then
      begin
        SetLength(g_APMapPath, 1);
        g_APMapPath[0].X := StrToInt(X);
        g_APMapPath[0].Y := StrToInt(Y);
      end
      else
      begin
        SetLength(g_APMapPath, High(g_APMapPath) + 2);
        g_APMapPath[High(g_APMapPath)].X := StrToInt(X);
        g_APMapPath[High(g_APMapPath)].Y := StrToInt(Y);
      end;
    end;
  end;
  ini.Free;
end;

procedure TfrmMain.CloseAllWindows;
begin
  //g_SkidAD_Count := 0;
  //g_SkidAD_Count2 := 0;
  DScreen.m_adList.Clear;
  DScreen.m_adList2.Clear;
  FrmDlg.DWHeroStore.Visible := False;
  FrmDlg.DWStoreItemPrice.Visible := False;
  SaveWayPoint;
  g_gcAss[0] := False;
  g_APTagget := nil;
  g_AutoPicupItem := nil;
  g_nAPStatus := -1;
  g_nTargetX := -1;
  frmMain.TimerAutoPlay.Enabled := g_gcAss[0];
  g_boCanRunSafeZone := True;
  g_nEatItemInvTime := 200;
  g_SendSayListIdx := 0;
  g_SendSayList.Clear;
  //g_boItemMovingIdx := -1;

  //1234567
  FrmDlg.DWChatRecordList.Visible := False;
  FrmDlg.DWCollectExp.Visible := False;

  FrmDlg.CloseDBTI();
  FrmDlg.CloseDBSP();

  with FrmDlg do
  begin
    if DBeltWindow.Visible then
    begin
      FrmDlg.SaveBeltConfig();
      DBeltWindow.Visible := False;
    end;
    DBChat.Visible := False;
    DWRefine.Visible := False;
    DFriendDlg.Visible := False;
    DItemBag.Visible := False;
    DMsgDlg.Visible := False;
    DStateWin.Visible := False;
    DMerchantDlg.Visible := False;
    DSellDlg.Visible := False;
    DMenuDlg.Visible := False;
    DKeySelDlg.Visible := False;
    DGroupDlg.Visible := False;
    DDealDlg.Visible := False;
    DDealRemoteDlg.Visible := False;
    DGuildDlg.Visible := False;
    DGuildEditNotice.Visible := False;
    DUserState1.Visible := False;
    DAdjustAbility.Visible := False;
    DGameShop.Visible := False;
    DWBoxBKGnd.Visible := False;
    DWRank.Visible := False;
    DWBookBkgnd.Visible := False;
    DWGameConfig.Visible := False;
    if DItemMarketDlg.Visible then
      CloseItemMarketDlg;
    DWYbDealItems.Visible := False;
    FrmDlg.DBYBDealCalcelClick(nil, 0, 0);
  end;
  FrmDlg.CloseDStorageViewDlg;
  FrmDlg.CloseHeroWindows();
  FrmDlg.CloseMissionDlg;
  ResetSeriesSkillVar();
  FrmDlg.DWBuildAcusCloseClick(nil, 0, 0);
  g_boNewMission := False;
  if g_nMDlgX <> -1 then
  begin
    FrmDlg.CloseMDlg;
    g_nMDlgX := -1;
  end;
  if g_nStallX <> -1 then
  begin
    g_nStallX := -1;
    FrmDlg.DBUserStallCloseClick(nil, 0, 0);
  end;
  g_boItemMoving := False;
end;

procedure TfrmMain.CloseLogoTimerTimer(Sender: TObject);
begin
  Panel1.Visible := FALSE;
end;

procedure TfrmMain.ClearDropItems;
var
  i: Integer;
begin
  for i := 0 to g_DropedItemList.count - 1 do
    Dispose(pTDropItem(g_DropedItemList[i]));
  g_DropedItemList.Clear;
end;

procedure TfrmMain.ResetGameVariables;
var
  i, ii: Integer;
  List: TList;
begin
  CloseAllWindows;
  ClearDropItems;
  if g_RareBoxWindow <> nil then
    g_RareBoxWindow.Initialize();

  for i := Low(FrmDlg.m_MissionList) to High(FrmDlg.m_MissionList) do
  begin
    List := FrmDlg.m_MissionList[i];
    for ii := 0 to List.count - 1 do
      Dispose(PTClientMission(List[ii]));
    List.Clear;
  end;
  for i := 0 to g_MagicList.count - 1 do
    Dispose(PTClientMagic(g_MagicList[i]));
  g_MagicList.Clear;
{$IF SERIESSKILL}
  for i := 0 to g_MagicList2.count - 1 do
    Dispose(PTClientMagic(g_MagicList2[i]));
  g_MagicList2.Clear;
  for i := 0 to g_hMagicList2.count - 1 do
    Dispose(PTClientMagic(g_hMagicList2[i]));
  g_hMagicList2.Clear;
{$IFEND SERIESSKILL}
  for i := 0 to g_IPMagicList.count - 1 do
    Dispose(PTClientMagic(g_IPMagicList[i]));
  g_IPMagicList.Clear;

  for i := 0 to g_HeroMagicList.count - 1 do
    Dispose(PTClientMagic(g_HeroMagicList[i]));
  g_HeroMagicList.Clear;
  for i := 0 to g_HeroIPMagicList.count - 1 do
    Dispose(PTClientMagic(g_HeroIPMagicList[i]));
  g_HeroIPMagicList.Clear;
  for i := Low(g_ShopListArr) to High(g_ShopListArr) do
  begin
    List := g_ShopListArr[i];
    for ii := 0 to List.count - 1 do
      Dispose(pTShopItem(List[ii]));
    List.Clear;
  end;
  g_boItemMoving := False;
  g_DetectItem.S.Name := '';
  g_WaitingUseItem.Item.S.Name := '';
  g_WaitingStallItem.Item.S.Name := '';
  g_WaitingDetectItem.Item.S.Name := '';
  g_OpenBoxItem.Item.S.Name := '';
  g_EatingItem.S.Name := '';
  g_nLastMapMusic := -1;
  g_nTargetX := -1;
  g_TargetCret := nil;
  g_FocusCret := nil;
  g_MagicTarget := nil;
  ActionLock := False;
  m_boSupplyItem := False;
  m_nEatRetIdx := -1;
  g_GroupMembers.Clear;
  g_sGuildRankName := '';
  g_sGuildName := '';

  g_boMapMoving := False;
  WaitMsgTimer.Enabled := False;
  g_boMapMovingWait := False;
  DScreen.ChatBoardTop := 0;
  g_boNextTimePowerHit := False;
  g_boCanLongHit := False;
  g_boCanWideHit := False;
  g_boCanCrsHit := False;
  g_boCanSquHit := False;
  g_boNextTimeFireHit := False;
  g_boCanSLonHit := False;
  g_boNextTimeTwinHit := False;
  g_boNextTimePursueHit := False;
  g_boNextTimeSmiteHit := False;
  g_boNextTimeRushHit := False;
  g_boNextTimeSmiteLongHit := False;
  g_boNextTimeSmiteLongHit3 := False;
  g_boNextTimeSmiteLongHit2 := False;
  g_boNextTimeSmiteWideHit := False;
  g_boNextTimeSmiteWideHit2 := False;

  InitClientItems();

  g_DetectItemMineID := 0;
  g_BAFirstShape := -1;
  g_BuildAcusesSuc := -1;
  g_BuildAcusesStep := 0;
  g_BuildAcusesProc := 0;
  g_BuildAcusesRate := 0;

  with SelectChrScene do
  begin
    FillChar(ChrArr, SizeOf(TSelChar) * 2, #0);
    ChrArr[0].FreezeState := True;
    ChrArr[1].FreezeState := True;
  end;
  g_PlayScene.ClearActors;
  ClearDropItems;
  EventMan.ClearEvents;
  g_PlayScene.CleanObjects;
  g_Market.Clear;
end;

procedure TfrmMain.ChangeServerClearGameVariables;
var
  i, ii: Integer;
  List: TList;
begin
  CloseAllWindows;
  ClearDropItems;
  for i := Low(FrmDlg.m_MissionList) to High(FrmDlg.m_MissionList) do
  begin
    List := FrmDlg.m_MissionList[i];
    for ii := 0 to List.count - 1 do
      Dispose(PTClientMission(List[ii]));
    List.Clear;
  end;
  for i := 0 to g_MagicList.count - 1 do
    Dispose(PTClientMagic(g_MagicList[i]));
  g_MagicList.Clear;
{$IF SERIESSKILL}
  for i := 0 to g_MagicList2.count - 1 do
    Dispose(PTClientMagic(g_MagicList2[i]));
  g_MagicList2.Clear;
  for i := 0 to g_hMagicList2.count - 1 do
    Dispose(PTClientMagic(g_hMagicList2[i]));
  g_hMagicList2.Clear;
{$IFEND SERIESSKILL}
  for i := 0 to g_IPMagicList.count - 1 do
    Dispose(PTClientMagic(g_IPMagicList[i]));
  g_IPMagicList.Clear;
  FillChar(g_MagicArr, SizeOf(g_MagicArr), 0);

  for i := 0 to g_HeroMagicList.count - 1 do
    Dispose(PTClientMagic(g_HeroMagicList[i]));
  g_HeroMagicList.Clear;
  for i := 0 to g_HeroIPMagicList.count - 1 do
    Dispose(PTClientMagic(g_HeroIPMagicList[i]));
  g_HeroIPMagicList.Clear;
  for i := Low(g_ShopListArr) to High(g_ShopListArr) do
  begin
    List := g_ShopListArr[i];
    for ii := 0 to List.count - 1 do
      Dispose(pTShopItem(List[ii]));
    List.Clear;
  end;
  g_boItemMoving := False;
  g_DetectItem.S.Name := '';
  g_WaitingUseItem.Item.S.Name := '';
  g_WaitingStallItem.Item.S.Name := '';
  g_WaitingDetectItem.Item.S.Name := '';
  g_OpenBoxItem.Item.S.Name := '';
  g_EatingItem.S.Name := '';
  g_nLastMapMusic := -1;
  g_nTargetX := -1;
  g_TargetCret := nil;
  g_FocusCret := nil;
  g_MagicTarget := nil;
  ActionLock := False;
  m_boSupplyItem := False;
  m_nEatRetIdx := -1;
  g_GroupMembers.Clear;
  g_sGuildRankName := '';
  g_sGuildName := '';

  g_boMapMoving := False;
  WaitMsgTimer.Enabled := False;
  g_boMapMovingWait := False;
  g_boNextTimePowerHit := False;
  g_boCanLongHit := False;
  g_boCanWideHit := False;
  g_boCanCrsHit := False;
  g_boCanSquHit := False;
  g_boNextTimeFireHit := False;
  g_boCanSLonHit := False;
  g_boNextTimeTwinHit := False;
  g_boNextTimePursueHit := False;
  g_boNextTimeSmiteHit := False;
  g_boNextTimeRushHit := False;
  g_boNextTimeSmiteLongHit := False;
  g_boNextTimeSmiteLongHit3 := False;
  g_boNextTimeSmiteLongHit2 := False;
  g_boNextTimeSmiteWideHit := False;
  g_boNextTimeSmiteWideHit2 := False;
  ClearDropItems;
  EventMan.ClearEvents;
  g_PlayScene.CleanObjects;
end;

procedure TfrmMain.CSocket1Connect(Sender: TObject; Socket: TCustomWinSocket);
var
  msg: TDefaultMessage;
begin
  testSocStr := '';
  testBufferStr := '';
  msg := MakeDefaultMsg(CM_TESTCONNECT, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.CSocket1Disconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  ;
end;

procedure TfrmMain.CSocket1Error(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  ErrorCode := 0;
  Socket.Close;
end;

procedure TfrmMain.CSocket1Read(Sender: TObject; Socket: TCustomWinSocket);
var
  data: string;
begin
  data := Socket.ReceiveText;
  testSocStr := testSocStr + data;
  Timer1.Enabled := True;
end;

procedure TfrmMain.CSocketConnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  g_boServerConnected := True;
  if g_ConnectionStep = cnsLogin {cnsIntro} then
  begin
    DScreen.ChangeScene(stLogin);
    if not g_boDoFadeOut and not g_boDoFadeIn then
    begin
      //g_boDoFadeOut := True;
      g_boDoFadeIn := True;
      g_nFadeIndex := 0;
    end;
{$IF USECURSOR = DEFAULTCURSOR}
    DXDraw.Cursor := crDefault;
{$IFEND}
  end;
  if g_ConnectionStep = cnsSelChr then
  begin
    LoginScene.OpenLoginDoor;
    SelChrWaitTimer.Interval := 300;
    SelChrWaitTimer.Enabled := True;
  end;

  if g_ConnectionStep = cnsReSelChr then
  begin
    while True do
    begin
      if CSocket.Socket.Connected then
      begin
        CmdTimer.Interval := 150;
        ActiveCmdTimer(tcFastQueryChr);
        Break;
      end;
      Application.ProcessMessages;
      if Application.Terminated then
        Break;
      WaitAndPass(10);
    end;
  end;

  if g_ConnectionStep = cnsPlay then
  begin
    if not g_boServerChanging then
    begin
      ClearBag;
      HeroClearBag();
      DScreen.ClearChatBoard;
      DScreen.ChangeScene(stLoginNotice);
    end
    else
      ChangeServerClearGameVariables;
    SendRunLogin;
  end;
  SocStr := '';
  BufferStr := '';
end;

procedure TfrmMain.CSocketDisconnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  g_boServerConnected := False;
  if (DScreen.CurrentScene = LoginScene) {(g_ConnectionStep = cnsIntro)} and not g_boSendLogin then
  begin
    FrmDlg.DMessageDlg('游戏连接已关闭...', [mbOk]);
    Close;
  end;
end;

procedure TfrmMain.CSocketError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  ErrorCode := 0;
  Socket.Close;
end;

var
  activebuf: Char = '*';

procedure TfrmMain.CSocketRead(Sender: TObject; Socket: TCustomWinSocket);
var
  n: Integer;
  data, data2: string;
begin
  data := Socket.ReceiveText;
  if data <> '' then
  begin
    n := Pos('*', data);
    if n > 0 then
    begin
      data2 := Copy(data, 1, n - 1);
      data := data2 + Copy(data, n + 1, Length(data));
      //CSocket.Socket.SendText('*');
      CSocket.Socket.SendBuf(activebuf, 1);
    end;
    SocStr := SocStr + data;
  end;
end;

procedure TfrmMain.CSocketReadA(Sender: TObject; Socket: TCustomWinSocket);
var
  n, RecvLen: Integer;
  data, data2: string;
begin
  RecvLen := Socket.ReceiveBuf((pRecvBuffer + RecvBufLen)^, BUFFERSIZE - RecvBufLen);
  if RecvLen > 0 then
  begin
    Inc(RecvBufLen, RecvLen);
    //copymemory
  end;

  data := Socket.ReceiveText;
  if data <> '' then
  begin
    n := Pos('*', data);
    if n > 0 then
    begin
      data2 := Copy(data, 1, n - 1);
      data := data2 + Copy(data, n + 1, Length(data));
      //CSocket.Socket.SendText('*');
      CSocket.Socket.SendBuf(activebuf, 1);
    end;
    SocStr := SocStr + data;
  end;
end;

procedure ProcessMessagePacket();
begin
  frmMain.TimerPacketTimer(nil);
end;

procedure TfrmMain.SendSocket(sendstr: string);
//const
  //Code                      : Byte = 1;
//var
  //sSendText                 : string;
begin

{$IFDEF CD}
  if g_ConnectionStep = cnsPlay then

  begin
    SendSocketCD(sendstr);
    Exit;
  end;
{$ENDIF}
  if CSocket.Socket.Connected then
  begin
    CSocket.Socket.SendText(Format('#1%s!', [{Code, } sendstr]));
    //Inc(Code);
    //if Code >= 10 then
    //  Code := 1;
  end;
end;

procedure TfrmMain.SendSocketCD(sendstr: string);
var
  cdbuf: array[0..1024 * 100 - 1] of Char;
  sendbuf: array[0..1024 * 100 - 1] of Char;
  len: Integer;
begin
  if CSocket.Socket.Connected then
  begin
{$IFDEF CD}
    len := CDClientGetMaxEncryptedSize(@sendstr[1], Length(sendstr));
    if len > 1024 * 80 then
      Exit;
    CDClientPacketEncrypt(@sendstr[1], Length(sendstr), @cdbuf[0], @len);
{$ENDIF}
    sendbuf[0] := '#';
    sendbuf[1] := '1';
    len := EncodeBuf(Integer(@cdbuf[0]), len, Integer(@sendbuf[2]));
    sendbuf[len + 2] := '!';
    CSocket.Socket.SendBuf(sendbuf, 3 + len);
  end;
end;

procedure TfrmMain.SendClientMessage(msg, Recog, param, tag, series: Integer);
var
  dMsg: TDefaultMessage;
begin
  dMsg := MakeDefaultMsg(msg, Recog, param, tag, series);
  SendSocket(EncodeMessage(dMsg));
end;

procedure TfrmMain.SendQueryLevelRank(nPage, nType: Integer);
begin
  if (nPage = FrmDlg.m_nLastLevelRankPage) and (nType = FrmDlg.m_nLastLevelRankType) then
    Exit;
  if GetTickCount - FrmDlg.m_dwSendMessageTick > 300 then
  begin
    FrmDlg.m_dwSendMessageTick := GetTickCount;
    g_boDrawLevelRank := False;
    FrmDlg.m_nLastLevelRankPage := nPage;
    FrmDlg.m_nLastLevelRankType := nType;
    FillChar(g_HumanLevelRanks, SizeOf(THumanLevelRanks), #0);
    FillChar(g_HeroLevelRanks, SizeOf(THeroLevelRanks), #0);
    SendClientMessage(CM_LEVELRANK, nPage, nType, 0, 0);
  end;
end;

procedure TfrmMain.SendShoping(sItemName: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_BUYSHOPITEM, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(sItemName));
end;

procedure TfrmMain.SendPresend(sPlayer, sItemName: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_SHOPPRESEND, g_MySelf.m_nRecogId, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(sPlayer + '/' + sItemName));
end;

procedure TfrmMain.SendNewAccount(ue: TUserEntry; ua: TUserEntryAdd);
var
  ss: string;
  iLen: Integer;
  msg: TDefaultMessage;
begin
  MakeNewId := ue.sAccount;
{$I '..\Common\Macros\VMPB.inc'}
  msg := MakeDefaultMsg(CM_ADDNEWUSER, 0, 0, 0, 0);
  {if @FEncodeFunc <> nil then begin
    Move(msg, FTempBuffer[0], 12);
    Move(ue, FTempBuffer[12], SizeOf(TUserEntry));
    Move(ua, FTempBuffer[12 + SizeOf(TUserEntry)], SizeOf(TUserEntryAdd));
    FEncodeFunc(PByte(@FTempBuffer), SizeOf(TUserEntry) + SizeOf(TUserEntryAdd) + 12);
    iLen := EncodeBuf(Integer(@FTempBuffer), SizeOf(TUserEntry) + SizeOf(TUserEntryAdd) + 12, Integer(@FSendBuffer));
    SetLength(ss, iLen);
    Move(FSendBuffer[0], ss[1], iLen);
    SendSocket(ss);
  end
  else
    ;}

  Move(msg, FTempBuffer[0], 12);
  Move(ue, FTempBuffer[12], SizeOf(TUserEntry));
  Move(ua, FTempBuffer[12 + SizeOf(TUserEntry)], SizeOf(TUserEntryAdd));
  //FEncodeFunc(PByte(@FTempBuffer), SizeOf(TUserEntry) + SizeOf(TUserEntryAdd) + 12);
  iLen := EncodeBuf(Integer(@FTempBuffer), SizeOf(TUserEntry) + SizeOf(TUserEntryAdd) + 12, Integer(@FSendBuffer));
  SetLength(ss, iLen);
  Move(FSendBuffer[0], ss[1], iLen);
  SendSocket(ss);

  //SendSocket(EncodeMessage(msg) + EncodeString(EncodeBuffer(@ue, SizeOf(TUserEntry)) + EncodeBuffer(@ua, SizeOf(TUserEntryAdd))));
  //SendCSocket(EncodeMessage(msg) + EncodeString(EncodeBuffer(@ue, SizeOf(TUserEntry)) + EncodeBuffer(@ua, SizeOf(TUserEntryAdd))));
  //SendCSocket(EncodeMessage(msg) + EnCodeString(__En__(EncodeBuffer(@ue, SizeOf(TUserEntry)) + EncodeBuffer(@ua, SizeOf(TUserEntryAdd)), g_sLoginKey^)));
{$I '..\Common\Macros\VMPE.inc'}
end;

procedure TfrmMain.SendBuildAcus(cr: TClientBuildAcus);
var
  DefMsg: TDefaultMessage;
begin
  DefMsg := MakeDefaultMsg(CM_BUILDACUS, 0, 0, 0, 0);
  SendSocket(EncodeMessage(DefMsg) + EncodeBuffer(@cr, SizeOf(TClientBuildAcus)));
end;

(*procedure TfrmMain.SendUpdateAccount(ue: TUserEntry; ua: TUserEntryAdd);
var
  ss                        : string;
  iLen                      : Integer;
  msg                       : TDefaultMessage;
begin
  MakeNewId := ue.sAccount;
  msg := MakeDefaultMsg(CM_UPDATEUSER, 0, 0, 0, 0);
{$I '..\Common\Macros\VMPB.inc'}
  if @FEncodeFunc <> nil then begin
    Move(msg, FTempBuffer[0], 12);
    Move(ue, FTempBuffer[12], SizeOf(TUserEntry));
    Move(ua, FTempBuffer[12 + SizeOf(TUserEntry)], SizeOf(TUserEntryAdd));
    FEncodeFunc(PByte(@FTempBuffer), SizeOf(TUserEntry) + SizeOf(TUserEntryAdd) + 12);
    iLen := EncodeBuf(Integer(@FTempBuffer), SizeOf(TUserEntry) + SizeOf(TUserEntryAdd) + 12, Integer(@FSendBuffer));
    SetLength(ss, iLen);
    Move(FSendBuffer[0], ss[1], iLen);
    SendSocket(ss);
  end else
    ;                                   //SendSocket(EncodeMessage(Msg) + EncodeBuffer(@ue, SizeOf(TUserEntry)) + EncodeBuffer(@ua, SizeOf(TUserEntryAdd)));
{$I '..\Common\Macros\VMPE.inc'}
end;*)

procedure TfrmMain.SendSelectServer(svname: string);
var
  ss: string;
  iLen: Integer;
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_SELECTSERVER, 0, 0, 0, 0);

{$I '..\Common\Macros\VMPB.inc'}
  {if @FEncodeFunc <> nil then begin
    Move(msg, FTempBuffer[0], 12);
    iLen := Length(svname);
    Move(svname[1], FTempBuffer[12], iLen);
    FEncodeFunc(PByte(@FTempBuffer), iLen + 12);
    iLen := EncodeBuf(Integer(@FTempBuffer), iLen + 12, Integer(@FSendBuffer));
    SetLength(ss, iLen);
    Move(FSendBuffer[0], ss[1], iLen);
    SendSocket(ss);
  end
  else
    ;}

  Move(msg, FTempBuffer[0], 12);
  iLen := Length(svname);
  Move(svname[1], FTempBuffer[12], iLen);
  //FEncodeFunc(PByte(@FTempBuffer), iLen + 12);
  iLen := EncodeBuf(Integer(@FTempBuffer), iLen + 12, Integer(@FSendBuffer));
  SetLength(ss, iLen);
  Move(FSendBuffer[0], ss[1], iLen);
  SendSocket(ss);

  //SendSocket(EncodeMessage(Msg) + EncodeString(svname));
{$I '..\Common\Macros\VMPE.inc'}

end;

procedure TfrmMain.SendChgPw(ID, passwd, newpasswd: string);
var
  S, ss: string;
  iLen: Integer;
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_CHANGEPASSWORD, 0, 0, 0, 0);

{$I '..\Common\Macros\VMPB.inc'}
  {if @FEncodeFunc <> nil then begin
    Move(msg, FTempBuffer[0], 12);
    S := ID + #9 + passwd + #9 + newpasswd;
    iLen := Length(S);
    Move(S[1], FTempBuffer[12], iLen);
    FEncodeFunc(PByte(@FTempBuffer), iLen + 12);
    iLen := EncodeBuf(Integer(@FTempBuffer), iLen + 12, Integer(@FSendBuffer));
    SetLength(ss, iLen);
    Move(FSendBuffer[0], ss[1], iLen);
    SendSocket(ss);
  end
  else
    ;}

  Move(msg, FTempBuffer[0], 12);
  S := ID + #9 + passwd + #9 + newpasswd;
  iLen := Length(S);
  Move(S[1], FTempBuffer[12], iLen);
  //FEncodeFunc(PByte(@FTempBuffer), iLen + 12);
  iLen := EncodeBuf(Integer(@FTempBuffer), iLen + 12, Integer(@FSendBuffer));
  SetLength(ss, iLen);
  Move(FSendBuffer[0], ss[1], iLen);
  SendSocket(ss);

  //SendSocket(EncodeMessage(Msg) + EncodeString(ID + #9 + passwd + #9 + newpasswd));
{$I '..\Common\Macros\VMPE.inc'}

end;

procedure TfrmMain.SendNewChr(uid, uname, shair, sjob, ssex: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_NEWCHR, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(uid + '/' + uname + '/' + shair + '/' + sjob + '/' + ssex));
end;

procedure TfrmMain.SendQueryChr;
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_QUERYCHR, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(LoginID + '/' + IntToStr(Certification)));
end;

procedure TfrmMain.SendDelChr(chrname: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_DELCHR, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(chrname));
end;

procedure TfrmMain.SendSelChr(chrname: string);
var
  msg: TDefaultMessage;
begin
  //chrname := g_PlayScene.EdChrNamet.Text;
  m_sCharName := chrname;
  msg := MakeDefaultMsg(CM_SELCHR, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(LoginID + '/' + chrname));
  g_Logined := True;
  //g_PlayScene.EdAccountt.Visible := FALSE; //2004/05/17
  //g_PlayScene.EdChrNamet.Visible := FALSE; //2004/05/17
end;

function NotifyCallback(NotifyType: Integer; NotifyData: Integer; pCallbackContext: Pointer): Integer; stdcall;
begin
  DebugOutStr(Format('(Notify) Type: %d, Data: %.8x', [NotifyType, DWORD(NotifyData)]));
  Result := 0;
end;

procedure TfrmMain.SendRunLogin;
var
  sSendMsg: string;
  HardwareHeader: THardwareHeader;

  KeyLen: Integer;
  KeyPos: Integer;
  offset: Integer;
  Dest: string;
  SrcPos: Integer;
  SrcAsc: Integer;
  Range: Integer;
  Src, Key: string;
begin
{$I '..\Common\Macros\VMPB.inc'}
  if g_bLoginKey^ then
  begin
    HardwareHeader.dwMagicCode := $13F13F13;
    try
      Src := Trim(uSMBIOS.GetHWID());
      HardwareHeader.xMd5Digest := MD5.MD5String(Src);

      Dest := '';
      Key := VMProtectDecryptStringA('legendsoft');
      KeyLen := Length(Key);
      KeyPos := 0;
      Range := 256;
      Randomize;
      offset := Random(Range);
      Dest := Format('%1.2x', [offset]);
      for SrcPos := 0 to SizeOf(HardwareHeader) - 1 do
      begin
        SrcAsc := (Ord(PChar(@HardwareHeader)[SrcPos]) + offset) mod 255;
        if KeyPos < KeyLen then
          KeyPos := KeyPos + 1
        else
          KeyPos := 1;
        SrcAsc := SrcAsc xor Ord(Key[KeyPos]);
        Dest := Dest + Format('%1.2x', [SrcAsc]);
        offset := SrcAsc;
      end;
    except
    end;
  end;
{$I '..\Common\Macros\VMPE.inc'}

{$I '..\Common\Macros\VMPB.inc'}


{$IFDEF CD}
  CDClientFree;
  CDClientInit;
{$ENDIF}
  if g_bLoginKey^ then
  begin
    sSendMsg := Format(VMProtectDecryptStringA('**%s/%s/%d/%d/%d/%s'),
      [LoginID, m_sCharName, Certification, CLIENT_VERSION_NUMBER, RUNLOGINCODE, Dest]);
    SendSocket(EncodeString(sSendMsg));
  end;
{$I '..\Common\Macros\VMPE.inc'}
end;

procedure TfrmMain.SendSay(Str: string);
var
  sx, sy, param: string;
  X, Y: Integer;
  msg: TDefaultMessage;
const
  sam = '/move';
begin
  if Str <> '' then
  begin
    if m_boPasswordIntputStatus then
    begin
      m_boPasswordIntputStatus := False;
      FrmDlg.DEdChat.PasswordChar := #0;
      FrmDlg.DEdChat.Visible := False;
      if not g_ChatStatusLarge then
        FrmDlg.DBChat.Visible := False;
      SendPassword(Str, 1);
      Exit;
    end;
    if CompareLstr(Str, '/cmd', Length('/cmd')) then
    begin
      ProcessCommand(Str);
      Exit;
    end;

    if CompareLstr(Str, sam, Length(sam)) then
    begin
      param := Copy(Str, Length(sam) + 1, Length(Str) - Length(sam));
      if param <> '' then
      begin
        sy := GetValidStr3(param, sx, [' ', ':', ',', #9]);
        if (sx <> '') and (sy <> '') then
        begin
          X := StrToInt(sx);
          Y := StrToInt(sy);
          if (X > 0) and (Y > 0) then
          begin
            g_MySelf.m_nTagX := X;
            g_MySelf.m_nTagY := Y;
            if not g_PathBusy then
            begin
              g_PathBusy := True;
              try
                Map.LoadMapData();
                g_MapPath := Map.FindPath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_MySelf.m_nTagX, g_MySelf.m_nTagY, 0);
                if g_MapPath <> nil then
                begin
                  g_MoveStep := 1;
                  TimerAutoMove.Enabled := True;
                  DScreen.AddChatBoardString(Format('自动移动至坐标(%d:%d)，点击鼠标任意键停止……', [g_MySelf.m_nTagX, g_MySelf.m_nTagY]), GetRGB(5), clWhite);
                end
                else
                begin
                  TimerAutoMove.Enabled := False;
                  DScreen.AddChatBoardString(Format('自动移动坐标点(%d:%d)不可到达', [g_MySelf.m_nTagX, g_MySelf.m_nTagY]), GetRGB(5), clWhite);
                  g_MySelf.m_nTagX := 0;
                  g_MySelf.m_nTagY := 0;
                end;
              finally
                g_PathBusy := False;
              end;
            end;
          end;
        end;
      end;
      Exit;
    end;
    if Str = '/debug check' then
    begin
      g_boShowMemoLog := not g_boShowMemoLog;
      g_PlayScene.MemoLog.Clear;
      g_PlayScene.MemoLog.Visible := g_boShowMemoLog;
      Exit;
    end;
    {if Str = '/debug powerblock' then begin
      SendPowerBlock();
      Exit;
    end;

    if Str = '/debug screen' then begin
      g_boCheckBadMapMode := not g_boCheckBadMapMode;
      if g_boCheckBadMapMode then DScreen.AddSysMsg('On')
      else DScreen.AddSysMsg('Off');
      Exit;
    end;}
    {if Str = '/check speedhack' then begin
      g_boCheckSpeedHackDisplay := not g_boCheckSpeedHackDisplay;
      Exit;
    end;
    if Str = '/hungry' then begin
      Inc(g_nMyHungryState);
      if g_nMyHungryState > 4 then g_nMyHungryState := 1;
      Exit;
    end;}

    if Str = '@password' then
    begin
      if FrmDlg.DEdChat.PasswordChar = #0 then
        FrmDlg.DEdChat.PasswordChar := '*'
      else
        FrmDlg.DEdChat.PasswordChar := #0;
      Exit;
    end;
    if FrmDlg.DEdChat.PasswordChar = '*' then
      FrmDlg.DEdChat.PasswordChar := #0;

    msg := MakeDefaultMsg(CM_SAY, 0, 0, 0, 0);
    SendSocket(EncodeMessage(msg) + EncodeString(Str));

    if Str[1] = '/' then
    begin
      DScreen.AddChatBoardString(Str, GetRGB(180), clWhite);
      GetValidStr3(Copy(Str, 2, Length(Str) - 1), WhisperName, [' ']);
    end;
  end;
end;

procedure TfrmMain.SendActMsg(ident, X, Y, dir: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(ident, Makelong(X, Y), 0, dir, 0);
  SendSocket(EncodeMessage(msg));

  ActionLock := True; //0320
  ActionLockTime := GetTickCount;
  //Inc(g_nSendCount);
end;

procedure TfrmMain.SendSpellMsg(ident, X, Y, dir, target: Integer; bLock: Boolean);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(ident, Makelong(X, Y), LoWord(target), dir, HiWord(target));
  SendSocket(EncodeMessage(msg));

  if not bLock then
    Exit;
  ActionLock := True; //0320
  ActionLockTime := GetTickCount;
  //Inc(g_nSendCount);
end;

procedure TfrmMain.SendQueryUserName(targetid, X, Y: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_QUERYUSERNAME, targetid, X, Y, 0);
  SendSocket(EncodeMessage(msg));
end;
{
procedure TfrmMain.SendItemSumCoundt(OrgItemIndex, ExItemIndex, hero: Integer; StrOrgItem, StrExItem: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_ITEMSUMCOUNT, OrgItemIndex, LoWord(ExItemIndex), HiWord(ExItemIndex), hero);
  SendSocket(EncodeMessage(msg) + EncodeString(StrOrgItem + '/' + StrExItem));
end;
}
procedure TfrmMain.SendItemSumCount(OrgItemIndex, ExItemIndex, hero: Integer;
  StrOrgItem, StrExItem: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_ITEMSUMCOUNT, OrgItemIndex, LoWord(ExItemIndex), HiWord(ExItemIndex), hero);
  SendSocket(EncodeMessage(msg) + EncodeString(StrOrgItem + '/' + StrExItem));
end;


procedure TfrmMain.SendLoadModOk;
var
  msg: TDefaultMessage;
begin
//  sz := 'asdf';
{$IFDEF TEST}
 // OutputDebugString('SendLoadModOk');
{$ENDIF}

  msg := MakeDefaultMsg(CM_LOADMOD_OK, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + '');
end;

procedure TfrmMain.SendDropItem(Name: string; itemserverindex, dropcnt: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_DROPITEM, itemserverindex, dropcnt, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(Name));
end;

procedure TfrmMain.SendHeroDropItem(Name: string; itemserverindex, dropcnt: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_HERODROPITEM, itemserverindex, dropcnt, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(Name));
end;

procedure TfrmMain.SendDismantleItem(Name: string; itemserverindex, dropcnt, hero: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_DISMANTLEITEM, itemserverindex, dropcnt, hero, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(Name));
end;

procedure TfrmMain.SendPickup;
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_PICKUP, 0, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendHeroSetTarget;
var
  msg: TDefaultMessage;
begin
  if (g_MySelf.m_HeroObject <> nil) and (g_FocusCret <> nil) then
  begin
    msg := MakeDefaultMsg(CM_HEROSETTARGET, g_FocusCret.m_nRecogId, g_FocusCret.m_nCurrX, g_FocusCret.m_nCurrY, 0);
    SendSocket(EncodeMessage(msg));
  end;
end;

procedure TfrmMain.SendHeroSetGuard;
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_HEROSETTARGET, 0, g_nMouseCurrX, g_nMouseCurrY, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendHeroJoinAttack();
var
  msg: TDefaultMessage;
begin
  if g_SeriesSkillFire then
    Exit;
  msg := MakeDefaultMsg(CM_HERORJOINTATTACK, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendOpenBox(OpenBoxItem: TOpenBoxItem);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_OPENBOX, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeBuffer(@OpenBoxItem, SizeOf(TOpenBoxItem)));
end;

procedure TfrmMain.SendSetSeriesSkill(Index, magid, hero: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_SETSERIESSKILL, Index, magid, 0, hero);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendTakeOnItem(where: BYTE; itmindex: Integer; itmname: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_TAKEONITEM, itmindex, where, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(itmname));
end;

procedure TfrmMain.HeroSendTakeOnItem(where: BYTE; itmindex: Integer; itmname: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_HEROTAKEONITEM, itmindex, where, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(itmname));
end;

procedure TfrmMain.SendTakeOffItem(where: BYTE; itmindex: Integer; itmname: string);
var
  msg: TDefaultMessage;
begin
{$IFDEF WEAPON_DROP}
  if where in [0..U_FASHION] then
    g_pweapon := nil;
{$ENDIF }
  msg := MakeDefaultMsg(CM_TAKEOFFITEM, itmindex, where, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(itmname));
end;

procedure TfrmMain.HeroSendTakeOffItem(where: BYTE; itmindex: Integer; itmname: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_HEROTAKEOFFITEM, itmindex, where, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(itmname));
end;

procedure TfrmMain.SendEat(itmindex: Integer; itmname: string; nUnBindItem: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_EAT, itmindex, 0, 0, nUnBindItem);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendHeroEat(itmindex: Integer; itmname: string; nType: Integer; nUnBindItem: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_HEROEAT, itmindex, nType, 0, nUnBindItem);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendButchAnimal(X, Y, dir, actorid: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_BUTCH, actorid, X, Y, dir);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendMagicKeyChange(magid: Integer; keych: Char);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_MAGICKEYCHANGE, magid, BYTE(keych), 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendHeroMagicKeyChange(magid: Integer; keych: Char);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_HEROMAGICKEYCHANGE, magid, BYTE(keych), 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendMerchantDlgSelect(merchant: Integer; rstr: string);
const
  sam = '@_automove ';
var
  X, Y: Integer;
  msg: TDefaultMessage;
  param, sx, sy, sM: string;
begin
  FrmDlg.CancelItemMoving;
  if Length(rstr) >= 2 then
  begin
    if CompareLstr(rstr, sam, Length(sam)) then
    begin
      param := Copy(rstr, Length(sam) + 1, Length(rstr) - Length(sam));
      if param <> '' then
      begin
        param := GetValidStr3(param, sx, [' ', ':', ',', #9]);
        sM := GetValidStr3(param, sy, [' ', ':', ',', #9]);
        if (sx <> '') and (sy <> '') then
        begin
          if (sM <> '') and (CompareText(g_sMapTitle, sM) <> 0) then
          begin
            //自动移动
            DScreen.AddChatBoardString(Format('到达 %s 之后才能使用自动走路', [sM]), clBlue, clWhite);
            Exit;
          end;
          X := StrToInt(sx);
          Y := StrToInt(sy);
          AutoMove(X, Y);
        end;
      end;
      Exit;
    end;
    if (rstr[1] = '@') and (rstr[2] = '@') then
    begin
      if CompareText(rstr, '@@buildguildnow') = 0 then
        FrmDlg.DMessageDlg('请输入行会名称：', [mbOk, mbAbort])
      else if CompareText(rstr, '@@ybbuylf') = 0 then
        FrmDlg.DMessageDlg('请输入要兑换的灵符数量(1~1000)：', [mbOk, mbAbort])
      else if CompareText(rstr, '@@givezhh') = 0 then
        FrmDlg.DMessageDlg('请输入你想赠给的角色名字以及数量，中间用空格分隔：', [mbOk, mbAbort])
      else if CompareText(rstr, '@@kachu_M2') = 0 then
        FrmDlg.DMessageDlg('请输入你要开除的徒弟的角色名（若含有英文字符请区分大小写）：', [mbOk, mbAbort])
      else if CompareText(rstr, '@@sdmarry') = 0 then
        FrmDlg.DMessageDlg('请输入你求婚对象的角色名（若含有英文字符请区分大小写）：', [mbOk, mbAbort])
      else if CompareText(rstr, '@@dealybme') = 0 then
        FrmDlg.QueryYbSell()
      else if CompareText(rstr, '@@BuHero') = 0 then
        FrmDlg.DMessageDlg('请输入英雄的名字：', [mbOk, mbAbort])
      else if CompareText(rstr, '@@BuHeroEx') = 0 then
        FrmDlg.DMessageDlg('请输入英雄的名字：', [mbOk, mbAbort])
      else if CompareText(rstr, '@@BuHeroEx') = 0 then
        FrmDlg.DMessageDlg('请输入英雄的名字：', [mbOk, mbAbort])
      else if CompareText(rstr, '@@TreasureIdentify') = 0 then
      begin
        FrmDlg.OpenDBTI();
      end
      else if CompareText(rstr, '@@ExchangeBook') = 0 then
      begin
        FrmDlg.ShowMDlg(0, '', '请把你要换成卷轴碎片的装备放在下面的物品栏中，我会帮你计算\你可以换取多少个卷轴碎片。\ \<返回/@back>\<关闭/@exit>');
        frmMain.ClientGetSendUserExchgBook(g_nCurMerchant);
      end
      else if CompareText(rstr, '@@SecretProperty') = 0 then
      begin
        FrmDlg.OpenDBSP();
      end
      else
        FrmDlg.DMessageDlg('请输入信息：', [mbOk, mbAbort]);
      param := Trim(FrmDlg.DlgEditText);
      rstr := rstr + #13 + param;
    end;
    if (rstr[1] = '@') then
    begin
      if CompareText(rstr, '@closewin') = 0 then
      begin
        FrmDlg.CloseMDlg;
      end
      else if CompareText(rstr, '@buildacus') = 0 then
      begin
        FrmDlg.OpenBuildAcusWin();
      end;
    end;
  end;
  msg := MakeDefaultMsg(CM_MERCHANTDLGSELECT, merchant, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(rstr));
  //DScreen.AddChatBoardString(EncodeMessage(msg) + EncodeString(rstr), GetRGB(5), clWhite);
end;

procedure TfrmMain.SendQueryPrice(merchant, itemindex: Integer; itemname: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_MERCHANTQUERYSELLPRICE, merchant, LoWord(itemindex), HiWord(itemindex), 0);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendQueryExchgBook(merchant, itemindex: Integer; itemname: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_MERCHANTQUERYEXCHGBOOK, merchant, LoWord(itemindex), HiWord(itemindex), 0);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendQueryRepairCost(merchant, itemindex: Integer; itemname: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_MERCHANTQUERYREPAIRCOST, merchant, LoWord(itemindex), HiWord(itemindex), 0);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendSellItem(merchant, itemindex: Integer; itemname: string; count: Word);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_USERSELLITEM, merchant, LoWord(itemindex), HiWord(itemindex), count);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendSellItemList(merchant: Integer; ItemList: String);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_SENDSELLITEMLIST, merchant, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(ItemList));
end;

procedure TfrmMain.SendExchgBook(merchant, itemindex: Integer; itemname: string; count: Word);
var
  msg: TDefaultMessage;
begin
  //DScreen.AddChatBoardString(Format('%d:%d', [merchant, itemindex]), GetRGB(5), clWhite);
  msg := MakeDefaultMsg(CM_ExchangeBook, merchant, LoWord(itemindex), HiWord(itemindex), count);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendRepairItem(merchant, itemindex: Integer; itemname: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_USERREPAIRITEM, merchant, LoWord(itemindex), HiWord(itemindex), 0);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendStorageItem(merchant, itemindex: Integer; itemname: string; count: Word);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_USERSTORAGEITEM, merchant, LoWord(itemindex), HiWord(itemindex), count);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendStorageItemView(merchant, itemindex: Integer; itemname: string; count: Word);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_USERSTORAGEITEMVIEW, merchant, LoWord(itemindex), HiWord(itemindex), count);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;


procedure TfrmMain.SendBindItem(merchant, itemindex: Integer; itemname: string; idx: Word);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_QUERYBINDITEM, merchant, LoWord(itemindex), HiWord(itemindex), idx);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendSelectItem(merchant, itemindex: Integer; itemname: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_ITEMDLGSELECT, merchant, LoWord(itemindex), HiWord(itemindex), 0);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendMaketSellItem(merchant, itemindex: Integer; price: string; count: Word);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_MARKET_SELL, merchant, LoWord(itemindex), HiWord(itemindex), count);
  SendSocket(EncodeMessage(msg) + EncodeString(price));
end;

procedure TfrmMain.SendGetDetailItem(merchant, menuindex: Integer; itemname: string; model: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_USERGETDETAILITEM, merchant, menuindex, 0, model);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendGetMarketPageList(merchant, pagetype: Integer; itemname: string);
var // Market System..
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_MARKET_LIST, merchant, pagetype, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendBuyMarket(merchant, sellindex: Integer);
var // Market System..
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_MARKET_BUY, merchant, LoWord(sellindex), HiWord(sellindex), 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendCancelMarket(merchant, sellindex: Integer);
var // Market System..
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_MARKET_CANCEL, merchant, LoWord(sellindex), HiWord(sellindex), 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendCaptchaRes(res: string);
var msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_CAPTCHAR, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(res));

end;

procedure TfrmMain.SendGetPayMarket(merchant, sellindex: Integer);
var // Market System..
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_MARKET_GETPAY, merchant, LoWord(sellindex), HiWord(sellindex), 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendMarketClose;
var // Market System..
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_MARKET_CLOSE, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendBuyItem(merchant, Itemserverindex: Integer; ItemName: string; conut: Word);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_USERBUYITEM, merchant, LoWord(Itemserverindex), HiWord(Itemserverindex), conut);
  SendSocket(EncodeMessage(msg) + EncodeString(ItemName));
end;

procedure TfrmMain.SendTakeBackStorageItem(merchant, itemserverindex: Integer; itemname: string; count: Word);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_USERTAKEBACKSTORAGEITEM, merchant, LoWord(itemserverindex), HiWord(itemserverindex), count);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendTakeBackStorageItemView(merchant, itemserverindex: Integer; itemname: string; count: Word); //2019-12-21
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_USERTAKEBACKSTORAGEITEMVIEW, merchant, LoWord(itemserverindex), HiWord(itemserverindex), count);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;


procedure TfrmMain.SendMakeDrugItem(merchant: Integer; itemname: string);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_USERMAKEDRUGITEM, merchant, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(itemname));
end;

procedure TfrmMain.SendDropGold(dropgold: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_DROPGOLD, dropgold, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendGroupMode(onoff: Boolean);
var
  msg: TDefaultMessage;
begin
  if onoff then
    msg := MakeDefaultMsg(CM_GROUPMODE, 0, 1, 0, 0) //on
  else
    msg := MakeDefaultMsg(CM_GROUPMODE, 0, 0, 0, 0); //off
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendCreateGroup(withwho: string);
var
  msg: TDefaultMessage;
begin
  if withwho <> '' then
  begin
    msg := MakeDefaultMsg(CM_CREATEGROUP, 0, 0, 0, 0);
    SendSocket(EncodeMessage(msg) + EncodeString(withwho));
  end;
end;

procedure TfrmMain.SendWantMiniMap;
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_WANTMINIMAP, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendGuildDlg;
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_OPENGUILDDLG, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendDealTry;
var
  msg: TDefaultMessage;
  who: string;
begin
  msg := MakeDefaultMsg(CM_DEALTRY, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(who));
end;

procedure TfrmMain.SendCancelDeal;
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_DEALCANCEL, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendAddDealItem(ci: TClientItem);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_DEALADDITEM, ci.MakeIndex, 0, 0, ci.Dura);
  SendSocket(EncodeMessage(msg) + EncodeString(ci.S.Name));
end;

procedure TfrmMain.SendDelDealItem(ci: TClientItem);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_DEALDELITEM, ci.MakeIndex, 0, 0, ci.Dura);
  SendSocket(EncodeMessage(msg) + EncodeString(ci.S.Name));
end;

procedure TfrmMain.SendChangeDealGold(gold: Integer);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_DEALCHGGOLD, gold, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendDealEnd;
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_DEALEND, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendAddGroupMember(withwho: string);
var
  msg: TDefaultMessage;
begin
  if withwho <> '' then
  begin
    msg := MakeDefaultMsg(CM_ADDGROUPMEMBER, 0, 0, 0, 0);
    SendSocket(EncodeMessage(msg) + EncodeString(withwho));
  end;
end;

procedure TfrmMain.SendDelGroupMember(withwho: string);
var
  msg: TDefaultMessage;
begin
  if withwho <> '' then
  begin
    msg := MakeDefaultMsg(CM_DELGROUPMEMBER, 0, 0, 0, 0);
    SendSocket(EncodeMessage(msg) + EncodeString(withwho));
  end;
end;

procedure TfrmMain.SendGuildHome;
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_GUILDHOME, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendGuildMemberList;
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_GUILDMEMBERLIST, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendGuildAddMem(who: string);
var
  msg: TDefaultMessage;
begin
  if Trim(who) <> '' then
  begin
    msg := MakeDefaultMsg(CM_GUILDADDMEMBER, 0, 0, 0, 0);
    SendSocket(EncodeMessage(msg) + EncodeString(who));
  end;
end;

procedure TfrmMain.SendGuildDelMem(who: string);
var
  msg: TDefaultMessage;
begin
  if Trim(who) <> '' then
  begin
    msg := MakeDefaultMsg(CM_GUILDDELMEMBER, 0, 0, 0, 0);
    SendSocket(EncodeMessage(msg) + EncodeString(who));
  end;
end;

procedure TfrmMain.SendGuildUpdateNotice(notices: string);
var
  msg: TDefaultMessage;
begin
  //zip
  msg := MakeDefaultMsg(CM_GUILDUPDATENOTICE, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(notices));
end;

procedure TfrmMain.SendGuildUpdateGrade(rankinfo: string);
var
  msg: TDefaultMessage;
begin
  //zip
  msg := MakeDefaultMsg(CM_GUILDUPDATERANKINFO, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeString(rankinfo));
end;

procedure TfrmMain.SendSpeedHackUser;
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_SPEEDHACKUSER, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg));
end;

procedure TfrmMain.SendAdjustBonus(remain: Integer; babil: TNakedAbility);
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_ADJUST_BONUS, remain, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeBuffer(@babil, SizeOf(TNakedAbility)));
end;
{
procedure TfrmMain.SendPowerBlock();
var
  msg: TDefaultMessage;
begin
  msg := MakeDefaultMsg(CM_POWERBLOCK, 0, 0, 0, 0);
  SendSocket(EncodeMessage(msg) + EncodeBuffer(@g_PowerBlock, SizeOf(TPowerBlock)));
end;
}
procedure TfrmMain.SendFireSerieSkill();
var
  msg: TDefaultMessage;
begin
  if (g_MySelf = nil) then Exit;

  if g_SeriesSkillFire then Exit;

  if g_MySelf.m_boUseCboLib then  Exit;
  
  if g_MySelf.m_nIPower < 5 then
  begin
    if GetTickCount - g_IPointLessHintTick > 10000 then
    begin
      g_IPointLessHintTick := GetTickCount;
      DScreen.AddSysMsg('内力值不足...');
    end;
    Exit;
  end;
  if (g_MySelf.m_nState and $04000000 = 0) and (g_MySelf.m_nState and $02000000 = 0) then
  begin
    if GetTickCount - g_SendFireSerieSkillTick > 1000 then
    begin
      g_SendFireSerieSkillTick := GetTickCount;
      msg := MakeDefaultMsg(CM_FIRESERIESSKILL, g_MySelf.m_nRecogId, 0, 0, 0);
      SendSocket(EncodeMessage(msg));
    end;
  end;
end;

function TfrmMain.ServerAcceptNextAction: Boolean;
begin
  if (g_MySelf <> nil) and g_MySelf.m_StallMgr.OnSale then
  begin
    Result := False;
    Exit;
  end;
  Result := True;
  if ActionLock then
  begin
    if GetTickCount - ActionLockTime > 5 * 1000 then
    begin
      ActionLock := False;
      //Dec (WarningLevel);
    end;
    Result := False;
  end;
end;

function TfrmMain.CanNextAction: Boolean;
begin
  if (g_MySelf <> nil) and g_MySelf.m_StallMgr.OnSale then
  begin
    Result := False;
    Exit;
  end;
  if not g_MySelf.m_boUseCboLib and
    (g_MySelf.IsIdle) and
    (g_MySelf.m_nState and $04000000 = 0) and
    (g_MySelf.m_nState and $02000000 = 0) and
    (GetTickCount - g_dwDizzyDelayStart > g_dwDizzyDelayTime) then
  begin
    Result := True;
  end
  else
    Result := False;
end;
//是否可以攻击，控制攻击速度

function TfrmMain.CanNextHit(settime: Boolean): Boolean;
var
  NextHitTime, LevelFastTime: Integer;
begin
  if (g_MySelf <> nil) and g_MySelf.m_StallMgr.OnSale then
  begin
    Result := False;
    Exit;
  end;
  LevelFastTime := _MIN(370, (g_MySelf.m_Abil.level * 14)); //0905
  LevelFastTime := _MIN(800, LevelFastTime + g_MySelf.m_nHitSpeed * g_nItemSpeed {60});

  if g_boSpeedRate then
  begin
    if g_MySelf.m_boAttackSlow then
      NextHitTime := g_nHitTime {1400} - LevelFastTime + 1500 - g_HitSpeedRate * 20 //腕力超过时，减慢攻击速度
    else
      NextHitTime := g_nHitTime {1400} - LevelFastTime - g_HitSpeedRate * 20;
  end
  else
  begin
    if g_MySelf.m_boAttackSlow then
      NextHitTime := g_nHitTime {1400} - LevelFastTime + 1500
    else
      NextHitTime := g_nHitTime {1400} - LevelFastTime;
  end;

  if NextHitTime < 0 then
    NextHitTime := 0;

  if GetTickCount - LastHitTick > LongWord(NextHitTime) then
  begin
    if settime then
      LastHitTick := GetTickCount;
    Result := True;
  end
  else
    Result := False;
end;

procedure TfrmMain.ActionFailed;
begin
  g_nTargetX := -1;
  g_nTargetY := -1;
  g_MySelf.m_boUseCboLib := False;
  ActionFailLock := True;
  ActionFailLockTime := GetTickCount();
  g_MySelf.MoveFail;
end;

function TfrmMain.IsUnLockAction({Action, adir: Integer}): Boolean;
begin
  if ActionFailLock then //如果操作被锁定，则在指定时间后解锁
    if Integer(GetTickCount - ActionFailLockTime) >= 1000 then //blue 1000
      ActionFailLock := False;
  if (ActionFailLock) or (g_boMapMoving) or (g_boServerChanging) then
    Result := False
  else
    Result := True;
end;

function TfrmMain.IsGroupMember(uname: string): Boolean;
begin
  Result := g_GroupMembers.IndexOf(uname) >= 0;
end;

procedure TfrmMain.CheckSpeedHack(rtime: LongWord);
begin
  Exit;
  {if g_dwFirstServerTime > 0 then begin
    if (GetTickCount - g_dwFirstClientTime) > 1 * 60 * 60 * 1000 then begin
      g_dwFirstServerTime := rtime;
      g_dwFirstClientTime := GetTickCount;
    end;
    cltime := GetTickCount - g_dwFirstClientTime;
    svtime := rtime - g_dwFirstServerTime + 3000;
    if cltime > svtime then begin
      Inc(g_nTimeFakeDetectCount);
      if g_nTimeFakeDetectCount > 6 then begin
        Str := 'Bad';
        FrmDlg.DMessageDlg('系统不稳定或网络状态极差，游戏被中止\' + '如有问题请联系游戏管理员', [mbOk]);
        frmMain.Close;
      end;
    end else begin
      Str := 'Good';
      g_nTimeFakeDetectCount := 0;
    end;
    if g_boCheckSpeedHackDisplay then
      DScreen.AddSysMsg(IntToStr(svtime) + ' - ' + IntToStr(cltime) + ' = ' + IntToStr(svtime - cltime) + ' ' + Str);
  end else begin
    g_dwFirstServerTime := rtime;
    g_dwFirstClientTime := GetTickCount;
  end;}
end;

procedure TfrmMain.RecalcAutoMovePath();
begin
  if (g_MySelf.m_nTagX > 0) and (g_MySelf.m_nTagY > 0) then
  begin
    if not g_PathBusy then
    begin
      g_PathBusy := True;
      try
        Map.ReLoadMapData();
        g_MapPath := Map.FindPath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_MySelf.m_nTagX, g_MySelf.m_nTagY, 0);
        //g_MapPath := Map.FindPath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY);
        if g_MapPath <> nil then
        begin
          g_MoveStep := 1;
          TimerAutoMove.Enabled := True;
        end
        else
        begin
          g_MySelf.m_nTagX := 0;
          g_MySelf.m_nTagY := 0;
          TimerAutoMove.Enabled := False;
          DScreen.AddChatBoardString(Format('自动移动目标(%d:%d)被占据，不可到达', [g_MySelf.m_nTagX, g_MySelf.m_nTagY]), GetRGB(5), clWhite);
        end;
      finally
        g_PathBusy := False;
      end;
    end;
  end;
end;

procedure TfrmMain.DecodeMessagePacket(datablock: string; btPacket: Integer);

  function ExtractUserName(line: string): string;
  var
    uname: string;
  begin
    GetValidStr3(line, line, ['(', '!', '*', '/', ')']);
    GetValidStr3(line, uname, [' ', '=', ':']);
    if uname <> '' then
      if (uname[1] = '/') or (uname[1] = '(') or (uname[1] = ' ') or (uname[1] = '[') then
        uname := '';
    Result := uname;
  end;

var
  head, body, body2, tagstr, data, rdstr, Str, Str2, str3: string;
  msg, msg2, DefMsg: TDefaultMessage;
  sMsg: TShortMessage;
  mbw: TMessageBodyW;
  desc,desc2: TCharDesc;
  wl: TMessageBodyWL;
  featureEx: Word;
  L, i, j, n, BLKSize, param, Sound, cltime, svtime: Integer;
  tempb: Boolean;
  Actor, Actor2: TActor;
  event: TClEvent;
  edBuf: PChar;
  nad, nFuncPos: Integer;
  ptrGetFunc: LPGETDYNCODE;
  meff: TMagicEff;
  ipExp: LongWord;
  List: TGList;
  pMission: PTClientMission;
  MsgResult: Integer;
  pc: PTClientItem;
  StallInfo: TStallInfo;
  PItem: PTClientItem;
  //uBlock                    : TClientStallInfo;

  rtime: LongWord;
  svrcfg: TServerConfig;

  Port: Word;
  url: string;

  nsmuggle: Integer;
  szsumggle: string;
  nOrgLen: Integer;
  sorg: string;
  Len: Integer;
  pszTmp: array[0..1024 * 100 - 1] of Char;
  pszCd: array[0..1024 * 100 - 1] of Char;
//  packet: PJX_PACKET;
//  sendmsg: TDefaultMessage;
  szcheck: string;
  res: Cardinal;
  resmsg: TDefaultMessage;
  log: string;
  szcap: string;
  nleftsec: Integer;
  sztmp: string;
  bSucess: Boolean;
  cdlen: Integer;
  ptc: PTClientItem;
  FeatureMsg: string;
label
  lab1;
begin

  if (btPacket = 0) and (datablock[1] = '+') then
  begin
    ProcessActMsg(datablock);
    Exit;
  end;
{$IFDEF CD}
  if g_ConnectionStep = cnsPlay then
  begin
    len := DeCodeBuf(Integer(@datablock[1]), Length(datablock), Integer(@pszTmp[0]));
    cdlen := CDClientGetMaxDecryptedSize(@pszTmp[0], len);
    if cdlen > 1024 * 80 then
      exit;
    CDClientPacketDecrypt(@pszTmp[0], len, @pszCd[0], @cdlen);
    SetLength(datablock, cdlen);
    CopyMemory(PChar(@datablock[1]), Pchar(@pszCd[0]), cdlen);
  end;

{$ENDIF}
  if Length(datablock) < DEFBLOCKSIZE then
  begin
    exit;
  end;
  body := '';
  if Length(datablock) > DEFBLOCKSIZE then
    body := Copy(datablock, DEFBLOCKSIZE + 1, Length(datablock) - DEFBLOCKSIZE);

  if btPacket = 0 then
  begin
    head := Copy(datablock, 1, DEFBLOCKSIZE);
    msg := DecodeMessage(head);
  end
  else
  begin
    body := body2;
  end;
{$IFDEF TEST}
  //log := Format('client %d,%d', [msg.Ident, Length(datablock)]);
 // OutputDebugString(pchar(log));
{$ENDIF}
{$IFNDEF CD}
  if (g_ConnectionStep = cnsPlay) and (SM_SMUGGLE = msg.ident) then // 有夹带数据
  begin
    nsmuggle := msg.X;
    nOrgLen := msg.Y;

//    log := Format('smudata %d,%d', [nsmuggle, nOrgLen]);
//    OutputDebugString(pchar(log));
    if (nsmuggle + nOrgLen) <> Length(body) then
    begin
//      OutputDebugString('exit1');
      Exit;
    end;

    if nsmuggle > Length(body) then // 数据错误 防止拷贝错误
    begin
//      OutputDebugString('exit2');
      Exit;
    end;
    len := DeCodeBuf(Integer(@body[1]), nsmuggle, Integer(@pszTmp[0]));

    bSucess := ProcessSmuggleData(pszTmp, len);
    if not bSucess then
    begin
//      OutputDebugString(Pchar(datablock));
    end;

    len := DeCodeBuf(Integer(@body[nsmuggle + 1]), nOrgLen, Integer(@pszTmp[0]));

    if len < DEFBLOCKSIZE then // 数据错误
    begin
//      OutputDebugString('exit3');
      Exit;
    end;
    DeCodeBuf(Integer(@pszTmp[0]), DEFBLOCKSIZE, Integer(@msg));
    body := StrPas(@pszTmp[DEFBLOCKSIZE]);
  end;
{$ENDIF}

  if msg.ident = SM_CHECKCLIENT then
  begin
    if (m_vtable <> nil) then
    begin
      szcheck := DecodeString(body);
{$IFDEF TEST}
 //     OutputDebugString(pchar(body));
 //     OutputDebugString(pchar(szcheck));
{$ENDIF}
      if szcheck <> '' then
      begin
        res := m_vtable.m_GetStringSign(@szcheck[1], Length(szcheck));
        resmsg := MakeDefaultMsg(CM_CHECKCLIENT_RES, 0, HiWord(res), LoWord(res), 0);
        SendSocket(EncodeMessage(resmsg));
        Timer2.Enabled := True;
      end;
    end;
    Exit;
  end
  else if msg.ident = SM_CAPTCHAR then
  begin
    len := DeCodeBuf(Integer(@body[1]), Length(body), Integer(@pszTmp[0]));
//    log := Format('captcha %d,%d', [Length(body), len]);
//    OutputDebugString(pchar(log));
    frmCaptcha.ShowCaptcha(@pszTmp[0], len, msg.Series);
    Exit;
  end
  else if msg.ident = SM_CAPTCHAR_RES then
  begin
    frmCaptcha.OnCaptchaRes(msg.Tag, msg.Series);
    Exit;
  end
  else if msg.ident = SM_CAP_NOTICE then
  begin
    nleftsec := msg.Series;
    if (nleftsec < 100) and (nleftsec > 0) then
    begin
      sztmp := Format('防挂机提示:将在%d秒后进程验证，请注意自己当前的位置！', [nleftsec]);
      DScreen.AddChatBoardString(sztmp, clWhite, clBlue);
    end;
  end
  else if msg.ident = SM_DYNCODE_NORES then
  begin

  end;

  if g_MySelf = nil then
  begin
    case msg.ident of
      SM_QUERYDYNCODE:
        begin
{$I '..\Common\Macros\VMPB.inc'}
          g_bLoginKey^ := False;
          Str := Copy(body, 1, msg.series);
          Str := DecodeString(Str);
          DCP_mars.InitStr(IntToStr(msg.param));
          Str := DCP_mars.DecryptString(Str);
{$IFDEF DEBUG_LOGIN}
          DCP_mars.InitStr('');
          Str := DCP_mars.DecryptString(Str);

          //DCP_mars.InitStr(VMProtectDecryptStringA('sWebSite'));
          //Str2 := DCP_mars.DecryptString(g_pRcHeader.sWebSite);

          if CompareText(Str, VMProtectDecryptStringA('http://blue.hn52pk.com')) = 0 then
          begin
            g_bLoginKey^ := True;
            g_pkeywords := NewStr('');
            g_pkeywords^ := IntToHex(msg.tag, 8);

            rdstr := Copy(body, msg.series + 1, Length(body) - msg.series);
            edBuf := FEndeBuffer;
            FillChar(edBuf^, 16 * 1024, #0);
            DecodeBuf(Integer(@rdstr[1]), Length(rdstr), Integer(edBuf));
            nFuncPos := Integer(@FEndeBuffer);

            {asm pushad end;
            ptrGetFunc := LPGETDYNCODE(nFuncPos);
            asm popad end;
            asm pushad end;
            FEncodeFunc := ptrGetFunc(1);
            asm popad end;
            asm pushad end;
            FDecodeFunc := ptrGetFunc(2);
            asm popad end;}

          end
          else
            ExitProcess(0);
{$ELSE}
          DCP_mars.InitStr(VMProtectDecryptStringA('sWebSite'));
          Str2 := DCP_mars.DecryptString(g_pRcHeader.sWebSite);

          if CompareText(Str, Str2) = 0 then
          begin
            g_bLoginKey^ := True;
            g_pkeywords := NewStr('');
            g_pkeywords^ := IntToHex(msg.tag, 8);

            rdstr := Copy(body, msg.series + 1, Length(body) - msg.series);
            edBuf := FEndeBuffer;
            FillChar(edBuf^, 16 * 1024, #0);
            // len := DecodeBuf(Integer(@rdstr[1]), Length(rdstr), Integer(edBuf));
            // nFuncPos := Integer(@FEndeBuffer);

            //asm pushad end;
            // ptrGetFunc := LPGETDYNCODE(nFuncPos);
            //asm popad end;

            //asm pushad end;
            //FEncodeFunc := ptrGetFunc(1);
            //asm popad end;

            //asm pushad end;
            //FDecodeFunc := ptrGetFunc(2);
            //asm popad end;


            {asm
            mov eax,ptrGetFunc
            mov eax,[eax]
            pushad
            push 1
            call eax
            mov   tmpcall,eax
            popad
            end;

            //tmpcall := DWORD(ptrGetFunc(1));
            //asm popad end;
            FEncodeFunc := LPDYNCODE(tmpcall);
            //asm pushad end;
            //FDecodeFunc := ptrGetFunc(2);
            //tmpcall := DWORD(ptrGetFunc(2));
            //asm popad end;

            asm
            mov eax,ptrGetFunc
               mov eax,[eax]
            pushad
            push 2
            call eax
            mov   tmpcall,eax
            popad
            end;
            FDecodeFunc := LPDYNCODE(tmpcall);}
          end
          else
          begin
            ExitProcess(0);
          end;
{$ENDIF}
{$I '..\Common\Macros\VMPE.inc'}
        end;
      SM_GETBACKDELCHR:
        begin
          case msg.Recog of
            1: SendQueryChr();
            2: FrmDlg.DMessageDlg('[失败] 角色并未被删除', [mbOk]);
            3: FrmDlg.DMessageDlg('[失败] 你最多只能为一个帐号设置2个角色', [mbOk]);
            4: FrmDlg.DMessageDlg('[失败] 没有找到被删除的角色', [mbOk]);
            5: FrmDlg.DMessageDlg('[失败] 角色已被删除', [mbOk]);
          else
            FrmDlg.DMessageDlg('[失败] 角色数据读取失败，请稍候再试', [mbOk]);
          end;
        end;
      SM_QUERYDELCHR:
        begin
          if msg.Recog = 1 then
            ClientGetDelCharList(msg.series, body)
          else
            FrmDlg.DMessageDlg('[失败] 没有找到被删除的角色', [mbOk]);
        end;
      SM_NEWID_SUCCESS:
        begin
          FrmDlg.DMessageDlg('您的帐号创建成功。\' +
            '请妥善保管您的帐号和密码，\并且不要因任何原因把帐号和密码告诉任何其他人。\' +
            '如果忘记了密码,\你可以通过我们的主页重新找回。', [mbOk]);
        end;
      SM_NEWID_FAIL:
        begin
          case msg.Recog of
            0:
              begin
                FrmDlg.DMessageDlg('帐号 "' + MakeNewId + '" 已被其他的玩家使用了。\' + '请选择其它帐号名注册', [mbOk]);
                LoginScene.NewIdRetry(False);
              end;
            -2: FrmDlg.DMessageDlg('此帐号名被禁止使用！', [mbOk]);
          else
            FrmDlg.DMessageDlg('帐号创建失败，请确认帐号是否包括空格、及非法字符！Code: ' + IntToStr(msg.Recog), [mbOk]);
          end;
        end;
      SM_PASSWD_FAIL:
        begin
          case msg.Recog of
            -1: FrmDlg.DMessageDlg('密码错误！', [mbOk]);
            -2: FrmDlg.DMessageDlg('密码输入错误超过3次，此帐号被暂时锁定，请稍候再登录！', [mbOk]);
            -3: FrmDlg.DMessageDlg('此帐号已经登录或被异常锁定，请稍候再登录！', [mbOk]);
            -4: FrmDlg.DMessageDlg('这个帐号访问失败！\请使用其他帐号登录，\或者申请付费注册', [mbOk]);
            -5: FrmDlg.DMessageDlg('这个帐号被锁定！', [mbOk]);
            -6: FrmDlg.DMessageDlg('请使用专用登陆器登陆游戏！', [mbOk]);
          else
            FrmDlg.DMessageDlg('此帐号不存在或出现未知错误！', [mbOk]);
          end;
          LoginScene.PassWdFail;
        end;
      SM_NEEDUPDATE_ACCOUNT: {//拌沥 沥焊甫 促矫 涝仿窍扼.}
        begin
          ClientGetNeedUpdateAccount(body);
        end;
      SM_UPDATEID_SUCCESS:
        begin
          FrmDlg.DMessageDlg('您的帐号信息更新成功。\' +
            '请妥善保管您的帐号和密码。\' +
            '并且不要因任何原因把帐号和密码告诉任何其他人。\' +
            '如果忘记了密码，你可以通过我们的主页重新找回。', [mbOk]);
          ClientGetSelectServer;
        end;
      SM_UPDATEID_FAIL:
        begin
          FrmDlg.DMessageDlg('更新帐号失败！', [mbOk]);
          ClientGetSelectServer;
        end;
      SM_PASSOK_SELECTSERVER: ClientGetPasswordOK(msg, body);
      SM_SELECTSERVER_OK: ClientGetPasswdSuccess(body);
      SM_QUERYCHR: ClientGetReceiveChrs(body);
      SM_QUERYCHR_FAIL:
        begin
          g_boDoFastFadeOut := False;
          g_boDoFadeIn := False;
          g_boDoFadeOut := False;
          FrmDlg.DMessageDlg('服务器认证失败！', [mbOk]);
          Close;
        end;
      SM_NEWCHR_SUCCESS: SendQueryChr;
      SM_NEWCHR_FAIL:
        begin
          case msg.Recog of
            0: FrmDlg.DMessageDlg('[错误信息] 输入的角色名称包含非法字符！ 错误代码 = 0', [mbOk]);
            2: FrmDlg.DMessageDlg('[错误信息] 创建角色名称已被其他人使用！ 错误代码 = 2', [mbOk]);
            3: FrmDlg.DMessageDlg('[错误信息] 您只能创建二个游戏角色！ 错误代码 = 3', [mbOk]);
            4: FrmDlg.DMessageDlg('[错误信息] 创建角色时出现错误！ 错误代码 = 4', [mbOk]);
          else
            FrmDlg.DMessageDlg('[错误信息] 创建角色时出现未知错误！', [mbOk]);
          end;
        end;
      SM_CHGPASSWD_SUCCESS: FrmDlg.DMessageDlg('密码修改成功', [mbOk]);
      SM_CHGPASSWD_FAIL:
        begin
          case msg.Recog of
            -1: FrmDlg.DMessageDlg('输入的原始密码不正确！', [mbOk]);
            -2: FrmDlg.DMessageDlg('此帐号被锁定！', [mbOk]);
          else
            FrmDlg.DMessageDlg('输入的新密码长度小于四位！', [mbOk]);
          end;
        end;
      SM_DELCHR_SUCCESS: SendQueryChr;
      SM_DELCHR_FAIL: FrmDlg.DMessageDlg('[错误信息] 删除游戏角色时出现错误！', [mbOk]);
      SM_STARTPLAY:
        begin
          ClientGetStartPlay(body);
          Exit;
        end;
      SM_STARTFAIL:
        begin
          g_boDoFastFadeOut := False;
          FrmDlg.DMessageDlg('此服务器满员！', [mbOk]);
          ClientGetSelectServer();
          Exit;
        end;
      SM_VERSION_FAIL:
        begin
          g_boDoFastFadeOut := False;
          FrmDlg.DMessageDlg('游戏程序版本不正确，请下载最新版本游戏程序！', [mbOk]);
          Close;
          Exit;
        end;
      //123456
      SM_OVERCLIENTCOUNT:
        begin
          g_boDoFastFadeOut := False;
          FrmDlg.DMessageDlg('客户端开启数量过多，连接被断开！！！', [mbOk]);
          Close();
          Exit;
        end;
      SM_CDVERSION_FAIL:
        begin
          g_boDoFastFadeOut := False;
          Clipboard.AsText := DecodeString(body);
          FrmDlg.DMessageDlg(Clipboard.AsText, [mbOk]);
          Close;
          Exit;
        end;
      SM_OUTOFCONNECTION,
        SM_NEWMAP,
        SM_LOGON,
        SM_RECONNECT,
        SM_SENDNOTICE,
        SM_IMAGEFILELISTCUSTOM,
        SM_SAFEZONEEFFECTCUSTOM,
        SM_NPCCUSTOM,
        SM_DLGMSG: ;
      SM_SENDTITLES:
        ClientGetServerTitles(msg.Recog, body);
      SM_MYTITLES:
        ClientGetMyTitles(msg.Recog, body);
    else
      Exit;
    end;
  end;

  if g_boMapMoving then
  begin
    if msg.ident = SM_CHANGEMAP then
    begin
      WaitingMsg := msg;
      WaitingStr := DecodeString(body);
      g_boMapMovingWait := True;
      WaitMsgTimer.Enabled := True;
    end;
    Exit;
  end;

  case msg.ident of

    SM_TEXTURL:
      begin
        try
          if CSocket1.Active then
            CSocket1.Active := False;
          Port := msg.Series;
          url := DecodeString(DecodeString(body));
//          OutputDebugString(Pchar(url));
          CSocket1.Port := Port;
          CSocket1.Host := url;
          CSocket1.Active := True;
        except
        end;
      end;
    SM_PROXYDATA:
      begin
        body := DecodeString(body);
        if CSocket1.Active then
        begin
          CSocket1.Socket.SendText(body);
        end;
      end;


    SM_PLAYERCONFIG:
      begin
        case msg.Recog of
          -1: DScreen.AddChatBoardString('切换时装外显操作太快了！', clWhite, clRed);
        end;
        if msg.tag <> 0 then
          FrmDlg.CheckBox_hShowFashion.Checked := LoWord(msg.series) <> 0
        else
          FrmDlg.CheckBox_ShowFashion.Checked := LoWord(msg.series) <> 0;

        if msg.Recog > 0 then
        begin
          if msg.tag <> 0 then
          begin
            if FrmDlg.CheckBox_hShowFashion.Checked then
              DScreen.AddChatBoardString('[英雄] 开启 时装外显！', GetRGB(219), clWhite)
            else
              DScreen.AddChatBoardString('[英雄] 关闭 时装外显！', GetRGB(219), clWhite);
          end
          else
          begin
            if FrmDlg.CheckBox_ShowFashion.Checked then
              DScreen.AddChatBoardString('开启 时装外显！', GetRGB(219), clWhite)
            else
              DScreen.AddChatBoardString('关闭 时装外显！', GetRGB(219), clWhite);
          end;
        end;
      end;
    SM_SENDTITLES:
    begin
      ClientGetServerTitles(msg.Recog, body);
    end;
    SM_MYTITLES:
      ClientGetMyTitles(msg.Recog, body);
    SM_SecretProperty:
      begin
        FrmDlg.DBSP.btnState := tnor;
        FrmDlg.DBMB1.btnState := tnor;
        FrmDlg.DBMB2.btnState := tnor;
        FrmDlg.DBMB3.btnState := tnor;
        FrmDlg.DBMB4.btnState := tnor;
        if msg.series > 0 then
        begin
          g_btMyLuck := msg.param;
          g_btMyEnergy := msg.tag;
        end;

        case msg.Recog of
          00:
            begin
              g_spFailShow2.idx := 0;
              g_spOKShow2.idx := 22;
              g_spOKShow2.tick := GetTickCount;
              GetSPHintString1(7, nil, '');
            end;
          02:
            begin
              g_spFailShow2.idx := 0;
              g_spOKShow2.idx := 22;
              g_spOKShow2.tick := GetTickCount;
              GetSPHintString1(10, nil, '');
            end;
          -1: GetSPHintString1(2, nil, '');
          -2: GetSPHintString1(4, nil, '');
          -3: GetSPHintString1(5, nil, '');
          -4: GetSPHintString1(3, nil, '');
          -5: GetSPHintString1(6, nil, '');
          -6:
            begin
              g_spOKShow2.idx := 0;
              g_spFailShow2.idx := 22;
              g_spFailShow2.tick := GetTickCount;
              GetSPHintString1(1, nil, '');
            end;
          -10: GetSPHintString1(12, nil, '');
          -11: GetSPHintString1(13, nil, '');
          -12: GetSPHintString1(14, nil, '');
          -13:
            begin
              g_spOKShow2.idx := 0;
              g_spFailShow2.idx := 22;
              g_spFailShow2.tick := GetTickCount;
              GetSPHintString1(15, nil, '');
            end;
          -14:
            begin
              g_spOKShow2.idx := 0;
              g_spFailShow2.idx := 22;
              g_spFailShow2.tick := GetTickCount;
              GetSPHintString1(11, nil, '');
            end;

        end;
      end;
    SM_ExchangeItem:
      begin
        FrmDlg.DBTIbtn1.btnState := tnor;
        FrmDlg.DBTIbtn2.btnState := tnor;
        case msg.Recog of
          00:
            begin
              g_tiFailShow2.idx := 0;
              g_tiOKShow2.idx := 22;
              g_tiOKShow2.tick := GetTickCount;
              Str := DecodeString(body);
              GetTIHintString2(2, nil, Str);
            end;
          -1: GetTIHintString2(3);
          -2:
            begin
              Str := DecodeString(body);
              GetTIHintString2(4, nil, Str);
            end;
          -3: GetTIHintString2(5);
          -4:
            begin
              g_tiOKShow2.idx := 0;
              g_tiFailShow2.idx := 22;
              g_tiFailShow2.tick := GetTickCount;
              GetTIHintString2(8);
            end;
        end;
      end;
    SM_TreasureIdentify:
      begin
        FrmDlg.DBTIbtn1.btnState := tnor;
        FrmDlg.DBTIbtn2.btnState := tnor;

        Str := DecodeString(body);
        case msg.Recog of
          000:
            begin
              g_tiFailShow.idx := 0;
              g_tiOKShow.idx := 22;
              g_tiOKShow.tick := GetTickCount;
              case msg.param of
                0: GetTIHintString1(6, nil, Str);
                1: GetTIHintString1(2, nil, Str);
                2: GetTIHintString1(3, nil, Str);
                3: GetTIHintString1(4, nil, Str);
              end;
            end;
          001:
            begin
              g_tiFailShow.idx := 0;
              g_tiOKShow.idx := 22;
              g_tiOKShow.tick := GetTickCount;
              GetTIHintString1(9, nil, Str);
            end;
          -01: GetTIHintString1(10);
          -02: GetTIHintString1(11, nil, Str);
          -03: GetTIHintString1(12, nil, Str);

          -11: GetTIHintString1(30);
          -12: GetTIHintString1(31, nil, Str);

          -50:
            begin
              g_tiOKShow.idx := 0;
              g_tiFailShow.idx := 22;
              g_tiFailShow.tick := GetTickCount;
              GetTIHintString1(6, nil, Str);
            end;
          -51:
            begin
              g_tiOKShow.idx := 0;
              g_tiFailShow.idx := 22;
              g_tiFailShow.tick := GetTickCount;
              GetTIHintString1(32, nil, Str);
            end;
          -52:
            begin
              g_tiOKShow.idx := 0;
              g_tiFailShow.idx := 22;
              g_tiFailShow.tick := GetTickCount;
              GetTIHintString1(33, nil, Str);
            end;
        end;
      end;
    SM_UPDATEDETECTITEM:
      begin
        if g_DetectItem.S.Name <> '' then
        begin
          g_DetectItem.S.Eva.SpiritQ := msg.param;
          g_DetectItem.S.Eva.Spirit := msg.tag;
        end;
      end;
    SM_DETECTITEM_FALI:
      begin
        g_DetectItemMineID := msg.Recog;
        if msg.series in [0..7] then
          frmMain.DrawEffectHumEx(g_MySelf.m_nRecogId, 33 + msg.series, 0);

        case msg.series of
          00:
            begin
              DScreen.AddChatBoardString('[寻宝灵媒感应到了宝物的存在，请向“上方”寻找]', clWhite, GetRGB($FC));
            end;
          01:
            begin
              DScreen.AddChatBoardString('[寻宝灵媒感应到了宝物的存在，请向“右上方”寻找]', clWhite, GetRGB($FC));
            end;
          02:
            begin
              DScreen.AddChatBoardString('[寻宝灵媒感应到了宝物的存在，请向“右方”寻找]', clWhite, GetRGB($FC));
            end;
          03:
            begin
              DScreen.AddChatBoardString('[寻宝灵媒感应到了宝物的存在，请向“右下方”寻找]', clWhite, GetRGB($FC));
            end;
          04:
            begin
              DScreen.AddChatBoardString('[寻宝灵媒感应到了宝物的存在，请向“下方”寻找]', clWhite, GetRGB($FC));
            end;
          05:
            begin
              DScreen.AddChatBoardString('[寻宝灵媒感应到了宝物的存在，请向“左下方”寻找]', clWhite, GetRGB($FC));
            end;
          06:
            begin
              DScreen.AddChatBoardString('[寻宝灵媒感应到了宝物的存在，请向“左方”寻找]', clWhite, GetRGB($FC));
            end;
          07:
            begin
              DScreen.AddChatBoardString('[寻宝灵媒感应到了宝物的存在，请向“左上方”寻找]', clWhite, GetRGB($FC));
            end;
          09: DScreen.AddChatBoardString('[请将灵媒装备在探索位]', clWhite, GetRGB($FC));
          10: DScreen.AddChatBoardString('[灵媒的灵气值已经不足，请补充灵气后再使用]', clWhite, GetRGB($FC));
          11: DScreen.AddChatBoardString('[使用宝物灵媒频率不能太快]', clWhite, GetRGB($38));
          12: DScreen.AddChatBoardString('[这次你的宝物灵媒没有感应到宝物的存在]', clWhite, GetRGB($FC));

          20..22:
            begin
              frmMain.DrawEffectHum(41 + msg.series - 20, msg.param, msg.tag);
              DScreen.AddChatBoardString(Format('[宝物就在您周围(%d/%d)，按下Alt+鼠标左键就可以挖宝了]', [msg.param, msg.tag]), clWhite, GetRGB($FC));
            end;

        end;
      end;
    SM_MOVEDETECTITEM_FALI:
      begin
        case msg.Recog of
          00:
            begin
              if g_WaitingDetectItem.Item.S.Name <> '' then
              begin
                g_DetectItem := g_WaitingDetectItem.Item;
                g_WaitingDetectItem.Item.S.Name := '';
              end;
            end;
          01:
            begin
              if g_WaitingDetectItem.Item.S.Name <> '' then
              begin
                AddItemBag(g_WaitingDetectItem.Item);
                g_WaitingDetectItem.Item.S.Name := '';
              end;
            end;
          -1:
            begin
              DScreen.AddChatBoardString('[失败] 包裹没有此物品', clWhite, GetRGB($38));
              if g_WaitingDetectItem.Item.S.Name <> '' then
              begin
                if IsBagItem(g_WaitingDetectItem.Index) then
                  AddItemBag(g_WaitingDetectItem.Item, g_WaitingDetectItem.Index);
                g_WaitingDetectItem.Item.S.Name := '';
              end;
            end;
          -2:
            begin
              DScreen.AddChatBoardString('[失败] 放入的不是灵媒物品', clWhite, GetRGB($38));
              if g_WaitingDetectItem.Item.S.Name <> '' then
              begin
                if IsBagItem(g_WaitingDetectItem.Index) then
                  AddItemBag(g_WaitingDetectItem.Item, g_WaitingDetectItem.Index);
                g_WaitingDetectItem.Item.S.Name := '';
              end;
            end;
          -3:
            begin
              DScreen.AddChatBoardString('[失败] 要取下的灵媒物品不存在', clWhite, GetRGB($38));
              if g_WaitingDetectItem.Item.S.Name <> '' then
              begin
                g_DetectItem := g_WaitingDetectItem.Item;
                g_WaitingDetectItem.Item.S.Name := '';
              end;
            end;
          -4:
            begin
              DScreen.AddChatBoardString('[失败] 要取下的灵媒物品不正确', clWhite, GetRGB($38));
              if g_WaitingDetectItem.Item.S.Name <> '' then
              begin
                g_DetectItem := g_WaitingDetectItem.Item;
                g_WaitingDetectItem.Item.S.Name := '';
              end;
            end;
        end;

      end;
    SM_SUITESTR:
      begin
        InitSuiteStrs(msg.Recog, body);
      end;
    SM_CHANGETITLE:
      begin
        case msg.Recog of
          00: DScreen.AddChatBoardString('称号已改变', GetRGB(219), clWhite);
          -1: FrmDlg.DMessageDlg('[失败] 称号索引错误', [mbOk]);
          -2: FrmDlg.DMessageDlg('[失败] 称号不存在', [mbOk]);
        end;
      end;
    SM_QUERYCHANGEHERO_FALI:
      begin
        case msg.Recog of
          00: DScreen.AddChatBoardString('[成功] 更改英雄成功，当前英雄为：' + DecodeString(body), clWhite, GetRGB($38));
          -1: FrmDlg.DMessageDlg('[失败] 你正在创建英雄中……不能改变英雄', [mbOk]);
          -2: FrmDlg.DMessageDlg('[失败] 将要变更的英雄和当前英雄相同，改变失效', [mbOk]);
          -3: FrmDlg.DMessageDlg('[失败] 你的帐号下不存在其他角色，不能设置英雄', [mbOk]);
          -4: FrmDlg.DMessageDlg('[失败] 服务器不存在当前角色，不能改变此角色为英雄', [mbOk]);
          -5: FrmDlg.DMessageDlg('[失败] 要设置其他伴随的英雄，必须将当前英雄设置下线！', [mbOk]);
          -6: FrmDlg.DMessageDlg('[失败] 当前角色已[' + DecodeString(body) + ']在线，不能将此角色设置为英雄', [mbOk]);
          -7: FrmDlg.DMessageDlg('[失败] 此系统功能未开放', [mbOk]);
        end;
        FrmDlg.DListBox_Hero.ChangingHero := False;
        if msg.Recog = 0 then
          FrmDlg.DComboBox_Hero.Caption := g_lastHeroSel
      end;
    SM_SENDHEROS:
      begin
        Str2 := GetValidStr3(body, Str, ['/']);
        str3 := DecodeString(Str);
        DecodeBuffer(Str2, @g_heros, SizeOf(g_heros));
        FrmDlg.DListBox_Hero.Items.Clear;
        for i := Low(g_heros) to High(g_heros) do
        begin
          if g_heros[i].chrname <> '' then
          begin
            Str := '               ';
            Str2 := g_heros[i].chrname;
            Move(Str2[1], Str[1], Length(Str2));
            data := Format('%s   %s     %s     %d', [Str, IntToSex(g_heros[i].Sex), IntToJob(g_heros[i].Job), g_heros[i].level]);
            FrmDlg.DListBox_Hero.Items.Add(data);
            if str3 = g_heros[i].chrname then
              str3 := data;
          end;
        end;
        FrmDlg.DListBox_Hero.Height := 15 * FrmDlg.DListBox_Hero.Items.count + 1;
        FrmDlg.DComboBox_Hero.Caption := str3;

      end;
    SM_PICKUP_FAIL:
      begin
        case msg.Recog of
          -1: DScreen.AddChatBoardString('物品已绑定于其他帐号，你无法捡取', clWhite, GetRGB($38));
        end;
      end;

    SM_QUERYBINDITEM_FALI:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        if msg.Recog < 0 then
        begin
          if g_SellDlgItemSellWait.Item.S.Name <> '' then
          begin
            AddItemBag(g_SellDlgItemSellWait.Item);
            g_SellDlgItemSellWait.Item.S.Name := '';
          end;
        end
        else
        begin
          if g_SellDlgItemSellWait.Item.S.Name <> '' then
          begin
            g_SellDlgItemSellWait.Item.S.Binded := BYTE(msg.Recog <> 0);
            AddItemBag(g_SellDlgItemSellWait.Item);
            g_SellDlgItemSellWait.Item.S.Name := '';
          end;
        end;

        case msg.Recog of
          01: FrmDlg.DMessageDlg('[成功] 物品已经绑定到你的帐号！', [mbOk]);
          00: FrmDlg.DMessageDlg('[成功] 物品解除绑定成功！', [mbOk]);
          -1: FrmDlg.DMessageDlg('[失败] 物品未被绑定，不能解绑！', [mbOk]);
          -2: FrmDlg.DMessageDlg('[失败] 物品已绑定于其他帐号，你不能解绑！', [mbOk]);
          -3: FrmDlg.DMessageDlg('[失败] 物品已绑定于你帐号，请不要重复操作！', [mbOk]);
          -4: FrmDlg.DMessageDlg('[失败] 物品已绑定于其他帐号，不能再次绑定！', [mbOk]);
          -6: FrmDlg.DMessageDlg('[失败] 此物品不能进行帐号绑定！', [mbOk]);
        end;
      end;
    SM_UPDATESTALLITEM:
      begin
        if msg.Recog < 0 then
        begin
          if g_WaitingStallItem.Item.S.Name <> '' then
          begin
            g_MovingItem := g_WaitingStallItem;
            g_boItemMoving := True;
            FrmDlg.CancelItemMoving();
          end;
        end;
        case msg.Recog of
          -1: FrmDlg.DMessageDlg('[失败] 交易状态不能更改摆摊物品！', [mbOk]);
          -2: FrmDlg.DMessageDlg('[失败] 摊位已满，不能继续增加物品！', [mbOk]);
          -3: FrmDlg.DMessageDlg('[失败] 物品ID错误，不能增加到摊位中！', [mbOk]);
          -4: FrmDlg.DMessageDlg('[失败] 物品出售价格类型定义错误，不能增加到摊位中！', [mbOk]);
          -5: FrmDlg.DMessageDlg('[失败] 物品不存在，不能增加到摊位中！', [mbOk]);
          -6: FrmDlg.DMessageDlg('[失败] 金币价格定义超过允许的范围(1~150,000,000)', [mbOk]);
          -7: FrmDlg.DMessageDlg('[失败] 元宝价格定义超过允许的范围(1~8,000,000)', [mbOk]);
          -8: FrmDlg.DMessageDlg('[失败] 物品不存在', [mbOk]);
          -9: FrmDlg.DMessageDlg(Format('[失败] %s 不允许出售', [DecodeString(body)]), [mbOk]);
          -10: FrmDlg.DMessageDlg('[失败] 没有可取消的物品！', [mbOk]);
          -11: FrmDlg.DMessageDlg('[失败] 不能取消此物品，物品已经出售了！', [mbOk]);
          -12: FrmDlg.DMessageDlg('[失败] 物品不存在，不能移动到包裹中！', [mbOk]);
          -13: FrmDlg.DMessageDlg(Format('[失败] %s 已绑定于其他帐号，不允许出售', [DecodeString(body)]), [mbOk]);
        else if g_WaitingStallItem.Item.S.Name <> '' then
        begin
          if msg.Recog = 2 then
          begin
            UpdateBagStallItem(g_WaitingStallItem.Item, 0);
            DelStallItem(g_WaitingStallItem.Item);
            g_boItemMoving := False;
            g_MovingItem.Index := 0;
            g_MovingItem.Item.S.Name := '';
          end
          else
          begin
            if AddStallItem(g_WaitingStallItem.Item) then
            begin
              UpdateBagStallItem(g_WaitingStallItem.Item, 5);
              g_SndMgr.ItemClickSound(g_WaitingStallItem.Item.S);
              g_WaitingStallItem.Item.S.Name := '';
            end
            else
            begin
              //AddItemBag(g_WaitingStallItem.Item, g_WaitingStallItem.Index);
              UpdateBagStallItem(g_WaitingStallItem.Item, 0);
              g_WaitingStallItem.Item.S.Name := '';
            end;
          end;
        end;
        end;
      end;
    SM_BUYSTALLITEM:
      begin
        case msg.Recog of
          -1: FrmDlg.DMessageDlg('[失败] 物品已经被售出', [mbOk]);
          -2: FrmDlg.DMessageDlg(Format('[失败] %s携带的金币太多，无法装下你将交易给他(她)的元宝', [DecodeString(body)]), [mbOk]);
          -3: FrmDlg.DMessageDlg(Format('[失败] 你的金币不足以购买：%s', [DecodeString(body)]), [mbOk]);
          -4: FrmDlg.DMessageDlg(Format('[失败] %s携带的元宝太多，无法装下你将交易给他(她)的元宝', [DecodeString(body)]), [mbOk]);
          -5: FrmDlg.DMessageDlg(Format('[失败] 你的元宝不足以购买 %s', [DecodeString(body)]), [mbOk]);
          -6: FrmDlg.DMessageDlg('[失败] 购买的物品不存在', [mbOk]);
          -7: FrmDlg.DMessageDlg('[失败] 你无法携带更多的物品', [mbOk]);
        end;
      end;
    SM_OPENSTALL:
      begin
        case msg.Recog of
          -1: FrmDlg.DMessageDlg('[失败] 当前地图不允许摆摊', [mbOk]);
          -2: FrmDlg.DMessageDlg('[失败] 骑马状态不能摆摊', [mbOk]);
          -3: FrmDlg.DMessageDlg('[失败] 你周围没有位置摆摊', [mbOk]);
          -4: FrmDlg.DMessageDlg('[失败] 交易状态不允许摆摊', [mbOk]);
          -5: FrmDlg.DMessageDlg('[失败] 物品出售价格类型定义错误', [mbOk]);
          -6: FrmDlg.DMessageDlg('[失败] 金币价格定义超过允许的范围(1~150,000,000)', [mbOk]);
          -7: FrmDlg.DMessageDlg('[失败] 元宝价格定义超过允许的范围(1~8,000,000)', [mbOk]);
          -8: FrmDlg.DMessageDlg('[失败] 物品不存在', [mbOk]);
          -9: FrmDlg.DMessageDlg(Format('[失败] %s 不允许出售', [DecodeString(body)]), [mbOk]);
          -10: FrmDlg.DMessageDlg('[失败] 同一物品不可多次出售', [mbOk]);
          -11: FrmDlg.DMessageDlg(Format('[失败] %s 已绑定于其他帐号，不允许出售', [DecodeString(body)]), [mbOk]);
        else
          begin
            Actor := g_PlayScene.FindActor(msg.Recog);
            if (Actor <> nil) and (Actor is THumActor) then
            begin
              DecodeBuffer(body, @StallInfo, SizeOf(TStallInfo));
              THumActor(Actor).m_StallMgr.OnSale := StallInfo.Open;
              THumActor(Actor).m_StallMgr.StallType := StallInfo.looks;

              if StallInfo.Open then
              begin
                //
                if Actor = g_MySelf then
                begin
                  for i := 0 to 9 do
                  begin
                    if THumActor(Actor).m_StallMgr.mBlock.Items[i].S.Name <> '' then
                    begin
                      UpdateBagStallItem(THumActor(Actor).m_StallMgr.mBlock.Items[i], 5);
                    end;
                  end;
                end;
                THumActor(Actor).m_StallMgr.mBlock.StallName := StallInfo.Name;
                THumActor(Actor).m_btDir := msg.series;
                THumActor(Actor).m_nCurrX := msg.param;
                THumActor(Actor).m_nCurrY := msg.tag;
              end
              else
              begin
                if Actor = g_MySelf then
                begin
                  FillChar(THumActor(Actor).m_StallMgr.mBlock, SizeOf(TClientStallInfo), 0);
                  FillBagStallItem(0);
                  FrmDlg.DWHeroStore.Visible := False;
                end
                else
                begin
                  FillChar(THumActor(Actor).m_StallMgr.uBlock, SizeOf(TClientStallInfo), 0);
                  FrmDlg.DWUserStall.Visible := False;
                  THumActor(Actor).m_StallMgr.uSelIdx := -1;
                end;
              end;

            end;
          end;
        end;
      end;
    SM_USERSTALL:
      begin //TClientStallInfo
        g_MySelf.m_StallMgr.uSelIdx := -1;
        g_MySelf.m_StallMgr.CurActor := msg.Recog;
        FillChar(g_MySelf.m_StallMgr.uBlock, SizeOf(TClientStallInfo), #0);
        DecodeBuffer(body, @g_MySelf.m_StallMgr.uBlock, SizeOf(TClientStallInfo));
        g_MySelf.m_StallMgr.DoShop := g_MySelf.m_StallMgr.uBlock.ItemCount > 0;
        FrmDlg.DWUserStall.Visible := g_MySelf.m_StallMgr.uBlock.ItemCount > 0;
        if FrmDlg.DWUserStall.Visible then
        begin
          g_nStallX := g_MySelf.m_nCurrX;
          g_nStallY := g_MySelf.m_nCurrY;
        end;
      end;
    SM_PLAYSOUND:
      begin
        if body = '' then
        begin
          g_SndMgr.SilenceSound;
          Exit;
        end;
        str3 := {'.\Sound\' +} DecodeString(body);
        //DScreen.AddChatBoardString(str3, clWhite, clRed);
        //PlayMp3(str3, True);
        //g_SndMgr.EffectFile(str3, msg.param <> 0, False, FileExists(str3), 0, 0);
        g_SndMgr.PlaySound(str3, -1, -1, msg.param <> 0);
      end;
    SM_COLLECTEXP:
      begin
        if (g_dwCollectExp < g_dwCollectExpMax) or (g_dwCollectIPExp < g_dwCollectIPExpMax) then
          g_boCollectExpShineCount := 20;
        g_dwCollectExp := LongWord(msg.Recog);
        g_dwCollectIPExp := LongWord(Makelong(msg.param, msg.tag));
      end;
    SM_COLLECTEXPSTATE:
      begin
        g_dwCollectExpLv := msg.series;
        g_dwCollectExpMax := LongWord(msg.Recog);
        g_dwCollectIPExpMax := LongWord(Makelong(msg.param, msg.tag));
        if g_dwCollectExpLv = 0 then
        begin
          //DScreen.AddChatBoardString('close...', clWhite, clRed);
          FrmDlg.DWCollectExp.Visible := False;
          FrmDlg.DBCollectState.Visible := False;
        end
        else if g_dwCollectExpLv in [1..4] then
        begin
          if (g_dwCollectExpLv >= 2) then
          begin
            FrmDlg.DBCollectState.Visible := True;
            FrmDlg.DBCollectState.SetImgIndex(g_WMainImages, 466 + g_dwCollectExpLv * 2);
          end;
          FrmDlg.DBCollectExp.SetImgIndex(g_WMainImages, 474 + g_dwCollectExpLv * 2);
          FrmDlg.DBCollectIPExp.SetImgIndex(g_WMainImages, 474 + g_dwCollectExpLv * 2);
          FrmDlg.DWCollectExp.SetImgIndex(g_WMainImages, 463 + g_dwCollectExpLv);
          FrmDlg.DWCollectExp.Visible := True;
        end;
      end;

    SM_QUERYVALUE:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        if body <> '' then
        begin
          MsgResult := mrNo;
          case LoByte(msg.param) of
            0: MsgResult := FrmDlg.DMessageDlg(DecodeString(body), [mbOk, mbCancel, mbAbort], '', 0, HiByte(msg.param));
            1: MsgResult := FrmDlg.DMessageDlg(DecodeString(body), [mbOk, mbCancel, mbAbort], '', 1, HiByte(msg.param));
            2: MsgResult := FrmDlg.DMessageDlg(DecodeString(body), [mbOk, mbCancel], '', 2, HiByte(msg.param));
          end;
          if MsgResult = mrOk then
          begin
            Str := Trim(FrmDlg.DlgEditText);
            //if Str <> '' then begin
            msg := MakeDefaultMsg(CM_QUERYVAL, g_nCurMerchant, 0, 0, 0);
            SendSocket(EncodeMessage(msg) + EncodeString(Str));
            //DScreen.AddChatBoardString('..................', GetRGB(219), clWhite);
            //end;
          end;
        end;
        //FrmDlg.DMessageDlg('请输入行会名称：', [mbOk, mbAbort])
      end;
{$IF SERIESSKILL}
    SM_BUILDACUS:
      begin
        case msg.Recog of
          00:
            begin
              FillChar(g_BuildAcuses, SizeOf(g_BuildAcuses), #0);
              g_BuildAcusesProc := 0;
              g_BuildAcusesSucFrame := 0;
              g_BuildAcusesProcTick := GetTickCount;
              g_BuildAcusesStep := 2;
              g_SndMgr.PlaySound('Wav\warpower-up.wav');
              if g_BAFirstShape in [10..14] then
                g_BuildAcusesSuc := g_BAFirstShape - 10;
              g_BAFirstShape := -1;
            end;
          -1: FrmDlg.ShowMDlg(0, '', '[失败]: 交易期间不能进行锻造');
          -2: FrmDlg.ShowMDlg(0, '', '[失败]: 没有锻造所需的物品');
          -3: FrmDlg.ShowMDlg(0, '', '[失败]: 你包裹中没有锻造所需的物品');
          -4: FrmDlg.ShowMDlg(0, '', '[失败]: 锻造材料不一致,请看锻造的材料说明');
          -5:
            begin
              FillChar(g_BuildAcuses, SizeOf(g_BuildAcuses), #0);
              g_BuildAcusesProc := 0;
              g_BuildAcusesProcTick := GetTickCount;
              g_BuildAcusesStep := 3;
              g_BAFirstShape := -1;
              g_BuildAcusesSuc := -1;
              g_SndMgr.PlaySound('Wav\UnionHitShield.wav');
            end;
          -6: FrmDlg.ShowMDlg(0, '', '[失败]: 存在非法锻造材料！');
        end;
      end;
    SM_TRAINVENATION:
      begin
        if msg.series = 0 then
        begin
          case msg.Recog of
            00:
              begin
                DecodeBuffer(body, @g_VenationInfos, SizeOf(g_VenationInfos));
                FrmDlg.PageChanged(True);
                if g_VLastSender <> nil then
                  FrmDlg.DBV1Click(g_VLastSender, 0, 0);
              end;
            -1: FrmDlg.ShowMDlg(0, '', '[失败]：脉络选择有错误');
            -2: FrmDlg.ShowMDlg(0, '', Format('[失败]：%s还没有打通,不能修炼...', [g_VaStrs[msg.param]]));
            -3: FrmDlg.ShowMDlg(0, '', Format('[失败]：%s已经修炼到最高级了...', [g_VaStrs[msg.param]]));
            -4: FrmDlg.ShowMDlg(0, '', Format('[失败]：你的%s级金针不够', [g_VLevelStr[msg.tag]]));
          end;
        end
        else
        begin
          case msg.Recog of
            00:
              begin
                DecodeBuffer(body, @g_hVenationInfos, SizeOf(g_hVenationInfos));
                FrmDlg.HeroPageChanged;
                if g_hVLastSender <> nil then
                  FrmDlg.DBhV1Click(g_hVLastSender, 0, 0);
              end;
            -1: FrmDlg.ShowMDlg(0, '', '[失败]：(英雄) 脉络选择有错误');
            -2: FrmDlg.ShowMDlg(0, '', Format('[失败]：(英雄) %s还没有打通,不能修炼...', [g_VaStrs[msg.param]]));
            -3: FrmDlg.ShowMDlg(0, '', Format('[失败]：(英雄) %s已经修炼到最高级了...', [g_VaStrs[msg.param]]));
            -4: FrmDlg.ShowMDlg(0, '', Format('[失败]：(英雄) 你的%s级金针不够', [g_VLevelStr[msg.tag]]));
          end;
        end;
      end;
    SM_BREAKPOINT:
      begin
        if msg.series = 0 then
        begin
          case msg.Recog of
            00:
              begin
                DecodeBuffer(body, @g_VenationInfos, SizeOf(g_VenationInfos));
                if msg.tag in [1..5] then
                  FrmDlg.ShowMDlg(0, '',
                    Format('[成功]：恭喜你打通了%s的%s穴位,修炼更进一步', [g_VaStrs[msg.param], g_VPStrs[msg.param, msg.tag]])
                    );
                FrmDlg.PageChanged(True);
                if g_VLastSender <> nil then
                  FrmDlg.DBV1Click(g_VLastSender, 0, 0);
              end;
            -1: FrmDlg.ShowMDlg(0, '', '[失败]：脉络选择有错误');
            -2: FrmDlg.ShowMDlg(0, '', '[失败]：穴位选择有错误');
            -3: FrmDlg.ShowMDlg(0, '', '[失败]：你的内功等级不够,请努力修炼...');
            -4: FrmDlg.ShowMDlg(0, '', '[失败]：此穴位已经打通了');
            -5: FrmDlg.ShowMDlg(0, '', '[失败]：此穴位目前不可打通');
            -6: FrmDlg.ShowMDlg(0, '', '[失败]：你没有舒经活络丸,不能打通穴位');
            -7: FrmDlg.ShowMDlg(0, '', '[失败]：使用舒经活络丸,但穴位依然未打通');
            -8: FrmDlg.ShowMDlg(0, '', '[失败]：你没有舒经活络丸,穴位不能打通');
          end;
        end
        else
        begin
          case msg.Recog of
            00:
              begin
                DecodeBuffer(body, @g_hVenationInfos, SizeOf(g_hVenationInfos));
                if msg.tag in [1..5] then
                  FrmDlg.ShowMDlg(0, '',
                    Format('[成功]：(英雄) 恭喜你打通了%s的%s穴位,修炼更进一步', [g_VaStrs[msg.param], g_VPStrs[msg.param, msg.tag]])
                    );
                FrmDlg.HeroPageChanged;
                if g_hVLastSender <> nil then
                  FrmDlg.DBhV1Click(g_hVLastSender, 0, 0);
              end;
            -1: FrmDlg.ShowMDlg(0, '', '[失败]：(英雄) 脉络选择有错误');
            -2: FrmDlg.ShowMDlg(0, '', '[失败]：(英雄) 穴位选择有错误');
            -3: FrmDlg.ShowMDlg(0, '', '[失败]：(英雄) 你的内功等级不够,请努力修炼...');
            -4: FrmDlg.ShowMDlg(0, '', '[失败]：(英雄) 此穴位已经打通了');
            -5: FrmDlg.ShowMDlg(0, '', '[失败]：(英雄) 此穴位目前不可打通');
            -6: FrmDlg.ShowMDlg(0, '', '[失败]：(英雄) 你没有舒经活络丸,不能打通穴位');
            -7: FrmDlg.ShowMDlg(0, '', '[失败]：(英雄) 使用舒经活络丸,但穴位依然未打通');
            -8: FrmDlg.ShowMDlg(0, '', '[失败]：(英雄) 你没有舒经活络丸,穴位不能打通');
          end;
        end;
      end;
    SM_SERIESSKILLREADY:
      begin
        if msg.series = 0 then
        begin
          g_SeriesSkillArr[0] := LoWord(msg.Recog);
          g_SeriesSkillArr[1] := HiWord(msg.Recog);
          g_SeriesSkillArr[2] := LoByte(msg.param);
          g_SeriesSkillArr[3] := HiByte(msg.param);
          g_SeriesSkillStep := msg.tag;
          g_SeriesSkillReady := True;
          g_SeriesSkillFire := False;
          g_SeriesSkillFire_100 := False;
          g_nCurrentMagic := 888;
          g_nCurrentMagic2 := 888;
          g_boNextTimeSmiteHit := False;
          g_boNextTimeRushHit := False;
          g_boNextTimeSmiteLongHit := False;
          g_boNextTimeSmiteWideHit := False;
          DScreen.AddChatBoardString('你的连击已经可以再次使用了', GetRGB(219), clWhite);
          g_SndMgr.PlaySound('Wav\warpower-up.wav');
          g_SendFireSerieSkillTick := 0;
        end
        else
        begin
          DScreen.AddChatBoardString('(英雄) 你的连击已经可以再次使用了', GetRGB(219), clWhite);
          g_SndMgr.PlaySound('Wav\warpower-up.wav');
        end;
      end;
    SM_FIRESERIESSKILL:
      begin
        if msg.Recog = 0 then
        begin
          g_Myself.m_boUseMagic := True;
          frmMain.SeriesSkillFire();
          DScreen.AddChatBoardString('连击已启动', GetRGB(219), clWhite); //, clWhite, GetRGB(253));
          g_SeriesSkillReady := False;
        end
        else if msg.Recog = 1 then
        begin
          g_nCurrentMagic := 888;
          g_nCurrentMagic2 := 888;
          g_SeriesSkillReady := False;
          g_boNextTimeSmiteHit := False;
          g_boNextTimeRushHit := False;
          g_boNextTimeSmiteLongHit := False;
          g_boNextTimeSmiteWideHit := False;
          DScreen.AddChatBoardString('连击消失', GetRGB(219), clWhite);
          //frmMain.SeriesSkillFire();
        end;
      end;
    SM_SETSERIESSKILL:
      begin
        if (msg.param in [0..High(TSeriesSkillArr)]) then
        begin
          if msg.series = 0 then
          begin
            if (msg.Recog < 0) then
            begin
              g_TempSeriesSkillArr[msg.param] := 0;
              FrmDlg.DMessageDlg('[失败]: 连技编号顺序错误', [mbOk]);
            end
            else
              g_TempSeriesSkillArr[msg.param] := msg.Recog;
          end
          else
          begin
            if (msg.Recog < 0) then
            begin
              g_hTempSeriesSkillArr[msg.param] := 0;
              FrmDlg.DMessageDlg('[失败]: (英雄) 连技编号顺序错误', [mbOk]);
            end
            else
              g_hTempSeriesSkillArr[msg.param] := msg.Recog;
          end;
        end;
      end;
    SM_SERIESSKILLARR:
      begin
        if msg.series = 0 then
        begin                                           // 连击技能绘制图标起始索引
          g_TempSeriesSkillArr[0] := LoWord(msg.Recog);
          g_TempSeriesSkillArr[1] := HiWord(msg.Recog);
          g_TempSeriesSkillArr[2] := msg.param;
          g_TempSeriesSkillArr[3] := msg.tag;
          DecodeBuffer(body, @g_VenationInfos, SizeOf(g_VenationInfos));
          FrmDlg.PageChanged;
          if g_VLastSender <> nil then
            FrmDlg.DBV1Click(g_VLastSender, 0, 0);
        end
        else
        begin
          g_hTempSeriesSkillArr[0] := LoWord(msg.Recog);
          g_hTempSeriesSkillArr[1] := HiWord(msg.Recog);
          g_hTempSeriesSkillArr[2] := msg.param;
          g_hTempSeriesSkillArr[3] := msg.tag;
          DecodeBuffer(body, @g_hVenationInfos, SizeOf(g_hVenationInfos));
          FrmDlg.HeroPageChanged;
          if g_hVLastSender <> nil then
            FrmDlg.DBhV1Click(g_hVLastSender, 0, 0);
        end;
      end;
{$IFEND SERIESSKILL}
    SM_SETMISSION:
      begin
        if msg.param in [1..4] then
        begin //class
          List := FrmDlg.m_MissionList[msg.param];
          case msg.series of
            1:
              begin //add update
                Str := DecodeString(body);
                //DScreen.AddChatBoardString('SM_SETMISSION:' + IntToStr(msg.param) + ' - ' + Str, clWhite, clBlue);
                i := Pos('title=', Str);
                j := Pos('desc=', Str);
                if (i <= 0) or (j <= 0) then
                  Exit;
                Str2 := Copy(Str, 7, j - 8); //title
                str3 := Copy(Str, j + 5, Length(Str) - j); //desc
                tempb := False;
                List.Lock;
                try
                  for i := 0 to List.count - 1 do
                  begin
                    pMission := List[i];
                    if IntToStr(msg.Recog) = pMission.sindex then
                    begin
                      pMission.sTitle := Str2;
                      pMission.sDesc := str3;
                      tempb := True;
                      Break;
                    end;
                  end;
                finally
                  List.Unlock;
                end;
                if not tempb then
                begin
                  New(pMission);
                  pMission.sindex := IntToStr(msg.Recog);
                  pMission.sTitle := Str2;
                  pMission.sDesc := str3;
                  List.Lock;
                  try
                    List.Add(pMission);
                  finally
                    List.Unlock;
                  end;
                  g_boNewMission := True;
                end;
                if msg.tag <> 0 then
                begin
                  g_boNewMission := False;
                  FrmDlg.ShowMissionDlg(msg.param);
                end;
              end;
            2:
              begin
                List.Lock;
                try
                  for i := 0 to List.count - 1 do
                  begin
                    pMission := List[i];
                    if IntToStr(msg.Recog) = pMission.sindex then
                    begin
                      Dispose(pMission);
                      List.Delete(i);
                      Break;
                    end;
                  end;
                finally
                  List.Unlock;
                end;
              end;
          end;
        end;
      end;
    SM_NEWMAP:
      begin
        g_sMapTitle := '';
        Str := DecodeString(body);
        g_PlayScene.SendMsg(SM_NEWMAP, 0,
          msg.param,
          msg.tag,
          msg.series,
          0, 0,
          Str {mapname});
      end;
    SM_SHELLEXECUTE:
      begin
        // 2019-11-19 第二个参数为99时可以外开，不填或其他为内开
        if msg.Recog <> 99 then
        begin
          with frmWebBrowser do
          begin
            if not Showing then
            begin
              Open(body)
            end;
          end;
        end
        else
        begin
           ShellExecute(Handle, nil, PChar(body), nil, nil, SW_SHOW);
        end;
      end;
    SM_QUERYITEMDLG: ClientGetSendItemDlg(msg.Recog, DecodeString(body));

    SM_QUERYBINDITEM: if msg.param = 0 then
        ClientGetSendBindItem(msg.Recog)
      else
        ClientGetSendUnBindItem(msg.Recog);

    SM_ITEMDLGSELECT:
      begin
        if msg.param = 255 then
          g_SellDlgItem.S.Name := '';
        if msg.Recog = 0 then
          FrmDlg.CloseDSellDlg;
      end;
    SM_SETTARGETXY:
      begin
        //
      end;
    SM_AFFIRMYBDEA_FAIL:
      begin
        case msg.Recog of
          01: FrmDlg.ShowMDlg(0, '', '[成功]: 交易成功！');
          -1: FrmDlg.ShowMDlg(0, '', '[失败]：进行交易失败，请稍候操作！');
          -2: FrmDlg.ShowMDlg(0, '', '[失败]：不存在交易订单，交易失败！');
          -3: FrmDlg.ShowMDlg(0, '', '[失败]：请先进行元宝冲值！');
          -4: FrmDlg.ShowMDlg(0, '', '[失败]：你的背包空位不足，请整理后再进行操作');
          -5: FrmDlg.ShowMDlg(0, '', '[失败]：该订单已超时，你无法收购，只能[取消收购]！');
          -6: FrmDlg.ShowMDlg(0, '', '[失败]：您持有的元宝数不足以收购！');
        else
          FrmDlg.ShowMDlg(0, '', '[失败]：未知错误，交易失败！');
        end;
      end;
    SM_CANCELYBSELL_FAIL:
      begin
        //FrmDlg.DBYbDealItemsCloseClick(nil, 0, 0);
        case msg.Recog of
          01: FrmDlg.ShowMDlg(0, '', '[成功]: 取消交易成功！');
          02: FrmDlg.ShowMDlg(0, '', '[成功]: 取消收购成功！');
          -1: FrmDlg.ShowMDlg(0, '', '[失败]：取消交易失败！');
          -2: FrmDlg.ShowMDlg(0, '', '[失败]：不存在交易订单，取消失败！');
          -3: FrmDlg.ShowMDlg(0, '', '[失败]：你的背包空位不足，请整理后再进行操作！');
          -4: FrmDlg.ShowMDlg(0, '', '[失败]：你没有可以支付的元宝，(你的物品已超期，需要支付1个元宝)');
        else
          FrmDlg.ShowMDlg(0, '', '[失败]：未知错误，取消交易失败！');
        end;
      end;
    SM_QUERYYBSELL_SELL:
      begin
        if (msg.Recog = -1) or (msg.Recog = -2) then
        begin
          FrmDlg.ShowMDlg(0, '', '[失败]: 没有查询到指定的记录！');
        end
        else
        begin
          FrmDlg.ServerSendYBSell(msg.Recog, msg.series, body);
        end;
      end;
    SM_QUERYYBSELL_DEAL:
      begin
        if (msg.Recog = -1) or (msg.Recog = -2) then
        begin
          FrmDlg.ShowMDlg(0, '', '[失败]: 没有查询到指定的记录！');
        end
        else
        begin
          FrmDlg.ServerSendYBDeal(msg.Recog, msg.series, body);
        end;
      end;
    SM_POST_FAIL2:
      begin
        if msg.Recog = 1 then
        begin
          FillChar(g_YbDealItems, SizeOf(g_YbDealItems), #0);
        end
        else
        begin
          FrmDlg.YbDealItemReturnBag();
        end;
        g_boYbDealing := False;
        case msg.Recog of
          01: FrmDlg.ShowMDlg(0, '', '[成功]: 系统已经成功接受您的申请！');
          -1: FrmDlg.ShowMDlg(0, '', '[失败]：您或者对方角色名中含有非法字符！');
          -2: FrmDlg.ShowMDlg(0, '', '[失败]：至少需要一件物品！');
          -3: FrmDlg.ShowMDlg(0, '', '[失败]：上次寄售物品已超过时间限制！');
          -4: FrmDlg.ShowMDlg(0, '', '[失败]：您尚未开通元宝交易系统！');
          -5: FrmDlg.ShowMDlg(0, '', '[失败]：您上次寄售的物品尚未成功交易！');
          -6: FrmDlg.ShowMDlg(0, '', '[失败]：对方已在元宝交易中！');
          -7: FrmDlg.ShowMDlg(0, '', '[失败]：您包裹中没有您要出售的物品！');
          -8: FrmDlg.ShowMDlg(0, '', '[失败]：定单失效，NPC准备未就绪，请重试！');
          -9: FrmDlg.ShowMDlg(0, '', '[失败]：普通交易状态下不能进行元宝买卖！');
          -10: FrmDlg.ShowMDlg(0, '', '[失败]：请输入合理的元宝数量，在0~9999之间！');
          -11: FrmDlg.ShowMDlg(0, '', '[失败]：您没有足够的金刚石，且数量在0~9999之间！');
          -12: FrmDlg.ShowMDlg(0, '', '[失败]：物品数量不正确！');
          -13: FrmDlg.ShowMDlg(0, '', Format('[失败]：%s 禁止寄售！', [DecodeString(body)]));
          -14: FrmDlg.ShowMDlg(0, '', Format('[失败]：%s 已绑定于其他帐号，禁止寄售！', [DecodeString(body)]));
        else
          FrmDlg.ShowMDlg(0, '', '[失败]：未知错误');
        end;
      end;
    SM_OPENDEAL_FAIL:
      begin
        case msg.Recog of
          00: FrmDlg.DMessageDlg('[成功]：成功开启元宝交易系统！', [mbOk]);
          -2: FrmDlg.DMessageDlg('[失败]：请先进行元宝冲值！', [mbOk]);
          -3: FrmDlg.DMessageDlg('[失败]：您已经开启元宝交易系统！', [mbOk]);
          -4: FrmDlg.DMessageDlg('[失败]：您的元宝数量不足开启交易系统！', [mbOk]);
        else
          FrmDlg.DMessageDlg('[失败]：开通元宝交易系统失败！', [mbOk]);
        end;
      end;
    SM_CLOSEBOX:
      begin
        if msg.Recog = 0 then
        begin
          DScreen.AddChatBoardString('至少需要预留六个空位', clWhite, clBlue);
        end
        else
        begin
          g_RareBoxWindow.m_boRareBoxShow := False;
          g_RareBoxWindow.m_boActive := False;
          g_RareBoxWindow.m_boKeyAvail := False;
          FrmDlg.DWBoxBKGnd.Visible := False;
        end;
        g_RareBoxWindow.m_boFlashStart := False;
        g_SndMgr.PlaySound(s_norm_button_click);
      end;
    SM_SELETEBOXFLASH:
      begin
        g_RareBoxWindow.m_boSelBoxFlash := True;
        g_RareBoxWindow.m_nFlashBoxTime := 5;
        g_RareBoxWindow.m_btSvrItemIdx := msg.Recog;
        g_RareBoxWindow.m_nFlashBoxCount := 0;
        g_RareBoxWindow.m_boFlashStart := False;
      end;
    SM_OPENBOX: if g_RareBoxWindow.m_boKeyAvail or (msg.param = 1) then
      begin
        //DScreen.AddChatBoardString(IntToStr(Msg.param), clWhite, clBlue);
        FrmDlg.DWBoxBKGnd.Visible := True;
        DecodeBuffer(body, @g_RareBoxWindow.m_BoxItems, SizeOf(TBoxItems));
        if g_OpenBoxItem.Item.S.Name <> '' then
          g_OpenBoxItem.Item.S.Name := '';
        if g_WaitingUseItem.Item.S.Name <> '' then
          g_WaitingUseItem.Item.S.Name := '';
        g_RareBoxWindow.m_btItemIdx := 9;
        g_RareBoxWindow.m_btSvrItemIdx := 0;
        g_RareBoxWindow.m_btFlashIdx := 0;
        g_RareBoxWindow.m_boFlashStart := False;
        g_RareBoxWindow.m_boSelBoxFlash := False;
        if not g_RareBoxWindow.m_boActive then
          if msg.param = 1 then
          begin
            g_RareBoxWindow.SetActive(6);
          end
          else
            g_RareBoxWindow.SetActive(g_OpenBoxItem.Item.S.Shape);
      end;
    SM_OPENBOX_FAIL:
      begin
        case msg.Recog of
          2: DScreen.AddChatBoardString('宝箱与钥匙类型不匹配', clWhite, clBlue);
          3: DScreen.AddChatBoardString('至少需要预留六个空位', clWhite, clBlue);
        end;
        if g_OpenBoxItem.Item.S.Name <> '' then
        begin
          AddItemBag(g_OpenBoxItem.Item, g_OpenBoxItem.Index);
          DScreen.AddSysMsg(g_OpenBoxItem.Item.S.Name + '被发现');
          g_OpenBoxItem.Item.S.Name := '';
        end;
        if g_WaitingUseItem.Item.S.Name <> '' then
        begin
          AddItemBag(g_WaitingUseItem.Item, g_WaitingUseItem.Index);
          DScreen.AddSysMsg(g_WaitingUseItem.Item.S.Name + '被发现');
          g_WaitingUseItem.Item.S.Name := '';
        end;
        g_RareBoxWindow.m_boKeyAvail := False;
        FrmDlg.DWBoxBKGnd.Visible := False;
      end;
    SM_BOOK:
      begin
        ClientOpenBook(msg, body);
      end;
    SM_LEVELRANK:
      begin
        g_boDrawLevelRank := False;
        FrmDlg.m_nLevelRankType := msg.param;
        if msg.Recog >= 0 then
        begin //reture page
          if FrmDlg.m_nLevelRankPage <> msg.Recog then
            FrmDlg.m_nLevelRankPage := msg.Recog;
          case msg.param of
            0..3:
              begin
                DecodeBuffer(body, @g_HumanLevelRanks, SizeOf(THumanLevelRanks));
                FrmDlg.DBLRFirst.Visible := True;
                FrmDlg.DBLRPrior.Visible := True;
                FrmDlg.DBLRNext.Visible := True;
                FrmDlg.DBLRLast.Visible := True;
                FrmDlg.DBLRMyRank.Visible := True;
                g_boDrawLevelRank := True;
              end;
            4..7:
              begin
                DecodeBuffer(body, @g_HeroLevelRanks, SizeOf(THeroLevelRanks));
                FrmDlg.DBLRFirst.Visible := True;
                FrmDlg.DBLRPrior.Visible := True;
                FrmDlg.DBLRNext.Visible := True;
                FrmDlg.DBLRLast.Visible := True;
                FrmDlg.DBLRMyRank.Visible := True;
                g_boDrawLevelRank := True;
              end;
          end;
        end
        else
        begin
          case msg.param of //reture type
            0..3: FrmDlg.DMessageDlg('[提示]: 你在该版没有排名', [mbOk]);
            4..7: FrmDlg.DMessageDlg('[提示]: 你的英雄在该版没有排名', [mbOk]);
          end;
        end;
      end;
    SM_HEROSPELL:
      begin
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          //UseMagicSpell(Msg.Recog, 74, Msg.param, Msg.tag, 74);
          g_PlayScene.NewMagic(Actor, 74, 74,
            Actor.m_nCurrX, Actor.m_nCurrY,
            msg.param, msg.tag,
            msg.Recog, mtBujaukGroundEffect, False, 60, tempb);
          g_SndMgr.PlaySound('Wav\splitshadow.wav');
        end;
      end;
    SM_SQUAREPOWERUP:
      begin
        g_nSquHitPoint := msg.param;
        if g_nMaxSquHitPoint <> msg.Recog then
          g_nMaxSquHitPoint := msg.Recog;
        if g_nSquHitPoint > g_nMaxSquHitPoint then
          g_nSquHitPoint := g_nMaxSquHitPoint;
      end;
    SM_STRUCKEFFECT:
      begin
        nad := Str_ToInt(body, 0);
        if (nad > 0) and (nad > msg.tag) then
          DrawEffectHumEx(msg.Recog, msg.param, nad)
        else
          DrawEffectHumEx(msg.Recog, msg.param, msg.tag);
      end;
    SM_FIREWORKS: DrawEffectHum(msg.param, msg.tag, msg.series);
    SM_BUGITEMFAIL:
      begin
        case msg.Recog of
          00: FrmDlg.DMessageDlg('[失败]: 非法物品名', [mbOk]);
          -1: FrmDlg.DMessageDlg('[失败]: 不存在你想购买的物品', [mbOk]);
          -2: FrmDlg.DMessageDlg('[失败]: 请先进行元宝冲值', [mbOk]);
          -3: FrmDlg.DMessageDlg('[失败]: 你帐号中的元宝数不够', [mbOk]);
          -4: FrmDlg.DMessageDlg('[失败]：你无法携带更多的物品', [mbOk]);
          -5: FrmDlg.DMessageDlg('[失败]：购买物品不在商城中', [mbOk]);
          -6: FrmDlg.DMessageDlg('[失败]: 您的购买速度过快', [mbOk]);
        else
          FrmDlg.DMessageDlg('[失败]: 你无法购买', [mbOk]);
        end;
      end;
    SM_PRESENDITEMFAIL:
      begin
        if msg.tag = 0 then
        begin
          case msg.Recog of
            01: FrmDlg.DMessageDlg('[成功]: 对方已经收到你的礼物', [mbOk]);
            00: FrmDlg.DMessageDlg('[失败]: 非法的物品名称', [mbOk]);
            -1: FrmDlg.DMessageDlg('[失败]: 抱歉, 服务器不存在你想购买赠送的物品', [mbOk]);
            -2: FrmDlg.DMessageDlg('[失败]: 请先进行元宝冲值', [mbOk]);
            -3: FrmDlg.DMessageDlg('[失败]: 你帐号中的元宝数不够', [mbOk]);
            -4: FrmDlg.DMessageDlg('[失败]：赠送人无法携带更多的物品', [mbOk]);
            -5: FrmDlg.DMessageDlg('[失败]：你想购买物品不在商城中', [mbOk]);
            -6: FrmDlg.DMessageDlg('[失败]: 您的购买速度过快', [mbOk]);
            -7: FrmDlg.DMessageDlg('[失败]: 赠送人不存在或不在线', [mbOk]);
            -8: FrmDlg.DMessageDlg('[失败]: 赠送人不能是自己', [mbOk]);
            -9: FrmDlg.DMessageDlg('[失败]: 服务器未开启赠送功能', [mbOk]);
          else
            FrmDlg.DMessageDlg('[失败]: 你无法购买', [mbOk]);
          end;
        end
        else
        begin
          case msg.Recog of
            01: FrmDlg.DMessageDlg('[成功]: 对方已经收到你的礼物', [mbOk]);
            00: FrmDlg.DMessageDlg('[失败]: 非法的物品名称', [mbOk]);
            -1: FrmDlg.DMessageDlg('[失败]: 抱歉, 服务器不存在你想购买赠送的物品', [mbOk]);
            -2: FrmDlg.DMessageDlg('[失败]: 你没有金币', [mbOk]);
            -3: FrmDlg.DMessageDlg('[失败]: 你帐的金币数不够', [mbOk]);
            -4: FrmDlg.DMessageDlg('[失败]：赠送人无法携带更多的物品', [mbOk]);
            -5: FrmDlg.DMessageDlg('[失败]：你想购买物品不在商城中', [mbOk]);
            -6: FrmDlg.DMessageDlg('[失败]: 您的购买速度过快', [mbOk]);
            -7: FrmDlg.DMessageDlg('[失败]: 赠送人不存在或不在线', [mbOk]);
            -8: FrmDlg.DMessageDlg('[失败]: 赠送人不能是自己', [mbOk]);
            -9: FrmDlg.DMessageDlg('[失败]: 服务器未开启赠送功能', [mbOk]);
          else
            FrmDlg.DMessageDlg('[失败]: 你无法购买', [mbOk]);
          end;
        end;
      end;
    SM_LOGON:
      begin
        g_dwFirstServerTime := 0;
        g_dwFirstClientTime := 0;
        with msg do
        begin
          DecodeBuffer(body, @wl, SizeOf(TMessageBodyWL));
          setlength(FeatureMsg,wl.lParam1);
          DecodeBuffer(copy(body, GetCodeMsgSize(SizeOf(TMessageBodyWL) * 4 / 3) + 1, GetCodeMsgSize(wl.lParam1 * 4 / 3 )),@FeatureMsg[1], wl.lParam1);
          g_PlayScene.SendMsg(SM_LOGON, msg.Recog,
            msg.param {x},
            msg.tag {y},
            msg.series {dir},
            wl.lParam1, //desc.Feature,
            wl.lParam2, //desc.Status,
            FeatureMsg);
          DScreen.ChangeScene(stPlayGame);
          SendClientMessage(CM_WANTVIEWRANGE, Makelong(g_TileMapOffSetX, g_TileMapOffSetY), 0, 0, 0);
          if not g_boDoFadeOut and not g_boDoFadeIn then
          begin
            //g_boDoFadeOut := True;
            g_boDoFadeIn := True;
            g_nFadeIndex := 10;
          end;
          SendClientMessage(CM_QUERYBAGITEMS, 1, 0, 0, 0);
          if LoByte(LoWord(wl.lTag1)) = 1 then
            g_boAllowGroup := True
          else
            g_boAllowGroup := False;
          g_boServerChanging := False;
        end;
        if g_wAvailIDDay > 0 then
        begin
          DScreen.AddChatBoardString('您当前通过包月帐号充值', GetRGB(219), clWhite)
        end
        else if g_wAvailIPDay > 0 then
        begin
          DScreen.AddChatBoardString('您当前通过包月IP 充值', GetRGB(219), clWhite)
        end
        else if g_wAvailIPHour > 0 then
        begin
          DScreen.AddChatBoardString('您当前通过计时IP 充值', GetRGB(219), clWhite)
        end
        else if g_wAvailIDHour > 0 then
        begin
          DScreen.AddChatBoardString('您当前通过计时帐号充值', GetRGB(219), clWhite)
        end;
        LoadUserConfig(m_sCharName);
        FrmDlg.LoadMySelfConfig();
        FrmDlg.LoadBeltConfig();
        LoadItemFilter2();

        //DScreen.AddChatBoardString(intToStr(g_MySelf.m_nRecogId), GetRGB(219), clWhite);
        SendClientMessage(CM_HIDEDEATHBODY, g_MySelf.m_nRecogId, Integer(g_gcGeneral[8]), 0, 0);

        if not g_gcGeneral[11] then
        begin
          DScreen.AddChatBoardString('[游戏声音已关闭]', clWhite, clblack);
        end;
        //g_ModuleDetect.FCheckTick
      end;
    SM_SERVERCONFIG: ClientGetServerConfig(msg, body);
    SM_SERVERCONFIG2:
      begin
{$I '..\Common\Macros\VMPBM.inc'}
        DecodeBuffer(DecodeString(body), @svrcfg, SizeOf(svrcfg));
        g_boAutoSay := svrcfg.AutoSay;
        g_boMutiHero := svrcfg.Reserved[0] <> 0;
        g_boSkill_114_MP := svrcfg.Reserved[1] <> 0;
        g_boSkill_68_MP := svrcfg.Reserved[2] <> 0;
        g_boUI0508 := svrcfg.Reserved[3] <> 0;
        g_boFindpathMyMap := Svrcfg.Reserved[4] <> 0;
        ReInitUserSateUI();
        FrmDlg.DBAotoSay.Visible := g_boAutoSay;

        if msg.series > 200 then
          g_nEatItemInvTime := msg.series;

        g_boForceNotViewFog := HiByte(msg.param) <> 0;
        g_boOpenStallSystem := LoByte(msg.param) <> 0;

        g_boAutoLongAttack := {$IF CONFIGTEST}True{$ELSE}LoByte(msg.tag) <> 0{$IFEND};

        g_boHero := {$IF CONFIGTEST}True{$ELSE}HiByte(msg.tag) <> 0{$IFEND};
        if g_boHero then
        begin
          FrmDlg.DBAttackMode.Top := 126;
          BOTTOMBOARD800 := 371;
        end
        else
        begin

          FrmDlg.DBAttackMode.Top := 113;
          BOTTOMBOARD800 := 291;
          if g_BuildBotTex = 0 then
          begin
            g_BuildBotTex := 1;
            //FrmDlg.BuildBottomWinSurface(False);
          end;
        end;

        if g_boHero then
        begin
          FrmDlg.DButtonRecallHero.Visible := True;
          FrmDlg.DButtonHeroState.Visible := True;
          FrmDlg.DButtonHeroBag.Visible := True;
          FrmDlg.DBAttackMode.Top := 126;
          BOTTOMBOARD800 := 371;

          {FrmDlg.DxEditRenewHPPercentHero.Visible := True;
          FrmDlg.DxEditRenewMPPercentHero.Visible := True;
          FrmDlg.DxEditRenewSpecialPercentHero.Visible := True;
          FrmDlg.DxEditPerHeroSidestep.Visible := True;

          FrmDlg.DxEditRenewHPTimeHero.Visible := True;
          FrmDlg.DxEditRenewMPTimeHero.Visible := True;
          FrmDlg.DxEditRenewSpecialTimeHero.Visible := True;

          FrmDlg.DEHeroCallHeroPre.Visible := True;
          FrmDlg.DEHeroSetTargetPre.Visible := True;
          FrmDlg.DEHeroUnionHitPre.Visible := True;
          FrmDlg.DEHeroSetAttackStatePre.Visible := True;
          FrmDlg.DEHeroSetGuardPre.Visible := True;

          FrmDlg.DEHeroCallHero.Visible := True;
          FrmDlg.DEHeroSetTarget.Visible := True;
          FrmDlg.DEHeroUnionHit.Visible := True;
          FrmDlg.DEHeroSetAttackState.Visible := True;
          FrmDlg.DEHeroSetGuard.Visible := True;}

        end
        else
        begin
          FrmDlg.DBAttackMode.Top := 113;
          FrmDlg.DButtonRecallHero.Visible := False;
          FrmDlg.DButtonHeroState.Visible := False;
          FrmDlg.DButtonHeroBag.Visible := False;
          BOTTOMBOARD800 := 291;

          FrmDlg.DxEditRenewHPPercentHero.Visible := False;
          FrmDlg.DxEditRenewMPPercentHero.Visible := False;
          FrmDlg.DxEditRenewSpecialPercentHero.Visible := False;
          FrmDlg.DxEditPerHeroSidestep.Visible := False;

          FrmDlg.DxEditRenewHPTimeHero.Visible := False;
          FrmDlg.DxEditRenewMPTimeHero.Visible := False;
          FrmDlg.DxEditRenewSpecialTimeHero.Visible := False;

          FrmDlg.DEHeroCallHeroPre.Visible := False;
          FrmDlg.DEHeroSetTargetPre.Visible := False;
          FrmDlg.DEHeroUnionHitPre.Visible := False;
          FrmDlg.DEHeroSetAttackStatePre.Visible := False;
          FrmDlg.DEHeroSetGuardPre.Visible := False;

          FrmDlg.DEHeroCallHero.Visible := False;
          FrmDlg.DEHeroSetTarget.Visible := False;
          FrmDlg.DEHeroUnionHit.Visible := False;
          FrmDlg.DEHeroSetAttackState.Visible := False;
          FrmDlg.DEHeroSetGuard.Visible := False;
        end;
        FrmDlg.BuildBottomWinSurface(g_boHero);
        if not g_boAutoLongAttack then
          g_gcTec[10] := False;

        FrmDlg.DBotStore.Visible := g_boOpenStallSystem;
{$I '..\Common\Macros\VMPE.inc'}
        //DScreen.AddChatBoardString('g_nEatIteminvTime ' + IntToStr(msg.series), GetRGB(219), clWhite)
      end;
    SM_SERVERCONFIG3:
      begin
{$IF CONFIGTEST}
        g_boSpeedRate := True;
        g_boSpeedRateShow := g_boSpeedRate;
{$ELSE}
        if (LoByte(msg.series) > 0) then
        begin
          g_boSpeedRate := True;
          g_boSpeedRateShow := False;
          g_HitSpeedRate := _MIN(68, LoByte(msg.param));
          g_MagSpeedRate := _MIN(68, HiByte(msg.param));
          g_MoveSpeedRate := _MIN(68, LoByte(msg.tag));
        end;
{$IFEND CONFIGTEST}
        //g_NewHint := HiByte(msg.tag) = 0;

        //DScreen.AddChatBoardString('h ' + IntToStr(g_HitSpeedRate) + ' s ' + IntToStr(g_MagSpeedRate) + ' m ' + IntToStr(g_MoveSpeedRate), GetRGB(219), clWhite);
      end;
    SM_RUNHUMAN: g_boCanRunHuman := msg.Recog <> 0;
    SM_INSAFEZONEFLAG: g_boCanRunSafeZone := msg.Recog <> 0;
    SM_RECONNECT: ClientGetReconnect(body);
    SM_TIMECHECK_MSG: CheckSpeedHack(msg.Recog);
    SM_AREASTATE: g_nAreaStateValue := msg.Recog;
    SM_MAPDESCRIPTION: ClientGetMapDescription(msg, body);
    SM_GAMEGOLDNAME: ClientGetGameGoldName(msg, body);
    SM_ADJUST_BONUS: ClientGetAdjustBonus(msg.Recog, body);
    SM_MYSTATUS: g_nMyHungryState := msg.param;
    SM_TURN:
      begin
        DecodeBuffer(body, @desc2, SizeOf(TCharDesc));
        Setlength(FeatureMsg,desc2.FeatureLen);
        DecodeBuffer(copy(body, GetCodeMsgSize(SizeOf(TCharDesc) * 4 / 3) + 1, GetCodeMsgSize(desc2.FeatureLen * 4 / 3)), @FeatureMsg[1],desc2.FeatureLen);
        n := GetCodeMsgSize((SizeOf(TCharDesc) + desc2.FeatureLen) * 4 / 3);
        // n := GetCodeMsgSize(SizeOf(TCharDesc) * 4 / 3);
        if Length(body) > n then
        begin
          body2 := Copy(body, n + 1, Length(body));
          data := DecodeString(body2);
          body2 := Copy(body, 1, n);
          Str := GetValidStr3(data, data, ['/']);
        end
        else
        begin
          body2 := body;
          data := '';
        end;
        DecodeBuffer(body2, @desc, SizeOf(TCharDesc));
        g_PlayScene.SendMsg(SM_TURN, msg.Recog,
          msg.param {x},
          msg.tag {y},
          msg.series {dir + light},
          desc.FeatureLen,
          desc.Status,
          FeatureMsg, desc.StatusEx);
        if data <> '' then
        begin
          Actor := g_PlayScene.FindActor(msg.Recog);
          if Actor <> nil then
          begin
            Actor.m_sDescUserName := GetValidStr3(data, Actor.m_sUserName, ['\']);
            Actor.m_sUserNameOffSet := TextWidthA(Actor.m_sUserName, False) div 2;
            if Pos('(', Actor.m_sUserName) <> 0 then
            begin
              ArrestStringEx(Actor.m_sUserName, '(', ')', data);
              //DScreen.AddChatBoardString(data, clWhite, clRed);
              if data = g_MySelf.m_sUserName then
              begin
                j := 0;
                for i := 0 to g_MySelf.m_SlaveObject.count - 1 do
                begin
                  if TActor(g_MySelf.m_SlaveObject[i]) = Actor then
                  begin
                    j := 1;
                    Break;
                  end;
                end;
                if j = 0 then
                  g_MySelf.m_SlaveObject.Add(Actor);
                //if g_MySelf.m_SlaveObject <> Actor then
                //  g_MySelf.m_SlaveObject := Actor;
              end;
            end;
            Actor.m_btNameColor := Str_ToInt(Str, 0);
            if Actor.m_btRace = RCC_MERCHANT then
              Actor.m_nNameColor := clLime
            else
              Actor.m_nNameColor := GetRGB(Actor.m_btNameColor);
          end;
        end;
      end;
    SM_FOXSTATE: ClientGetFoxState(msg, body);
    SM_BACKSTEP:
      begin
        n := GetCodeMsgSize(SizeOf(TCharDesc) * 4 / 3);
        if Length(body) > n then
        begin
          body2 := Copy(body, n + 1, Length(body));
          data := DecodeString(body2);
          body2 := Copy(body, 1, n);
          Str := GetValidStr3(data, data, ['/']);
        end
        else
        begin
          body2 := body;
          data := '';
        end;
        DecodeBuffer(body2, @desc, SizeOf(TCharDesc));
        g_PlayScene.SendMsg(SM_BACKSTEP, msg.Recog,
          msg.param {x},
          msg.tag {y},
          msg.series {dir + light},
          desc.FeatureLen,
          desc.Status,
          '', desc.StatusEx);
        if data <> '' then
        begin
          Actor := g_PlayScene.FindActor(msg.Recog);
          if Actor <> nil then
          begin
            Actor.m_sDescUserName := GetValidStr3(data, Actor.m_sUserName, ['\']);
            Actor.m_sUserNameOffSet := TextWidthA(Actor.m_sUserName, False) div 2;
            Actor.m_btNameColor := Str_ToInt(Str, 0);
            if Actor.m_btRace = RCC_MERCHANT then
              Actor.m_nNameColor := clLime
            else
              Actor.m_nNameColor := GetRGB(Actor.m_btNameColor);
          end;
        end;
      end;
    SM_SPACEMOVE_HIDE, SM_SPACEMOVE_HIDE2:
      if msg.Recog <> g_MySelf.m_nRecogId then g_PlayScene.SendMsg(msg.ident, msg.Recog, msg.param {x}, msg.tag {y}, 0, 0, 0, '');
    SM_HEROLOGIN:
      begin
        {
        DecodeBuffer(body, @wl, Sizeof(TMessageBodyW));
        SetLength(FeatureMsg, wl.lparam1);
        DecodeBuffer(copy(body, GetCodeMsgSize(Sizeof(TMessageBodyW) * 4 / 3) + 1, Length(Body)), @FeatureMsg[1], wl.lparam1);
        if FeatureMsg <> '' then Actor.m_nFeature := FeatureMsg;    }
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          if Actor.m_btIsHero <> 1 then
            Actor.m_btIsHero := 2;
        end;
        DrawEffectHum(84, msg.param, msg.tag);
      end;
    SM_HEROLOGOUT: DrawEffectHum(85, msg.param, msg.tag);

    SM_SPACEMOVE_SHOW, SM_SPACEMOVE_SHOW2:
      begin
        DecodeBuffer(body, @desc2, SizeOf(TCharDesc));
        Setlength(FeatureMsg,desc2.FeatureLen );
        DecodeBuffer(copy(body, GetCodeMsgSize(SizeOf(TCharDesc) * 4 / 3) + 1, GetCodeMsgSize(desc2.FeatureLen * 4 / 3)), @FeatureMsg[1], Desc2.FeatureLen);
        n := GetCodeMsgSize((SizeOf(TCharDesc) + desc2.FeatureLen) * 4 / 3);
        // n := GetCodeMsgSize(SizeOf(TCharDesc) * 4 / 3);
        if Length(body) > n then
        begin
          // body2 := Copy(body, n + 1, Length(body));
          body2 := Copy(body, n + 1, Length(body));
          data := DecodeString(body2);
          body2 := Copy(body, 1, n);
          Str := GetValidStr3(data, data, ['/']);
        end
        else
        begin
          body2 := body;
          data := '';
        end;

        //DScreen.AddChatBoardString(body, clWhite, clRed);
        DecodeBuffer(body2, @desc, SizeOf(TCharDesc));
        if (msg.Recog <> g_MySelf.m_nRecogId) then
          g_PlayScene.NewActor(msg.Recog, msg.param, msg.tag, msg.series, FeatureMsg, desc.Status);
          //g_PlayScene.NewActor(msg.Recog, msg.param, msg.tag, msg.series, desc.FeatureLen, desc.Status);
        g_PlayScene.SendMsg(msg.ident, msg.Recog,
          msg.param {x},
          msg.tag {y},
          msg.series {dir + light},
          desc2.FeatureLen,
          desc.Status,
          FeatureMsg , desc.StatusEx);
        if data <> '' then
        begin
          Actor := g_PlayScene.FindActor(msg.Recog);
          if Actor <> nil then
          begin
            Actor.m_sDescUserName := GetValidStr3(data, Actor.m_sUserName, ['\']);
            Actor.m_sUserNameOffSet := TextWidthA(Actor.m_sUserName, False) div 2;
            Actor.m_btNameColor := Str_ToInt(Str, 0);
            if Actor.m_btRace = RCC_MERCHANT then
              Actor.m_nNameColor := clLime
            else
              Actor.m_nNameColor := GetRGB(Actor.m_btNameColor);
          end;
        end;
      end;

    SM_RUSH, SM_RUSHEX, SM_RUSHKUNG:
      begin
        DecodeBuffer(body, @desc, SizeOf(TCharDesc));
        if msg.Recog = g_MySelf.m_nRecogId then
        begin
          g_PlayScene.SendMsg(msg.ident, msg.Recog,
            msg.param {x},
            msg.tag {y},
            msg.series {dir+light},
            desc.FeatureLen,
            desc.Status, '', desc.StatusEx);
        end
        else
          g_PlayScene.SendMsg(msg.ident, msg.Recog,
            msg.param {x},
            msg.tag {y},
            msg.series {dir+light},
            desc.FeatureLen,
            desc.Status, '', desc.StatusEx);
        if (msg.ident = SM_RUSH) then
          g_dwLatestRushRushTick := GetTickCount;
      end;

    SM_WALK, SM_RUN, SM_HORSERUN:
      begin
        DecodeBuffer(body, @desc, SizeOf(TCharDesc));
        if msg.Recog <> g_MySelf.m_nRecogId then
          g_PlayScene.SendMsg(msg.ident, msg.Recog,
            msg.param {x},
            msg.tag {y},
            msg.series {dir+light},
            desc.FeatureLen,
            desc.Status, '', desc.StatusEx);
      end;

    SM_CHANGELIGHT:
      begin
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
          Actor.m_nChrLight := msg.param;
      end;

    SM_LAMPCHANGEDURA: if g_UseItems[U_RIGHTHAND].S.Name <> '' then
        g_UseItems[U_RIGHTHAND].Dura := msg.Recog;
    SM_HEROLAMPCHANGEDURA: if g_HeroUseItems[U_RIGHTHAND].S.Name <> '' then
        g_HeroUseItems[U_RIGHTHAND].Dura := msg.Recog;

    SM_MOVEFAIL:
      begin
        ActionFailed;
        ActionLock := False;
        frmMain.RecalcAutoMovePath();
        DecodeBuffer(body, @desc, SizeOf(TCharDesc));
        ActionFailLock := False;
        g_PlayScene.SendMsg(SM_TURN, msg.Recog,
          msg.param {x},
          msg.tag {y},
          msg.series {dir},
          desc.FeatureLen,
          desc.Status, '', desc.StatusEx);
      end;
    RM_SPELLFAIL:
      begin
        g_Myself.CleanUserMsgs;
        g_Myself.m_nCurrentAction := 0;
        g_Myself.m_boLockEndFrame := False;
        ActionFailLock := True;
        ActionFailLockTime := GetTickCount();
        ActionFailLock := False;
      end;
      
    SM_BUTCH:
      begin
        DecodeBuffer(body, @desc, SizeOf(TCharDesc));
        if msg.Recog <> g_MySelf.m_nRecogId then
        begin
          Actor := g_PlayScene.FindActor(msg.Recog);
          if Actor <> nil then
          begin
            Actor.SendMsg(SM_SITDOWN,
              msg.param {x},
              msg.tag {y},
              msg.series {dir},
              '', 0, '', 0);
            if msg.ident = SM_SITDOWN then
              if body <> '' then
                Actor.m_boDigFragment := True;
          end;
        end;
      end;
    SM_SITDOWN:
      begin
        DecodeBuffer(body, @desc, SizeOf(TCharDesc));
        if msg.Recog <> g_MySelf.m_nRecogId then
        begin
          Actor := g_PlayScene.FindActor(msg.Recog);
          if Actor <> nil then
          begin
            Actor.SendMsg(SM_SITDOWN,
              msg.param {x},
              msg.tag {y},
              msg.series {dir},
              '', 0, '', 0);
            if msg.ident = SM_SITDOWN then
              if body <> '' then
                Actor.m_boDigFragment := True;
          end;
        end;
      end;

    SM_HIT,
      SM_HEAVYHIT,
      SM_POWERHIT,
      SM_LONGHIT,
      SM_SQUHIT,
      SM_CRSHIT,
      SM_TWNHIT,
      SM_WIDEHIT,
      SM_BIGHIT,
      SM_FIREHIT,
      SM_PURSUEHIT,
      SM_HERO_LONGHIT,
      SM_HERO_LONGHIT2,
      SM_SMITEHIT,
      SM_SMITELONGHIT,
      SM_SMITELONGHIT2,
      SM_SMITELONGHIT3,
      SM_SMITEWIDEHIT,
      SM_SMITEWIDEHIT2:
      begin
        //DScreen.AddChatBoardString(IntToStr(Msg.ident), clWhite, clRed);
        if msg.Recog <> g_MySelf.m_nRecogId then
        begin
          Actor := g_PlayScene.FindActor(msg.Recog);
          if Actor <> nil then
          begin
            Actor.SendMsg(msg.ident,
              msg.param {x},
              msg.tag {y},
              msg.series {dir},
              '',
              0,
              body,
              0);
            if msg.ident = SM_HEAVYHIT then
              if body <> '' then
                Actor.m_boDigFragment := True;
          end;
        end;
      end;
    SM_WWJATTACK, SM_WSJATTACK, SM_WTJATTACK:
      begin
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          //if Actor.m_nCurrentAction <> 0 then Actor.m_nCurrentAction := 0;   /////////
          Actor.SendMsg(msg.ident,
            msg.param {x},
            msg.tag {y},
            msg.series {dir},
            '', 0, '',
            0);
        end;
      end;
    SM_FLYAXE, SM_81, SM_82, SM_83:
      begin
        DecodeBuffer(body, @mbw, SizeOf(TMessageBodyW));
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          Actor.SendMsg(msg.ident,
            msg.param {x},
            msg.tag {y},
            msg.series {dir},
            '', 0, '',
            0);
          Actor.m_nTargetX := mbw.Param1; //x 带瘤绰 格钎
          Actor.m_nTargetY := mbw.Param2; //y
          Actor.m_nTargetRecog := Makelong(mbw.Tag1, mbw.Tag2);
        end;
      end;

    SM_LIGHTING, SM_LIGHTING_1..SM_LIGHTING_3:
      begin
        DecodeBuffer(body, @wl, SizeOf(TMessageBodyWL));
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          Actor.SendMsg(msg.ident,
            msg.param {x},
            msg.tag {y},
            msg.series {dir},
            '', 0, '',
            0);
          Actor.m_nTargetX := wl.lParam1; //x 带瘤绰 格钎
          Actor.m_nTargetY := wl.lParam2; //y
          Actor.m_nTargetRecog := wl.lTag1;
          Actor.m_nMagicNum := wl.lTag2; //付过 锅龋
        end;
      end;

    SM_SPELL:
      begin
        UseMagicSpell(msg.Recog {who}, msg.series {effectnum}, msg.param {tx}, msg.tag {y}, Str_ToInt(body, 0));
      end;
    SM_MAGICFIRE:
      begin
        DecodeBuffer(body, @desc, SizeOf(TCharDesc));
        UseMagicFire(msg.Recog {who},
          LoByte(msg.series) {efftype},
          HiByte(msg.series) {effnum},
          msg.param {tx},
          msg.tag {y},
          desc.FeatureLen {taget},
          desc.Status {lv});
      end;
    SM_MAGICFIRE_FAIL: UseMagicFireFail(msg.Recog {who});
    SM_OUTOFCONNECTION:
      begin
        g_boDoFastFadeOut := False;
        g_boDoFadeIn := False;
        g_boDoFadeOut := False;
        FrmDlg.DMessageDlg('服务器连接被强行中断。\连接时间可能超过限制', [mbOk]);
        Close;
      end;
    SM_DEATH, SM_NOWDEATH:
      begin
        DecodeBuffer(body, @desc, SizeOf(TCharDesc));
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          Actor.SendMsg(msg.ident,
            msg.param {x}, msg.tag {y}, msg.series {dir},
            '', desc.Status, '',
            0);
          Actor.m_Abil.HP := 0;
          Actor.m_nIPower := -1;
        end
        else
        begin
          g_PlayScene.SendMsg(SM_DEATH, msg.Recog, msg.param {x}, msg.tag {y}, msg.series {dir}, desc.FeatureLen, desc.Status, '', desc.StatusEx);
        end;
      end;
    SM_SKELETON:
      begin
        DecodeBuffer(body, @desc, SizeOf(TCharDesc));
        Setlength(FeatureMsg,desc.FeatureLen);
        DecodeBuffer(copy(body, GetcodeMsgSize(SizeOf(TCharDesc) * 4 / 3) + 1, length(body)),@FeatureMsg[1], desc.FeatureLen);
        g_PlayScene.SendMsg(SM_SKELETON, msg.Recog, msg.param {HP}, msg.tag {maxHP}, msg.series {damage}, desc.FeatureLen, desc.Status, FeatureMsg, desc.StatusEx);
      end;
    SM_ALIVE:
      begin
        DecodeBuffer(body, @desc, SizeOf(TCharDesc));
        Setlength(FeatureMsg,desc.FeatureLen);
        DecodeBuffer(copy(body, GetCodeMsgSize(SizeOf(TCharDesc) * 4 / 3) + 1, Length(Body)),@FeatureMsg[1], desc.FeatureLen);
        g_PlayScene.SendMsg(SM_ALIVE, msg.Recog, msg.param {HP}, msg.tag {maxHP}, msg.series {damage}, desc.FeatureLen, desc.Status, FeatureMsg, desc.StatusEx);
      end;
    SM_ABILITY:
      begin
        g_MySelf.m_nGold := msg.Recog;
        g_MySelf.m_btJob := LoByte(msg.param);
        g_MySelf.m_nIPowerLvl := HiByte(msg.param);
        g_MySelf.m_nGameGold := Makelong(msg.tag, msg.series);
        DecodeBuffer(body, @g_MySelf.m_Abil, SizeOf(TAbility));
      end;
    SM_SUBABILITY:
      begin
        g_nMyHitPoint := LoByte(msg.param);
        g_nMySpeedPoint := HiByte(msg.param);
        g_nMyAntiPoison := LoByte(msg.tag);
        g_nMyPoisonRecover := HiByte(msg.tag);
        g_nMyHealthRecover := LoByte(msg.series);
        g_nMySpellRecover := HiByte(msg.series);
        g_nMyAntiMagic := LoByte(LoWord(msg.Recog));
        g_nMyIPowerRecover := HiByte(LoWord(msg.Recog));
        g_nMyAddDamage := LoByte(HiWord(msg.Recog));
        g_nMyDecDamage := HiByte(HiWord(msg.Recog));
        //g_nMyIPowerRecover := HiWord(LongWord(msg.Recog));

      end;
    SM_REFDIAMOND:
      begin
        g_MySelf.m_nGameDiamd := (msg.Recog);
        g_MySelf.m_nGameGird := (msg.param);
      end;
    SM_DAYCHANGING:
      begin
        g_nDayBright := msg.param;
{$IF VIEWFOG}
        DarkLevel := msg.tag;
{$ELSE}
        DarkLevel := 0;
{$IFEND VIEWFOG}
        if g_boForceNotViewFog then
          DarkLevel := 0;
        if DarkLevel = 0 then
          g_boViewFog := False
        else
          g_boViewFog := True;
      end;
    SM_INTERNALPOWER:
      begin
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
          Actor.m_nIPower := msg.param;
      end;
    SM_WINEXP:
      begin
        g_MySelf.m_Abil.Exp := msg.Recog;
        if not g_gcGeneral[3] or (LongWord(Makelong(msg.param, msg.tag)) > g_MaxExpFilter) then
          DScreen.AddSysMsgBottom(Format('经验值 +%d', [LongWord(Makelong(msg.param, msg.tag))]));
        //DScreen.AddChatBoardString(Format('%d经验值增加', [LongWord(MakeLong(msg.param, msg.tag))]), clWhite, clRed);
      end;
    SM_HEROWINEXP:
      begin
        if g_MySelf.m_HeroObject <> nil then
        begin
          g_MySelf.m_HeroObject.m_Abil.Exp := msg.Recog;
          if not g_gcGeneral[3] or (LongWord(Makelong(msg.param, msg.tag)) > g_MaxExpFilter) then
            DScreen.AddSysMsgBottom(Format('(英雄)经验值 +%d', [LongWord(Makelong(msg.param, msg.tag))]));
          //DScreen.AddChatBoardString(Format('%d英雄经验值增加', [LongWord(MakeLong(msg.param, msg.tag))]), clWhite, clRed);
        end;
      end;
    SM_WINNIMBUSEXP:
      begin
        if msg.Recog > 0 then
          DScreen.AddSysMsgBottom(Format('当前灵气值 %d', [msg.Recog]));
      end;
    SM_HEROWINNIMBUSEXP:
      begin
        if msg.Recog > 0 then
          DScreen.AddSysMsgBottom(Format('(英雄)当前灵气值 %d', [msg.Recog]));
      end;
    SM_WINIPEXP:
      begin
        g_MySelf.m_nIPowerExp := msg.Recog;
        ipExp := LongWord(Makelong(msg.param, msg.tag));
        if ipExp > 0 then
          DScreen.AddSysMsgBottom(Format('%d点内功经验增加', [ipExp]));
        if msg.series in [3..28] then
          g_nMagicRange := msg.series;
      end;
    SM_HEROWINIPEXP:
      begin
        if g_MySelf.m_HeroObject <> nil then
        begin
          g_MySelf.m_HeroObject.m_nIPowerExp := msg.Recog;
          ipExp := LongWord(Makelong(msg.param, msg.tag));
          if ipExp > 0 then
            DScreen.AddSysMsgBottom(Format('(英雄)%d点内功经验增加', [ipExp]));
        end;
      end;
    SM_LEVELUP:
      begin
        g_MySelf.m_Abil.level := msg.param;
        DScreen.AddSysMsg('您的等级已升级！');
      end;
    SM_HEALTHSPELLCHANGED:
      begin
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
{$IF HIGHHP}
          DecodeBuffer(body, @desc, SizeOf(TCharDesc));
          Actor.m_Abil.HP := DWORD(desc.FeatureLen);
          Actor.m_Abil.MP := DWORD(desc.Status);
          Actor.m_Abil.MaxHP := DWORD(desc.StatusEx);
{$ELSE}
          Actor.m_Abil.HP := msg.param;
          Actor.m_Abil.MP := msg.tag;
          Actor.m_Abil.MaxHP := msg.series;
{$IFEND}
        end;
      end;

    SM_STRUCK:
      begin
        DecodeBuffer(body, @wl, SizeOf(TMessageBodyWL));
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          if g_gcGeneral[13] and (msg.series > 0) then
            Actor.StruckShowDamage2(IntToStr(msg.series));

          if Actor = g_MySelf then
          begin
            //if g_MySelf.m_nNameColor = 249 then
              //g_dwLatestStruckTick := GetTickCount;
          end
          else
          begin
            if Actor.CanCancelAction then
              Actor.CancelAction;
          end;
          if (Actor <> g_MySelf) and (Actor <> g_MySelf.m_HeroObject) then
          begin //blue
            if (Actor.m_btRace <> 0) or not g_gcGeneral[15] then
              Actor.UpdateMsg(SM_STRUCK, wl.lTag2, wl.lParam1, msg.series {damage}, '', wl.lParam2, '', wl.lTag1);
          end;
{$IF HIGHHP}
          Actor.m_Abil.HP := DWORD(Makelong(msg.param, msg.tag));
          Actor.m_Abil.MaxHP := DWORD(wl.lParam1);
{$ELSE}
          Actor.m_Abil.HP := msg.param;
          Actor.m_Abil.MaxHP := msg.tag;
{$IFEND}
          if g_boOpenAutoPlay and TimerAutoPlay.Enabled then
          begin //0613 自己受人攻击,小退
            Actor2 := g_PlayScene.FindActor(wl.lTag1);
            if (Actor2 = nil) or ((Actor2.m_btRace <> 0) and (Actor2.m_btIsHero <> 1)) then
              Exit;

            if (g_MySelf <> nil) then
            begin
              if (Actor = g_MySelf.m_HeroObject) then
              begin //英雄受人攻击
                //
                FrmDlg.ClientCallHero();

              end
              else if (Actor = g_MySelf) then
              begin //自己受人攻击,小退
                g_nAPReLogon := 1; //保存状态
                g_nAPrlRecallHero := (g_MySelf.m_HeroObject <> nil);
                g_nOverAPZone2 := g_nOverAPZone;
                g_APGoBack2 := g_APGoBack;
                if g_APMapPath <> nil then
                begin
                  SetLength(g_APMapPath2, High(g_APMapPath));
                  for i := 0 to High(g_APMapPath) do
                    g_APMapPath2[i] := g_APMapPath[i];
                end;
                g_APLastPoint2 := g_APLastPoint;
                g_APStep2 := g_APStep;
                AppLogoutEx();
                {SaveBagsData();}
              end;
            end;
          end;

        end;
      end;

    SM_CHANGEFACE:
      begin
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          DecodeBuffer(body, @desc, SizeOf(TCharDesc));
          Setlength(FeatureMsg,desc.FeatureLen);
          DecodeBuffer(copy(body,  GetCodeMsgSize(SizeOf(TCharDesc) * 4 / 3) + 1, Length(body)), @FeatureMsg[1], Desc.FeatureLen);
          Actor.m_nWaitForRecogId := Makelong(msg.param, msg.tag);
          Actor.m_nWaitForFeature := FeatureMsg;
          Actor.m_nWaitForStatus := desc.Status;
          AddChangeFace(Actor.m_nWaitForRecogId);
        end;
      end;
    SM_PASSWORD:
      begin
        //PlayScene.EdChat.PasswordChar:='*';
        SetInputStatus();
      end;
    SM_OPENHEALTH:
      begin
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          if Actor <> g_MySelf then
          begin
{$IF HIGHHP}
            DecodeBuffer(body, @sMsg, SizeOf(TShortMessage));
            Actor.m_Abil.HP := DWORD(Makelong(msg.param, msg.tag));
            Actor.m_Abil.MaxHP := DWORD(Makelong(sMsg.ident, sMsg.wMsg));
{$ELSE}
            Actor.m_Abil.HP := msg.param;
            Actor.m_Abil.MaxHP := msg.tag;
{$IFEND}
          end;
          Actor.m_boOpenHealth := True;
          //actor.OpenHealthTime := 999999999;
          //actor.OpenHealthStart := GetTickCount;
        end;
      end;
    SM_CLOSEHEALTH:
      begin
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          Actor.m_boOpenHealth := False;
        end;
      end;
    SM_INSTANCEHEALGUAGE:
      begin
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
{$IF HIGHHP}
          DecodeBuffer(body, @sMsg, SizeOf(TShortMessage));
          Actor.m_Abil.HP := DWORD(Makelong(msg.param, msg.tag));
          Actor.m_Abil.MaxHP := DWORD(Makelong(sMsg.ident, sMsg.wMsg));
{$ELSE}
          Actor.m_Abil.HP := msg.param;
          Actor.m_Abil.MaxHP := msg.tag;
{$IFEND}
          Actor.m_noInstanceOpenHealth := True;
          Actor.m_dwOpenHealthTime := 2 * 1000;
          Actor.m_dwOpenHealthStart := GetTickCount;
        end;
      end;

    SM_BREAKWEAPON:
      begin
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          if Actor is THumActor then
            THumActor(Actor).DoWeaponBreakEffect;
        end;
      end;
    SM_SYSMESSAGE2:
      begin
        Str := DecodeString(body);
        DScreen.m_adList.InsertObject(0, Str, TObject(msg.param));
        nad := 0;
        DScreen.m_adList2.InsertObject(0, '', TObject(nad));
      end;
    SM_SYSMESSAGE4:
      begin
        Str := DecodeString(body);
        DScreen.AddSysMsgBottom2(Str);
      end;
    SM_HEAR, SM_CRY, SM_GROUPMESSAGE, SM_GUILDMESSAGE, SM_WHISPER, SM_SYSMESSAGE:
      begin
        if (msg.ident = SM_HEAR) {or (Msg.ident = SM_GROUPMESSAGE)} and (FrmDlg.DBRefuseSay.tag <> 0) then
          Exit;
        if (msg.ident = SM_CRY) and (FrmDlg.DBRefuseCry.tag <> 0) then
          Exit;
        if (msg.ident = SM_WHISPER) and (FrmDlg.DBRefuseWhisper.tag <> 0) then
          Exit;
        if (msg.ident = SM_GUILDMESSAGE) and (FrmDlg.DBRefuseGuild.tag <> 0) then
          Exit;
        Str := DecodeString(body);
{$IFDEF OPENCENTERMAG}
        if msg.tag > 0 then
        begin
          DScreen.AddSysMsgCenter(Str, GetRGB(LoByte(msg.param)), GetRGB(HiByte(msg.param)), msg.tag);
          Exit;
        end;
{$ENDIF OPENCENTERMAG}
        if FrmDlg.m_BlockList.count > 0 then
        begin
          Str2 := ExtractUserName(Str);
          nFuncPos := FrmDlg.m_BlockList.IndexOf(Str2);
          if nFuncPos >= 0 then
          begin
            Exit;
          end;
        end;

        if msg.ident = SM_WHISPER then
        begin
          GetValidStr3(Str, str3, [' ', '=', '>']);
          if FrmDlg.m_FriendsList.IndexOf(str3) > -1 then
            DScreen.AddChatBoardString(Str, clWhite, GetRGB(253))
          else
            DScreen.AddChatBoardString(Str, GetRGB(LoByte(msg.param)), GetRGB(HiByte(msg.param)));

          FrmDlg.m_xChatRecordList.Add(Format('[%s] %s', [TimeToStr(Now), Str]));
          if FrmDlg.m_xChatRecordList.count > 5000 then
          begin
            FrmDlg.m_xChatRecordList.Delete(0);
          end;
        end
        else
          DScreen.AddChatBoardString(Str, GetRGB(LoByte(msg.param)), GetRGB(HiByte(msg.param)));

        if msg.ident = SM_GUILDMESSAGE then
          FrmDlg.AddGuildChat(Str)
        else if msg.ident = SM_HEAR then
        begin
          Actor := g_PlayScene.FindActor(msg.Recog);
          if Actor <> nil then
            Actor.Say(Str);
        end;
      end;
    SM_ATTACKMODE:
      begin
        case msg.param of
          HAM_ALL:
            begin
              g_sAttackMode := sAttackModeOfAll;
              FrmDlg.DBAttackMode.CaptionEx := sAttackModeOfAll;
            end;
          HAM_PEACE:
            begin
              g_sAttackMode := sAttackModeOfPeaceful;
              FrmDlg.DBAttackMode.CaptionEx := sAttackModeOfPeaceful;
            end;
          HAM_DEAR:
            begin
              g_sAttackMode := sAttackModeOfDear;
              FrmDlg.DBAttackMode.CaptionEx := sAttackModeOfDear;
            end;
          HAM_MASTER:
            begin
              g_sAttackMode := sAttackModeOfMaster;
              FrmDlg.DBAttackMode.CaptionEx := sAttackModeOfMaster;
            end;
          HAM_GROUP:
            begin
              g_sAttackMode := sAttackModeOfGroup;
              FrmDlg.DBAttackMode.CaptionEx := sAttackModeOfGroup;
            end;
          HAM_GUILD:
            begin
              g_sAttackMode := sAttackModeOfGuild;
              FrmDlg.DBAttackMode.CaptionEx := sAttackModeOfGuild;
            end;
          HAM_PKATTACK:
            begin
              g_sAttackMode := sAttackModeOfRedWhite;
              FrmDlg.DBAttackMode.CaptionEx := sAttackModeOfRedWhite;
            end;
        end;
      end;
    SM_USERNAME:
      begin
        Str := DecodeString(body);
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          Actor.m_sDescUserName := GetValidStr3(Str, Actor.m_sUserName, ['\']);
          Actor.m_sUserNameOffSet := TextWidthA(Actor.m_sUserName, False) div 2;
          Actor.m_btNameColor := msg.param;
          if Actor.m_btRace = RCC_MERCHANT then
            Actor.m_nNameColor := clLime
          else
            Actor.m_nNameColor := GetRGB(msg.param);
          if msg.tag in [1..5] then
            Actor.m_btAttribute := msg.tag;
        end;
      end;
    SM_CHANGENAMECOLOR:
      begin
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor <> nil then
        begin
          Actor.m_btNameColor := msg.param;
          if Actor.m_btRace = RCC_MERCHANT then
            Actor.m_nNameColor := clLime
          else
            Actor.m_nNameColor := GetRGB(msg.param);
        end;
      end;

    SM_HIDE, SM_GHOST, SM_DISAPPEAR:
      begin
        if g_MySelf.m_nRecogId <> msg.Recog then
          g_PlayScene.SendMsg(SM_HIDE, msg.Recog, msg.param {x}, msg.tag {y}, msg.series, 0, 0, '');
      end;

    SM_DIGUP:
      begin
        DecodeBuffer(body, @wl, SizeOf(TMessageBodyWL));
        Setlength(FeatureMsg, wl.lparam1);
        DecodeBuffer(copy(body, GetCodeMsgSize(SizeOf(TMessageBodyWL) * 4 / 3) + 1, Length(body)),@FeatureMsg[1],wl.lParam1);
        Actor := g_PlayScene.FindActor(msg.Recog);
        if Actor = nil then
          Actor := g_PlayScene.NewActor(msg.Recog, msg.param, msg.tag, msg.series, FeatureMsg, wl.lParam2);
        Actor.m_nCurrentEvent := wl.lTag1;
        Actor.SendMsg(SM_DIGUP,
          msg.param {x},
          msg.tag {y},
          msg.series {dir + light},
          FeatureMsg,
          wl.lParam2, '', 0);
      end;
    SM_HEROSTATE:
      if g_MySelf <> nil then
      begin
        DecodeBuffer(body, @wl, SizeOf(TMessageBodyWL));
        Setlength(FeatureMsg, wl.lparam1);
        DecodeBuffer(copy(body, GetCodeMsgSize(SizeOf(TMessageBodyWL) * 4 / 3) + 1, Length(body)), @FeatureMsg[1], wl.lparam1);
        g_MySelf.m_HeroObject := g_PlayScene.NewActor(msg.Recog, msg.param, msg.tag, msg.series, FeatureMsg, wl.lParam2);
        // g_MySelf.m_HeroObject := g_PlayScene.NewActor(msg.Recog, msg.param, msg.tag, msg.series, wl.lParam1, wl.lParam2);
        g_MySelf.m_HeroObject.m_btIsHero := 1;
        FrmDlg.DWHeroStatus.Visible := True;
      end;
    SM_HEROABILITY: if (g_MySelf <> nil) and (g_MySelf.m_HeroObject <> nil) then
      begin
        g_MySelf.m_HeroObject.m_nGold := msg.Recog;
        g_MySelf.m_HeroObject.m_btJob := LoByte(msg.param);
        g_MySelf.m_HeroObject.m_nIPowerLvl := HiByte(msg.param);
        g_MySelf.m_HeroObject.m_wGloryPoint := msg.series;
        DecodeBuffer(body, @g_MySelf.m_HeroObject.m_Abil, SizeOf(TAbility));
      end;
    SM_HEROSUBABILITY:
      begin
        g_nHeroHitPoint := LoByte(msg.param);
        g_nHeroSpeedPoint := HiByte(msg.param);
        g_nHeroAntiPoison := LoByte(msg.tag);
        g_nHeroPoisonRecover := HiByte(msg.tag);
        g_nHeroHealthRecover := LoByte(msg.series);
        g_nHeroSpellRecover := HiByte(msg.series);
        g_nHeroAntiMagic := LoByte(LoWord(msg.Recog));
        g_nHeroIPowerRecover := HiByte(LoWord(msg.Recog));
        g_nHeroAddDamage := LoByte(HiWord(msg.Recog));
        g_nHeroDecDamage := HiByte(HiWord(msg.Recog));
        //g_nHeroIPowerRecover := HiWord(msg.Recog);
      end;
    SM_HEROSTATEDISPEAR: if g_MySelf <> nil then
      begin
        if msg.Recog = 0 then
        begin
          SaveBagsData();
          HeroClearBag();
          g_MySelf.m_HeroObject := nil;
          FrmDlg.CloseHeroWindows;
        end
        else
        begin
          for i := 0 to g_MySelf.m_SlaveObject.count - 1 do
          begin
            if TActor(g_MySelf.m_SlaveObject[i]).m_nRecogId = msg.Recog then
            begin
              g_MySelf.m_SlaveObject.Delete(i);
              Break;
            end;
          end;
          //g_MySelf.m_SlaveObject := nil;
        end;
      end;
    SM_HERONAME:
      begin
        Str := DecodeString(body);
        if (Str <> '') and (g_MySelf.m_HeroObject <> nil) then
        begin
          g_MySelf.m_HeroObject.m_sDescUserName := GetValidStr3(Str, g_MySelf.m_HeroObject.m_sUserName, ['\']);
          g_MySelf.m_HeroObject.m_sUserNameOffSet := TextWidthA(g_MySelf.m_HeroObject.m_sUserName, False) div 2;
          g_MySelf.m_HeroObject.m_btNameColor := msg.param;
          g_MySelf.m_HeroObject.m_nNameColor := GetRGB(msg.param);
          m_sHeroCharName := g_MySelf.m_HeroObject.m_sUserName;
        end;
      end;
    SM_HEROLOYALTY:
      begin
        Str := DecodeString(body);
        if g_MySelf.m_HeroObject <> nil then
          if Str <> '' then
            g_MySelf.m_HeroObject.m_sLoyaly := Str
          else
            g_MySelf.m_HeroObject.m_sLoyaly := '50.00%'
      end;

    SM_DIGDOWN:
      begin
        g_PlayScene.SendMsg(SM_DIGDOWN, msg.Recog, msg.param {x}, msg.tag {y}, 0, 0, 0, '');
      end;
    SM_SHOWEVENT:
      begin
        DecodeBuffer(body, @sMsg, SizeOf(TShortMessage));
        event := TClEvent.Create(msg.Recog, LoWord(msg.tag) {x}, msg.series {y}, msg.param {e-type});
        event.m_nDir := 0;
        event.m_nEventParam := sMsg.ident;
        event.m_nEventLevel := sMsg.wMsg;
        EventMan.AddEvent(event);
      end;
    SM_HIDEEVENT: EventMan.DelEventById(msg.Recog);
    SM_ADDITEM: ClientGetAddItem(msg.series, body);
    SM_HEROADDITEM: ClientHeroGetAddItem(body);
    SM_BAGITEMS: ClientGetBagItmes(body);
    SM_SAFEZONEEFFECTCUSTOM: ClientGetSafeZoneEffectCustom(body);
    SM_NPCCUSTOM: ClientGetNpcCustom(body);
    SM_HEROBAGITEMS: ClientHeroGetBagItmes(body, msg.series);

    SM_COUNTERITEMCHANGE:
      begin
        if not g_boDealEnd then
          g_dwDealActionTick := GetTickCount;
        ChangeItemCount(msg.Recog, msg.param, msg.tag, DecodeString(body));
      end;
    SM_HEROCOUNTERITEMCHANGE:
      begin
        if not g_boDealEnd then
          g_dwDealActionTick := GetTickCount;
        HeroChangeItemCount(msg.Recog, msg.param, msg.tag, DecodeString(body));
      end;

    SM_UPDATEITEM: ClientGetUpdateItem(body);
    SM_HEROUPDATEITEM: ClientHeroGetUpdateItem(body);
    SM_DELITEM: ClientGetDelItem(body);
    SM_HERODELITEM: ClientHeroGetDelItem(body);

    SM_DELITEMS: ClientGetDelItems(body, msg.param);
    SM_HERODELITEMS: ClientHeroGetDelItems(body, msg.param);
    SM_DROPITEM_SUCCESS: DelDropItem(DecodeString(body), msg.Recog);
    SM_DROPITEM_FAIL: ClientGetDropItemFail(DecodeString(body), msg.Recog);

    SM_HERODROPITEM_SUCCESS: DelDropItem(DecodeString(body), msg.Recog);
    SM_HERODROPITEM_FAIL: ClientHeroGetDropItemFail(DecodeString(body), msg.Recog);

    SM_ITEMSHOW:
      begin
        ClientGetShowItem(msg.Recog, msg.param {x}, msg.tag {y}, msg.series {looks}, DecodeString(body));
      end;
    SM_ITEMHIDE: ClientGetHideItem(msg.Recog, msg.param, msg.tag);
    SM_OPENDOOR_OK: Map.OpenDoor(msg.param, msg.tag);
    SM_OPENDOOR_LOCK: DScreen.AddSysMsg('此门被锁定');
    SM_CLOSEDOOR: Map.CloseDoor(msg.param, msg.tag);

    SM_ADDITEMTOHEROBAG:
    if g_WaitingUseItem.Item.S.Name <> '' then
      begin
        DelStallItem(g_WaitingUseItem.Item);
        HeroAddItemBag(g_WaitingUseItem.Item);
        g_WaitingUseItem.Item.S.Name := '';
      end;
    SM_HEROEXCHGBAGITEM_FAIL: if g_WaitingUseItem.Item.S.Name <> '' then
      begin
        if msg.Recog = 0 then
        begin
          AddItemBag(g_WaitingUseItem.Item);
          g_WaitingUseItem.Item.S.Name := '';
          DScreen.AddChatBoardString('(英雄) 背包已满，请整理后进行操作', clWhite, clRed);
        end
        else if msg.Recog = 1 then
        begin
          HeroAddItemBag(g_WaitingUseItem.Item);
          g_WaitingUseItem.Item.S.Name := '';
          DScreen.AddChatBoardString('你的背包已满，请整理后进行操作', clWhite, clRed);
        end
        else if msg.Recog = 2 then
        begin
          AddItemBag(g_WaitingUseItem.Item);
          DScreen.AddChatBoardString(g_WaitingUseItem.Item.S.Name + '不能放到英雄包裹中', clWhite, clRed);
          g_WaitingUseItem.Item.S.Name := '';
        end;
      end;
    SM_GETITEMFROMHEROBAG: if g_WaitingUseItem.Item.S.Name <> '' then
      begin
        AddItemBag(g_WaitingUseItem.Item);
        g_WaitingUseItem.Item.S.Name := '';
      end;
    SM_TAKEON_OK:
      begin
        // g_MySelf.m_nFeature := msg.Recog;             扩展面容   2019-12-05
        SetLength(g_MySelf.m_nFeature,msg.Recog);
        DecodeBuffer(body,@g_MySelf.m_nFeature[1], msg.Recog);
        g_MySelf.FeatureChanged;
        if g_WaitingUseItem.Item.S.Name <> '' then
        begin
          if g_WaitingUseItem.Index in [0..U_FASHION] then
            g_UseItems[g_WaitingUseItem.Index] := g_WaitingUseItem.Item;
          g_WaitingUseItem.Item.S.Name := '';
        end;
      end;
    SM_TAKEON_FAIL: 
      begin
        if g_WaitingUseItem.Item.S.Name <> '' then
        begin
          AddItemBag(g_WaitingUseItem.Item);
          g_WaitingUseItem.Item.S.Name := '';
        end;
      end;
    SM_HEROTAKEON_OK:
      if g_WaitingUseItem.Item.S.Name <> '' then
      begin
        if g_WaitingUseItem.Index in [0..U_FASHION] then
          g_HeroUseItems[g_WaitingUseItem.Index] := g_WaitingUseItem.Item;
        g_WaitingUseItem.Item.S.Name := '';
      end;
    SM_HEROTAKEON_FAIL: if g_WaitingUseItem.Item.S.Name <> '' then
      begin
        HeroAddItemBag(g_WaitingUseItem.Item);
        g_WaitingUseItem.Item.S.Name := '';
      end;
    SM_TAKEOFF_OK:
      begin
        // g_MySelf.m_nFeature := msg.Recog;                 2019-12-05
        SetLength(g_MySelf.m_nFeature, msg.Recog);
        DeCodeBuffer(body, @g_MySelf.m_nFeature[1],msg.Recog);
        g_MySelf.FeatureChanged;
        //AddItemBag(g_WaitingUseItem.Item);
        g_WaitingUseItem.Item.S.Name := '';
      end;
    SM_HEROTAKEOFF_OK: if g_WaitingUseItem.Item.S.Name <> '' then
      begin
        HeroAddItemBag(g_WaitingUseItem.Item);
        g_WaitingUseItem.Item.S.Name := '';
      end;

    SM_TAKEOFF_FAIL:
    if g_WaitingUseItem.Item.S.Name <> '' then
      begin
        if g_WaitingUseItem.Index < 0 then
        begin
          n := -(g_WaitingUseItem.Index + 1);
          g_UseItems[n] := g_WaitingUseItem.Item;
        end;
        g_WaitingUseItem.Item.S.Name := '';
      end;
    SM_HEROTAKEOFF_FAIL: if g_WaitingUseItem.Item.S.Name <> '' then
      begin
        if (g_WaitingUseItem.Index < (0 - HERO_MIIDX_OFFSET)) and (g_WaitingUseItem.Index >= -((U_FASHION + 1) + HERO_MIIDX_OFFSET)) then
        begin
          n := -(g_WaitingUseItem.Index + 1 + HERO_MIIDX_OFFSET);
          g_HeroUseItems[n] := g_WaitingUseItem.Item;
        end;
        g_WaitingUseItem.Item.S.Name := '';
      end;
    SM_QUERYREFINEITEM: FrmDlg.DWRefine.Visible := True;
    SM_SENDUSEITEMS: ClientGetSendUseItems(body);
    SM_HEROUSEITEMS: ClientGetSendHeroUseItems(body);

    SM_WEIGHTCHANGED:
      begin
        g_MySelf.m_Abil.Weight := msg.Recog;
        g_MySelf.m_Abil.WearWeight := msg.param;
        g_MySelf.m_Abil.HandWeight := msg.tag;
      end;
    SM_GOLDCHANGED:
      begin
        g_SndMgr.PlaySound(s_money);
        if msg.Recog > g_MySelf.m_nGold then
          DScreen.AddSysMsg('获得 ' + IntToStr(msg.Recog - g_MySelf.m_nGold) + g_sGoldName);
        g_MySelf.m_nGold := msg.Recog;
        g_MySelf.m_nGameGold := Makelong(msg.param, msg.tag);
      end;
    SM_FEATURECHANGED:
      begin
        g_PlayScene.SendMsg(msg.ident, msg.Recog, 0, 0, 0,
          Makelong(msg.param, msg.tag),
          Makelong(msg.series, 0), body);
      end;
    SM_APPRCHANGED, SM_CHARSTATUSCHANGED:
      begin
        if body <> '' then
          g_PlayScene.SendMsg(msg.ident, msg.Recog, 0, 0, 0, Makelong(msg.param, msg.tag), msg.series, DecodeString(body))
        else
          g_PlayScene.SendMsg(msg.ident, msg.Recog, 0, 0, 0, Makelong(msg.param, msg.tag), msg.series, '');
      end;
    SM_CLEAROBJECTS:
      begin
        //PlayScene.CleanObjects;
        g_boMapMoving := True;
      end;
    SM_EAT_OK: if msg.Recog <> 0 then
      begin
        Str := '';
        if msg.Recog <> g_EatingItem.MakeIndex then
        begin

          for i := MAXBAGITEMCL - 1 downto 0 do
          begin
            if g_ItemArr[i].S.Name <> '' then
            begin
              if g_ItemArr[i].MakeIndex = g_EatingItem.MakeIndex then
              begin
                DelStallItem(g_ItemArr[i]);
                Str := g_ItemArr[i].S.Name;
                g_ItemArr[i].S.Name := '';
                Break;
              end;
            end;
          end;

        end;
        if Str = '' then
        begin
          Str := g_EatingItem.S.Name;
          if m_boSupplyItem then
          begin
            if m_nEatRetIdx in [0..5] then
              AutoSupplyBeltItem(g_EatingItem.S.AniCount, m_nEatRetIdx, Str)
            else
              AutoSupplyBagItem(g_EatingItem.S.AniCount, Str);
            m_boSupplyItem := False;
          end;
        end;
        g_EatingItem.S.Name := '';
        ArrangeItembag;
        m_nEatRetIdx := -1;
      end;
    SM_HEROEAT_OK:
      begin
        g_EatingItem.S.Name := '';
        ArrangeHeroItembag;
      end;
    SM_EAT_FAIL:
      begin
        if msg.Recog = g_EatingItem.MakeIndex then
        begin
          //DScreen.AddChatBoardString(g_EatingItem.S.Name + ' ' + IntToStr(msg.tag), clRed, clWhite);
          if msg.tag > 0 then
            g_EatingItem.Dura := msg.tag;
          AddItemBag(g_EatingItem, m_nEatRetIdx);
          g_EatingItem.S.Name := '';
          m_nEatRetIdx := -1;
        end;
        m_boSupplyItem := False;
        case msg.series of
          1: DScreen.AddChatBoardString('[失败] 你的金币不足，不能释放积灵珠！', clRed, clWhite);
          2: DScreen.AddChatBoardString('[失败] 你的元宝不足，不能释放积灵珠！', clRed, clWhite);
          3: DScreen.AddChatBoardString('[失败] 你的金刚石不足，不能释放积灵珠！', clRed, clWhite);
          4: DScreen.AddChatBoardString('[失败] 你的灵符不足，不能释放积灵珠！', clRed, clWhite);
        end;
      end;
    SM_HEROEAT_FAIL:
      begin
        if msg.tag > 0 then
          g_EatingItem.Dura := msg.tag;
        HeroAddItemBag(g_EatingItem);
        g_EatingItem.S.Name := '';
        case msg.series of
          1: DScreen.AddChatBoardString('[失败] 你的金币不足，英雄不能释放积灵珠！', clRed, clWhite);
          2: DScreen.AddChatBoardString('[失败] 你的元宝不足，英雄不能释放积灵珠！', clRed, clWhite);
          3: DScreen.AddChatBoardString('[失败] 你的金刚石不足，英雄不能释放积灵珠！', clRed, clWhite);
          4: DScreen.AddChatBoardString('[失败] 你的灵符不足，英雄不能释放积灵珠！', clRed, clWhite);
        end;
      end;
    SM_OFFERITEM, SM_SPECOFFERITEM: if body <> '' then
        ClientGetShopItems(body, msg.param);

    SM_ADDMAGIC: if body <> '' then
        ClientGetAddMagic(body);
    SM_HEROADDMAGIC: if body <> '' then
        ClientHeroGetAddMagic(body);
    SM_SENDMYMAGIC: if body <> '' then
        ClientGetMyMagics(body);
    SM_HEROMYMAGICS:
    begin
      // if body <> '' then      初始化技能英雄列表   2019-11-13 10:15:34
      ClientGetHeroMagics(body);
    end;
    SM_DELMAGIC: ClientGetDelMagic(msg.Recog, msg.param);

    SM_CONVERTMAGIC: ClientConvertMagic(msg.Recog, msg.param, msg.tag, msg.series, (body));
    SM_HCONVERTMAGIC: hClientConvertMagic(msg.Recog, msg.param, msg.tag, msg.series, (body));

    SM_HERODELMAGIC: ClientHeroGetDelMagic(msg.Recog, msg.param);
    SM_MAGIC_LVEXP: ClientGetMagicLvExp(msg.Recog {magid}, msg.param {lv}, Makelong(msg.tag, msg.series));
    SM_MAGIC_MAXLV: ClientGetMagicMaxLv(msg.Recog {magid}, msg.param {Maxlv}, msg.series);

    SM_HEROMAGIC_LVEXP: ClientHeroGetMagicLvExp(msg.Recog {magid}, msg.param {lv}, Makelong(msg.tag, msg.series));

    SM_DURACHANGE: ClientGetDuraChange(msg.param {useitem index}, msg.Recog, Makelong(msg.tag, msg.series));
    SM_BAGDURACHANGE: ClientGetBagDuraChange(msg.Recog, msg.Param, Msg.Tag = 1, msg.Series = 1);
    SM_HERODURACHANGE: ClientHeroGetDuraChange(msg.param {useitem index}, msg.Recog, Makelong(msg.tag, msg.series));
    SM_HEROPOWERUP: if g_MySelf.m_HeroObject <> nil then
      begin
        g_MySelf.m_HeroObject.m_nHeroEnergyType := msg.param;
        g_MySelf.m_HeroObject.m_nHeroEnergy := msg.Recog;
        g_MySelf.m_HeroObject.m_nMaxHeroEnergy := msg.tag;
        if msg.param = 1 then
          g_SndMgr.PlaySound('Wav\powerup.wav');
      end;
    SM_MERCHANTSAY: ClientGetMerchantSay(msg.Recog, msg.param, DecodeString(body));
    SM_MERCHANTDLGCLOSE: FrmDlg.CloseMDlg;
    SM_SENDGOODSLIST: ClientGetSendGoodsList(msg.Recog, msg.param, msg.Series, body);
    SM_SENDUSERMAKEDRUGITEMLIST: ClientGetSendMakeDrugList(msg.Recog, body);
    SM_SENDUSERSELL: ClientGetSendUserSell(msg.Recog);
    SM_SENDUSERREPAIR: ClientGetSendUserRepair(msg.Recog);
    SM_SENDBUYPRICE:
      begin
        if g_SellDlgItem.S.Name <> '' then
        begin
          if msg.Recog > 0 then
          begin
            if g_SellDlgItem.S.Overlap > 0 then
              g_sSellPriceStr := IntToStr(msg.Recog * g_SellDlgItem.Dura) + g_sGoldName
            else
              g_sSellPriceStr := IntToStr(msg.Recog) + g_sGoldName;
          end
          else
            g_sSellPriceStr := '???? ' + g_sGoldName {金币'};
        end;
      end;
    SM_SENDBOOKCNT:
      begin
        if g_SellDlgItem.S.Name <> '' then
        begin
          if msg.Recog > 0 then
          begin
            if g_SellDlgItem.S.Overlap > 0 then
              g_sSellPriceStr := '换: ' + IntToStr(msg.Recog * g_SellDlgItem.Dura) + '卷轴碎片'
            else
              g_sSellPriceStr := '换: ' + IntToStr(msg.Recog) + '卷轴碎片';
          end
          else
          begin
            case msg.Recog of
              00: g_sSellPriceStr := '不可以兑换';
              -1: g_sSellPriceStr := '不是装备类';
              -2: g_sSellPriceStr := '装备级别太低';
              -3: g_sSellPriceStr := '装备级别太高';
            end;
          end;
        end;
      end;
    SM_USERSELLITEM_OK:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        g_MySelf.m_nGold := msg.Recog;
        g_SellDlgItemSellWait.Item.S.Name := '';
      end;

    SM_USERSELLITEM_FAIL:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        AddItemBag(g_SellDlgItemSellWait.Item);
        g_SellDlgItemSellWait.Item.S.Name := '';
        FrmDlg.DMessageDlg('此物品不能出售', [mbOk]);
      end;
    SM_USEREXCHGITEM_FAIL:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        AddItemBag(g_SellDlgItemSellWait.Item);
        g_SellDlgItemSellWait.Item.S.Name := '';
        case msg.Recog of
          -1: FrmDlg.DMessageDlg('[失败] 摆摊中，不能操作', [mbOk]);
          -2: FrmDlg.DMessageDlg('[失败] 物品已经绑定他人', [mbOk]);
          -3: FrmDlg.DMessageDlg('[失败] 禁止出售的物品，也不能更换卷轴碎片', [mbOk]);
          -4: FrmDlg.DMessageDlg('[失败] 更换卷轴碎片失败', [mbOk]);
          -5: FrmDlg.DMessageDlg('[失败] 该不是装备类', [mbOk]);
          -6: FrmDlg.DMessageDlg('[失败] 该装备级别太低', [mbOk]);
          -7: FrmDlg.DMessageDlg('[失败] 该装备级别太高', [mbOk]);
        end;

      end;

    SM_USERSELLCOUNTITEM_OK:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        g_MySelf.m_nGold := msg.Recog;
        SellItemProg(msg.param, msg.tag);
        g_SellDlgItemSellWait.Item.S.Name := '';
      end;

    SM_USERSELLCOUNTITEM_FAIL:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        AddItemBag(g_SellDlgItemSellWait.Item);
        g_SellDlgItemSellWait.Item.S.Name := '';
        FrmDlg.DMessageDlg('此物品不能出售', [mbOk]);
      end;

    SM_SENDREPAIRCOST:
      begin
        if g_SellDlgItem.S.Name <> '' then
        begin
          if msg.Recog >= 0 then
            g_sSellPriceStr := IntToStr(msg.Recog) + ' ' + g_sGoldName {金币}
          else
            g_sSellPriceStr := '???? ' + g_sGoldName {金币};
        end;
      end;
    SM_USERREPAIRITEM_OK:
      begin
        if g_SellDlgItemSellWait.Item.S.Name <> '' then
        begin
          FrmDlg.LastestClickTime := GetTickCount;
          g_MySelf.m_nGold := msg.Recog;
          g_SellDlgItemSellWait.Item.Dura := msg.param;
          g_SellDlgItemSellWait.Item.DuraMax := msg.tag;
          AddItemBag(g_SellDlgItemSellWait.Item);
          g_SellDlgItemSellWait.Item.S.Name := '';
        end;
      end;
    SM_USERREPAIRITEM_FAIL:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        AddItemBag(g_SellDlgItemSellWait.Item);
        g_SellDlgItemSellWait.Item.S.Name := '';
        FrmDlg.DMessageDlg('您不能修理此物品', [mbOk]);
      end;
    SM_ITEMSUMCOUNT_FAIL:
      begin
        if g_WaitingUseItem.Item.S.Name <> '' then
        begin
          if msg.series <> 0 then
          begin
            if msg.Recog = 0 then
            begin
              HeroAddItemBag(g_WaitingUseItem.Item);
              g_WaitingUseItem.Item.S.Name := '';
              DScreen.AddChatBoardString('(英雄)重叠失败,物品最高数量是 ' + IntToStr(g_WaitingUseItem.Item.DuraMax), clWhite, clRed);
            end
            else
            begin
              g_WaitingUseItem.Item.Dura := msg.param;
              HeroAddItemBag(g_WaitingUseItem.Item);
              g_WaitingUseItem.Item.S.Name := '';
            end;
          end
          else
          begin
            if msg.Recog = 0 then
            begin
              AddItemBag(g_WaitingUseItem.Item, g_WaitingUseItem.Index);
              g_WaitingUseItem.Item.S.Name := '';
              DScreen.AddChatBoardString('重叠失败,物品最高数量是 ' + IntToStr(g_WaitingUseItem.Item.DuraMax), clWhite, clRed);
            end
            else
            begin
              g_WaitingUseItem.Item.Dura := msg.param;
              AddItemBag(g_WaitingUseItem.Item, g_WaitingUseItem.Index);
              g_WaitingUseItem.Item.S.Name := '';
            end;
          end;
        end;
      end;
    SM_STORAGE_OK, SM_STORAGE_FULL, SM_STORAGE_FAIL:
      begin
        FrmDlg.LastestClickTime := GetTickCount;

        if msg.ident <> SM_STORAGE_OK then
        begin
          if msg.ident = SM_STORAGE_FULL then
          begin
            FrmDlg.DMessageDlg('您的个人仓库已经满了，不能再保管任何东西了', [mbOk]);
          end
          else
          begin
            if msg.Recog = 2 then
            begin
              FrmDlg.DMessageDlg('寄存物品失败,同类单个物品最高重叠数量是 ' + IntToStr(MAX_OVERLAPITEM), [mbOk]);
            end
            else if msg.Recog = 3 then
            begin
              g_SellDlgItemSellWait.Item.Dura := g_SellDlgItemSellWait.Item.Dura - msg.param;
              g_MovingItem.Item.Dura := g_MovingItem.Item.Dura - msg.param;
              DScreen.AddChatBoardString(Format('成功寄存 %s %d个', [g_SellDlgItemSellWait.Item.S.Name, msg.param]), clBlue, clWhite);
            end
            else
            begin
              FrmDlg.DMessageDlg('您不能寄存物品', [mbOk]);
            end;
          end;
          if g_SellDlgItemSellWait.Item.s.Name <> '' then
          begin
            AddItemBag(g_SellDlgItemSellWait.Item);
          end;
          if g_MovingItem.Item.s.Name <> '' then
          begin
            AddItemBag(g_MovingItem.Item);
            g_MovingItem.Item.s.Name := '';
            g_boItemMoving := False;
          end;
        end
        else
        begin
          new(PTC);
          ptc.s := g_MovingItem.Item.s;
          ptc.MakeIndex := g_MovingItem.Item.MakeIndex;
          ptc.Dura := g_movingItem.Item.Dura;
          ptc.DuraMax := g_movingItem.Item.DuraMax;
          g_SaveItemList.Add(ptc);
          g_MovingItem.Item.s.Name := '';
          g_boItemMoving := False;
          g_SellDlgItemSellWait.Item.S.Name := '';
        end;


      end;
    SM_SAVEITEMLIST:
      begin
        ClientGetSaveItemList(msg.Recog, body);
      end;
    SM_GETSTORAGEITEMLIST:
      begin
        ClientGetStorageItemList(msg.Recog, body);
      end;
    SM_TAKEBACKSTORAGEITEM_OK,
      SM_TAKEBACKSTORAGEITEM_FAIL,
      SM_TAKEBACKSTORAGEITEM_FULLBAG:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        if msg.ident <> SM_TAKEBACKSTORAGEITEM_OK then
        begin
          if msg.ident = SM_TAKEBACKSTORAGEITEM_FULLBAG then
            FrmDlg.DMessageDlg('您无法携带更多物品了', [mbOk])
          else
            FrmDlg.DMessageDlg('您无法取回物品', [mbOk]);
        end
        else
        begin
          FrmDlg.DelStorageItem(msg.Recog, msg.param, boolean(msg.Series));
        end;
      end;

    SM_BUYITEM_SUCCESS:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        g_MySelf.m_nGold := msg.Recog;
        FrmDlg.SoldOutGoods(Makelong(msg.param, msg.tag));
      end;
    SM_BUYITEM_FAIL:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        case msg.Recog of
          1: FrmDlg.DMessageDlg('此物品被卖出', [mbOk]);
          2: FrmDlg.DMessageDlg('您无法携带更多物品了', [mbOk]);
          3: FrmDlg.DMessageDlg('您没有足够的钱来购买此物品', [mbOk]);
        end;
      end;
    SM_MAKEDRUG_SUCCESS:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        g_MySelf.m_nGold := msg.Recog;
        FrmDlg.DMessageDlg('您要的物品已经搞定了', [mbOk]);
      end;
    SM_MAKEDRUG_FAIL:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        case msg.Recog of
          1: FrmDlg.DMessageDlg('未知错误', [mbOk]);
          2: FrmDlg.DMessageDlg('发生了错误', [mbOk]);
          3: FrmDlg.DMessageDlg(g_sGoldName {'金币'} + '不足', [mbOk]);
          4: FrmDlg.DMessageDlg('你缺乏所必需的物品', [mbOk]);
        end;
      end;
    SM_NORMALEFFECT: DrawEffectHum(msg.series {type}, msg.param {x}, msg.tag {y});
    SM_SENDDETAILGOODSLIST: ClientGetSendDetailGoodsList(msg.Recog, msg.param, msg.tag, body);
    SM_TEST: Inc(g_nTestReceiveCount);
    SM_SENDNOTICE: ClientGetSendNotice(body);
    SM_IMAGEFILELISTCUSTOM: ClientGetImageFileListCustom(body);
    SM_POSTIONMOVE:
      ClientGetPositionMove(msg, body);
    SM_GROUPMODECHANGED:
      begin
        if msg.param > 0 then
        begin
          g_boAllowGroup := True;
          DScreen.AddChatBoardString('[开启组队开关]', GetRGB(219), clWhite);
        end
        else
        begin
          g_boAllowGroup := False;
          DScreen.AddChatBoardString('[关闭组队开关]', GetRGB(219), clWhite);
        end;
        g_dwChangeGroupModeTick := GetTickCount;
      end;
    SM_CREATEGROUP_OK:
      begin
        g_dwChangeGroupModeTick := GetTickCount;
        g_boAllowGroup := True;
      end;
    SM_CREATEGROUP_FAIL:
      begin
        g_dwChangeGroupModeTick := GetTickCount;
        case msg.Recog of
          -1: FrmDlg.DMessageDlg('编组还未成立或者你还不够等级创建！', [mbOk]);
          -2: FrmDlg.DMessageDlg('输入的人物名称不正确！', [mbOk]);
          -3: FrmDlg.DMessageDlg('您想邀请加入编组的人已经加入了其它组！', [mbOk]);
          -4: FrmDlg.DMessageDlg('对方不允许编组！', [mbOk]);
        end;
      end;
    SM_GROUPADDMEM_OK:
      begin
        g_dwChangeGroupModeTick := GetTickCount;
        //GroupMembers.Add (DecodeString(body));
      end;
    SM_GROUPADDMEM_FAIL:
      begin
        g_dwChangeGroupModeTick := GetTickCount;
        case msg.Recog of
          -1: FrmDlg.DMessageDlg('编组还未成立或者你还不够等级创建！', [mbOk]);
          -2: FrmDlg.DMessageDlg('输入的人物名称不正确！', [mbOk]);
          -3: FrmDlg.DMessageDlg('已经加入编组！', [mbOk]);
          -4: FrmDlg.DMessageDlg('对方不允许编组！', [mbOk]);
          -5: FrmDlg.DMessageDlg('您想邀请加入编组的人已经加入了其它组！', [mbOk]);
        end;
      end;
    SM_GROUPDELMEM_OK:
      g_dwChangeGroupModeTick := GetTickCount;
    SM_GROUPDELMEM_FAIL:
      begin
        g_dwChangeGroupModeTick := GetTickCount;
        case msg.Recog of
          -1: FrmDlg.DMessageDlg('编组还未成立或者您还不够等级创建', [mbOk]);
          -2: FrmDlg.DMessageDlg('输入的人物名称不正确！', [mbOk]);
          -3: FrmDlg.DMessageDlg('此人不在本组中！', [mbOk]);
        end;
      end;
    SM_GROUPCANCEL:
      g_GroupMembers.Clear;
    SM_GROUPMEMBERS:
      ClientGetGroupMembers(DecodeString(body));
    SM_OPENGUILDDLG:
      begin
        g_dwQueryMsgTick := GetTickCount;
        ClientGetOpenGuildDlg(body);
      end;
    SM_SENDGUILDMEMBERLIST:
      begin
        g_dwQueryMsgTick := GetTickCount;
        ClientGetSendGuildMemberList(body);
      end;

    SM_OPENGUILDDLG_FAIL:
      begin
        g_dwQueryMsgTick := GetTickCount;
        FrmDlg.DMessageDlg('您还没有加入行会！', [mbOk]);
      end;
    SM_DEALTRY_FAIL:
      begin
        g_dwQueryMsgTick := GetTickCount;
        FrmDlg.DMessageDlg('只有二人面对面才能进行交易', [mbOk]);
      end;
    SM_DEALMENU:
      begin
        g_dwQueryMsgTick := GetTickCount;
        g_sDealWho := DecodeString(body);
        FrmDlg.OpenDealDlg;
      end;
    SM_DEALCANCEL:
      begin
        MoveDealItemToBag;
        if g_DealDlgItem.S.Name <> '' then
        begin
          AddItemBag(g_DealDlgItem);
          g_DealDlgItem.S.Name := '';
        end;
        if g_nDealGold > 0 then
        begin
          g_MySelf.m_nGold := g_MySelf.m_nGold + g_nDealGold;
          g_nDealGold := 0;
        end;
        FrmDlg.CloseDealDlg;
      end;
    SM_DEALADDITEM_OK:
      begin
        g_dwDealActionTick := GetTickCount;
        if g_DealDlgItem.S.Name <> '' then
        begin
          ResultDealItem(g_DealDlgItem, msg.Recog, msg.param);
          g_DealDlgItem.S.Name := '';
        end;
      end;
    SM_DEALADDITEM_FAIL:
      begin
        g_dwDealActionTick := GetTickCount;
        if g_DealDlgItem.S.Name <> '' then
        begin
          AddItemBag(g_DealDlgItem);
          g_DealDlgItem.S.Name := '';
        end;
        if msg.Recog <> 0 then
          DScreen.AddChatBoardString('重叠失败,物品最高数量是 ' + IntToStr(MAX_OVERLAPITEM), clWhite, clRed);
      end;
    SM_DEALDELITEM_OK:
      begin
        g_dwDealActionTick := GetTickCount;
        if g_DealDlgItem.S.Name <> '' then
        begin
          g_DealDlgItem.S.Name := '';
        end;
      end;
    SM_DEALDELITEM_FAIL:
      begin
        g_dwDealActionTick := GetTickCount;
        if g_DealDlgItem.S.Name <> '' then
        begin
          AddDealItem(g_DealDlgItem);
          g_DealDlgItem.S.Name := '';
        end;
        FrmDlg.CancelItemMoving;
      end;
    SM_DEALREMOTEADDITEM: ClientGetDealRemoteAddItem(body);
    SM_DEALREMOTEDELITEM: ClientGetDealRemoteDelItem(body);
    SM_DEALCHGGOLD_OK:
      begin
        g_nDealGold := msg.Recog;
        g_MySelf.m_nGold := Makelong(msg.param, msg.tag);
        g_dwDealActionTick := GetTickCount;
      end;
    SM_DEALCHGGOLD_FAIL:
      begin
        g_nDealGold := msg.Recog;
        g_MySelf.m_nGold := Makelong(msg.param, msg.tag);
        g_dwDealActionTick := GetTickCount;
      end;
    SM_DEALREMOTECHGGOLD:
      begin
        g_nDealRemoteGold := msg.Recog;
        g_SndMgr.PlaySound(s_money);
      end;
    SM_DEALSUCCESS:
      begin
        FrmDlg.CloseDealDlg;
      end;
    SM_SENDUSERSTORAGEITEM:
      begin
        ClientGetSendUserStorage(msg.Recog);
      end;
    SM_OPENSTORAGEVIEW:
    begin
      ClientGetSendUserStorageView(msg.Recog); //待修改
    end;
    SM_READMINIMAP_OK:
      begin
        g_dwQueryMsgTick := GetTickCount;
        ClientGetReadMiniMap(msg.param);
      end;
    SM_READMINIMAP_FAIL:
      begin
        g_dwQueryMsgTick := GetTickCount;
        DScreen.AddChatBoardString('没有小地图', clWhite, clRed);
        g_nMiniMapIndex := -1;
      end;
    SM_CHANGEGUILDNAME:
      begin
        ClientGetChangeGuildName(DecodeString(body));
      end;
    SM_SENDUSERSTATE:
      begin
        ClientGetSendUserState(body);
      end;
    SM_GUILDADDMEMBER_OK:
      begin
        SendGuildMemberList;
      end;
    SM_GUILDADDMEMBER_FAIL:
      begin
        case msg.Recog of
          1: FrmDlg.DMessageDlg('你没有权利使用这个命令', [mbOk]);
          2: FrmDlg.DMessageDlg('想加入进来的成员应该来面对掌门人', [mbOk]);
          3: FrmDlg.DMessageDlg('对方已经加入我们的行会', [mbOk]);
          4: FrmDlg.DMessageDlg('对方已经加入其他行会', [mbOk]);
          5: FrmDlg.DMessageDlg('对方不允许加入行会', [mbOk]);
        end;
      end;
    SM_GUILDDELMEMBER_OK:
      begin
        SendGuildMemberList;
      end;
    SM_GUILDDELMEMBER_FAIL:
      begin
        case msg.Recog of
          1: FrmDlg.DMessageDlg('不能使用命令！', [mbOk]);
          2: FrmDlg.DMessageDlg('此人非本行会成员！', [mbOk]);
          3: FrmDlg.DMessageDlg('行会掌门人不能开除自己！', [mbOk]);
          4: FrmDlg.DMessageDlg('不能使用命令！', [mbOk]);
        end;
      end;
    SM_GUILDRANKUPDATE_FAIL:
      begin
        case msg.Recog of
          -2: FrmDlg.DMessageDlg('[提示信息] 掌门人位置不能为空', [mbOk]);
          -3: FrmDlg.DMessageDlg('[提示信息] 新的行会掌门人已经被传位', [mbOk]);
          -4: FrmDlg.DMessageDlg('[提示信息] 一个行会最多只能有二个掌门人', [mbOk]);
          -5: FrmDlg.DMessageDlg('[提示信息] 掌门人位置不能为空', [mbOk]);
          -6: FrmDlg.DMessageDlg('[提示信息] 不能添加成员/删除成员', [mbOk]);
          -7: FrmDlg.DMessageDlg('[提示信息] 职位重复或者出错', [mbOk]);
        end;
      end;
    SM_GUILDMAKEALLY_OK,
      SM_GUILDMAKEALLY_FAIL:
      begin
        case msg.Recog of
          -1: FrmDlg.DMessageDlg('您无此权限！', [mbOk]);
          -2: FrmDlg.DMessageDlg('结盟失败！', [mbOk]);
          -3: FrmDlg.DMessageDlg('行会结盟必须双方掌门人面对面！', [mbOk]);
          -4: FrmDlg.DMessageDlg('对方行会掌门人不允许结盟！', [mbOk]);
        end;
      end;
    SM_GUILDBREAKALLY_OK,
      SM_GUILDBREAKALLY_FAIL:
      begin
        case msg.Recog of
          -1: FrmDlg.DMessageDlg('解除结盟！', [mbOk]);
          -2: FrmDlg.DMessageDlg('此行会不是您行会的结盟行会！', [mbOk]);
          -3: FrmDlg.DMessageDlg('没有此行会！', [mbOk]);
        end;
      end;
    SM_BUILDGUILD_OK:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        FrmDlg.DMessageDlg('行会建立成功', [mbOk]);
      end;
    SM_BUILDGUILD_FAIL:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        case msg.Recog of
          -1: FrmDlg.DMessageDlg('您已经加入其它行会', [mbOk]);
          -2: FrmDlg.DMessageDlg('缺少创建费用', [mbOk]);
          -3: FrmDlg.DMessageDlg('你没有准备好需要的全部物品', [mbOk]);
        else
          FrmDlg.DMessageDlg('创建行会失败！！！', [mbOk]);
        end;
      end;
    SM_MENU_OK:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
        if body <> '' then
          FrmDlg.DMessageDlg(DecodeString(body), [mbOk]);
      end;
    SM_DLGMSG:
      begin
        if body <> '' then
          FrmDlg.DMessageDlg(DecodeString(body), [mbOk]);
      end;
    SM_DONATE_OK:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
      end;
    SM_DONATE_FAIL:
      begin
        FrmDlg.LastestClickTime := GetTickCount;
      end;
    SM_PLAYDICE:
      begin
        n := GetCodeMsgSize(SizeOf(TMessageBodyWL) * 4 / 3);
        {if Length(body) > n then begin
          body2 := Copy(body, n + 1, Length(body));
          data := DecodeString(body2);
          body2 := Copy(body, 1, n);
        end else begin
          body2 := body;
          data := '';
        end;}
        body2 := Copy(body, n + 1, Length(body));
        data := DecodeString(body2);
        body2 := Copy(body, 1, n);
        DecodeBuffer(body2, @wl, SizeOf(TMessageBodyWL));
        FrmDlg.m_nDiceCount := msg.param; //QuestActionInfo.nParam1
        FrmDlg.m_Dice[0].nDicePoint := LoByte(LoWord(wl.lParam1)); //UserHuman.m_DyVal[0]
        FrmDlg.m_Dice[1].nDicePoint := HiByte(LoWord(wl.lParam1)); //UserHuman.m_DyVal[0]
        FrmDlg.m_Dice[2].nDicePoint := LoByte(HiWord(wl.lParam1)); //UserHuman.m_DyVal[0]
        FrmDlg.m_Dice[3].nDicePoint := HiByte(HiWord(wl.lParam1)); //UserHuman.m_DyVal[0]

        FrmDlg.m_Dice[4].nDicePoint := LoByte(LoWord(wl.lParam2)); //UserHuman.m_DyVal[0]
        FrmDlg.m_Dice[5].nDicePoint := HiByte(LoWord(wl.lParam2)); //UserHuman.m_DyVal[0]
        FrmDlg.m_Dice[6].nDicePoint := LoByte(HiWord(wl.lParam2)); //UserHuman.m_DyVal[0]
        FrmDlg.m_Dice[7].nDicePoint := HiByte(HiWord(wl.lParam2)); //UserHuman.m_DyVal[0]

        FrmDlg.m_Dice[8].nDicePoint := LoByte(LoWord(wl.lTag1)); //UserHuman.m_DyVal[0]
        FrmDlg.m_Dice[9].nDicePoint := HiByte(LoWord(wl.lTag1)); //UserHuman.m_DyVal[0]
        FrmDlg.DialogSize := 0;
        FrmDlg.DMessageDlg('', []);
        SendMerchantDlgSelect(msg.Recog, data);
      end;
    SM_PASSWORDSTATUS: ClientGetPasswordStatus(@msg, body);
    //SM_GETREGINFO: ClientGetRegInfo(@Msg,Body);
    SM_MARKET_LIST:
      begin
        g_Market.OnMsgWriteData(msg, body);
        FrmDlg.ShowItemMarketDlg;
      end;
    SM_MARKET_RESULT:
      begin
        case msg.param of // Market System..
          UMResult_Success: ;
          UMResult_Fail: FrmDlg.DMessageDlg('[失败]: 使用交易市场出错, 请告知管理员.', [mbOk]);
          UMResult_ReadFail: FrmDlg.DMessageDlg('[失败]: 读取寄售物品列表出错, 请告知管理员.', [mbOk]);
          UMResult_WriteFail: FrmDlg.DMessageDlg('[失败]: 存储寄售物品出错, 请告知管理员.', [mbOk]);
          UMResult_ReadyToSell: ClientGetSendUserMaketSell(msg.Recog);
          UMResult_OverSellCount: FrmDlg.DMessageDlg('[失败]: 寄售物品超过限制. 最多可以寄售 ' + IntToStr(MARKET_MAX_SELL_COUNT) + ' 个物品.', [mbOk]);
          UMResult_LessMoney:
            begin
              FrmDlg.LastestClickTime := GetTickCount;
              if g_SellDlgItemSellWait.Item.S.Name <> '' then
                AddItemBag(g_SellDlgItemSellWait.Item);
              g_SellDlgItemSellWait.Item.S.Name := '';
              FrmDlg.DMessageDlg('[失败]: 你携带的金币不足以支付寄售的费用.', [mbOk]);
            end;
          UMResult_LessLevel: FrmDlg.DMessageDlg('[失败]: 需要 ' + IntToStr(MARKET_ALLOW_LEVEL) + ' 级以上才能使用交易市场.', [mbOk]);
          UMResult_MaxBagItemCount: FrmDlg.DMessageDlg('[失败]: 背包空位不足.', [mbOk]);
          UMResult_NoItem: FrmDlg.DMessageDlg('[失败]: 物品不存在.', [mbOk]);
          UMResult_DontSell:
            begin
              FrmDlg.LastestClickTime := GetTickCount;
              AddItemBag(g_SellDlgItemSellWait.Item);
              g_SellDlgItemSellWait.Item.S.Name := '';
              FrmDlg.DMessageDlg('[失败]: 该物品不能寄售.', [mbOk]);
            end;
          UMResult_DontBuy: FrmDlg.DMessageDlg('[失败]: 不能购买自己的物品.', [mbOk]);
          //UMResult_DontGetMoney: ;
          UMResult_MarketNotReady: FrmDlg.DMessageDlg('[失败]: 交易市场未准备就绪.', [mbOk]);
          UMResult_LessTrustMoney:
            begin
              FrmDlg.LastestClickTime := GetTickCount;
              if g_SellDlgItemSellWait.Item.S.Name <> '' then
                AddItemBag(g_SellDlgItemSellWait.Item);
              g_SellDlgItemSellWait.Item.S.Name := '';
              FrmDlg.DMessageDlg('[失败]: 寄售物品价格至少 ' + IntToStr(MARKET_CHARGE_MONEY) + ' 金币.', [mbOk]);
            end;
          UMResult_MaxTrustMoney: FrmDlg.DMessageDlg('[失败]: 寄售物品价格不能大于 ' + IntToStr(MARKET_MAX_TRUST_MONEY) + ' 金币.', [mbOk]);
          UMResult_CancelFail: FrmDlg.DMessageDlg('[失败]: 该物品不属于你.', [mbOk]);
          UMResult_OverMoney: FrmDlg.DMessageDlg('[失败]: 达到金币存放的限额.', [mbOk]);
          UMResult_SellOK:
            begin
              FrmDlg.DSellDlg.Visible := False;
              FrmDlg.LastestClickTime := GetTickCount;
              g_SellDlgItemSellWait.Item.S.Name := '';
            end;
          UMResult_BuyOK: ;
          UMResult_CancelOK: ;
          UMResult_GetPayOK: ;
        else
        end;
      end;
    SM_AUTOMOVE:
      begin
        AutoMove(msg.Param,msg.Tag);
      end;
    SM_SELLSECCESSITEM:  //  返回批量出售成功的物品结果  
      begin
        if Msg.Param = 0 then exit;
        if g_ItemSell.Count = 0 then exit;

        for I := sizeof(Msg.Param)* 8 - 1 downto 0 do
        begin
          if I > g_ItemSell.Count - 1 then  continue;
          if ((1 shl I) and  Msg.Param)  <> 0  then
          begin
            PItem := pTClientItem(g_ItemSell[I]);
            g_ItemSell.Delete(I);
            dispose(pTClientItem(PItem));
          end;
        end;
      end;
  else
    begin
      {if g_MySelf = nil then Exit;
      g_PlayScene.MemoLog.Lines.Add('Ident: ' + IntToStr(Msg.ident));
      g_PlayScene.MemoLog.Lines.Add('Recog: ' + IntToStr(Msg.Recog));
      g_PlayScene.MemoLog.Lines.Add('Param: ' + IntToStr(Msg.param));
      g_PlayScene.MemoLog.Lines.Add('Tag: ' + IntToStr(Msg.tag));
      g_PlayScene.MemoLog.Lines.Add('Series: ' + IntToStr(Msg.series));}
    end;
  end;
  //if Pos('#', datablock) > 0 then
  //  DScreen.AddSysMsg(datablock);
end;

procedure TfrmMain.ClientGetPasswdSuccess(body: string);
var
  Str, runaddr, runport, certifystr: string;
begin
  //if (g_sLoginKey^ = g_pRcHeader.sWebSite) then begin
  Str := DecodeString(body);
  Str := GetValidStr3(Str, runaddr, ['/']);
  Str := GetValidStr3(Str, runport, ['/']);
  Str := GetValidStr3(Str, certifystr, ['/']);
  Certification := Str_ToInt(certifystr, 0);

  CSocket.Active := False;
  CSocket.Host := '';
  CSocket.Port := 0;
  FrmDlg.DSelServerDlg.Visible := False;
  g_sSelChrAddr := runaddr;
  g_nSelChrPort := Str_ToInt(runport, 0);

  while True do
  begin
    if not CSocket.Socket.Connected then
    begin

      g_ConnectionStep := cnsSelChr;
      g_boQuerySelChar := True;
      with CSocket do
      begin
        g_sSelChrAddr := runaddr;
        g_nSelChrPort := Str_ToInt(runport, 0);
        if isIPAddr(g_sSelChrAddr) then
          Address := g_sSelChrAddr
        else
          Host := g_sSelChrAddr;
        Port := g_nSelChrPort;
        Active := True;
      end;

      Break;
    end;
    Application.ProcessMessages;
    if Application.Terminated then
      Break;
    WaitAndPass(10);
  end;
end;

procedure TfrmMain.ClientGetPasswordOK(msg: TDefaultMessage; sBody: string);
var
  i: Integer;
  sServerName: string;
  sServerStatus: string;
  nCount: Integer;
begin
  {.$I '..\Common\Macros\VMPB.inc'}
    //if (g_sLoginKey^ = g_pRcHeader.sWebSite) then begin
  sBody := DecodeString(sBody);
  nCount := _MIN(6, msg.series);
  g_ServerList.Clear;
  for i := 0 to nCount - 1 do
  begin
    sBody := GetValidStr3(sBody, sServerName, ['/']);
    sBody := GetValidStr3(sBody, sServerStatus, ['/']);
    g_ServerList.AddObject(sServerName, TObject(Str_ToInt(sServerStatus, 0)));
  end;

  g_wAvailIDDay := LoWord(msg.Recog);
  g_wAvailIDHour := HiWord(msg.Recog);
  g_wAvailIPDay := msg.param;
  g_wAvailIPHour := msg.tag;

  if g_wAvailIDDay > 0 then
  begin
    if g_wAvailIDDay = 1 then
      FrmDlg.DMessageDlg('您当前ID费用到今天为止', [mbOk])
    else if g_wAvailIDDay <= 3 then
      FrmDlg.DMessageDlg('您当前IP费用还剩 ' + IntToStr(g_wAvailIDDay) + ' 天', [mbOk]);
  end
  else if g_wAvailIPDay > 0 then
  begin
    if g_wAvailIPDay = 1 then
      FrmDlg.DMessageDlg('您当前IP费用到今天为止', [mbOk])
    else if g_wAvailIPDay <= 3 then
      FrmDlg.DMessageDlg('您当前IP费用还剩 ' + IntToStr(g_wAvailIPDay) + ' 天', [mbOk]);
  end
  else if g_wAvailIPHour > 0 then
  begin
    if g_wAvailIPHour <= 100 then
      FrmDlg.DMessageDlg('您当前IP费用还剩 ' + IntToStr(g_wAvailIPHour) + ' 小时', [mbOk]);
  end
  else if g_wAvailIDHour > 0 then
  begin
    FrmDlg.DMessageDlg('您当前ID费用还剩 ' + IntToStr(g_wAvailIDHour) + ' 小时', [mbOk]);
    ;
  end;

  //if not LoginScene.m_boUpdateAccountMode then
  ClientGetSelectServer;
  //end;
{.$I '..\Common\Macros\VMPE.inc'}
end;

procedure TfrmMain.ClientGetSelectServer;
begin
{$I '..\Common\Macros\VMPB.inc'}
  if g_bLoginKey^ then
  begin
    LoginScene.HideLoginBox;
    FrmDlg.ShowSelectServerDlg;

    g_ModuleDetect.FCheckTick := 0;
  end;
{$I '..\Common\Macros\VMPE.inc'}
end;

procedure TfrmMain.ClientGetNeedUpdateAccount(body: string);
var
  ue: TUserEntry;
begin
  DecodeBuffer(body, @ue, SizeOf(TUserEntry));
  LoginScene.UpdateAccountInfos(ue);
end;

procedure TfrmMain.ClientGetReceiveChrs(body: string);
var
  b: Boolean;
  i, select: Integer;
  Str, uname, sjob, shair, slevel, ssex: string;
  Surface: TDirectDrawSurface;
begin
  if g_boOpenAutoPlay and (g_nAPReLogon = 1) then
  begin //0613
    g_nAPReLogon := 2;
    g_nAPReLogonWaitTick := GetTickCount;
    g_nAPReLogonWaitTime := 5000 + Random(10) * 1000;
  end;

  {.$I '..\Common\Macros\VMPB.inc'}
    //if (g_sLoginKey^ = g_pRcHeader.sWebSite) then begin
  SelectChrScene.ClearChrs;
  Str := DecodeString(body);
  b := False;
  for i := 0 to 1 do
  begin
    Str := GetValidStr3(Str, uname, ['/']);
    Str := GetValidStr3(Str, sjob, ['/']);
    Str := GetValidStr3(Str, shair, ['/']);
    Str := GetValidStr3(Str, slevel, ['/']);
    Str := GetValidStr3(Str, ssex, ['/']);
    select := 0;
    if (uname <> '') and (slevel <> '') and (ssex <> '') then
    begin
      if uname[1] = '*' then
      begin
        select := i;
        uname := Copy(uname, 2, Length(uname) - 1);
      end;
      SelectChrScene.AddChr(uname, Str_ToInt(sjob, 0), Str_ToInt(shair, 0), Str_ToInt(slevel, 0), Str_ToInt(ssex, 0));
      b := True;
      g_ReSelChr := True;
      //FrmDlg.DscStart.tag := FrmDlg.DscStart.WLib.Images[FrmDlg.DscStart.FaceIndex].Height;
      if  FrmDlg.DscStart.ULib <> nil then
      begin
        // Surface := FrmDlg.DscStart.ULib.Images[Format(g_sDscStart, [BYTE(FrmDlg.DscStart.Downed)])];
        Surface := g_Resource98k.Images[46];
        if Surface <> nil then
        begin
          FrmDlg.DscStart.tag := Surface.Height;
          if not g_Logined then
          begin
            g_ReSelChr := False;
            FrmDlg.DscStart.tag := 0;
          end;
        end;
      end;
    end;
    with SelectChrScene do
    begin
      if select = 0 then
      begin
        ChrArr[0].FreezeState := False;
        ChrArr[0].Selected := True;
        ChrArr[1].FreezeState := True;
        ChrArr[1].Selected := False;
      end
      else
      begin
        ChrArr[0].FreezeState := True;
        ChrArr[0].Selected := False;
        ChrArr[1].FreezeState := False;
        ChrArr[1].Selected := True;
      end;
    end;
  end;
  if not g_Logined or not b then
  begin
    g_ReSelChr := False;
    FrmDlg.DscStart.tag := 0;
  end;
  //end;
{//$I '..\Common\Macros\VMPE.inc'}
end;

procedure TfrmMain.ClientGetStartPlay(body: string);
var
  Str, addr, sport: string;
begin
  {//$I '..\Common\Macros\VMPB.inc'}
    //if (g_sLoginKey^ = g_pRcHeader.sWebSite) then begin
  Str := DecodeString(body);

{$IFDEF TEST}
  // Str := '192.168.1.200/7200';
{$ENDIF}
  sport := GetValidStr3(Str, addr, ['/']);
  g_nRunServerPort := Str_ToInt(sport, 0);

  g_sRunServerAddr := addr;
  CSocket.Active := False;
  CSocket.Host := '';
  CSocket.Port := 0;
  Timer2.Enabled := False;


  while True do
  begin
    if not CSocket.Socket.Connected then
    begin
      g_ConnectionStep := cnsPlay;
      with CSocket do
      begin
        if isIPAddr(g_sRunServerAddr) then
          Address := g_sRunServerAddr
        else
          Host := g_sRunServerAddr;
        Port := g_nRunServerPort;
        Active := True;
      end;
      SocStr := '';
      BufferStr := '';
      Break;
    end;
    Application.ProcessMessages;
    if Application.Terminated then
      Break;
    WaitAndPass(10);
  end;
end;

procedure TfrmMain.ClientGetReconnect(body: string);
var
  Str, addr, sport: string;
begin

  Str := DecodeString(body);
  sport := GetValidStr3(Str, addr, ['/']);

  SaveBagsData();
  g_boServerChanging := True;
  CSocket.Active := False;
  CSocket.Host := '';
  CSocket.Port := 0;

  while True do
  begin
    if not CSocket.Socket.Connected then
    begin

      g_ConnectionStep := cnsPlay;
      with CSocket do
      begin
        if isIPAddr(addr) then
          Address := addr
        else
          Host := addr;
        Port := Str_ToInt(sport, 0);
        Active := True;
      end;
      SocStr := '';
      BufferStr := '';

      Break;
    end;
    Application.ProcessMessages;
    if Application.Terminated then
      Break;
    WaitAndPass(10);
  end;
end;

procedure TfrmMain.ClientGetMapDescription(msg: TDefaultMessage; sBody: string);
var
  sTitle: string;
begin
  sBody := DecodeString(sBody);
  sTitle := sBody;
  g_sMapTitle := sTitle;
  LoadWayPoint;

  if not g_gcGeneral[11] then
  begin
    g_nLastMapMusic := msg.Recog;
    g_SndMgr.SilenceSound;
  end
  else
  begin
    if msg.Recog = -1 then
    begin
      g_nLastMapMusic := -1;
      g_SndMgr.SilenceSound;
    end;
    if g_nLastMapMusic <> msg.Recog then
    begin
      g_nLastMapMusic := msg.Recog;
      g_SndMgr.PlaySound('.\Music\' + IntToStr(g_nLastMapMusic) + '.mp3', -1, -1, True);
    end;

    {if msg.Recog = -1 then begin
      g_nLastMapMusic := -1;
      if MP3.InitMusic then begin
        MP3.Pause;
      end;
    end else begin
      if (g_nLastMapMusic = -1) and (MP3.InitMusic) then begin
        MP3.Resume();
      end else if g_nLastMapMusic <> msg.Recog then begin
        g_nLastMapMusic := msg.Recog;
        PlayMapMusic(True);
      end;
    end;}
  end;
end;

procedure TfrmMain.ClientGetGameGoldName(msg: TDefaultMessage; sBody: string);
var
  sData: string;
begin
  if sBody <> '' then
  begin
    sBody := DecodeString(sBody);
    sBody := GetValidStr3(sBody, sData, [#13]);
    g_sGameGoldName := sData;
    g_sGamePointName := sBody;
  end;
  g_MySelf.m_nGameGold := msg.Recog;
  g_MySelf.m_nGamePoint := Makelong(msg.param, msg.tag);
end;

procedure TfrmMain.ClientGetAdjustBonus(bonus: Integer; body: string);
var
  str1, Str2, str3: string;
begin
  g_nBonusPoint := bonus;
  body := GetValidStr3(body, str1, ['/']);
  str3 := GetValidStr3(body, Str2, ['/']);
  DecodeBuffer(str1, @g_BonusTick, SizeOf(TNakedAbility));
  DecodeBuffer(Str2, @g_BonusAbil, SizeOf(TNakedAbility));
  DecodeBuffer(str3, @g_NakedAbil, SizeOf(TNakedAbility));
  FillChar(g_BonusAbilChg, SizeOf(TNakedAbility), #0);
end;

procedure TfrmMain.ClientGetAddItem(Hint: Integer; body: string);
var
  cu: TClientItem;
begin
  if body <> '' then
  begin
    DecodeBuffer(body, @cu, SizeOf(TClientItem));
    AddItemBag(cu);
    if Hint <> 0 then
      DScreen.AddSysMsg(cu.S.Name + ' 被发现');
  end;
end;

procedure TfrmMain.ClientHeroGetAddItem(body: string);
var
  cu: TClientItem;
begin
  if body <> '' then
  begin
    DecodeBuffer(body, @cu, SizeOf(TClientItem));
    HeroAddItemBag(cu);
    DScreen.AddSysMsg(cu.S.Name + ' 在英雄包裹内被发现');
  end;
end;

procedure TfrmMain.ClientGetUpdateItem(body: string);
var
  i: Integer;
  cu: TClientItem;
begin
  if body <> '' then
  begin
    DecodeBuffer(body, @cu, SizeOf(TClientItem));
    UpdateItemBag(cu);

    for i := Low(g_UseItems) to High(g_UseItems) do
    begin
      if (g_UseItems[i].S.Name = cu.S.Name) and (g_UseItems[i].MakeIndex = cu.MakeIndex) then
        g_UseItems[i] := cu;
    end;
    if (g_SellDlgItem.S.Name <> '') and (g_SellDlgItem.MakeIndex = cu.MakeIndex) then
      g_SellDlgItem := cu;

    for i := 0 to 1 do
    begin
      if (g_TIItems[i].Item.MakeIndex = cu.MakeIndex) and (g_TIItems[i].Item.S.Name <> '') then
      begin
        g_TIItems[i].Item := cu;
        if i = 0 then
          GetTIHintString1(1, @g_TIItems[0].Item);
      end;
    end;
    AutoPutOntiBooks();

    for i := 0 to 1 do
    begin
      if (g_spItems[i].Item.MakeIndex = cu.MakeIndex) and (g_spItems[i].Item.S.Name <> '') then
      begin
        g_spItems[i].Item := cu;
      end;
    end;

  end;
end;

procedure TfrmMain.ClientHeroGetUpdateItem(body: string);
var
  i: Integer;
  cu: TClientItem;
begin
  if body <> '' then
  begin
    DecodeBuffer(body, @cu, SizeOf(TClientItem));
    HeroUpdateItemBag(cu);
    for i := Low(g_HeroUseItems) to High(g_HeroUseItems) do
    begin
      if (g_HeroUseItems[i].S.Name = cu.S.Name) and (g_HeroUseItems[i].MakeIndex = cu.MakeIndex) then
        g_HeroUseItems[i] := cu;
    end;
  end;
end;

procedure TfrmMain.ClientGetDelItem(body: string);
var
  i: Integer;
  cu: TClientItem;
begin
  if body <> '' then
  begin
    DecodeBuffer(body, @cu, SizeOf(TClientItem));
    DelItemBag(cu.S.Name, cu.MakeIndex);
    for i := Low(g_UseItems) to High(g_UseItems) do
    begin
      if (g_UseItems[i].S.Name = cu.S.Name) and (g_UseItems[i].MakeIndex = cu.MakeIndex) then
        g_UseItems[i].S.Name := '';
    end;
    for i := 0 to 1 do
    begin
      if (g_TIItems[i].Item.MakeIndex = cu.MakeIndex) then
      begin
        g_TIItems[i].Item.S.Name := '';
        if i = 0 then
          GetTIHintString1(0);
      end;
    end;
    for i := 0 to 1 do
    begin
      if (g_spItems[i].Item.MakeIndex = cu.MakeIndex) then
      begin
        g_spItems[i].Item.S.Name := '';
      end;
    end;

  end;
end;

procedure TfrmMain.ClientHeroGetDelItem(body: string);
var
  i: Integer;
  cu: TClientItem;
begin
  if body <> '' then
  begin
    DecodeBuffer(body, @cu, SizeOf(TClientItem));
    HeroDelItemBag(cu.S.Name, cu.MakeIndex);
    for i := Low(g_HeroUseItems) to High(g_HeroUseItems) do
    begin
      if (g_HeroUseItems[i].S.Name = cu.S.Name) and (g_HeroUseItems[i].MakeIndex = cu.MakeIndex) then
        g_HeroUseItems[i].S.Name := '';
    end;
  end;
end;

procedure TfrmMain.ClientGetDelItems(body: string; wOnlyBag: Word);
var
  i, iindex: Integer;
  Str, iname: string;
  cu: TClientItem;
begin
  body := DecodeString(body);
  while body <> '' do
  begin
    body := GetValidStr3(body, iname, ['/']);
    body := GetValidStr3(body, Str, ['/']);
    if (iname <> '') and (Str <> '') then
    begin
      iindex := Str_ToInt(Str, 0);
      DelItemBag(iname, iindex);
      if wOnlyBag = 0 then
      begin
        for i := Low(g_UseItems) to High(g_UseItems) do
        begin
          if (g_UseItems[i].S.Name = iname) and (g_UseItems[i].MakeIndex = iindex) then
          begin
            g_UseItems[i].S.Name := '';
            Break;
          end;
        end;
      end;
      for i := 0 to 1 do
      begin
        if (g_TIItems[i].Item.MakeIndex = cu.MakeIndex) then
        begin
          g_TIItems[i].Item.S.Name := '';
          if i = 0 then
            GetTIHintString1(0);
        end;
      end;
      for i := 0 to 1 do
      begin
        if (g_spItems[i].Item.MakeIndex = cu.MakeIndex) then
        begin
          g_spItems[i].Item.S.Name := '';
        end;
      end;
    end
    else
      Break;
  end;
end;

procedure TfrmMain.ClientHeroGetDelItems(body: string; wOnlyBag: Word);
var
  i, iindex: Integer;
  Str, iname: string;
begin
  body := DecodeString(body);
  while body <> '' do
  begin
    body := GetValidStr3(body, iname, ['/']);
    body := GetValidStr3(body, Str, ['/']);
    if (iname <> '') and (Str <> '') then
    begin
      iindex := Str_ToInt(Str, 0);
      HeroDelItemBag(iname, iindex);
      if wOnlyBag = 0 then
      begin
        for i := Low(g_HeroUseItems) to High(g_HeroUseItems) do
          if (g_HeroUseItems[i].S.Name = iname) and (g_HeroUseItems[i].MakeIndex = iindex) then
          begin
            g_HeroUseItems[i].S.Name := '';
            Break;
          end;
      end;
    end
    else
      Break;
  end;
end;

procedure TfrmMain.ClientHeroGetBagItmes(body: string; nBagSize: Integer);
var
  n: Integer;
  Str: string;
  cu: TClientItem;
begin
  if nBagSize >= 10 then
  begin
    g_nHeroBagSize := nBagSize;
    FrmDlg.DHeroItemGrid.RowCount := nBagSize div 5;
    FrmDlg.DHeroItemGrid.Height := (nBagSize div 5) * 32;
    case g_nHeroBagSize of
      10: n := 1;
      20: n := 2;
      30: n := 3;
      35: n := 4;
      40: n := 5;
    else
      begin
        n := 5;
        g_nHeroBagSize := 40;
      end;
    end;
    FrmDlg.DHeroItemBag.SetImgIndex(g_WMain3Images, 374 + n);
    //FrmDlg.DHeroItemBag.SetImgName(g_WMainUibImages, Format(g_sHeroItemBag, [n]));
  end;
  FillChar(g_HeroItemArr, SizeOf(TClientItem) * MAXBAGITEMCL, #0);
  while True do
  begin
    if body = '' then
      Break;
    body := GetValidStr3(body, Str, ['/']);
    DecodeBuffer(Str, @cu, SizeOf(TClientItem));
    HeroAddItemBag(cu);
  end;
  //FillChar(ItemSaveArr, SizeOf(TClientItem) * MAXBAGITEMCL, #0);
  //Loadbagsdat('.\Config\' + g_sServerName + '.' + m_sHeroCharName + '.itm-plus', @ItemSaveArr);
  //if CompareItemArr then
  //  Move(ItemSaveArr, g_HeroItemArr, SizeOf(TClientItem) * MAXBAGITEMCL);
  ArrangeHeroItembag;
  //g_boHeroBagLoaded := True;
end;

procedure TFrmMain.ClientGetNpcCustom(body: String);
var
  ptPackage: pTClientNpcCustomPackage;
  ptServer: TNpcCustom;
  Str: String;
  i: Integer;
begin
  Str := '';
  if g_NpcCustomList <> nil then
  begin
    for i := 0 to (g_NpcCustomList.Count - 1) do
    begin
      ptPackage := g_NpcCustomList.Items[i];
      Dispose(ptPackage);
    end;
    g_NpcCustomList.Clear;
  end;

  while True do
  begin
    if body = '' then
      Break;
    body := GetValidStr3(body, Str, ['/']);
    New(ptPackage);
    DecodeBuffer(Str, PChar(@ptServer), SizeOf(TNpcCustom));

    ptPackage^.nNpcCode := ptServer.nNpcCode;
    ptPackage^.nNpcDir := ptServer.nNpcDir;
    ptPackage^.DrawCustom := GetImageFileByIndexCustom(ptServer.nResFileIndex);
    ptPackage^.nStandStartOffset := ptServer.nStandStartOffset;
    ptPackage^.bStandUseEffect := ptServer.bStandUseEffect;
    ptPackage^.nStandEffectStartOffset := ptServer.nStandEffectStartOffset;
    ptPackage^.nStandPlayCount := ptServer.nStandPlayCount;
    ptPackage^.nHitStartOffset := ptServer.nHitStartOffset;
    ptPackage^.bHitUseEffect := ptServer.bHitUseEffect;
    ptPackage^.nHitEffectStartOffset := ptServer.nHitEffectStartOffset;
    ptPackage^.nHitPlayCount := ptServer.nHitPlayCount;
    ptPackage^.nPlaySpeed := ptServer.nPlaySpeed;

    g_NpcCustomList.Add(ptPackage);
  end;

end;

procedure TFrmMain.ClientGetSafeZoneEffectCustom(body: String);
var
  ptPackage: pTClientSafeZoneEffectCustomPackage;
  ptServer: TStartPointCustom;
  Str: String;
  i: Integer;
begin
  Str := '';
  if g_SafeZoneEffectCustomList <> nil then
  begin
    for i := 0 to (g_SafeZoneEffectCustomList.Count - 1) do
    begin
      ptPackage := g_SafeZoneEffectCustomList.Items[i];
      Dispose(ptPackage);
    end;
    g_SafeZoneEffectCustomList.Clear;
  end;

  while True do
  begin
    if body = '' then
      Break;
    body := GetValidStr3(body, Str, ['/']);
    New(ptPackage);
    DecodeBuffer(Str, PChar(@ptServer), SizeOf(TStartPointCustom));
    ptPackage^.EventType := ptServer.nEffectsType;
    ptPackage^.DrawCustom := GetImageFileByIndexCustom(ptServer.nEffectsFileIndex);
    ptPackage^.nEffectsStartOffset := ptServer.nEffectsStartOffset;
    ptPackage^.nEffectsCountOffset := ptServer.nEffectsCountOffset;
    ptPackage^.bEffectsBlendDraw := ptServer.bEffectsBlendDraw;
    ptPackage^.nEffectsSpeed := ptServer.nEffectsSpeed;
    g_SafeZoneEffectCustomList.Add(ptPackage);
  end;

end;

procedure TfrmMain.ClientGetBagItmes(body: string);
var
  i, k: Integer;
  Str: string;
  cu: TClientItem;
  ItemSaveArr: array[0..MAXBAGITEMCL - 1] of TClientItem;

  function CompareItemArr: Boolean;
  var
    i, j: Integer;
    flag: Boolean;
  begin
    flag := True;
    for i := 0 to MAXBAGITEMCL - 1 do
    begin
      if ItemSaveArr[i].S.Name <> '' then
      begin
        flag := False;
        for j := 0 to MAXBAGITEMCL - 1 do
        begin
          if (g_ItemArr[j].S.Name = ItemSaveArr[i].S.Name) and (g_ItemArr[j].MakeIndex = ItemSaveArr[i].MakeIndex) then
          begin
            if (g_ItemArr[j].Dura = ItemSaveArr[i].Dura) and (g_ItemArr[j].DuraMax = ItemSaveArr[i].DuraMax) then
              flag := True;
            Break;
          end;
        end;
        if not flag then
          Break;
      end;
    end;
    if flag then
    begin
      for i := 0 to MAXBAGITEMCL - 1 do
      begin
        if g_ItemArr[i].S.Name <> '' then
        begin
          flag := False;
          for j := 0 to MAXBAGITEMCL - 1 do
          begin
            if (g_ItemArr[i].S.Name = ItemSaveArr[j].S.Name) and
              (g_ItemArr[i].MakeIndex = ItemSaveArr[j].MakeIndex) then
            begin
              if (g_ItemArr[i].Dura = ItemSaveArr[j].Dura) and
                (g_ItemArr[i].DuraMax = ItemSaveArr[j].DuraMax) then
              begin
                flag := True;
              end;
              Break;
            end;
          end;
          if not flag then
            Break;
        end;
      end;
    end;
    Result := flag;
  end;
begin
  g_SellDlgItem.S.Name := '';
  //FillChar(g_BuildItems, SizeOf(g_BuildItems), #0);
  FillChar(g_RefineItems, SizeOf(TMovingItem) * 3, #0);
  FillChar(g_BuildAcuses, SizeOf(g_BuildAcuses), #0);
  //if not g_MySelf.m_StallMgr.OnSale then FillChar(g_MySelf.m_StallMgr.mBlock.Items, SizeOf(TClientItem) * 10, #0);
  FillChar(g_ItemArr, SizeOf(TClientItem) * MAXBAGITEMCL, #0);

  FillChar(g_TIItems, SizeOf(g_TIItems), #0);
  FillChar(g_spItems, SizeOf(g_spItems), #0);

  if (g_MovingItem.Item.S.Name <> '') and (IsBagItem(g_MovingItem.Index)) then
  begin
    g_MovingItem.Item.S.Name := '';
    g_boItemMoving := False;
  end;

  while True do
  begin
    if body = '' then
      Break;
    body := GetValidStr3(body, Str, ['/']);
    DecodeBuffer(Str, @cu, SizeOf(TClientItem));
    AddItemBag(cu);
  end;

  FillChar(ItemSaveArr, SizeOf(TClientItem) * MAXBAGITEMCL, #0);
  Loadbagsdat('.\Config\' + g_sServerName + '.' + m_sCharName + '.itm-plus', @ItemSaveArr);
  if CompareItemArr then
    Move(ItemSaveArr, g_ItemArr, SizeOf(TClientItem) * MAXBAGITEMCL);
  ArrangeItembag;
  g_boBagLoaded := True;

  if g_MySelf <> nil then
  begin
    if not g_MySelf.m_StallMgr.OnSale then
    begin
      for i := 0 to 9 do
      begin
        if g_MySelf.m_StallMgr.mBlock.Items[i].S.Name <> '' then
        begin
          UpdateBagStallItem(g_MySelf.m_StallMgr.mBlock.Items[i], 4);
        end;
      end;
    end
    else
    begin
      for i := 0 to 9 do
      begin
        if g_MySelf.m_StallMgr.mBlock.Items[i].S.Name <> '' then
        begin
          UpdateBagStallItem(g_MySelf.m_StallMgr.mBlock.Items[i], 5);
        end;
      end;
    end;
  end;

  if g_boOpenAutoPlay and (g_nAPReLogon = 4) then
  begin //0613
    g_nAPReLogon := 0;
    g_nOverAPZone := g_nOverAPZone2;
    g_APGoBack := g_APGoBack2;
    if g_APMapPath2 <> nil then
    begin
      SetLength(g_APMapPath, High(g_APMapPath2) + 1);
      for k := 0 to High(g_APMapPath2) do
        g_APMapPath[k] := g_APMapPath2[k];
    end;
    g_APLastPoint := g_APLastPoint2;
    g_APStep := g_APStep2;

    g_gcAss[0] := True;
    g_APTagget := nil;
    g_AutoPicupItem := nil;
    g_nAPStatus := -1;
    g_nTargetX := -1;

    g_APGoBack2 := False;
    g_APMapPath2 := nil;
    GetNearPoint();
    frmMain.TimerAutoPlay.Enabled := g_gcAss[0];
    DScreen.AddChatBoardString('[挂机] 开始自动挂机...', clWhite, clRed);
    SaveWayPoint;
    if g_nAPrlRecallHero or (g_MySelf.m_HeroObject = nil) then
    begin //:= (g_MySelf.m_HeroObject <> nil);
      FrmDlg.m_dwUnRecallHeroTick := GetTickCount - 58000;
    end;

  end;
end;

procedure TfrmMain.ClientGetDropItemFail(iname: string; sindex: Integer);
var
  pc: PTClientItem;
begin
  pc := GetDropItem(iname, sindex);
  if pc <> nil then
  begin
{$IFDEF WEAPON_DROP}
//    if pc.WeaponIndex < 0 then
//    begin
//      sel := pc.WeaponIndex;
//      sel := -(sel + 1);
//      if (sel >= 0) and (sel <= U_FASHION) then
//      begin
//        g_UseItems[sel] := pc^;
//      end;
//      DelDropItem(iname, sindex);
//      exit;
//    end;
    if (g_pweapon <> nil) and (g_pweapon.MakeIndex = pc.MakeIndex) then
    begin
      g_pweapon.s.Name := pc.s.Name;
      DelDropItem(iname, sindex);
      exit;
    end;
{$ENDIF}
    AddItemBag(pc^);
    DelDropItem(iname, sindex);
  end;
end;

procedure TfrmMain.ClientHeroGetDropItemFail(iname: string; sindex: Integer);
var
  pc: PTClientItem;
begin
  pc := GetDropItem(iname, sindex);
  if pc <> nil then
  begin
    HeroAddItemBag(pc^);
    DelDropItem(iname, sindex);
  end;
end;

procedure TfrmMain.ClientGetShowItem(itemid, X, Y, looks: Integer; itmname: string);
var
  i: Integer;
  DropItem: pTDropItem;
  P: pTCItemRule;
begin
  for i := 0 to g_DropedItemList.count - 1 do
  begin
    if pTDropItem(g_DropedItemList[i]).ID = itemid then
      Exit;
  end;
  New(DropItem);
  DropItem.ID := itemid;
  DropItem.X := X;
  DropItem.Y := Y;
  DropItem.looks := looks;
  DropItem.Name := itmname;
  GetValidStr3(DropItem.Name, itmname, ['\']);
  DropItem.FlashTime := GetTickCount - LongWord(Random(3000));
  DropItem.BoFlash := False;

  DropItem.boNonSuch := False;
  DropItem.boShowName := g_ShowItemList.IndexOf(itmname) < 0; //True;
  DropItem.boPickUp := DropItem.boShowName;

  if g_gcAss[5] then
  begin
    DropItem.boNonSuch := False;
    DropItem.boPickUp := False;
    DropItem.boShowName := False;
    i := g_APPickUpList.IndexOf(itmname);
    if i >= 0 then
    begin
      DropItem.boNonSuch := Integer(g_APPickUpList.Objects[i]) <> 0;
      DropItem.boPickUp := True;
      if not DropItem.boNonSuch then
        DropItem.boShowName := True;
    end;
  end
  else
  begin
    P := pTCItemRule(g_ItemsFilter_All.GetValues(itmname));
    if P <> nil then
    begin
      DropItem.boNonSuch := P.rare;
      DropItem.boPickUp := P.pick;
      DropItem.boShowName := P.show;
    end;
  end;

  //DropItem.boShowName := g_ShowItemList.IndexOf(itmname) < 0;
  //if g_gcAss[5] then DropItem.boShowName := g_APPickUpList.IndexOf(itmname) >= 0;

  g_DropedItemList.Add(DropItem);
end;

procedure TfrmMain.ClientGetHideItem(itemid, X, Y: Integer);
var
  i: Integer;
  DropItem: pTDropItem;
begin
  for i := 0 to g_DropedItemList.count - 1 do
  begin
    DropItem := g_DropedItemList[i];
    if DropItem.ID = itemid then
    begin
      Dispose(DropItem);
      g_DropedItemList.Delete(i);
      Break;
    end;
  end;
end;

procedure TfrmMain.ClientGetSendUseItems(body: string);
var
  Index: Integer;
  Str, data: string;
  cu: TClientItem;
begin
  FillChar(g_UseItems, SizeOf(TClientItem) * 14, #0);
  while True do
  begin
    if body = '' then
      Break;
    body := GetValidStr3(body, Str, ['/']);
    body := GetValidStr3(body, data, ['/']);
    Index := Str_ToInt(Str, -1);
    if Index in [0..U_FASHION] then
    begin
      DecodeBuffer(data, @cu, SizeOf(TClientItem));
      g_UseItems[Index] := cu;
    end;
  end;
end;

procedure TfrmMain.ClientGetSendHeroUseItems(body: string);
var
  Index: Integer;
  Str, data: string;
  cu: TClientItem;
begin
  FillChar(g_HeroUseItems, SizeOf(TClientItem) * 14, #0);
  while True do
  begin
    if body = '' then
      Break;
    body := GetValidStr3(body, Str, ['/']);
    body := GetValidStr3(body, data, ['/']);
    Index := Str_ToInt(Str, -1);
    if Index in [0..U_FASHION] then
    begin
      DecodeBuffer(data, @cu, SizeOf(TClientItem));
      g_HeroUseItems[Index] := cu;
    end;
  end;
end;

procedure TfrmMain.ClientGetAddMagic(body: string);

  function ListSortCompareLevel(Item1, Item2: Pointer): Integer;
  begin
    Result := 1;
    if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) < Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := -1
    else if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) = Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := 0;
  end;

var
  i: Integer;
  pcm: PTClientMagic;
begin
  New(pcm);
  DecodeBuffer(body, @(pcm^), SizeOf(TClientMagic));
  g_MagicArr[pcm.Def.btclass][pcm.Def.wMagicid] := pcm;
{$IF SERIESSKILL}
  if pcm.Def.wMagicid in [100..111] then
  begin
    if pcm.Def.btclass = 0 then
    begin
      if pcm.Def.btJob = g_MySelf.m_btJob then
        if g_MagicList2.count <= 3 then
          g_MagicList2.Add(pcm);
      g_MagicList2.Sort(@ListSortCompareLevel);
    end
    else
      g_IPMagicList.Add(pcm);
  end
  else
{$IFEND SERIESSKILL}begin
    if pcm.Def.btclass = 0 then
      g_MagicList.Add(pcm)
    else
      g_IPMagicList.Add(pcm);
  end;
  for i := 0 to g_MagicList.count - 1 do
    if PTClientMagic(g_MagicList[i]).Def.wMagicid = 67 then
    begin
      g_MagicList.Move(i, 0);
      Break;
    end;
end;

procedure TfrmMain.ClientHeroGetAddMagic(body: string);

  function ListSortCompareLevel(Item1, Item2: Pointer): Integer;
  begin
    Result := 1;
    if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) < Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := -1
    else if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) = Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := 0;
  end;

var
  pcm: PTClientMagic;
begin
  New(pcm);
  DecodeBuffer(body, @(pcm^), SizeOf(TClientMagic));
{$IF SERIESSKILL}
  if pcm.Def.wMagicid in [100..111] then
  begin
    if pcm.Def.btclass = 0 then
    begin
      if pcm.Def.btJob = g_MySelf.m_HeroObject.m_btJob then
        if g_hMagicList2.count <= 3 then
          g_hMagicList2.Add(pcm);
      g_hMagicList2.Sort(@ListSortCompareLevel);
    end
    else
      g_HeroIPMagicList.Add(pcm);
  end
  else
{$IFEND SERIESSKILL}begin
    if pcm.Def.btclass = 0 then
      g_HeroMagicList.Add(pcm)
    else
      g_HeroIPMagicList.Add(pcm);
  end;
end;

procedure TfrmMain.ClientGetDelMagic(magid, btclass: Integer);
var
  i: Integer;
begin
  if btclass = 0 then
  begin
{$IF SERIESSKILL}
    for i := g_MagicList2.count - 1 downto 0 do
    begin
      if PTClientMagic(g_MagicList2[i]).Def.wMagicid = magid then
      begin
        Dispose(PTClientMagic(g_MagicList2[i]));
        g_MagicList2.Delete(i);
        Break;
      end;
    end;
{$IFEND SERIESSKILL}
    for i := g_MagicList.count - 1 downto 0 do
    begin
      if PTClientMagic(g_MagicList[i]).Def.wMagicid = magid then
      begin
        Dispose(PTClientMagic(g_MagicList[i]));
        g_MagicList.Delete(i);
        Break;
      end;
    end;
  end
  else
  begin
    for i := g_IPMagicList.count - 1 downto 0 do
    begin
      if PTClientMagic(g_IPMagicList[i]).Def.wMagicid = magid then
      begin
        Dispose(PTClientMagic(g_IPMagicList[i]));
        g_IPMagicList.Delete(i);
        Break;
      end;
    end;
  end;
  g_MagicArr[btclass][magid] := nil;
end;

procedure TfrmMain.ClientConvertMagic(t1, t2, id1, id2: Integer; S: string);

  function ListSortCompareLevel(Item1, Item2: Pointer): Integer;
  begin
    Result := 1;
    if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) < Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := -1
    else if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) = Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := 0;
  end;

var
  i: Integer;
  cm: TClientMagic;
  pcm: PTClientMagic;
begin
  DecodeBuffer(S, @cm, SizeOf(TClientMagic));
  if t1 = 0 then
  begin
    for i := g_MagicList2.count - 1 downto 0 do
    begin
      pcm := PTClientMagic(g_MagicList2[i]);
      if pcm.Def.wMagicid = id1 then
      begin
        //pcm.Def.btclass := t2;
        //pcm.Def.wMagicid := id2;
        //pcm.Def.sMagicName := S;
        pcm^ := cm;
        if t1 = t2 then
        begin //update
          g_MagicArr[t1][id1] := nil;
          g_MagicArr[t1][id2] := pcm;
        end
        else
        begin //convert
          g_MagicList2.Delete(i);
          g_MagicList2.Sort(@ListSortCompareLevel);
          g_IPMagicList.Add(pcm);
          g_MagicArr[t1][id1] := nil;
          g_MagicArr[t2][id2] := pcm;
        end;
        Break;
      end;
    end;
    for i := g_MagicList.count - 1 downto 0 do
    begin
      pcm := PTClientMagic(g_MagicList[i]);
      if pcm.Def.wMagicid = id1 then
      begin
        //pcm.Def.btclass := t2;
        //pcm.Def.wMagicid := id2;
        //pcm.Def.sMagicName := S;
        pcm^ := cm;
        if t1 = t2 then
        begin
          g_MagicArr[t1][id1] := nil;
          g_MagicArr[t1][id2] := pcm;
        end
        else
        begin
          g_MagicList.Delete(i);
          g_IPMagicList.Add(pcm);
          g_MagicArr[t1][id1] := nil;
          g_MagicArr[t2][id2] := pcm;
        end;
        Break;
      end;
    end;
  end
  else
  begin
    for i := g_IPMagicList.count - 1 downto 0 do
    begin
      pcm := PTClientMagic(g_IPMagicList[i]);
      if pcm.Def.wMagicid = id1 then
      begin
        //pcm.Def.btclass := t2;
        //pcm.Def.wMagicid := id2;
        //pcm.Def.sMagicName := S;
        pcm^ := cm;
        if t1 = t2 then
        begin //update
          g_MagicArr[t1][id1] := nil;
          g_MagicArr[t1][id2] := pcm;
        end
        else
        begin //convert
          g_IPMagicList.Delete(i);
{$IF SERIESSKILL}
          if pcm.Def.wMagicid in [100..111] then
          begin
            //if pcm.Def.btJob = g_MySelf.m_btJob then
            if g_MagicList2.count <= 3 then
              g_MagicList2.Add(pcm);
            g_MagicList2.Sort(@ListSortCompareLevel);
          end
          else
{$IFEND SERIESSKILL}begin
            g_MagicList.Add(pcm);
          end;
          g_MagicArr[t1][id1] := nil;
          g_MagicArr[t2][id2] := pcm;
        end;
        Break;
      end;
    end;
  end;

end;

procedure TfrmMain.hClientConvertMagic(t1, t2, id1, id2: Integer; S: string);

  function ListSortCompareLevel(Item1, Item2: Pointer): Integer;
  begin
    Result := 1;
    if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) < Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := -1
    else if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) = Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := 0;
  end;

var
  i: Integer;
  pcm: PTClientMagic;
  cm: TClientMagic;
begin
  //DScreen.AddChatBoardString(format('%d %d %d %d %s', [t1, t2, id1, id2, S]), clWhite, clRed);

  DecodeBuffer(S, @cm, SizeOf(TClientMagic));

  if t1 = 0 then
  begin
    for i := g_hMagicList2.count - 1 downto 0 do
    begin
      pcm := PTClientMagic(g_hMagicList2[i]);
      if pcm.Def.wMagicid = id1 then
      begin
        //pcm.Def.btclass := t2;
        //pcm.Def.wMagicid := id2;
        //pcm.Def.sMagicName := S;
        pcm^ := cm;
        //DScreen.AddChatBoardString('1111111', clWhite, clRed);
        if t1 = t2 then
        begin //update
          //g_MagicArr[t1][id1] := nil;
          //g_MagicArr[t1][id2] := pcm;
        end
        else
        begin //convert
          g_hMagicList2.Delete(i);
          g_hMagicList2.Sort(@ListSortCompareLevel);
          g_HeroIPMagicList.Add(pcm);
          //g_MagicArr[t1][id1] := nil;
          //g_MagicArr[t2][id2] := pcm;
        end;
        Break;
      end;
    end;
    for i := g_HeroMagicList.count - 1 downto 0 do
    begin
      pcm := PTClientMagic(g_HeroMagicList[i]);
      if pcm.Def.wMagicid = id1 then
      begin
        //pcm.Def.btclass := t2;
        //pcm.Def.wMagicid := id2;
        //pcm.Def.sMagicName := S;
        pcm^ := cm;
        if t1 = t2 then
        begin
          //g_MagicArr[t1][id1] := nil;
          //g_MagicArr[t1][id2] := pcm;
        end
        else
        begin
          g_HeroMagicList.Delete(i);
          g_HeroIPMagicList.Add(pcm);
          //g_MagicArr[t1][id1] := nil;
          //g_MagicArr[t2][id2] := pcm;
        end;
        Break;
      end;
    end;
  end
  else
  begin
    for i := g_HeroIPMagicList.count - 1 downto 0 do
    begin
      pcm := PTClientMagic(g_HeroIPMagicList[i]);
      if pcm.Def.wMagicid = id1 then
      begin
        //pcm.Def.btclass := t2;
        //pcm.Def.wMagicid := id2;
        //pcm.Def.sMagicName := S;
        pcm^ := cm;
        if t1 = t2 then
        begin //update
          //g_MagicArr[t1][id1] := nil;
          //g_MagicArr[t1][id2] := pcm;
        end
        else
        begin //convert
          g_HeroIPMagicList.Delete(i);
{$IF SERIESSKILL}
          if pcm.Def.wMagicid in [100..111] then
          begin
            //if pcm.Def.btJob = g_MySelf.m_btJob then
            if g_hMagicList2.count <= 3 then
              g_hMagicList2.Add(pcm);
            g_hMagicList2.Sort(@ListSortCompareLevel);
          end
          else
{$IFEND SERIESSKILL}begin
            g_HeroMagicList.Add(pcm);
          end;
          //g_MagicArr[t1][id1] := nil;
          //g_MagicArr[t2][id2] := pcm;
        end;
        Break;
      end;
    end;
  end;

end;

procedure TfrmMain.ClientHeroGetDelMagic(magid, btclass: Integer);
var
  i: Integer;
begin
  if btclass = 0 then
  begin
{$IF SERIESSKILL}
    for i := g_hMagicList2.count - 1 downto 0 do
    begin
      if PTClientMagic(g_hMagicList2[i]).Def.wMagicid = magid then
      begin
        Dispose(PTClientMagic(g_hMagicList2[i]));
        g_hMagicList2.Delete(i);
        Break;
      end;
    end;
{$IFEND SERIESSKILL}
    for i := g_HeroMagicList.count - 1 downto 0 do
    begin
      if PTClientMagic(g_HeroMagicList[i]).Def.wMagicid = magid then
      begin
        Dispose(PTClientMagic(g_HeroMagicList[i]));
        g_HeroMagicList.Delete(i);
        Break;
      end;
    end;
  end
  else
  begin
    for i := g_HeroIPMagicList.count - 1 downto 0 do
    begin
      if PTClientMagic(g_HeroIPMagicList[i]).Def.wMagicid = magid then
      begin
        Dispose(PTClientMagic(g_HeroIPMagicList[i]));
        g_HeroIPMagicList.Delete(i);
        Break;
      end;
    end;
  end;

end;

procedure TfrmMain.ClientGetMyMagics(body: string);

  function ListSortCompareLevel(Item1, Item2: Pointer): Integer;
  begin
    Result := 1;
    if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) < Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := -1
    else if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) = Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := 0;
  end;

var
  i: Integer;
  data: string;
  pcm: PTClientMagic;
begin
  for i := 0 to g_MagicList.count - 1 do
    Dispose(PTClientMagic(g_MagicList[i]));
  g_MagicList.Clear;

{$IF SERIESSKILL}
  for i := 0 to g_MagicList2.count - 1 do
    Dispose(PTClientMagic(g_MagicList2[i]));
  g_MagicList2.Clear;
{$IFEND SERIESSKILL}

  for i := 0 to g_IPMagicList.count - 1 do
    Dispose(PTClientMagic(g_IPMagicList[i]));
  g_IPMagicList.Clear;
  FillChar(g_MagicArr, SizeOf(g_MagicArr), 0);
  while True do
  begin
    if body = '' then
      Break;
    body := GetValidStr3(body, data, ['/']);
    if data <> '' then
    begin
      New(pcm);
      DecodeBuffer(data, @(pcm^), SizeOf(TClientMagic));
{$IF SERIESSKILL}
      if pcm.Def.wMagicid in [100..111] then
      begin
        if pcm.Def.btclass = 0 then
        begin
          if pcm.Def.btJob = g_MySelf.m_btJob then
            if g_MagicList2.count <= 3 then
              g_MagicList2.Add(pcm);
          g_MagicList2.Sort(@ListSortCompareLevel);
        end
        else
          g_IPMagicList.Add(pcm);
      end
      else
{$IFEND SERIESSKILL}begin
        if pcm.Def.btclass = 0 then
          g_MagicList.Add(pcm)
        else
          g_IPMagicList.Add(pcm);
      end;
      g_MagicArr[pcm.Def.btclass][pcm.Def.wMagicid] := pcm;
    end
    else
      Break;
  end;
  for i := 0 to g_MagicList.count - 1 do
    if PTClientMagic(g_MagicList[i]).Def.wMagicid = 67 then
    begin
      g_MagicList.Move(i, 0);
      Break;
    end;
end;

procedure TfrmMain.ClientGetHeroMagics(body: string);

  function ListSortCompareLevel(Item1, Item2: Pointer): Integer;
  begin
    Result := 1;
    if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) < Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := -1
    else if Integer(PTClientMagic(Item1).Def.TrainLevel[0]) = Integer(PTClientMagic(Item2).Def.TrainLevel[0]) then
      Result := 0;
  end;

var
  i: Integer;
  data: string;
  pcm: PTClientMagic;
begin
  for i := 0 to g_HeroMagicList.count - 1 do
    Dispose(PTClientMagic(g_HeroMagicList[i]));
  g_HeroMagicList.Clear;
{$IF SERIESSKILL}
  for i := 0 to g_hMagicList2.count - 1 do
    Dispose(PTClientMagic(g_hMagicList2[i]));
  g_hMagicList2.Clear;
{$IFEND SERIESSKILL}
  for i := 0 to g_HeroIPMagicList.count - 1 do
    Dispose(PTClientMagic(g_HeroIPMagicList[i]));
  g_HeroIPMagicList.Clear;
  while True do
  begin
    if body = '' then
      Break;
    body := GetValidStr3(body, data, ['/']);
    if data <> '' then
    begin
      New(pcm);
      DecodeBuffer(data, @(pcm^), SizeOf(TClientMagic));
{$IF SERIESSKILL}
      if pcm.Def.wMagicid in [100..111] then
      begin
        if pcm.Def.btclass = 0 then
        begin
          if pcm.Def.btJob = g_MySelf.m_HeroObject.m_btJob then
            if g_hMagicList2.count <= 3 then
              g_hMagicList2.Add(pcm);
          g_hMagicList2.Sort(@ListSortCompareLevel);
        end
        else
          g_HeroIPMagicList.Add(pcm);
      end
      else
{$IFEND SERIESSKILL}begin
        if pcm.Def.btclass = 0 then
          g_HeroMagicList.Add(pcm)
        else
          g_HeroIPMagicList.Add(pcm);
      end;
    end
    else
      Break;
  end;
end;

procedure TfrmMain.ClientGetShopItems(body: string; Int: Integer);
var
  data: string;
  pSi: pTShopItem;
begin
  g_btSellType := Int;
  while True do
  begin
    if body = '' then
      Break;
    body := GetValidStr3(body, data, ['/']);
    if data <> '' then
    begin
      New(pSi);
      DecodeBuffer(data, @(pSi^), SizeOf(TShopItem));
      g_ShopListArr[pSi.btclass].Add(pSi);
    end
    else
      Break;
  end;
end;

procedure TfrmMain.ClientGetMagicLvExp(magid, maglv, magtrain: Integer);
var
  nType: Integer;
  pcm: PTClientMagic;
begin
  nType := HiWord(magid);
  magid := LoWord(magid);
  pcm := g_MagicArr[nType][magid];
  if pcm <> nil then
  begin
    pcm.level := maglv;
    pcm.CurTrain := magtrain;
  end;
end;

procedure TfrmMain.ClientGetMagicMaxLv(magid, magMaxlv, hero: Integer);
var
  i: Integer;
  pcm: PTClientMagic;
begin
  magid := LoWord(magid);
  if hero = 0 then
  begin
    pcm := g_MagicArr[0][magid];
    if (magid <= 0) or (magid >= 255) then
    begin
      Exit;
    end;
    if pcm <> nil then
      pcm.Def.btTrainLv := magMaxlv;
  end
  else
  begin
    for i := g_hMagicList2.count - 1 downto 0 do
    begin
      if PTClientMagic(g_hMagicList2[i]).Def.wMagicid = magid then
      begin
        PTClientMagic(g_hMagicList2[i]).Def.btTrainLv := magMaxlv;
        Exit;
      end;
    end;
    for i := g_HeroMagicList.count - 1 downto 0 do
    begin
      if PTClientMagic(g_HeroMagicList[i]).Def.wMagicid = magid then
      begin
        PTClientMagic(g_HeroMagicList[i]).Def.btTrainLv := magMaxlv;
        Break;
      end;
    end;
  end;
end;

procedure TfrmMain.ClientHeroGetMagicLvExp(magid, maglv, magtrain: Integer);
var
  i, nType: Integer;
begin
  nType := HiWord(magid);
  magid := LoWord(magid);
  if nType = 0 then
  begin
    for i := g_hMagicList2.count - 1 downto 0 do
    begin
      if PTClientMagic(g_hMagicList2[i]).Def.wMagicid = magid then
      begin
        PTClientMagic(g_hMagicList2[i]).level := maglv;
        PTClientMagic(g_hMagicList2[i]).CurTrain := magtrain;
        Exit;
      end;
    end;
    for i := g_HeroMagicList.count - 1 downto 0 do
    begin
      if PTClientMagic(g_HeroMagicList[i]).Def.wMagicid = magid then
      begin
        PTClientMagic(g_HeroMagicList[i]).level := maglv;
        PTClientMagic(g_HeroMagicList[i]).CurTrain := magtrain;
        Break;
      end;
    end;
  end
  else
  begin
    for i := g_hMagicList2.count - 1 downto 0 do
    begin
      if PTClientMagic(g_hMagicList2[i]).Def.wMagicid = magid then
      begin
        PTClientMagic(g_hMagicList2[i]).level := maglv;
        PTClientMagic(g_hMagicList2[i]).CurTrain := magtrain;
        Exit;
      end;
    end;
    for i := g_HeroIPMagicList.count - 1 downto 0 do
    begin
      if (PTClientMagic(g_HeroIPMagicList[i]).Def.wMagicid = magid) and (nType = PTClientMagic(g_HeroIPMagicList[i]).Def.btclass) then
      begin
        PTClientMagic(g_HeroIPMagicList[i]).level := maglv;
        PTClientMagic(g_HeroIPMagicList[i]).CurTrain := magtrain;
        Break;
      end;
    end;
  end;
end;

function GetMagicLv(Actor: TActor; magid: Integer): Integer;
var
  i: Integer;
begin
  Result := 0;
  if (Actor = nil) then
    Exit;
  if (magid <= 0) or (magid >= 255) then
  begin
    Exit;
  end;
  if Actor.m_btIsHero = 1 then
  begin
    for i := g_HeroMagicList.count - 1 downto 0 do
    begin
      if PTClientMagic(g_HeroMagicList[i]).Def.wMagicid = magid then
      begin
        Result := PTClientMagic(g_HeroMagicList[i]).level;
        Break;
      end;
    end;
  end
  else
  begin
    if g_MagicArr[0][magid] <> nil then
      Result := g_MagicArr[0][magid].level;
    {for i := g_MagicList.count - 1 downto 0 do begin
      if PTClientMagic(g_MagicList[i]).Def.wMagicId = magid then begin
        Result := PTClientMagic(g_MagicList[i]).level;
        Break;
      end;
    end;}
  end;
end;

procedure TfrmMain.ClientGetDuraChange(uidx, newdura, newduramax: Integer);
begin
  if uidx in [0..U_FASHION] then
  begin
    if g_UseItems[uidx].S.Name <> '' then
    begin
      g_UseItems[uidx].Dura := newdura;
      g_UseItems[uidx].DuraMax := newduramax;
    end;
  end;
end;

procedure TfrmMain.ClientGetBagDuraChange(MakeIndex: Integer; NewDura: Word; isHero: Boolean; WaitItemToBag: boolean);
var
  I: Integer;
begin
  if (WaitItemToBag) and (g_WaitingUseItem.Item.S.Name <> '') then
  begin
    if not isHero  then
    begin
      AddItemBag(g_WaitingUseItem.Item, g_WaitingUseItem.Index);
      g_WaitingUseItem.Item.S.Name := '';
    end
    else
    begin
      HeroAddItemBag(g_WaitingUseItem.Item);
      g_WaitingUseItem.Item.S.Name := '';
    end;
  end;

  I := 0;
  if not isHero then
  begin
    while I <= Length(g_ItemArr) - 1 do
    begin
      if (g_ItemArr[I].MakeIndex = MakeIndex) and (g_ItemArr[I].s.Name <> '') then
      begin
        g_ItemArr[I].Dura := NewDura;
        break;
      end;
      Inc(I);
    end;
  end
  else
  begin
    while I <= Length(g_HeroItemArr) - 1 do
    begin
      if (g_HeroItemArr[I].MakeIndex = MakeIndex) and (g_HeroItemArr[I].s.Name <> '') then
      begin
        g_HeroItemArr[I].Dura := NewDura;
        break;
      end;
      Inc(I);
    end;
  end;
end;

procedure TfrmMain.ClientHeroGetDuraChange(uidx, newdura, newduramax: Integer);
begin
  if uidx in [0..U_FASHION] then
  begin
    if g_HeroUseItems[uidx].S.Name <> '' then
    begin
      g_HeroUseItems[uidx].Dura := newdura;
      g_HeroUseItems[uidx].DuraMax := newduramax;
    end;
  end;
end;

procedure TfrmMain.ClientGetMerchantSay(merchant, face: Integer; saying: string);
var
  npcname: string;
begin
  g_nMDlgX := g_MySelf.m_nCurrX;
  g_nMDlgY := g_MySelf.m_nCurrY;
  if g_nCurMerchant <> merchant then
  begin
    g_nCurMerchant := merchant;
    // FrmDlg.ResetMenuDlg;
    FrmDlg.CloseMDlg;
  end;
  saying := GetValidStr3(saying, npcname, ['/']);
  FrmDlg.ShowMDlg(face, npcname, saying);
end;

procedure TfrmMain.ClientGetSendGoodsList(merchant, count, Model: Integer; body: string);
var
  gname, gsub, gprice, gstock, str: string;
  pcg: pTClientGoods;
  gd: TClientGoods;
  I, Len: Integer;
begin
  FrmDlg.ResetMenuDlg;
  g_nCurMerchant := merchant;
  with FrmDlg do
  begin
    body := DecodeString(body);
    I := 1;
    Len := GetCodeMsgSize(Sizeof(TClientGoods) * 4 / 3);
    while I < Length(body) do
    begin
      New(pcg);
      str := Copy(body ,I , Len);
      DeCodeBuf(Integer(str), Len, Integer(@gd));
      pcg^ := gd;
      if model = 1 then
        MerchandiseGood.Add(pcg)
      else
        MenuList.Add(pcg);
      Inc(I, Len);
    end;

    if Model = 1 then
    begin
      m_boMerchandise := True;
      FrmDlg.WinMerchandiseDlg.Visible := True;
      m_nCurrBuyPage := 1;
      FrmDlg.m_nMaxBuyPage := MerchandiseGood.Count div (Frmdlg.MerchandiseBuy.ColCount * Frmdlg.MerchandiseBuy.RowCount);
      if MerchandiseGood.Count mod (Frmdlg.MerchandiseBuy.ColCount * Frmdlg.MerchandiseBuy.RowCount) > 0then Inc(FrmDlg.m_nMaxBuyPage);
      if FrmDlg.m_nMaxBuyPage = 0 then FrmDlg.m_nMaxBuyPage := 1;
      FrmDlg.DItemBag.Visible := True;
    end
    else
      FrmDlg.ShowShopMenuDlg(dmBuy);
    FrmDlg.CurDetailItem := '';
  end;
end;

procedure TfrmMain.ClientGetDelCharList(count: Integer; body: string);
var
  gname, gjob, gsex, glevel: string;
  pcg: pTDelChar;
begin
  FrmDlg.ResetDelCharMenuDlg;
  with FrmDlg do
  begin
    body := DecodeString(body);
    while body <> '' do
    begin
      body := GetValidStr3(body, gname, ['/']);
      body := GetValidStr3(body, gjob, ['/']);
      body := GetValidStr3(body, gsex, ['/']);
      body := GetValidStr3(body, glevel, ['/']);
      body := GetValidStr3(body, gsex, ['/']);
      if (gname <> '') and (glevel <> '') and (gsex <> '') then
      begin
        New(pcg);
        pcg.sCharName := gname;
        pcg.nLevel := Str_ToInt(glevel, 1);
        pcg.btJob := Str_ToInt(gjob, 0);
        pcg.btSex := Str_ToInt(gsex, 0);
        m_DelCharList.Add(pcg);
      end
      else
        Break;
    end;
    FrmDlg.ShowDelCharInfoDlg;
  end;
end;

procedure TfrmMain.ClientGetSendMakeDrugList(merchant: Integer; body: string);
var
  gname, gsub, gprice, gstock: string;
  pcg: PTClientGoods;
begin
  FrmDlg.ResetMenuDlg;

  g_nCurMerchant := merchant;
  with FrmDlg do
  begin
    //clear shop menu list
    //deocde body received from server
    body := DecodeString(body);
    while body <> '' do
    begin
      body := GetValidStr3(body, gname, ['/']);
      body := GetValidStr3(body, gsub, ['/']);
      body := GetValidStr3(body, gprice, ['/']);
      body := GetValidStr3(body, gstock, ['/']);
      if (gname <> '') and (gprice <> '') and (gstock <> '') then
      begin
        New(pcg);
        pcg.Name := gname;
        pcg.SubMenu := Str_ToInt(gsub, 0);
        pcg.price := Str_ToInt(gprice, 0);
        pcg.Stock := Str_ToInt(gstock, 0);
        pcg.Grade := -1;
        MenuList.Add(pcg);
      end
      else
        Break;
    end;
    FrmDlg.ShowShopMenuDlg(dmMakeDrug);
    FrmDlg.CurDetailItem := '';
    FrmDlg.BoMakeDrugMenu := True;
  end;
end;

procedure TfrmMain.ClientGetSendUserSell(merchant: Integer);
begin
  FrmDlg.CloseDSellDlg;
  g_nCurMerchant := merchant;
  FrmDlg.SpotDlgMode := dmSell;
  FrmDlg.ShowShopSellDlg;
end;

procedure TfrmMain.ClientGetSendUserExchgBook(merchant: Integer);
begin
  FrmDlg.CloseDSellDlg;
  g_nCurMerchant := merchant;
  FrmDlg.SpotDlgMode := dmExchangeBook;
  FrmDlg.ShowShopSellDlg;
end;

procedure TfrmMain.ClientGetSendItemDlg(merchant: Integer; Str: string);
begin
  FrmDlg.CloseDSellDlg;
  g_nCurMerchant := merchant;
  FrmDlg.SpotDlgStr := Str;
  FrmDlg.SpotDlgMode := dmItemDlg;
  FrmDlg.ShowShopSellDlg;
end;

procedure TfrmMain.ClientGetSendBindItem(merchant: Integer);
begin
  FrmDlg.CloseDSellDlg;
  g_nCurMerchant := merchant;
  FrmDlg.SpotDlgMode := dmBindItem;
  FrmDlg.ShowShopSellDlg;
end;

procedure TfrmMain.ClientGetSendUnBindItem(merchant: Integer);
begin
  FrmDlg.CloseDSellDlg;
  g_nCurMerchant := merchant;
  FrmDlg.SpotDlgMode := dmUnBindItem;
  FrmDlg.ShowShopSellDlg;
end;

procedure TfrmMain.ClientGetSendUserRepair(merchant: Integer);
begin
  FrmDlg.CloseDSellDlg;
  g_nCurMerchant := merchant;
  FrmDlg.SpotDlgMode := dmRepair;
  FrmDlg.ShowShopSellDlg;
end;

procedure TfrmMain.ClientGetSendUserStorage(merchant: Integer);
begin
  FrmDlg.CloseDSellDlg;
  g_nCurMerchant := merchant;
  FrmDlg.SpotDlgMode := dmStorage;
  FrmDlg.ShowShopSellDlg;
end;

procedure TFrmMain.ClientGetSendUserStorageView(merchant: Integer);
begin
  FrmDlg.CloseDStorageViewDlg;
  g_nCurMerchant := merchant;
  FrmDlg.ShowStorageViewDlg;
end;

procedure TfrmMain.ClientGetSendUserMaketSell(merchant: Integer);
begin
  FrmDlg.CloseDSellDlg;
  g_nCurMerchant := merchant;
  FrmDlg.SpotDlgMode := dmMaketSell;
  FrmDlg.ShowShopSellDlg;
  FrmDlg.DItemMarketCloseClick(nil, 0, 0);
end;
{
procedure TfrmMain.ClientGetRegInfo(msg: pTDefaultMessage; body: string);
begin
  //DecodeBuffer(body, @g_RegInfo, SizeOf(TRegInfo));
end;
}

procedure TfrmMain.ClientGetStorageItemList(merchant: Integer; bodystr: string);
var
  i: Integer;
  data: string;
  pc: PTClientItem;
  pcg: PTClientGoods;
begin
  for i := 0 to g_SaveItemList.count - 1 do
  begin
    Dispose(PTClientItem(g_SaveItemList[i]));
  end;
  g_SaveItemList.Clear;

  while True do
  begin
    if bodystr = '' then
      Break;
    bodystr := GetValidStr3(bodystr, data, ['/']);
    if data <> '' then
    begin
      New(pc);
      DecodeBuffer(data, @(pc^), SizeOf(TClientItem));
      g_SaveItemList.Add(pc);
    end
    else
      Break;
  end;

end;


procedure TfrmMain.ClientGetSaveItemList(merchant: Integer; bodystr: string);
var
  i: Integer;
  data: string;
  pc: PTClientItem;
  pcg: PTClientGoods;
begin
  FrmDlg.ResetMenuDlg;

  for i := 0 to g_SaveItemList.count - 1 do
    Dispose(PTClientItem(g_SaveItemList[i]));
  g_SaveItemList.Clear;

  while True do
  begin
    if bodystr = '' then
      Break;
    bodystr := GetValidStr3(bodystr, data, ['/']);
    if data <> '' then
    begin
      New(pc);
      DecodeBuffer(data, @(pc^), SizeOf(TClientItem));
      g_SaveItemList.Add(pc);
    end
    else
      Break;
  end;

  g_nCurMerchant := merchant;

  with FrmDlg do
  begin
    //deocde body received from server
    for i := 0 to g_SaveItemList.count - 1 do
    begin
      New(pcg);
      pcg.Name := PTClientItem(g_SaveItemList[i]).S.Name;
      pcg.SubMenu := 0;
      pcg.price := PTClientItem(g_SaveItemList[i]).MakeIndex;
      pcg.Stock := Round(PTClientItem(g_SaveItemList[i]).Dura / 1000);
      pcg.Grade := Round(PTClientItem(g_SaveItemList[i]).DuraMax / 1000);
      MenuList.Add(pcg);
    end;
    FrmDlg.ShowShopMenuDlg(dmGetSave);
    FrmDlg.BoStorageMenu := True;
  end;
end;

procedure TfrmMain.ClientGetSendDetailGoodsList(merchant, count, topline: Integer; bodystr: string);
var
  i: Integer;
  data: string;
  pcg: PTClientGoods;
  pc: PTClientItem;
begin
  FrmDlg.ResetMenuDlg();

  g_nCurMerchant := merchant;

  bodystr := DecodeString(bodystr);
  while True do
  begin
    if bodystr = '' then Break;
    bodystr := GetValidStr3(bodystr, data, ['/']);
    if data <> '' then
    begin
      New(pc);
      DecodeBuffer(data, @(pc^), SizeOf(TClientItem));
      if not FrmDlg.m_boMerchandise then
        g_MenuItemList.Add(pc)
      else
        FrmDlg.MerChandiseItem.add(pc);
    end
    else
      Break;
  end;

  if not FrmDlg.m_boMerchandise then
  begin
    with FrmDlg do
    begin
      //clear shop menu list
      for i := 0 to g_MenuItemList.count - 1 do
      begin
        New(pcg);
        pcg.Name := PTClientItem(g_MenuItemList[i]).S.Name;
        pcg.SubMenu := 0;
        pcg.price := PTClientItem(g_MenuItemList[i]).DuraMax;
        pcg.Stock := PTClientItem(g_MenuItemList[i]).MakeIndex;
        pcg.Grade := Round(PTClientItem(g_MenuItemList[i]).Dura / 1000);
        MenuList.Add(pcg);
      end;
      FrmDlg.ShowShopMenuDlg(dmDetailMenu);
      FrmDlg.BoDetailMenu := True;
      FrmDlg.MenuTopLine := topline;
    end;
  end
  else
  begin
    FrmDlg.m_nCurrItemPage := 1;
    FrmDlg.m_nMaxItemPage := FrmDlg.MerChandiseItem.Count div (FrmDlg.DGridItemMerchandiase.ColCount * FrmDlg.DGridItemMerchandiase.RowCount);
    if FrmDlg.MerChandiseItem.Count mod (FrmDlg.DGridItemMerchandiase.ColCount * FrmDlg.DGridItemMerchandiase.RowCount) > 0 then  Inc(FrmDlg.m_nMaxItemPage);
    if FrmDlg.m_nMaxItemPage = 0 then FrmDlg.m_nMaxItemPage := 1;
    FrmDlg.ItemMerchandiseDlg.Visible := True;
  end;
end;

procedure TfrmMain.ClientGetImageFileListCustom(body: string); //处理服务器端传回的自定义文件列表信息
var
  data: string;
  sFileName: String;
  tmpCustomWMImage, NewCustomWMImage: TWMImages;
  i: Integer;
begin
  if g_FileCustomList_Client <> nil then
  begin
    g_FileCustomList_Client.Clear;  //g_FIleCustomList_Client对象是StringList无需释放引用内存，直接CLEAR即可
  end;

  body := DecodeString(body);
  while True do
  begin
    if body = '' then  Break;
    
    body := GetValidStr3(body, data, ['/']);
    sFileName := '';
    if (data <> '') and (data[1] <> ';') then
    begin
      sFileName := ChangeFileExt(data,'.wil');
      sFileName := '.\Data\'+sFileName;
    end;

    NewCustomWMImage := nil;
    for I := 0 to g_LoadImagesList.Count - 1 do
    begin
      tmpCustomWMImage := g_LoadImagesList.Items[I];
      if SameText(UpperCase(tmpCustomWMImage.FileName), UpperCase(sFileName)) then
      begin
        NewCustomWMImage := tmpCustomWMImage;
        Break;
      end;
    end;       

    if NewCustomWMImage = nil then
    begin
      NewCustomWMImage := TWMImages.Create(nil);
      NewCustomWMImage.DXDraw := DXDraw;
      NewCustomWMImage.DDraw := DXDraw.DDraw;
      NewCustomWMImage.FileName := sFileName;
      NewCustomWMImage.LibType := ltUseCache;
      NewCustomWMImage.Initialize;
      g_LoadImagesList.Add(NewCustomWMImage);
    end;
    g_FileCustomList_Client.AddObject(data,NewCustomWMImage);
  end;

end;

procedure TfrmMain.ClientGetSendNotice(body: string);
var
  data, msgstr: string;
begin
  g_boDoFastFadeOut := False;

  if g_boOpenAutoPlay and (g_nAPReLogon = 3) then
  begin
    g_nAPReLogon := 4;
    SendClientMessage(CM_LOGINNOTICEOK, 0, 0, 0, CLIENTTYPE);
    Exit;
  end;

  msgstr := '';
  body := DecodeString(body);
  while True do
  begin
    if body = '' then
      Break;
    body := GetValidStr3(body, data, [#27]);
    msgstr := msgstr + data + '\';
  end;

  FrmDlg.DialogSize := 2;
  if FrmDlg.DMessageDlg(msgstr, [mbOk]) = mrOk then
  begin
    SendClientMessage(CM_LOGINNOTICEOK, 0, 0, 0, CLIENTTYPE);
  end;

end;

procedure TfrmMain.ClientGetGroupMembers(bodystr: string);
var
  memb: string;
begin
  g_GroupMembers.Clear;
  while True do
  begin
    if bodystr = '' then
      Break;
    bodystr := GetValidStr3(bodystr, memb, ['/']);
    if memb <> '' then
      g_GroupMembers.Add(memb)
    else
      Break;
  end;
end;

procedure TfrmMain.ClientGetOpenGuildDlg(bodystr: string);
var
  Str, data, linestr, s1: string;
  pstep: Integer;
begin
  if g_boShowMemoLog then
    g_PlayScene.MemoLog.Lines.Add('ClientGetOpenGuildDlg');

  Str := DecodeString(bodystr);
  Str := GetValidStr3(Str, FrmDlg.Guild, [#13]);
  Str := GetValidStr3(Str, FrmDlg.GuildFlag, [#13]);
  Str := GetValidStr3(Str, data, [#13]);
  if data = '1' then
    FrmDlg.GuildCommanderMode := True
  else
    FrmDlg.GuildCommanderMode := False;

  FrmDlg.GuildStrs.Clear;
  FrmDlg.GuildNotice.Clear;
  pstep := 0;
  while True do
  begin
    if Str = '' then
      Break;
    Str := GetValidStr3(Str, data, [#13]);
    if data = '<Notice>' then
    begin
      FrmDlg.GuildStrs.AddObject(Char(7) + '行会公告', TObject(clWhite));
      FrmDlg.GuildStrs.Add(' ');
      pstep := 1;
      Continue;
    end;
    if data = '<KillGuilds>' then
    begin
      FrmDlg.GuildStrs.Add(' ');
      FrmDlg.GuildStrs.AddObject(Char(7) + '敌对行会', TObject(clWhite));
      FrmDlg.GuildStrs.Add(' ');
      pstep := 2;
      linestr := '';
      Continue;
    end;
    if data = '<AllyGuilds>' then
    begin
      if linestr <> '' then
        FrmDlg.GuildStrs.Add(linestr);
      linestr := '';
      FrmDlg.GuildStrs.Add(' ');
      FrmDlg.GuildStrs.AddObject(Char(7) + '联盟行会', TObject(clWhite));
      FrmDlg.GuildStrs.Add(' ');
      pstep := 3;
      Continue;
    end;

    if pstep = 1 then
      FrmDlg.GuildNotice.Add(data);

    if data <> '' then
    begin
      if data[1] = '<' then
      begin
        ArrestStringEx(data, '<', '>', s1);
        if s1 <> '' then
        begin
          FrmDlg.GuildStrs.Add(' ');
          FrmDlg.GuildStrs.AddObject(Char(7) + s1, TObject(clWhite));
          FrmDlg.GuildStrs.Add(' ');
          Continue;
        end;
      end;
    end;
    if (pstep = 2) or (pstep = 3) then
    begin
      if Length(linestr) > 80 then
      begin
        FrmDlg.GuildStrs.Add(linestr);
        linestr := '';
      end
      else
        linestr := linestr + fmstr(data, 18);
      Continue;
    end;

    FrmDlg.GuildStrs.Add(data);
  end;

  if linestr <> '' then
    FrmDlg.GuildStrs.Add(linestr);

  FrmDlg.ShowGuildDlg;
end;

procedure TfrmMain.ClientGetSendGuildMemberList(body: string);
var
  Str, data, rankname, members: string;
  rank: Integer;
begin
  Str := DecodeString(body);
  FrmDlg.GuildStrs.Clear;
  FrmDlg.GuildMembers.Clear;
  rank := 0;
  while True do
  begin
    if Str = '' then
      Break;
    Str := GetValidStr3(Str, data, ['/']);
    if data <> '' then
    begin
      if data[1] = '#' then
      begin
        rank := Str_ToInt(Copy(data, 2, Length(data) - 1), 0);
        Continue;
      end;
      if data[1] = '*' then
      begin
        if members <> '' then
          FrmDlg.GuildStrs.Add(members);
        rankname := Copy(data, 2, Length(data) - 1);
        members := '';
        FrmDlg.GuildStrs.Add(' ');
        if FrmDlg.GuildCommanderMode then
          FrmDlg.GuildStrs.AddObject(fmstr('(' + IntToStr(rank) + ')', 3) + '<' + rankname + '>', TObject(clWhite))
        else
          FrmDlg.GuildStrs.AddObject('<' + rankname + '>', TObject(clWhite));
        FrmDlg.GuildMembers.Add('#' + IntToStr(rank) + ' <' + rankname + '>');
        Continue;
      end;
      if Length(members) > 80 then
      begin
        FrmDlg.GuildStrs.Add(members);
        members := '';
      end;
      members := members + fmstr(data, 18);
      FrmDlg.GuildMembers.Add(data);
    end;
  end;
  if members <> '' then
    FrmDlg.GuildStrs.Add(members);
end;

procedure TfrmMain.MinTimerTimer(Sender: TObject);
var
  i: Integer;
begin
  if g_PlayScene = nil then

    for i := 0 to g_PlayScene.m_ActorList.count - 1 do
    begin
      if IsGroupMember(TActor(g_PlayScene.m_ActorList[i]).m_sUserName) then
      begin
        TActor(g_PlayScene.m_ActorList[i]).m_boGrouped := True;
      end
      else
        TActor(g_PlayScene.m_ActorList[i]).m_boGrouped := False;
    end;
  for i := g_FreeActorList.count - 1 downto 0 do
  begin
    if GetTickCount - TActor(g_FreeActorList[i]).m_dwDeleteTime > 60 * 1000 then
    begin
      TActor(g_FreeActorList[i]).Free;
      g_FreeActorList.Delete(i);
    end;
  end;
  //RefPageForm();
end;

procedure TfrmMain.CheckHackTimerTimer(Sender: TObject);
const
  busy: Boolean = False;
begin
  //
end;

procedure TfrmMain.ClientGetDealRemoteAddItem(body: string);
var
  ci: TClientItem;
begin
  if body <> '' then
  begin
    DecodeBuffer(body, @ci, SizeOf(TClientItem));
    AddDealRemoteItem(ci);
  end;
end;

procedure TfrmMain.ClientGetDealRemoteDelItem(body: string);
var
  ci: TClientItem;
begin
  if body <> '' then
  begin
    DecodeBuffer(body, @ci, SizeOf(TClientItem));
    DelDealRemoteItem(ci);
  end;
end;

procedure TfrmMain.ClientGetReadMiniMap(mapindex: Integer);
var
  i: Integer;
  szMapTitle: string;
  pMapDescInfo: pTMapDescInfo;
begin
  if g_nApMiniMap then
  begin
    g_nApMiniMap := False;
    if mapindex >= 1 then
    begin
      g_nMiniMapIndex := mapindex - 1;
    end;
  end
  else
  begin
    if mapindex >= 1 then
    begin
      // g_boViewMiniMap := True;      寻路和小地图冲突   2019-12-23
      g_nMiniMapIndex := mapindex - 1;
    end;
  end;
  //123456
  g_xCurMapDescList.Clear;
  for i := 0 to g_xMapDescList.count - 1 do
  begin
    szMapTitle := g_xMapDescList[i];
    pMapDescInfo := pTMapDescInfo(g_xMapDescList.Objects[i]);
    if (CompareText(g_xMapDescList[i], g_sMapTitle) = 0) and
      (((pMapDescInfo.nFullMap = g_nViewMinMapLv) and (pMapDescInfo.nFullMap = 1)) or
      ((g_nViewMinMapLv <> 1) and (pMapDescInfo.nFullMap = 0))) then
    begin
      g_xCurMapDescList.AddObject(g_xMapDescList[i], TObject(pMapDescInfo));
    end;
  end;
end;

procedure TfrmMain.ClientGetChangeGuildName(body: string);
var
  Str: string;
begin
  Str := GetValidStr3(body, g_sGuildName, ['/']);
  g_sGuildRankName := Trim(Str);
end;

procedure TfrmMain.ClientGetSendUserState(body: string);
var
  UserState: TUserStateInfo;
  i, ii: Integer;
  Titles:THumTitles;
begin
  FillChar(UserState, SizeOf(TUserStateInfo), #0);
  DecodeBuffer(body, @UserState, SizeOf(TUserStateInfo));
  UserState.NameColor := GetRGB(UserState.NameColor);
  if not g_boUI0508 then
  begin
    ii := 0;
    FillChar(Titles, SizeOf(Titles), 0);
    for i := Low(Titles) to High(Titles) do
    begin
      if UserState.Titles[i].Index > 0 then
      begin
        Titles[ii] := UserState.Titles[i];
        Inc(ii);
      end;
    end;
    if ii > 0 then UserState.Titles := Titles;
  end;

  FrmDlg.OpenUserState(UserState);
end;

procedure TfrmMain.DrawEffectHum(nType, nX, nY: Integer);
var
  Effect: TMagicEff;
  boFly: Boolean;
begin
  Effect := nil;
  case nType of
    0: ;
    1: Effect := TNormalDrawEffect.Create(nX, nY, g_WMon14Img, 410, 6, 120, True);
    2: Effect := TNormalDrawEffect.Create(nX, nY, g_WMagic2Images, 670, 10, 150, True);
    3:
      begin
        Effect := TNormalDrawEffect.Create(nX, nY, g_WMagic2Images, 690, 10, 150, True);
        g_SndMgr.PlaySound(48, nX, nY);
      end;

    4:
      begin
        g_PlayScene.NewMagic(nil, 70, 70, nX, nY, nX, nY, 0, mtRedGroundThunder, False, 60, boFly);
        g_SndMgr.PlaySound(8301, nX, nY);
      end;
    5:
      begin
        g_PlayScene.NewMagic(nil, 71, 71, nX, nY, nX, nY, 0, mtRedThunder, False, 60, boFly);
        g_SndMgr.PlaySound(8206, nX, nY);
      end;
    6:
      begin
        g_PlayScene.NewMagic(nil, 72, 72, nX, nY, nX, nY, 0, mtLava, False, 60, boFly);
        g_SndMgr.PlaySound(8302, nX, nY);
      end;
    7:
      begin
        g_PlayScene.NewMagic(nil, 73, 73, nX, nY, nX, nY, 0, mtSpurt, False, 60, boFly);
        g_SndMgr.PlaySound(8208, nX, nY);
      end;
    8:
      begin
        //Effect := THeroCharEffect.Create(g_Wui, 1210, 12, 120, Actor);
        Effect := TNormalDrawEffect.Create(nX, nY, g_Wui, 1210, 12, 120, True);
        g_SndMgr.PlaySound('Wav\dare-death.wav');
      end;
    41..43:
      begin
        Effect := TNormalDrawEffect.Create(nX, nY, g_Wui, 1170 + 10 * (nType - 41), 6, 220, True);
        g_SndMgr.PlaySound('Wav\Flashbox.wav');
      end;
    75..83:
      begin
        Effect := TNormalDrawEffect.Create(nX, nY, g_WMagic3Images, (nType - 75) * 20, 20, 150, True);
        if nType >= 78 then
          g_SndMgr.PlaySound('Wav\newysound-mix.wav', nX, nY);
      end;
    84:
      begin
        Effect := TNormalDrawEffect.Create(nX, nY, g_WEffectImg, 800, 10, 100, True);
        g_SndMgr.PlaySound('Wav\HeroLogin.wav', nX, nY);
      end;
    85:
      begin
        Effect := TNormalDrawEffect.Create(nX, nY, g_WEffectImg, 810, 10, 100, True);
        g_SndMgr.PlaySound('Wav\HeroLogout.wav', nX, nY);
      end;
  end;
  if Effect <> nil then
  begin
    Effect.MagOwner := g_MySelf;
    g_PlayScene.m_EffectList.Add(Effect);
  end;
end;

procedure TfrmMain.DrawEffectHumEx(nID, nType, tag: Integer);
var
  Effect: TMagicEff;
  Actor: TActor;
begin
  Actor := g_PlayScene.FindActor(nID);
  if Actor = nil then
    Exit;
  Effect := nil;
  case nType of
    //0: ;
    1: Effect := THeroCharEffect.Create(g_WMagic4Images, 170, 5, 120, Actor);
    2: Effect := THeroCharEffect.Create(g_WMagic4Images, 520, 16, 120, Actor);
    3: Effect := THeroCharEffect.Create(g_WMagic4Images, 820, 10, 120, Actor);
    4: Effect := THeroCharEffect.Create(g_WMagic4Images, 600, 6, 120, Actor);
    5: Effect := THeroCharEffect.Create(g_WMagic4Images, 260, 8, 120, Actor);
    6: Effect := THeroCharEffect.Create(g_WMagic4Images, 420, 16, 120, Actor);
    7: Effect := THeroCharEffect.Create(g_WMagic4Images, 180, 6, 120, Actor);
    8: Effect := THeroCharEffect.Create(g_WMagic4Images, 180, 6, 120, Actor);
    9:
      begin
        Effect := THeroCharEffect.Create(g_WMain2Images, 00, 25, 120, Actor);
        g_SndMgr.PlaySound('Wav\dare-death.wav');
      end;
    10:
      begin
        Effect := THeroCharEffect.Create(g_WMain2Images, 30, 25, 120, Actor);
        g_SndMgr.PlaySound('Wav\dare-win.wav');
      end;
    11:
      begin
        Effect := THeroCharEffect.Create(g_WMagic5Images, 790, 10, 60, Actor);
        g_SndMgr.PlaySound('Wav\hero-shield.wav');
      end;
    13:
      begin
        Effect := THeroCharEffect.Create(g_WMagic6Images, 470, 5, 120, Actor);
        g_SndMgr.PlaySound('Wav\UnionHitShield.wav');
      end;
    14:
      begin
        Effect := THeroCharEffect.Create(g_WMain2Images, 110, 15, 80, Actor);
        g_SndMgr.PlaySound('Wav\powerup.wav');
      end;
    15:
      begin
        Effect := THeroCharEffect.Create(g_WMagic6Images, 480, 6, 120, Actor);
        g_SndMgr.PlaySound('Wav\hero-shield.wav');
      end;
    16:
      begin
        Effect := THeroCharEffect.Create(g_WMagic6Images, 490, 8, 120, Actor);
        g_SndMgr.PlaySound('Wav\hero-shield.wav');
      end;
    17: Effect := THeroCharEffect.Create(g_WMon24Img, 3740, 10, 500, Actor);

    18:
      begin
        Effect := THeroCharEffect.Create(g_cboEffect, 4060, 37, 50, Actor);
        g_SndMgr.PlaySound('Wav\warpower-up.wav');
      end;
    19:
      begin
        Effect := THeroCharEffect.Create(g_cboEffect, 4100, 33, 55, Actor);
        g_SndMgr.PlaySound('Wav\warpower-up.wav');
      end;
    20:
      begin
        Effect := THeroCharEffect.Create(g_cboEffect, 4140, 30, 60, Actor);
        g_SndMgr.PlaySound('Wav\warpower-up.wav');
      end;
    21: Effect := THeroCharEffect.Create(g_cboEffect, 4180, 06, 120, Actor);
    22: Effect := THeroCharEffect.Create(g_cboEffect, 4190, 04, 120, Actor);

    23: Effect := THeroCharEffect.Create(g_WMain2Images, 640, 10, 120, Actor);
    24: Effect := THeroCharEffect.Create(g_WMain2Images, 650, 15, 095, Actor);
    25: Effect := THeroCharEffect.Create(g_WMain2Images, 670, 18, 090, Actor);
    26: Effect := THeroCharEffect.Create(g_WMain2Images, 690, 17, 090, Actor);
    27: Effect := THeroCharEffect.Create(g_WMain2Images, 710, 19, 088, Actor);
    28: Effect := THeroCharEffect.Create(g_WMain2Images, 630, 06, 120, Actor);

    29: Actor.StruckShowDamage(IntToStr(tag));

    30: Effect := THeroCharEffect.Create(g_WMagic8Images2, 2460, 06, 100, Actor);
    31:
      begin
        Effect := THeroCharEffect.Create(g_Wui, 1210, 12, 120, Actor);
        //Effect := TNormalDrawEffect.Create(nX, nY, g_WMon14Img, 410, 6, 120, True);
        g_SndMgr.PlaySound('Wav\dare-death.wav');
      end;
    32:
      begin
        Effect := THeroCharEffect.Create(g_Wui, 1222, 12, 120, Actor);
        g_SndMgr.PlaySound('Wav\dare-win.wav');
      end;
    33..40:
      begin
        Effect := THeroCharEffect.Create(g_Wui, 1080 + 10 * (nType - 33), 6, 220, Actor);
        g_SndMgr.PlaySound('Wav\SelectBoxFlash.wav');
      end;
    41..43:
      begin
        Effect := THeroCharEffect.Create(g_Wui, 1170 + 10 * (nType - 41), 6, 220, Actor);
        g_SndMgr.PlaySound('Wav\Flashbox.wav');
      end;
  end;
  if Effect <> nil then
  begin
    //Effect.MagOwner := g_MySelf;
    g_PlayScene.m_EffectList.Add(Effect);
  end;
end;

procedure TfrmMain.SelectChr(sChrName: string);
begin
  //PlayScene.EdChrNamet.Text := sChrName;
end;

function TfrmMain.GetNpcImg(wAppr: Word; var WMImage: TWMImages): Boolean;
var
  i: Integer;
  FileName, FileName2, FileName3: string;
begin
  for i := 0 to NpcImageList.count - 1 do
  begin
    WMImage := TWMImages(NpcImageList.Items[i]);
    if WMImage.Appr = wAppr then
    begin
      Result := True;
      Exit;
    end;
  end;
  FileName := NpcImageDir + IntToStr(wAppr) + '.wil';
  FileName2 := NpcImageDir + IntToStr(wAppr) + '.wis';
  FileName3 := NpcImageDir + IntToStr(wAppr) + '.wzl';
  //if FileExists(FileName) or FileExists(FileName2) or FileExists(FileName3) then begin
  WMImage := TWMImages.Create(nil);
  WMImage.FileName := FileName;
  WMImage.LibType := ltUseCache;
  WMImage.DDraw := DXDraw.DDraw;
  WMImage.Appr := wAppr;
  WMImage.Initialize;
  NpcImageList.Add(WMImage);
  Result := True;
  //end;
end;

function TfrmMain.GetWDnItemImg(idx: Integer): TDirectDrawSurface;
begin
  Result := nil;
  if idx < 10000 then
  begin
    Result := g_WDnItemImages.Images[idx];
    Exit;
  end;
  if idx < 20000 then
  begin
    Result := g_WDnItemImages2.Images[idx - 10000];
    Exit;
  end;
end;

function TfrmMain.GetWBagItemImg(idx: Integer): TDirectDrawSurface;
begin
  Result := nil;
  if idx < 10000 then
  begin
    Result := g_WBagItemImages.Images[idx];
    Exit;
  end;
  if idx < 20000 then
  begin
    //DScreen.AddChatBoardString(format('%d', [idx]), clWhite, clRed);
    Result := g_WBagItemImages2.Images[idx - 10000];
    Exit;
  end;
end;

function TfrmMain.GetWBagItemImg(idx: Integer; var ax, ay: Integer): TDirectDrawSurface;
begin
  Result := nil;
  if idx < 10000 then
  begin
    Result := g_WBagItemImages.GetCachedImage(idx, ax, ay);
    Exit;
  end;
  if idx < 20000 then
  begin
    Result := g_WBagItemImages2.GetCachedImage(idx - 10000, ax, ay);
    Exit;
  end;
end;

function TfrmMain.GetWStateImg(idx: Integer; var ax, ay: Integer): TDirectDrawSurface;
var
  i: Integer;
  FileName, FileName2, FileName3: string;
  FileIdx: Integer;
  WMImage: TWMImages;
begin
  if idx < 10000 then
  begin
    Result := g_WStateItemImages.GetCachedImage(idx, ax, ay);
    Exit;
  end;
  if idx < 20000 then
  begin
    Result := g_WStateItemImages2.GetCachedImage(idx - 10000, ax, ay);
    Exit;
  end;

  FileIdx := idx div 10000;
  for i := 0 to ItemImageList.count - 1 do
  begin
    WMImage := TWMImages(ItemImageList.Items[i]);
    if WMImage.Appr = FileIdx then
    begin
      Result := WMImage.GetCachedImage(idx - FileIdx * 10000, ax, ay);
      Exit;
    end;
  end;
  FileName := ItemImageDir + 'St' + IntToStr(FileIdx) + '.wil';
  FileName2 := ItemImageDir + 'St' + IntToStr(FileIdx) + '.wis';
  FileName3 := ItemImageDir + 'St' + IntToStr(FileIdx) + '.wzl';
  //if FileExists(FileName) or FileExists(FileName2) or FileExists(FileName3) then begin
  WMImage := TWMImages.Create(nil);
  WMImage.FileName := FileName;
  WMImage.LibType := ltUseCache;
  WMImage.DDraw := DXDraw.DDraw;
  WMImage.Appr := FileIdx;
  WMImage.Initialize;
  ItemImageList.Add(WMImage);
  Result := WMImage.GetCachedImage(idx - FileIdx * 10000, ax, ay);
  //end;
end;

function TfrmMain.GetWStateImg(idx: Integer): TDirectDrawSurface;
var
  i: Integer;
  FileName, FileName2, FileName3: string;
  FileIdx: Integer;
  WMImage: TWMImages;
begin
  if idx < 10000 then
  begin
    Result := g_WStateItemImages.Images[idx];
    Exit;
  end;
  if idx < 20000 then
  begin
    Result := g_WStateItemImages2.Images[idx - 10000];
    Exit;
  end;
  FileIdx := idx div 10000;
  for i := 0 to ItemImageList.count - 1 do
  begin
    WMImage := TWMImages(ItemImageList.Items[i]);
    if WMImage.Appr = FileIdx then
    begin
      Result := WMImage.Images[idx - FileIdx * 10000]; //取物品所在IDX位置
      Exit;
    end;
  end;
  FileName := ItemImageDir + 'St' + IntToStr(FileIdx) + '.wil';
  FileName2 := ItemImageDir + 'St' + IntToStr(FileIdx) + '.wis';
  FileName3 := ItemImageDir + 'St' + IntToStr(FileIdx) + '.wzl';
  //if FileExists(FileName) or FileExists(FileName2) or FileExists(FileName3) then begin
  WMImage := TWMImages.Create(nil);
  WMImage.FileName := FileName;
  WMImage.LibType := ltUseCache;
  WMImage.DDraw := DXDraw.DDraw;
  WMImage.Appr := FileIdx;
  WMImage.Initialize;
  ItemImageList.Add(WMImage);
  Result := WMImage.Images[idx - FileIdx * 10000]; //取物品所在IDX位置
  //end;
end;

function TfrmMain.GetWWeaponEffectImg(Actor: THumActor; Weapon, wShape, m_btSex, nFrame: Integer; var ax, ay: Integer; boUseCboLib: Boolean): TDirectDrawSurface;
var
  frame, ndir, MaxIdx: Integer;
begin
  Result := nil;
  if Weapon <= 0 then
    Exit;
  if boUseCboLib then
  begin
    with Actor do
    begin
      case m_nCurrentAction of
        SM_RUSHEX:
          begin
            frame := 8;
            ndir := 10;
            MaxIdx := 80;
          end;
        SM_SMITEHIT:
          begin
            frame := 15;
            ndir := 20;
            MaxIdx := 160;
          end;
        SM_SMITELONGHIT: if m_boSmiteLongHit = 2 then
          begin
            frame := 6;
            ndir := 10;
            MaxIdx := 320;
          end;
        SM_SMITELONGHIT3:
          begin
            frame := 6;
            ndir := 10;
            MaxIdx := 160;
          end;
        SM_SMITELONGHIT2, SM_SMITEWIDEHIT2:
          begin
            frame := 12;
            ndir := 20;
            MaxIdx := 400;
          end;
        SM_SMITEWIDEHIT:
          begin
            frame := 10;
            ndir := 10;
            MaxIdx := 560;
          end;
        SM_SPELL:
          begin
            case m_CurMagic.EffectNumber of
              104:
                begin
                  frame := 6;
                  ndir := 10;
                  MaxIdx := 640;
                end;
              112:
                begin
                  frame := 6;
                  ndir := 10;
                  MaxIdx := 720;
                end;
              106:
                begin
                  frame := 8;
                  ndir := 10;
                  MaxIdx := 800;
                end;
              107:
                begin
                  frame := 13;
                  ndir := 10;
                  MaxIdx := 1040;
                end;
              108:
                begin
                  frame := 6;
                  ndir := 10;
                  MaxIdx := 1200;
                end;
              109:
                begin
                  frame := 12;
                  ndir := 20;
                  MaxIdx := 1440;
                end;
              110:
                begin
                  frame := 12;
                  ndir := 20;
                  MaxIdx := 1600;
                end;
              111:
                begin
                  frame := 14;
                  ndir := 20;
                  MaxIdx := 1760;
                end;
              105 {112}:
                begin
                  frame := 10;
                  ndir := 10;
                  MaxIdx := 880;
                end;
            end;
          end;
      end;
      if m_nCurrentFrame < MaxIdx then
      begin
        if (GetTickCount - m_dwFrameTick) > HUMWINEFFECTTICK {200} then
        begin //Blue
          if m_nFrame < (frame - 1) then
            Inc(m_nFrame)
          else
            m_nFrame := 0;
          m_dwFrameTick := GetTickCount();
        end;
        case Weapon of
          1, 2: Result := g_cboHumEffect.GetCachedImage((40000 + 2000 * ((Weapon - 1) * 2 + m_btSex)) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
          3: Result := g_cboHumEffect2.GetCachedImage((4000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
          4:
            begin
              case wShape of
                160, 161: Result := g_cboHumEffect2.GetCachedImage((12000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
                162, 163: Result := g_cboHumEffect2.GetCachedImage((16000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
                164, 165: Result := g_cboHumEffect2.GetCachedImage((20000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
              end;
            end;
          7: Result := g_cboHumEffect3.GetCachedImage((20000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
          8: Result := g_cboHumEffect3.GetCachedImage((12000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
          9: Result := g_cboHumEffect3.GetCachedImage((16000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);

          10: Result := g_cboHumEffect3.GetCachedImage((32000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
          11: Result := g_cboHumEffect3.GetCachedImage((28000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
          12: Result := g_cboHumEffect3.GetCachedImage((36000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
          13: Result := g_cboHumEffect3.GetCachedImage((48000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
          14: Result := g_cboHumEffect3.GetCachedImage((52000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
          15: Result := g_cboHumEffect3.GetCachedImage((56000 + 2000 * m_btSex) + (m_btDir * ndir) + m_nFrame, m_nWpeX, m_nWpeY);
        end;
      end
      else
      begin
        case Weapon of
          1: Result := g_cboHumEffect.GetCachedImage((40000 + 2000 * ((Weapon - 1) * 2 + m_btSex)) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          2: Result := g_cboHumEffect.GetCachedImage((40000 + 2000 * ((Weapon - 1) * 2 + m_btSex)) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          3: Result := g_cboHumEffect2.GetCachedImage((4000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          4: Result := g_cboHumEffect2.GetCachedImage((12000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          5: Result := g_cboHumEffect2.GetCachedImage((16000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          6: Result := g_cboHumEffect2.GetCachedImage((20000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);

          7: Result := g_cboHumEffect3.GetCachedImage((20000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          8: Result := g_cboHumEffect3.GetCachedImage((12000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          9: Result := g_cboHumEffect3.GetCachedImage((16000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);

          10: Result := g_cboHumEffect3.GetCachedImage((32000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          11: Result := g_cboHumEffect3.GetCachedImage((28000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          12: Result := g_cboHumEffect3.GetCachedImage((36000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          13: Result := g_cboHumEffect3.GetCachedImage((48000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          14: Result := g_cboHumEffect3.GetCachedImage((52000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
          15: Result := g_cboHumEffect3.GetCachedImage((56000 + 2000 * m_btSex) + m_nCurrentFrame, m_nWpeX, m_nWpeY);
        end;
      end;
    end;
    Exit;
  end;

  case Weapon of
    1: Result := g_WHumEffect2.GetCachedImage(HUMANFRAME * ((Weapon - 1) * 2 + m_btSex) + nFrame, ax, ay);
    2: Result := g_WHumEffect2.GetCachedImage(HUMANFRAME * ((Weapon - 1) * 2 + m_btSex) + nFrame, ax, ay);
    3: Result := g_WHumEffect2.GetCachedImage(6000 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);
    4: Result := g_WHumEffect2.GetCachedImage(8400 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);
    5: Result := g_WHumEffect2.GetCachedImage(9600 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);
    6: Result := g_WHumEffect2.GetCachedImage(10800 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);

    7: Result := g_WHumEffect3.GetCachedImage(6000 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);
    8: Result := g_WHumEffect3.GetCachedImage(3600 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);
    9: Result := g_WHumEffect3.GetCachedImage(4800 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);

    10: Result := g_WHumEffect3.GetCachedImage(9600 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);
    11: Result := g_WHumEffect3.GetCachedImage(8400 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);
    12: Result := g_WHumEffect3.GetCachedImage(10800 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);
    13: Result := g_WHumEffect3.GetCachedImage(14400 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);
    14: Result := g_WHumEffect3.GetCachedImage(15600 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);
    15: Result := g_WHumEffect3.GetCachedImage(16800 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);

    16: Result := g_WHumEffect2.GetCachedImage(13200 + HUMANFRAME * (m_btSex) + nFrame, ax, ay);
  end;
end;

function TfrmMain.GetWWeaponImg(Weapon, m_btSex, nFrame: Integer; var ax, ay: Integer; boUseCboLib: Boolean): TDirectDrawSurface;
var
  i: Integer;
  FileName, FileName2, FileName3: string;
  FileIdx: Integer;
  WMImage: TWMImages;
begin
  Result := nil;
  FileIdx := (Weapon - m_btSex) div 2;

  if boUseCboLib then
  begin
    if (FileIdx < 100) then
    begin
      if (FileIdx >= 50) and (FileIdx < 75) then
      begin
        Weapon := Weapon - 24; //(50 * 2 + Sex) - 24 = 76
        Result := g_cboweapon.GetCachedImage(2000 * Weapon + nFrame, ax, ay);
      end
      else if FileIdx >= 75 then
      begin
        Result := g_cboweapon3.GetCachedImage(2000 * (Weapon - 150) + nFrame, ax, ay);
      end
      else
        Result := g_cboweapon.GetCachedImage(2000 * Weapon + nFrame, ax, ay);
    end;
    Exit;
  end;

  if (FileIdx < 100) then
  begin
    if (FileIdx >= 50) and (FileIdx < 75) then
    begin
      if g_WWeapon2Images <> nil then
        Result := g_WWeapon2Images.GetCachedImage(HUMANFRAME * (Weapon - 100) + nFrame, ax, ay);
    end
    else if FileIdx >= 75 then
    begin
      if g_WWeapon3Images <> nil then
        Result := g_WWeapon3Images.GetCachedImage(HUMANFRAME * (Weapon - 150) + nFrame, ax, ay);
    end
    else
      Result := g_WWeaponImages.GetCachedImage(HUMANFRAME * Weapon + nFrame, ax, ay);
    Exit;
  end;

  for i := 0 to WeaponImageList.count - 1 do
  begin
    WMImage := TWMImages(WeaponImageList.Items[i]);
    if WMImage.Appr = FileIdx then
    begin
      Result := WMImage.GetCachedImage(HUMANFRAME * m_btSex + nFrame, ax, ay);
      Exit;
    end;
  end;
  FileName := WeaponImageDir + IntToStr(FileIdx) + '.wil';
  FileName2 := WeaponImageDir + IntToStr(FileIdx) + '.wis';
  FileName3 := WeaponImageDir + IntToStr(FileIdx) + '.wzl';
  //if FileExists(FileName) or FileExists(FileName2) or FileExists(FileName3) then begin
  WMImage := TWMImages.Create(nil);
  WMImage.FileName := FileName;
  WMImage.LibType := ltUseCache;
  WMImage.DDraw := DXDraw.DDraw;
  WMImage.Appr := FileIdx;
  WMImage.Initialize;
  WeaponImageList.Add(WMImage);
  Result := WMImage.GetCachedImage(HUMANFRAME * m_btSex + nFrame, ax, ay);
  //end;
end;

function TfrmMain.GetWHumImg(Dress, m_btSex, nFrame: Integer; var ax, ay: Integer; boUseCboLib: Boolean): TDirectDrawSurface;
var
  i: Integer;
  FileName, FileName2, FileName3: string;
  FileIdx: Integer;
  WMImage: TWMImages;
begin
  Result := nil;
  FileIdx := (Dress - m_btSex) shr 1;

  if boUseCboLib then
  begin
    //dscreen.AddSysMsg(inttostr(FileIdx) + ' ' + inttostr(Dress));

    if (FileIdx < 75) then
    begin
      if (FileIdx >= 25) and (FileIdx < 50) then
      begin
        Dress := Dress - 26; //(25 * 2 + Sex) - 26 = 24
        Result := g_cbohum.GetCachedImage(2000 * Dress + nFrame, ax, ay);
      end
      else if FileIdx >= 50 then
      begin
        Dress := Dress - 100;
        //dscreen.AddSysMsg(inttostr(Dress));
        Result := g_cbohum3.GetCachedImage(2000 * Dress + nFrame, ax, ay);
      end
      else
        Result := g_cbohum.GetCachedImage(2000 * Dress + nFrame, ax, ay);
      Exit;
    end;
  end;

  if (FileIdx < 75) then
  begin
    if (FileIdx >= 25) and (FileIdx < 50) then
    begin
      if g_WHum2ImgImages <> nil then
        Result := g_WHum2ImgImages.GetCachedImage(HUMANFRAME * (Dress - 50) + nFrame, ax, ay);
    end
    else if FileIdx >= 50 then
    begin
      if g_WHum3ImgImages <> nil then
        Result := g_WHum3ImgImages.GetCachedImage(HUMANFRAME * (Dress - 100) + nFrame, ax, ay);
    end
    else
      Result := g_WHumImgImages.GetCachedImage(HUMANFRAME * Dress + nFrame, ax, ay);
    Exit;
  end;

  for i := 0 to HumImageList.count - 1 do
  begin
    WMImage := TWMImages(HumImageList.Items[i]);
    if WMImage.Appr = FileIdx then
    begin
      Result := WMImage.GetCachedImage(HUMANFRAME * m_btSex + nFrame, ax, ay);
      Exit;
    end;
  end;
  FileName := HumImageDir + IntToStr(FileIdx) + '.wil';
  FileName2 := HumImageDir + IntToStr(FileIdx) + '.wis';
  FileName3 := HumImageDir + IntToStr(FileIdx) + '.wzl';
  //if FileExists(FileName) or FileExists(FileName2) or FileExists(FileName3) then begin
  WMImage := TWMImages.Create(nil);
  WMImage.FileName := FileName;
  WMImage.LibType := ltUseCache;
  WMImage.DDraw := DXDraw.DDraw;
  WMImage.Appr := FileIdx;
  WMImage.Initialize;
  HumImageList.Add(WMImage);
  Result := WMImage.GetCachedImage(HUMANFRAME * m_btSex + nFrame, ax, ay);
  //end;
end;

procedure TfrmMain.ClientGetPasswordStatus(msg: pTDefaultMessage; body: string);
begin

end;

procedure TfrmMain.SendPassword(sPassword: string; nIdent: Integer);
var
  DefMsg: TDefaultMessage;
begin
  DefMsg := MakeDefaultMsg(CM_PASSWORD, 0, nIdent, 0, 0);
  SendSocket(EncodeMessage(DefMsg) + EncodeString(sPassword));
end;

procedure TfrmMain.SendRefineItems(cr: TClientRefineItems);
var
  DefMsg: TDefaultMessage;
begin
  DefMsg := MakeDefaultMsg(CM_REFINEITEM, 0, 0, 0, 0);
  SendSocket(EncodeMessage(DefMsg) + EncodeBuffer(@cr, SizeOf(TClientRefineItems)));
end;

procedure TfrmMain.SendStallInfo(cr: TClientStallItems; cnt: Integer);
var
  DefMsg: TDefaultMessage;
begin
  DefMsg := MakeDefaultMsg(CM_OPENSTALL, g_MySelf.m_nRecogId, 0, 0, cnt);
  SendSocket(EncodeMessage(DefMsg) + EncodeBuffer(@cr, SizeOf(TClientStallItems)));
end;

procedure TfrmMain.SendGateTick;
begin

end;

procedure TfrmMain.SendGetbackDelCharName(sName: string);
var
  DefMsg: TDefaultMessage;
begin
  DefMsg := MakeDefaultMsg(CM_GETBACKDELCHR, 0, 0, 0, 0);
  SendSocket(EncodeMessage(DefMsg) + EncodeString(sName));
end;

procedure TfrmMain.SendHeroItemToMasterBag(nMakeIdx: Integer; sItemName: string);
var
  DefMsg: TDefaultMessage;
begin
  DefMsg := MakeDefaultMsg(CM_HEROADDITEMTOPLAYER, nMakeIdx, 0, 0, 0);
  SendSocket(EncodeMessage(DefMsg) + EncodeString(sItemName));
end;

procedure TfrmMain.SendMasterItemToHeroBag(nMakeIdx: Integer; sItemName: string);
var
  DefMsg: TDefaultMessage;
begin
  DefMsg := MakeDefaultMsg(CM_PLAYERADDITEMTOHERO, nMakeIdx, 0, 0, 0);
  SendSocket(EncodeMessage(DefMsg) + EncodeString(sItemName));
end;

procedure TfrmMain.SetInputStatus;
begin
  if m_boPasswordIntputStatus then
  begin
    m_boPasswordIntputStatus := False;
    FrmDlg.DEdChat.PasswordChar := #0;
    FrmDlg.DEdChat.Visible := False;
    if not g_ChatStatusLarge then
      FrmDlg.DBChat.Visible := False;
  end
  else
  begin
    m_boPasswordIntputStatus := True;
    FrmDlg.DEdChat.PasswordChar := '*';
    FrmDlg.DEdChat.Visible := True;
    FrmDlg.DEdChat.SetFocus;
  end;
end;

procedure TfrmMain.ClientGetServerConfig(msg: TDefaultMessage; sBody: string);
var
  ClientConf: TClientConf;
begin
{$I '..\Common\Macros\VMPBM.inc'}
{$IF CONFIGTEST}
  g_boOpenAutoPlay := True;
  g_boSpeedRate := True;
  g_boSpeedRateShow := g_boSpeedRate;
{$ELSE}
  g_boOpenAutoPlay := LoByte(LoWord(msg.Recog)) = 1;
  g_boSpeedRate := msg.series <> 0;
  g_boSpeedRateShow := g_boSpeedRate;
{$IFEND CONFIGTEST}

  g_boCanRunMon := HiByte(LoWord(msg.Recog)) = 1;
  g_boCanRunNpc := LoByte(HiWord(msg.Recog)) = 1;
  g_boCanRunAllInWarZone := HiByte(HiWord(msg.Recog)) = 1;

  sBody := DecodeString(sBody);
  DecodeBuffer(sBody, @ClientConf, SizeOf(ClientConf));

  g_boCanRunHuman := ClientConf.boRunHuman;
  g_boCanRunMon := ClientConf.boRunMon;
  g_boCanRunNpc := ClientConf.boRunNpc;
  g_boCanRunAllInWarZone := ClientConf.boWarRunAll;
  // g_DeathColorEffect := TColorEffect(_MIN(8, ClientConf.btDieColor));

  //g_nHitTime := ClientConf.wHitIime;
  //g_dwSpellTime := ClientConf.wSpellTime;
  //g_nItemSpeed := ClientConf.btItemSpeed;

  g_boCanStartRun := ClientConf.boCanStartRun;
  g_boParalyCanRun := ClientConf.boParalyCanRun;
  g_boParalyCanWalk := ClientConf.boParalyCanWalk;
  g_boParalyCanHit := ClientConf.boParalyCanHit;
  g_boParalyCanSpell := ClientConf.boParalyCanSpell;
  g_boShowRedHPLable := ClientConf.boShowRedHPLable;
  g_boShowHPNumber := ClientConf.boShowHPNumber;
  g_boShowJobLevel := ClientConf.boShowJobLevel;
  g_boDuraAlert := ClientConf.boDuraAlert;
  g_boMagicLock := ClientConf.boMagicLock;

  //g_boAutoPuckUpItem := ClientConf.boAutoPuckUpItem;
{$I '..\Common\Macros\VMPE.inc'}
end;

procedure TfrmMain.OpenConfigDlg(boStatus: Boolean);
begin
  //Form2.ParentWindow := frmMain.Handle;
  //Form2.show;
end;

procedure TfrmMain.ProcessCommand(sData: string);
var
  sCmd, sParam1, sParam2, sParam3, sParam4, sParam5: string;
begin
  sData := GetValidStr3(sData, sCmd, [' ', ':', #9]);
  sData := GetValidStr3(sData, sCmd, [' ', ':', #9]);
  sData := GetValidStr3(sData, sParam1, [' ', ':', #9]);
  sData := GetValidStr3(sData, sParam2, [' ', ':', #9]);
  sData := GetValidStr3(sData, sParam3, [' ', ':', #9]);
  sData := GetValidStr3(sData, sParam4, [' ', ':', #9]);
  sData := GetValidStr3(sData, sParam5, [' ', ':', #9]);
  if CompareText(sCmd, 'ShowHumanMsg') = 0 then
    CmdShowHumanMsg(sParam1, sParam2, sParam3, sParam4, sParam5);
end;

procedure TfrmMain.CmdShowHumanMsg(sParam1, sParam2, sParam3, sParam4, sParam5: string);
var
  sHumanName: string;
begin
  sHumanName := sParam1;
  if (sHumanName <> '') and (sHumanName[1] = 'C') then
  begin
    g_PlayScene.MemoLog.Clear;
    Exit;
  end;
  if sHumanName <> '' then
  begin
    ShowMsgActor := g_PlayScene.FindActor(sHumanName);
    if ShowMsgActor = nil then
    begin
      DScreen.AddChatBoardString(Format('%s没找到', [sHumanName]), clWhite, clRed);
      Exit;
    end;
  end;
  g_boShowMemoLog := not g_boShowMemoLog;
  g_PlayScene.MemoLog.Clear;
  g_PlayScene.MemoLog.Visible := g_boShowMemoLog;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;

  if {not frmWebBrowser.Showing and} not g_DlgInitialize and ((g_MySelf = nil) or (mrOk = FrmDlg.DMessageDlg('确认退出游戏吗？', [mbOk, mbCancel]))) then
  begin
    if g_MySelf <> nil then
    begin
      SaveBagsData();
      SaveItemFilter();
    end;
    CanClose := True;
  end;
end;

function TfrmMain.GetMagicByID(magid: Integer): PTClientMagic;
begin
  Result := nil;
  if (magid <= 0) or (magid >= 255) then
  begin
    Exit;
  end;
  Result := g_MagicArr[0][magid];
  {Result := nil;
  for i := g_MagicList.count - 1 downto 0 do begin
    if PTClientMagic(g_MagicList[i]).Def.wMagicId = magid then begin
      Result := PTClientMagic(g_MagicList[i]);
      Break;
    end;
  end;}
end;

function TfrmMain.HeroGetMagicByID(magid: Integer): PTClientMagic;
var
  i: Integer;
begin
  Result := nil;
  for i := g_HeroMagicList.count - 1 downto 0 do
  begin
    if PTClientMagic(g_HeroMagicList[i]).Def.wMagicid = magid then
    begin
      Result := PTClientMagic(g_HeroMagicList[i]);
      Break;
    end;
  end;
end;

procedure TfrmMain.TimerHeroActorTimer(Sender: TObject);
begin
  if (g_MySelf <> nil) then
  begin
    if not g_boMapMoving and not g_boServerChanging then
    begin
      if GetTickCount - g_MySelf.m_dwAutoTecTick > 100 then
      begin
        g_MySelf.m_dwAutoTecTick := GetTickCount;
        ActorAutoEat(g_MySelf);
      end;
    end;
    if g_MySelf.m_HeroObject <> nil then
    begin
      if GetTickCount - g_MySelf.m_dwAutoTecHeroTick > 100 then
      begin
        g_MySelf.m_dwAutoTecHeroTick := GetTickCount;
        HeroActorAutoEat(g_MySelf);
      end;
    end;
  end;
end;

procedure TfrmMain.TimerPacketTimer(Sender: TObject);
var
  data: string;
label
  LOOP;
begin
  if not g_boProcMessagePacket then
    Exit;

  BufferStr := BufferStr + SocStr;
  SocStr := '';

  if BufferStr <> '' then
  begin
    while Length(BufferStr) >= 2 do
    begin
      if g_boMapMovingWait then Break;

      if Pos('!', BufferStr) <= 0 then Break;
      
      BufferStr := ArrestStringEx(BufferStr, '#', '!', data);
      if data <> '' then
      begin
        DecodeMessagePacket(data, 0);
        //DScreen.AddChatBoardString(data, clWhite, clBlue);
      end
      else
        Break;
    end;
  end;

  if g_SeriesSkillFire_100 and (g_MySelf <> nil) and g_MySelf.ActionFinished {and (CanNextAction and ServerAcceptNextAction and CanNextHit())} then
  begin
    g_SeriesSkillFire_100 := False;
    g_nCurrentMagic2 := 1;
    g_nCurrentMagic := 888;
    UseMagic(g_nMouseX, g_nMouseY, g_MagicArr[0][g_SeriesSkillArr[0]], False, True);
  end;

  if g_boQueryPrice then
  begin
    if GetTickCount - g_dwQueryPriceTime > 500 then
    begin
      g_boQueryPrice := False;
      case FrmDlg.SpotDlgMode of
        dmSell: SendQueryPrice(g_nCurMerchant, g_SellDlgItem.MakeIndex, g_SellDlgItem.S.Name);
        dmRepair: SendQueryRepairCost(g_nCurMerchant, g_SellDlgItem.MakeIndex, g_SellDlgItem.S.Name);
        dmExchangeBook: SendQueryExchgBook(g_nCurMerchant, g_SellDlgItem.MakeIndex, g_SellDlgItem.S.Name);
      end;
    end;
  end;

  if g_nBonusPoint > 0 then
  begin
    if not FrmDlg.DBotPlusAbil.Visible then
      FrmDlg.DBotPlusAbil.Visible := True;
  end
  else
  begin
    if FrmDlg.DBotPlusAbil.Visible then
      FrmDlg.DBotPlusAbil.Visible := False;
  end;

end;

procedure TfrmMain.SmartChangePoison(pcm: PTClientMagic);
var
  Str, cStr: string;
  i: Integer;
begin
  if g_MySelf = nil then
    Exit;
  g_MySelf.m_btPoisonDecHealth := 0;
  if pcm.Def.wMagicid in [13..19, 30, 43, 55, 57] then
  begin
    Str := '符';
    cStr := '符';
  end
  else if pcm.Def.wMagicid in [6, 38] then
  begin
    if (g_MagicTarget <> nil) then
    begin
      Str := '药';
      g_boExchgPoison := not g_boExchgPoison;
      if g_boExchgPoison then
      begin
        //dec health
        g_MySelf.m_btPoisonDecHealth := 1;
        cStr := '灰';
      end
      else
      begin
        g_MySelf.m_btPoisonDecHealth := 2;
        cStr := '黄';
      end;
    end
    else
      Exit;
  end
  else
    Exit;

  //g_boCheckPoison := True;
  if (g_UseItems[U_BUJUK].S.StdMode = 25) and (g_UseItems[U_BUJUK].S.Shape <> 6) and (Pos(cStr, g_UseItems[U_BUJUK].S.Name) > 0) then
  begin
    //g_boCheckPoison := False;
    Exit;
  end;

  g_boCheckTakeOffPoison := False;
  g_WaitingUseItem.Index := U_BUJUK;
  for i := 6 to MAXBAGITEMCL - 1 do
  begin
    if (g_ItemArr[i].S.NeedIdentify < 4) and (g_ItemArr[i].S.StdMode = 25) and (g_ItemArr[i].S.Shape <> 6) and (Pos(Str, g_ItemArr[i].S.Name) > 0) and (Pos(cStr, g_ItemArr[i].S.Name) > 0) then
    begin
      g_WaitingUseItem.Item := g_ItemArr[i];
      g_ItemArr[i].S.Name := '';
      g_boCheckTakeOffPoison := True;
      SendTakeOnItem(g_WaitingUseItem.Index, g_WaitingUseItem.Item.MakeIndex, g_WaitingUseItem.Item.S.Name);
      ArrangeItembag;
      Exit;
    end;
  end;
  if Str = '符' then
    DScreen.AddChatBoardString('你的[护身符]已经用完', clWhite, clBlue)
  else if g_boExchgPoison then
    DScreen.AddChatBoardString('你的[灰色药粉]已经用完', clWhite, clBlue)
  else
    DScreen.AddChatBoardString('你的[黄色药粉]已经用完', clWhite, clBlue)
end;

procedure TfrmMain.ClientOpenBook(msg: TDefaultMessage; sBody: string);
begin
  if sBody <> '' then
  begin
    g_sBookLabel := sBody;
  end
  else
    g_sBookLabel := '';
  g_nBookPath := msg.param;
  g_nBookPage := msg.tag;
  g_HillMerchant := msg.Recog;
  if g_nBookPath > 0 then
    FrmDlg.DWBookBkgnd.Visible := True;
end;

function TfrmMain.IsRegisteredHotKey(HotKey: Cardinal): Boolean;
begin
  Result := False;
  if not FrmDlg.DWGameConfig.Visible then
    Exit;
  if FrmDlg.DxEditSSkill.HotKey = HotKey then
  begin
    Result := True;
    Exit;
  end;
  if FrmDlg.DEHeroCallHero.HotKey = HotKey then
  begin
    Result := True;
    Exit;
  end;
  if FrmDlg.DEHeroSetTarget.HotKey = HotKey then
  begin
    Result := True;
    Exit;
  end;
  if FrmDlg.DEHeroUnionHit.HotKey = HotKey then
  begin
    Result := True;
    Exit;
  end;
  if FrmDlg.DEHeroSetAttackState.HotKey = HotKey then
  begin
    Result := True;
    Exit;
  end;
  if FrmDlg.DEHeroSetGuard.HotKey = HotKey then
  begin
    Result := True;
    Exit;
  end;
  if FrmDlg.DESwitchAttackMode.HotKey = HotKey then
  begin
    Result := True;
    Exit;
  end;
  if FrmDlg.DESwitchMiniMap.HotKey = HotKey then
  begin
    Result := True;
    Exit;
  end;
end;

procedure TfrmMain.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  with DScreen do
  begin

    if WheelDelta > 0 then
    begin
      if ssCtrl in Shift then
      begin
        if ChatBoardTop > VIEWCHATLINE then
          ChatBoardTop := ChatBoardTop - VIEWCHATLINE
        else
          ChatBoardTop := 0;
      end
      else
      begin
        if not FrmDlg.DBChat.Visible then
        begin
          if ChatBoardTop >= 1 then
            Dec(ChatBoardTop, 1);
        end
        else
        begin
          ChatBoardTop := _MAX(0, ChatBoardTop - 3);
        end;
      end;
    end
    else if WheelDelta < 0 then
    begin
      if ssCtrl in Shift then
      begin
        if ChatBoardTop + VIEWCHATLINE < ChatStrs.count - 1 then
          ChatBoardTop := ChatBoardTop + VIEWCHATLINE
        else
          ChatBoardTop := ChatStrs.count - 1;
        if ChatBoardTop < 0 then
          ChatBoardTop := 0;
      end
      else
      begin
        if not FrmDlg.DBChat.Visible then
        begin
          if ChatBoardTop < ChatStrs.count - 1 then
            Inc(ChatBoardTop);
        end
        else if ChatBoardTop < ChatStrs.count - 1 then
          Inc(ChatBoardTop, _MIN(3, ChatStrs.count - 1 - ChatBoardTop));
      end;
    end;
    FrmDlg.DMBChat.UpdatePos(ChatBoardTop);
  end;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  Panel1.Width := 800;
  Panel1.Height := 600;
  Panel1.Left := (Self.Width - 800) div 2;
  Panel1.Top := (Self.Height - 600) div 2;
end;

procedure TfrmMain.DecodeMessagePacketTest(datablock: string);
var
  head, body: string;
  msg: TDefaultMessage;
begin
  if (datablock[1] = '+') or (Length(datablock) < DEFBLOCKSIZE) then
    Exit;
  head := Copy(datablock, 1, DEFBLOCKSIZE);
  body := Copy(datablock, DEFBLOCKSIZE + 1, Length(datablock) - DEFBLOCKSIZE);
  msg := DecodeMessage(head);
  case msg.ident of
    CM_PROXYDATA:
      begin
{$I '..\Common\Macros\VMPBM.inc'}
        body := DecodeString(body);
        CSocket.Socket.SendText(body);
        Timer1.Enabled := False;
{$I '..\Common\Macros\VMPE.inc'}
      end;

  end;
end;

procedure TfrmMain.Timer1Timer(Sender: TObject);
var data: string;
begin
  if not g_boProcMessagePacket then
    Exit;
  testBufferStr := testBufferStr + testSocStr;
  testSocStr := '';

  if testBufferStr <> '' then
  begin
    while Length(testBufferStr) >= 2 do
    begin
      if g_boMapMovingWait then  Break;

      if Pos('!', testBufferStr) <= 0 then  Break;

      testBufferStr := ArrestStringEx(testBufferStr, '#', '!', data);
      if data <> '' then
      begin
        DecodeMessagePacketTest(data);
      end
      else
        Break;
    end;
  end;

end;

procedure TfrmMain.Timer2Timer(Sender: TObject);
begin
  {
  if m_vtable <> nil then
  begin
    //OutputDebugString('Timer2Timer');
    m_Vtable.m_CheckPe(0);
  end;
  }
end;

procedure TfrmMain.TimerAutoMagicTimer(Sender: TObject);
var
  pcm: PTClientMagic;
  nspeed: Integer;
begin
  if (g_MySelf <> nil) and g_MySelf.m_StallMgr.OnSale then
  begin
    Exit;
  end;
  if (g_MySelf <> nil) and g_boAutoSay and (FrmDlg.DBAotoSay.tag = 0) and (g_MySelf.m_sAutoSayMsg <> '') then
  begin
    if GetTickCount - FrmDlg.m_sAutoSayMsgTick > 30 * 1000 then
    begin
      FrmDlg.m_sAutoSayMsgTick := GetTickCount;
      SendSay(g_MySelf.m_sAutoSayMsg);
    end;
  end;
  if (g_MySelf <> nil) and IsUnLockAction() then
  begin
    if CanNextAction and ServerAcceptNextAction then
    begin
      nspeed := 0;
      if g_boSpeedRate then
        nspeed := g_MagSpeedRate * 20;
      if (GetTickCount - g_dwLatestSpellTick > (g_dwSpellTime + g_dwMagicDelayTime - nspeed)) then
      begin
        if g_gcTec[4] and (g_MySelf.m_nState and $00100000 = 0) {and (g_MySelf.m_nState and $00000100 = 0)} then
        begin
          if g_MagicArr[0][31] <> nil then
          begin
            frmMain.UseMagic(SCREENWIDTH div 2, SCREENHEIGHT div 2, g_MagicArr[0][31]);
            Exit;
          end;
        end;
        case g_MySelf.m_btJob of
          0:
            begin
              if g_gcTec[3] and not g_boNextTimePursueHit then
              begin
                pcm := GetMagicByID(56);
                if pcm <> nil then
                begin
                  UseMagic(SCREENWIDTH div 2, SCREENHEIGHT div 2, pcm);
                  Exit;
                end;
              end;
              if g_gcTec[11] and not g_boNextTimeSmiteLongHit2 then
              begin
                pcm := GetMagicByID(113);
                if pcm <> nil then
                begin
                  UseMagic(SCREENWIDTH div 2, SCREENHEIGHT div 2, pcm);
                  Exit;
                end;
              end;
              if g_gcTec[2] and not g_boNextTimeFireHit then
              begin
                pcm := GetMagicByID(26);
                if pcm <> nil then
                begin
                  UseMagic(SCREENWIDTH div 2, SCREENHEIGHT div 2, pcm);
                  Exit;
                end;
              end;
              if g_gcTec[13] and not g_boCanSLonHit then
              begin
                pcm := GetMagicByID(66);
                if pcm <> nil then
                begin
                  UseMagic(SCREENWIDTH div 2, SCREENHEIGHT div 2, pcm);
                  Exit;
                end;
              end;
              if g_gcTec[9] and not g_boNextTimeTwinHit then
              begin
                pcm := GetMagicByID(43);
                if pcm <> nil then
                begin
                  UseMagic(SCREENWIDTH div 2, SCREENHEIGHT div 2, pcm);
                  Exit;
                end;
              end
            end;
          {1: begin
              if g_gcTec[4] and (g_MySelf.m_nState and $00100000 = 0) then begin
                pcm := GetMagicByID(31);
                if pcm <> nil then
                  UseMagic(SCREENWIDTH div 2, SCREENHEIGHT div 2, pcm);
              end;
            end;}
          2:
            begin
              if g_gcTec[6] and (g_MySelf.m_nState and $00800000 = 0) then
              begin
                pcm := GetMagicByID(18);
                if pcm <> nil then
                  UseMagic(SCREENWIDTH div 2, SCREENHEIGHT div 2, pcm);
              end;
            end;
        end;

        if g_gcTec[7] and (GetTickCount - g_MySelf.m_dwPracticeTick > _MAX(500, g_gnTecTime[8])) then
        begin
          g_MySelf.m_dwPracticeTick := GetTickCount;

          pcm := GetMagicByID(g_gnTecPracticeKey);
          if pcm <> nil then
            UseMagic(g_nMouseX, g_nMouseY, pcm);
        end;
      end;
    end;
  end;
end;

function TfrmMain.DirToDX(Direction, tdir: Integer): Integer;
begin
  if Direction = -1 then
    Direction := 7;
  case Direction of
    0, 4: Result := 0;
    1..3: Result := 1 * tdir;
  else
    Result := -1 * tdir;
  end;
end;

function TfrmMain.DirToDY(Direction, tdir: Integer): Integer;
begin
  if Direction = -1 then
    Direction := 7;
  case Direction of
    2, 6: Result := 0;
    3..5: Result := 1 * tdir;
  else
    Result := -1 * tdir;
  end;
end;

procedure TfrmMain.TimerAutoMoveTimer(Sender: TObject);
var
  ndir: Integer;
  X1, Y1, X2, Y2, X3, Y3: Integer;
  boCanRun: Boolean;
begin
  if (g_MySelf = nil) or (Map.m_MapBuf = nil) or (not CSocket.Active) then
    Exit;
  if g_MapPath <> nil then
  begin

    if ((g_MySelf.m_nCurrX = g_MySelf.m_nTagX) and (g_MySelf.m_nCurrY = g_MySelf.m_nTagY)) then
    begin
      TimerAutoMove.Enabled := False;
      DScreen.AddChatBoardString('已经到达终点', GetRGB(5), clWhite);
      SetLength(g_MapPath, 0);
      g_MapPath := nil;
      g_MySelf.m_nTagX := 0;
      g_MySelf.m_nTagY := 0;
    end;

    if CanNextAction and ServerAcceptNextAction and IsUnLockAction() then
    begin
      if g_MoveStep <= High(g_MapPath) then
      begin
        g_nTargetX := g_MapPath[g_MoveStep].X;
        g_nTargetY := g_MapPath[g_MoveStep].Y;
        while (abs(g_MySelf.m_nCurrX - g_nTargetX) <= 1) and (abs(g_MySelf.m_nCurrY - g_nTargetY) <= 1) do
        begin
          boCanRun := False;
          if g_MoveStep + 1 <= High(g_MapPath) then
          begin
            X1 := g_MySelf.m_nCurrX;
            Y1 := g_MySelf.m_nCurrY;
            X2 := g_MapPath[(g_MoveStep + 1)].X;
            Y2 := g_MapPath[(g_MoveStep + 1)].Y;
            ndir := GetNextDirection(X1, Y1, X2, Y2);
            GetNextPosXY(ndir, X1, Y1);

            X3 := g_MySelf.m_nCurrX;
            Y3 := g_MySelf.m_nCurrY;
            GetNextRunXY(ndir, X3, Y3);
            if (g_MapPath[(g_MoveStep + 1)].X = X3) and (g_MapPath[(g_MoveStep + 1)].Y = Y3) then
              boCanRun := True;
          end;

          if boCanRun and Map.CanMove(X1, Y1) and not g_PlayScene.CrashMan(X1, Y1) then
          begin
            Inc(g_MoveStep);
            g_nTargetX := g_MapPath[g_MoveStep].X;
            g_nTargetY := g_MapPath[g_MoveStep].Y;
            if g_MoveStep >= High(g_MapPath) then
              Break;
          end
          else
          begin
            g_nTargetX := g_MapPath[g_MoveStep].X;
            g_nTargetY := g_MapPath[g_MoveStep].Y;
            Break;
          end;
        end;

        if (abs(g_MySelf.m_nCurrX - g_MySelf.m_nTagX) <= 1) and
          (abs(g_MySelf.m_nCurrY - g_MySelf.m_nTagY) <= 1) then
        begin
          g_nTargetX := g_MySelf.m_nTagX;
          g_nTargetY := g_MySelf.m_nTagY;
        end;

        if (abs(g_MySelf.m_nCurrX - g_nTargetX) <= 1) and (abs(g_MySelf.m_nCurrY - g_nTargetY) <= 1) then
        begin //目标座标
          g_ChrAction := caWalk;
          g_MoveBusy := True;
        end
        else
        begin
          if g_MySelf.CanRun > 0 then
          begin
            g_ChrAction := caRun;
            g_MoveBusy := True;
          end
          else
          begin
            g_ChrAction := caWalk;
            g_MoveBusy := True;
          end;
        end;
      end;
    end;
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  ini: TIniFile;
begin
  if g_boFullScreen then
    Exit;
  ini := TIniFile.Create('.\lscfg.ini');
  if ini <> nil then
  begin
    ini.WriteInteger('Positions', 'Left', frmMain.Left);
    ini.WriteInteger('Positions', 'Top', frmMain.Top);
    ini.Free;
  end;
end;

procedure TfrmMain.TimerAutoPlayTimer(Sender: TObject);
var
  T: PFindNOde;
  ndir, X1, Y1: Integer;
  b: Boolean;
label
  AAAA;
  procedure randomtag();
  var
    i: Integer;
  label
    lloop;
  begin
    i := 0;
    b := False;
    ndir := g_MySelf.m_btDir;
    if Random(28) = 0 then
      ndir := Random(8);

    while i < 16 do
    begin
      if not GetNextPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, ndir, 2, g_nTargetX, g_nTargetY) then
      begin
        GetFrontPosition(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, ndir, g_nTargetX, g_nTargetY);
        if not g_PlayScene.CanWalk(g_nTargetX, g_nTargetY) then
        begin
          g_MySelf.SendMsg(CM_TURN, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, Random(8), '', 0, '', 0);
          Inc(i);
        end
        else
        begin
          b := True;
          Break;
        end;
      end
      else
      begin
        if g_PlayScene.CanWalk(g_nTargetX, g_nTargetY) then
        begin
          b := True;
          Break;
        end
        else
        begin
          ndir := Random(8);
          Inc(i);
        end;
      end;
    end;
  end;

begin
  g_sAPStr := '';
  g_boAPAutoMove := False;

  if g_MySelf = nil then
    Exit;
  if not g_boOpenAutoPlay then
    Exit;

  if g_MySelf.m_boDeath then
  begin
    g_gcAss[0] := False;
    g_APTagget := nil;
    g_AutoPicupItem := nil;
    g_nAPStatus := -1;
    g_nTargetX := -1;
    frmMain.TimerAutoPlay.Enabled := g_gcAss[0];
    WaitAndPass(2000);
    DScreen.ClearHint;
    Application.Terminate;
    Exit;
  end;

  if (g_MySelf.m_HeroObject <> nil) then
  begin
    if GetTickCount - FrmDlg.m_dwUnRecallHeroTick > 3000 then
    begin
{$I '..\Common\Macros\VMPBM.inc'}
      if (g_MySelf.m_HeroObject.m_Abil.HP <> 0) and (Round((g_MySelf.m_HeroObject.m_Abil.HP / g_MySelf.m_HeroObject.m_Abil.MaxHP) * 100) < 20) then
      begin
        FrmDlg.m_dwUnRecallHeroTick := GetTickCount;
        g_pbRecallHero^ := True;
        FrmDlg.ClientCallHero();
      end;
{$I '..\Common\Macros\VMPE.inc'}
    end;
  end
  else
  begin
    if GetTickCount - FrmDlg.m_dwUnRecallHeroTick > 62000 then
    begin
{$I '..\Common\Macros\VMPBM.inc'}
      if TargetHumCount(g_MySelf) <= 3 then
      begin
        FrmDlg.m_dwUnRecallHeroTick := GetTickCount;
        g_pbRecallHero^ := True;
        FrmDlg.ClientCallHero();
      end;
{$I '..\Common\Macros\VMPE.inc'}
    end;
  end;

  g_AutoPicupItem := nil;
  case GetAutoPalyStation() of
    0:
      begin
        if not EatItemName('回城卷') and not EatItemName('回城卷包') and not EatItemName('盟重传送石') and not EatItemName('比奇传送石') then
          DScreen.AddChatBoardString('[挂机] 你的回城卷已用完,已挂机停止!!!', clWhite, clRed)
        else
          DScreen.AddChatBoardString('[挂机] 回城并挂机停止!!!', clWhite, clRed);
        g_gcAss[0] := False;
        g_APTagget := nil;
        g_AutoPicupItem := nil;
        g_nAPStatus := -1;
        g_nTargetX := -1;
        frmMain.TimerAutoPlay.Enabled := g_gcAss[0];
        g_boAPAutoMove := True;
        Exit;
      end;
    1:
      begin //此时为该怪物首次被发现，自动寻找路径
        if HeroAttackTagget(g_APTagget) then
        begin
          Exit;
        end;
        if g_APTagget <> nil then
        begin
          g_nTargetX := g_APTagget.m_nCurrX;
          g_nTargetY := g_APTagget.m_nCurrY;
          AP_findpath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_APTagget.m_nCurrX, g_APTagget.m_nCurrY);
        end;
        g_nTargetX := -1;
        g_nAPStatus := 1;
        g_boAPAutoMove := True;
      end;
    2:
      begin //此时该物品为首次发现，自动寻找路径
        if (g_AutoPicupItem <> nil) and ((g_nAPStatus <> 2) or (g_APPathList.count = 0)) then
        begin
          g_nTargetX := g_AutoPicupItem.X;
          g_nTargetY := g_AutoPicupItem.Y;
          AP_findpath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nTargetX, g_nTargetY);
          g_nTargetX := -1;
          g_sAPStr := Format('[挂机] 物品目标：%s(%d,%d) 正在去拾取', [g_AutoPicupItem.Name, g_AutoPicupItem.X, g_AutoPicupItem.Y])
        end
        else if (g_AutoPicupItem <> nil) then
        begin
          g_nTargetX := g_AutoPicupItem.X;
          g_nTargetY := g_AutoPicupItem.Y;
          AP_findpath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nTargetX, g_nTargetY);
          g_nTargetX := -1;
          g_sAPStr := Format('[挂机] 物品目标：%s(%d,%d) 正在去拾取', [g_AutoPicupItem.Name, g_AutoPicupItem.X, g_AutoPicupItem.Y])
        end;
        g_nAPStatus := 2;
        g_boAPAutoMove := True;
      end;
    3:
      begin
        if (g_APMapPath <> nil) and (g_APStep >= 0) and (g_APStep <= High(g_APMapPath)) then
        begin
          if (High(g_APMapPath) > 0) then
          begin
            g_nTargetX := g_APMapPath[g_APStep].X;
            g_nTargetY := g_APMapPath[g_APStep].Y;
            AP_findpath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nTargetX, g_nTargetY);
            g_sAPStr := Format('[挂机] 循路搜寻目标(%d,%d)', [g_nTargetX, g_nTargetY]);
            g_nTargetX := -1;
          end
          else
          begin
            if (g_nTargetX = -1) or (g_APPathList.count = 0) then
            begin

              {invTime := 0;
              b := False;
              while invTime < 15 do begin
                Randomize;
                g_nTargetX := RandomRange(g_MySelf.m_nCurrX - 6, g_MySelf.m_nCurrX + 6);
                Randomize;
                g_nTargetY := RandomRange(g_MySelf.m_nCurrY - 6, g_MySelf.m_nCurrY + 6);
                if g_PlayScene.CanWalk(g_nTargetX, g_nTargetY) then begin
                  b := True;
                  Break;
                end;
                Inc(invTime);
              end;}
              if b then
                AP_findpath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nTargetX, g_nTargetY); //memory leak !!!
              g_sAPStr := Format('[挂机] 定点随机搜寻目标(%d,%d)', [g_APMapPath[g_APStep].X, g_APMapPath[g_APStep].Y]);
              g_nTargetX := -1;
            end;
          end;
        end
        else if (g_nTargetX = -1) or (g_APPathList.count = 0) then
        begin
          randomtag();
          {invTime := 0;
          b := False;
          while invTime < 15 do begin
            //Randomize;
            g_nTargetX := RandomRange(g_MySelf.m_nCurrX - 6, g_MySelf.m_nCurrX + 6);
            //Randomize;
            g_nTargetY := RandomRange(g_MySelf.m_nCurrY - 6, g_MySelf.m_nCurrY + 6);
            if g_PlayScene.CanWalk(g_nTargetX, g_nTargetY) then begin
              b := True;
              Break;
            end;
            Inc(invTime);
          end;}
          if b then
            AP_findpath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nTargetX, g_nTargetY); //memory leak !!!
          //g_sAPStr := format('[挂机] 随机搜寻目标(%d,%d)', [g_nTargetX, g_nTargetY]);
          g_sAPStr := '[挂机] 随机搜寻目标...';
          g_nTargetX := -1;
        end;
        g_nAPStatus := 3;
        g_boAPAutoMove := True;
      end;
    4:
      begin
        if (g_APMapPath <> nil) and (g_APStep >= 0) and (g_APStep <= High(g_APMapPath)) then
        begin
          if (g_APLastPoint.X >= 0) then
          begin
            g_nTargetX := g_APLastPoint.X;
            g_nTargetY := g_APLastPoint.Y;
            AP_findpath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nTargetX, g_nTargetY);
          end
          else
          begin
            g_nTargetX := g_APMapPath[g_APStep].X;
            g_nTargetY := g_APMapPath[g_APStep].Y;
            AP_findpath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nTargetX, g_nTargetY);
          end;
          g_sAPStr := Format('[挂机] 超出搜寻范围,返回(%d,%d)', [g_nTargetX, g_nTargetY]);
          g_nTargetX := -1;
        end
        else if (g_nTargetX = -1) or (g_APPathList.count = 0) then
        begin
          randomtag();
          {invTime := 0;
          b := False;
          while invTime < 15 do begin
            Randomize;
            g_nTargetX := RandomRange(g_MySelf.m_nCurrX - 6, g_MySelf.m_nCurrX + 6);
            Randomize;
            g_nTargetY := RandomRange(g_MySelf.m_nCurrY - 6, g_MySelf.m_nCurrY + 6);
            if g_PlayScene.CanWalk(g_nTargetX, g_nTargetY) then begin
              b := True;
              Break;
            end;
            Inc(invTime);
          end;}
          if b then
            AP_findpath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nTargetX, g_nTargetY);
          g_sAPStr := Format('[挂机] 超出搜寻范围,随机搜寻目标(%d,%d)', [g_nTargetX, g_nTargetY]);
          g_nTargetX := -1;
        end;
        g_nAPStatus := 3;
        g_boAPAutoMove := True;
      end;
  end;

  if (g_APPathList.count > 0) and ((g_nTargetX = -1) or ((g_nTargetX = g_MySelf.m_nCurrX) and (g_nTargetY = g_MySelf.m_nCurrY))) then
  begin

    T := PFindNOde(g_APPathList[0]);
    g_nTargetX := T.X;
    g_nTargetY := T.Y;

    if g_nAPStatus in [1..4] then
    begin
      if (abs(g_MySelf.m_nCurrX - g_nTargetX) <= 1) and (abs(g_MySelf.m_nCurrY - g_nTargetY) <= 1) then
      begin
        if g_PlayScene.CanWalk(g_nTargetX, g_nTargetY) then
        begin
          if (g_nAPStatus = 2) and (g_AutoPicupItem <> nil) then
          begin
            if (abs(g_MySelf.m_nCurrX - g_AutoPicupItem.X) > 1) or (abs(g_MySelf.m_nCurrY - g_AutoPicupItem.Y) > 1) then
            begin
              goto AAAA;
            end
            else
            begin
              Dispose(T);
              g_APPathList.Delete(0);
              Exit;
            end;
          end
          else
          begin
            AAAA:
            if (g_APPathList.count > 2) then
            begin
              ndir := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, PFindNOde(g_APPathList[2]).X, PFindNOde(g_APPathList[2]).Y);
            end
            else
              ndir := GetNextDirection(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_nTargetX, g_nTargetY);

            X1 := g_MySelf.m_nCurrX;
            Y1 := g_MySelf.m_nCurrY;
            GetNextRunXY(ndir, X1, Y1);

            if Map.CanMove(X1, Y1) then
            begin
              if g_PlayScene.CrashMan(X1, Y1) then
              begin
                g_nTargetX := T.X;
                g_nTargetY := T.Y;
                g_ChrAction := caWalk;
              end
              else
              begin
                g_nTargetX := X1;
                g_nTargetY := Y1;
                g_ChrAction := caRun;
              end;
            end;
          end;
        end;
      end;
    end;

    Dispose(T);
    g_APPathList.Delete(0);
  end;

  if g_boAPAutoMove and (g_APPathList.count > 0) then
  begin
    Init_Queue2();
  end;
end;

procedure TfrmMain.WMGraphNotify(var msg: TMessage);
begin
  {if MP3 = nil then Exit;
  if MP3.MediaEvent <> nil then begin
    while MP3.MediaEvent.GetEvent(EventCode, Param1, Param2, 0) = S_OK do begin
      MP3.MediaEvent.FreeEventParams(EventCode, Param1, Param2);
      if EventCode = EC_COMPLETE then begin
        if MP3.g_pMediaControl <> nil then begin
          MP3.g_pMediaControl.Stop;

          //MP3.g_pMediaControl.Run;
          //DScreen.AddChatBoardString('EC_Complete', clWhite, clblack);
        end;
        if MP3.g_pMediaSeeking <> nil then begin
          CurrentPosition := 0;
          MP3.g_pMediaSeeking.SetPositions(CurrentPosition, AM_SEEKING_AbsolutePositioning, EndPosition, AM_SEEKING_NoPositioning);
        end;
        if MP3.g_pMediaControl <> nil then begin
          MP3.g_pMediaControl.run;
          //Break;
        end;
      end;
    end;
  end;}
end;

procedure TfrmMain.ClientGetServerTitles(Len: Integer; S: string);
var
  i, len2: Integer;
  pClientItem: pTClientStdItem;
  aaa: array of TClientStdItem;

  P, p2: Pointer;
  cnt: Integer;
begin
  for i := 0 to g_TitlesList.count - 1 do
    Dispose(pTClientStdItem(g_TitlesList.Items[i]));
  g_TitlesList.Clear;

  if Len = 0 then
    Exit;

  GetMem(P, Len);
  DecodeBuffer2(S, PChar(P), Len);
  FVCLUnZip.ZLibDecompressBuffer(P, Len, p2, len2);

  cnt := len2 div SizeOf(TClientStdItem);
  SetLength(aaa, cnt);
  Move(PChar(p2)^, aaa[0], len2);
  FreeMem(P);
  FreeMem(p2);

  for i := Low(aaa) to High(aaa) do
  begin
    New(pClientItem);
    pClientItem^ := aaa[i];
    g_TitlesList.Add(pClientItem);
    //DScreen.AddChatBoardString(pClientItem.Name, clWhite, clRed);
  end;
end;
procedure TfrmMain.ReInitUserSateUI;
var
  I:  Integer;
begin
  FrmDlg.ReSetStateDlg;

  if g_boUI0508 then
  begin
    SetLength(g_DBStateStrArr,4);
    SetLength(g_DBStateStrArrUS,3);
    SetLength(g_DBStateStrArr2,4);

    g_DBStateStrArr[0] :=  '装' + sLineBreak + '备';
    g_DBStateStrArr[1] :=  '状' + sLineBreak + '态';
    g_DBStateStrArr[2] :=  '属' + sLineBreak + '性';
    g_DBStateStrArr[3] :=  '技' + sLineBreak + '能';

    g_DBStateStrArrUS[0] := '装' + sLineBreak + '备';
    g_DBStateStrArrUS[1] := '时' + sLineBreak + '装';
    g_DBStateStrArrUS[2] := '称' + sLineBreak + '号';

    g_DBStateStrArr2[0] := '状' + sLineBreak + '态';
    g_DBStateStrArr2[1] := '技' + sLineBreak + '能';
    g_DBStateStrArr2[2] := '经' + sLineBreak + '络';
    g_DBStateStrArr2[3] := '连' + sLineBreak + '击';
    Move(g_VaInfos_Def0508[0], g_VaInfos[0], SizeOf(g_VaInfos_Def0508));
  end
  else
  begin
    SetLength(g_DBStateStrArr,7);
    SetLength(g_DBStateStrArrUS,3);
    SetLength(g_DBStateStrArr2,5);

    g_DBStateStrArr[0] :=  '装' + sLineBreak + '备';
    g_DBStateStrArr[1] :=  '时' + sLineBreak + '装';
    g_DBStateStrArr[2] :=  '状' + sLineBreak + '态';
    g_DBStateStrArr[3] :=  '属' + sLineBreak + '性';
    g_DBStateStrArr[4] :=  '称' + sLineBreak + '号';
    g_DBStateStrArr[5] :=  '技' + sLineBreak + '能';
    g_DBStateStrArr[6] :=  '其' + sLineBreak + '他';

    g_DBStateStrArrUS[0] := '装' + sLineBreak + '备';
    g_DBStateStrArrUS[1] := '时' + sLineBreak + '装';
    g_DBStateStrArrUS[2] := '称' + sLineBreak + '号';

    g_DBStateStrArr2[0] := '状' + sLineBreak + '态';
    g_DBStateStrArr2[1] := '技' + sLineBreak + '能';
    g_DBStateStrArr2[2] := '经' + sLineBreak + '络';
    g_DBStateStrArr2[3] := '连' + sLineBreak + '击';
    g_DBStateStrArr2[4] := '其' + sLineBreak + '他';
    Move(g_VaInfos_Def[0], g_VaInfos[0], SizeOf(g_VaInfos_Def0508));
  end;
end;

procedure TfrmMain.InitSuiteStrs(Len: Integer; S: string);
var
  i, len2: Integer;
  SuiteItems: pTClientSuiteItems;
  aaa: array of TClientSuiteItems;
  P, p2: Pointer;
  cnt: Integer;
const
  fn = '.\Data\SuiteStrs.dat';
begin
  for i := 0 to g_SuiteItemsList.count - 1 do
    Dispose(pTClientSuiteItems(g_SuiteItemsList.Items[i]));
  g_SuiteItemsList.Clear;

  if Len = 0 then
    Exit;

  GetMem(P, Len);
  DecodeBuffer2(S, PChar(P), Len);
  FVCLUnZip.ZLibDecompressBuffer(P, Len, p2, len2);
  //zlib125.DecompressBuf(P, Len, 0, p2, len2);
  FreeMem(P);

  cnt := len2 div SizeOf(TClientSuiteItems);
  SetLength(aaa, cnt);
  Move(PChar(p2)^, aaa[0], len2);
  FreeMem(p2);

  for i := Low(aaa) to High(aaa) do
  begin
    New(SuiteItems);
    SuiteItems^ := aaa[i];
    g_SuiteItemsList.Add(SuiteItems);
  end;
end;

procedure TfrmMain.ClientGetFoxState(msg: TDefaultMessage; Buff: string);
var
  i: Integer;
  NameCol, data, Buff2, FeatureMsg: string;
  desc, desc2: TCharDesc;
  Actor: TActor;
begin
  DecodeBuffer(Buff, @desc2,SizeOf(TCharDesc));
  Setlength(FeatureMsg, desc2.FeatureLen);
  DecodeBuffer(Copy(Buff, GetCodeMsgSize(SizeOf(TCharDesc) * 4 / 3) + 1, GetCodeMsgSize(desc2.FeatureLen * 4 / 3)), @FeatureMsg[1], desc2.FeatureLen);
  i := GetCodeMsgSize(SizeOf(TCharDesc) * 4 / 3) + GetCodeMsgSize(desc2.FeatureLen * 4 / 3);
  if Length(Buff) > i then
  begin
    Buff2 := Copy(Buff, i + 1, Length(Buff));
    data := DecodeString(Buff2);
    Buff2 := Copy(Buff, 1, i);
    NameCol := GetValidStr3(data, data, ['/']);
  end
  else
  begin
    Buff2 := Buff;
    data := '';
  end;
  DecodeBuffer(Buff2, @desc, SizeOf(TCharDesc));
  g_PlayScene.SendMsg(SM_TURN, msg.Recog,
    msg.param {x},
    msg.tag {y},
    msg.series {dir + light},
    desc.FeatureLen,
    desc.Status,
    FeatureMsg, desc.StatusEx);

  if data <> '' then
  begin
    Actor := g_PlayScene.FindActor(msg.Recog);
    if Actor <> nil then
    begin
      Actor.m_sDescUserName := GetValidStr3(data, Actor.m_sUserName, ['\']);
      Actor.m_sUserNameOffSet := TextWidthA(Actor.m_sUserName, False) div 2;
      Actor.m_btNameColor := Str_ToInt(NameCol, 0);
      if Actor.m_btRace = RCC_MERCHANT then
        Actor.m_nNameColor := clLime
      else
        Actor.m_nNameColor := GetRGB(Actor.m_btNameColor);
      Actor.m_nTempState := HiByte(msg.series);
    end;
  end;
end;

procedure TfrmMain.SendCDCheck();
begin

end;

procedure TfrmMain.ClientGetPositionMove(msg: TDefaultMessage; Buff: string);
var
  pActor: TActor;
  fFlay: Boolean;
  psMessage: TPostionMoveMessage;
  Len: Integer;
  FeatureMsg: string;
begin
  Len :=  pos('/', Buff);
  pActor := g_PlayScene.FindActor(msg.Recog);
  if pActor <> nil then
  begin
    DecodeBuffer(Copy(Buff, 1, len - 1), @psMessage, SizeOf(psMessage));
    DecodeBuffer(Copy(Buff, len + 1, Length(Buff)), @FeatureMsg[1], psMessage.lFeature);
    pActor.m_fHideMode := True;

    g_PlayScene.NewMagic(pActor, 0075, 0075,
      pActor.m_nCurrX, pActor.m_nCurrY,
      msg.param, msg.tag,
      msg.Recog, mtExploBujauk, False, 60, fFlay);
    g_SndMgr.PlaySound('Wav\cyclone.wav');

    if msg.Recog = g_MySelf.m_nRecogId then
    begin
      pActor.SendMsg(SM_TURN, msg.param, msg.tag, LoByte(msg.series), FeatureMsg, psMessage.nStatus, psMessage.szBuff, 0, 300);
    end
    else
    begin
      pActor.SendMsg(SM_TURN, msg.param, msg.tag, LoByte(msg.series), FeatureMsg, psMessage.nStatus, psMessage.szBuff, 0, 300);
    end;
  end;

end;

procedure TfrmMain.ProcessActMsg(datablock: string);
var
  data, tagstr: string;
  cltime, svtime: Integer;
  rtime: LongWord;
  meff: TMagicEff;
begin
{$I '..\Common\Macros\VMPBM.inc'}
  if (datablock[2] = 'G') and (datablock[3] = 'D') and (datablock[4] = '/') then
  begin
    data := Copy(datablock, 2, Length(datablock) - 1);
    data := GetValidStr3(data, tagstr, ['/']);
    if data <> '' then
    begin
      rtime := LongWord(Str_ToInt(data, 0));

      if rtime <= 0 then
        Exit;

      if g_rtime = rtime then
        Exit;

      g_rtime := rtime;

      //if tagstr = 'GD' then begin
      ActionLock := False;
      g_MoveBusy := False;
      //ActionFailLock := False;
      g_MoveErr := 0;
      if TimerAutoMove.Enabled then
        Inc(g_MoveStep);

      //if data <> '' then begin
        //CheckSpeedHack(Str_ToInt(data, 0));
{$IF CHECKPACKED}
      if g_dwFirstServerTime > 0 then
      begin
        if (GetTickCount - g_dwFirstClientTime) > 10 * 60 * 1000 then
        begin
          g_dwFirstServerTime := rtime;
          g_dwFirstClientTime := GetTickCount;
        end;
        cltime := GetTickCount - g_dwFirstClientTime;
        svtime := rtime - g_dwFirstServerTime;
        //DScreen.AddChatBoardString('[速度检测] 时间差：' + IntToStr(cltime - svtime), GetRGB(219), clWhite);
        if cltime > svtime + 4500 then
        begin
          Inc(g_nTimeFakeDetectCount);
          if g_nTimeFakeDetectCount >= 3 then
          begin
            //FrmDlg.DMessageDlg('系统不稳定或网络状态极差，游戏被中止！\如有问题请联系游戏管理员！', [mbOk]);
            ExitProcess(0);
            DScreen.Finalize;
            g_PlayScene.Finalize;
            LoginNoticeScene.Finalize;
            frmMain.Close;
            FrmDlg.Free;
            frmMain.Free;
          end;
        end
        else
        begin
          if abs(cltime - svtime) < 20 then
          begin
            g_nTimeFakeDetectCount := 0;
          end
          else if abs(cltime - svtime) < 40 then
          begin
            if g_nTimeFakeDetectCount > 1 then
              Dec(g_nTimeFakeDetectCount, 2);
          end
          else if abs(cltime - svtime) < 80 then
          begin
            if g_nTimeFakeDetectCount > 0 then
              Dec(g_nTimeFakeDetectCount);
          end;
        end;
      end
      else
      begin
        g_dwFirstServerTime := rtime;
        g_dwFirstClientTime := GetTickCount;
      end;
{$IFEND CHECKPACKED}
    end;
    Exit;
  end
  else
  begin
    tagstr := Copy(datablock, 2, Length(datablock) - 1);
  end;

  if tagstr = 'DIG' then
    g_MySelf.m_boDigFragment := True
  else if tagstr = 'PWR' then
    g_boNextTimePowerHit := True
  else if tagstr = 'LNG' then
    g_boCanLongHit := True
  else if tagstr = 'ULNG' then
    g_boCanLongHit := False
  else if tagstr = 'WID' then
    g_boCanWideHit := True
  else if tagstr = 'UWID' then
    g_boCanWideHit := False
  else if tagstr = 'STN' then
    g_boCanStnHit := True
  else if tagstr = 'USTN' then
    g_boCanStnHit := False
  else if tagstr = 'CRS' then
  begin
    g_boCanCrsHit := True;
    DScreen.AddChatBoardString('双龙斩开启', GetRGB(219), clWhite);
  end
  else if tagstr = 'UCRS' then
  begin
    g_boCanCrsHit := False;
    DScreen.AddChatBoardString('双龙斩关闭', GetRGB(219), clWhite);
  end
  else if tagstr = 'TWN' then
  begin
    g_boNextTimeTwinHit := True;
    g_dwLatestTwinHitTick := GetTickCount;
    DScreen.AddChatBoardString('召集雷电力量成功', GetRGB(219), clWhite);

    meff := TCharEffect.Create(210, 6, g_MySelf);
    meff.NextFrameTime := 80;
    meff.ImgLib := g_WMagic2Images;
    g_PlayScene.m_EffectList.Add(meff);
    g_SndMgr.PlaySound(s_twinhitReady);
  end
  else if tagstr = 'UTWN' then
  begin
    g_boNextTimeTwinHit := False;
    DScreen.AddChatBoardString('雷电力量消失', GetRGB(219), clWhite);
  end
  else if tagstr = 'SQU' then
  begin
    g_boCanSquHit := True;
    DScreen.AddChatBoardString('[龙影剑法] 开启', GetRGB(219), clWhite);
  end
  else if tagstr = 'FIR' then
  begin
    g_boNextTimeFireHit := True;
    g_dwLatestFireHitTick := GetTickCount;
    //Myself.SendMsg (SM_READYFIREHIT, Myself.XX, Myself.m_nCurrY, Myself.Dir, 0, 0, '', 0);
  end
  else if tagstr = 'PUR' then
  begin
    g_boNextTimePursueHit := True;
    g_dwLatestPursueHitTick := GetTickCount;
  end
  else if tagstr = 'RSH' then
  begin
    g_boNextTimeRushHit := True;
    g_dwLatestRushHitTick := GetTickCount;
  end
  else if tagstr = 'SMI' then
  begin
    g_boNextTimeSmiteHit := True;
    g_dwLatestSmiteHitTick := GetTickCount;
    //DScreen.AddChatBoardString('三绝杀 get ready...', clWhite, clRed);
  end
  else if tagstr = 'SMIL3' then
  begin
    g_boNextTimeSmiteLongHit3 := True;
    g_dwLatestSmiteLongHitTick3 := GetTickCount;
    DScreen.AddChatBoardString('[血魂一击] 已准备...', GetRGB(219), clWhite);
  end
  else if tagstr = 'SMIL' then
  begin
    g_boNextTimeSmiteLongHit := True;
    g_dwLatestSmiteLongHitTick := GetTickCount;
    //DScreen.AddChatBoardString('断岳斩 get ready...', clWhite, clRed);
  end
  else if tagstr = 'SMIL2' then
  begin
    g_boNextTimeSmiteLongHit2 := True;
    g_dwLatestSmiteLongHitTick2 := GetTickCount;
    DScreen.AddChatBoardString('[断空斩] 已准备...', GetRGB(219), clWhite);
  end
  else if tagstr = 'SMIW' then
  begin
    g_boNextTimeSmiteWideHit := True;
    g_dwLatestSmiteWideHitTick := GetTickCount;
  end
  else if tagstr = 'SMIW2' then
  begin
    g_boNextTimeSmiteWideHit2 := True;
    g_dwLatestSmiteWideHitTick2 := GetTickCount;
    DScreen.AddChatBoardString('[倚天辟地] 已准备', clBlue, clWhite);
    g_SndMgr.PlaySound('Wav\S6-1.wav');
  end
  else if tagstr = 'MDS' then
  begin
    DScreen.AddChatBoardString('[美杜莎之瞳] 技能可施展', clBlue, clWhite);
    meff := TCharEffect.Create(1110, 10, g_MySelf);
    meff.NextFrameTime := 80;
    meff.ImgLib := g_WMagic2Images;
    g_PlayScene.m_EffectList.Add(meff);
    g_SndMgr.PlaySound('wav\M1-2.wav');
  end
  else if tagstr = 'UFIR' then
    g_boNextTimeFireHit := False
  else if tagstr = 'UPUR' then
    g_boNextTimePursueHit := False
  else if tagstr = 'USMI' then
    g_boNextTimeSmiteHit := False
  else if tagstr = 'URSH' then
    g_boNextTimeRushHit := False
  else if tagstr = 'USMIL' then
    g_boNextTimeSmiteLongHit := False
  else if tagstr = 'USML3' then
    g_boNextTimeSmiteLongHit3 := False
  else if tagstr = 'USML2' then
  begin
    g_boNextTimeSmiteLongHit2 := False;
    //DScreen.AddChatBoardString('[断空斩] 力量消失...', clWhite, clRed);
  end
  else if tagstr = 'USMIW' then
    g_boNextTimeSmiteWideHit := False
  else if tagstr = 'USMIW2' then
    g_boNextTimeSmiteWideHit2 := False
  else if tagstr = 'USQU' then
  begin
    g_boCanSquHit := False;
    DScreen.AddChatBoardString('[龙影剑法] 关闭', GetRGB(219), clWhite);
  end
  else if tagstr = 'SLON' then
  begin
    g_boCanSLonHit := True;
    g_dwLatestSLonHitTick := GetTickCount;
    DScreen.AddChatBoardString('[开天斩] 力量凝聚...', GetRGB(219), clWhite);
  end
  else if tagstr = 'USLON' then
  begin
    g_boCanSLonHit := False;
    DScreen.AddChatBoardString('[开天斩] 力量消失', clWhite, clRed);
  end;
{$I '..\Common\Macros\VMPE.inc'}
end;

procedure TfrmMain.ClientGetMyTitles(nHero: Integer; Buff: string);
var
  i: Integer;
  data: string;
  ht: THumTitle;
begin
  if nHero <> 0 then
    FillChar(g_hTitles, SizeOf(g_hTitles), 0)
  else
    FillChar(g_Titles, SizeOf(g_Titles), 0);
  i := 0;
  while True do
  begin
    if Buff = '' then
      Break;
    Buff := GetValidStr3(Buff, data, ['/']);
    if data <> '' then
    begin
      DecodeBuffer(data, @ht, SizeOf(THumTitle));

      if nHero <> 0 then
        g_hTitles[i] := ht
      else
        g_Titles[i] := ht;

      Inc(i);
      if i > High(THumTitles) then
        Break;
    end
    else
      Break;
  end;
end;

procedure TfrmMain.timerRefreshTimer(Sender: TObject);
begin
  if frmdlg.Memo.Visible and timerRefresh.Enabled then
  begin
   timerRefresh.Enabled := False;
   frmdlg.Memo.Repaint;
   canReDraw := False;
  end;
end;
//  寻路算法     2019-12-14
procedure TfrmMain.AutoMove(TagX, TagY: Integer);
begin
  if (g_MySelf.m_nCurrX = TagX) and (g_MySelf.m_nCurrY = TagY)  then  Exit;
  if  (TagX > 0)  and (TagY > 0) then
  begin
    g_MySelf.m_nTagX := TagX;
    g_MySelf.m_nTagY := TagY;
    if not g_PathBusy then
    begin
      g_PathBusy := True;
      try
        Map.LoadMapData();
        g_MapPath := Map.FindPath(g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, g_MySelf.m_nTagX, g_MySelf.m_nTagY, 0);
        //g_MapPath := Map.FindPath(g_MySelf.m_nTagX, g_MySelf.m_nTagY, g_MySelf.m_nCurrX, g_MySelf.m_nCurrY, 0);
        if g_MapPath <> nil then
        begin
          g_MoveStep := 1;
          TimerAutoMove.Enabled := True;
          DScreen.AddChatBoardString(Format('自动移动至坐标(%d:%d)，点击鼠标任意键停止……', [g_MySelf.m_nTagX, g_MySelf.m_nTagY]), GetRGB(5), clWhite);
        end
        else
        begin
          TimerAutoMove.Enabled := False;
          DScreen.AddChatBoardString(Format('自动移动坐标点(%d:%d)不可到达', [g_MySelf.m_nTagX, g_MySelf.m_nTagY]), GetRGB(5), clWhite);
          g_MySelf.m_nTagX := 0;
          g_MySelf.m_nTagY := 0;
        end;
      finally
        g_PathBusy := False;
      end;
    end;
  end;
end;


end.

