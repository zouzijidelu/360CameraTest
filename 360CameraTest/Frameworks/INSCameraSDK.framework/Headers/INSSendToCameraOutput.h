//
//  INSSendToCameraOutput.h
//  INSCameraSDK
//
//  Created by zeng bin on 11/15/17.
//  Copyright © 2017 insta360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "INSCameraMediaSession.h"
#import "INSCameraMediaDataTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface INSSendToCameraOutput : NSObject <INSCameraMediaPluggable>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithTypes:(INSCameraDataType)type;

@end

NS_ASSUME_NONNULL_END
