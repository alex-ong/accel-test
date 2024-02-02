#version 300 es
precision mediump float;


uniform bool setup_mode;
uniform float field_left_x;
uniform float field_right_x;
uniform float field_top_y;
uniform float field_bottom_y;

uniform bool stat_palette_white;

uniform float paletteA_x1;
uniform float paletteA_y1;
uniform float paletteA_x2;
uniform float paletteA_y2;

uniform float paletteB_x1;
uniform float paletteB_y1;
uniform float paletteB_x2;
uniform float paletteB_y2;

uniform bool sharpen_preview;
uniform float preview_left_x;
uniform float preview_right_x;
uniform float preview_top_y;
uniform float preview_bottom_y;

uniform bool skip_detect_game;
uniform bool skip_detect_game_over;

uniform float game_black_x1;
uniform float game_black_y1;
uniform float game_black_x2;
uniform float game_black_y2;
uniform float game_grey_x1;
uniform float game_grey_y1;

in vec2 v_texCoord;
uniform sampler2D u_inputTexture;
uniform vec2 u_inputSize;
uniform vec2 u_outputSize;
out vec4 fragColor;

float myLerp(float start, float end, float perc) {
    return start + (end - start) * perc;
}

float distPoints(vec2 a, vec2 b) {
    return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y) * 20.43;
}

vec3 closest_stat(vec2 uv) {
    const vec2 test[28] = vec2[](
        vec2(0.195, 0.023), vec2(0.456, 0.023), vec2(0.727, 0.023), vec2(0.456, 0.080),
        vec2(0.334, 0.486), vec2(0.594, 0.486), vec2(0.334, 0.546), vec2(0.594, 0.546),
        vec2(0.109, 0.976), vec2(0.370, 0.976), vec2(0.631, 0.976), vec2(0.892, 0.976),
        vec2(0.195, 0.165), vec2(0.456, 0.165), vec2(0.727, 0.165), vec2(0.727, 0.220),
        vec2(0.456, 0.637), vec2(0.727, 0.637), vec2(0.195, 0.695), vec2(0.456, 0.695),
        vec2(0.195, 0.329), vec2(0.456, 0.329), vec2(0.456, 0.386), vec2(0.727, 0.386),
        vec2(0.195, 0.782), vec2(0.456, 0.782), vec2(0.727, 0.782), vec2(0.195, 0.840)
    );

    float min_dist = distPoints(uv, test[0]);
    int result = 0;

    for (int i = 1; i < 28; i++) {
        float dist = distPoints(uv, test[i]);
        if (dist < min_dist) {
            min_dist = dist;
            result = i;
        }
    }
    return vec3(test[result].x, test[result].y, float(result) / 4.0);
}

bool blockStatIsWhite(int id) {
    return id < 3;
}

bool blockStatIsCol1(int id) {
    return 3 <= id && id <= 4;
}

bool blockStatIsCol2(int id) {
    return id > 4;
}

float blockWidth() {
    return (field_right_x - field_left_x) / 10.0 / 256.0;
}

float blockHeight() {
    return (field_bottom_y - field_top_y) / 20.0 / 224.0;
}

float pixelWidthUV() {
    float bw = blockWidth();
    return bw / 8.0;
}

float pixelHeightUV() {
    float bh = blockHeight();
    return bh / 8.0;
}

vec2 pixelUV() {
    return vec2(pixelWidthUV(), pixelHeightUV());
}

bool inBox(vec2 uv) {
    float startX = field_left_x / 256.0;
    float endX = field_right_x / 256.0;
    float startY = field_top_y / 224.0;
    float endY = field_bottom_y / 224.0;
    return (uv.x > startX && uv.x < endX && uv.y > startY && uv.y < endY);
}

bool inBox2(vec2 uv, vec4 box) {
    return (uv.x >= box.r &&
            uv.x <= box.g &&
            uv.y >= box.b &&
            uv.y <= box.a);
}

vec4 pixBox(vec2 uv, int pixels) {
    return vec4(uv.x - (float(pixels) / 256.0), uv.x + (float(pixels) / 256.0),
                uv.y - (float(pixels) / 224.0), uv.y + (float(pixels) / 224.0));
}

