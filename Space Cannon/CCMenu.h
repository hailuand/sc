//
//  CCMenu.h
//  Space Cannon
//
//  Created by Andreas Hailu on 11/25/14.
//  Copyright (c) 2014 Andreas Hailu. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface CCMenu : SKNode

@property (nonatomic) int score;
@property (nonatomic) int topScore;
@property (nonatomic) BOOL touchable;
-(void)hide;
-(void)show;

@end
