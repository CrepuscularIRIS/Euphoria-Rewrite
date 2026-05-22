#ifndef END_NEBULA_SETTINGS_GLSL
#define END_NEBULA_SETTINGS_GLSL

// ---- Solas-like End Nebula + Black Hole (minecraft:the_end) ------------------
// All default values derived from Solas Shader V3.3 (Septonious).
// Source: shaders/lib/common.glsl of Solas V3.3
// Color channels use EP's float 0.00-1.00 convention (LIGHT_END_R=195 → 195/255=0.76).
// The sqrt-gamma encoding in endNebula.glsl then produces the same linear HDR value.

//#define END_NEBULA
#define END_BLACK_HOLE
//#define END_VOID_CLOUDS
//#define END_VOID_VORTEX

#define END_NEBULA_BRIGHTNESS 3.00 //[1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define END_BLACK_HOLE_SIZE   1.0  //[3.0 2.5 2.0 1.5 1.0 0.5 0.25]

// Disk tilt angle. Positive = tilt disk clockwise when viewed from above.
#define END_BLACK_HOLE_ANGLE 0.0 //[-0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5]

// Torus shaping exponent — Solas uses: 1.0 + (180.0 - abs(sunPathRotation)) / 8.0
// With Solas default SUN_ANGLE_END = -70: 1.0 + (180 - 70) / 8 = 14.75
#define END_DISK_TILT_FACTOR 14.75 //[5.0 6.25 7.5 8.75 10.0 11.25 12.5 13.75 14.75 15.0 16.25 17.5 18.75 20.0 22.5]

// Nebula first color (orange/gold) — Solas V3.3: LIGHT_END 208/132/44, I=2.60
// Float equivalents: 208/255=0.82, 132/255=0.52, 44/255=0.17
#define NEBULA_END_FIRST_R 0.82 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.82 0.85 0.90 0.95 1.00]
#define NEBULA_END_FIRST_G 0.52 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.52 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define NEBULA_END_FIRST_B 0.17 //[0.00 0.05 0.10 0.15 0.17 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define NEBULA_END_FIRST_I 2.60 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.60 2.75 3.00 3.25 3.50]

// Nebula second color (teal/cyan) — Solas V3.3: 32/244/184, I=1.60
// Float equivalents: 32/255=0.13, 244/255=0.96, 184/255=0.72
#define NEBULA_END_SECOND_R 0.13 //[0.00 0.05 0.10 0.13 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define NEBULA_END_SECOND_G 0.96 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 0.96 1.00]
#define NEBULA_END_SECOND_B 0.72 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.72 0.75 0.80 0.85 0.90 0.95 1.00]
#define NEBULA_END_SECOND_I 1.60 //[0.25 0.50 0.75 1.00 1.25 1.50 1.60 1.75 2.00 2.25 2.50 2.75 3.00]

// Black hole accent light — Solas V3.3: LIGHT_END 195/170/165, I=1.45 (warm pinkish-white)
// Float equivalents: 195/255=0.76, 170/255=0.67, 165/255=0.65
#define END_BHOLE_LIGHT_R 0.76 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.76 0.80 0.85 0.90 0.95 1.00]
#define END_BHOLE_LIGHT_G 0.67 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.67 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define END_BHOLE_LIGHT_B 0.65 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define END_BHOLE_LIGHT_I 1.45 //[0.25 0.50 0.75 1.00 1.25 1.45 1.50 1.75 2.00 2.25 2.50]

// ---- End Void Clouds (Solas gravity-lens cloud layer) -----------------------
// Sky-projected cloud wisps at the same visual plane as the accretion disk.
// Coordinates are in bHoleCoord space and warped by black hole gravity.
// "Vision effects": clouds distort and lean toward the black hole center.
#define END_CLOUD_DENSITY   0.50 //[0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 1.00 1.25 1.50]
#define END_CLOUD_WARP      0.80 //[0.00 0.20 0.40 0.60 0.80 1.00 1.25 1.50 2.00]
#define END_CLOUD_BRIGHTNESS 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 2.00]

// ---- End Void Vortex (Eclipse-inspired tornado) -----------------------------
// Raymarched swirling void-fog centered at the End island origin.
// Source: Eclipse-Shader-Unstable/shaders/lib/end_fog.glsl (MIT, David Hoskins hash)
#define VORTEX_STEPS      16   //[4 6 8 10 12 16 24 32]
#define END_VORTEX_DENSITY 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 2.00]
#define END_HAZE_DENSITY   1.00 //[0.00 0.25 0.50 0.75 1.00 1.50 2.00]
#define END_VORTEX_BRIGHTNESS 1.00 //[0.10 0.25 0.50 0.75 1.00 1.25 1.50 2.00 3.00 4.00 5.00]

// Vortex light color — Eclipse defaults: AmbientLightEnd_R/G/B = 0.30/0.35/1.00
#define VORTEX_LIGHT_R 0.30 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define VORTEX_LIGHT_G 0.50 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define VORTEX_LIGHT_B 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

// ---- End Lightning (Bliss v2.1.2 End Storm) ---------------------------------
// Random lightning flashes in the End using time-based hash (no persistent buffer).
// Lightning color mixes with vortex color outside the vortex zone.
#define END_LIGHTNING
#define END_LIGHTNING_R 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define END_LIGHTNING_G 0.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define END_LIGHTNING_B 0.50 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

// ---- End Disk Volumetric Clouds (Solas V3.3 END_DISK system) -----------------
// Raymarched cloud layer at a fixed world height — looks like a protoplanetary disk.
// Ported from Solas shaders/lib/atmosphere/volumetricClouds.glsl by Septonious.
#define END_DISK_CLOUDS
#define END_DISK_HEIGHT     0.0 //[-200.0 -160.0 -120.0 -80.0 -60.0 -40.0 -20.0 0.0 20.0 40.0 60.0]
#define END_DISK_AMOUNT      9.0 //[7.5 8.0 8.5 9.0 9.5 10.0 10.5 11.0]
#define END_DISK_THICKNESS  12.0 //[4.0 6.0 8.0 10.0 12.0 14.0 16.0 18.0 20.0]
#define END_DISK_OPACITY     1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#endif // END_NEBULA_SETTINGS_GLSL
