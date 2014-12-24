//
//  NPBImageCache.m
//  Huggle
//
//  Created by Nigel Brady on 12/24/14.
//  Copyright (c) 2014 Huggle. All rights reserved.
//
#define CACHE_DIRECTORY @"NPBImageCache"
#define DEFAULT_DISK_USAGE 100 * 1024 * 1000

#import <UIKit/UIKit.h>
#import "NPBImageCache.h"

@interface NPBImageCache ()

@property (strong, nonatomic) NSMutableDictionary *cacheKeyLookup;

@end

@implementation NPBImageCache

+(instancetype) sharedInstance{
  
  static NPBImageCache *sharedCache = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedCache = [[self alloc] init];
  });
  
  return sharedCache;
}

-(instancetype)init{
  self = [super init];
  
  if(self){
    _maximumDiskUsage = DEFAULT_DISK_USAGE;
    _cacheKeyLookup = [[NSMutableDictionary alloc] init];
  }
  
  self.delegate = self;
  return self;
}

-(UIImage *)cachedImageForRequest:(NSURLRequest *)request{
  NSString *key = request.URL.absoluteString;
  
  UIImage *cachedImage = [self objectForKey:key];
  
  if(cachedImage){
    NSLog(@"Returning cached image for %@", key);
    return cachedImage;
  }
  
  NSString *diskCachedName = request.URL.lastPathComponent;
  cachedImage = [self diskCachedImageWithName:diskCachedName];
  
  if(cachedImage){
    NSLog(@"Loaded image for %@ from disk", key);
    [self setObject:cachedImage forKey:key];
    [_cacheKeyLookup setObject:key
                        forKey:[NSNumber numberWithUnsignedInteger:cachedImage.hash]];
  }
  
  NSLog(@"Cached image for %@ not found.", key);
  return nil;
}

-(void)cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request{
  NSString *key = request.URL.absoluteString;
  [self setObject:image forKey:key];
  [_cacheKeyLookup setObject:key
                         forKey:[NSNumber numberWithUnsignedInteger:image.hash]];
}

-(void)cache:(NSCache *)cache willEvictObject:(id)obj{
  NSLog(@"Evicting an object from the cache.");
  NSObject *object = (NSObject *)obj;
  NSNumber *reverseKey = [NSNumber numberWithUnsignedInteger:object.hash];
  NSString *targetKey = _cacheKeyLookup[reverseKey];
  
  if(targetKey) {
    [_cacheKeyLookup removeObjectForKey:reverseKey];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSLog(@"Removing image %@ from cache, saving to disk...", targetKey);
      [self saveObjectToDisk:obj withKey:targetKey];
    });
  } else {
    NSLog(@"Couldn't find this object's key...?");
  }
}

-(UIImage *)diskCachedImageWithName:(NSString *)name{
  NSString *filePath =
      [[self pathForCacheFolder] stringByAppendingPathComponent:name];
  
  if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
    return nil;
  } else {
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
    return [UIImage imageWithData:data];
  }
}

-(void)saveObjectToDisk:(id)obj withKey:(NSString *)key{
  NSString *cacheDir = [self pathForCacheFolder];
  long long folderSize = [self sizeOfFolderAtPath:cacheDir];
  
  if(folderSize >= self.maximumDiskUsage){
    [self clearCacheDirectory];
  }
  
  UIImage *image = (UIImage *)obj;
  NSData *data = UIImagePNGRepresentation(image);
  NSString *fileName = [[NSURL URLWithString:key]
                        lastPathComponent];
  NSString *filePath = [[self pathForCacheFolder]
                        stringByAppendingPathComponent:fileName];
  
  BOOL result = [data writeToFile:filePath atomically:YES];
  
  if(result){
    NSLog(@"Successfully wrote image to %@", filePath);
  } else {
    NSLog(@"Failed to write image to %@", filePath);
  }
}

-(NSString *)pathForCacheFolder{
  NSString *cacheDir =
    [NSTemporaryDirectory() stringByAppendingPathComponent:CACHE_DIRECTORY];
  
  if(![[NSFileManager defaultManager] fileExistsAtPath:cacheDir]){
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:&error];
    
    if(error){
      NSLog(@"Failed to create image cache directory: %@", error.description);
    }
  }
  return cacheDir;
}

-(void)clearCacheDirectory{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *directory = [self pathForCacheFolder];
  NSError *error = nil;
  for (NSString *file in [fm contentsOfDirectoryAtPath:directory error:&error]) {
    BOOL success = [fm removeItemAtPath:[NSString stringWithFormat:@"%@%@", directory, file] error:&error];
    if (!success || error) {
      NSLog(@"Error deleting cached file %@: %@", file, error.description);
    }
  }
}

- (unsigned long long int)sizeOfFolderAtPath:(NSString *)folderPath {
  NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
  NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
  NSString *fileName;
  unsigned long long int fileSize = 0;
  
  while (fileName = [filesEnumerator nextObject]) {
    
    NSError *error;
    NSDictionary *fileDictionary =
    [[NSFileManager defaultManager]
     attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName]
     error:&error];
    
    if(!error){
      fileSize += [fileDictionary fileSize];
    } else {
      NSLog(@"Error enumerating file: %@: %@", fileName, error.description);
    }
  }
  return fileSize;
}

-(void)clearCachedItemForURL:(NSString *)url{
  NSObject *obj = [self objectForKey:url];
  if(obj){
    [_cacheKeyLookup
     removeObjectForKey:[NSNumber numberWithUnsignedInteger:obj.hash]];
    [self removeObjectForKey:url];
  }
}

-(void)setMaximumDiskUsage:(int)maximumDiskUsage{
  _maximumDiskUsage = maximumDiskUsage;
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self clearCacheDirectory];
  });
}

@end
