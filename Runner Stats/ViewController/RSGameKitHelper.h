//
//  RSGameKitHelper.h
//  Runner Stats
//
//  Created by Mr. Who on 3/27/14.
//  Copyright (c) 2014 hk. All rights reserved.
//
#import <GameKit/GameKit.h>
#import <Foundation/Foundation.h>

@protocol GameKitHelperProtocol <NSObject>
-(void) onScoresSubmitted:(bool)success;
@end


@interface RSGameKitHelper : NSObject <GKGameCenterControllerDelegate>

@property (assign, nonatomic) id<GameKitHelperProtocol> delegate;

@property (readonly, nonatomic) NSError *lastError;

@property (assign, nonatomic) BOOL gameCenterFeaturesEnabled;

+ (id) sharedGameKitHelper;

- (void) authenticateLocalPlayer;

-(void) submitScore:(double_t)score
           category:(NSString*)category;

@end
