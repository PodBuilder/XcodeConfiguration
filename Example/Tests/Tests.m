//
//  XcodeConfigurationTests.m
//  XcodeConfigurationTests
//
//  Created by William Kent on 07/02/2014.
//  Copyright (c) 2014 William Kent. All rights reserved.
//

#import <XcodeConfiguration/XCConfiguration.h>

SpecBegin(XCConfiguration)

describe(@"string parsing", ^{
    it(@"should parse xcconfig text correctly", ^{
        NSString *source = @"FOO = BAR\n";
        XCConfiguration *config = [[XCConfiguration alloc] initWithConfigurationFileContents:source];
        expect(config.configurationDictionary).to.equal(@{ @"FOO": @"BAR" });
    });
    
    it(@"should strip comments correctly", ^{
        NSString *source = @"FOO = BAR // I am a comment\n//I am another comment";
        XCConfiguration *config = [[XCConfiguration alloc] initWithConfigurationFileContents:source];
        expect(config.configurationDictionary).to.equal(@{ @"FOO": @"BAR" });
    });
    
    it(@"should handle empty lines correctly", ^{
        NSString *source = @"   \n   \n";
        XCConfiguration *config = [[XCConfiguration alloc] initWithConfigurationFileContents:source];
        expect(config.configurationDictionary).to.haveCountOf(0);
    });
});

describe(@"dictionary parsing", ^{
    it(@"should parse a dictionary correctly", ^{
        NSDictionary *values = @{ @"FOO": @"BAR" };
        XCConfiguration *config = [[XCConfiguration alloc] initWithConfigurationDictionary:values];
        expect(config.configurationDictionary).to.equal(values);
    });
});

describe(@"OTHER_LDFLAGS handling", ^{
    it(@"should expand OTHER_LDFLAGS correctly", ^{
        NSDictionary *values = @{ @"OTHER_LDFLAGS": @"-lz -framework Foundation -weak_framework UIKit" };
        XCConfiguration *config = [[XCConfiguration alloc] initWithConfigurationDictionary:values];
        
        expect(config.otherLibraries.allObjects).to.equal(@[ @"z" ]);
        expect(config.frameworks.allObjects).to.equal(@[ @"Foundation" ]);
        expect(config.weakLinkedFrameworks.allObjects).to.equal(@[ @"UIKit" ]);
    });
    
    it(@"should expand OTHER_LDFLAGS correctly when parsing a string", ^{
        NSString *source = @"OTHER_LDFLAGS = -lz -framework Foundation -weak_framework UIKit -dead_strip";
        XCConfiguration *config = [[XCConfiguration alloc] initWithConfigurationFileContents:source];
        
        expect(config.attributes[@"OTHER_LDFLAGS"]).to.equal(@"-dead_strip");
        expect(config.frameworks.allObjects).to.equal(@[ @"Foundation" ]);
        expect(config.weakLinkedFrameworks.allObjects).to.equal(@[ @"UIKit" ]);
        expect(config.otherLibraries.allObjects).to.equal(@[ @"z" ]);
    });
    
    it(@"should preserve unhandled OTHER_LDFLAGS", ^{
        NSDictionary *values = @{ @"OTHER_LDFLAGS": @"-lz -dead_strip" };
        XCConfiguration *config = [[XCConfiguration alloc] initWithConfigurationDictionary:values];
        
        expect(config.otherLibraries.allObjects).to.equal(@[ @"z" ]);
        expect(config.attributes[@"OTHER_LDFLAGS"]).to.equal(@"-dead_strip");
    });
    
    it(@"should recreate OTHER_LDFLAGS in -configurationDictionary", ^{
        XCConfiguration *config = [[XCConfiguration alloc] init];
        config.attributes[@"OTHER_LDFLAGS"] = @"-dead_strip";
        [config.otherLibraries addObject:@"z"];
        [config.frameworks addObject:@"Foundation"];
        [config.weakLinkedFrameworks addObject:@"UIKit"];
        
        // The behavior of the below code is due to the fact
        // that the order of the words in the OTHER_LDFLAGS value
        // is not guaranteed to be stable.
        NSDictionary *values = config.configurationDictionary;
        NSArray *flags = values[@"OTHER_LDFLAGS"];
        expect(flags).to.contain(@"-dead_strip");
        expect(flags).to.contain(@"-framework Foundation");
        expect(flags).to.contain(@"-weak_framework UIKit");
        expect(flags).to.contain(@"-lz");
    });
});

SpecEnd
