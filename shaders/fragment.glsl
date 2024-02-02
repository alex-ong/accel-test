precision mediump float;
varying vec2 v_texCoord;
uniform sampler2D u_inputTexture;
uniform vec2 u_inputSize;
uniform vec2 u_outputSize;

void main() {
    float Pixels = 500.0;
    float dx = 15.0 * (1.0 / Pixels);
    float dy = 10.0 * (1.0 / Pixels);
    vec2 Coord = vec2(dx * floor(v_texCoord.x / dx),
                    dy * floor(v_texCoord.y / dy));
    vec4 color = texture2D(u_inputTexture, Coord);
    gl_FragColor = color;
}