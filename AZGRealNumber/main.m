//
//  main.m
//  AZGRealNumber
//
//  Created by 安志钢 on 16-12-26.
//  Copyright (c) 2016年 安志钢. All rights reserved.
//
/*
 IMPORTANT:
 
 BSD 3-Clause License
 
 Copyright (c) 2016, AN Zhigang
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the copyright holder nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import "AZGRealNumber.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        // insert code here...
        AZGRealNumber *real1 = [[AZGRealNumber alloc] initWithMantissa:@"100" exponent:0 isNegative:NO];
        AZGRealNumber *real2 = [[AZGRealNumber alloc] initWithMantissa:@"3" exponent:0 isNegative:NO];
        AZGRealNumber *real3 = [[AZGRealNumber alloc] initWithMantissa:@"4" exponent:0 isNegative:NO];
        AZGRealNumber *real4 = [[AZGRealNumber alloc] initWithMantissa:@"2" exponent:0 isNegative:NO];
        
        NSLog(@"%@ / %@\n= %@", real1, real2, [real1 realNumberByDividingBy:real2]);
        NSLog(@"sqrt(%@)\n= %@", real2, [real2 realNumberByRaisingToRoot:real4]);
        NSLog(@"factorial(%@)\n= %@", real1, [real1 realNumberByFactorial]);
        NSLog(@"Greatest Common Divisor of %@ and %@ is\n %@", real1, real3, [real1 greatestCommonDivisor:real3]);
        NSLog(@"Least Common Multiple of %@ and %@ is\n %@", real1, real3, [real1 leastCommonMultiple:real3]);
        NSLog(@"Generate a random number:\n%@", [AZGRealNumber random]);
        
    }
    return 0;
}

