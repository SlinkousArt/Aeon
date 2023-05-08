#version 120


#define hueSteps 8 // the number of hues to use [2 4 8 16 32 64]
#define satSteps 4 // the number of saturations to use [2 4 8 16 32 64]
#define valSteps 4 // the number of lightnesses to use [2 4 8 16 32 64] 

//#define RGB // whether to use rgb or hsv [0 1]
#define rgbSteps 4 // the number of rgb values to use [2 4 8 16 32 64]

//#define BLACKEN // Whether or not to blackent the background

uniform sampler2D gcolor;

varying vec2 texcoord;

// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


const float steps = 4.0;

uniform vec3 palette[8];
uniform int paletteSize;

const int indexMatrix4x4[16] = int[](0,  8,  2,  10,
                                     12, 4,  14, 6,
                                     3,  11, 1,  9,
                                     15, 7,  13, 5);

const int indexMatrix2x2[4] = int[](0,  2,
								    3,  1);

const int indexMatrix8x8[64] = int[](0,  32, 8,  40, 2,  34, 10, 42,
                                     48, 16, 56, 24, 50, 18, 58, 26,
                                     12, 44, 4,  36, 14, 46, 6,  38,
                                     60, 28, 52, 20, 62, 30, 54, 22,
                                     3,  35, 11, 43, 1,  33, 9,  41,
                                     51, 19, 59, 27, 49, 17, 57, 25,
                                     15, 47, 7,  39, 13, 45, 5,  37,
                                     63, 31, 55, 23, 61, 29, 53, 21);

float indexValue() {
    int x = int(mod(gl_FragCoord.x, 4));
    int y = int(mod(gl_FragCoord.y, 4));
    return indexMatrix4x4[(x + y * 4)] / 16.0;
}


float hueDistance(float h1, float h2) {
    float diff = abs((h1 - h2));
    return min(abs((1.0 - diff)), diff);
}
vec3[2] closestColors(float hue) {
    vec3 ret[2];
    vec3 closest = vec3(-2, 0, 0);
    vec3 secondClosest = vec3(-2, 0, 0);
    vec3 temp;
    for (int i = 0; i < paletteSize; ++i) {
        temp = palette[i];
        float tempDistance = hueDistance(temp.x, hue);
        if (tempDistance < hueDistance(closest.x, hue)) {
            secondClosest = closest;
            closest = temp;
        } else {
            if (tempDistance < hueDistance(secondClosest.x, hue)) {
                secondClosest = temp;
            }
        }
    }
    ret[0] = closest;
    ret[1] = secondClosest;
    return ret;
}

float lightnessStep(float l, float lightnessSteps) {
    /* Quantize the lightness to one of `lightnessSteps` values */
    return floor((0.5 + l * (lightnessSteps - 1.0))) / (lightnessSteps - 1.0);
}

float dither(float color, float dithersteps) {
    float d = indexValue();

    float l1 = lightnessStep(max((color - 0.125), 0.0), dithersteps);
    float l2 = lightnessStep(min((color + 0.124), 1.0), dithersteps);
    float lightnessDiff = (color - l1) / (l2 - l1);

    float resultColor = (lightnessDiff < d) ? l1 : l2;
    return resultColor;
}

void main() {
	float mask;
	vec3 ogRGB = texture2D(gcolor, texcoord).rgb;
	vec3 ogHSV = rgb2hsv(ogRGB).xyz;
    float val = ogHSV.z;
    vec3 ditherhsv = hsv2rgb(vec3(dither(ogHSV.x, hueSteps), dither(ogHSV.y, satSteps), dither(ogHSV.z, valSteps))).rgb;
    vec3 nonditherhsv = hsv2rgb(vec3(lightnessStep(ogHSV.x, hueSteps), lightnessStep(ogHSV.y, satSteps), lightnessStep(ogHSV.z, valSteps))).rgb;
    vec3 ditherrgb = vec3(dither(ogRGB.r, rgbSteps), dither(ogRGB.g, rgbSteps), dither(ogRGB.b, rgbSteps)).rgb;
    vec3 nonditherrgb = vec3(lightnessStep(ogRGB.r, rgbSteps), lightnessStep(ogRGB.g, rgbSteps), lightnessStep(ogRGB.b, rgbSteps)).rgb;
    #ifdef RGB 
        vec3 final = ditherrgb;
    #else 
        vec3 final = ditherhsv;
    #endif
/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(vec3(final), 1.0); //gcolor
}

