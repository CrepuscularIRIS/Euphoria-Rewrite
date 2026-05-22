//////////////////////////////////////////
// Complementary Shaders by EminGT      //
// With Euphoria Patches by SpacEagle17 //
//////////////////////////////////////////

// End Vortex TAA Pre-pass
// Runs before deferred1.glsl. In the End, raymarches GetEndVortex per pixel and
// blends the result with the previous frame stored in colortex11 (Bliss-style TAA).
// deferred1.glsl reads colortex11 directly — no per-pixel raymarch in the sky pass.
//
// Why this works:
//   The TAA blend rate (clamp(4*frameTime, 0, 1) ≈ 0.064 at 60fps) means each frame
//   contributes only ~6.4% of the new value. Noise at any single pixel is averaged
//   over ~15 frames, matching Bliss's colortex4 LUT accumulation (mixhistory ≈ 0.067).
//   colortex11 is persistent (clear=false in shaders.properties).

#include "/lib/common.glsl"
#if defined END
    #include "/lib/shaderSettings/endNebula.glsl"
#endif
#if defined END && defined END_VOID_VORTEX
    #include "/lib/atmospherics/endVortex.glsl"
#endif

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

uniform sampler2D colortex11;  // persistent vortex TAA history buffer

/*DRAWBUFFERS:b*/
void main() {
#if defined END && defined END_VOID_VORTEX
    // Reconstruct the sky-direction world vector for this pixel (always at sky depth).
    // This matches the direction deferred1 computes for sky pixels (z0 = 1.0).
    vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, 1.0, 1.0) * 2.0 - 1.0);
    viewPos /= viewPos.w;
    vec3 worldDir = normalize(mat3(gbufferModelViewInverse) * viewPos.xyz);

    float dither = texture2DLod(noisetex, texCoord * vec2(viewWidth, viewHeight) / 128.0, 0.0).b;
    #ifdef TAA
        dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
    #endif

    vec4 currVortex = GetEndVortex(worldDir, dither);
    vec4 prevVortex = texture2DLod(colortex11, texCoord, 0);

    // Bliss TAA blend rate: clamp(4 * frameTime, 0, 1).
    // At 60fps ≈ 0.064 (matches Bliss mixhistory ≈ 0.067).
    float mixhistory = clamp(4.0 * frameTime, 0.0, 1.0);
    gl_FragData[0] = mix(prevVortex, currVortex, mixhistory);
#else
    // Non-END or vortex disabled: discard so colortex11 retains previous value.
    discard;
#endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif
