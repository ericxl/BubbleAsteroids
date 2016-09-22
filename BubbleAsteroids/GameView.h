//
//  GameView.h
//  BubbleAsteroids
//
//  Created by Eric Liang on 7/12/12.
//  Copyright (c) 2012 St.Stephen's. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GameView : NSOpenGLView <NSSoundDelegate>{
    NSSound *popSound;
    NSSound *backgroundMusic;
}
@end
