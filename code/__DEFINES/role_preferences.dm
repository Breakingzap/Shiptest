

//Values for antag preferences, event roles, etc. unified here



//These are synced with the Database, if you change the values of the defines
//then you MUST update the database!
#define ROLE_SYNDICATE "Syndicate"
#define ROLE_TRAITOR "Traitor"
#define ROLE_OPERATIVE "Operative"
#define ROLE_CHANGELING "Changeling"
#define ROLE_WIZARD "Wizard"
#define ROLE_MALF "Malf AI"
#define ROLE_REV "Revolutionary"
#define ROLE_REV_HEAD "Head Revolutionary"
#define ROLE_REV_SUCCESSFUL "Victorious Revolutionary"
#define ROLE_ALIEN "Xenomorph"
#define ROLE_PAI "pAI"
#define ROLE_NINJA "Space Ninja"
#define ROLE_MONKEY "Monkey"
#define ROLE_ABDUCTOR "Abductor"
#define ROLE_REVENANT "Revenant"
#define ROLE_BROTHER "Blood Brother"
#define ROLE_BRAINWASHED "Brainwashed Victim"
#define ROLE_OVERTHROW "Syndicate Mutineer" //Role removed, left here for safety.
#define ROLE_HIVE "Hivemind Host" //Role removed, left here for safety.
#define ROLE_OBSESSED "Obsessed"
#define ROLE_SPACE_DRAGON "Space Dragon"
#define ROLE_SENTIENCE "Sentience Potion Spawn"
#define ROLE_PYROCLASTIC_SLIME "Pyroclastic Anomaly Slime"
#define ROLE_MIND_TRANSFER "Mind Transfer Potion"
#define ROLE_POSIBRAIN "Posibrain"
#define ROLE_DRONE "Drone"
#define ROLE_DEATHSQUAD "Deathsquad"
#define ROLE_LAVALAND "Lavaland"
#define ROLE_INTERNAL_AFFAIRS "Internal Affairs Agent"
#define ROLE_FAMILIES "Familes Antagonists"
#define ROLE_BORER "borer"
#define ROLE_FRONTIERSMEN "Frontiersmen"

//Missing assignment means it's not a gamemode specific role, IT'S NOT A BUG OR ERROR.
//The gamemode specific ones are just so the gamemodes can query whether a player is old enough
//(in game days played) to play that role
GLOBAL_LIST_INIT(special_roles, list(
	ROLE_PAI,
	ROLE_FRONTIERSMEN = /datum/antagonist/frontiersmen,
	ROLE_ALIEN,
	ROLE_SENTIENCE,
))

//Job defines for what happens when you fail to qualify for any job during job selection
#define BERANDOMJOB 1
#define RETURNTOLOBBY 2
