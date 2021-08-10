//
//  NSURLRequest+APLWKWebViewController.m
//  
//
//  Created by apploft GmbH on 10.08.21.
//

#import "NSURLRequest+APLWKWebViewController.h"

@implementation NSURLRequest (APLWKWebViewController)

- (BOOL)aplWKWWisMailtoRequest {
    return [[[[self URL] scheme] lowercaseString] isEqualToString:@"mailto"];
}

- (NSArray<NSString *>*)aplWKWWmailRecipients {
    NSMutableArray *recipients = [NSMutableArray array];

    if (!self.aplWKWWisMailtoRequest) {
        return recipients;
    }

    NSArray *rawURLparts = [[self.URL resourceSpecifier] componentsSeparatedByString:@"?"];

    // Assuming web pages send to one recipient.
    if (rawURLparts.count != 1) {
        return recipients;
    }

    NSString *defaultRecipient = [rawURLparts objectAtIndex:0];

    if (defaultRecipient.length) {
        [recipients addObject:defaultRecipient];
    }

    return recipients;
}

@end
