#version 120

#define goalHue 40.0 // the desired hue to display [0 10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 220 230 240 250 260 270 280 290 300 310 320 330 340 350]
#define wiggle 20 // wiggle room [0 10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 220 230 240 250 260 270 280 290 300 310 320 330 340 350]
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

float dither(float color) {
    float closestColor = (color <= 0.5) ? 0 : 1;
    float secondClosestColor = 1 - closestColor;
    float d = indexValue();
    float distance = abs(closestColor - color);
    return (distance <= d) ? closestColor : secondClosestColor;
}

void main() {
	float mask;
	vec3 ogRGB = texture2D(gcolor, texcoord).rgb;
	vec3 ogHSV = rgb2hsv(ogRGB).xyz;
    float val = ogHSV.z;
	float val4 = floor(val * 4.0) / 4.0;
	vec3 valtest = hsv2rgb(vec3(0, 0, val4)).rgb;
	vec3 test64 = vec3((floor(ogRGB.r * 4.0) / 4.0), (floor(ogRGB.g * 4.0) / 4.0), (floor(ogRGB.b * 4.0) / 4.0)).rgb;
	vec3 test64hsv = hsv2rgb(vec3((floor(ogHSV.x * 4.0) / 4.0), (floor(ogHSV.y * 4.0) /4.0), (floor(ogHSV.z * 8.0) /8.0))).rgb;
	vec3 otherdithertest = hsv2rgb(vec3(0, 0, dither(float(val * 1.0)))).rgb;
	vec3 otherdithertest2 = hsv2rgb(vec3((floor(ogHSV.x * 8.0) / 8.0), (floor(ogHSV.y * 8.0) /8.0), dither(float(val * 2.0)))).rgb;

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(vec3(otherdithertest), 1.0); //gcolor
}

