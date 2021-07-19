/*
*   REQUIRED INCLUDES FOR SERVER
*/

#include <a_samp>                   // SA-MP natives and callbacks
#include <a_mysql>                  // MySQL support
#include <bcrypt>
#include <zcmd>                     // Command creation
#include <sscanf2>                  // Parameter splitting
#include <foreach>                  // Optimized looping
#include <streamer>                 // Entity streamer

#include "includes/sac"             // SA-MP Anti-Cheat (SAC)
#include "includes/colours"         // Text and player colours


/*
*   SERVER DETAILS
*/

#define SERVER_NAME                 "Project Resurgence"
#define SERVER_SITE                 "www.sa-mp.com"
#define SERVER_VER                  "0.1"
#define SAMP_VER                    "0.3.7"

#define SQL_HOST                    "localhost"
#define SQL_USER                    "sampuser"
#define SQL_DB                      "samp"
#define SQL_PASS                    "r3surg3nc3"

#define MAX_DB_RECONNECT_ATTEMPTS   5
#define MAX_EMAIL_LENGTH            50
#define ACCOUNT_LOCK_TIME           21600 // In seconds - 6 hour security lock
#define NUM_SECURITY_QUESTIONS      5

#define BCRYPT_COST                 12
#define MAX_LOGIN_ATTEMPTS          3
#define START_MONEY                 100


/*
*   SECURITY QUESTIONS
*/

#define SECURITY_Q1                 "What is your mothers maiden name?"
#define SECURITY_Q2                 "What is the surname of your first manager?"
#define SECURITY_Q3                 "What is the make of your first car?"
#define SECURITY_Q4                 "What is your fathers middle name?"
#define SECURITY_Q5                 "What did you always want to be as a child?"


/*
*   ERROR CODES
*/

#define ERROR_CODE_NOCONNECTION     1
#define ERROR_CODE_LOSTCONNECTION   2
#define ERROR_CODE_NOSAVE           3
#define ERROR_CODE_NOSAVE_USERLOCK  4


/*
*   ADMIN LEVELS
*/

#define ADMIN_LEVEL_MOD             1
#define ADMIN_LEVEL_ADMIN           2
#define ADMIN_LEVEL_LEAD            3
#define ADMIN_LEVEL_OWNER           4

#define ADMIN_CMD_MUTE              1
#define ADMIN_CMD_UNMUTE            1
#define ADMIN_CMD_JAIL              1
#define ADMIN_CMD_UNJAIL            1
#define ADMIN_CMD_KICK              2
#define ADMIN_CMD_V                 3


/*
*   DIALOG DEFINITIONS
*/

#define DIALOG_REGISTER             1
#define DIALOG_LOGIN                2
#define DIALOG_PWRESET_START        3
#define DIALOG_PWRESET_OPTIONS      4
#define DIALOG_PWRESET_EMAIL        5
#define DIALOG_PWRESET_QUESTIONS    6
#define DIALOG_PWRESET_SUPPORT      7




/*
*   PLAYER CLASSES : USED DURING CLASS SELECTION
*/

#define CLASS_CIVILIAN              0
#define CLASS_POLICE                1


/*
*   TIME DISPLAY MODES
*/

#define TIME_DISPLAY_DEFAULT        0
#define TIME_DISPLAY_SHOW_AMPM      1


/*
*   WEATHER TYPES
*/

#define WEATHER_SUNNY               1
#define WEATHER_RAIN                8
#define WEATHER_FOG                 9
#define WEATHER_SANDSTORM           19
#define WEATHER_HEATWAVE            11
#define WEATHER_DULL                12
#define WEATHER_SMOG                20


/*
*   VEHICLE COMPONENTS
*/

#define COMPONENT_NOS_X2            1009
#define COMPONENT_NOS_X5            1008
#define COMPONENT_NOS_X10           1010
#define COMPONENT_STEREO            1086
#define COMPONENT_HYDRAULICS        1087


/*
*   MISC DEFINITIONS
*/

#define IsValidVehicleModel(%0)     ((%0 > 400) || (%0 < 611))
#define GetVehicleModelName(%0)     vehicleNames[%0 - 400]


/*
*   PLAYER CONFIGURATION : USED TO STORE ANYTHING RELATED TO THE PLAYER
*/

enum _playerConfig {
    connectionTime,
    lastLogin,
    lastSave,
    securityLock,
    bool:authenticated,
    loginAttempts,
    bcryptHash[BCRYPT_HASH_LENGTH],
    email,
    securityQ[NUM_SECURITY_QUESTIONS],
    lastQ,
    bool:spawned,
    bool:banned,
    timeFormat,
    inVehicleID,
    adminLevel,
    wantedLevel,
    money,
    money_bank,
    bool:inCombat,
    bool:handcuffed,
    jailTime,
    bool:inAdminJail,
    muteTime
}
new player[MAX_PLAYERS][_playerConfig];


/*
*   PLAYER SKILLS : USED DURING GAMEPLAY
*/

enum _playerSkills {

}
new skill[MAX_PLAYERS][_playerSkills];


/*
*   VEHICLE CONFIGURATION : USED TO STORE ANYTHING RELATED TO THE VEHICLE
*/

enum _vehicleConfig {
    bool:engine,
    bool:lights,
    bool:alarm,
    bool:doors,
    bool:hood,
    bool:trunk,
    bool:objective,
    bool:locked,
    neon[2]
}
new vehicle[MAX_VEHICLES][_vehicleConfig];

enum _vehicleComponents {
    nos,
    bool:stereo,
    bool:hydraulics,
    rims,
    frontBumper,
    rearBumper,
    sideskirt_left,
    sideskirt_right,
    roofVent,
    spoiler,
    exhaust,
    frontBullbars,
    rearBullbars,
    bullbar1,
    bullbar2,
    bullbar3
}
new vehicleComponent[MAX_VEHICLES][_vehicleComponents];


/*
*   CHECKPOINTS FOR BUILDING ENTER/EXITS
*/

enum _buildingCheckpoints {
    alhambra,
    ammunation[2],
    barberSalon[2],
    bigS,
    binco,
    burgerShot[2],
    cityHall,
    cluckinBell[3],
    didierSachs,
    emptyStore,
    gym,
    insideTrack,
    jimsStickyRing,
    lspd,
    mexicanRestaurant,
    prolaps,
    pigPen,
    roboi[2],
    sexShop[3],
    subUrban,
    tattooParlour[2],
    twentyFourSeven,
    victim,
    wellStackedPizza,
    xoomer[2],
    zip,
    exitCP[21]
}
new checkpoint[_buildingCheckpoints];


/*
*   SIDE MISSION VEHICLES
*/

enum _missionVehicles {
    ammunation[2]
}
new missionVehicle[_missionVehicles];


/*
*   TEXTDRAWS
*/

new Text:textdraw_time_default,
    Text:textdraw_time_ampm,
    Text:textdraw_ampm,
    PlayerText:textdraw_location[MAX_PLAYERS];


/*
*   MISC GLOBAL VARIABLES
*/

new clock[3];


/*
*   VEHICLE NAMES
*/

new vehicleNames[][] =
{
	"Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel", "Dumper", "Firetruck",
	"Trashmaster", "Stretch", "Manana", "Infernus", "Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan",
	"Moonbeam", "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BF Injection", "Hunter", "Premier",
	"Enforcer", "Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer", "Previon",
	"Coach", "Cabbie", "Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral", "Squalo",
	"Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed", "Yankee",
	"Caddy", "Solair", "Berkley's RC Van", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider",
	"Glendale", "Oceanic", "Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy", "Hermes", "Sabre",
	"Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage", "Dozer",
	"Maverick", "News Chopper", "Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking",
	"Blista Compact", "Police Maverick", "Boxville", "Benson", "Mesa", "RC Goblin", "Hotring Racer A",
	"Hotring Racer B", "Bloodring Banger", "Rancher", "Super GT", "Elegant", "Journey", "Bike", "Mountain Bike",
	"Beagle", "Cropduster", "Stunt Plane", "Tanker", "Roadtrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra",
	"FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck", "Fortune", "Cadrona", "FBI Truck", "Willard",
	"Forklift", "Tractor", "Combine", "Feltzer", "Remington", "Slamvan", "Blade", "Freight", "Streak", "Vortex",
	"Vincent", "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder", "Primo", "Cargobob", "Tampa",
	"Sunrise", "Merit", "Utility", "Nevada", "Yosemite", "Windsor", "Monster", "Monster", "Uranus", "Jester",
	"Sultan", "Stratium", "Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito", "Freight Flat",
	"Streak Carriage", "Go-Kart", "Lawnmower", "Dune", "Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley",
	"Stafford", "BF-400", "News Van", "Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club",
	"Freight Box", "Trailer", "Andromada", "Dodo", "RC Cam", "Launch", "Police Car (LS)", "Police Car (SF)",
	"Police Car (LV)", "Police Ranger", "Picador", "S.W.A.T. Tank", "Alpha", "Phoenix", "Glendale (damaged)",
	"Sadler (damaged)", "Luggage", "Luggage", "Stairs", "Boxville", "Tiller", "Utility Trailer"
};


/*
*   GPS LOCATION
*/

enum _locationConfig
{
	locName[28],
	Float:locArea[6]
}

