#include <a_samp>
#include <colours>
#include <keys>


// Callbacks
forward OnPlayerTargetActor(playerid, actorid);
forward OnPlayerTargetActorEnd(playerid, actorid);
forward OnActorTargetted(actorid, issuerid);
forward OnPlayerLookAtActor(playerid, actorid);
forward OnPlayerLookAtActorEnd(playerid, actorid);


public OnPlayerConnect(playerid) {
    EnablePlayerCameraTarget(playerid, 1);
	return 1;
}

public OnPlayerConnect(playerid) {
    #if defined MyLib_OnPlayerConnect
        return MyLib_OnPlayerConnect(playerid);
    #else
        return 1;
    #endif
}
#if defined _ALS_OnPlayerConnect
    #undef OnPlayerConnect
#else
    #define _ALS_OnPlayerConnect
#endif
#define OnPlayerConnect MyLib_OnPlayerConnect
#if defined MyLib_OnPlayerConnect
    forward MyLib_OnPlayerConnect(playerid);
#endif

public OnPlayerUpdate(playerid) {
    new targetActor = GetPlayerTargetActor(playerid);
    new targetedActor = player[playerid][aimingActor];

    if (targetActor != INVALID_ACTOR_ID) { // Aiming at an actor
        if (targetedActor != targetActor) { // Actor doesn't match previous value
            player[playerid][aimingActor] = targetActor;

            OnPlayerTargetActor(playerid, targetActor);
            OnActorTargetted(targetActor, playerid);
        }
        else { // Actor is the same as previously

        }
    }
    else { // Not aiming at an actor
        new targetedActor = player[playerid][aimingActor];

        if (targetedActor != -1) {
            player[playerid][aimingActor] = -1;

            OnPlayerTargetActorEnd(playerid, targetedActor);
        }
        else { // Now check if player is looking at an actor
            new lookingAtActor = GetPlayerCameraTargetActor(playerid);
			new lookedAtActor = player[playerid][lookingActor];

			if (lookingAtActor != INVALID_ACTOR_ID) { // Looking at an actor
			    if (lookedAtActor != lookingAtActor) { // Actor doesn't match previous value
				    player[playerid][lookingActor] = lookingAtActor;

					OnPlayerLookAtActor(playerid, lookingAtActor);
				}
				else { // Actor is the same as previously

				}
			}
			else { // Not looking at an actor
			    if (lookedAtActor != -1) {
				    player[playerid][lookingActor] = -1;

					OnPlayerLookAtActorEnd(playerid, lookingAtActor);
				}
			}
        }
    }
}


public OnPlayerTargetActor(playerid, actorid) {
    new string[30];
    format(string, sizeof(string), "You are aiming at actorid %d", actorid);
    SendClientMessage(playerid, COLOUR_WHITE, string);
    return 1;
}

public OnPlayerTargetActorEnd(playerid, actorid) {
    new string[40];
    format(string, sizeof(string), "You are no longer aiming at actorid %d", actorid);
    SendClientMessage(playerid, COLOUR_WHITE, string);
    return 1;
}

public OnActorTargetted(actorid, issuerid) {
    new string[64];
    format(string, sizeof(string), "Actorid %d is being targetted by %s(%d)", PlayerName(issuerid), issuerid);
    SendClientMessageToAll(COLOUR_WHITE, string);
    return 1;
}

public OnPlayerLookAtActor(playerid, actorid) {
    new string[31];
	format(string, sizeof(string), "You are looking at actorid %d", actorid);
	SendClientMessage(playerid, COLOUR_WHITE, string);
    return 1;
}

public OnPlayerLookAtActorEnd(playerid, actorid) {
    new string[41];
	format(string, sizeof(string), "You are no longer looking at actorid %d", actorid);
	SendClientMessage(playerid, COLOUR_WHITE, string);
    return 1;
}
