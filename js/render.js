// File in charge of rendering webcam via shader to texture
// It loads shaders, then renders immediately

// If device isn't ready yet (devices.js) it will keep waiting until 
// a frame is presented.

var gl = canvas.getContext("webgl2");

if (!gl) {
    alert("WebGL2 not supported, please change web-browser or gpu.");
}

// injection points into our program
var demoData = {
    program: null,
    positionAttributeLocation: null,
    textureLocation: null,
    inputSizeLocation: null,
    outputSizeLocation: null,
    outputTexture: null,
};

loadShaders();
requestAnimationFrame(render);

/* 
* function defs 
*/
async function loadShaders() {
    const vertexShaderSource = await fetch("shaders/vertex.glsl").then(
        (result) => result.text()
    );
    const fragmentShaderSource = await fetch("shaders/fragment.glsl").then(
        (result) => result.text()
    );
    runDemo(vertexShaderSource, fragmentShaderSource);
}



/*
Set's a program's uniform value
*/
function set_program_uniform(gl, program, uniformName, valueType, value) {
    const location = gl.getUniformLocation(program, uniformName);
    if (valueType === gl.FLOAT) {
        gl.uniform1f(location, value);
    } else if (valueType === gl.INT) {
        gl.uniform1i(location, value);
    }
}

function runDemo(vertexSrc, fragmentSrc) {
    const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexSrc);
    const fragmentShader = createShader(
        gl,
        gl.FRAGMENT_SHADER,
        fragmentSrc
    );

    demoData.program = createProgram(gl, vertexShader, fragmentShader);
    gl.useProgram(demoData.program); // set the program we're setting constants on

    demoData.positionAttributeLocation = gl.getAttribLocation(
        demoData.program,
        "a_position"
    );
    demoData.textureLocation = gl.getUniformLocation(
        demoData.program,
        "u_inputTexture"
    );

    demoData.inputSizeLocation = gl.getUniformLocation(
        demoData.program,
        "u_inputSize"
    );
    demoData.outputSizeLocation = gl.getUniformLocation(
        demoData.program,
        "u_outputSize"
    );
    
    const program = demoData.program;
    // webgl doesnt let you put constants inside the fragment shader
    // so we inject them here. You could also inject them via ui later :)
    set_program_uniform(gl, program, "setup_mode", gl.INT, false);
    set_program_uniform(gl, program, "field_left_x", gl.FLOAT, 62);
    set_program_uniform(gl, program, "field_right_x", gl.FLOAT, 112.5);
    set_program_uniform(gl, program, "field_top_y", gl.FLOAT, 40);
    set_program_uniform(gl, program, "field_bottom_y", gl.FLOAT, 199);
    set_program_uniform(gl, program, "stat_palette_white", gl.INT, true);
    set_program_uniform(gl, program, "paletteA_x1", gl.FLOAT, 19);
    set_program_uniform(gl, program, "paletteA_y1", gl.FLOAT, 102);
    set_program_uniform(gl, program, "paletteA_x2", gl.FLOAT, 19);
    set_program_uniform(gl, program, "paletteA_y2", gl.FLOAT, 157);
    set_program_uniform(gl, program, "paletteB_x1", gl.FLOAT, 19);
    set_program_uniform(gl, program, "paletteB_y1", gl.FLOAT, 119);
    set_program_uniform(gl, program, "paletteB_x2", gl.FLOAT, 19);
    set_program_uniform(gl, program, "paletteB_y2", gl.FLOAT, 172);
    set_program_uniform(gl, program, "sharpen_preview", gl.INT, true);
    set_program_uniform(gl, program, "preview_left_x", gl.FLOAT, 123);
    set_program_uniform(gl, program, "preview_right_x", gl.FLOAT, 143);
    set_program_uniform(gl, program, "preview_top_y", gl.FLOAT, 111);
    set_program_uniform(gl, program, "preview_bottom_y", gl.FLOAT, 128);
    set_program_uniform(gl, program, "skip_detect_game", gl.INT, false);
    set_program_uniform(gl, program, "skip_detect_game_over", gl.INT, false);
    set_program_uniform(gl, program, "game_black_x1", gl.FLOAT, 64);
    set_program_uniform(gl, program, "game_black_y1", gl.FLOAT, 20);
    set_program_uniform(gl, program, "game_black_x2", gl.FLOAT, 152);
    set_program_uniform(gl, program, "game_black_y2", gl.FLOAT, 20);
    set_program_uniform(gl, program, "game_grey_x1", gl.FLOAT, 23.5);
    set_program_uniform(gl, program, "game_grey_y1", gl.FLOAT, 218.6);

    /*end dump*/
    const positionBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    const positions = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]);
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);

    demoData.outputTexture = createAndSetupTexture(
        gl,
        outputWidth,
        outputHeight
    );
}

