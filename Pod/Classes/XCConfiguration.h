/*
 * Copyright (c) 2012 Eloy Durán <eloy.de.enige@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

@interface XCConfiguration : NSObject <NSCopying>

/// Creates an instance of \c XcodeConfiguration containing no settings.
/// \remarks This is a designated initializer.
- (id)init;
/// Creates an instance of \c XcodeConfiguration containing settings obtained from parsing the given string.
- (id)initWithConfigurationFileContents:(NSString *)sourceCode;
/// Creates an instance of \c XcodeConfiguration containing settings obtained from reading from the given stream.
- (id)initByParsingData:(NSData *)data;
/// Creates an instance of \c XcodeConfiguration containing settings obtained from reading from the given URL.
- (id)initByReadingURL:(NSURL *)location;
/// Creates an instance of \c XcodeConfiguration containing settings obtained from the given dictionary.
/// \param settings A dictionary in the format of the dictionary returned by the \c configurationDictionary method.
/// \remarks This is a designated initializer.
- (id)initWithConfigurationDictionary:(NSDictionary *)settings;

#pragma mark Properties

@property (readonly) NSMutableDictionary *attributes;
@property (readonly) NSMutableSet *frameworks;
@property (readonly) NSMutableSet *weakLinkedFrameworks;
@property (readonly) NSMutableSet *otherLibraries;
@property (readonly) NSMutableArray *includedFiles;

- (NSDictionary *)configurationDictionary;
- (NSString *)configurationFileSource;

- (void)mergeConfiguration:(XCConfiguration *)other;

@end
