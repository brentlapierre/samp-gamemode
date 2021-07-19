#include <a_samp>

#define TEST_MSG "blah"

main() {
    new Float:minPercent = 15.5;
    new Float:maxPercent = 84.5;
    new Float:randFloat = randomfloat(minPercent, maxPercent);
    printf("%.4f", randFloat);
    print("this is a test: "TEST_MSG"_OK");
}

stock Float:randomfloat(Float:min, Float:max, &num_decimal = 4) {
    new Float:mul = floatpower(10.0, num_decimal),
        min_int = floatround(min * mul),
        max_int = floatround(max * mul);
    return float(random(max_int - min_int) + min_int) / mul;
}
