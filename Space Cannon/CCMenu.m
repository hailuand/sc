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
    SKSpriteNode *_playButton;
    SKSpriteNode *_scoreboard;
    SKSpriteNode *_title;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        _title.position = CGPointMake(0.0, 140.0);
        [self addChild:_title];
        
        _scoreboard = [SKSpriteNode spriteNodeWithImageNamed:@"Scoreboard"];
        _scoreboard.position = CGPointMake(0.0, 70.0);
        [self addChild:_scoreboard];
        
        _playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        _playButton.position = CGPointMake(0.0, 0.0);
        _playButton.name = @"Play";
        [self addChild:_playButton];
        
        scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        scoreLabel.fontSize = 30;
        scoreLabel.position = CGPointMake(-52, -20);
        [_scoreboard addChild:scoreLabel];
        
        topScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        topScoreLabel.fontSize = 30;
        topScoreLabel.position = CGPointMake(48, -20);
        [_scoreboard addChild:topScoreLabel];
        
        self.score = 0;
        self.topScore = 0;
        self.touchable = YES;
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

-(void)hide{
    self.hidden = NO;
    self.touchable = NO;
    
    SKAction *animateMenu = [SKAction scaleTo:0.0 duration:0.5];
    animateMenu.timingMode = SKActionTimingEaseIn;
    [self runAction:animateMenu completion:^{
        self.hidden = YES;
        self.xScale = 1.0;
        self.yScale = 1.0;
    }];

}

-(void)show{
    self.hidden = NO;
    self.touchable = NO;
    
    SKAction *fadeIn = [SKAction fadeInWithDuration:0.5];
    // Animate title
    _title.position = CGPointMake(0.0, 280);
    _title.alpha = 0;
    SKAction *animateTitle = [SKAction group:@[[SKAction moveToY:140 duration:0.5], fadeIn]];
    animateTitle.timingMode = SKActionTimingEaseOut;
    [_title runAction:animateTitle];
    
    // Animate scoreboard
    _scoreboard.xScale = 4.0;
    _scoreboard.yScale = 4.0;
    _scoreboard.alpha = 0;
    SKAction* animateScoreboard = [SKAction group:@[[SKAction scaleTo:1.0 duration:0.5], fadeIn]];
    animateScoreboard.timingMode = SKActionTimingEaseOut;
    [_scoreboard runAction:animateScoreboard];
    
    // Animate playbutton
    _playButton.alpha = 0;
    SKAction *animatePlayButton = [SKAction fadeInWithDuration:2.0];
    animatePlayButton.timingMode = SKActionTimingEaseIn;
    [_playButton runAction:animatePlayButton completion:^{
        self.touchable = YES;
    }];
}

@end
