//
//  NSURLRequest+APLWKWebViewController.h
//  
//
//  Created by apploft GmbH on 10.08.21.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (APLWKWebViewController)

- (BOOL)aplWKWWisMailtoRequest;
- (NSArray<NSString *>*)aplWKWWmailRecipients;

@end