vec4 pixBoxStat(vec2 uv, int pixels) {
    return vec4(uv.x - float(pixels) / 23.0, uv.x + float(pixels) / 23.0,
                uv.y - float(pixels) / 104.0, uv.y + float(pixels) / 104.0);
}

vec2 paletteA1_uv() {
    return vec2(paletteA_x1 / 256.0, paletteA_y1 / 224.0);
}

vec2 paletteA2_uv() {
    return vec2(paletteA_x2 / 256.0, paletteA_y2 / 224.0);
}

vec2 paletteB1_uv() {
    return vec2(paletteB_x1 / 256.0, paletteB_y1 / 224.0);
}

vec2 paletteB2_uv() {
    return vec2(paletteB_x2 / 256.0, paletteB_y2 / 224.0);
}

vec4 paletteA1_box() {
    return pixBox(paletteA1_uv(), 1);
}

vec4 paletteA2_box() {
    return pixBox(paletteA2_uv(), 1);
}

vec4 paletteB1_box() {
    return pixBox(paletteB1_uv(), 1);
}

vec4 paletteB2_box() {
    return pixBox(paletteB2_uv(), 1);
}

vec2 gameBlack1_uv() {
    return vec2(game_black_x1 / 256.0, game_black_y1 / 224.0);
}

vec2 gameBlack2_uv() {
    return vec2(game_black_x2 / 256.0, game_black_y2 / 224.0);
}

vec2 gameGrey1_uv() {
    return vec2(game_grey_x1 / 256.0, game_grey_y1 / 224.0);
}

vec4 gameBlack1_box() {
    return pixBox(gameBlack1_uv(), 2);
}

vec4 gameBlack2_box() {
    return pixBox(gameBlack2_uv(), 2);
}

vec4 gameGrey1_box() {
    return pixBox(gameGrey1_uv(), 2);
}

vec4 preview_box() {
    return vec4(preview_left_x / 256.0,
                preview_right_x / 256.0,
                preview_top_y / 224.0,
                preview_bottom_y / 224.0);
}

vec2 prev_offset1() {
    return vec2(myLerp(preview_left_x, preview_right_x, 0.30) / 256.0,
                myLerp(preview_top_y, preview_bottom_y, 0.875) / 224.0);
}

vec2 prev_offset2() {
    return vec2(myLerp(preview_left_x, preview_right_x, 0.4375) / 256.0,
                myLerp(preview_top_y, preview_bottom_y, 0.875) / 224.0);
}

vec2 prev_offset3() {
    return vec2(myLerp(preview_left_x, preview_right_x, 0.6875) / 256.0,
                myLerp(preview_top_y, preview_bottom_y, 0.875) / 224.0);
}

vec4 blockTex(bool white, vec2 uv, vec4 base) {
    if (!white) {
        uv = vec2(uv.x / 2.0, uv.y);
    } else {
        uv = vec2(uv.x / 2.0 + 0.5, uv.y);
    }

    vec4 result = texture(u_inputTexture, uv);
    if (result.a == 0.0) {
        return base;
    } else {
        return result;
    }
}

bool isWhite(vec4 rgba) {
    float limit = 0.6;
    return (rgba.r >= limit &&
            rgba.g >= limit &&
            rgba.b >= limit);
}

bool isBlack(vec4 rgba) {
    float limit = 0.20;
    return (rgba.r <= limit &&
            rgba.g <= limit &&
            rgba.b <= limit);
}

bool isGrey(vec4 rgba) {
    float limit = 0.30;
    return (rgba.r >= 0.5 - limit && rgba.r <= 0.5 + limit &&
            rgba.g >= 0.5 - limit && rgba.g <= 0.5 + limit &&
            rgba.b >= 0.5 - limit && rgba.b <= 0.5 + limit);
}

