#include <a_samp>
#include <streamer>
#include <sscanf2>
#include <zcmd>
#include <easyDialog>

#define MORTE_TIMER_DURATION 300
#define CUSTO_HOSPITAL 10000
#define CUSTO_MEDICO 4000
#define PAGAMENTO_MEDICO 4000

enum E_DATA_DEATH
{
    Float:PosX,
    Float:PosY,
    Float:PosZ,
    Interior,
    VirtualWorld,
    bool:isDead
}
new gDeathData[MAX_PLAYERS][E_DATA_DEATH];

new DeathTimer[MAX_PLAYERS];
new DeathTimeLeft[MAX_PLAYERS];
new bool:CheckpointActive[MAX_PLAYERS];
new LocatedPatient[MAX_PLAYERS];

new PlayerText:__deathScreen[MAX_PLAYERS][16];

forward updateDeath(playerid);
forward reanimatingPlayer(playerid, otherid);

main(){}


/*
                                                   ooooooooo.   ooooo     ooo oooooooooo.  ooooo        ooooo   .oooooo.    .oooooo..o 
                                                   `888   `Y88. `888'     `8' `888'   `Y8b `888'        `888'  d8P'  `Y8b  d8P'    `Y8 
                                                    888   .d88'  888       8   888     888  888          888  888          Y88bo.      
                                                    888ooo88P'   888       8   888oooo888'  888          888  888           `"Y8888o.  
                                                    888          888       8   888    `88b  888          888  888               `"Y88b 
                                                    888          `88.    .8'   888    .88P  888       o  888  `88b    ooo  oo     .d8P 
                                                   o888o           `YbodP'    o888bood8P'  o888ooooood8 o888o  `Y8bood8P'  8""88888P'  
*/

public OnPlayerConnect(playerid)
{
    DeathTimer[playerid] = 0;
    KillTimer(DeathTimer[playerid]);
    DeathTimeLeft[playerid] = 0;
    gDeathData[playerid][isDead] = false;

    createTextdrawDeath(playerid);
    return true;
}

public OnPlayerDisconnect(playerid, reason)
{
    KillTimer(DeathTimer[playerid]);
    gDeathData[playerid][isDead] = false;

    if(CheckpointActive[playerid])
    {
        DisablePlayerCheckpoint(playerid);
        CheckpointActive[playerid] = false;
    }
    return true;
}

public OnPlayerSpawn(playerid)
{
    if (gDeathData[playerid][isDead])
    {
        SetPlayerPos(playerid, gDeathData[playerid][PosX], gDeathData[playerid][PosY], gDeathData[playerid][PosZ]);
        SetPlayerInterior(playerid, gDeathData[playerid][Interior]);
        SetPlayerVirtualWorld(playerid, gDeathData[playerid][VirtualWorld]);

        showDeathScreen(playerid);
        ApplyAnimation(playerid, "CRACK", "CRCKIDLE2", 4.0, 1, 0, 0, 0, 0, 1);
        SetPlayerHealth(playerid, 9999.0);

        if (DeathTimer[playerid] == 0)
        {
            DeathTimer[playerid] = SetTimerEx("updateDeath", 1000, true, "i", playerid);
        }

        return true;
    }
    return true;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    GetPlayerPos(playerid, gDeathData[playerid][PosX], gDeathData[playerid][PosY], gDeathData[playerid][PosZ]);
    gDeathData[playerid][Interior] = GetPlayerInterior(playerid);
    gDeathData[playerid][VirtualWorld] = GetPlayerVirtualWorld(playerid);
    gDeathData[playerid][isDead] = true;

    showDeathScreen(playerid);
    
    DeathTimeLeft[playerid] = MORTE_TIMER_DURATION;
    DeathTimer[playerid] = SetTimerEx("updateDeath", 1000, true, "i", playerid);
    
    updateDeath(playerid); 
    return true;
}

public OnPlayerEnterCheckpoint(playerid)
{
    if(CheckpointActive[playerid])
    {
        DisablePlayerCheckpoint(playerid);
        CheckpointActive[playerid] = false;
        
        new msg[128];
        format(msg, sizeof(msg), "Waze: Voce chegou no local do paciente (ID: %d)! O checkpoint foi removido.", LocatedPatient[playerid]);
        SendClientMessage(playerid, 0x00FF00AA, msg); 
        
        LocatedPatient[playerid] = INVALID_PLAYER_ID;
    }
    return true;
}

