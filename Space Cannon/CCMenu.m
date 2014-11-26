//
//  CCMenu.m
//  Space Cannon
//
//  Created by Andreas Hailu on 11/25/14.
//  Copyright (c) 2014 Andreas Hailu. All rights reserved.
//

#import "CCMenu.h"

@implementation CCMenu{
    SKLabelNode *scoreLabel;
    SKLabelNode *topScoreLabel;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        SKSpriteNode *title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        title.position = CGPointMake(0.0, 140.0);
        [self addChild:title];
        
        SKSpriteNode *scoreboard = [SKSpriteNode spriteNodeWithImageNamed:@"Scoreboard"];
        scoreboard.position = CGPointMake(0.0, 70.0);
        [self addChild:scoreboard];
        
        SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        playButton.position = CGPointMake(0.0, 0.0);
        playButton.name = @"Play";
        [self addChild:playButton];
        
        scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        scoreLabel.fontSize = 30;
        scoreLabel.position = CGPointMake(-52, 50);
        [self addChild:scoreLabel];
        
        topScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        topScoreLabel.fontSize = 30;
        topScoreLabel.position = CGPointMake(48, 50);
        [self addChild:topScoreLabel];
        
        self.score = 0;
        self.topScore = 0;
    }
    return self;
}

-(void)setScore:(int)score{
    _score = score;
    scoreLabel.text =  [[NSNumber numberWithInt:score] stringValue];
}

-(void)setTopScore:(int)topScore{
    _topScore = topScore;
    topScoreLabel.text =  [[NSNumber numberWithInt:topScore] stringValue];
}

@end
