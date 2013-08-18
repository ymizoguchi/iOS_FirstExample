//
//  ViewController.m
//  Empty2
//
//  Created by Yoshihiro Mizoguchi on 2013/08/15.
//  Copyright (c) 2013年 Yoshihiro Mizoguchi. All rights reserved.
//

#import "ViewController.h"

// shaderに渡す変数のための名前文字
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];
enum {
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
    NUM_ATTRIBUTES
};

// 描画用サンプルデータ
#define RED   1.0f, 0.0f, 0.0f, 1.0f
#define GREEN 0.0f, 1.0f, 0.0f, 1.0f
#define BLUE  0.0f, 0.0f, 1.0f, 1.0f
#define BLACK 0.0f, 0.0f, 0.0f, 1.0f
#define WHITE 1.0f, 1.0f, 1.0f, 1.0f
// Z (GL_LINE_STRIPで表示)
GLfloat zed_points[] = {
    -0.5, -0.5,
    0.5, -0.5,
    -0.5, 0.5,
    0.5, 0.5};
GLfloat zed_colors[] = {
    RED,
    BLUE,
    BLUE,
    GREEN
};
// 四角形 (GL_TRIANGLE_STRIPで表示)
GLfloat square_points[] = {
    -0.25, -0.25,
    0.25, -0.25,
    -0.25, 0.25,
    0.25, 0.25};
GLfloat square_colors[] = {
    RED,
    GREEN,
    BLUE,
    RED
};

@interface ViewController () {
    // Shaderへ渡す変換行列
    GLKMatrix4 _modelViewProjectionMatrix;
    // Shaderを定義するプログラム変数
    GLuint _program;
    // アニメーション用変数 回転(_rotation), 速度(_speed)
    float _rotation;
    float _speed;
}
// Open GL描画管理オブジェクト
@property (strong, nonatomic) EAGLContext *context;
@end

@implementation ViewController

// 最初に1回実行される
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 最初は回転速度は正の0.5fとする.
    _speed = 0.5f;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:self.context];
    
    // マウス入力があるとhandleTapFromを呼ぶようにする
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    // vertex shader (VertexShader.vsh を参照するようにする)
    NSString *vertexShaderSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"vsh"] encoding:NSUTF8StringEncoding error:nil];
    const char *vertexShaderSourceCString = [vertexShaderSource cStringUsingEncoding:NSUTF8StringEncoding];
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSourceCString, NULL);
    glCompileShader(vertexShader);
    // fragment shader (FragmentShader.fsh を参照するようにする)
    NSString *fragmentShaderSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FragmentShader" ofType:@"fsh"] encoding:NSUTF8StringEncoding error:nil];
    const char *fragmentShaderSourceCString = [fragmentShaderSource cStringUsingEncoding:NSUTF8StringEncoding];
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSourceCString, NULL);
    glCompileShader(fragmentShader);
    // Create and link program
    _program = glCreateProgram();
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    glLinkProgram(_program);
    
}

// マウス入力時に呼ばれる関数
- (void)handleTapFrom:(UITapGestureRecognizer *)recognizer {
    CGPoint touchLocation = [recognizer locationInView:recognizer.view];
    touchLocation = CGPointMake(touchLocation.x, 320 - touchLocation.y);
    // ここでは速度の正負を反転するだけにする
    _speed = - _speed;
}

- (void)update
{
    // 何も書かないがメソッドは準備しておく (viewが呼ばれる)
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // 変換行列の準備
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    // Z は z軸を中心に回転させる
    GLKMatrix4 baseModelViewMatrix1 = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    baseModelViewMatrix1 = GLKMatrix4Rotate(baseModelViewMatrix1, _rotation, 0.0f, 0.0f, 1.0f);
    GLKMatrix4 baseModelViewMatrix2 = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    // 四角形は y軸を中心に回転させる
    baseModelViewMatrix2 = GLKMatrix4Rotate(baseModelViewMatrix2, _rotation, 0.0f, 1.0f, 0.0f);
    // 回転角の更新
    _rotation += self.timeSinceLastUpdate * _speed;
    
    // 視点はz軸方向に下がって回転しないことにする.
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, 0.0f, 1.0f, 1.0f, 1.0f);
    
    GLKMatrix4 modelViewMatrix1 = GLKMatrix4Multiply(modelViewMatrix,baseModelViewMatrix1);
    GLKMatrix4 modelViewMatrix2 = GLKMatrix4Multiply(modelViewMatrix,baseModelViewMatrix2);
    
    // 背景は白にする.
    glClearColor(WHITE);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Shaderプログラムを指定する.
    glUseProgram(_program);
    
    // Z (変換行列, 点座標, 色, 表示GL_LINE_STRIP)
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix1);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, zed_points);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, 0, zed_colors);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glDrawArrays(GL_LINE_STRIP, 0, 4);
    
    // 四角形 (変換行列, 点座標, 色, 表示GL_LINE_STRIP)
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix2);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, square_points);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, 0, square_colors);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
}

@end