public reanimatingPlayer(playerid, otherid)
{
    if(!gDeathData[otherid][isDead]) return false;
    
    ClearAnimations(otherid, 1);
    ClearAnimations(playerid, 1);
    
    SetPlayerHealth(otherid, 100.0);
    
    new dinheiroPaciente = GetPlayerMoney(otherid);
    if(dinheiroPaciente >= CUSTO_MEDICO)
    {
        GivePlayerMoney(otherid, -CUSTO_MEDICO);
        GivePlayerMoney(playerid, PAGAMENTO_MEDICO);
        
        SendClientMessage(otherid, 0x5ECE0BFF, "Tratamento: O medico curou voce e isso lhe custou R$4.000");
        SendClientMessage(playerid, 0x5ECE0BFF, "Tratamento: Voce recebeu R$4.000 por salvar uma vida");
    }
    else
    {
        SendClientMessage(otherid, 0x5ECE0BFF, "Tratamento: O medico curou voce gratuitamente (sem dinheiro)");
        SendClientMessage(playerid, 0x5ECE0BFF, "Tratamento: Voce salvou uma vida, mas o paciente nao tinha dinheiro");
    }
    
    gDeathData[otherid][isDead] = false;
    KillTimer(DeathTimer[otherid]);
    hideDeathScreen(otherid);
    
    return true;
}

public updateDeath(playerid)
{
    if(!gDeathData[playerid][isDead]) 
    {
        KillTimer(DeathTimer[playerid]);
        DeathTimer[playerid] = 0;
        return 0;
    }

    DeathTimeLeft[playerid]--;

    new string[128];
    new minutos;
    new segundos;
    minutos = DeathTimeLeft[playerid] / 60;
    segundos = DeathTimeLeft[playerid] % 60;

    if(minutos > 0)
    {
        if(segundos == 0)
        {
            format(string, sizeof(string), "%d_minuto%s_e_00_segundos", minutos, (minutos == 1) ? ("") : ("s"));
        }
        else
        {
            format(string, sizeof(string), "%d_minuto%s_e_%02d_segundos", minutos, (minutos == 1) ? ("") : ("s"), segundos);
        }
    }
    else
    {
        format(string, sizeof(string), "%d_segundo%s", segundos, (segundos == 1) ? ("") : ("s"));
    }
    
    PlayerTextDrawSetString(playerid, __deathScreen[playerid][14], string);

    SetPlayerHealth(playerid, 9999.0);
    SetPlayerPos(playerid, gDeathData[playerid][PosX], gDeathData[playerid][PosY], gDeathData[playerid][PosZ]);
    SetPlayerInterior(playerid, gDeathData[playerid][Interior]);
    SetPlayerVirtualWorld(playerid, gDeathData[playerid][VirtualWorld]);
    ApplyAnimation(playerid, "CRACK", "CRCKIDLE2", 4.0, 1, 0, 0, 0, 0, 1);

    if(DeathTimeLeft[playerid] <= 0)
    {
        finishDeath(playerid, false);
    }
    return true;
}
/*
                                                 .oooooo..o ooooooooooooo   .oooooo.     .oooooo.   oooo    oooo  .oooooo..o 
                                                d8P'    `Y8 8'   888   `8  d8P'  `Y8b   d8P'  `Y8b  `888   .8P'  d8P'    `Y8 
                                                Y88bo.           888      888      888 888           888  d8'    Y88bo.      
                                                 `"Y8888o.       888      888      888 888           88888[       `"Y8888o.  
                                                     `"Y88b      888      888      888 888           888`88b.         `"Y88b 
                                                oo     .d8P      888      `88b    d88' `88b    ooo   888  `88b.  oo     .d8P 
                                                8""88888P'      o888o      `Y8bood8P'   `Y8bood8P'  o888o  o888o 8""88888P'  
*/

stock finishDeath(playerid, bool:desistiu)
{
    if(!gDeathData[playerid][isDead]) return true;
    
    gDeathData[playerid][isDead] = false;
    KillTimer(DeathTimer[playerid]);
    DeathTimer[playerid] = 0;
    ClearAnimations(playerid, 1);
    
    if(desistiu)
    {
        new dinheiro = GetPlayerMoney(playerid);
        if(dinheiro >= CUSTO_HOSPITAL)
        {
            GivePlayerMoney(playerid, -CUSTO_HOSPITAL);
            SendClientMessage(playerid, 0xC72C30FF, "Morte: Voce desistiu de viver e pagou R$10.000 para o hospital!");
        }
        else
        {
            SendClientMessage(playerid, 0xC72C30FF, "Morte: Voce desistiu de viver mas nao tinha dinheiro para pagar o hospital!");
        }
        
        SetPlayerPos(playerid, 1183.3020, -1332.3422, 13.5829);
        SetPlayerInterior(playerid, 0);
        SetPlayerVirtualWorld(playerid, 0);
    }
    else
    {
        SendClientMessage(playerid, 0xC72C30FF, "Morte: Voce morreu e ninguem lhe salvou. Voce nasceu no hospital");
        SetPlayerHealth(playerid, 100.0);

        SetPlayerPos(playerid, 1183.3020, -1332.3422, 13.5829);
        SetPlayerInterior(playerid, 0);
        SetPlayerVirtualWorld(playerid, 0);
    }
    
    hideDeathScreen(playerid);
    return true;
}