static const locations[][_locationConfig] =
{
	{"The Big Ear",                 {-410.00,1403.30,-3.00,-137.90,1681.20,200.00}},
	{"Aldea Malvada",               {-1372.10,2498.50,0.00,-1277.50,2615.30,200.00}},
	{"Angel Pine",                  {-2324.90,-2584.20,-6.10,-1964.20,-2212.10,200.00}},
	{"Arco del Oeste",              {-901.10,2221.80,0.00,-592.00,2571.90,200.00}},
	{"Avispa Country Club",         {-2646.40,-355.40,0.00,-2270.00,-222.50,200.00}},
	{"Avispa Country Club",         {-2831.80,-430.20,-6.10,-2646.40,-222.50,200.00}},
	{"Avispa Country Club",         {-2361.50,-417.10,0.00,-2270.00,-355.40,200.00}},
	{"Avispa Country Club",         {-2667.80,-302.10,-28.80,-2646.40,-262.30,71.10}},
	{"Avispa Country Club",         {-2470.00,-355.40,0.00,-2270.00,-318.40,46.10}},
	{"Avispa Country Club",         {-2550.00,-355.40,0.00,-2470.00,-318.40,39.70}},
	{"Back o Beyond",               {-1166.90,-2641.10,0.00,-321.70,-1856.00,200.00}},
	{"Battery Point",               {-2741.00,1268.40,-4.50,-2533.00,1490.40,200.00}},
	{"Bayside",                     {-2741.00,2175.10,0.00,-2353.10,2722.70,200.00}},
	{"Bayside Marina",              {-2353.10,2275.70,0.00,-2153.10,2475.70,200.00}},
	{"Beacon Hill",                 {-399.60,-1075.50,-1.40,-319.00,-977.50,198.50}},
	{"Blackfield",                  {964.30,1203.20,-89.00,1197.30,1403.20,110.90}},
	{"Blackfield",                  {964.30,1403.20,-89.00,1197.30,1726.20,110.90}},
	{"Blackfield Chapel",           {1375.60,596.30,-89.00,1558.00,823.20,110.90}},
	{"Blackfield Chapel",           {1325.60,596.30,-89.00,1375.60,795.00,110.90}},
	{"Blackfield Intersection",     {1197.30,1044.60,-89.00,1277.00,1163.30,110.90}},
	{"Blackfield Intersection",     {1166.50,795.00,-89.00,1375.60,1044.60,110.90}},
	{"Blackfield Intersection",     {1277.00,1044.60,-89.00,1315.30,1087.60,110.90}},
	{"Blackfield Intersection",     {1375.60,823.20,-89.00,1457.30,919.40,110.90}},
	{"Blueberry",                   {104.50,-220.10,2.30,349.60,152.20,200.00}},
	{"Blueberry",                   {19.60,-404.10,3.80,349.60,-220.10,200.00}},
	{"Blueberry Acres",             {-319.60,-220.10,0.00,104.50,293.30,200.00}},
	{"Caligula's Palace",           {2087.30,1543.20,-89.00,2437.30,1703.20,110.90}},
	{"Caligula's Palace",           {2137.40,1703.20,-89.00,2437.30,1783.20,110.90}},
	{"Calton Heights",              {-2274.10,744.10,-6.10,-1982.30,1358.90,200.00}},
	{"Chinatown",                   {-2274.10,578.30,-7.60,-2078.60,744.10,200.00}},
	{"City Hall",                   {-2867.80,277.40,-9.10,-2593.40,458.40,200.00}},
	{"Come-A-Lot",                  {2087.30,943.20,-89.00,2623.10,1203.20,110.90}},
	{"Commerce",                    {1323.90,-1842.20,-89.00,1701.90,-1722.20,110.90}},
	{"Commerce",                    {1323.90,-1722.20,-89.00,1440.90,-1577.50,110.90}},
	{"Commerce",                    {1370.80,-1577.50,-89.00,1463.90,-1384.90,110.90}},
	{"Commerce",                    {1463.90,-1577.50,-89.00,1667.90,-1430.80,110.90}},
	{"Commerce",                    {1583.50,-1722.20,-89.00,1758.90,-1577.50,110.90}},
	{"Commerce",                    {1667.90,-1577.50,-89.00,1812.60,-1430.80,110.90}},
	{"Conference Center",           {1046.10,-1804.20,-89.00,1323.90,-1722.20,110.90}},
	{"Conference Center",           {1073.20,-1842.20,-89.00,1323.90,-1804.20,110.90}},
	{"Cranberry Station",           {-2007.80,56.30,0.00,-1922.00,224.70,100.00}},
	{"Creek",                       {2749.90,1937.20,-89.00,2921.60,2669.70,110.90}},
	{"Dillimore",                   {580.70,-674.80,-9.50,861.00,-404.70,200.00}},
	{"Doherty",                     {-2270.00,-324.10,-0.00,-1794.90,-222.50,200.00}},
	{"Doherty",                     {-2173.00,-222.50,-0.00,-1794.90,265.20,200.00}},
	{"Downtown",                    {-1982.30,744.10,-6.10,-1871.70,1274.20,200.00}},
	{"Downtown",                    {-1871.70,1176.40,-4.50,-1620.30,1274.20,200.00}},
	{"Downtown",                    {-1700.00,744.20,-6.10,-1580.00,1176.50,200.00}},
	{"Downtown",                    {-1580.00,744.20,-6.10,-1499.80,1025.90,200.00}},
	{"Downtown",                    {-2078.60,578.30,-7.60,-1499.80,744.20,200.00}},
	{"Downtown",                    {-1993.20,265.20,-9.10,-1794.90,578.30,200.00}},
	{"Downtown Los Santos",         {1463.90,-1430.80,-89.00,1724.70,-1290.80,110.90}},
	{"Downtown Los Santos",         {1724.70,-1430.80,-89.00,1812.60,-1250.90,110.90}},
	{"Downtown Los Santos",         {1463.90,-1290.80,-89.00,1724.70,-1150.80,110.90}},
	{"Downtown Los Santos",         {1370.80,-1384.90,-89.00,1463.90,-1170.80,110.90}},
	{"Downtown Los Santos",         {1724.70,-1250.90,-89.00,1812.60,-1150.80,110.90}},
	{"Downtown Los Santos",         {1370.80,-1170.80,-89.00,1463.90,-1130.80,110.90}},
	{"Downtown Los Santos",         {1378.30,-1130.80,-89.00,1463.90,-1026.30,110.90}},
	{"Downtown Los Santos",         {1391.00,-1026.30,-89.00,1463.90,-926.90,110.90}},
	{"Downtown Los Santos",         {1507.50,-1385.20,110.90,1582.50,-1325.30,335.90}},
	{"East Beach",                  {2632.80,-1852.80,-89.00,2959.30,-1668.10,110.90}},
	{"East Beach",                  {2632.80,-1668.10,-89.00,2747.70,-1393.40,110.90}},
	{"East Beach",                  {2747.70,-1668.10,-89.00,2959.30,-1498.60,110.90}},
	{"East Beach",                  {2747.70,-1498.60,-89.00,2959.30,-1120.00,110.90}},
	{"East Los Santos",             {2421.00,-1628.50,-89.00,2632.80,-1454.30,110.90}},
	{"East Los Santos",             {2222.50,-1628.50,-89.00,2421.00,-1494.00,110.90}},
	{"East Los Santos",             {2266.20,-1494.00,-89.00,2381.60,-1372.00,110.90}},
	{"East Los Santos",             {2381.60,-1494.00,-89.00,2421.00,-1454.30,110.90}},
	{"East Los Santos",             {2281.40,-1372.00,-89.00,2381.60,-1135.00,110.90}},
	{"East Los Santos",             {2381.60,-1454.30,-89.00,2462.10,-1135.00,110.90}},
	{"East Los Santos",             {2462.10,-1454.30,-89.00,2581.70,-1135.00,110.90}},
	{"Easter Basin",                {-1794.90,249.90,-9.10,-1242.90,578.30,200.00}},
	{"Easter Basin",                {-1794.90,-50.00,-0.00,-1499.80,249.90,200.00}},
	{"Easter Bay Airport",          {-1499.80,-50.00,-0.00,-1242.90,249.90,200.00}},
	{"Easter Bay Airport",          {-1794.90,-730.10,-3.00,-1213.90,-50.00,200.00}},
	{"Easter Bay Airport",          {-1213.90,-730.10,0.00,-1132.80,-50.00,200.00}},
	{"Easter Bay Airport",          {-1242.90,-50.00,0.00,-1213.90,578.30,200.00}},
	{"Easter Bay Airport",          {-1213.90,-50.00,-4.50,-947.90,578.30,200.00}},
	{"Easter Bay Airport",          {-1315.40,-405.30,15.40,-1264.40,-209.50,25.40}},
	{"Easter Bay Airport",          {-1354.30,-287.30,15.40,-1315.40,-209.50,25.40}},
	{"Easter Bay Airport",          {-1490.30,-209.50,15.40,-1264.40,-148.30,25.40}},
	{"Easter Bay Chemicals",        {-1132.80,-768.00,0.00,-956.40,-578.10,200.00}},
	{"Easter Bay Chemicals",        {-1132.80,-787.30,0.00,-956.40,-768.00,200.00}},
	{"El Castillo del Diablo",      {-464.50,2217.60,0.00,-208.50,2580.30,200.00}},
	{"El Castillo del Diablo",      {-208.50,2123.00,-7.60,114.00,2337.10,200.00}},
	{"El Castillo del Diablo",      {-208.50,2337.10,0.00,8.40,2487.10,200.00}},
	{"El Corona",                   {1812.60,-2179.20,-89.00,1970.60,-1852.80,110.90}},
	{"El Corona",                   {1692.60,-2179.20,-89.00,1812.60,-1842.20,110.90}},
	{"El Quebrados",                {-1645.20,2498.50,0.00,-1372.10,2777.80,200.00}},
	{"Esplanade East",              {-1620.30,1176.50,-4.50,-1580.00,1274.20,200.00}},
	{"Esplanade East",              {-1580.00,1025.90,-6.10,-1499.80,1274.20,200.00}},
	{"Esplanade East",              {-1499.80,578.30,-79.60,-1339.80,1274.20,20.30}},
	{"Esplanade North",             {-2533.00,1358.90,-4.50,-1996.60,1501.20,200.00}},
	{"Esplanade North",             {-1996.60,1358.90,-4.50,-1524.20,1592.50,200.00}},
	{"Esplanade North",             {-1982.30,1274.20,-4.50,-1524.20,1358.90,200.00}},
	{"Fallen Tree",                 {-792.20,-698.50,-5.30,-452.40,-380.00,200.00}},
	{"Fallow Bridge",               {434.30,366.50,0.00,603.00,555.60,200.00}},
	{"Fern Ridge",                  {508.10,-139.20,0.00,1306.60,119.50,200.00}},
	{"Financial",                   {-1871.70,744.10,-6.10,-1701.30,1176.40,300.00}},
	{"Fisher's Lagoon",             {1916.90,-233.30,-100.00,2131.70,13.80,200.00}},
	{"Flint Intersection",          {-187.70,-1596.70,-89.00,17.00,-1276.60,110.90}},
	{"Flint Range",                 {-594.10,-1648.50,0.00,-187.70,-1276.60,200.00}},
	{"Fort Carson",                 {-376.20,826.30,-3.00,123.70,1220.40,200.00}},
	{"Foster Valley",               {-2270.00,-430.20,-0.00,-2178.60,-324.10,200.00}},
	{"Foster Valley",               {-2178.60,-599.80,-0.00,-1794.90,-324.10,200.00}},
	{"Foster Valley",               {-2178.60,-1115.50,0.00,-1794.90,-599.80,200.00}},
	{"Foster Valley",               {-2178.60,-1250.90,0.00,-1794.90,-1115.50,200.00}},
	{"Frederick Bridge",            {2759.20,296.50,0.00,2774.20,594.70,200.00}},
	{"Gant Bridge",                 {-2741.40,1659.60,-6.10,-2616.40,2175.10,200.00}},
	{"Gant Bridge",                 {-2741.00,1490.40,-6.10,-2616.40,1659.60,200.00}},
	{"Ganton",                      {2222.50,-1852.80,-89.00,2632.80,-1722.30,110.90}},
	{"Ganton",                      {2222.50,-1722.30,-89.00,2632.80,-1628.50,110.90}},
	{"Garcia",                      {-2411.20,-222.50,-0.00,-2173.00,265.20,200.00}},
	{"Garcia",                      {-2395.10,-222.50,-5.30,-2354.00,-204.70,200.00}},
	{"Garver Bridge",               {-1339.80,828.10,-89.00,-1213.90,1057.00,110.90}},
	{"Garver Bridge",               {-1213.90,950.00,-89.00,-1087.90,1178.90,110.90}},
	{"Garver Bridge",               {-1499.80,696.40,-179.60,-1339.80,925.30,20.30}},
	{"Glen Park",                   {1812.60,-1449.60,-89.00,1996.90,-1350.70,110.90}},
	{"Glen Park",                   {1812.60,-1100.80,-89.00,1994.30,-973.30,110.90}},
	{"Glen Park",                   {1812.60,-1350.70,-89.00,2056.80,-1100.80,110.90}},
	{"Green Palms",                 {176.50,1305.40,-3.00,338.60,1520.70,200.00}},
	{"Greenglass College",          {964.30,1044.60,-89.00,1197.30,1203.20,110.90}},
	{"Greenglass College",          {964.30,930.80,-89.00,1166.50,1044.60,110.90}},
	{"Hampton Barns",               {603.00,264.30,0.00,761.90,366.50,200.00}},
	{"Hankypanky Point",            {2576.90,62.10,0.00,2759.20,385.50,200.00}},
	{"Harry Gold Parkway",          {1777.30,863.20,-89.00,1817.30,2342.80,110.90}},
	{"Hashbury",                    {-2593.40,-222.50,-0.00,-2411.20,54.70,200.00}},
	{"Hilltop Farm",                {967.30,-450.30,-3.00,1176.70,-217.90,200.00}},
	{"Hunter Quarry",               {337.20,710.80,-115.20,860.50,1031.70,203.70}},
	{"Idlewood",                    {1812.60,-1852.80,-89.00,1971.60,-1742.30,110.90}},
	{"Idlewood",                    {1812.60,-1742.30,-89.00,1951.60,-1602.30,110.90}},
	{"Idlewood",                    {1951.60,-1742.30,-89.00,2124.60,-1602.30,110.90}},
	{"Idlewood",                    {1812.60,-1602.30,-89.00,2124.60,-1449.60,110.90}},
	{"Idlewood",                    {2124.60,-1742.30,-89.00,2222.50,-1494.00,110.90}},
	{"Idlewood",                    {1971.60,-1852.80,-89.00,2222.50,-1742.30,110.90}},
	{"Jefferson",                   {1996.90,-1449.60,-89.00,2056.80,-1350.70,110.90}},
	{"Jefferson",                   {2124.60,-1494.00,-89.00,2266.20,-1449.60,110.90}},
	{"Jefferson",                   {2056.80,-1372.00,-89.00,2281.40,-1210.70,110.90}},
	{"Jefferson",                   {2056.80,-1210.70,-89.00,2185.30,-1126.30,110.90}},
	{"Jefferson",                   {2185.30,-1210.70,-89.00,2281.40,-1154.50,110.90}},
	{"Jefferson",                   {2056.80,-1449.60,-89.00,2266.20,-1372.00,110.90}},
	{"Julius Thruway East",         {2623.10,943.20,-89.00,2749.90,1055.90,110.90}},
	{"Julius Thruway East",         {2685.10,1055.90,-89.00,2749.90,2626.50,110.90}},
	{"Julius Thruway East",         {2536.40,2442.50,-89.00,2685.10,2542.50,110.90}},
	{"Julius Thruway East",         {2625.10,2202.70,-89.00,2685.10,2442.50,110.90}},
	{"Julius Thruway North",        {2498.20,2542.50,-89.00,2685.10,2626.50,110.90}},
	{"Julius Thruway North",        {2237.40,2542.50,-89.00,2498.20,2663.10,110.90}},
	{"Julius Thruway North",        {2121.40,2508.20,-89.00,2237.40,2663.10,110.90}},
	{"Julius Thruway North",        {1938.80,2508.20,-89.00,2121.40,2624.20,110.90}},
	{"Julius Thruway North",        {1534.50,2433.20,-89.00,1848.40,2583.20,110.90}},
	{"Julius Thruway North",        {1848.40,2478.40,-89.00,1938.80,2553.40,110.90}},
	{"Julius Thruway North",        {1704.50,2342.80,-89.00,1848.40,2433.20,110.90}},
	{"Julius Thruway North",        {1377.30,2433.20,-89.00,1534.50,2507.20,110.90}},
	{"Julius Thruway South",        {1457.30,823.20,-89.00,2377.30,863.20,110.90}},
	{"Julius Thruway South",        {2377.30,788.80,-89.00,2537.30,897.90,110.90}},
	{"Julius Thruway West",         {1197.30,1163.30,-89.00,1236.60,2243.20,110.90}},
	{"Julius Thruway West",         {1236.60,2142.80,-89.00,1297.40,2243.20,110.90}},
	{"Juniper Hill",                {-2533.00,578.30,-7.60,-2274.10,968.30,200.00}},
	{"Juniper Hollow",              {-2533.00,968.30,-6.10,-2274.10,1358.90,200.00}},
	{"K.A.C.C. Military Fuels",     {2498.20,2626.50,-89.00,2749.90,2861.50,110.90}},
	{"Kincaid Bridge",              {-1339.80,599.20,-89.00,-1213.90,828.10,110.90}},
	{"Kincaid Bridge",              {-1213.90,721.10,-89.00,-1087.90,950.00,110.90}},
	{"Kincaid Bridge",              {-1087.90,855.30,-89.00,-961.90,986.20,110.90}},
	{"King's",                      {-2329.30,458.40,-7.60,-1993.20,578.30,200.00}},
	{"King's",                      {-2411.20,265.20,-9.10,-1993.20,373.50,200.00}},
	{"King's",                      {-2253.50,373.50,-9.10,-1993.20,458.40,200.00}},
	{"LVA Freight Depot",           {1457.30,863.20,-89.00,1777.40,1143.20,110.90}},
	{"LVA Freight Depot",           {1375.60,919.40,-89.00,1457.30,1203.20,110.90}},
	{"LVA Freight Depot",           {1277.00,1087.60,-89.00,1375.60,1203.20,110.90}},
	{"LVA Freight Depot",           {1315.30,1044.60,-89.00,1375.60,1087.60,110.90}},
	{"LVA Freight Depot",           {1236.60,1163.40,-89.00,1277.00,1203.20,110.90}},
	{"Las Barrancas",               {-926.10,1398.70,-3.00,-719.20,1634.60,200.00}},
	{"Las Brujas",                  {-365.10,2123.00,-3.00,-208.50,2217.60,200.00}},
	{"Las Colinas",                 {1994.30,-1100.80,-89.00,2056.80,-920.80,110.90}},
	{"Las Colinas",                 {2056.80,-1126.30,-89.00,2126.80,-920.80,110.90}},
	{"Las Colinas",                 {2185.30,-1154.50,-89.00,2281.40,-934.40,110.90}},
	{"Las Colinas",                 {2126.80,-1126.30,-89.00,2185.30,-934.40,110.90}},
	{"Las Colinas",                 {2747.70,-1120.00,-89.00,2959.30,-945.00,110.90}},
	{"Las Colinas",                 {2632.70,-1135.00,-89.00,2747.70,-945.00,110.90}},
	{"Las Colinas",                 {2281.40,-1135.00,-89.00,2632.70,-945.00,110.90}},
	{"Las Payasadas",               {-354.30,2580.30,2.00,-133.60,2816.80,200.00}},
	{"Las Venturas Airport",        {1236.60,1203.20,-89.00,1457.30,1883.10,110.90}},
	{"Las Venturas Airport",        {1457.30,1203.20,-89.00,1777.30,1883.10,110.90}},
	{"Las Venturas Airport",        {1457.30,1143.20,-89.00,1777.40,1203.20,110.90}},
	{"Las Venturas Airport",        {1515.80,1586.40,-12.50,1729.90,1714.50,87.50}},
	{"Last Dime Motel",             {1823.00,596.30,-89.00,1997.20,823.20,110.90}},
	{"Leafy Hollow",                {-1166.90,-1856.00,0.00,-815.60,-1602.00,200.00}},
	{"Liberty City",                {-1000.00,400.00,1300.00,-700.00,600.00,1400.00}},
	{"Lil' Probe Inn",              {-90.20,1286.80,-3.00,153.80,1554.10,200.00}},
	{"Linden Side",                 {2749.90,943.20,-89.00,2923.30,1198.90,110.90}},
	{"Linden Station",              {2749.90,1198.90,-89.00,2923.30,1548.90,110.90}},
	{"Linden Station",              {2811.20,1229.50,-39.50,2861.20,1407.50,60.40}},
	{"Little Mexico",               {1701.90,-1842.20,-89.00,1812.60,-1722.20,110.90}},
	{"Little Mexico",               {1758.90,-1722.20,-89.00,1812.60,-1577.50,110.90}},
	{"Los Flores",                  {2581.70,-1454.30,-89.00,2632.80,-1393.40,110.90}},
	{"Los Flores",                  {2581.70,-1393.40,-89.00,2747.70,-1135.00,110.90}},
	{"Los Santos International",    {1249.60,-2394.30,-89.00,1852.00,-2179.20,110.90}},
	{"Los Santos International",    {1852.00,-2394.30,-89.00,2089.00,-2179.20,110.90}},
	{"Los Santos International",    {1382.70,-2730.80,-89.00,2201.80,-2394.30,110.90}},
	{"Los Santos International",    {1974.60,-2394.30,-39.00,2089.00,-2256.50,60.90}},
	{"Los Santos International",    {1400.90,-2669.20,-39.00,2189.80,-2597.20,60.90}},
	{"Los Santos International",    {2051.60,-2597.20,-39.00,2152.40,-2394.30,60.90}},
	{"Marina",                      {647.70,-1804.20,-89.00,851.40,-1577.50,110.90}},
	{"Marina",                      {647.70,-1577.50,-89.00,807.90,-1416.20,110.90}},
	{"Marina",                      {807.90,-1577.50,-89.00,926.90,-1416.20,110.90}},
	{"Market",                      {787.40,-1416.20,-89.00,1072.60,-1310.20,110.90}},
	{"Market",                      {952.60,-1310.20,-89.00,1072.60,-1130.80,110.90}},
	{"Market",                      {1072.60,-1416.20,-89.00,1370.80,-1130.80,110.90}},
	{"Market",                      {926.90,-1577.50,-89.00,1370.80,-1416.20,110.90}},
	{"Market Station",              {787.40,-1410.90,-34.10,866.00,-1310.20,65.80}},
	{"Martin Bridge",               {-222.10,293.30,0.00,-122.10,476.40,200.00}},
	{"Missionary Hill",             {-2994.40,-811.20,0.00,-2178.60,-430.20,200.00}},
	{"Montgomery",                  {1119.50,119.50,-3.00,1451.40,493.30,200.00}},
	{"Montgomery",                  {1451.40,347.40,-6.10,1582.40,420.80,200.00}},
	{"Montgomery Intersection",     {1546.60,208.10,0.00,1745.80,347.40,200.00}},
	{"Montgomery Intersection",     {1582.40,347.40,0.00,1664.60,401.70,200.00}},
	{"Mulholland",                  {1414.00,-768.00,-89.00,1667.60,-452.40,110.90}},
	{"Mulholland",                  {1281.10,-452.40,-89.00,1641.10,-290.90,110.90}},
	{"Mulholland",                  {1269.10,-768.00,-89.00,1414.00,-452.40,110.90}},
	{"Mulholland",                  {1357.00,-926.90,-89.00,1463.90,-768.00,110.90}},
	{"Mulholland",                  {1318.10,-910.10,-89.00,1357.00,-768.00,110.90}},
	{"Mulholland",                  {1169.10,-910.10,-89.00,1318.10,-768.00,110.90}},
	{"Mulholland",                  {768.60,-954.60,-89.00,952.60,-860.60,110.90}},
	{"Mulholland",                  {687.80,-860.60,-89.00,911.80,-768.00,110.90}},
	{"Mulholland",                  {737.50,-768.00,-89.00,1142.20,-674.80,110.90}},
	{"Mulholland",                  {1096.40,-910.10,-89.00,1169.10,-768.00,110.90}},
	{"Mulholland",                  {952.60,-937.10,-89.00,1096.40,-860.60,110.90}},
	{"Mulholland",                  {911.80,-860.60,-89.00,1096.40,-768.00,110.90}},
	{"Mulholland",                  {861.00,-674.80,-89.00,1156.50,-600.80,110.90}},
	{"Mulholland Intersection",     {1463.90,-1150.80,-89.00,1812.60,-768.00,110.90}},
	{"North Rock",                  {2285.30,-768.00,0.00,2770.50,-269.70,200.00}},
	{"Ocean Docks",                 {2373.70,-2697.00,-89.00,2809.20,-2330.40,110.90}},
	{"Ocean Docks",                 {2201.80,-2418.30,-89.00,2324.00,-2095.00,110.90}},
	{"Ocean Docks",                 {2324.00,-2302.30,-89.00,2703.50,-2145.10,110.90}},
	{"Ocean Docks",                 {2089.00,-2394.30,-89.00,2201.80,-2235.80,110.90}},
	{"Ocean Docks",                 {2201.80,-2730.80,-89.00,2324.00,-2418.30,110.90}},
	{"Ocean Docks",                 {2703.50,-2302.30,-89.00,2959.30,-2126.90,110.90}},
	{"Ocean Docks",                 {2324.00,-2145.10,-89.00,2703.50,-2059.20,110.90}},
	{"Ocean Flats",                 {-2994.40,277.40,-9.10,-2867.80,458.40,200.00}},
	{"Ocean Flats",                 {-2994.40,-222.50,-0.00,-2593.40,277.40,200.00}},
	{"Ocean Flats",                 {-2994.40,-430.20,-0.00,-2831.80,-222.50,200.00}},
	{"Octane Springs",              {338.60,1228.50,0.00,664.30,1655.00,200.00}},
	{"Old Venturas Strip",          {2162.30,2012.10,-89.00,2685.10,2202.70,110.90}},
	{"Palisades",                   {-2994.40,458.40,-6.10,-2741.00,1339.60,200.00}},
	{"Palomino Creek",              {2160.20,-149.00,0.00,2576.90,228.30,200.00}},
	{"Paradiso",                    {-2741.00,793.40,-6.10,-2533.00,1268.40,200.00}},
	{"Pershing Square",             {1440.90,-1722.20,-89.00,1583.50,-1577.50,110.90}},
	{"Pilgrim",                     {2437.30,1383.20,-89.00,2624.40,1783.20,110.90}},
	{"Pilgrim",                     {2624.40,1383.20,-89.00,2685.10,1783.20,110.90}},
	{"Pilson Intersection",         {1098.30,2243.20,-89.00,1377.30,2507.20,110.90}},
	{"Pirates in Men's Pants",      {1817.30,1469.20,-89.00,2027.40,1703.20,110.90}},
	{"Playa del Seville",           {2703.50,-2126.90,-89.00,2959.30,-1852.80,110.90}},
	{"Prickle Pine",                {1534.50,2583.20,-89.00,1848.40,2863.20,110.90}},
	{"Prickle Pine",                {1117.40,2507.20,-89.00,1534.50,2723.20,110.90}},
	{"Prickle Pine",                {1848.40,2553.40,-89.00,1938.80,2863.20,110.90}},
	{"Prickle Pine",                {1938.80,2624.20,-89.00,2121.40,2861.50,110.90}},
	{"Queens",                      {-2533.00,458.40,0.00,-2329.30,578.30,200.00}},
	{"Queens",                      {-2593.40,54.70,0.00,-2411.20,458.40,200.00}},
	{"Queens",                      {-2411.20,373.50,0.00,-2253.50,458.40,200.00}},
	{"Randolph Industrial",         {1558.00,596.30,-89.00,1823.00,823.20,110.90}},
	{"Redsands East",               {1817.30,2011.80,-89.00,2106.70,2202.70,110.90}},
	{"Redsands East",               {1817.30,2202.70,-89.00,2011.90,2342.80,110.90}},
	{"Redsands East",               {1848.40,2342.80,-89.00,2011.90,2478.40,110.90}},
	{"Redsands West",               {1236.60,1883.10,-89.00,1777.30,2142.80,110.90}},
	{"Redsands West",               {1297.40,2142.80,-89.00,1777.30,2243.20,110.90}},
	{"Redsands West",               {1377.30,2243.20,-89.00,1704.50,2433.20,110.90}},
	{"Redsands West",               {1704.50,2243.20,-89.00,1777.30,2342.80,110.90}},
	{"Regular Tom",                 {-405.70,1712.80,-3.00,-276.70,1892.70,200.00}},
	{"Richman",                     {647.50,-1118.20,-89.00,787.40,-954.60,110.90}},
	{"Richman",                     {647.50,-954.60,-89.00,768.60,-860.60,110.90}},
	{"Richman",                     {225.10,-1369.60,-89.00,334.50,-1292.00,110.90}},
	{"Richman",                     {225.10,-1292.00,-89.00,466.20,-1235.00,110.90}},
	{"Richman",                     {72.60,-1404.90,-89.00,225.10,-1235.00,110.90}},
	{"Richman",                     {72.60,-1235.00,-89.00,321.30,-1008.10,110.90}},
	{"Richman",                     {321.30,-1235.00,-89.00,647.50,-1044.00,110.90}},
	{"Richman",                     {321.30,-1044.00,-89.00,647.50,-860.60,110.90}},
	{"Richman",                     {321.30,-860.60,-89.00,687.80,-768.00,110.90}},
	{"Richman",                     {321.30,-768.00,-89.00,700.70,-674.80,110.90}},
	{"Robada Intersection",         {-1119.00,1178.90,-89.00,-862.00,1351.40,110.90}},
	{"Roca Escalante",              {2237.40,2202.70,-89.00,2536.40,2542.50,110.90}},
	{"Roca Escalante",              {2536.40,2202.70,-89.00,2625.10,2442.50,110.90}},
	{"Rockshore East",              {2537.30,676.50,-89.00,2902.30,943.20,110.90}},
	{"Rockshore West",              {1997.20,596.30,-89.00,2377.30,823.20,110.90}},
	{"Rockshore West",              {2377.30,596.30,-89.00,2537.30,788.80,110.90}},
	{"Rodeo",                       {72.60,-1684.60,-89.00,225.10,-1544.10,110.90}},
	{"Rodeo",                       {72.60,-1544.10,-89.00,225.10,-1404.90,110.90}},
	{"Rodeo",                       {225.10,-1684.60,-89.00,312.80,-1501.90,110.90}},
	{"Rodeo",                       {225.10,-1501.90,-89.00,334.50,-1369.60,110.90}},
	{"Rodeo",                       {334.50,-1501.90,-89.00,422.60,-1406.00,110.90}},
	{"Rodeo",                       {312.80,-1684.60,-89.00,422.60,-1501.90,110.90}},
	{"Rodeo",                       {422.60,-1684.60,-89.00,558.00,-1570.20,110.90}},
	{"Rodeo",                       {558.00,-1684.60,-89.00,647.50,-1384.90,110.90}},
	{"Rodeo",                       {466.20,-1570.20,-89.00,558.00,-1385.00,110.90}},
	{"Rodeo",                       {422.60,-1570.20,-89.00,466.20,-1406.00,110.90}},
	{"Rodeo",                       {466.20,-1385.00,-89.00,647.50,-1235.00,110.90}},
	{"Rodeo",                       {334.50,-1406.00,-89.00,466.20,-1292.00,110.90}},
	{"Royal Casino",                {2087.30,1383.20,-89.00,2437.30,1543.20,110.90}},
	{"San Andreas Sound",           {2450.30,385.50,-100.00,2759.20,562.30,200.00}},
	{"Santa Flora",                 {-2741.00,458.40,-7.60,-2533.00,793.40,200.00}},
	{"Santa Maria Beach",           {342.60,-2173.20,-89.00,647.70,-1684.60,110.90}},
	{"Santa Maria Beach",           {72.60,-2173.20,-89.00,342.60,-1684.60,110.90}},
	{"Shady Cabin",                 {-1632.80,-2263.40,-3.00,-1601.30,-2231.70,200.00}},
	{"Shady Creeks",                {-1820.60,-2643.60,-8.00,-1226.70,-1771.60,200.00}},
	{"Shady Creeks",                {-2030.10,-2174.80,-6.10,-1820.60,-1771.60,200.00}},
	{"Sobell Rail Yards",           {2749.90,1548.90,-89.00,2923.30,1937.20,110.90}},
	{"Spinybed",                    {2121.40,2663.10,-89.00,2498.20,2861.50,110.90}},
	{"Starfish Casino",             {2437.30,1783.20,-89.00,2685.10,2012.10,110.90}},
	{"Starfish Casino",             {2437.30,1858.10,-39.00,2495.00,1970.80,60.90}},
	{"Starfish Casino",             {2162.30,1883.20,-89.00,2437.30,2012.10,110.90}},
	{"Temple",                      {1252.30,-1130.80,-89.00,1378.30,-1026.30,110.90}},
	{"Temple",                      {1252.30,-1026.30,-89.00,1391.00,-926.90,110.90}},
	{"Temple",                      {1252.30,-926.90,-89.00,1357.00,-910.10,110.90}},
	{"Temple",                      {952.60,-1130.80,-89.00,1096.40,-937.10,110.90}},
	{"Temple",                      {1096.40,-1130.80,-89.00,1252.30,-1026.30,110.90}},
	{"Temple",                      {1096.40,-1026.30,-89.00,1252.30,-910.10,110.90}},
	{"The Camel's Toe",             {2087.30,1203.20,-89.00,2640.40,1383.20,110.90}},
	{"The Clown's Pocket",          {2162.30,1783.20,-89.00,2437.30,1883.20,110.90}},
	{"The Emerald Isle",            {2011.90,2202.70,-89.00,2237.40,2508.20,110.90}},
	{"The Farm",                    {-1209.60,-1317.10,114.90,-908.10,-787.30,251.90}},
	{"Four Dragons Casino",         {1817.30,863.20,-89.00,2027.30,1083.20,110.90}},
	{"The High Roller",             {1817.30,1283.20,-89.00,2027.30,1469.20,110.90}},
	{"The Mako Span",               {1664.60,401.70,0.00,1785.10,567.20,200.00}},
	{"The Panopticon",              {-947.90,-304.30,-1.10,-319.60,327.00,200.00}},
	{"The Pink Swan",               {1817.30,1083.20,-89.00,2027.30,1283.20,110.90}},
	{"The Sherman Dam",             {-968.70,1929.40,-3.00,-481.10,2155.20,200.00}},
	{"The Strip",                   {2027.40,863.20,-89.00,2087.30,1703.20,110.90}},
	{"The Strip",                   {2106.70,1863.20,-89.00,2162.30,2202.70,110.90}},
	{"The Strip",                   {2027.40,1783.20,-89.00,2162.30,1863.20,110.90}},
	{"The Strip",                   {2027.40,1703.20,-89.00,2137.40,1783.20,110.90}},
	{"The Visage",                  {1817.30,1863.20,-89.00,2106.70,2011.80,110.90}},
	{"The Visage",                  {1817.30,1703.20,-89.00,2027.40,1863.20,110.90}},
	{"Unity Station",               {1692.60,-1971.80,-20.40,1812.60,-1932.80,79.50}},
	{"Valle Ocultado",              {-936.60,2611.40,2.00,-715.90,2847.90,200.00}},
	{"Verdant Bluffs",              {930.20,-2488.40,-89.00,1249.60,-2006.70,110.90}},
	{"Verdant Bluffs",              {1073.20,-2006.70,-89.00,1249.60,-1842.20,110.90}},
	{"Verdant Bluffs",              {1249.60,-2179.20,-89.00,1692.60,-1842.20,110.90}},
	{"Verdant Meadows",             {37.00,2337.10,-3.00,435.90,2677.90,200.00}},
	{"Verona Beach",                {647.70,-2173.20,-89.00,930.20,-1804.20,110.90}},
	{"Verona Beach",                {930.20,-2006.70,-89.00,1073.20,-1804.20,110.90}},
	{"Verona Beach",                {851.40,-1804.20,-89.00,1046.10,-1577.50,110.90}},
	{"Verona Beach",                {1161.50,-1722.20,-89.00,1323.90,-1577.50,110.90}},
	{"Verona Beach",                {1046.10,-1722.20,-89.00,1161.50,-1577.50,110.90}},
	{"Vinewood",                    {787.40,-1310.20,-89.00,952.60,-1130.80,110.90}},
	{"Vinewood",                    {787.40,-1130.80,-89.00,952.60,-954.60,110.90}},
	{"Vinewood",                    {647.50,-1227.20,-89.00,787.40,-1118.20,110.90}},
	{"Vinewood",                    {647.70,-1416.20,-89.00,787.40,-1227.20,110.90}},
	{"Whitewood Estates",           {883.30,1726.20,-89.00,1098.30,2507.20,110.90}},
	{"Whitewood Estates",           {1098.30,1726.20,-89.00,1197.30,2243.20,110.90}},
	{"Willowfield",                 {1970.60,-2179.20,-89.00,2089.00,-1852.80,110.90}},
	{"Willowfield",                 {2089.00,-2235.80,-89.00,2201.80,-1989.90,110.90}},
	{"Willowfield",                 {2089.00,-1989.90,-89.00,2324.00,-1852.80,110.90}},
	{"Willowfield",                 {2201.80,-2095.00,-89.00,2324.00,-1989.90,110.90}},
	{"Willowfield",                 {2541.70,-1941.40,-89.00,2703.50,-1852.80,110.90}},
	{"Willowfield",                 {2324.00,-2059.20,-89.00,2541.70,-1852.80,110.90}},
	{"Willowfield",                 {2541.70,-2059.20,-89.00,2703.50,-1941.40,110.90}},
	{"Yellow Bell Station",         {1377.40,2600.40,-21.90,1492.40,2687.30,78.00}},
	// Citys Zones
	{"Los Santos",                  {44.60,-2892.90,-242.90,2997.00,-768.00,900.00}},
	{"Las Venturas",                {869.40,596.30,-242.90,2997.00,2993.80,900.00}},
	{"Bone County",                 {-480.50,596.30,-242.90,869.40,2993.80,900.00}},
	{"Tierra Robada",               {-2997.40,1659.60,-242.90,-480.50,2993.80,900.00}},
	{"Tierra Robada",               {-1213.90,596.30,-242.90,-480.50,1659.60,900.00}},
	{"San Fierro",                  {-2997.40,-1115.50,-242.90,-1213.90,1659.60,900.00}},
	{"Red County",                  {-1213.90,-768.00,-242.90,2997.00,596.30,900.00}},
	{"Flint County",                {-1213.90,-2892.90,-242.90,44.60,-768.00,900.00}},
	{"Whetstone",                   {-2997.40,-2892.90,-242.90,-1213.90,-1115.50,900.00}}
};