vec4 sampleBlock(vec2 uv, vec2 pixelSize) {
    vec4 centre = texture(u_inputTexture, uv);
    vec4 tr = texture(u_inputTexture, vec2(uv.x + pixelSize.x, uv.y - pixelSize.y));
    vec4 right = texture(u_inputTexture, vec2(uv.x + pixelSize.x, uv.y));
    vec4 bl = texture(u_inputTexture, vec2(uv.x - pixelSize.x, uv.y + pixelSize.y));
    vec4 bot_right = texture(u_inputTexture, vec2(uv.x + pixelSize.x, uv.y + pixelSize.y));
    vec4 avg = (tr + bl + bot_right + centre + right) / 5.0;
    return avg;
}

vec4 palette1(vec2 pixelSize) {
    vec4 a1 = sampleBlock(paletteA1_uv(), pixelSize);
    vec4 a2 = sampleBlock(paletteA2_uv(), pixelSize);
    return (a1+a2)/2.0; // S Piece
}

vec4 palette2(vec2 pixelSize) {
    vec4 b1 = sampleBlock(paletteB1_uv(), pixelSize);
    vec4 b2 = sampleBlock(paletteB2_uv(), pixelSize);
    return (b1+b2)/2.0; // L Piece
}

//Low cost color distance
//https://www.compuphase.com/cmetric.htm
float colorDist(vec4 e1, vec4 e2)
{
	float r = (e1.r-e2.r);
	float g = (e1.g-e2.g);
	float b = (e1.b-e2.b);
	float rMean = (e1.r+e2.r)/2.0;
	if (rMean > 0.5) {
		return 3.0*r*r + 4.0*g*g + 2.0*b*b;
	} else {
		return 2.0*r*r + 4.0*g*g + 3.0*b*b;
	}
}


vec4 matchPalette(vec4 p1, vec4 p2, vec4 col) {
    float dist1 = colorDist(p1, col);
    float dist2 = colorDist(p2, col);
    if (dist1 < dist2) {
        return p1;
    } else {
        return p2;
    }
}



vec4 sampleEdge(vec2 uv, vec2 pixelSize) {
    float topyUv = uv.y + 2.5 * pixelSize.y;
    float bottomyUv = uv.y - 3.5 * pixelSize.y;
    vec4 top = texture(u_inputTexture, vec2(uv.x, topyUv));
    vec4 bottom = texture(u_inputTexture, vec2(uv.x, bottomyUv));
    return (top + bottom) / 2.0;
}

vec4 sampleEdgeStat(vec2 uv, vec2 pixelSize) {
    float topyUv = uv.y + 1.5 * pixelSize.y;
    float bottomyUv = uv.y - 2.5 * pixelSize.y;
    vec4 top = texture(u_inputTexture, vec2(uv.x, topyUv));
    vec4 bottom = texture(u_inputTexture, vec2(uv.x, bottomyUv));
    return (top + bottom) / 2.0;
}

bool isInGame(vec2 pixelSize) {
    vec4 black1 = sampleBlock(gameBlack1_uv(), pixelSize); // black box next to "LINES";
    vec4 black2 = sampleBlock(gameBlack2_uv(), pixelSize); // black box of "TOP/SCORE"
    vec4 grey1 = sampleBlock(gameGrey1_uv(), pixelSize);   // grey box of bottom middle left
    return (isBlack(black1) && isBlack(black2) && (isGrey(grey1) || isWhite(grey1)));
}

bool isGameOver(vec2 pixelSize) {
    float startX = field_left_x / 256.0 + 4.0 * pixelSize.x;
    float startY = field_top_y / 224.0 + 4.0 * pixelSize.y;

    vec4 topleft = sampleBlock(vec2(startX, startY), pixelSize);
    vec4 topmid = sampleBlock(vec2(startX + 40.0 * pixelSize.x, startY), pixelSize);
    vec4 topright = sampleBlock(vec2(startX + 80.0 * pixelSize.x, startY), pixelSize);

    float midY = startY - 50.0 * pixelSize.y;
    vec4 midleft = sampleBlock(vec2(startX, midY), pixelSize);
    vec4 midmid = sampleBlock(vec2(startX + 40.0 * pixelSize.x, midY), pixelSize);
    vec4 midright = sampleBlock(vec2(startX + 80.0 * pixelSize.x, midY), pixelSize);

    return (isWhite(topleft) && isWhite(topmid) && isWhite(topright) &&
            isWhite(midleft) && isWhite(midmid) && isWhite(midright));
}