function render() {
    if (video.videoWidth <= 0 || video.videoHeight <= 0) {
        requestAnimationFrame(render);
        return;
    }
    if (demoData.outputTexture === null) {
        requestAnimationFrame(render);
        return;
    }
    gl.clear(gl.COLOR_BUFFER_BIT);

    gl.useProgram(demoData.program);
    gl.enableVertexAttribArray(demoData.positionAttributeLocation);
    gl.vertexAttribPointer(
        demoData.positionAttributeLocation,
        2,
        gl.FLOAT,
        false,
        0,
        0
    );

    gl.uniform1i(demoData.textureLocation, 0);
    gl.uniform2f(
        demoData.inputSizeLocation,
        video.videoWidth,
        video.videoHeight
    );
    gl.uniform2f(demoData.outputSizeLocation, outputWidth, outputHeight);

    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, demoData.outputTexture);
    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        video
    );

    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

    // Perform asynchronous readPixels
    const pixels = new Uint8Array(outputWidth * outputHeight * 4);
    readPixelsAsync(gl, outputWidth, outputHeight, pixels).then(
        (resultPixels) => {
            // Continue processing the pixels as needed
            // For demonstration, just log the resultPixels
            //console.log(resultPixels);
            const canvas2D = debugCanvas;
            const ctx2D = canvas2D.getContext("2d");

            if (ctx2D) {
                const clampedArray = new Uint8ClampedArray(resultPixels);
                const imageData = new ImageData(
                    clampedArray,
                    outputWidth,
                    outputHeight
                );
                ctx2D.clearRect(0, 0, canvas2D.width, canvas2D.height);
                ctx2D.putImageData(imageData, 0, 0);
            } else {
                console.error("2D Canvas or context is null.");
            }
        }
    );

    requestAnimationFrame(render);
}

function createAndSetupTexture(gl, width, height) {
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        width,
        height,
        0,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        null
    );
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    return texture;
}

function createShader(gl, type, source) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        console.error(
            "Shader compilation error:",
            gl.getShaderInfoLog(shader)
        );
        gl.deleteShader(shader);
        return null;
    }

    return shader;
}

function createProgram(gl, vertexShader, fragmentShader) {
    const program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        console.error(
            "Program linking error:",
            gl.getProgramInfoLog(program)
        );
        gl.deleteProgram(program);
        return null;
    }

    return program;
}

function readPixelsAsync(gl, width, height, buffer) {
    return new Promise((resolve) => {
        const bufpak = gl.createBuffer();
        gl.bindBuffer(gl.PIXEL_PACK_BUFFER, bufpak);
        gl.bufferData(
            gl.PIXEL_PACK_BUFFER,
            buffer.byteLength,
            gl.STREAM_READ
        );
        gl.readPixels(0, 0, width, height, gl.RGBA, gl.UNSIGNED_BYTE, 0);

        const sync = gl.fenceSync(gl.SYNC_GPU_COMMANDS_COMPLETE, 0);
        gl.flush();

        clientWaitAsync(gl, sync, 0, 10).then(() => {
            gl.deleteSync(sync);
            gl.bindBuffer(gl.PIXEL_PACK_BUFFER, bufpak);
            gl.getBufferSubData(gl.PIXEL_PACK_BUFFER, 0, buffer);
            gl.bindBuffer(gl.PIXEL_PACK_BUFFER, null);
            gl.deleteBuffer(bufpak);

            resolve(new Uint8Array(buffer));
        });
    });
}

function clientWaitAsync(gl, sync, flags = 0, interval_ms = 10) {
    return new Promise((resolve, reject) => {
        const check = () => {
            const res = gl.clientWaitSync(sync, flags, 0);
            if (res == gl.WAIT_FAILED) {
                reject();
                return;
            }
            if (res == gl.TIMEOUT_EXPIRED) {
                setTimeout(check, interval_ms);
                return;
            }
            resolve();
        };
        check();
    });
}