stock createTextdrawDeath(playerid)
{
    __deathScreen[playerid][0] = CreatePlayerTextDraw(playerid, 325.000, 1.000, "_");
    PlayerTextDrawLetterSize(playerid, __deathScreen[playerid][0], 0.000, 49.499);
    PlayerTextDrawTextSize(playerid, __deathScreen[playerid][0], 0.000, 654.000);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][0], 2);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][0], -1);
    PlayerTextDrawUseBox(playerid, __deathScreen[playerid][0], 1);
    PlayerTextDrawBoxColor(playerid, __deathScreen[playerid][0], 100);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][0], 1);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][0], 1);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][0], 150);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][0], 1);    

    __deathScreen[playerid][1] = CreatePlayerTextDraw(playerid, 290.000, 142.000, "LD_BEAT:chit");
    PlayerTextDrawTextSize(playerid, __deathScreen[playerid][1], 60.000, 76.000);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][1], 1);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][1], -195264513);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][1], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][1], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][1], 255);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][1], 4);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][1], 1);

    __deathScreen[playerid][2] = CreatePlayerTextDraw(playerid, 294.000, 147.000, "LD_BEAT:chit");
    PlayerTextDrawTextSize(playerid, __deathScreen[playerid][2], 52.000, 66.000);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][2], 1);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][2], 505290495);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][2], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][2], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][2], 255);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][2], 4);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][2], 1);

    __deathScreen[playerid][3] = CreatePlayerTextDraw(playerid, 309.000, 170.000, "LD_BEAT:chit");
    PlayerTextDrawTextSize(playerid, __deathScreen[playerid][3], 8.000, 10.000);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][3], 1);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][3], -195264513);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][3], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][3], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][3], 255);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][3], 4);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][3], 1);

    __deathScreen[playerid][4] = CreatePlayerTextDraw(playerid, 321.000, 170.000, "LD_BEAT:chit");
    PlayerTextDrawTextSize(playerid, __deathScreen[playerid][4], 8.000, 10.000);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][4], 1);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][4], -195264513);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][4], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][4], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][4], 255);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][4], 4);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][4], 1);

    __deathScreen[playerid][5] = CreatePlayerTextDraw(playerid, 321.000, 184.000, "LD_BEAT:chit");
    PlayerTextDrawTextSize(playerid, __deathScreen[playerid][5], 6.000, 7.000);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][5], 1);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][5], -195264513);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][5], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][5], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][5], 255);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][5], 4);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][5], 1);

    __deathScreen[playerid][6] = CreatePlayerTextDraw(playerid, 320.000, 183.000, "LD_BEAT:chit");
    PlayerTextDrawTextSize(playerid, __deathScreen[playerid][6], 6.000, 7.000);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][6], 1);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][6], -195264513);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][6], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][6], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][6], 255);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][6], 4);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][6], 1);

    __deathScreen[playerid][7] = CreatePlayerTextDraw(playerid, 319.000, 182.000, "LD_BEAT:chit");
    PlayerTextDrawTextSize(playerid, __deathScreen[playerid][7], 6.000, 7.000);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][7], 1);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][7], -195264513);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][7], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][7], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][7], 255);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][7], 4);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][7], 1);

    __deathScreen[playerid][8] = CreatePlayerTextDraw(playerid, 315.000, 181.000, "LD_BEAT:chit");
    PlayerTextDrawTextSize(playerid, __deathScreen[playerid][8], 10.000, 7.000);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][8], 1);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][8], -195264513);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][8], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][8], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][8], 255);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][8], 4);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][8], 1);

    __deathScreen[playerid][9] = CreatePlayerTextDraw(playerid, 310.000, 180.000, "LD_BEAT:chit");
    PlayerTextDrawTextSize(playerid, __deathScreen[playerid][9], 7.000, 10.000);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][9], 1);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][9], -195264513);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][9], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][9], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][9], 255);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][9], 4);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][9], 1);

    __deathScreen[playerid][10] = CreatePlayerTextDraw(playerid, 311.000, 179.000, "LD_BEAT:chit");
    PlayerTextDrawTextSize(playerid, __deathScreen[playerid][10], 5.000, 9.000);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][10], 1);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][10], -195264513);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][10], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][10], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][10], 255);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][10], 4);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][10], 1);

    __deathScreen[playerid][11] = CreatePlayerTextDraw(playerid, 321.000, 207.000, "Voce_desmaiou.");
    PlayerTextDrawLetterSize(playerid, __deathScreen[playerid][11], 0.349, 1.800);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][11], 2);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][11], -1);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][11], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][11], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][11], 150);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][11], 1);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][11], 1);

    __deathScreen[playerid][12] = CreatePlayerTextDraw(playerid, 322.000, 233.000, "Aparentemente_as_coisas_nao_sairam_como_planejado,_e~n~agora_voce_esta_ai_lutando_pela_sua_vida.");
    PlayerTextDrawLetterSize(playerid, __deathScreen[playerid][12], 0.180, 1.099);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][12], 2);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][12], -2139062017);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][12], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][12], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][12], 150);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][12], 1);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][12], 1);

    __deathScreen[playerid][13] = CreatePlayerTextDraw(playerid, 322.000, 274.000, "Voce_precisa_ser_reanimado,_ou_aguarde");
    PlayerTextDrawLetterSize(playerid, __deathScreen[playerid][13], 0.180, 1.099);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][13], 2);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][13], -2139062017);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][13], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][13], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][13], 150);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][13], 1);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][13], 1);

    __deathScreen[playerid][14] = CreatePlayerTextDraw(playerid, 322.000, 291.000, "2_minutos_e_41_segundos");
    PlayerTextDrawLetterSize(playerid, __deathScreen[playerid][14], 0.349, 1.899);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][14], 2);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][14], -1);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][14], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][14], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][14], 150);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][14], 1);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][14], 1);

    __deathScreen[playerid][15] = CreatePlayerTextDraw(playerid, 322.000, 316.000, "Para_desistir_e_ir_direto_ao_Hospital.");
    PlayerTextDrawLetterSize(playerid, __deathScreen[playerid][15], 0.180, 1.099);
    PlayerTextDrawAlignment(playerid, __deathScreen[playerid][15], 2);
    PlayerTextDrawColor(playerid, __deathScreen[playerid][15], -2139062017);
    PlayerTextDrawSetShadow(playerid, __deathScreen[playerid][15], 0);
    PlayerTextDrawSetOutline(playerid, __deathScreen[playerid][15], 0);
    PlayerTextDrawBackgroundColor(playerid, __deathScreen[playerid][15], 150);
    PlayerTextDrawFont(playerid, __deathScreen[playerid][15], 1);
    PlayerTextDrawSetProportional(playerid, __deathScreen[playerid][15], 1);
}

