precision mediump float;

attribute vec4 a_position;
attribute vec4 a_color;
varying lowp vec4 colorVarying;
uniform mat4 modelViewProjectionMatrix;

void main() {
    colorVarying = a_color;
    gl_Position = modelViewProjectionMatrix * a_position;
}