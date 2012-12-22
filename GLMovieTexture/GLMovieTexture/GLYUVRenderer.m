//
//  GLYUVRender.m
//  GLMovieTexture
//
//  Created by hayashi on 12/23/12.
//  Copyright (c) 2012 hayashi. All rights reserved.
//

#import "GLYUVRenderer.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define GLSL(src) #src

@interface GLYUVRenderer(){
	uint32_t _programId;
	int      _position;
	int      _texcoord;
	int      _textures[2];
}
@end

@implementation GLYUVRenderer

-(void)renderWithTexture:(uint32_t)textureId uvTexture:(uint32_t)uvTextureId
{
	if( _programId==0 && ![self loadShaders] ){
		return;
	}
	static const float v[8] = { -1, -1, +1, -1, +1, +1, -1, +1 };
	static const float t[8] = {  0,  0,  1,  0,  1,  1,  0,  1 };
	glUseProgram(_programId);
	glUniform1i(_textures[0], 0);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, textureId);
	glUniform1i(_textures[1], 1);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, uvTextureId);
	glEnableVertexAttribArray(_position);
	glEnableVertexAttribArray(_texcoord);
	glVertexAttribPointer(_position, 2, GL_FLOAT, 0, 0, v);
	glVertexAttribPointer(_texcoord, 2, GL_FLOAT, 0, 0, t);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	glDisableVertexAttribArray(_position);
	glDisableVertexAttribArray(_texcoord);
	glUseProgram(0);
}

- (void)dealloc
{
	glDeleteProgram(_programId);
    [super dealloc];
}

-(BOOL)loadShaders{
	if( _programId ){ return TRUE; }
	
	const char *src[2] = {
		GLSL(
			 attribute vec4 position;
			 attribute vec2 texcoord;
			 varying vec2 v_TexCoord;
			 void main(){
				 gl_Position = position;
				 v_TexCoord = texcoord;
			 }
			 ),
		GLSL(
			 precision lowp float;
			 varying lowp vec2 v_TexCoord;
			 uniform sampler2D _MainTex;
			 uniform sampler2D _SubTex1;
			 const mat3 m = mat3(1.0,1.0,1.0, 0.0,-0.344,1.772, 1.402,-0.714,0.0 );
			 const vec3 t = vec3(-0.701,0.529,-0.886);
			 void main(){
				 gl_FragColor.rgb = (m*vec3(texture2D(_MainTex,v_TexCoord).r,texture2D(_SubTex1,v_TexCoord).ra)+t);
			 }
			 )
	};
	
	_programId = glCreateProgram();
	if( _programId == 0 ){
		NSLog(@"Failed to create program");
		return FALSE;
	}
	if( ![self loadShader:src[0] type:GL_VERTEX_SHADER] ){
		return FALSE;
	}
	if( ![self loadShader:src[1] type:GL_FRAGMENT_SHADER] ){
		return FALSE;
	}
	
	glLinkProgram(_programId);
	
	GLint status;
	glGetProgramiv(_programId, GL_LINK_STATUS, &status);
	if( status == 0 ){
		NSLog(@"Failed to link program");
		return FALSE;
	}
	
	_position = glGetAttribLocation(_programId,"position");
	_texcoord = glGetAttribLocation(_programId,"texcoord");
	_textures[0] = glGetUniformLocation(_programId,"_MainTex");
	_textures[1] = glGetUniformLocation(_programId,"_SubTex1");
	
	return TRUE;
}

-(BOOL)loadShader:(const char*)src type:(uint32_t)type{
	if( !src ){
		NSLog(@"Failed to load shader");
		return FALSE;
	}
	GLuint shaderId = glCreateShader(type);
	glShaderSource(shaderId, 1, &src, NULL);
	glCompileShader(shaderId);
	
    GLint loglen;
	glGetShaderiv(shaderId, GL_INFO_LOG_LENGTH, &loglen);
    if( loglen > 0 ){
		char *log = (char *)malloc(loglen);
		glGetShaderInfoLog(shaderId, loglen, &loglen, log);
		NSLog(@"Shader compile log: [%s]", log);
		free(log);
	}
	GLint status = 0;
    glGetShaderiv(shaderId, GL_COMPILE_STATUS, &status);
    if (status == 0){
        glDeleteShader(shaderId);
		NSLog(@"Failed to compile shader");
        return FALSE;
    }
	glAttachShader(_programId, shaderId);
	glDeleteShader(shaderId);
	return TRUE;
}

@end