stock showDeathScreen(playerid)
{  
    for (new i = 0; i < sizeof(__deathScreen[]); i++)
    {
        if (__deathScreen[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        { 
            PlayerTextDrawShow(playerid, __deathScreen[playerid][i]);
        }
    }
}

stock hideDeathScreen(playerid)
{  
    for (new i = 0; i < sizeof(__deathScreen[]); i++)
    {
        if (__deathScreen[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        { 
            PlayerTextDrawHide(playerid, __deathScreen[playerid][i]);
        }
    }
}

stock getDistanceBetweenPlayers(playerid, playerid2) 
{
    new Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2, Float:tmpdis;
    GetPlayerPos(playerid, x1, y1, z1);
    GetPlayerPos(playerid2, x2, y2, z2);
    tmpdis = floatsqroot(floatpower(floatabs(floatsub(x2, x1)), 2) +floatpower(floatabs(floatsub(y2, y1)), 2)+floatpower(floatabs(floatsub(z2, z1)), 2));
    return floatround(tmpdis);
} 

/*
                                                .oooooo.     .oooooo.   ooo        ooooo       .o.       ooooo      ooo oooooooooo.     .oooooo.    .oooooo..o 
                                               d8P'  `Y8b   d8P'  `Y8b  `88.       .888'      .888.      `888b.     `8' `888'   `Y8b   d8P'  `Y8b  d8P'    `Y8 
                                              888          888      888  888b     d'888      .8"888.      8 `88b.    8   888      888 888      888 Y88bo.      
                                              888          888      888  8 Y88. .P  888     .8' `888.     8   `88b.  8   888      888 888      888  `"Y8888o.  
                                              888          888      888  8  `888'   888    .88ooo8888.    8     `88b.8   888      888 888      888      `"Y88b 
                                              `88b    ooo  `88b    d88'  8    Y     888   .8'     `888.   8       `888   888     d88' `88b    d88' oo     .d8P 
                                               `Y8bood8P'   `Y8bood8P'  o8o        o888o o88o     o8888o o8o        `8  o888bood8P'    `Y8bood8P'  8""88888P'  
*/

COMMAND:reanimar(playerid, params[])
{
    if(IsPlayerInAnyVehicle(playerid))
        return SendClientMessage(playerid, 0xFF4500FF, "Falha: Voce nao pode reanimar o paciente dentro de um veiculo.");

    new targetid;
    if(sscanf(params, "r", targetid)) 
        return SendClientMessage(playerid, 0xFF4500FF, "/REANIMAR [ID]");
    
    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, 0xFF4500FF, "Falha: Jogador nao conectado.");
    
    //if(playerid == targetid)
     //   return SendClientMessage(playerid, 0xFF4500FF, "Falha: Voce nao pode reanimar a si mesmo");
    
    if(!gDeathData[targetid][isDead])
        return SendClientMessage(playerid, 0xFF4500FF, "Falha: Este jogador nao esta morto.");
    
    new Float:dist = getDistanceBetweenPlayers(playerid, targetid);
    if(dist > 3.0)
        return SendClientMessage(playerid, 0xFF4500FF, "Falha: Voce nao esta perto o suficiente do paciente.");

    ApplyAnimation(playerid, "MEDIC", "CPR", 4.1, 0, 0, 0, 0, 0, 1);
    SendClientMessage(playerid, 0x5ECE0BFF, "RCP: Reanimando paciente...");
    
    SetTimerEx("reanimatingPlayer", 5000, false, "dd", playerid, targetid);
    return true;
}

COMMAND:morrer(playerid, params[])
{
    if(gDeathData[playerid][isDead])
        return false;

    SetPlayerHealth(playerid, 0.0);
    gDeathData[playerid][isDead] = true;
    return true;
}

COMMAND:feridos(playerid, params[])
{
    new count = 0;
    new string[2048];
    new header[] = "ID\tPACIENTE\tTEMPO\n";
    
    string[0] = EOS;
    
    strcat(string, header);
    
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && gDeathData[i][isDead])
        {
            count++;
            
            new playerName[MAX_PLAYER_NAME];
            GetPlayerName(i, playerName, sizeof(playerName));
            
            new line[128];
            format(line, sizeof(line), "%d\t%s\t%ds\n", i, playerName, DeathTimeLeft[i]);
            strcat(string, line);
        }
    }
    
    if(count == 0)
    {
        SendClientMessage(playerid, 0xFF4500FF, "Falha: Nenhum jogador ferido no momento");
        return true;
    }
    
    Dialog_Show(playerid, dialogInjured, DIALOG_STYLE_TABLIST_HEADERS, "Jogadores Feridos:", string, "Localizar", "Cancelar");
    return true;
}

Dialog:dialogInjured(playerid, response, listitem, inputtext[])
{
    if(!response) return true;

    new selectedPlayerID = -1;
    new currentIndex = 0;
        
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && gDeathData[i][isDead])
        {
            if(currentIndex == listitem)
            {
                selectedPlayerID = i;
                break;
            }
            currentIndex++;
        }
    }
    
    if(selectedPlayerID == -1)
        SendClientMessage(playerid, 0xFF4500FF, "Falha: Jogador nao encontrado.");
    
    if(selectedPlayerID == playerid)
        SendClientMessage(playerid, 0xFF4500FF, "Falha: Voce nao pode se localizar para si mesmo.");
    
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(selectedPlayerID, playerName, sizeof(playerName));
    
    new Float:posX, Float:posY, Float:posZ;
    GetPlayerPos(selectedPlayerID, posX, posY, posZ);
    
    SetPlayerCheckpoint(playerid, posX, posY, posZ, 5.0);

    CheckpointActive[playerid] = true;
    LocatedPatient[playerid] = selectedPlayerID;
    
    new msg[128];
    format(msg, sizeof(msg), "Waze: Voce localizou %s (ID: %d). Um checkpoint foi marcado no mapa.", playerName, selectedPlayerID);
    SendClientMessage(playerid, 0x00FF00AA, msg);
    return true;
}