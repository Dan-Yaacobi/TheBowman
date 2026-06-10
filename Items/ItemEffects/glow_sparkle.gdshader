shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.85, 0.4, 1.0, 1.0);
uniform float glow_radius : hint_range(0.0, 1.0) = 0.35;
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float glow_softness : hint_range(0.01, 1.0) = 0.4;
uniform float sparkle_count : hint_range(1.0, 8.0) = 4.0;
uniform float sparkle_speed : hint_range(0.0, 5.0) = 1.2;
uniform float sparkle_size : hint_range(0.0, 0.15) = 0.055;
uniform float sparkle_orbit : hint_range(0.1, 0.8) = 0.48;
uniform float sparkle_intensity : hint_range(0.0, 5.0) = 2.5;
uniform vec2 frame_size = vec2(32.0, 32.0); // set to your frame size in pixels

float star_sdf(vec2 p, float size) {
    vec2 ap = abs(p);
    float d = max(
        (ap.x + ap.y) - size * 1.2,
        max(ap.x, ap.y) - size * 0.55
    );
    return d;
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Convert UV to pixel coords, snap to frame-local UV
    vec2 tex_size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
    vec2 pixel_pos = UV * tex_size;
    vec2 frame_uv = fract(pixel_pos / frame_size); // 0→1 within current frame
    vec2 centered = frame_uv - vec2(0.5);

    // --- Radial glow ---
    float dist = length(centered);
    float glow = smoothstep(glow_radius, glow_radius - glow_softness, dist);
    glow = pow(glow, 1.8) * glow_intensity;
    float outside = 1.0 - tex.a;
    vec4 glow_contrib = glow_color * glow * outside;

    // --- Sparkles ---
    vec4 sparkle_contrib = vec4(0.0);
    float time = TIME * sparkle_speed;
    for (float i = 0.0; i < 8.0; i++) {
        if (i >= sparkle_count) break;
        float angle = (i / sparkle_count) * TAU + time;
        float orbit = sparkle_orbit + (mod(i, 2.0) * 0.07);
        vec2 spark_pos = vec2(cos(angle), sin(angle)) * orbit;
        float phase = i / sparkle_count;
        float pulse = 0.55 + 0.45 * sin(time * 2.1 + phase * TAU);
        float size = sparkle_size * pulse;
        vec2 local = centered - spark_pos;
        float sd = star_sdf(local, size);
        float star = smoothstep(0.01, -0.01, sd) * pulse;
        vec4 spark_color = mix(glow_color, vec4(1.0), smoothstep(size * 0.6, 0.0, length(local)));
        sparkle_contrib += spark_color * star * sparkle_intensity;
    }

// --- Compose ---
    vec4 final;
    final.rgb = tex.rgb + glow_contrib.rgb + sparkle_contrib.rgb * (1.0 - tex.a) + sparkle_contrib.rgb * 0.3;
    final.a = max(tex.a, glow * outside); // glow extends alpha outside sprite
    final = clamp(final, 0.0, 1.0);
    final *= COLOR;
    COLOR = final;
}