//
//  PlugReachability.m
//  Plug
//
//  Created by Ben Gottlieb on 3/2/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

#import "PlugReachability.h"
@import SystemConfiguration;

@protocol Plug_ReachabilityDelegate <NSObject>
- (void) setOnline: (BOOL) online wifi: (BOOL) wifi;
@end

@interface Plug_Reachability ()
- (void) statusChanged: (SCNetworkReachabilityFlags) flags;

@property (nonatomic) BOOL offline;

@property (nonatomic, weak) id <Plug_ReachabilityDelegate> delegate;
@property (nonatomic) dispatch_queue_t reachabilityQueue;
@property (nonatomic) SCNetworkReachabilityRef reachabilityRef;
@end

static void PlugReachabilityCallback(SCNetworkReachabilityRef ref, SCNetworkReachabilityFlags flags, void *info) {
	@autoreleasepool {
		[(__bridge Plug_Reachability *) info statusChanged: flags];
	}
}


@implementation Plug_Reachability

- (void) dealloc {
	[self stop];
}

- (instancetype) init {
	if (self = [super init]) {
		NSString			*hostname = @"www.google.com";

		self.reachabilityQueue = dispatch_queue_create("com.standalone.plug reachability queue", 0);
		self.reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [hostname UTF8String]);
		
		[self start];
	}
	return self;
}

- (void) setDelegate: (id <Plug_ReachabilityDelegate>) delegate {
	_delegate = delegate;
}


- (BOOL) start {
	SCNetworkReachabilityContext    context = { 0, NULL, NULL, NULL, NULL };
	
	context.info = (__bridge void *) self;

	if (SCNetworkReachabilitySetCallback(self.reachabilityRef, PlugReachabilityCallback, &context)) {
		return SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilityQueue);
	}
	
	return false;
}

- (void) stop {
	SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, NULL);
	SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);
}

- (void) statusChanged: (SCNetworkReachabilityFlags) flags {
	BOOL		online = (flags & kSCNetworkReachabilityFlagsReachable) == kSCNetworkReachabilityFlagsReachable;
	
	#if TARGET_OS_IPHONE
		BOOL	wifi = !((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN);
	#else
		BOOL	wifi = true;
	#endif
	
	[self.delegate setOnline: online wifi: wifi];
}

@end