vec4 sampleBlockStat(vec2 uv, vec2 pixelSize) {
    vec4 centre = texture(u_inputTexture, uv);
    vec4 tr = texture(u_inputTexture, vec2(uv.x + pixelSize.x, uv.y - pixelSize.y));
    vec4 right = texture(u_inputTexture, vec2(uv.x + pixelSize.x, uv.y));
    vec4 bl = texture(u_inputTexture, vec2(uv.x - pixelSize.x, uv.y + pixelSize.y));
    vec4 bot_right = texture(u_inputTexture, vec2(uv.x + pixelSize.x, uv.y + pixelSize.y));
    vec4 avg = (tr + bl + bot_right + centre + right) / 5.0;
    return avg;
}





vec4 process(vec2 uv) {
    
    if (setup_mode) {
        vec4 col = texture(u_inputTexture, uv);
        if (inBox(uv)) {
            return (vec4(0.0,1.0,0.0,1.0) + col)/2.0;
        } else {
            return col;
        }
    }

    
    if (!inBox(uv)) {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }

    vec2 pixelSize = pixelUV();
    vec4 centre = texture(u_inputTexture, uv);
    vec4 edge = sampleEdge(uv, pixelSize);

    vec4 result = centre;

    if (sharpen_preview && inBox2(uv, preview_box())) {
        vec4 edgeStat = sampleEdgeStat(uv, pixelSize);
        float sharpen = 5.0;
        result = mix(result, edgeStat, sharpen);
    }

    vec4 white = vec4(1.0, 1.0, 1.0, 1.0);
    vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 grey = vec4(0.5, 0.5, 0.5, 1.0);

    vec4 c1 = palette1(pixelSize);
    vec4 c2 = palette2(pixelSize);

    bool isWhiteCentre = isWhite(centre);
    bool isWhiteEdge = isWhite(edge);

    bool isBlackCentre = isBlack(centre);
    bool isBlackEdge = isBlack(edge);

    bool isGreyCentre = isGrey(centre);
    bool isGreyEdge = isGrey(edge);

    bool isEdge = !isWhiteEdge && !isBlackEdge && !isGreyEdge;

    // Apply palette colors to white blocks
    if (isWhiteCentre) {
        if (blockStatIsWhite(int(centre.r * 10.0))) {
            if (isEdge) {
                result = matchPalette(c1, c2, centre);
            } else {
                result = white;
            }
        }
    }

    // Apply palette colors to color1 blocks
    if (blockStatIsCol1(int(centre.r * 10.0))) {
        if (isEdge) {
            result = matchPalette(c1, c2, centre);
        } else {
            result = c1;
        }
    }

    // Apply palette colors to color2 blocks
    if (blockStatIsCol2(int(centre.r * 10.0))) {
        if (isEdge) {
            result = matchPalette(c1, c2, centre);
        } else {
            result = c2;
        }
    }

    // Convert grey blocks to white
    if (isGreyCentre) {
        result = white;
    }

    // Convert black blocks to black
    if (isBlackCentre) {
        result = black;
    }

    // Override palette colors in setup mode
    if (setup_mode) {
        if (inBox2(uv, paletteA1_box()) || inBox2(uv, paletteA2_box())) {
            result = vec4(1.0, 0.0, 0.0, 1.0);
        }
        if (inBox2(uv, paletteB1_box()) || inBox2(uv, paletteB2_box())) {
            result = vec4(0.0, 0.0, 1.0, 1.0);
        }
        if (inBox2(uv, gameBlack1_box()) || inBox2(uv, gameBlack2_box()) || inBox2(uv, gameGrey1_box())) {
            result = grey;
        }
    }

    // Detect game over and block preview
    if (!skip_detect_game && isInGame(pixelSize)) {
        result = black;
    }
    if (!skip_detect_game_over && isGameOver(pixelSize)) {
        result = grey;
    }

    return result;
}


void main() {
    //fragColor = vec4(0.5,0.5,0.5,1.0);
    fragColor = process(v_texCoord);
}
