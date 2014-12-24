//
//  NPBImageCache.h
//  Huggle
//
//  Created by Nigel Brady on 12/24/14.
//  Copyright (c) 2014 Huggle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIImageView+AFNetworking.h>

@interface NPBImageCache: NSCache <AFImageCache, NSCacheDelegate>

@property (nonatomic) int maximumDiskUsage;

+(instancetype) sharedInstance;

-(void)clearCachedItemForURL:(NSString *)url;
-(UIImage *)cachedImageForRequest:(NSURLRequest *)request;
-(void)cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request;
-(void)cache:(NSCache *)cache willEvictObject:(id)obj;
-(void)clearCacheDirectory;

@end
