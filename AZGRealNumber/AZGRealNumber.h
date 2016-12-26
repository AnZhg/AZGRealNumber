//
//  AZGRealNumber.h
//  SciCalculator
//
//  Created by 安志钢 on 2016-09-21.
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

enum {
    AZGOrderedAscending = -1,
    AZGOrderedSame,
    AZGOrderedDescending
};
typedef int AZGComparisonResult;

enum {
    AZGRoundPlain,
    AZGRoundDown,
    AZGRoundUp,
    AZGRoundBankers
};
typedef int AZGRoundingMode;

@interface AZGRealNumber : NSObject

- (instancetype)initWithMantissa:(NSString *)mantissa exponent:(int)exponent isNegative:(BOOL)isNegative;
- (instancetype)initWithRealNumber:(AZGRealNumber *)realNumber;
- (instancetype)initWithPowerOfTen:(int)power isNegative:(BOOL)isNegative;

+ (AZGRealNumber *)realNumberWithMantissa:(NSString *)mantissa exponent:(int)exponent isNegative:(BOOL)isNegative;
+ (AZGRealNumber *)realNumberWithPowerOfTen:(int)power isNegative:(BOOL)isNegative;
+ (AZGRealNumber *)zero;
+ (AZGRealNumber *)positiveOne;
+ (AZGRealNumber *)negativeOne;
+ (AZGRealNumber *)pi;
+ (AZGRealNumber *)e;

+ (AZGRealNumber *)random;

- (BOOL)isPositive;
- (BOOL)isZero;
- (BOOL)isNegative;
- (BOOL)isOdd;
- (BOOL)isEven;

- (AZGRealNumber *)realNumberByRoundingInMode:(AZGRoundingMode)roundingMode withScale:(int)scale;

- (AZGComparisonResult)absoluteCompare:(AZGRealNumber *)realNumber;
- (AZGComparisonResult)compare:(AZGRealNumber *)realNumber;

- (AZGRealNumber *)absoluteValue;

- (AZGRealNumber *)realNumberByAdding:(AZGRealNumber *)operand;
- (AZGRealNumber *)realNumberBySubtracting:(AZGRealNumber *)operand;
- (AZGRealNumber *)realNumberByNegation;
- (AZGRealNumber *)realNumberByMultiplyingBy:(AZGRealNumber *)operand;
- (AZGRealNumber *)realNumberByDividingBy:(AZGRealNumber *)operand;
- (AZGRealNumber *)realNumberByModulus:(AZGRealNumber *)operand;
- (AZGRealNumber *)realNumberByRaisingToPower:(AZGRealNumber *)power;
- (AZGRealNumber *)realNumberByRaisingToRoot:(AZGRealNumber *)root;
- (AZGRealNumber *)realNumberByFactorial;

- (AZGRealNumber *)greatestCommonDivisor:(AZGRealNumber *)operand;
- (AZGRealNumber *)leastCommonMultiple:(AZGRealNumber *)operand;

@end
