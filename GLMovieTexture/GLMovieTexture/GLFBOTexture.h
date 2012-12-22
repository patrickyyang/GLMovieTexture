//
//  GLFBOTexture.h
//  GLMovieTexture
//
//  Created by hayashi on 12/23/12.
//  Copyright (c) 2012 hayashi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLFBOTexture : NSObject
@property (readonly) uint32_t fboId;
@property (readonly) uint32_t textureId;
-(id)initWithSize:(CGSize)size;
-(void)bind;
-(void)unbind;
@end
