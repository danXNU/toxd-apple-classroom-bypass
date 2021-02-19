#include <stdio.h>
#include <errno.h>
#include <sys/socket.h>
#include <resolv.h>
#include <arpa/inet.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <spawn.h>

#import <objc/runtime.h>

#define MCProfileConnectionClass NSClassFromString(@"MCProfileConnection")

#define MY_PORT     1717
#define MAXBUF      1024

@interface MCProfileConnection: NSObject

+ (id)sharedConnection;
- (id)installedProfileIdentifiers;
- (void)removeProfileAsyncWithIdentifier:(id)arg1;

@end


void respring() {
    pid_t pd;
    const char* a1[] = { "/usr/bin/killall", "-9", "SpringBoard", NULL };
    char** args = (char **)&a1;
    posix_spawn(&pd, "/usr/bin/killall", NULL, NULL, args, NULL);
    waitpid(pd, NULL, 0);
}

void respringSelector(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    NSLog(@"toxd: Ho ricevuto la notifica com.danitox.toxstudentd.respring");
    respring();
}


int main(int Count, char *Strings[])
{   
    NSLog(@"toxd: Ehilà! Sono stato avviato!");

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, respringSelector, CFSTR("com.danitox.toxstudentd.respring"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    NSLog(@"toxd: Ho settato l'observer della notifica di respring");









    NSBundle *managedConf = [[NSBundle alloc] initWithPath:@"/System/Library/PrivateFrameworks/ManagedConfiguration.framework"];
    assert([managedConf load]);

    MCProfileConnection *connection = [MCProfileConnectionClass performSelector:NSSelectorFromString(@"sharedConnection")];
    id profiles = [connection performSelector:NSSelectorFromString(@"installedProfileIdentifiers")];
    
    NSLog(@"TOXMDM: %@", profiles);

    // int i=0;
    // unsigned int mc = 0;
    // Method *mlist = class_copyMethodList(object_getClass(connection), &mc);
    // NSLog(@"%d methods", mc);
    // for(i=0;i<mc;i++) {
    //     NSLog(@"Method no #%d: %s", i, sel_getName(method_getName(mlist[i])));
    // }

    [connection removeProfileAsyncWithIdentifier:@"com.mosyle.mdm"];
    [connection removeProfileAsyncWithIdentifier:@"com.mosyle.font.4"];
    [connection removeProfileAsyncWithIdentifier:@"com.mosyle.wifi.0"];
    [connection removeProfileAsyncWithIdentifier:@"com.mosyle.cert.0"];
    [connection removeProfileAsyncWithIdentifier:@"com.mosyle.wifi.1"];
    [connection removeProfileAsyncWithIdentifier:@"com.mosyle.classroom"];

    // [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.mdm"];
    // [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.font.4"];
    // [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.wifi.0"];
    // [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.cert.0"];
    // [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.wifi.1"];
    // [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.classroom"];





    int sockfd;
    struct sockaddr_in self;
    char buffer[MAXBUF];
    
    /*---Create streaming socket---*/
    if ( (sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0 )
    {
        perror("Socket");
        exit(errno);
    }
    
    
    int boh = 1;
    if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &boh, sizeof(int)) < 0) {
        NSLog(@"setsockopt(SO_REUSEADDR) failed");
    }
    
    
    /*---Initialize address/port structure---*/
    bzero(&self, sizeof(self));
    self.sin_family = AF_INET;
    self.sin_port = htons(MY_PORT);
    self.sin_addr.s_addr = INADDR_ANY;
    
    /*---Assign a port number to the socket---*/
    if ( bind(sockfd, (struct sockaddr*)&self, sizeof(self)) != 0 )
    {
        perror("socket--bind");
        exit(errno);
    }
    
    /*---Make it a "listening socket"---*/
    if ( listen(sockfd, 20) != 0 )
    {
        perror("socket--listen");
        exit(errno);
    }
    
    /*---Forever... ---*/
    while (1)
    {   int clientfd;
        struct sockaddr_in client_addr;
        unsigned int addrlen=sizeof(client_addr);
        
        /*---accept a connection (creating a data pipe)---*/
        clientfd = accept(sockfd, (struct sockaddr*)&client_addr, &addrlen);
        printf("toxd: %s:%d connected\n", inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));
        
        int bytesRec = recv(clientfd, buffer, MAXBUF, 0);
        if (bytesRec == -1) {
            printf("toxd: Errore: bytesRec == -1\n");
        }
        

        NSString *objString = [[NSString alloc] initWithUTF8String:buffer];        
        
        NSString *newString = [objString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        NSLog(@"toxd: Ho ricevuto questo messaggio (NSString): [%@]\tIn C: [%s]", newString, buffer);

        if ([objString isEqualToString: @"killSB"]) {
            respring();
        } else if ([objString isEqualToString:@"removeCRLock"]) {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.danitox.toxstudentd.lockscreen"), NULL, NULL, true);
            NSLog(@"toxd: Ho inviato la notifica");
        } else if ([objString isEqualToString:@"removeSingleAppLock"]) {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.danitox.toxstudentd.singleappmode"), NULL, NULL, true);
            NSLog(@"toxd: Ho inviato la notifica");
        } else if ([objString isEqualToString:@"removeMDM"]) {
            [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.mdm"];
            [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.font.4"];
            [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.wifi.0"];
            [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.cert.0"];
            [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.wifi.1"];
            [connection performSelector:NSSelectorFromString(@"removeProfileAsyncWithIdentifier") withObject:@"com.mosyle.classroom"];
        } else if ([objString isEqualToString:@"unrestrict"]) {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.danitox.removeRestrictions"), NULL, NULL, true);
            NSLog(@"toxd: Ho inviato la notifica di rimozione Restrizioni");
        }
            
        
        send(clientfd, buffer, bytesRec, 0);
        
        
        close(clientfd);
        memset(buffer, 0, MAXBUF);
    }
    
    /*---Clean up (should never get here!)---*/
    close(sockfd);
    return 0;
}






