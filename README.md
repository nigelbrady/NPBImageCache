NPBImageCache
=============

An AFCache implementation for AFNetworking that supports in-memory and on-disk caching.

The [AFNetworking](www.afnetworking.com) library adds useful categories that let you populate a UIImageView
with an image from some URL. It aggressively caches the results to cut down on network traffic, but 
sometimes this is not what you want. For example, if you know the contents of an image URL have changed
(the user replaced the image), the cache data for that image should be removed, and the contents reloaded
from the server.

That's where this class comes in!

This is an implementation of NSCache and AFCache that transparently handles image caching for you. To use it:

```objective-c
#import NPBCache.h
#import <UIKit+AFNetworking.h>

//Do this in your app delegate, or before the first request is made...
[UIImageView setSharedImageCache:[NPBImageCache sharedInstance]];

//Make the request as usual.
UIImageView *imageView = ....
[imageView setImageWithURL:url placeholderImage:nil];

//To clear the cache for a particular URL
NSString *urlString = @"http://www.server.com/image123";
[[NPBImageCache sharedInstance] clearCachedItemForURL: urlString];

```
