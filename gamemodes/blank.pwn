#include <a_samp>
#include <actor>
#include "includes/colours"

new actor, nearActor;

main(){}

public OnGameModeInit() {
    actor = CreateActor(0, 20.0, 20.0, 3.5, 0.0);
    nearActor = 0;
    return 1;
}

public OnPlayerConnect(playerid) {
    new string[13];
    format(string, sizeof(string), "actorid: %d", actor);
    SendClientMessage(playerid, COLOUR_WHITE, string);
    return 1;
}

public OnPlayerUpdate(playerid) {
    if (IsPlayerInRangeOfActor(playerid, actor)) {
        if (nearActor == 0) {
            nearActor = 1;
            SendClientMessage(playerid, COLOUR_WHITE, "You are near the actor.");
        }
    }
    else {
        nearActor = 0;
        SendClientMessage(playerid, COLOUR_RED, "You are no longer near the actor.");
    }
    return 1;
}
