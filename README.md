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

//Use AFNetworking to load the image from the URL as usual...
UIImageView *imageView = ....
[imageView setImageWithURL:url placeholderImage:nil];

//To clear the cache for a particular URL
NSString *urlString = @"http://www.server.com/image123";
[[NPBImageCache sharedInstance] clearCachedItemForURL: urlString];

```
It should also work in Swift.

The cache attempts to load an image for a particular URL from memory. If that image is not present,
it checks a folder in the temporary directory for the image. If that also fails, it returns nil
and the image is loaded over the network.

As memory pressure forces the cache to evict objects, it writes them to the temporary directory
to be possibly loaded later.

By default, the temporary directory is allowed to grow to 100MB, after which the entire directory
is purged.

To purge the directory yourself, call:
```objective-c
[[NPBImageCache sharedInstance] clearCacheDirectory];
```

You can also change the disk usage limit:
```objective-c
int sizeInBytes = 250 * 1024 * 1000;
[[NPBImageCache sharedInstance] setMaximumDiskUsage: sizeInBytes];
```

However, after you change maximum disk usage value, the temporary directory is cleared.
