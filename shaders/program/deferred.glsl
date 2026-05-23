//////////////////////////////////////////
// Complementary Shaders by EminGT      //
// With Euphoria Patches by SpacEagle17 //
//////////////////////////////////////////

// Bliss-style End vortex LUT pre-pass.
// Writes a persistent 256x256 direction-space LUT into colortex10 and keeps a few
// reserved texels for lightning timer/flash/position state.

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

/*DRAWBUFFERS:a*/
void main() {
#if defined END && defined END_VOID_VORTEX
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    vec4 prevTex = texelFetch(colortex10, pixel, 0);
    vec4 currTex = prevTex;
    float mixhistory = 0.06;

    if (gl_FragCoord.y < 1.0) {
        float flash = 0.0;
        const float maxWaitTime = 5.0;

        float timer = texelFetch(colortex10, VP_LIGHTNING_TIMER_TEXEL, 0).x;
        timer -= frameTime;

        if (timer <= 0.0) {
            flash = 1.0;
            timer = pow(hash11(float(frameCounter)), 5.0) * maxWaitTime;
        }

        if (all(equal(pixel, VP_LIGHTNING_TIMER_TEXEL))) {
            mixhistory = 1.0;
            currTex = vec4(timer, 0.0, 0.0, 1.0);
        } else if (all(equal(pixel, VP_LIGHTNING_FLASH_TEXEL))) {
            mixhistory = clamp(4.0 * frameTime, 0.0, 1.0);
            currTex = vec4(flash, 0.0, 0.0, 1.0);
        } else if (all(equal(pixel, VP_LIGHTNING_POS_TEXEL))) {
            mixhistory = clamp(500.0 * frameTime, 0.0, 1.0);

            vec3 lastPos = texelFetch(colortex10, VP_LIGHTNING_POS_TEXEL, 0).xyz * 2.0 - 1.0;
            lastPos += vpHash31(float(frameCounter / 50)) * 2.0 - 1.0;
            lastPos = lastPos * 0.5 + 0.5;

            if (timer > maxWaitTime * 0.7) {
                lastPos = vec3(0.0);
            }

            currTex = vec4(lastPos, 1.0);
        }
    } else {
        vec2 lutCoord = vpCurrentEndVortexLUTCoord();
        vec3 viewVector = vpCartToSphere(lutCoord);
        vec3 viewPosition = mat3(gbufferModelView) * viewVector * 256.0;

        float dither = fract(float(frameCounter) / 1.6180339887);
        float dither2 = fract(float(frameCounter) / 2.6180339887);

        currTex = GetEndVortex(viewPosition, dither, dither2);
    }

    gl_FragData[0] = mix(prevTex, currTex, mixhistory);
#else
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
