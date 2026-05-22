#ifndef LUX_WATER_SETTINGS_GLSL
#define LUX_WATER_SETTINGS_GLSL

// ---- LUX-style Water Waves (Lux Shader v1.2 by TechDevOnGithub) -------------
// Replaces EP's texture-based water normals with Lux's sin-wave + noise stack.
// Enable LUX_WATER_NORMALS (WATER_STYLE >= 2 required).
// Default values and option lists taken verbatim from Lux v1.2 settings.glsl.

// Gerstner wave stack
#define LUX_WAVE_SPEED       1.0   //[0.25 0.50 0.75 1.0 1.25 1.50 1.75 2.0]
#define LUX_WAVE_LENGTH     16.0   //[8.0 10.0 12.0 14.0 16.0 18.0 20.0 30.0 40.0]
#define LUX_WAVE_LACUNARITY  1.4   //[1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6]
#define LUX_WAVE_PERSISTENCE 0.93  //[0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99]
#define LUX_WAVE_AMPLITUDE   0.34  //[0.05 0.10 0.15 0.20 0.25 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40]
#define LUX_WAVE_DIR_SPREAD  0.42  //[0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.42 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define LUX_WAVE_ITERATIONS  5     //[0 1 2 3 4 5 6 7 8 9 10]

// Layered noise on top of wave stack
#define LUX_NOISE_SCALE      0.007 //[0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.01]
#define LUX_NOISE_LACUNARITY 0.7   //[0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5]
#define LUX_NOISE_AMPLITUDE  0.45  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8]
#define LUX_NOISE_PERSISTENCE 0.75 //[0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define LUX_NOISE_ITERATIONS 4     //[0 1 2 3 4 5 6 7 8 9 10]

// Depth absorption: red absorbs strongest → retains cold teal-blue at depth
#define LUX_MURKINESS        0.55  //[0.20 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.80]

#endif // LUX_WATER_SETTINGS_GLSL
