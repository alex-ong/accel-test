// globals, accessible by other .js files
// are defined a top level using var

var video = document.getElementById("webcam");
var videoSelect = document.getElementById("videoSource");


const outputWidth = 360;
const outputHeight = 224;

var canvas = document.getElementById("outputCanvas");
canvas.width = outputWidth;
canvas.height = outputHeight;

var debugCanvas = document.getElementById("outputCanvas2");
debugCanvas.width = outputWidth;
debugCanvas.height = outputHeight;


// This is how you import devices.js and shaders.js
// todo: proper imports
document.write('<script type="text/javascript" src="js/devices.js"></script>');
document.write('<script type="text/javascript" src="js/render.js"></script>');

