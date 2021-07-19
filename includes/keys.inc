/*
*   Key press types
*/

#define HOLDING(%0) \
        ((newkeys & (%0)) == (%0))
#define PRESSED(%0) \
        (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define PRESSING(%0,%1) \
        (%0 & (%1))
#define RELEASED(%0) \
        (((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))


/*
*   Key definitions
*/

#define KEY_AIM        128