main(){}

new db_handle,
    reconnectAttempts;


/*
*   OnGameModeInit : EXECUTES ON SERVER STARTUP
*/

public OnGameModeInit() {
    printf("%s version %s has loaded", SERVER_NAME, SERVER_VER);
    printf("(c) 2015 %s :: %s", SERVER_NAME, SERVER_SITE);
    print("--------------------------------");

    new string_setHostname[64];
    format(string_setHostname, sizeof(string_setHostname), "hostname %s v.%s [%s]", SERVER_NAME, SERVER_VER, SAMP_VER);
    SendRconCommand(string_setHostname);

    SetGameModeText("Cops and Robbers");
    SetWeather(WEATHER_SUNNY);
    SetWorldTime(7); // Set the time to 7 am
    clock[1] = 7; // Set the hour to 7 am
    TextDrawSetString(Text:textdraw_ampm, "am");

    DisableInteriorEnterExits();
    UsePlayerPedAnims();
    SetDeathDropAmount(0);
    EnableStuntBonusForAll(0);

    SetTimer("timer_1000ms", 1000, true);


    /*
    *   DATABASE CONNECTION
    */
    mysql_log(LOG_ERROR | LOG_WARNING, LOG_TYPE_HTML);
    db_handle = mysql_connect(SQL_HOST, SQL_USER, SQL_DB, SQL_PASS);
    CreateSQLTables();


    /*
    *   PLAYER CLASSES
    */
    AddPlayerClass(0, 2105.4773, -1776.6875, 13.3911, 120.5673, 0, 0, 0, 0, 0, 0);


    /*
    *   VEHICLE SPAWNS
    */
    CreateStaticVehicleEx(481, 1963.5414, -1412.5167, 13.0948, 132.1975, -1, -1, 180);     // GLEN PARK - BMX
	CreateStaticVehicleEx(481, 1907.3293, -1402.8795, 13.2771, 65.8256, -1, -1, 180);      // GLEN PARK - BMX
	CreateStaticVehicleEx(448, 2097.5940, -1814.2268, 12.9818, 90.2881, -1, -1, 180);      // IDLEWOOD - Pizzaboy for Well-Stacked SIDE-MISSION
	CreateStaticVehicleEx(448, 2097.6011, -1817.0757, 12.9818, 89.6768, -1, -1, 180);      // IDLEWOOD - Pizzaboy for Well-Stacked SIDE-MISSION
	CreateStaticVehicleEx(492, 2117.0549, -1783.1254, 13.1697, 180.1259, -1, -1, 180);     // IDLEWOOD - Random car spawn (CHEAP)
	CreateStaticVehicleEx(492, 2052.6104, -1904.2002, 13.3286, 180.4601, -1, -1, 180);     // IDLEWOOD - Random car spawn (CHEAP)
	CreateStaticVehicleEx(416, 2036.3568, -1424.8959, 17.1415, 179.9803, -1, -1, 180);     // JEFFERSON - Ambulance
	CreateStaticVehicleEx(416, 2012.7878, -1411.2791, 17.1412, 89.5918, -1, -1, 180);      // JEFFERSON - Ambulance
	CreateStaticVehicleEx(416, 1176.9420, -1308.5403, 14.0231, 269.1733, -1, -1, 180);     // MARKET - Ambulance
	CreateStaticVehicleEx(416, 1177.4766, -1338.8846, 14.0592, 270.7091, -1, -1, 180);     // MARKET - Ambulance
	missionVehicle[ammunation][1] = CreateStaticVehicleEx(609, 1423.1058, -1294.3430, 13.6242, 179.7749, 0,
		0, 180, false);	// MARKET - Boxville for Ammunation SIDE-MISSION
	CreateStaticVehicleEx(409, 1022.8722, -1136.3894, 23.5337, 89.8156, 0, 0, 180);        // MARKET - Stretch
	CreateStaticVehicleEx(420, 1191.0548, -1315.1404, 13.2576, 179.9754, -1, -1, 180);     // MARKET - Taxi
	CreateStaticVehicleEx(525, 569.5156, -1297.1204, 17.1235, 9.4674, 17, 20, 180);        // RODEO - Tow Truck
	CreateStaticVehicleEx(445, 1535.8989, -1677.7561, 13.2578, 0.1267, -1, -1, 180);       // PERSHING SQUARE - Admiral
	CreateStaticVehicleEx(438, 1535.7972, -1668.3037, 13.3873, 0.6459, 6, 76, 180);        // PERSHING SQUARE - Cabbie
	CreateStaticVehicleEx(427, 1544.8230, -1658.9716, 6.0224, 89.9998, 0, 1, 180);         // PERSHING SQUARE - Enforcer
	CreateStaticVehicleEx(427, 1558.8275, -1710.8671, 6.0226, 179.4914, 0, 1, 180);        // PERSHING SQUARE - Enforcer
	CreateStaticVehicleEx(490, 1569.6101, -1614.0260, 13.5114, 180.2138, 0, 0, 180);       // PERSHING SQUARE - FBI Rancher
	CreateStaticVehicleEx(523, 1601.3694, -1704.2208, 5.4590, 91.4412, 0, 0, 180);         // PERSHING SQUARE - HPV-1000
	CreateStaticVehicleEx(523, 1583.5588, -1710.8759, 5.4624, 180.7263, 0, 0, 180);        // PERSHING SQUARE - HPV-1000
	CreateStaticVehicleEx(523, 1584.8356, -1671.6987, 5.4635, 91.1349, 0, 0, 180);         // PERSHING SQUARE - HPV-1000
	CreateStaticVehicleEx(523, 1601.9028, -1687.8412, 5.4608, 270.5534, 0, 0, 180);        // PERSHING SQUARE - HPV-1000
	CreateStaticVehicleEx(523, 1545.0867, -1680.2902, 5.4622, 90.3487, 0, 0, 180);         // PERSHING SQUARE - HPV-1000
	CreateStaticVehicleEx(523, 1526.3474, -1644.5916, 5.4601, 359.4013, 0, 0, 180);        // PERSHING SQUARE - HPV-1000
	CreateStaticVehicleEx(596, 1601.7264, -1691.9922, 5.6122, 89.8438, 0, 1, 180);         // PERSHING SQUARE - Police Car
	CreateStaticVehicleEx(596, 1578.5626, -1710.9344, 5.6120, 179.3608, 0, 1, 180);        // PERSHING SQUARE - Police Car
	CreateStaticVehicleEx(596, 1570.3848, -1710.6204, 5.6119, 359.7379, 0, 1, 180);        // PERSHING SQUARE - Police Car
	CreateStaticVehicleEx(596, 1528.3572, -1683.8815, 5.6121, 89.6698, 0, 1, 180);         // PERSHING SQUARE - Police Car
	CreateStaticVehicleEx(596, 1534.6437, -1644.7954, 5.6108, 179.8977, 0, 1, 180);        // PERSHING SQUARE - Police Car
	CreateStaticVehicleEx(596, 1545.3591, -1672.1112, 5.6108, 269.6912, 0, 1, 180);        // PERSHING SQUARE - Police Car
	CreateStaticVehicleEx(599, 1591.4363, -1711.1505, 6.0793, 180.1122, 0, 1, 180);        // PERSHING SQUARE - Police Ranger
	CreateStaticVehicleEx(587, 1545.1326, -1651.0658, 5.6174, 89.9713, -1, -1, 180);       // PERSHING SQUARE - Random Car Spawn (ALL)
	CreateStaticVehicleEx(587, 1545.8292, -1684.3910, 5.6163, 269.2561, -1, -1, 180);      // PERSHING SQUARE - Random Car Spawn (ALL)
	CreateStaticVehicleEx(587, 1574.4895, -1711.0133, 5.6173, 179.8264, -1, -1, 180);      // PERSHING SQUARE - Random Car Spawn (ALL)
	CreateStaticVehicleEx(587, 1601.6707, -1700.1418, 5.6160, 90.3198, -1, -1, 180);       // PERSHING SQUARE - Random Car Spawn (ALL)
	CreateStaticVehicleEx(421, 1493.2217, -1737.1499, 13.3417, 270.0429, 0, 0, 180);       // PERSHING SQUARE - Washington
	CreateStaticVehicleEx(421, 1484.6533, -1737.1742, 13.3417, 270.3521, 0, 0, 180);       // PERSHING SQUARE - Washington
	missionVehicle[ammunation][0] = CreateStaticVehicleEx(609, 2388.5330, -2015.0560, 13.6209, 269.7960, 0,
		0, 180, false);	// WILLOWFIELD - Ammunation Boxville for SIDE-MISSION
	CreateStaticVehicleEx(422, 2389.3772, -1977.0598, 13.4486, 269.6373, -1, -1, 180);     // WILLOWFIELD - Bobcat
	CreateStaticVehicleEx(492, 2380.2615, -1927.5846, 13.1646, 0.3569, -1, -1, 180);       // WILLOWFIELD - Random car spawn (CHEAP)
	CreateStaticVehicleEx(492, 2498.8735, -1953.6162, 13.2056, 179.9695, -1, -1, 180);     // WILLOWFIELD - Random car spawn (CHEAP)


    /*
    *
    */
    // COMMERCE - Roboi's Food Mart
    checkpoint[roboi][0] = CreateDynamicCP(1352.3682, -1759.2537, 13.5078, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Roboi's Food Mart", COLOUR_LABEL_SHOP, 1352.3682, -1759.2537, 13.5078 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1352.3682, -1759.2537, 13.5078, 34, 0, 0,0, -1, 500.0);
    // DOWNTOWN LOS SANTOS - Inside Track
    checkpoint[insideTrack] = CreateDynamicCP(1631.8396, -1172.9271, 24.0843, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Casino]\n{FFFFFF}Inside Track\nHorse Betting", COLOUR_LABEL_CASINO, 1631.8396, -1172.9271, 24.0843 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1631.8396, -1172.9271, 24.0843, 42, 0, 0,0, -1, 500.0);
    // DOWNTOWN LOS SANTOS - ZIP
    checkpoint[zip] = CreateDynamicCP(1456.4880, -1137.5918, 23.9483, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}ZIP Clothing Store", COLOUR_LABEL_SHOP, 1456.4880, -1137.5918, 23.9483 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1456.4880, -1137.5918, 23.9483, 45, 0, 0,0, -1, 500.0);
    // EAST LOS SANTOS - Cluckin' Bell
    checkpoint[cluckinBell][0] = CreateDynamicCP(2419.7883, -1508.9695, 24.0000, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Food]\n{FFFFFF}Cluckin' Bell", COLOUR_LABEL_FOOD, 2419.7883, -1508.9695, 24.0000 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(2419.7883, -1508.9695, 24.0000, 14, 0, 0,0, -1, 500.0);
    // EL CORONA - 24/7 Convenience Store
    checkpoint[twentyFourSeven] = CreateDynamicCP(1833.7815, -1842.6147, 13.5781, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}24/7", COLOUR_LABEL_SHOP, 1833.7815, -1842.6147, 13.5781 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1833.7815, -1842.6147, 13.5781, 52, 0, 0,0, -1, 500.0);
    // EL CORONA - Empty Store
    checkpoint[emptyStore] = CreateDynamicCP(1976.6508, -2036.6124, 13.5469, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("N/A", 0xFFFFFFFF, 1976.6508, -2036.6124, 13.5469 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1976.6508, -2036.6124, 13.5469, 37, 0, 0,0, -1, 500.0);
    // EL CORONA - Mexican Restaurant
    checkpoint[mexicanRestaurant] = CreateDynamicCP(1948.9843, -1985.1040, 13.5469, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Food]\n{FFFFFF}Mexican Restaurant", COLOUR_LABEL_FOOD, 1948.9843, -1985.1040, 13.5469 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1948.9843, -1985.1040, 13.5469, 37, 0, 0,0, -1, 500.0);
    // EL CORONA - Sex Shop
    checkpoint[sexShop][0] = CreateDynamicCP(1940.0056, -2115.9719, 13.6953, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Sex Shop", COLOUR_LABEL_SHOP, 1940.0056, -2115.9719, 13.6953 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1940.0056, -2115.9719, 13.6953, 38, 0, 0,0, -1, 500.0);
    // GANTON - Binco
    checkpoint[binco] = CreateDynamicCP(2244.3308, -1665.5498, 15.4766, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Binco Clothing Store", COLOUR_LABEL_SHOP, 2244.3308, -1665.5498, 15.4766 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(2244.3308, -1665.5498, 15.4766, 45, 0, 0,0, -1, 500.0);
    // GANTON - Gym
    checkpoint[gym] = CreateDynamicCP(2229.9028, -1721.2588, 13.5613, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("Gym", 0xC42B2BFF, 2229.9028, -1721.2588, 13.5613 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(2229.9028, -1721.2588, 13.5613, 54, 0, 0,0, -1, 500.0);
    // IDLEWOOD - Alhambra Night Club
    checkpoint[alhambra] = CreateDynamicCP(1836.9731, -1682.4681, 13.3256, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("Alhambra Night Club", 0x007F46FF, 1836.9731, -1682.4681, 13.3256 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1836.9731, -1682.4681, 13.3256, 48, 0, 0,0, -1, 500.0);
    // IDLEWOOD - Reese's Barber Salon
    checkpoint[barberSalon][0] = CreateDynamicCP(2070.6272, -1793.8312, 13.5469, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Reese's Barber Salon", COLOUR_LABEL_SHOP, 2070.6272, -1793.8312, 13.5469 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(2070.6272, -1793.8312, 13.5469, 7, 0, 0,0, -1, 500.0);
    // IDLEWOOD - Tattoo Parlour
    checkpoint[tattooParlour][0] = CreateDynamicCP(2068.5808, -1779.8098, 13.5596, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Tattoo Parlour", COLOUR_LABEL_SHOP, 2068.5808, -1779.8098, 13.5596 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(2068.5808, -1779.8098, 13.5596, 39, 0, 0,0, -1, 500.0);
    // IDLEWOOD - Well-Stacked Pizza
    checkpoint[wellStackedPizza] = CreateDynamicCP(2105.4880, -1806.4988, 13.5547, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Food]\n{FFFFFF}Well-Stacked Pizza", COLOUR_LABEL_FOOD, 2105.4880, -1806.4988, 13.5547 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(2105.4880, -1806.4988, 13.5547, 29, 0, 0,0, -1, 500.0);
    // IDLEWOOD - Xoomer Gas
    checkpoint[xoomer][0] = CreateDynamicCP(1928.5809, -1776.3131, 13.5469, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Xoomer Convenience", COLOUR_LABEL_SHOP, 1928.5809, -1776.3131, 13.5469 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1928.5809, -1776.3131, 13.5469, 52, 0, 0,0, -1, 500.0);
        /*  JEFFERSON - Sub Urban  */
    checkpoint[subUrban] = CreateDynamicCP(2112.8521, -1211.4565, 23.9629, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Sub Urban Clothing Store", COLOUR_LABEL_SHOP, 2112.8521, -1211.4565, 23.9629 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(2112.8521, -1211.4565, 23.9629, 45, 0, 0,0, -1, 500.0);
    // JEFFERSON - The Pig Pen
    checkpoint[pigPen] = CreateDynamicCP(2421.5305, -1219.2437, 25.5616, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("The Pig Pen", 0xFF32E3FF, 2421.5305, -1219.2437, 25.5616 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(2421.5305, -1219.2437, 25.5616, 38, 0, 0,0, -1, 500.0);
    // MARKET - Ammunation
    checkpoint[ammunation][0] = CreateDynamicCP(1368.8864, -1279.8348, 13.5469, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Ammunation", COLOUR_LABEL_SHOP, 1368.8864, -1279.8348, 13.5469 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1368.8864, -1279.8348, 13.5469, 6, 0, 0,0, -1, 500.0);
    // MARKET - Barber Salon
    checkpoint[barberSalon][1] = CreateDynamicCP(824.0537, -1588.3116, 13.5436, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Barber Salon", COLOUR_LABEL_SHOP, 824.0537, -1588.3116, 13.5436 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(824.0537, -1588.3116, 13.5436, 7, 0, 0,0, -1, 500.0);
    // MARKET - Big S Liquor & Deli
    checkpoint[bigS] = CreateDynamicCP(875.8027, -1565.0177, 13.5334, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Big S Liquor & Deli", COLOUR_LABEL_SHOP, 875.8027, -1565.0177, 13.5334 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(875.8027, -1565.0177, 13.5334, 52, 0, 0,0, -1, 500.0);
    // MARKET - Burger Shot
    checkpoint[burgerShot][0] = CreateDynamicCP(810.4850, -1616.1683, 13.5469, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Food]\n{FFFFFF}Burger Shot", COLOUR_LABEL_FOOD, 810.4850, -1616.1683, 13.5469 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(810.4850, -1616.1683, 13.5469, 10, 0, 0,0, -1, 500.0);
    // MARKET - Cluckin' Bell
    checkpoint[cluckinBell][1] = CreateDynamicCP(928.9165, -1352.9698, 13.3438, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Food]\n{FFFFFF}Cluckin' Bell", COLOUR_LABEL_FOOD, 928.9165, -1352.9698, 13.3438 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(928.9165, -1352.9698, 13.3438, 14, 0, 0,0, -1, 500.0);
    // MARKET - Jim's Sticky Ring
    checkpoint[jimsStickyRing] = CreateDynamicCP(1038.1411, -1340.7314, 13.7451, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Food]\n{FFFFFF}Jim's Sticky Ring", COLOUR_LABEL_FOOD, 1038.1411, -1340.7314, 13.7451 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1038.1411, -1340.7314, 13.7451, 17, 0, 0,0, -1, 500.0);
    // MARKET - Sex Shop
    checkpoint[sexShop][1] = CreateDynamicCP(953.8809, -1336.8286, 13.5389, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Sex Shop", COLOUR_LABEL_SHOP, 953.8809, -1336.8286, 13.5389 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(953.8809, -1336.8286, 13.5389, 38, 0, 0,0, -1, 500.0);
    // MULHOLLAND - Xoomer Gas
    checkpoint[xoomer][1] = CreateDynamicCP(1000.5931, -919.9285, 42.3281, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Xoomer Convenience", COLOUR_LABEL_SHOP, 1000.5931, -919.9285, 42.3281 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1000.5931, -919.9285, 42.3281, 52, 0, 0,0, -1, 500.0);
    // PERSHING SQUARE - City Hall
    checkpoint[cityHall] = CreateDynamicCP(1479.4294, -1772.3127, 18.7958, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("City Hall", 0xFFFFFFFF, 1479.4294, -1772.3127, 18.7958 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1479.4294, -1772.3127, 18.7958, 61, 0, 0,0, -1, 500.0);
    // PERSHING SQUARE - LSPD
    checkpoint[lspd] = CreateDynamicCP(1555.4998, -1675.6289, 16.1953, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("Police Department", 0x0026FFFF, 1555.4998, -1675.6289, 16.1953 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1555.4998, -1675.6289, 16.1953, 30, 0, 0,0, -1, 500.0);
    // RODEO - Didier Sachs
    checkpoint[didierSachs] = CreateDynamicCP(454.2044, -1477.9888, 30.8142, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Didier Sachs Clothing Store", COLOUR_LABEL_SHOP, 454.2044, -1477.9888, 30.8142 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(454.2044, -1477.9888, 30.8142, 45, 0, 0,0, -1, 500.0);
    // RODEO - PROlaps
    checkpoint[prolaps] = CreateDynamicCP(499.5152, -1360.6228, 16.3687, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}PROlaps Clothing Store", COLOUR_LABEL_SHOP, 499.5152, -1360.6228, 16.3687 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(499.5152, -1360.6228, 16.3687, 45, 0, 0,0, -1, 500.0);
    // RODEO - Victim
    checkpoint[victim] = CreateDynamicCP(461.7038, -1500.7974, 31.0453, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Victim Clothing Store", COLOUR_LABEL_SHOP, 461.7038, -1500.7974, 31.0453 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(461.7038, -1500.7974, 31.0453, 45, 0, 0,0, -1, 500.0);
    // TEMPLE - Burger Shot
    checkpoint[burgerShot][1] = CreateDynamicCP(1199.2942, -918.1407, 43.1230, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Food]\n{FFFFFF}Burger Shot", COLOUR_LABEL_FOOD, 1199.2942, -918.1407, 43.1230 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1199.2942, -918.1407, 43.1230, 10, 0, 0,0, -1, 500.0);
    // TEMPLE - Roboi's Food Mart
    checkpoint[roboi][1] = CreateDynamicCP(1315.4867, -897.6832, 39.5781, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Roboi's Food Mart", COLOUR_LABEL_SHOP, 1315.4867, -897.6832, 39.5781 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1315.4867, -897.6832, 39.5781, 34, 0, 0,0, -1, 500.0);
    // TEMPLE - Sex Shop
    checkpoint[sexShop][2] = CreateDynamicCP(1087.7229, -922.4821, 43.3906, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Sex Shop", COLOUR_LABEL_SHOP, 1087.7229, -922.4821, 43.3906 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(1087.7229, -922.4821, 43.3906, 38, 0, 0,0, -1, 500.0);
    // WILLOWFIELD - Ammunation
    checkpoint[ammunation][1] = CreateDynamicCP(2400.4768, -1981.9961, 13.5469, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Shop]\n{FFFFFF}Ammunation", COLOUR_LABEL_SHOP, 2400.4768, -1981.9961, 13.5469 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(2400.4768, -1981.9961, 13.5469, 6, 0, 0,0, -1, 500.0);
    // WILLOWFIELD - Cluckin' Bell
    checkpoint[cluckinBell][2] = CreateDynamicCP(2397.8264, -1899.1852, 13.5469, 1.5, 0, 0, -1, 25.0);
    CreateDynamic3DTextLabel("[Food]\n{FFFFFF}Cluckin' Bell", COLOUR_LABEL_FOOD, 2397.8264, -1899.1852, 13.5469 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    CreateDynamicMapIcon(2397.8264, -1899.1852, 13.5469, 14, 0, 0,0, -1, 500.0);


    checkpoint[exitCP][0] = CreateDynamicCP(493.3881, -24.8725, 1000.6797, 1.5, 0, 0, -1, 25.0); // Alhambra
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 493.3881, -24.8725, 1000.6797 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][1] = CreateDynamicCP(285.4078, -41.7508, 1001.5156, 1.5, 0, 0, -1, 25.0); // Ammunation
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 285.4078, -41.7508, 1001.5156 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][2] = CreateDynamicCP(412.0234, -54.4461, 1001.8984, 1.5, 0, 0, -1, 25.0); // Barber Salon
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 412.0234, -54.4461, 1001.8984 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][3] = CreateDynamicCP(207.6609, -111.2572, 1005.1328, 1.5, 0, 0, -1, 25.0); // Binco
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 207.6609, -111.2572, 1005.1328 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][4] = CreateDynamicCP(362.8844, -75.1801, 1001.5078, 1.5, 0, 0, -1, 25.0); // Burger Shot
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 362.8844, -75.1801, 1001.5078 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][5] = CreateDynamicCP(390.7693, 173.8254, 1008.3828, 1.5, 0, 0, -1, 25.0); // City Hall
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 390.7693, 173.8254, 1008.3828 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][6] = CreateDynamicCP(364.9425, -11.8084, 1001.8516, 1.5, 0, 0, -1, 25.0); // Cluckin' Bell
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 364.9425, -11.8084, 1001.8516 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][7] = CreateDynamicCP(204.3289, -168.8602, 1000.5234, 1.5, 0, 0, -1, 25.0); // Didier Sachs
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 204.3289, -168.8602, 1000.5234 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][8] = CreateDynamicCP(772.3028, -5.5156, 1000.7285, 1.5, 0, 0, -1, 25.0); // Gym
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 772.3028, -5.5156, 1000.7285 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][9] = CreateDynamicCP(834.6678, 7.3913, 1004.1870, 1.5, 0, 0, -1, 25.0); // Inside Track
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 834.6678, 7.3913, 1004.1870 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][10] = CreateDynamicCP(377.1337, -193.3049, 1000.6328, 1.5, 0, 0, -1, 25.0); // Jim's Sticky Ring
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 377.1337, -193.3049, 1000.6328 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][11] = CreateDynamicCP(1204.7920, -13.8523, 1000.9219, 1.5, 0, 0, -1, 25.0); // Pig Pen
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 1204.7920, -13.8523, 1000.9219 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][12] = CreateDynamicCP(207.0391, -140.3764, 1003.5078, 1.5, 0, 0, -1, 25.0); // PROlaps
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 207.0391, -140.3764, 1003.5078 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][13] = CreateDynamicCP(418.6334, -84.3686, 1001.8047, 1.5, 0, 0, -1, 25.0); // Reese's Barber Salon
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 418.6334, -84.3686, 1001.8047 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][14] = CreateDynamicCP(-25.8912, -188.2513, 1003.5469, 1.5, 0, 0, -1, 25.0); // Roboi's Food Mart
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, -25.8912, -188.2513, 1003.5469 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][15] = CreateDynamicCP(-100.3527, -25.0381, 1000.7188, 1.5, 0, 0, -1, 25.0); // Sex Shop
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, -100.3527, -25.0381, 1000.7188 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][16] = CreateDynamicCP(203.7812, -50.6632, 1001.8047, 1.5, 0, 0, -1, 25.0); // Sub Urban
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 203.7812, -50.6632, 1001.8047 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][17] = CreateDynamicCP(-204.3668, -27.3474, 1002.2734, 1.5, 0, 0, -1, 25.0); // Tattoo Parlour
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, -204.3668, -27.3474, 1002.2734 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][18] = CreateDynamicCP(227.5095, -8.1530, 1002.2109, 1.5, 0, 0, -1, 25.0); // Victim
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 227.5095, -8.1530, 1002.2109 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][19] = CreateDynamicCP(372.3482, -133.5235, 1001.4922, 1.5, 0, 0, -1, 25.0); // Well-Stacked Pizza
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 372.3482, -133.5235, 1001.4922 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);
    checkpoint[exitCP][20] = CreateDynamicCP(161.4028, -97.1097, 1001.8047, 1.5, 0, 0, -1, 25.0); // ZIP
    CreateDynamic3DTextLabel("[Exit]", COLOUR_WHITE, 161.4028, -97.1097, 1001.8047 + 0.5, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 100.0);


    /*
    *   TEXTDRAWS
    */
    textdraw_time_default = TextDrawCreate(550.000000, 20.000000, "00:00");
	TextDrawBackgroundColor(textdraw_time_default, 255);
	TextDrawFont(textdraw_time_default, 3);
	TextDrawLetterSize(textdraw_time_default, 0.539999, 2.299999);
	TextDrawColor(textdraw_time_default, -1);
	TextDrawSetOutline(textdraw_time_default, 1);
	TextDrawSetProportional(textdraw_time_default, 1);
	TextDrawSetSelectable(textdraw_time_default, 0);

	textdraw_time_ampm = TextDrawCreate(550.000000, 20.000000, "00:00");
	TextDrawBackgroundColor(textdraw_time_ampm, 255);
	TextDrawFont(textdraw_time_ampm, 3);
	TextDrawLetterSize(textdraw_time_ampm, 0.539999, 2.299999);
	TextDrawColor(textdraw_time_ampm, -1);
	TextDrawSetOutline(textdraw_time_ampm, 1);
	TextDrawSetProportional(textdraw_time_ampm, 1);
	TextDrawSetSelectable(textdraw_time_ampm, 0);

	textdraw_ampm = TextDrawCreate(607.000000, 21.000000, "pm");
	TextDrawBackgroundColor(textdraw_ampm, 255);
	TextDrawFont(textdraw_ampm, 2);
	TextDrawLetterSize(textdraw_ampm, 0.290000, 1.400000);
	TextDrawColor(textdraw_ampm, -1);
	TextDrawSetOutline(textdraw_ampm, 1);
	TextDrawSetProportional(textdraw_ampm, 1);
	TextDrawSetSelectable(textdraw_ampm, 0);
    return 1;
}

#define TABLE_PREFIX "resurgence"

CreateSQLTables() {
    // Users table
    mysql_query(db_handle, "CREATE TABLE IF NOT EXISTS "TABLE_PREFIX"_users
        (userid INT NOT NULL auto_increment PRIMARY KEY,
        username VARHCAR(24) NOT NULL,
        password VARCHAR(60) NOT NULL,
        first_ip VARCHAR(15) NOT NULL,
        last_ip VARCHAR(15) NOT NULL,
        email VARCHAR(50) NOT NULL,
        created TIMESTAMP NOT NULL,
        last_login TIMESTAMP NOT NULL,
        disabled TINYINT(1) NOT NULL,
        locked TIMESTAMP NOT NULL,
        banned TINYINT(1) NOT NULL,
        ban_date TIMESTAMP NOT NULL,
        friend_count INT NOT NULL,
        muted TIMESTAMP NOT NULL,
        mute_time INT NOT NULL);", false);

    // Characters table
    mysql_query(db_handle, "CREATE TABLE IF NOT EXISTS "TABLE_PREFIX"_characters
        (characterid INT NOT NULL auto_increment PRIMARY KEY,
        userid INT NOT NULL,
        created TIMESTAMP NOT NULL,
        last_played TIMESTAMP NOT NULL,
        disabled TINYINT(1) NOT NULL,
        wallet_money INT(8) NOT NULL,
        bank_money INT NOT NULL,
        jailed TIMESTAMP NOT NULL,
        jail_time INT NOT NULL);", false);

    // Skills table
    mysql_query(db_handle, "CREATE TABLE IF NOT EXISTS "TABLE_PREFIX"_skills
        (characterid INT NOT NULL PRIMARY KEY,
        );", false);

    mysql_query(db_handle, "CREATE TABLE IF NOT EXISTS "TABLE_PREFIX"_friends
        (
        );", false);
	return 1;
}

public OnGameModeExit() {
    printf("%s version %s has unloaded", SERVER_NAME, SERVER_VER);

    mysql_close();

    TextDrawHideForAll(Text:textdraw_time_default);
    TextDrawHideForAll(Text:textdraw_time_ampm);
    TextDrawHideForAll(Text:textdraw_ampm);
    TextDrawDestroy(Text:textdraw_time_default);
    TextDrawDestroy(Text:textdraw_time_ampm);
    TextDrawDestroy(Text:textdraw_ampm);
    return 1;
}


/*
*   timer_1000ms :: THE MAIN TIMER FOR THE SERVER
*/
forward timer_1000ms();
public timer_1000ms() {
	clock[2] ++;

	if(clock[2] == 60) {
		clock[1] ++;
		clock[2] = 0;
		SetWorldTime(clock[1]);

		if(clock[1] == 12) TextDrawSetString(Text:textdraw_ampm, "pm");
	}
	if(clock[1] == 24) {
		clock[0] ++;
		clock[1] = 0;

		TextDrawSetString(Text:textdraw_ampm, "am");
	}
	if(clock[0] == 8) {
		clock[0] = 0;
	}

	new string_setTime[6],
		hour = clock[1];

	format(string_setTime, sizeof(string_setTime), "%02d:%02d", clock[1], clock[2]);
	TextDrawSetString(Text:textdraw_time_default, string_setTime);

	if(hour > 12) hour = hour - 12;
	format(string_setTime, sizeof(string_setTime), "%02d:%02d", hour, clock[2]);
	TextDrawSetString(Text:textdraw_time_ampm, string_setTime);

	foreach(Player, i) {
		new loc[28],
			string_setLocation[42];

		GetPlayerLocation(i, loc, 28);
		format(string_setLocation, sizeof(string_setLocation), "Location: ~w~%s", loc);
		PlayerTextDrawSetString(i, PlayerText:textdraw_location[i], string_setLocation);


        /*
        *   MUTED PLAYER
        */

        if (player[i][muteTime] > 0) {
            player[i][muteTime] -= 1;

            if (player[i][muteTime] == 0) {
                SendClientMessage(i, COLOUR_GREEN, "[SERVER] You have been automatically unmuted by the system and can use the chat again.");
            }
        }


        /*
        *   JAILED PLAYER
        */

        if (player[i][jailTime] > 0) {
            player[i][jailTime] -= 1;

            if (player[i][jailTime] == 0) {
                switch (player[i][inAdminJail]) {
                    case true: {
                        SendClientMessage(i, COLOUR_GREEN, "[SERVER] You have been automatically released from jail. Please follow the /rules next time, thanks!");
                        break;
                    }
                    case false: {
                        SendClientMessage(i, COLOUR_GREEN, "[LSPD] You have served your jail time and been released.");
                        break;
                    }
                }
            }
        }
    }
	return 1;
}

forward timer_30000ms(playerid);
public timer_30000ms(playerid) {
    if ((player[playerid][lastSave] - gettime()) >= 30000) {
        UpdatePlayerData(playerid);
    }
    return 1;
}

public OnIncomingConnection(playerid, ip_address[], port) {
    printf("Incoming connection: %s:%d has taken playerid %d", ip_address, port, playerid);
    return 1;
}

public OnPlayerConnect(playerid) {
    new string_playerConnected[74];
    format(string_playerConnected, sizeof(string_playerConnected), "Hello %s, welcome to %s v.%s!", PlayerName(playerid), SERVER_NAME, SERVER_VER);
    SendClientMessage(playerid, COLOUR_WHITE, string_playerConnected);

    format(string_playerConnected, sizeof(string_playerConnected), "[SERVER] %s(%d) joined %s", PlayerName(playerid), playerid, SERVER_NAME);

    foreach (Player, i) {
        if (playerid != i) {
            SendClientMessage(i, COLOUR_GREY, string_playerConnected);
        }
    }

    /*
    *   LOCATION TEXTDRAW
    */

    textdraw_location[playerid] = CreatePlayerTextDraw(playerid, 4.000000, 430.000000, "Location: ~w~Unknown");
    PlayerTextDrawBackgroundColor(playerid, PlayerText:textdraw_location[playerid], 255);
    PlayerTextDrawFont(playerid, PlayerText:textdraw_location[playerid], 1);
    PlayerTextDrawLetterSize(playerid, PlayerText:textdraw_location[playerid], 0.420000, 1.600000);
    PlayerTextDrawColor(playerid, PlayerText:textdraw_location[playerid], 6927871);
    PlayerTextDrawSetOutline(playerid, PlayerText:textdraw_location[playerid], 1);
    PlayerTextDrawSetProportional(playerid, PlayerText:textdraw_location[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, PlayerText:textdraw_location[playerid], 0);

    player[playerid][connectionTime] = gettime();
    SetTimerEx("timer_30000ms", 30000, true, "d", playerid);

    new sql[85];
    mysql_format(db_handle, sql, sizeof(sql), "SELECT * FROM users WHERE username='%e' LIMIT 1", PlayerName(playerid));
    mysql_tquery(db_handle, sql, "OnAccountCheckIfExists", "ds", playerid, PlayerName(playerid));

    player[playerid][adminLevel] = 4;
    return 1;
}

forward OnAccountCheckIfExists(playerid, username[]);
public OnAccountCheckIfExists(playerid, username[]) {
    if (strcmp(PlayerName(playerid), username, true) != 0) return 0;

    new string_userCheck[138],
        string_title[64];

    if (cache_num_rows() > 0) { // Account is registered
        new accountLock = cache_get_field_content_int(0, "securityLock");
        new accountIp[16];
        cache_get_field_content(0, "last_ip", accountIp, db_handle, 16);
        cache_get_field_content(0, "email", player[playerid][email], db_handle, MAX_EMAIL_LENGTH);

        if (accountLock > gettime()) {
            if (!strcmp(GetPlayerIpAddress(playerid), accountIp)) { // Help the user reset their password
                format(string_title, sizeof(string_title), "%s - Account Recovery", SERVER_NAME);
                format(string_userCheck, sizeof(string_userCheck), "Your account is currently locked due to recent " \
                    "login attempt failures.\n\nIf you would like to recover your account, please click 'Okay'.");
                return ShowPlayerDialog(playerid, DIALOG_PWRESET_START, DIALOG_STYLE_MSGBOX, string_title, string_userCheck, "Okay", "Quit");
            }
            else { // Possibly malicious user, kick from server
                SendClientMessage(playerid, COLOUR_RED, "[SERVER] Your account is currently locked due to recent login " \
                    "attempt failures. Please come back later or contact an administrator for assistance.");
                return Kick(playerid);
            }
        }

        cache_get_field_content(0, "password", player[playerid][bcryptHash], db_handle, BCRYPT_HASH_LENGTH);

        format(string_title, sizeof(string_title), "%s - Account Login", SERVER_NAME);
        format(string_userCheck, sizeof(string_userCheck), "This account is registered. Please enter your password into the field below to login.");
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, string_title, string_userCheck, "Login", "Quit");
    }
    else { // Account does not exist
        format(string_title, sizeof(string_title), "%s - Account Registration", SERVER_NAME);
        format(string_userCheck, sizeof(string_userCheck), "This account is not registered. Please enter a password into the field below to begin the registration process.");
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, string_title, string_userCheck, "Continue", "Quit");
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason) {
    new string_playerDisconnect[73];

    switch (reason) {
        case 0: format(string_playerDisconnect, sizeof(string_playerDisconnect), "[SERVER] %s(%d) left the server (Lost Connection)", PlayerName(playerid), playerid);
        case 1: format(string_playerDisconnect, sizeof(string_playerDisconnect), "[SERVER] %s(%d) left the server (Disconnected)", PlayerName(playerid), playerid);
        case 2: format(string_playerDisconnect, sizeof(string_playerDisconnect), "[SERVER] %s(%d) left the server (Kicked)", PlayerName(playerid), playerid);
    }

    SendClientMessageToAll(COLOUR_GREY, string_playerDisconnect);

    if (player[playerid][authenticated] == true) {
        UpdatePlayerData(playerid);
    }

    ClearPlayerConfig(playerid);
    return 1;
}

public OnPlayerSpawn(playerid) {
    player[playerid][spawned] = true;

    SetPlayerColor(playerid, COLOUR_WHITE);

    switch (player[playerid][timeFormat]) {
        case TIME_DISPLAY_DEFAULT: TextDrawShowForPlayer(playerid, Text:textdraw_time_default);
        case TIME_DISPLAY_SHOW_AMPM: {
            TextDrawShowForPlayer(playerid, Text:textdraw_time_ampm);
            TextDrawShowForPlayer(playerid, Text:textdraw_ampm);
        }
    }

    PlayerTextDrawShow(playerid, PlayerText:textdraw_location[playerid]);
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason) {
    player[playerid][spawned] = false;

    switch (killerid) {
        case INVALID_PLAYER_ID: SendDeathMessage(INVALID_PLAYER_ID, playerid, reason);
        default: SendDeathMessage(killerid, playerid, reason);
    }

    SetPlayerColor(playerid, COLOUR_GREY);
    TextDrawHideForPlayer(playerid, Text:textdraw_location[playerid]);
    return 1;
}

public public OnPlayerUpdate(playerid)
{
    new playerMoney = GetPlayerMoneyEx(playerid);
    if (playerMoney != GetPlayerMoney(playerid)) {
        SetPlayerMoney(playerid, playerMoney);

        new string_playerUpdate[78];
        format(string_playerUpdate, sizeof(string_playerUpdate), "[SAC] {FFFFFF}Money cheat attempt by %s(%d) prevented.", PlayerName(playerid), playerid);

        foreach(Player, i) {
            if (player[i][adminLevel] >= ADMIN_LEVEL_MOD) {
                SendClientMessage(i, COLOUR_LIGHTPURPLE, string_playerUpdate);
            }
        }
    }
    return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate) {
    if (newstate == PLAYER_STATE_DRIVER) {
        new vehicleid = GetPlayerVehicleID(playerid);
        player[playerid][inVehicleID] = vehicleid;

        SetVehicleParamsEx(vehicleid, vehicle[vehicleid][engine], vehicle[vehicleid][lights], vehicle[vehicleid][alarm], vehicle[vehicleid][doors], vehicle[vehicleid][hood], vehicle[vehicleid][trunk], vehicle[vehicleid][objective]);

        if ((vehicleid == missionVehicle[ammunation][0]) || (vehicleid == missionVehicle[ammunation][1])) {
            SendClientMessage(playerid, COLOUR_WHITE, "[MISSION] Ammunation side mission available. Press 2 to get started.");
        }
    }

    if (oldstate == PLAYER_STATE_DRIVER) {
        new vengine, vlights, valarm, vdoors, vhood, vtrunk, vobjective;
        GetVehicleParamsEx(player[playerid][inVehicleID], vengine, vlights, valarm, vdoors, vhood, vtrunk, vobjective);
        SetVehicleParamsEx(player[playerid][inVehicleID], false, vlights, valarm, vdoors, vhood, vtrunk, vobjective);

        player[playerid][inVehicleID] = 0;
    }
    return 1;
}

public OnPlayerEnterDynamicCP(playerid, checkpointid) {
    new interior = 0;

    if(checkpointid == checkpoint[roboi][0])
		return SetPlayerPosEx(playerid, -25.9388, -186.1507, 1003.5469, 0.9008, interior, 1001);
	else if(checkpointid == checkpoint[roboi][1])
		return SetPlayerPosEx(playerid, -25.9388, -186.1507, 1003.5469, 0.9008, interior, 1002);
	else if(checkpointid == checkpoint[insideTrack])
		return SetPlayerPosEx(playerid, 832.4626, 7.3818, 1004.1797, 90.3034, interior, 1003);
	else if(checkpointid == checkpoint[zip])
		return SetPlayerPosEx(playerid, 161.3305, -94.1630, 1001.8047, 1.2904, interior, 1004);
	else if(checkpointid == checkpoint[cluckinBell][0])
		return SetPlayerPosEx(playerid, 364.9847, -9.4533, 1001.8516, 300.4080, interior, 1005);
	else if(checkpointid == checkpoint[cluckinBell][1])
		return SetPlayerPosEx(playerid, 364.9847, -9.4533, 1001.8516, 300.4080, interior, 1006);
	else if(checkpointid == checkpoint[cluckinBell][2])
		return SetPlayerPosEx(playerid, 364.9847, -9.4533, 1001.8516, 300.4080, interior, 1007);
	else if(checkpointid == checkpoint[twentyFourSeven])
		return SendClientMessage(playerid, COLOUR_GREY, "The 24/7 is currently closed.");
	else if(checkpointid == checkpoint[emptyStore])
		return SendClientMessage(playerid, COLOUR_GREY, "This building is currently unoccupied.");
	else if(checkpointid == checkpoint[mexicanRestaurant])
		return SendClientMessage(playerid, COLOUR_GREY, "The Mexican restaurant is currently closed.");
	else if(checkpointid == checkpoint[sexShop][0])
		return SetPlayerPosEx(playerid, -100.3775, -22.7395, 1000.7188, 0.3689, interior, 1011);
	else if(checkpointid == checkpoint[sexShop][1])
		return SetPlayerPosEx(playerid, -100.3775, -22.7395, 1000.7188, 0.3689, interior, 1012);
	else if(checkpointid == checkpoint[sexShop][2])
		return SetPlayerPosEx(playerid, -100.3775, -22.7395, 1000.7188, 0.3689, interior, 1013);
	else if(checkpointid == checkpoint[binco])
		return SetPlayerPosEx(playerid, 207.6928, -108.5880, 1005.1328, 357.5952, interior, 1014);
	else if(checkpointid == checkpoint[gym])
		return SetPlayerPosEx(playerid, 772.2314, -3.0801, 1000.7295, 1.7820, interior, 1015);
	else if(checkpointid == checkpoint[alhambra])
		return SetPlayerPosEx(playerid, 493.4344, -22.3562, 1000.6797, 0.1342, interior, 1016);
	else if(checkpointid == checkpoint[barberSalon][0])
		return SetPlayerPosEx(playerid, 418.6306, -82.4745, 1001.8047, 359.1790, interior, 1017);
	else if(checkpointid == checkpoint[barberSalon][1])
		return SetPlayerPosEx(playerid, 412.0573, -52.0658, 1001.8984, 358.8813, interior, 1018);
	else if(checkpointid == checkpoint[tattooParlour][0])
		return SetPlayerPosEx(playerid, -204.2249, -25.3435, 1002.2734, 292.3571, interior, 1019);
	else if(checkpointid == checkpoint[tattooParlour][1])
		return SetPlayerPosEx(playerid, -204.2249, -25.3435, 1002.2734, 292.3571, interior, 1020);
	else if(checkpointid == checkpoint[wellStackedPizza])
		return SetPlayerPosEx(playerid, 370.8942, -131.6681, 1001.4922, 0.5160, interior, 1021);
	else if(checkpointid == checkpoint[xoomer][0])
		return SendClientMessage(playerid, COLOUR_GREY, "Xoomer is currently closed.");
	else if(checkpointid == checkpoint[xoomer][1])
		return SendClientMessage(playerid, COLOUR_GREY, "Xoomer is currently closed.");
	else if(checkpointid == checkpoint[subUrban])
		return SetPlayerPosEx(playerid, 203.8786, -48.0519, 1001.8047, 357.6732, interior, 1024);
	else if(checkpointid == checkpoint[pigPen])
		return SetPlayerPosEx(playerid, 1205.6206, -9.2782, 1000.9219, 302.9438, interior, 1025);
	else if(checkpointid == checkpoint[ammunation][0])
		return SetPlayerPosEx(playerid, 286.9014, -39.0733, 1001.5156, 304.0519, interior, 1026);
	else if(checkpointid == checkpoint[ammunation][1])
		return SendClientMessage(playerid, COLOUR_GREY, "Ammunation is currently closed.");
	else if(checkpointid == checkpoint[bigS])
		return SendClientMessage(playerid, COLOUR_GREY, "Big S Liquor & Deli is currently closed.");
	else if(checkpointid == checkpoint[burgerShot][0])
		return SetPlayerPosEx(playerid, 364.9047, -73.7819, 1001.5078, 302.1413, interior, 1029);
	else if(checkpointid == checkpoint[burgerShot][1])
		return SetPlayerPosEx(playerid, 364.9047, -73.7819, 1001.5078, 302.1413, interior, 1030);
	else if(checkpointid == checkpoint[jimsStickyRing])
		return SetPlayerPosEx(playerid, 378.2261, -191.3923, 1000.6328, 358.5876, interior, 1031);
	else if(checkpointid == checkpoint[cityHall])
		return SetPlayerPosEx(playerid, 387.6645, 173.7492, 1008.3828, 91.3328, interior, 1032);
	else if(checkpointid == checkpoint[lspd])
		return SendClientMessage(playerid, COLOUR_GREY, "The Los Santos Police Department is currently closed.");
	else if(checkpointid == checkpoint[didierSachs])
		return SetPlayerPosEx(playerid, 204.3693, -166.2919, 1000.5234, 357.8517, interior, 1034);
	else if(checkpointid == checkpoint[prolaps])
		return SetPlayerPosEx(playerid, 207.0309, -137.4387, 1003.0938, 359.1638, interior, 1035);
	else if(checkpointid == checkpoint[victim])
		return SetPlayerPosEx(playerid, 224.4629, -8.1687, 1002.2109, 89.9059, interior, 1036);
    return 1;
}

public OnPlayerText(playerid, text[]) {
    if (player[playerid][muteTime] > 0) return 0;

    /*
    *   CHAT MESSAGE FILTER
    */
    // ...
    new message[192];
    format(message, sizeof(message), "%s", text);

    new string_playerText[159];
    format(string_playerText, sizeof(string_playerText), "{%06x}%s(%d): {FFFFFF}%s", GetPlayerColor(playerid)>>>8, PlayerName(playerid), playerid, message);
    SendClientMessageToAll(COLOUR_WHITE, string_playerText);
    return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success) {
    if (!success) {
        new i = strfind(cmdtext, " "),
            cmd[31];

        if (i != -1) strmid(cmd, cmdtext, 0, i, sizeof(cmd));
        else strcat(cmd, cmdtext);

        new string_cmdPerformed[72];
        format(string_cmdPerformed, sizeof(string_cmdPerformed), "[SERVER] {FFFFFF}The command '%s' does not exist.", cmd);
		SendClientMessage(playerid, COLOUR_RED, string_cmdPerformed);
    }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch (dialogid) {
        case DIALOG_REGISTER: {
            if (!response) return Kick(playerid);

            if (strlen(inputtext) < 8) {
                new string_title[64],
                    string_dialogRegister[84];

                format(string_title, sizeof(string_title), "%s - Account Registration", SERVER_NAME);
                format(string_dialogRegister, sizeof(string_dialogRegister), "{FF0000}Your password must be at least 8 " \
                    "characters long!\n\n{FFFFFF}This account is not registered. Please enter a password into the field below " \
                    "to begin the registration process.");
                return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, string_title, string_dialogRegister, "Continue", "Quit");
            }

            bcrypt_hash(inputtext, BCRYPT_COST, "OnPasswordHashed", "d", playerid);
        }
        case DIALOG_LOGIN: {
            if (!response) return Kick(playerid);

            if (strlen(inputtext) < 8) {
                new string_title[64],
                    string_dialogLogin[84];

                format(string_title, sizeof(string_title), "%s - Account Login", SERVER_NAME);
                format(string_dialogLogin, sizeof(string_dialogLogin), "{FF0000}Your password must be at least 8 " \
                    "characters long!\n\n{FFFFFF}This account is registered. Please enter your password into the field " \
                    "below to login.");
                return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, string_title, string_dialogLogin, "Login", "Quit");
            }

            bcrypt_check(inputtext, player[playerid][bcryptHash],  "OnPasswordChecked", "d", playerid);
        }
        case DIALOG_PWRESET_START: {
            if (!response) return Kick(playerid);

            new string_title[64],
                string_dialogRecover[124];

            format(string_title, sizeof(string_title), "%s - Account Recovery", SERVER_NAME);
            format(string_dialogRecover, sizeof(string_dialogRecover), "Recovery Options\n" \
                "Send Recovery Email\tso*****il@g***l.com\n" \
                "Answer Security Questions\n" \
                "Contact An Administrator");
            return ShowPlayerDialog(playerid, DIALOG_PWRESET_OPTIONS, DIALOG_STYLE_TABLIST_HEADERS, string_title, string_dialogRecover, "Select", "Quit");
        }
        case DIALOG_PWRESET_OPTIONS: {
            if (!response) return Kick(playerid);

            new string_title[64],
                string_dialogRecover[200];

            switch (listitem) {
                case 0: { // Send Recovery Email
                    format(string_title, sizeof(string_title), "%s - Account Recovery - Email Recovery", SERVER_NAME);
                    format(string_dialogRecover, sizeof(string_dialogRecover), "Email Recovery\n\n" \
                        "Your email address is %s\n\n" \
                        "If this is incorrect, please contact support for assistance.", player[playerid][email]);
                    return ShowPlayerDialog(playerid, DIALOG_PWRESET_EMAIL, DIALOG_STYLE_MSGBOX, string_title, string_dialogRecover, "Recover", "Back");
                }
                case 1: { // Answer Security Questions
                    new randomQ;

                    for (new i = 0; i < NUM_SECURITY_QUESTIONS; i ++) {
                        randomQ = player[playerid][securityQ][random(NUM_SECURITY_QUESTIONS)];

                        if (player[playerid][lastQ] != randomQ) {
                            player[playerid][lastQ] = randomQ;
                            break;
                        }
                    }

                    format(string_title, sizeof(string_title), "%s - Account Recovery - Security Questions", SERVER_NAME);
                    format(string_dialogRecover, sizeof(string_dialogRecover), "Security Questions\n\n" \
                        "%s", player[playerid][lastQ]);
                    return ShowPlayerDialog(playerid, DIALOG_PWRESET_QUESTIONS, DIALOG_STYLE_INPUT, string_title, string_dialogRecover, "Submit", "Back");
                }
                case 2: { // Contact An Administrator
                    format(string_title, sizeof(string_title), "%s - Account Recovery - Contact Support", SERVER_NAME);
                    format(string_dialogRecover, sizeof(string_dialogRecover), "Contact Support\n\n" \
                        "");
                    return ShowPlayerDialog(playerid, DIALOG_PWRESET_SUPPORT, DIALOG_STYLE_MSGBOX, string_title, string_dialogRecover, "Recover", "Back");
                }
            }
        }
        case DIALOG_PWRESET_EMAIL: {
            if (!response) return ReturnToRecoveryOptions(playerid);


        }
        case DIALOG_PWRESET_QUESTIONS: {
            if (!response) return ReturnToRecoveryOptions(playerid);


        }
        case DIALOG_PWRESET_SUPPORT: {
            if (!response) return ReturnToRecoveryOptions(playerid);


        }
    }
    return 1;
}

forward OnPasswordHashed(playerid);
public OnPasswordHashed(playerid) {
    new hash[BCRYPT_HASH_LENGTH],
        sql[230];
    bcrypt_get_hash(hash);

    mysql_format(db_handle, sql, sizeof(sql), "INSERT INTO users (username, password, first_ip, last_ip, lastLogin, " \
        "money) VALUES ('%e', '%s', '%s', first_ip, %d, %d)", PlayerName(playerid), hash, GetPlayerIpAddress(playerid), player[playerid][lastLogin], START_MONEY);
    mysql_tquery(db_handle, sql, "OnPlayerRegister", "d", playerid);
    return 1;
}

forward OnPasswordChecked(playerid);
public OnPasswordChecked(playerid) {
    new bool:match = bcrypt_is_equal();
    new currentTime = gettime();

    if (match == true) { // Login successful
        player[playerid][authenticated] = true;
        player[playerid][lastLogin] = currentTime;
        player[playerid][adminLevel] = cache_get_field_content_int(0, "adminLevel");
        SetPlayerTimeFormat(playerid, cache_get_field_content_int(0, "timeFormat"));
        SetPlayerMoney(playerid, cache_get_field_content_int(0, "money"));
        player[playerid][money_bank] = cache_get_field_content_int(0, "money_bank");
        player[playerid][jailTime] = cache_get_field_content_int(0, "jailTime");
        player[playerid][muteTime] = cache_get_field_content_int(0, "muteTime");
    }
    else { // Login failure
        player[playerid][loginAttempts] += 1;

        if (player[playerid][loginAttempts] >= MAX_LOGIN_ATTEMPTS) { // Login attempts exceeded the MAX_LOGIN_ATTEMPTS
            player[playerid][securityLock] = (currentTime + ACCOUNT_LOCK_TIME);
            LockAccount(playerid);
        }
    }

    format(player[playerid][bcryptHash], BCRYPT_HASH_LENGTH, "");
    return 1;
}

forward OnPlayerRegister(playerid);
public OnPlayerRegister(playerid) {
    if (cache_affected_rows() > 0) { // Registration successful
        player[playerid][authenticated] = true;
        SetPlayerMoney(playerid, START_MONEY);
        SetPlayerTimeFormat(playerid, TIME_DISPLAY_DEFAULT);
    } else { // Registration failure
        new string_title[64],
            string_playerRegister[200];

        format(string_title, sizeof(string_title), "%s - Account Registration", SERVER_NAME);
        format(string_playerRegister, sizeof(string_playerRegister), "{FF0000}There was an issue registering your account. " \
        "Please try again.\n\n{FFFFFF}This account is not registered. Please enter a password into the field below " \
            "to begin the registration process.");
        return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, string_title, string_playerRegister, "Continue", "Quit");
    }
    return 1;
}

forward OnPlayerDataUpdate(playerid);
public OnPlayerDataUpdate(playerid) {
    if (cache_affected_rows() > 0) { // Query success
        player[playerid][lastSave] = gettime();
    }
    else { // Query failure
        new string_playerDataUpdate[90];

        foreach(Player, i) {
            if (player[i][adminLevel] >= ADMIN_LEVEL_MOD) {
                format(string_playerDataUpdate, sizeof(string_playerDataUpdate), "[ADMIN] {FF0000}Database Error : " \
                    "{FFFFFF}Please contact an administrator. Error code: %d", ERROR_CODE_NOSAVE);
                SendClientMessage(i, COLOUR_LIGHTPURPLE, string_playerDataUpdate);
            }
        }
    }
    return 1;
}

forward OnAccountLock(playerid);
public OnAccountLock(playerid) {
    new string_accountLock[128];

    if (cache_affected_rows() == 0) { // Query failure
        foreach(Player, i) {
            if (player[i][adminLevel] >= ADMIN_LEVEL_MOD) {
                format(string_accountLock, sizeof(string_accountLock), "[ADMIN] {FF0000}Database Error : " \
                    "{FFFFFF}Please contact an administrator. Error code: %d", ERROR_CODE_NOSAVE_USERLOCK);
                SendClientMessage(i, COLOUR_LIGHTPURPLE, string_accountLock);
            }
        }
    }

    format(string_accountLock, sizeof(string_accountLock), "[SERVER] You have exceeded the maximum login attempts. " \
        "Your account has been temporarily locked for your security.");
    SendClientMessage(playerid, COLOUR_RED, string_accountLock);
    Kick(playerid);
    return 1;
}

public OnQueryError(errorid, error[], callback[], query[], connectionHandle) {
    new string_queryError[145];

    switch (errorid) {
        case CR_SERVER_GONE_ERROR: {
            reconnectAttempts += 1;

            if (reconnectAttempts == MAX_DB_RECONNECT_ATTEMPTS) {
                printf("[SERVER] Database Error : Connection lost. Exceeded maximum reconnect attempts (%d). Error code: %d", \
                    MAX_DB_RECONNECT_ATTEMPTS, ERROR_CODE_LOSTCONNECTION);
                format(string_queryError, sizeof(string_queryError), "[ADMIN] {FF0000}Database Error : " \
                    "{FFFFFF}Connection lost. Exceeded maximum reconnect attempts. Please contact an administrator. " \
                    "Error code: %d", ERROR_CODE_LOSTCONNECTION);
            }
            else {
                printf("[SERVER] Database Error : Connection lost. Attempting to reconnect (%d/%d). Error code: %d", \
                    reconnectAttempts, MAX_DB_RECONNECT_ATTEMPTS, ERROR_CODE_LOSTCONNECTION);
                format(string_queryError, sizeof(string_queryError), "[ADMIN] {FF0000}Database Error : " \
                    "{FFFFFF}Connection lost. Attempting to reconnect (%d/%d).", reconnectAttempts, MAX_DB_RECONNECT_ATTEMPTS);

                mysql_reconnect(db_handle);
            }

            foreach(Player, i) {
                if (player[i][adminLevel] >= ADMIN_LEVEL_MOD) {
                    SendClientMessage(i, COLOUR_LIGHTPURPLE, string_queryError);
                }
            }
        }
        case ER_SYNTAX_ERROR: {
            printf("[SERVER] Database Error : There is a syntax error in query %s", query);
        }
    }
    return 1;
}


/*                                      *
*               COMMANDS                *
*                                       */

CMD:setmoney(playerid, params[]) {
    SetPlayerMoney(playerid, 999999999);
    return 1;
}

CMD:respawn(playerid, params[]) {
    if (player[playerid][spawned] == false) return
        SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be spawned to use '/respawn'.");
    if (player[playerid][wantedLevel] > 0) return
        SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't use '/respawn' while wanted.");
    if (player[playerid][inCombat] == true) return
        SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't use '/respawn' while in combat.");

    SetPlayerHealth(playerid, 0);

    new string_cmd_respawn[62];
    format(string_cmd_respawn, sizeof(string_cmd_respawn), "%s(%d) has respawned using '/respawn'.", PlayerName(playerid), playerid);
    SendClientMessageToAll(COLOUR_GREY, string_cmd_respawn);
    return 1;
}

CMD:clock(playerid, params[]) {
    if (player[playerid][timeFormat] == TIME_DISPLAY_DEFAULT) {
        SetPlayerTimeFormat(playerid, TIME_DISPLAY_SHOW_AMPM);
        SendClientMessage(playerid, COLOUR_WHITE, "[SERVER] Your time display has been changed to 12 hour format (am/pm).");
    }
    else {
        SetPlayerTimeFormat(playerid, TIME_DISPLAY_DEFAULT);
        SendClientMessage(playerid, COLOUR_WHITE, "[SERVER] Your time display has been changed to 24 hour format.");
    }
}

CMD:locate(playerid, params[]) {
    if (player[playerid][spawned] == false) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be spawned to use '/loc(ate)'.");

	new targetid;
	if (sscanf(params, "u", targetid)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/loc(ate) [ Player ]");
	if (!IsPlayerConnected(targetid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you are trying to locate does not exist.");
	if (playerid == targetid) return
		SendClientMessage(playerid, COLOUR_WHITE, "Are you lost? Your location is displayed below the radar.");

	new loc[28],
		string_cmd_locate[66];
	GetPlayerLocation(targetid, loc, 28);
	format(string_cmd_locate, sizeof(string_cmd_locate), "%s(%d) is located at %s.", PlayerName(targetid), targetid, loc);
	SendClientMessage(playerid, COLOUR_WHITE, string_cmd_locate);
	return 1;
}

CMD:loc(playerid, params[]) return cmd_locate(playerid, params);

CMD:gc(playerid, params[]) {
	if (player[playerid][spawned] == false) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be spawned to use '/gc'.");

	new targetid,
        amount,
        string_cmd_givecash[80];
	if (sscanf(params, "ud", targetid, amount)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/gc [ Player ] [ Amount ]");
	if (targetid == INVALID_PLAYER_ID) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you are trying to give money to does not exist.");
	if (playerid == targetid) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't send money to yourself.");
	if (player[targetid][spawned] == false) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can only send money to someone that is spawned.");
	if (!IsPlayerNearPlayer(playerid, targetid)) {
		format(string_cmd_givecash, sizeof(string_cmd_givecash), "Error: {FFFFFF}You must be near %s(%d) to send money.", PlayerName(targetid), targetid);
		return SendClientMessage(playerid, COLOUR_RED, string_cmd_givecash);
	}
	if ((amount < 0) || (amount > 10000)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can only send between $1 and $10,000.");

    new playerMoney = GetPlayerMoneyEx(playerid);
    if (playerMoney < amount) {
        format(string_cmd_givecash, sizeof(string_cmd_givecash), "Error: {FFFFFF}You don't have $%d to send. Your current balance is $%d.", amount, playerMoney);
        return SendClientMessage(playerid, COLOUR_RED, string_cmd_givecash);
    }

	GivePlayerMoneyEx(targetid, amount);
	TakePlayerMoney(playerid, amount);

	format(string_cmd_givecash, sizeof(string_cmd_givecash), "You have given $%d to %s(%d).", amount, PlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOUR_GREEN, string_cmd_givecash);

	format(string_cmd_givecash, sizeof(string_cmd_givecash), "%s(%d) has given you $%d.", PlayerName(playerid), playerid, amount);
	SendClientMessage(targetid, COLOUR_GREEN, string_cmd_givecash);
	return 1;
}

CMD:mute(playerid, params[]) {
	if (player[playerid][adminLevel] < ADMIN_CMD_MUTE) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/mute'.");

	new targetid,
        time,
        reason[21],
        string_cmd_mute[86];
	if (sscanf(params, "uds[21](no reason)", targetid, time, reason)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/mute [ Player ] [ Time ] [ Reason " \
			"(Optional) ]  -- {A5A5A5}'/mute help' for more info");
	if (!IsPlayerConnected(targetid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you tried to mute does not exist.");
	if (playerid == targetid) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't mute yourself.");
	if (player[targetid][adminLevel] >= player[playerid][adminLevel]) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't mute a staff member of equal or higher level.");
	if (player[targetid][muteTime] > 0) {
		format(string_cmd_mute, sizeof(string_cmd_mute), "Error: {FFFFFF}%s(%d) is already muted.", PlayerName(targetid), targetid);
		return SendClientMessage(playerid, COLOUR_RED, string_cmd_mute);
	}
	if ((time < 60) && (time != -1)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The 'time' must be 60 seconds and above.");
	if (time > 3600) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The 'time' must be 3600 seconds and below.");

	player[targetid][muteTime] = time;

	format(string_cmd_mute, sizeof(string_cmd_mute), "[ADMIN] {FFFFFF}%s(%d) has been muted for %s.", PlayerName(targetid), targetid, reason);
	SendClientMessageToAll(COLOUR_LIGHTPURPLE, string_cmd_mute);
	return 1;
}

CMD:unmute(playerid, params[]) {
	if (player[playerid][adminLevel] < ADMIN_CMD_UNMUTE) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/unmute'.");

	new targetid,
        string_cmd_unmute[63];
	if (sscanf(params, "u", targetid)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/unmute [ Player ]");
	if (!IsPlayerConnected(targetid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you tried to unmute does not exist.");
	if (playerid == targetid) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't unmute yourself.");
	if (player[targetid][adminLevel] >= player[playerid][adminLevel]) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't unmute a staff member of equal or higher level.");
	if (player[targetid][muteTime] == 0) {
		format(string_cmd_unmute, sizeof(string_cmd_unmute), "Error: {FFFFFF}%s(%d) is not muted.", PlayerName(targetid), targetid);
		return SendClientMessage(playerid, COLOUR_RED, string_cmd_unmute);
	}

	player[targetid][muteTime] = 0;

	format(string_cmd_unmute, sizeof(string_cmd_unmute), "[ADMIN] {FFFFFF}%s(%d) has been unmuted.", PlayerName(targetid), targetid);
	SendClientMessageToAll(COLOUR_LIGHTPURPLE, string_cmd_unmute);
	return 1;
}

CMD:jail(playerid, params[]) {
	if (player[playerid][adminLevel] < ADMIN_CMD_JAIL) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/jail'.");

	new targetid,
        time,
        reason[21],
        string_cmd_jail[86];
	if (sscanf(params, "uds[21](no reason)", targetid, time, reason)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/jail [ Player ] [ Time ] [ Reason " \
			"(Optional) ]  -- {A5A5A5}'/jail help' for more info");
	if (!IsPlayerConnected(targetid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you tried to jail does not exist.");
	if (playerid == targetid) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't jail yourself.");
	if (player[targetid][adminLevel] >= player[playerid][adminLevel]) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't jail a staff member of equal or higher level.");
	if (player[targetid][inAdminJail]) {
		format(string_cmd_jail, sizeof(string_cmd_jail), "Error: {FFFFFF}%s(%d) is already in jail.", PlayerName(targetid), targetid);
		return SendClientMessage(playerid, COLOUR_RED, string_cmd_jail);
	}
	if (time < 60) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The 'time' must be 60 seconds and above.");
	if (time > 600) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The 'time' must be 600 seconds and below.");

	player[targetid][jailTime] = time;

	format(string_cmd_jail, sizeof(string_cmd_jail), "[ADMIN] {FFFFFF}%s(%d) has been jailed for %s.", PlayerName(targetid), targetid, reason);
	SendClientMessageToAll(COLOUR_LIGHTPURPLE, string_cmd_jail);
	return 1;
}

CMD:unjail(playerid, params[]) {
	if (player[playerid][adminLevel] < ADMIN_CMD_UNJAIL) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/unjail'.");

	new targetid,
        string_cmd_unjail[64];
	if (sscanf(params, "u", targetid)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/unjail [ Player ]");
	if (!IsPlayerConnected(targetid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you tried to unjail does not exist.");
	if (playerid == targetid) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't unjail yourself.");
	if (player[targetid][adminLevel] >= player[playerid][adminLevel]) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't unjail a staff member of equal or higher level.");
	if (!player[targetid][inAdminJail]) {
		format(string_cmd_unjail, sizeof(string_cmd_unjail), "Error: {FFFFFF}%s(%d) is not in jail.", PlayerName(targetid), targetid);
		return SendClientMessage(playerid, COLOUR_RED, string_cmd_unjail);
	}

	player[targetid][jailTime] = 0;

	format(string_cmd_unjail, sizeof(string_cmd_unjail), "[ADMIN] {FFFFFF}%s(%d) has been unjailed.", PlayerName(targetid), targetid);
	SendClientMessageToAll(COLOUR_LIGHTPURPLE, string_cmd_unjail);
	return 1;
}

CMD:kick(playerid, params[]) {
	if (player[playerid][adminLevel] < ADMIN_CMD_KICK) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/kick'.");

	new targetid,
        reason[21],
        string_cmd_kick[87];
	if (sscanf(params, "us[21](no reason)", targetid, reason)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/kick [ Player ] [ Reason (Optional) ]" \
			"  -- {A5A5A5}'/kick help' for more info");
	if (!IsPlayerConnected(targetid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The player you tried to kick does not exist.");
	if (playerid == targetid) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't kick yourself.");
	if (player[targetid][adminLevel] >= player[playerid][adminLevel]) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You can't kick a staff member of equal or higher level.");

	format(string_cmd_kick, sizeof(string_cmd_kick), "[ADMIN] {FFFFFF}%s(%d) has been kicked for %s.", PlayerName(targetid), targetid, reason);
	SendClientMessageToAll(COLOUR_LIGHTPURPLE, string_cmd_kick);

	Kick(targetid);
	return 1;
}

CMD:v(playerid, params[]) {
    if (player[playerid][spawned] == false) return
        SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be spawned to use '/v'.");
	if (player[playerid][adminLevel] < ADMIN_CMD_V) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You do not have permission to use '/v'.");
	if (IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You cannot use '/v' if you're already in a vehicle.");

	new modelid;
	if (sscanf(params, "d", modelid)) return
		SendClientMessage(playerid, COLOUR_SYNTAX, "Syntax: {FFFFFF}/v [ Model ]");
	if ((modelid < 400) || (modelid > 611)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}Invalid vehicle model.");

	new Float:playerPos[4],
		vehicleid,
		string_cmd_v[40];
	GetPlayerPos(playerid, playerPos[0], playerPos[1], playerPos[2]);
	GetPlayerFacingAngle(playerid, playerPos[3]);

	vehicleid = CreateVehicleEx(modelid, playerPos[0], playerPos[1], playerPos[2], playerPos[3], -1, -1, -1);
	PutPlayerInVehicle(playerid, vehicleid, 0);

	switch (IsVehicleModelNameAn(modelid)) {
		case 0: format(string_cmd_v, sizeof(string_cmd_v), "You have spawned a %s.", GetVehicleModelName(modelid));
		case 1: format(string_cmd_v, sizeof(string_cmd_v), "You have spawned an %s.", GetVehicleModelName(modelid));
	}

	SendClientMessage(playerid, COLOUR_GREY, string_cmd_v);
	return 1;
}

CMD:engine(playerid, params[]) {
    if (player[playerid][spawned] == false) return
        SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be spawned to use '/engine'.");
	if (!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/engine'");
	if (GetPlayerVehicleSeat(playerid) != 0) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/engine'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch (vehicle[vehicleid][engine]) {
		case false: SetVehicleParamsEx_Fixed(vehicleid, true, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
		case true: SetVehicleParamsEx_Fixed(vehicleid, false, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
	}
	return 1;
}

CMD:lights(playerid, params[]) {
    if (player[playerid][spawned] == false) return
        SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be spawned to use '/lights'.");
	if (!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/lights'");
	if (GetPlayerVehicleSeat(playerid) != 0) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/lights'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch (vehicle[vehicleid][lights]) {
		case false: SetVehicleParamsEx_Fixed(vehicleid, vengine, true, valarm, vdoors, vbonnet, vboot, vobjective);
		case true: SetVehicleParamsEx_Fixed(vehicleid, vengine, false, valarm, vdoors, vbonnet, vboot, vobjective);
	}
	return 1;
}

CMD:alarm(playerid, params[]) {
    if (player[playerid][spawned] == false) return
        SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be spawned to use '/alarm'.");
	if (!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/alarm'");
	if (GetPlayerVehicleSeat(playerid) != 0) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/alarm'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch (vehicle[vehicleid][alarm]) {
		case false: SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, true, vdoors, vbonnet, vboot, vobjective);
		case true: SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, false, vdoors, vbonnet, vboot, vobjective);
	}
	return 1;
}

CMD:hood(playerid, params[]) {
    if (player[playerid][spawned] == false) return
        SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be spawned to use '/hood'.");
	if (!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/hood'");
	if (GetPlayerVehicleSeat(playerid) != 0) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/hood'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch (vehicle[vehicleid][hood]) {
		case false: SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, true, vboot, vobjective);
		case true: SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, false, vboot, vobjective);
	}
	return 1;
}

CMD:trunk(playerid, params[]) {
    if (player[playerid][spawned] == false) return
        SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be spawned to use '/trunk'.");
	if (!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/trunk'");
	if (GetPlayerVehicleSeat(playerid) != 0) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/trunk'");

	new vehicleid = GetPlayerVehicleID(playerid),
		vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);

	switch (vehicle[vehicleid][trunk]) {
		case false: SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, true, vobjective);
		case true: SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, false, vobjective);
	}
	return 1;
}

CMD:lock(playerid, params[]) {
    if (player[playerid][spawned] == false) return
        SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be spawned to use '/lock'.");
	if (!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/lock'");
	if (GetPlayerVehicleSeat(playerid) != 0) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/lock'");

	new vehicleid = GetPlayerVehicleID(playerid);
	if(vehicle[vehicleid][locked] == true) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The vehicle you're driving is already locked.");

	new vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
	SetVehicleParamsEx(vehicleid, vengine, vlights, valarm, true, vbonnet, vboot, vobjective);

	vehicle[vehicleid][locked] = true;
	SendClientMessage(playerid, COLOUR_GREY, "You have locked your vehicle.");
	return 1;
}

CMD:unlock(playerid, params[]) {
    if (player[playerid][spawned] == false) return
        SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be spawned to use '/unlock'.");
	if (!IsPlayerInAnyVehicle(playerid)) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be in a vehicle to use '/unlock'");
	if (GetPlayerVehicleSeat(playerid) != 0) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}You must be driving the vehicle to use '/unlock'");

	new vehicleid = GetPlayerVehicleID(playerid);
	if (vehicle[vehicleid][locked] == false) return
		SendClientMessage(playerid, COLOUR_RED, "Error: {FFFFFF}The vehicle you're driving is already unlocked.");

	new vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
	SetVehicleParamsEx(vehicleid, vengine, vlights, valarm, false, vbonnet, vboot, vobjective);

	vehicle[vehicleid][locked] = false;
	SendClientMessage(playerid, COLOUR_GREY, "You have unlocked your vehicle.");
	return 1;
}



/*
*   FUNCTIONS :: REQUIRED FOR PROPER FUNCTIONALITY
*/

stock UpdatePlayerData(playerid) {
    new sql[154];
    mysql_format(db_handle, sql, sizeof(sql), "UPDATE users SET timeFormat=%d,adminLevel=%d,money=%d,money_bank=%d," \
        "jailTime=%d,muteTime=%d WHERE username='%s'", PlayerName(playerid));
    mysql_tquery(db_handle, sql, "OnPlayerDataUpdate", "d", playerid);
    return 1;
}

stock LockAccount(playerid) {
    new sql[154];
    mysql_format(db_handle, sql, sizeof(sql), "UPDATE users SET securityLock=%d WHERE username='%s'", player[playerid][securityLock], PlayerName(playerid));
    mysql_tquery(db_handle, sql, "OnAccountLock", "d", playerid);
    return 1;
}

stock ClearPlayerConfig(playerid) {
    player[playerid][connectionTime] = 0;
    player[playerid][lastLogin] = 0;
    player[playerid][lastSave] = 0;
    player[playerid][securityLock] = 0;
    player[playerid][authenticated] = false;
    player[playerid][loginAttempts] = 0;
    format(player[playerid][email], MAX_EMAIL_LENGTH, "");
    player[playerid][spawned] = false;
    player[playerid][banned] = false;
    player[playerid][timeFormat] = TIME_DISPLAY_DEFAULT;
    player[playerid][inVehicleID] = 0;
    player[playerid][adminLevel] = 0;
    player[playerid][wantedLevel] = 0;
    SetPlayerMoney(playerid, 0);
    player[playerid][money_bank] = 0;
    player[playerid][inCombat] = false;
    player[playerid][handcuffed] = false;
    player[playerid][jailTime] = 0;
    player[playerid][inAdminJail] = false;
    player[playerid][muteTime] = 0;
    return 1;
}

stock ReturnToRecoveryOptions(playerid) {
    new string_title[64],
        string_recoveryOptions[MAX_EMAIL_LENGTH];

    format(string_title, sizeof(string_title), "%s - Account Recovery", SERVER_NAME);
    format(string_recoveryOptions, sizeof(string_recoveryOptions), "Recovery Options\n" \
        "Send Recovery Email\tso*****il@g***l.com\n" \
        "Answer Security Questions\n" \
        "Contact An Administrator");
    return ShowPlayerDialog(playerid, DIALOG_PWRESET_OPTIONS, DIALOG_STYLE_TABLIST_HEADERS, string_title, string_recoveryOptions, "Select", "Back");
}

stock PlayerName(playerid) {
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	return name;
}

stock GetPlayerIpAddress(playerid) {
    new ip_address[16];
    GetPlayerIp(playerid, ip_address, 16);
    return ip_address;
}

stock SetPlayerTimeFormat(playerid, mode) {
	player[playerid][timeFormat] = mode;

	switch (mode) {
		case TIME_DISPLAY_DEFAULT: {
			TextDrawHideForPlayer(playerid, Text:textdraw_time_ampm);
			TextDrawHideForPlayer(playerid, Text:textdraw_ampm);
			TextDrawShowForPlayer(playerid, Text:textdraw_time_default);
		}
		case TIME_DISPLAY_SHOW_AMPM: {
			TextDrawHideForPlayer(playerid, Text:textdraw_time_default);
			TextDrawShowForPlayer(playerid, Text:textdraw_time_ampm);
			TextDrawShowForPlayer(playerid, Text:textdraw_ampm);
		}
	}
	return 1;
}

stock GetPlayerLocation(playerid, locname[], len) {
	new Float:player_pos[3];
	GetPlayerPos(playerid, player_pos[0], player_pos[1], player_pos[2]);

	for (new i = 0; i != sizeof(locations); i ++) {
		if (player_pos[0] >= locations[i][locArea][0] && player_pos[0] <= locations[i][locArea][3] &&
			player_pos[1] >= locations[i][locArea][1] && player_pos[1] <= locations[i][locArea][4]) return
			format(locname, len, locations[i][locName], 0);
	}
	return 0;
}

stock SetPlayerPosEx(playerid, Float:x, Float:y, Float:z, Float:a, interior, virtual_world) {
	SetPlayerPos(playerid, x, y, z);
	SetPlayerFacingAngle(playerid, a);
	SetPlayerInterior(playerid, interior);
	SetPlayerVirtualWorld(playerid, virtual_world);
	SetCameraBehindPlayer(playerid);
	return 1;
}

stock IsPlayerNearPlayer(playerid, targetid) {
	new Float:player_pos[3];
	GetPlayerPos(targetid, player_pos[0], player_pos[1], player_pos[2]);

	if (IsPlayerInRangeOfPoint(playerid, 2.5, player_pos[0], player_pos[1], player_pos[2])) return 1;
	return 0;
}

stock GetPlayerMoneyEx(playerid) return player[playerid][money];

stock GivePlayerMoneyEx(playerid, amount) {
	player[playerid][money] += amount;
	GivePlayerMoney(playerid, amount);
	return 1;
}

stock SetPlayerMoney(playerid, amount) {
	player[playerid][money] = amount;
	GivePlayerMoney(playerid, (-GetPlayerMoney(playerid)) + amount);
	return 1;
}

stock TakePlayerMoney(playerid, amount) {
	player[playerid][money] -= amount;
	GivePlayerMoney(playerid, -amount);
	return 1;
}

stock IsVehicleModelNameAn(modelid) {
	switch(modelid) {
		case 411, 416, 419, 427, 441, 445, 464, 465, 467, 490, 501, 507, 521, 522, 523, 528, 546, 562, 564, 577,
			585, 592, 594, 602: return 1;
	}
	return 0;
}

stock CreateStaticVehicleEx(modelid, Float:x, Float:y, Float:z, Float:rot, col1, col2, respawn_delay,
	bool:engine_param = true, bool:hood_param = false, bool:trunk_param = false) {
    if (!IsValidVehicleModel(modelid)) return 0;

	new vehicleid = AddStaticVehicleEx(modelid, x, y, z, rot, col1, col2, respawn_delay);
	vehicle[vehicleid][engine] = engine_param;
	vehicle[vehicleid][hood] = hood_param;
	vehicle[vehicleid][trunk] = trunk_param;

	new vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
	SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, hood_param, trunk_param, vobjective);
	return vehicleid;
}

stock CreateVehicleEx(modelid, Float:x, Float:y, Float:z, Float:rot, col1, col2, respawn_delay,
	bool:engine_param = true, bool:hood_param = false, bool:trunk_param = false) {
	if (!IsValidVehicleModel(modelid)) return 0;

	new vehicleid = CreateVehicle(modelid, x, y, z, rot, col1, col2, respawn_delay);
	vehicle[vehicleid][engine] = engine_param;
	vehicle[vehicleid][hood] = hood_param;
	vehicle[vehicleid][trunk] = trunk_param;

	new vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
	SetVehicleParamsEx_Fixed(vehicleid, vengine, vlights, valarm, vdoors, hood_param, trunk_param, vobjective);
	return vehicleid;
}

new timer_vehicleAlarm[MAX_VEHICLES];
stock SetVehicleParamsEx_Fixed(vehicleid, engine_param, lights_param, alarm_param, doors_param, hood_param, trunk_param, objective_param) {
	switch (engine_param) {
		case false: vehicle[vehicleid][engine] = false;
		case true: vehicle[vehicleid][engine] = true;
	}

	switch (lights_param) {
		case false: vehicle[vehicleid][lights] = false;
		case true: vehicle[vehicleid][lights] = true;
	}

	switch (alarm_param) {
		case false: vehicle[vehicleid][alarm] = false;
		case true: vehicle[vehicleid][alarm] = true;
	}

	switch (hood_param) {
		case false: vehicle[vehicleid][hood] = false;
		case true: vehicle[vehicleid][hood] = true;
	}

	switch (trunk_param) {
		case false: vehicle[vehicleid][trunk] = false;
		case true: vehicle[vehicleid][trunk] = true;
	}

	SetVehicleParamsEx(vehicleid, engine_param, lights_param, alarm_param, doors_param, hood_param, trunk_param, objective_param);

	if (alarm_param) {
		KillTimer(timer_vehicleAlarm[vehicleid]);
		timer_vehicleAlarm[vehicleid] = SetTimerEx("DisableVehicleAlarm", 20000, false, "d", vehicleid);
	}
	return 1;
}

forward DisableVehicleAlarm(vehicleid);
public DisableVehicleAlarm(vehicleid) {
	new vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective;
	GetVehicleParamsEx(vehicleid, vengine, vlights, valarm, vdoors, vbonnet, vboot, vobjective);
	SetVehicleParamsEx(vehicleid, vengine, vlights, false, vdoors, vbonnet, vboot, vobjective);
}

stock AddNeonToVehicle(vehicleid, neonid) {
	if ((vehicle[vehicleid][neon][0] != 0) || (vehicle[vehicleid][neon][1] != 0)) RemoveNeonFromVehicle(vehicleid);

	new modelid;
	switch (neonid) {
		case 0: modelid = 18647;
		case 1: modelid = 18648;
		case 2: modelid = 18649;
		case 3: modelid = 18650;
		case 4: modelid = 18651;
		case 5: modelid = 18652;
	}

	vehicle[vehicleid][neon][0] = CreateDynamicObject(modelid, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
	AttachDynamicObjectToVehicle(vehicle[vehicleid][neon][0], vehicleid, -0.5, 0.0, -0.5, 0.0, 0.0, 0.0);
	vehicle[vehicleid][neon][1] = CreateDynamicObject(modelid, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
	AttachDynamicObjectToVehicle(vehicle[vehicleid][neon][1], vehicleid, 0.5, 0.0, -0.5, 0.0, 0.0, 0.0);
	return 1;
}

stock RemoveNeonFromVehicle(vehicleid) {
    DestroyDynamicObject(vehicle[vehicleid][neon][0]);
    DestroyDynamicObject(vehicle[vehicleid][neon][1]);
    return 1;
}
