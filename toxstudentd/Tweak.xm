#import <sys/cdefs.h>
#import <stdint.h>
#import <mach/message.h>
#import <Availability.h>
#import <dispatch/dispatch.h>


@interface STULockLongRunningOperation
+ (void)unloadLockScreenPlugin;
+ (void)removeCurrentAppLock;
@end

@interface ToxSaver : NSObject 
- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo;
@end

@implementation ToxSaver
- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
    if (error) {
        NSLog(@"Error image: %@", error);
    } else {
        NSLog(@"Success image!!");
    }
}
@end

static void saveImage(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    NSLog(@"Ho ricevuto la notifica per 'image'");
    NSLog(@"userinfo: %@", userInfo);
    NSDictionary *newUserInfo = (__bridge NSDictionary*)userInfo;
    NSString *filePath = [newUserInfo valueForKeyPath:@"imagePath"];
    if (filePath == nil) {
        NSLog(@"Here.\n");
        return;
    }
    
    NSURL *url = [NSURL fileURLWithPath:filePath];
    if (url == nil) {
        NSLog(@"Here2.\n");
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (data == nil) {
        NSLog(@"Here3\n");
        return;
    }
    
    UIImage *image = [[UIImage alloc] initWithData:data];
    if (image == nil) {
        NSLog(@"Here4\n");
        return;
    }

	NSLog(@"toxstudentd: Ho ricevuto la notifica com.danitox.imagesaver");
    ToxSaver *saver = [[ToxSaver alloc] init];
    UIImageWriteToSavedPhotosAlbum(image, saver, @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), nil);
}

static void removeClassroomLockScreen(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
	NSLog(@"toxstudentd: Ho ricevuto la notifica com.danitox.toxstudentd.lockscreen");
	[%c(STULockLongRunningOperation) unloadLockScreenPlugin];
}


static void removeSingleAppMode(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSLog(@"toxstudentd: Ho ricevuto la notifica com.danitox.toxstudentd.singleappmode");
	[%c(STULockLongRunningOperation) removeCurrentAppLock];
}

@interface MCProfileConnection
+ (id)sharedConnection;
- (id)installedProfileIdentifiers;
@end

static void removeMDMProfile(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
	NSLog(@"mdmremover: Ho ricevuto la notifica com.danitox.toxstudentd.removeMDM");
    id profiles = [[%c(MCProfileConnection) sharedConnection] installedProfileIdentifiers];
	NSLog(@"Ecco i profili instalalti: %@", profiles);
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, removeClassroomLockScreen, CFSTR("com.danitox.toxstudentd.lockscreen"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	NSLog(@"toxstudentd: Ho aggiunto l'observer alla notifica di rimozione CRLock");
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, removeSingleAppMode, CFSTR("com.danitox.toxstudentd.singleappmode"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    NSLog(@"toxstudentd: Ho aggiunto l'observer alla notifica di rimozione SingleAppMode");

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, saveImage, CFSTR("com.danitox.imagesaver"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    NSLog(@"toxstudentd: Ho aggiunto l'observer alla notifica di salvo immagine");

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, removeMDMProfile, CFSTR("com.danitox.toxstudentd.removeMDM"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	NSLog(@"toxstudentd: Ho aggiunto l'observer alla notifica di rimozione MDM");
}
