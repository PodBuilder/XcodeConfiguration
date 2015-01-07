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

#import "XCConfiguration.h"
#import <NSString+ShellSplit/NSString+WKShellSplit.h>

static id XCReduceArray(NSArray *array, id initialValue, void (^block)(id reduced, id value)) {
    id result = initialValue;
    NSUInteger limit = array.count;
    
    for (NSUInteger i = 0; i < limit; i++) {
        block(result, array[i]);
    }
    
    return result;
}

static NSArray *XCTranslateArray(NSArray *array, id (^block)(id value)) {
    NSMutableArray *result = [NSMutableArray array];
    NSUInteger limit = array.count;
    
    for (NSUInteger i = 0; i < limit; i++) {
        [result addObject:block(array[i])];
    }
    
    return result;
}

static NSArray *XCTranslateDictionary(NSDictionary *dictionary, id (^block)(id key, id value)) {
    NSMutableArray *result = [NSMutableArray array];
    
    for (id key in dictionary.allKeys) {
        [result addObject:block(key, dictionary[key])];
    }
    
    return result;
}

#pragma mark -

@implementation XCConfiguration

- (id)init {
    return [self initWithConfigurationDictionary:@{}];
}

- (id)initWithConfigurationFileContents:(NSString *)sourceCode {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    NSArray *lines = [sourceCode componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *includedFiles = [NSMutableArray array];
    
    for (NSString *rawLine in lines) {
        NSString *line = [self stripCommentFromConfigurationFileLine:rawLine];
        if ([line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) continue;
        
        NSString *includePath;
        BOOL isInclude = [self extractIncludeFileTarget:&includePath fromConfigurationFileLine:line];
        
        if (isInclude) {
            [includedFiles addObject:includePath];
        } else {
            NSString *key;
            NSString *value;
            BOOL isRegularLine = [self extractKey:&key andValue:&value fromConfigurationFileLine:line];
            
            if (isRegularLine) {
                key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                values[key] = value;
            }
        }
    }
    
    XCConfiguration *config = [self initWithConfigurationDictionary:values];
    config->_includedFiles = includedFiles;
    return config;
}

- (id)initByParsingData:(NSData *)data {
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [self initWithConfigurationFileContents:string];
}

- (id)initByReadingURL:(NSURL *)location {
    return [self initByParsingData:[NSData dataWithContentsOfURL:location]];
}

- (id)initWithConfigurationDictionary:(NSDictionary *)settings {
    self = [super init];
    
    _attributes = [[NSMutableDictionary alloc] init];
    _includedFiles = [[NSMutableArray alloc] init];
    _frameworks = [[NSMutableSet alloc] init];
    _weakLinkedFrameworks = [[NSMutableSet alloc] init];
    _otherLibraries = [[NSMutableSet alloc] init];
    
    NSString *flagString = settings[@"OTHER_LDFLAGS"] ?: @"";
    flagString = [[flagString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
    
    NSArray *flags = [flagString componentsSplitUsingShellQuotingRules];
    NSMutableArray *fixedFlags = [NSMutableArray array];
    
    BOOL skipNextFlag = NO;
    NSInteger count = flags.count;
    for (NSInteger i = 0; i < count; i++) {
        if (skipNextFlag) { skipNextFlag = NO; continue; }
        
        NSString *flag = flags[i];
        
        if ([flag hasPrefix:@"-l"]) {
            [self.otherLibraries addObject:[flag substringFromIndex:2]];
        } else if ([flag hasPrefix:@"-framework"]) {
            [self.frameworks addObject:flags[i + 1]];
            skipNextFlag = YES;
        } else if ([flag hasPrefix:@"-weak_framework"]) {
            [self.weakLinkedFrameworks addObject:flags[i + 1]];
            skipNextFlag = YES;
        } else {
            NSRange range = [flag rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (!(range.location == NSNotFound && range.length == 0)) {
                [fixedFlags addObject:[NSString stringWithFormat:@"\"%@\"", flag]];
            } else {
                [fixedFlags addObject:flag];
            }
        }
    }
    
    _attributes = [settings mutableCopy];
    if (fixedFlags.count != 0) self.attributes[@"OTHER_LDFLAGS"] = [fixedFlags componentsJoinedByString:@" "];
    else [self.attributes removeObjectForKey:@"OTHER_LDFLAGS"];
    
    return self;
}

#pragma mark Properties

- (NSDictionary *)configurationDictionary {
    NSMutableDictionary *settings = [self.attributes mutableCopy];
    NSMutableString *flags = settings[@"OTHER_LDFLAGS"] ?: @"";
    flags = [[flags stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
    
    [flags appendString:XCReduceArray(self.otherLibraries.allObjects, [NSMutableString string], ^(id reduced, id value) {
        [reduced appendFormat:@" -l%@", value];
    })];
    
    [flags appendString:XCReduceArray(self.frameworks.allObjects, [NSMutableString string], ^(id reduced, id value) {
        [reduced appendFormat:@" -framework %@", value];
    })];
    
    [flags appendString:XCReduceArray(self.weakLinkedFrameworks.allObjects, [NSMutableString string], ^(id reduced, id value) {
        [reduced appendFormat:@" -weak_framework %@", value];
    })];
    
    NSString *finalFlags = [flags stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (finalFlags.length != 0) settings[@"OTHER_LDFLAGS"] = finalFlags;
    else [settings removeObjectForKey:@"OTHER_LDFLAGS"];
    
    return settings;
}

- (NSString *)configurationFileSource {
    NSArray *includeLines = XCTranslateArray(self.includedFiles, ^id(id value) {
        NSString *pathWithExtension = value;
        if (![pathWithExtension.pathExtension isEqualToString:@"xcconfig"]) {
            pathWithExtension = [pathWithExtension stringByAppendingPathExtension:@"xcconfig"];
        }
        
        return [NSString stringWithFormat:@"#include \"%@\"", pathWithExtension];
    });
    
    NSArray *settingLines = XCTranslateDictionary(self.configurationDictionary, ^id(id key, id value) {
        return [NSString stringWithFormat:@"%@ = %@", key, value];
    });
    
    // Write out the #include lines, a blank line (for aesthetic purposes), and then the setting lines.
    NSMutableArray *lines = [NSMutableArray array];
    [lines addObjectsFromArray:includeLines];
    [lines addObject:@""];
    [lines addObjectsFromArray:settingLines];
    [lines addObject:@""];
    
    return [lines componentsJoinedByString:@"\n"];
}

- (void)mergeConfiguration:(XCConfiguration *)other {
    for (NSString *key in other.attributes.allKeys) {
        NSString *oldValue = [self.attributes[key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *newValue = [other.attributes[key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSArray *existing = [oldValue componentsSplitUsingShellQuotingRules];
        if ([existing containsObject:newValue]) self.attributes[key] = oldValue;
        else self.attributes[key] = [NSString stringWithFormat:@"%@ %@", oldValue, newValue];
    }
    
    [self.frameworks addObjectsFromArray:other.frameworks.allObjects];
    [self.weakLinkedFrameworks addObjectsFromArray:other.weakLinkedFrameworks.allObjects];
    [self.otherLibraries addObjectsFromArray:other.otherLibraries.allObjects];
}

#pragma mark Private Methods

- (NSString *)stripCommentFromConfigurationFileLine:(NSString *)line {
    static NSRegularExpression *commentRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        commentRegex = [NSRegularExpression regularExpressionWithPattern:@"//.*$" options:NSRegularExpressionAnchorsMatchLines error:NULL];
        NSAssert(commentRegex != nil, @"Could not compile regular expression");
    });
    
    return [commentRegex stringByReplacingMatchesInString:line options:0 range:NSMakeRange(0, line.length) withTemplate:@""];
}

- (BOOL)extractIncludeFileTarget:(NSString **)path fromConfigurationFileLine:(NSString *)line {
    static NSRegularExpression *includeRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        includeRegex = [NSRegularExpression regularExpressionWithPattern:@"#include\\s*\"(.+)\"" options:0 error:NULL];
        NSAssert(includeRegex != nil, @"Could not compile regular expression");
    });
    
    NSTextCheckingResult *match = [includeRegex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
    if (match == nil) return NO;
    
    NSRange range = [match rangeAtIndex:1];
    if (range.location == NSNotFound && range.length == 0) return NO;
    if (path != NULL) *path = [line substringWithRange:range];
    return YES;
}

- (BOOL)extractKey:(NSString **)key andValue:(NSString **)value fromConfigurationFileLine:(NSString *)line {
    static NSRegularExpression *lineRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lineRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*(.+?)\\s*=\\s*(.+)$" options:0 error:NULL];
        NSAssert(lineRegex != nil, @"Could not compile regular expression");
    });
    
    NSTextCheckingResult *match = [lineRegex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
    
    NSRange range = [match rangeAtIndex:1];
    if (range.location == NSNotFound && range.length == 0) return NO;
    if (key != NULL) *key = [line substringWithRange:range];
    
    range = [match rangeAtIndex:2];
    if (range.location == NSNotFound && range.length == 0) return NO;
    if (value != NULL) *value = [line substringWithRange:range];
    
    return YES;
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    XCConfiguration *copy = [[[self class] allocWithZone:zone] initWithConfigurationDictionary:[self.configurationDictionary copy]];
    copy->_includedFiles = [_includedFiles copy];
    return copy;
}

#pragma mark NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p: %@>", NSStringFromClass([self class]), self, self.configurationDictionary];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[self class]]) return NO;
    
    XCConfiguration *other = object;
    return ([self.attributes isEqual:other.attributes] &&
            [self.frameworks isEqual:other.frameworks] &&
            [self.weakLinkedFrameworks isEqual:other.frameworks] &&
            [self.otherLibraries isEqual:other.otherLibraries]);
}

- (NSUInteger)hash {
    return self.attributes.hash ^ self.frameworks.hash ^ self.weakLinkedFrameworks.hash ^ self.otherLibraries.hash;
}

@end
