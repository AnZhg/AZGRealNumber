//
//  AZGRealNumber.m
//  SciCalculator
//
//  Created by 安志钢 on 2016-09-21.
//  Copyright (c) 2016年 安志钢. All rights reserved.
//

#import "AZGRealNumber.h"
#import <Accelerate/Accelerate.h>

@implementation AZGRealNumber
{
    bool _isNegative;
    unsigned short int _mantissa[6];
    signed int _exponent;
    unsigned short int _length;
}

- (instancetype)init
{
    self = [super init];
    
    if (self != nil) {
        _isNegative = false;
        _mantissa[0] = 0;
        _exponent = 0;
        _length = 1;
    }
    
    return self;
}

- (instancetype)initWithMantissa:(NSString *)mantissa exponent:(int)exponent isNegative:(BOOL)isNegative
{
    self = [super init];
    
    if (self != nil) {
        _exponent = exponent;
        
        unsigned int m[6] = {0};
        
        int i, j, k, carry;
        
        // Extra place for carry use and NULL terminator.
        char s[mantissa.length + 2];
        s[0] = '0';
        memcpy(s + 1, mantissa.UTF8String, mantissa.length + 1);
        
        // Scan all leading 0's.
        for (i = 1; i < (int)strlen(s); ++i) {
            if (s[i] != '0') {
                break;
            }
        }
        
        // Scan all trailing 0's.
        for (j = (int)strlen(s) - 1; j > i; --j) {
            if (s[j] != '0') {
                break;
            }
        }
        
        // Delete trailing 0's and change exponent.
        _exponent += strlen(s) - j - 1;
        
        if (j - i + 1 > 28) {
            // Truncate extra digits.
            // Change exponent.
            _exponent += j - i - 27;
            
            k = i + 28;
            carry = (s[k] > '4');
            s[k] = '\0';
            
            while (carry) {
                s[--k] += carry;
                carry = (s[k] > '9');
                if (carry) {
                    s[k] -= 10;
                }
            }
            
            if (k == i - 1) {
                // Carry results in extra digit. Need to truncate again.
                ++_exponent;
                
                k = i + 27;
                carry = (s[k] > '4');
                s[k] = '\0';
                
                while (carry) {
                    s[--k] += carry;
                    carry = (s[k] > '9');
                    if (carry) {
                        s[k] -= 10;
                    }
                }
                
                // Valid digits start index.
                --i;
            }
            
            // Valid digits end index.
            j = i + 27;
            
            // Carry may result in trailing 0's.
            while (s[j] == '0') {
                --j;
                ++_exponent;
            }
        }
        
        for (k = i; k <= j; ++k) {
            m[0] = m[0] * 10 + s[k] - '0';
            m[1] *= 10;
            m[2] *= 10;
            m[3] *= 10;
            m[4] *= 10;
            m[5] *= 10;
            
            for (i = 0; i < 6; ++i) {
                if (m[i] > 0xFFFF) {
                    m[i + 1] += m[i] >> 16;
                    m[i] &= 0xFFFF;
                }
            }
        }
        
        _mantissa[0] = (unsigned short int)m[0];
        _mantissa[1] = (unsigned short int)m[1];
        _mantissa[2] = (unsigned short int)m[2];
        _mantissa[3] = (unsigned short int)m[3];
        _mantissa[4] = (unsigned short int)m[4];
        _mantissa[5] = (unsigned short int)m[5];
        
        _length = 6;
        while (_mantissa[_length - 1] == 0) {
            if (_length != 1) {
                --_length;
            } else {
                break;
            }
        }
        
        if ((_length == 1) && (_mantissa[0] == 0)) {
            // 0 * 10 ^ n = 0.
            _exponent = 0;
            
            // -0 = 0.
            _isNegative = NO;
        } else {
            _isNegative = isNegative;
        }
    }

    return self;
}

- (instancetype)initWithRealNumber:(AZGRealNumber *)realNumber
{
    self = [super init];
    
    if (self != nil) {
        _isNegative = realNumber->_isNegative;
        _exponent = realNumber->_exponent;
        _length = realNumber->_length;
        
        int i;
        for (i = 0; i < _length; ++i) {
            _mantissa[i] = realNumber->_mantissa[i];
        }
    }
    
    return self;
}

- (instancetype)initWithPowerOfTen:(int)power isNegative:(BOOL)isNegative
{
    self = [super init];
    
    if (self != nil) {
        _isNegative = isNegative;
        _exponent = power;
        _length = 1;
        _mantissa[0] = 1;
    }
    
    return self;
}

+ (AZGRealNumber *)realNumberWithMantissa:(NSString *)mantissa exponent:(int)exponent isNegative:(BOOL)isNegative
{
    return [[AZGRealNumber alloc] initWithMantissa:mantissa exponent:exponent isNegative:isNegative];
}

+ (AZGRealNumber *)realNumberWithPowerOfTen:(int)power isNegative:(BOOL)isNegative
{
    return [[AZGRealNumber alloc] initWithPowerOfTen:power isNegative:isNegative];
}

+ (AZGRealNumber *)zero
{
    return [[AZGRealNumber alloc] init];
}

+ (AZGRealNumber *)positiveOne
{
    AZGRealNumber *positiveOne = [[AZGRealNumber alloc] init];
    
    positiveOne->_mantissa[0] = 1;
    positiveOne->_length = 1;
    positiveOne->_exponent = 0;
    positiveOne->_isNegative = NO;
    
    return positiveOne;
}

+ (AZGRealNumber *)negativeOne
{
    AZGRealNumber *negativeOne = [[AZGRealNumber alloc] init];
    
    negativeOne->_mantissa[0] = 1;
    negativeOne->_length = 1;
    negativeOne->_exponent = 0;
    negativeOne->_isNegative = YES;
    
    return negativeOne;
}

+ (AZGRealNumber *)pi
{
    AZGRealNumber *pi = [[AZGRealNumber alloc] init];
    
    pi->_mantissa[0] = 15543u;
    pi->_mantissa[1] = 34450u;
    pi->_mantissa[2] = 40768u;
    pi->_mantissa[3] = 283u;
    pi->_mantissa[4] = 43551u;
    pi->_mantissa[5] = 2598u;
    pi->_length = 6;
    pi->_isNegative = NO;
    pi->_exponent = -27;
    
    return pi;
}

+ (AZGRealNumber *)e
{
    AZGRealNumber *e = [[AZGRealNumber alloc] init];
    
    e->_mantissa[0] = 19183u;
    e->_mantissa[1] = 49292u;
    e->_mantissa[2] = 18795u;
    e->_mantissa[3] = 12593u;
    e->_mantissa[4] = 33425u;
    e->_mantissa[5] = 2248u;
    e->_length = 6;
    e->_isNegative = NO;
    e->_exponent = -27;
    
    return e;
}

+ (AZGRealNumber *)random
{
    return [AZGRealNumber realNumberWithMantissa:[NSString stringWithFormat:@"0%07i%07i%07i%07i", arc4random_uniform(9999999), arc4random_uniform(9999999), arc4random_uniform(9999999), arc4random_uniform(9999999)] exponent:-28 isNegative:NO];
}

- (BOOL)isPositive
{
    return !(self.isZero || self.isNegative);
}

- (BOOL)isZero
{
    return ((_length == 1) && (_mantissa[0] == 0));
}

- (BOOL)isNegative
{
    return _isNegative;
}

- (BOOL)isOdd
{
    return (_mantissa[0] & 1);
}

- (BOOL)isEven
{
    return (!self.isOdd);
}

+ (AZGRealNumber *)numericalError
{
    AZGRealNumber *error = [[AZGRealNumber alloc] init];
    error->_mantissa[0] = 1u;
    error->_length = 1;
    error->_isNegative = NO;
    error->_exponent = -29;
    
    return error;
}

void mantissaToCString(AZGRealNumber *realNumber, char **str)
{
    char s[29];
    unsigned short mantissa[6];
    char *p = s;
    int i, j, carry;
    
    memset(s, '0', sizeof(s) - 1);
    s[28] = '\0';
    
    memcpy(mantissa, realNumber->_mantissa, sizeof(mantissa));
    
    for (i = 0; i < 96; ++i) {
        carry = (mantissa[5] >= 0x8000);
        
        // Shift n[] left, doubling it.
        mantissa[5] = ((mantissa[5] << 1) & 0xFFFF) + (mantissa[4] >= 0x8000);
        mantissa[4] = ((mantissa[4] << 1) & 0xFFFF) + (mantissa[3] >= 0x8000);
        mantissa[3] = ((mantissa[3] << 1) & 0xFFFF) + (mantissa[2] >= 0x8000);
        mantissa[2] = ((mantissa[2] << 1) & 0xFFFF) + (mantissa[1] >= 0x8000);
        mantissa[1] = ((mantissa[1] << 1) & 0xFFFF) + (mantissa[0] >= 0x8000);
        mantissa[0] = ((mantissa[0] << 1) & 0xFFFF);
        
        // Add s[] to itself in decimal, doubling it.
        for (j = sizeof(s) - 2; j >= 0; --j) {
            s[j] += s[j] - '0' + carry;
            
            carry = (s[j] > '9');
            
            if (carry) {
                s[j] -= 10;
            }
        }
    }
    
    while ((p[0] == '0') && (p < &s[sizeof(s) - 2])) {
        ++p;
    }
    
    memcpy(*str, p, 29 - (p - s));
}

- (AZGRealNumber *)realNumberByRoundingInMode:(AZGRoundingMode)roundingMode withScale:(int)scale
{
    // Handle special case.
    if ((_length == 1) && (_mantissa[0] == 0)) {
        // For zero, no matter which decimal place is rounded to, result is zero.
        return [AZGRealNumber zero];
    }
    
    char s[30];
    char *p = s + 1;
    mantissaToCString(self, &p);
    int i;
    
    if (scale + (int)strlen(p) + _exponent < 0) {
        // Truncate more than existing digits.
        switch (roundingMode) {
            case AZGRoundPlain:
                return [AZGRealNumber zero];
            case AZGRoundDown:
                if (_isNegative) {
                    return [AZGRealNumber realNumberWithMantissa:@"1" exponent:-scale isNegative:YES];
                } else {
                    return [AZGRealNumber zero];
                }
            case AZGRoundUp:
                if (_isNegative) {
                    return [AZGRealNumber zero];
                } else {
                    return [AZGRealNumber realNumberWithMantissa:@"1" exponent:-scale isNegative:NO];
                }
            case AZGRoundBankers:
                return [AZGRealNumber zero];
                
            default:
                return nil;
        }
    } else if (scale + (int)strlen(p) + _exponent == 0) {
        // Truncate exactly all digits.
        switch (roundingMode) {
            case AZGRoundPlain:
                if (p[0] > '4') {
                    // msb carry when rounding it off.
                    if (_isNegative) {
                        return [AZGRealNumber negativeOne];
                    } else {
                        return [AZGRealNumber positiveOne];
                    }
                } else {
                    // p[0] <= '4'. No carry.
                    return [AZGRealNumber zero];
                }
            case AZGRoundDown:
                if (_isNegative) {
                    return [AZGRealNumber realNumberWithMantissa:@"1" exponent:-scale isNegative:YES];
                } else {
                    return [AZGRealNumber zero];
                }
            case AZGRoundUp:
                if (_isNegative) {
                    return [AZGRealNumber zero];
                } else {
                    return [AZGRealNumber realNumberWithMantissa:@"1" exponent:-scale isNegative:NO];
                }
            case AZGRoundBankers:
                return [AZGRealNumber zero];
                
            default:
                return nil;
        }
        
    } else if (scale + _exponent >= 0) {
        // No digit trucated.
        return self;
    } else {
        // Truncte part of digits.
        s[0] = '0';
        
        i = (int)strlen(p) + _exponent + scale;
        
        switch (roundingMode) {
            case AZGRoundPlain:
                p[i - 1] += (p[i] > '4');
                p[i--] = '\0';
                
                while (p[i] > '9') {
                    p[i] -= 10;
                    ++p[--i];
                }
                break;
            case AZGRoundDown:
                if (_isNegative) {
                    p[i--] = '\0';
                    ++p[i];
                    
                    while (p[i] > '9') {
                        p[i] -= 10;
                        ++p[--i];
                    }
                } else {
                    p[i] = '\0';
                }
                break;
            case AZGRoundUp:
                if (_isNegative) {
                    p[i] = '\0';
                } else {
                    p[i--] = '\0';
                    ++p[i];
                    
                    while (p[i] > '9') {
                        p[i] -= 10;
                        ++p[--i];
                    }
                }
                break;
            case AZGRoundBankers:
                if ((!_isNegative) && (scale + _exponent == -1) && (p[i] == '5')) {
                    // If number is positive, and falls to right at the middle, then round to nearest even digit.
                    if ((p[i - 1] - '0') & 1) {
                        // Digit is odd.
                        p[i--] = '\0';
                        ++p[i];
                        
                        while (p[i] > '9') {
                            p[i] -= 10;
                            ++p[--i];
                        }
                    } else {
                        // Digit is even.
                        p[i] = '\0';
                    }
                } else {
                    // Otherwise, the same as round plain.
                    p[i - 1] += (p[i] > '4');
                    p[i--] = '\0';
                    
                    while (p[i] > '9') {
                        p[i] -= 10;
                        ++p[--i];
                    }
                }
                break;
                
            default:
                break;
        }
        
        
        return [AZGRealNumber realNumberWithMantissa:[NSString stringWithFormat:@"%s", s] exponent:-scale isNegative:_isNegative];
    }
}

- (AZGComparisonResult)absoluteCompare:(AZGRealNumber *)realNumber
{
    // Handle special cases.
    BOOL isZero = ((_length == 1) && (_mantissa[0] == 0));
    BOOL opdIsZero = ((realNumber->_length == 1) && (realNumber->_mantissa[0] == 0));
    
    if (isZero && opdIsZero) {
        // 0 == 0.
        return AZGOrderedSame;
    } else if (isZero && (!opdIsZero)) {
        // 0 < non-zero.
        return AZGOrderedAscending;
    } else if ((!isZero) && opdIsZero) {
        // non-zero > 0.
        return AZGOrderedDescending;
    }
    
    AZGComparisonResult result = AZGOrderedSame;
    
    int i;
    
    char m[29];
    char m_opd[29];
    
    char *p = m;
    
    int mLen, opdLen;
    
    // Two non-zero numbers.
    mantissaToCString(self, &p);
    
    p = m_opd;
    mantissaToCString(realNumber, &p);
    
    mLen = (int)strlen(m);
    opdLen = (int)strlen(m_opd);
    
    if (_exponent + mLen == realNumber->_exponent + opdLen) {
        if (_length == realNumber->_length) {
            for (i = 0; i < mLen; ++i) {
                if (m[i] > m_opd[i]) {
                    result = AZGOrderedDescending;
                    break;
                } else if (m[i] < m_opd[i]) {
                    result = AZGOrderedAscending;
                    break;
                }
            }
        } else {
            // _length != realNumber->_length
            if (_length > realNumber->_length) {
                result = AZGOrderedDescending;
            } else {
                // _length < realNumber->length.
                result = AZGOrderedAscending;
            }
        }
    } else {
        // _exponent + mLen != realNumber->_exponent + opdLen.
        if (_exponent + mLen > realNumber->_exponent + opdLen) {
            result = AZGOrderedDescending;
        } else {
            // _exponent + mLen < realNumber->_exponent + opdLen.
            result = AZGOrderedAscending;
        }
    }
    
    return result;
}

- (AZGComparisonResult)compare:(AZGRealNumber *)realNumber
{
    AZGComparisonResult result = AZGOrderedSame;
    
    if (_isNegative == realNumber->_isNegative) {
        result = [self absoluteCompare:realNumber];
        
        if (_isNegative) {
            result = -result;
        }
    } else {
        // _isNegative != realNumber->_isNegative
        result = (int)realNumber->_isNegative - (int)_isNegative;
    }
    
    return result;
}

- (AZGRealNumber *)absoluteValue
{
    AZGRealNumber *result = [[AZGRealNumber alloc] initWithRealNumber:self];
    result->_isNegative = NO;
    return result;
}

- (AZGRealNumber *)realNumberByAdding:(AZGRealNumber *)operand
{
    // Handle special cases.
    if ((_length == 1) && (_mantissa[0] == 0)) {
        return operand;
    } else if ((operand->_length == 1) && (operand->_mantissa[0] == 0)) {
        return self;
    }
    
    int exponent;
    BOOL isNegative;
    
    AZGRealNumber *num;
    
    int i, j, k, carry;
    
    int msb1, msb2;
    
    char m1[30] = {'0'};
    char m2[30] = {'0'};
    char *p;
    p = m1 + 1;
    mantissaToCString(self, &p);
    p = m2 + 1;
    mantissaToCString(operand, &p);
    
    char *p1;
    char *p2;
    
    if (_exponent != operand->_exponent) {
        // Calculate position of the most significant bit.
        msb1 = (int)strlen(m1) + _exponent;
        msb2 = (int)strlen(m2) + operand->_exponent;
        
        if (msb1 - msb2 > 28) {
            return self;
        } else if (msb1 - msb2 < -28) {
            return operand;
        } else if ((msb1 - msb2 == 28) || (msb1 - msb2 == -28)) {
            // Make sure p1 points to mantissa of the number with larger msb position.
            if (msb1 >= msb2) {
                p1 = m1;
                p2 = m2;
                
                exponent = operand->_exponent;
                num = self;
            } else {
                // sum1 < sum2.
                p1 = m2;
                p2 = m1;
                
                exponent = _exponent;
                num = operand;
            }
            
            carry = (p2[1] > '4');
            
            if (carry) {
                --exponent;
                
                // Pad number with larger exponent with trailing 0's.
                for (i = (int)strlen(p1); i < 29; ++i) {
                    p1[i] = '0';
                }
                
                ++p[i];
                
                // Add overwritten NULL terminator.
                p1[i + 1] = '\0';
                
                while (p1[i] > '9') {
                    p1[i--] -= 10;
                    ++p1[i];
                }
            } else {
                // No carry.
                return num;
            }
        } else {
            // -20 < msb1 - msb2 < 20.
            
            // Make sure p1 points to mantissa of the number with larger exponent.
            if (_exponent >= operand->_exponent) {
                p1 = m1;
                p2 = m2;
                
                j = _exponent;
                exponent = operand->_exponent;
            } else {
                // _exponent < operand->_exponent
                p1 = m2;
                p2 = m1;
                
                j = operand->_exponent;
                exponent = _exponent;
            }
            
            // Avoid over padding number with larger exponent.
            j -= exponent;
            k = 30 - (int)strlen(p1) >= j ? 0 : j - (30 - (int)strlen(p1));
            
            // Pad trailing 0's to mantissa of number with larger exponent.
            i = (int)strlen(p1);
            for (; j > k; --j) {
                p1[i++] = '0';
            }
            // Add overwritten NULL terminator.
            p1[i] = '\0';
            
            if (j != 0) {
                // Truncate mantissa of number with smaller exponent.
                exponent += j;
                i = (int)strlen(p2) - j;
                carry = (p2[i] > '4');
                
                while (carry) {
                    p2[i--] -= 10;
                    carry = ((++p2[i]) > '9');
                }
                p[(int)strlen(p2) - j] = '\0';
                
                if (i == -1) {
                    // Carry results in extra digit. Need to truncate again.
                    i = (int)strlen(p2) - 1;
                    carry = (p2[i] > '4');
                    
                    for (; i > 0; --i) {
                        p2[i] = p2[i - 1] + carry;
                        
                        if (p2[i] > '9') {
                            p2[i] -= 10;
                            carry = 1;
                        } else {
                            carry = 0;
                        }
                    }
                    p2[0] = '0';
                }
            }
        }
    } else {
        exponent = _exponent;
    }
    
//    m1[0] = '0';
//    m2[0] = '0';
    
    if (strlen(m1) == strlen(m2)) {
        // Use j as comparison result here.
        j = 0;
        for (i = 0; i < (int)strlen(m1); ++i) {
            if (m1[i] > m2[i]) {
                j = 1;
                break;
            } else if (m1[i] < m2[i]) {
                j = -1;
                break;
            }
        }
        
        if (j >= 0) {
            // mantissa(self) >= mantissa(operand).
            goto ADD_DESCEND;
        } else {
            // mantissa(self) < mantissa(operand).
            goto ADD_ASCEND;
        }
    } else if (strlen(m1) > strlen(m2)) {
    ADD_DESCEND:
        i = (int)strlen(m1);
        j = (int)strlen(m2);
        p1 = m1;
        p2 = m2;
        
        isNegative = _isNegative;
    } else {
    ADD_ASCEND:
        i = (int)strlen(m2);
        j = (int)strlen(m1);
        p1 = m2;
        p2 = m1;
        
        isNegative = operand->_isNegative;
    }
    
    carry = 0;
    
    if (_isNegative == operand->_isNegative) {
        for (--i, --j; j > 0; --i, --j) {
            p1[i] += p2[j] + carry - '0';
            
            if (p1[i] > '9') {
                p1[i] -= 10;
                carry = 1;
            } else {
                carry = 0;
            }
        }
        
        for (; i >= 0; --i) {
            p1[i] += carry;
            
            if (p1[i] > '9') {
                p1[i] -= 10;
                carry = 1;
            } else {
                break;
            }
        }
    } else {
        // _isNegative != operand->_isNegative.
        for (--i, --j; j > 0; --i, --j) {
            p1[i] -= p2[j] + carry - '0';
            
            if (p1[i] < '0') {
                p1[i] += 10;
                carry = 1;
            } else {
                carry = 0;
            }
        }
        
        for (; i >= 0; --i) {
            p1[i] -= carry;
            
            if (p1[i] < '0') {
                p1[i] += 10;
                carry = 1;
            } else {
                break;
            }
        }
    }
    
    // Delete leading 0's.
    while (*p1 == '0') {
        ++p1;
    }
    
    return [AZGRealNumber realNumberWithMantissa:[NSString stringWithFormat:@"%s", p1] exponent:exponent isNegative:isNegative];
}

- (AZGRealNumber *)realNumberBySubtracting:(AZGRealNumber *)operand
{
    // a - b = a + (-b).
    return [self realNumberByAdding:[operand realNumberByNegation]];
}

- (AZGRealNumber *)realNumberByNegation
{
    AZGRealNumber *result = [[AZGRealNumber alloc] initWithRealNumber:self];
    result->_isNegative = !(result->_isNegative);
    return result;
}

    // Optimized version.
    // 2-Point.
    // Since 8th ~ 15th is always 0, the original expression is simplified as follows.
/*
 * 32-Point Number Theoretic Transform and Inverse Number Theoretic Transform.
 *
 * Forward matrix (mod 193):
 *    0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
 *  ╭                                                               ╮
 * 0│ 1   1   1   1   1   1   1   1   1   1   1   1   1   1   1   1 │
 * 1│ 1   3   9  27  81  50 150  64 192 190 184 166 112 143  43 129 │
 * 2│ 1   9  81 150 192 184 112  43   1   9  81 150 192 184 112  43 │
 * 3│ 1  27 150 190 112 129   9  50 192 166  43   3  81  64 184 143 │
 * 4│ 1  81 192 112   1  81 192 112   1  81 192 112   1  81 192 112 │
 * 5│ 1  50 184 129  81 190  43  27 192 143   9  64 112   3 150 166 │
 * 6│ 1 150 112   9 192  43  81 184   1 150 112   9 192  43  81 184 │
 * 7│ 1  64  43  50 112  27 184   3 192 129 150 143  81 166   9 190 │
 * 8│ 1 192   1 192   1 192   1 192   1 192   1 192   1 192   1 192 │
 * 9│ 1 190   9 166  81 143 150 129 192   3 184  27 112  50  43  64 │
 * A│ 1 184  81  43 192   9 112 150   1 184  81  43 192   9 112 150 │
 * B│ 1 166 150   3 112  64   9 143 192  27  43 190  81 129 184  50 │
 * C│ 1 112 192  81   1 112 192  81   1  12 192  81   1 112 191  81 │
 * D│ 1 143 184  64  81   3  43 166 192  50   9 129 112 190 150  27 │
 * E│ 1  43 112 184 192 150  81   9   1  43 112 184 192 150  81   9 │
 * F│ 1 129  43 143 112 166 184 190 192  64 150  50  81  27   9   3 │
 *  ╰                                                               ╯
 * 32⁻¹ = 187
 */
void ntt_mod193(unsigned int **io)
{
    // Decimation-in-Time (Cooley-Tukey Algorithm).
    
    unsigned int tmp[32];
    
    // Initialize.
    tmp[ 0] = (*io)[ 0]; tmp[ 1] = (*io)[16]; tmp[ 2] = (*io)[ 8]; tmp[ 3] = (*io)[24];
    tmp[ 4] = (*io)[ 4]; tmp[ 5] = (*io)[20]; tmp[ 6] = (*io)[12]; tmp[ 7] = (*io)[28];
    tmp[ 8] = (*io)[ 2]; tmp[ 9] = (*io)[18]; tmp[10] = (*io)[10]; tmp[11] = (*io)[26];
    tmp[12] = (*io)[ 6]; tmp[13] = (*io)[22]; tmp[14] = (*io)[14]; tmp[15] = (*io)[30];
    tmp[16] = (*io)[ 1]; tmp[17] = (*io)[17]; tmp[18] = (*io)[ 9]; tmp[19] = (*io)[25];
    tmp[20] = (*io)[ 5]; tmp[21] = (*io)[21]; tmp[22] = (*io)[13]; tmp[23] = (*io)[29];
    tmp[24] = (*io)[ 3]; tmp[25] = (*io)[19]; tmp[26] = (*io)[11]; tmp[27] = (*io)[27];
    tmp[28] = (*io)[ 7]; tmp[29] = (*io)[23]; tmp[30] = (*io)[15]; tmp[31] = (*io)[31];
    
    // 2-Point.
    (*io)[ 0] = (tmp[ 0] + tmp[ 1]) % 193; (*io)[ 1] = (tmp[ 0] + 192 * tmp[ 1]) % 193;
    (*io)[ 2] = (tmp[ 2] + tmp[ 3]) % 193; (*io)[ 3] = (tmp[ 2] + 192 * tmp[ 3]) % 193;
    (*io)[ 4] = (tmp[ 4] + tmp[ 5]) % 193; (*io)[ 5] = (tmp[ 4] + 192 * tmp[ 5]) % 193;
    (*io)[ 6] = (tmp[ 6] + tmp[ 7]) % 193; (*io)[ 7] = (tmp[ 6] + 192 * tmp[ 7]) % 193;
    (*io)[ 8] = (tmp[ 8] + tmp[ 9]) % 193; (*io)[ 9] = (tmp[ 8] + 192 * tmp[ 9]) % 193;
    (*io)[10] = (tmp[10] + tmp[11]) % 193; (*io)[11] = (tmp[10] + 192 * tmp[11]) % 193;
    (*io)[12] = (tmp[12] + tmp[13]) % 193; (*io)[13] = (tmp[12] + 192 * tmp[13]) % 193;
    (*io)[14] = (tmp[14] + tmp[15]) % 193; (*io)[15] = (tmp[14] + 192 * tmp[15]) % 193;
    (*io)[16] = (tmp[16] + tmp[17]) % 193; (*io)[17] = (tmp[16] + 192 * tmp[17]) % 193;
    (*io)[18] = (tmp[18] + tmp[19]) % 193; (*io)[19] = (tmp[18] + 192 * tmp[19]) % 193;
    (*io)[20] = (tmp[20] + tmp[21]) % 193; (*io)[21] = (tmp[20] + 192 * tmp[21]) % 193;
    (*io)[22] = (tmp[22] + tmp[23]) % 193; (*io)[23] = (tmp[22] + 192 * tmp[23]) % 193;
    (*io)[24] = (tmp[24] + tmp[25]) % 193; (*io)[25] = (tmp[24] + 192 * tmp[25]) % 193;
    (*io)[26] = (tmp[26] + tmp[27]) % 193; (*io)[27] = (tmp[26] + 192 * tmp[27]) % 193;
    (*io)[28] = (tmp[28] + tmp[29]) % 193; (*io)[29] = (tmp[28] + 192 * tmp[29]) % 193;
    (*io)[30] = (tmp[30] + tmp[31]) % 193; (*io)[31] = (tmp[30] + 192 * tmp[31]) % 193;
    
    // 4-Point.
    tmp[ 0] = ((*io)[ 0] +       (*io)[ 2]) % 193; tmp[ 1] = ((*io)[ 1] + 112 * (*io)[ 3]) % 193;
    tmp[ 2] = ((*io)[ 0] + 192 * (*io)[ 2]) % 193; tmp[ 3] = ((*io)[ 1] +  81 * (*io)[ 3]) % 193;
    tmp[ 4] = ((*io)[ 4] +       (*io)[ 6]) % 193; tmp[ 5] = ((*io)[ 5] + 112 * (*io)[ 7]) % 193;
    tmp[ 6] = ((*io)[ 4] + 192 * (*io)[ 6]) % 193; tmp[ 7] = ((*io)[ 5] +  81 * (*io)[ 7]) % 193;
    tmp[ 8] = ((*io)[ 8] +       (*io)[10]) % 193; tmp[ 9] = ((*io)[ 9] + 112 * (*io)[11]) % 193;
    tmp[10] = ((*io)[ 8] + 192 * (*io)[10]) % 193; tmp[11] = ((*io)[ 9] +  81 * (*io)[11]) % 193;
    tmp[12] = ((*io)[12] +       (*io)[14]) % 193; tmp[13] = ((*io)[13] + 112 * (*io)[15]) % 193;
    tmp[14] = ((*io)[12] + 192 * (*io)[14]) % 193; tmp[15] = ((*io)[13] +  81 * (*io)[15]) % 193;
    tmp[16] = ((*io)[16] +       (*io)[18]) % 193; tmp[17] = ((*io)[17] + 112 * (*io)[19]) % 193;
    tmp[18] = ((*io)[16] + 192 * (*io)[18]) % 193; tmp[19] = ((*io)[17] +  81 * (*io)[19]) % 193;
    tmp[20] = ((*io)[20] +       (*io)[22]) % 193; tmp[21] = ((*io)[21] + 112 * (*io)[23]) % 193;
    tmp[22] = ((*io)[20] + 192 * (*io)[22]) % 193; tmp[23] = ((*io)[21] +  81 * (*io)[23]) % 193;
    tmp[24] = ((*io)[24] +       (*io)[26]) % 193; tmp[25] = ((*io)[25] + 112 * (*io)[27]) % 193;
    tmp[26] = ((*io)[24] + 192 * (*io)[26]) % 193; tmp[27] = ((*io)[25] +  81 * (*io)[27]) % 193;
    tmp[28] = ((*io)[28] +       (*io)[30]) % 193; tmp[29] = ((*io)[29] + 112 * (*io)[31]) % 193;
    tmp[30] = ((*io)[28] + 192 * (*io)[30]) % 193; tmp[31] = ((*io)[29] +  81 * (*io)[31]) % 193;
    
    // 8-Point.
    (*io)[ 0] = (tmp[ 0] +       tmp[ 4]) % 193; (*io)[ 1] = (tmp[ 1] +  43 * tmp[ 5]) % 193;
    (*io)[ 2] = (tmp[ 2] + 112 * tmp[ 6]) % 193; (*io)[ 3] = (tmp[ 3] + 184 * tmp[ 7]) % 193;
    (*io)[ 4] = (tmp[ 0] + 192 * tmp[ 4]) % 193; (*io)[ 5] = (tmp[ 1] + 150 * tmp[ 5]) % 193;
    (*io)[ 6] = (tmp[ 2] +  81 * tmp[ 6]) % 193; (*io)[ 7] = (tmp[ 3] +   9 * tmp[ 7]) % 193;
    (*io)[ 8] = (tmp[ 8] +       tmp[12]) % 193; (*io)[ 9] = (tmp[ 9] +  43 * tmp[13]) % 193;
    (*io)[10] = (tmp[10] + 112 * tmp[14]) % 193; (*io)[11] = (tmp[11] + 184 * tmp[15]) % 193;
    (*io)[12] = (tmp[ 8] + 192 * tmp[12]) % 193; (*io)[13] = (tmp[ 9] + 150 * tmp[13]) % 193;
    (*io)[14] = (tmp[10] +  81 * tmp[14]) % 193; (*io)[15] = (tmp[11] +   9 * tmp[15]) % 193;
    (*io)[16] = (tmp[16] +       tmp[20]) % 193; (*io)[17] = (tmp[17] +  43 * tmp[21]) % 193;
    (*io)[18] = (tmp[18] + 112 * tmp[22]) % 193; (*io)[19] = (tmp[19] + 184 * tmp[23]) % 193;
    (*io)[20] = (tmp[16] + 192 * tmp[20]) % 193; (*io)[21] = (tmp[17] + 150 * tmp[21]) % 193;
    (*io)[22] = (tmp[18] +  81 * tmp[22]) % 193; (*io)[23] = (tmp[19] +   9 * tmp[23]) % 193;
    (*io)[24] = (tmp[24] +       tmp[28]) % 193; (*io)[25] = (tmp[25] +  43 * tmp[29]) % 193;
    (*io)[26] = (tmp[26] + 112 * tmp[30]) % 193; (*io)[27] = (tmp[27] + 184 * tmp[31]) % 193;
    (*io)[28] = (tmp[24] + 192 * tmp[28]) % 193; (*io)[29] = (tmp[25] + 150 * tmp[29]) % 193;
    (*io)[30] = (tmp[26] +  81 * tmp[30]) % 193; (*io)[31] = (tmp[27] +   9 * tmp[31]) % 193;
    
    // 16-Point.
    tmp[ 0] = ((*io)[ 0] +       (*io)[ 8]) % 193; tmp[ 1] = ((*io)[ 1] +  64 * (*io)[ 9]) % 193;
    tmp[ 2] = ((*io)[ 2] +  43 * (*io)[10]) % 193; tmp[ 3] = ((*io)[ 3] +  50 * (*io)[11]) % 193;
    tmp[ 4] = ((*io)[ 4] + 112 * (*io)[12]) % 193; tmp[ 5] = ((*io)[ 5] +  27 * (*io)[13]) % 193;
    tmp[ 6] = ((*io)[ 6] + 184 * (*io)[14]) % 193; tmp[ 7] = ((*io)[ 7] +   3 * (*io)[15]) % 193;
    tmp[ 8] = ((*io)[ 0] + 192 * (*io)[ 8]) % 193; tmp[ 9] = ((*io)[ 1] + 129 * (*io)[ 9]) % 193;
    tmp[10] = ((*io)[ 2] + 150 * (*io)[10]) % 193; tmp[11] = ((*io)[ 3] + 143 * (*io)[11]) % 193;
    tmp[12] = ((*io)[ 4] +  81 * (*io)[12]) % 193; tmp[13] = ((*io)[ 5] + 166 * (*io)[13]) % 193;
    tmp[14] = ((*io)[ 6] +   9 * (*io)[14]) % 193; tmp[15] = ((*io)[ 7] + 190 * (*io)[15]) % 193;
    tmp[16] = ((*io)[16] +       (*io)[24]) % 193; tmp[17] = ((*io)[17] +  64 * (*io)[25]) % 193;
    tmp[18] = ((*io)[18] +  43 * (*io)[26]) % 193; tmp[19] = ((*io)[19] +  50 * (*io)[27]) % 193;
    tmp[20] = ((*io)[20] + 112 * (*io)[28]) % 193; tmp[21] = ((*io)[21] +  27 * (*io)[29]) % 193;
    tmp[22] = ((*io)[22] + 184 * (*io)[30]) % 193; tmp[23] = ((*io)[23] +   3 * (*io)[31]) % 193;
    tmp[24] = ((*io)[16] + 192 * (*io)[24]) % 193; tmp[25] = ((*io)[17] + 129 * (*io)[25]) % 193;
    tmp[26] = ((*io)[18] + 150 * (*io)[26]) % 193; tmp[27] = ((*io)[19] + 143 * (*io)[27]) % 193;
    tmp[28] = ((*io)[20] +  81 * (*io)[28]) % 193; tmp[29] = ((*io)[21] + 166 * (*io)[29]) % 193;
    tmp[30] = ((*io)[22] +   9 * (*io)[30]) % 193; tmp[31] = ((*io)[23] + 190 * (*io)[31]) % 193;
    
    // 32-Point.
    (*io)[ 0] = (tmp[ 0] +       tmp[16]) % 193; (*io)[ 1] = (tmp[ 1] +   8 * tmp[17]) % 193;
    (*io)[ 2] = (tmp[ 2] +  64 * tmp[18]) % 193; (*io)[ 3] = (tmp[ 3] + 126 * tmp[19]) % 193;
    (*io)[ 4] = (tmp[ 4] +  43 * tmp[20]) % 193; (*io)[ 5] = (tmp[ 5] + 151 * tmp[21]) % 193;
    (*io)[ 6] = (tmp[ 6] +  50 * tmp[22]) % 193; (*io)[ 7] = (tmp[ 7] +  14 * tmp[23]) % 193;
    (*io)[ 8] = (tmp[ 8] + 112 * tmp[24]) % 193; (*io)[ 9] = (tmp[ 9] + 124 * tmp[25]) % 193;
    (*io)[10] = (tmp[10] +  27 * tmp[26]) % 193; (*io)[11] = (tmp[11] +  23 * tmp[27]) % 193;
    (*io)[12] = (tmp[12] + 184 * tmp[28]) % 193; (*io)[13] = (tmp[13] + 121 * tmp[29]) % 193;
    (*io)[14] = (tmp[14] +   3 * tmp[30]) % 193; (*io)[15] = (tmp[15] +  24 * tmp[31]) % 193;
    (*io)[16] = (tmp[ 0] + 192 * tmp[16]) % 193; (*io)[17] = (tmp[ 1] + 185 * tmp[17]) % 193;
    (*io)[18] = (tmp[ 2] + 129 * tmp[18]) % 193; (*io)[19] = (tmp[ 3] +  67 * tmp[19]) % 193;
    (*io)[20] = (tmp[ 4] + 150 * tmp[20]) % 193; (*io)[21] = (tmp[ 5] +  42 * tmp[21]) % 193;
    (*io)[22] = (tmp[ 6] + 143 * tmp[22]) % 193; (*io)[23] = (tmp[ 7] + 179 * tmp[23]) % 193;
    (*io)[24] = (tmp[ 8] +  81 * tmp[24]) % 193; (*io)[25] = (tmp[ 9] +  69 * tmp[25]) % 193;
    (*io)[26] = (tmp[10] + 166 * tmp[26]) % 193; (*io)[27] = (tmp[11] + 170 * tmp[27]) % 193;
    (*io)[28] = (tmp[12] +   9 * tmp[28]) % 193; (*io)[29] = (tmp[13] +  72 * tmp[29]) % 193;
    (*io)[30] = (tmp[14] + 190 * tmp[30]) % 193; (*io)[31] = (tmp[15] + 169 * tmp[31]) % 193;
}

void intt_mod193(unsigned int **io)
{
    unsigned int tmp[32];
    
    // Initialize.
    tmp[ 0] = (*io)[ 0]; tmp[ 1] = (*io)[16]; tmp[ 2] = (*io)[ 8]; tmp[ 3] = (*io)[24];
    tmp[ 4] = (*io)[ 4]; tmp[ 5] = (*io)[20]; tmp[ 6] = (*io)[12]; tmp[ 7] = (*io)[28];
    tmp[ 8] = (*io)[ 2]; tmp[ 9] = (*io)[18]; tmp[10] = (*io)[10]; tmp[11] = (*io)[26];
    tmp[12] = (*io)[ 6]; tmp[13] = (*io)[22]; tmp[14] = (*io)[14]; tmp[15] = (*io)[30];
    tmp[16] = (*io)[ 1]; tmp[17] = (*io)[17]; tmp[18] = (*io)[ 9]; tmp[19] = (*io)[25];
    tmp[20] = (*io)[ 5]; tmp[21] = (*io)[21]; tmp[22] = (*io)[13]; tmp[23] = (*io)[29];
    tmp[24] = (*io)[ 3]; tmp[25] = (*io)[19]; tmp[26] = (*io)[11]; tmp[27] = (*io)[27];
    tmp[28] = (*io)[ 7]; tmp[29] = (*io)[23]; tmp[30] = (*io)[15]; tmp[31] = (*io)[31];
    
    // 2-Point.
    (*io)[ 0] = (tmp[ 0] + tmp[ 1]) % 193; (*io)[ 1] = (tmp[ 0] + 192 * tmp[ 1]) % 193;
    (*io)[ 2] = (tmp[ 2] + tmp[ 3]) % 193; (*io)[ 3] = (tmp[ 2] + 192 * tmp[ 3]) % 193;
    (*io)[ 4] = (tmp[ 4] + tmp[ 5]) % 193; (*io)[ 5] = (tmp[ 4] + 192 * tmp[ 5]) % 193;
    (*io)[ 6] = (tmp[ 6] + tmp[ 7]) % 193; (*io)[ 7] = (tmp[ 6] + 192 * tmp[ 7]) % 193;
    (*io)[ 8] = (tmp[ 8] + tmp[ 9]) % 193; (*io)[ 9] = (tmp[ 8] + 192 * tmp[ 9]) % 193;
    (*io)[10] = (tmp[10] + tmp[11]) % 193; (*io)[11] = (tmp[10] + 192 * tmp[11]) % 193;
    (*io)[12] = (tmp[12] + tmp[13]) % 193; (*io)[13] = (tmp[12] + 192 * tmp[13]) % 193;
    (*io)[14] = (tmp[14] + tmp[15]) % 193; (*io)[15] = (tmp[14] + 192 * tmp[15]) % 193;
    (*io)[16] = (tmp[16] + tmp[17]) % 193; (*io)[17] = (tmp[16] + 192 * tmp[17]) % 193;
    (*io)[18] = (tmp[18] + tmp[19]) % 193; (*io)[19] = (tmp[18] + 192 * tmp[19]) % 193;
    (*io)[20] = (tmp[20] + tmp[21]) % 193; (*io)[21] = (tmp[20] + 192 * tmp[21]) % 193;
    (*io)[22] = (tmp[22] + tmp[23]) % 193; (*io)[23] = (tmp[22] + 192 * tmp[23]) % 193;
    (*io)[24] = (tmp[24] + tmp[25]) % 193; (*io)[25] = (tmp[24] + 192 * tmp[25]) % 193;
    (*io)[26] = (tmp[26] + tmp[27]) % 193; (*io)[27] = (tmp[26] + 192 * tmp[27]) % 193;
    (*io)[28] = (tmp[28] + tmp[29]) % 193; (*io)[29] = (tmp[28] + 192 * tmp[29]) % 193;
    (*io)[30] = (tmp[30] + tmp[31]) % 193; (*io)[31] = (tmp[30] + 192 * tmp[31]) % 193;
    
    // 4-Point.
    tmp[ 0] = ((*io)[ 0] +       (*io)[ 2]) % 193; tmp[ 1] = ((*io)[ 1] +  81 * (*io)[ 3]) % 193;
    tmp[ 2] = ((*io)[ 0] + 192 * (*io)[ 2]) % 193; tmp[ 3] = ((*io)[ 1] + 112 * (*io)[ 3]) % 193;
    tmp[ 4] = ((*io)[ 4] +       (*io)[ 6]) % 193; tmp[ 5] = ((*io)[ 5] +  81 * (*io)[ 7]) % 193;
    tmp[ 6] = ((*io)[ 4] + 192 * (*io)[ 6]) % 193; tmp[ 7] = ((*io)[ 5] + 112 * (*io)[ 7]) % 193;
    tmp[ 8] = ((*io)[ 8] +       (*io)[10]) % 193; tmp[ 9] = ((*io)[ 9] +  81 * (*io)[11]) % 193;
    tmp[10] = ((*io)[ 8] + 192 * (*io)[10]) % 193; tmp[11] = ((*io)[ 9] + 112 * (*io)[11]) % 193;
    tmp[12] = ((*io)[12] +       (*io)[14]) % 193; tmp[13] = ((*io)[13] +  81 * (*io)[15]) % 193;
    tmp[14] = ((*io)[12] + 192 * (*io)[14]) % 193; tmp[15] = ((*io)[13] + 112 * (*io)[15]) % 193;
    tmp[16] = ((*io)[16] +       (*io)[18]) % 193; tmp[17] = ((*io)[17] +  81 * (*io)[19]) % 193;
    tmp[18] = ((*io)[16] + 192 * (*io)[18]) % 193; tmp[19] = ((*io)[17] + 112 * (*io)[19]) % 193;
    tmp[20] = ((*io)[20] +       (*io)[22]) % 193; tmp[21] = ((*io)[21] +  81 * (*io)[23]) % 193;
    tmp[22] = ((*io)[20] + 192 * (*io)[22]) % 193; tmp[23] = ((*io)[21] + 112 * (*io)[23]) % 193;
    tmp[24] = ((*io)[24] +       (*io)[26]) % 193; tmp[25] = ((*io)[25] +  81 * (*io)[27]) % 193;
    tmp[26] = ((*io)[24] + 192 * (*io)[26]) % 193; tmp[27] = ((*io)[25] + 112 * (*io)[27]) % 193;
    tmp[28] = ((*io)[28] +       (*io)[30]) % 193; tmp[29] = ((*io)[29] +  81 * (*io)[31]) % 193;
    tmp[30] = ((*io)[28] + 192 * (*io)[30]) % 193; tmp[31] = ((*io)[29] + 112 * (*io)[31]) % 193;
    
    // 8-Point.
    (*io)[ 0] = (tmp[ 0] +       tmp[ 4]) % 193; (*io)[ 1] = (tmp[ 1] +   9 * tmp[ 5]) % 193;
    (*io)[ 2] = (tmp[ 2] +  81 * tmp[ 6]) % 193; (*io)[ 3] = (tmp[ 3] + 150 * tmp[ 7]) % 193;
    (*io)[ 4] = (tmp[ 0] + 192 * tmp[ 4]) % 193; (*io)[ 5] = (tmp[ 1] + 184 * tmp[ 5]) % 193;
    (*io)[ 6] = (tmp[ 2] + 112 * tmp[ 6]) % 193; (*io)[ 7] = (tmp[ 3] +  43 * tmp[ 7]) % 193;
    (*io)[ 8] = (tmp[ 8] +       tmp[12]) % 193; (*io)[ 9] = (tmp[ 9] +   9 * tmp[13]) % 193;
    (*io)[10] = (tmp[10] +  81 * tmp[14]) % 193; (*io)[11] = (tmp[11] + 150 * tmp[15]) % 193;
    (*io)[12] = (tmp[ 8] + 192 * tmp[12]) % 193; (*io)[13] = (tmp[ 9] + 184 * tmp[13]) % 193;
    (*io)[14] = (tmp[10] + 112 * tmp[14]) % 193; (*io)[15] = (tmp[11] +  43 * tmp[15]) % 193;
    (*io)[16] = (tmp[16] +       tmp[20]) % 193; (*io)[17] = (tmp[17] +   9 * tmp[21]) % 193;
    (*io)[18] = (tmp[18] +  81 * tmp[22]) % 193; (*io)[19] = (tmp[19] + 150 * tmp[23]) % 193;
    (*io)[20] = (tmp[16] + 192 * tmp[20]) % 193; (*io)[21] = (tmp[17] + 184 * tmp[21]) % 193;
    (*io)[22] = (tmp[18] + 112 * tmp[22]) % 193; (*io)[23] = (tmp[19] +  43 * tmp[23]) % 193;
    (*io)[24] = (tmp[24] +       tmp[28]) % 193; (*io)[25] = (tmp[25] +   9 * tmp[29]) % 193;
    (*io)[26] = (tmp[26] +  81 * tmp[30]) % 193; (*io)[27] = (tmp[27] + 150 * tmp[31]) % 193;
    (*io)[28] = (tmp[24] + 192 * tmp[28]) % 193; (*io)[29] = (tmp[25] + 184 * tmp[29]) % 193;
    (*io)[30] = (tmp[26] + 112 * tmp[30]) % 193; (*io)[31] = (tmp[27] +  43 * tmp[31]) % 193;
    
    // 16-Point.
    tmp[ 0] = ((*io)[ 0] +       (*io)[ 8]) % 193; tmp[ 1] = ((*io)[ 1] + 190 * (*io)[ 9]) % 193;
    tmp[ 2] = ((*io)[ 2] +   9 * (*io)[10]) % 193; tmp[ 3] = ((*io)[ 3] + 166 * (*io)[11]) % 193;
    tmp[ 4] = ((*io)[ 4] +  81 * (*io)[12]) % 193; tmp[ 5] = ((*io)[ 5] + 143 * (*io)[13]) % 193;
    tmp[ 6] = ((*io)[ 6] + 150 * (*io)[14]) % 193; tmp[ 7] = ((*io)[ 7] + 129 * (*io)[15]) % 193;
    tmp[ 8] = ((*io)[ 0] + 192 * (*io)[ 8]) % 193; tmp[ 9] = ((*io)[ 1] +   3 * (*io)[ 9]) % 193;
    tmp[10] = ((*io)[ 2] + 184 * (*io)[10]) % 193; tmp[11] = ((*io)[ 3] +  27 * (*io)[11]) % 193;
    tmp[12] = ((*io)[ 4] + 112 * (*io)[12]) % 193; tmp[13] = ((*io)[ 5] +  50 * (*io)[13]) % 193;
    tmp[14] = ((*io)[ 6] +  43 * (*io)[14]) % 193; tmp[15] = ((*io)[ 7] +  64 * (*io)[15]) % 193;
    tmp[16] = ((*io)[16] +       (*io)[24]) % 193; tmp[17] = ((*io)[17] + 190 * (*io)[25]) % 193;
    tmp[18] = ((*io)[18] +   9 * (*io)[26]) % 193; tmp[19] = ((*io)[19] + 166 * (*io)[27]) % 193;
    tmp[20] = ((*io)[20] +  81 * (*io)[28]) % 193; tmp[21] = ((*io)[21] + 143 * (*io)[29]) % 193;
    tmp[22] = ((*io)[22] + 150 * (*io)[30]) % 193; tmp[23] = ((*io)[23] + 129 * (*io)[31]) % 193;
    tmp[24] = ((*io)[16] + 192 * (*io)[24]) % 193; tmp[25] = ((*io)[17] +   3 * (*io)[25]) % 193;
    tmp[26] = ((*io)[18] + 184 * (*io)[26]) % 193; tmp[27] = ((*io)[19] +  27 * (*io)[27]) % 193;
    tmp[28] = ((*io)[20] + 112 * (*io)[28]) % 193; tmp[29] = ((*io)[21] +  50 * (*io)[29]) % 193;
    tmp[30] = ((*io)[22] +  43 * (*io)[30]) % 193; tmp[31] = ((*io)[23] +  64 * (*io)[31]) % 193;
    
    // 32-Point.
    (*io)[ 0] = (tmp[ 0] +       tmp[16]) * 187 % 193; (*io)[ 1] = (tmp[ 1] + 169 * tmp[17]) * 187 % 193;
    (*io)[ 2] = (tmp[ 2] + 190 * tmp[18]) * 187 % 193; (*io)[ 3] = (tmp[ 3] +  72 * tmp[19]) * 187 % 193;
    (*io)[ 4] = (tmp[ 4] +   9 * tmp[20]) * 187 % 193; (*io)[ 5] = (tmp[ 5] + 170 * tmp[21]) * 187 % 193;
    (*io)[ 6] = (tmp[ 6] + 166 * tmp[22]) * 187 % 193; (*io)[ 7] = (tmp[ 7] +  69 * tmp[23]) * 187 % 193;
    (*io)[ 8] = (tmp[ 8] +  81 * tmp[24]) * 187 % 193; (*io)[ 9] = (tmp[ 9] + 179 * tmp[25]) * 187 % 193;
    (*io)[10] = (tmp[10] + 143 * tmp[26]) * 187 % 193; (*io)[11] = (tmp[11] +  42 * tmp[27]) * 187 % 193;
    (*io)[12] = (tmp[12] + 150 * tmp[28]) * 187 % 193; (*io)[13] = (tmp[13] +  67 * tmp[29]) * 187 % 193;
    (*io)[14] = (tmp[14] + 129 * tmp[30]) * 187 % 193; (*io)[15] = (tmp[15] + 185 * tmp[31]) * 187 % 193;
    (*io)[16] = (tmp[ 0] + 192 * tmp[16]) * 187 % 193; (*io)[17] = (tmp[ 1] +  24 * tmp[17]) * 187 % 193;
    (*io)[18] = (tmp[ 2] +   3 * tmp[18]) * 187 % 193; (*io)[19] = (tmp[ 3] + 121 * tmp[19]) * 187 % 193;
    (*io)[20] = (tmp[ 4] + 184 * tmp[20]) * 187 % 193; (*io)[21] = (tmp[ 5] +  23 * tmp[21]) * 187 % 193;
    (*io)[22] = (tmp[ 6] +  27 * tmp[22]) * 187 % 193; (*io)[23] = (tmp[ 7] + 124 * tmp[23]) * 187 % 193;
    (*io)[24] = (tmp[ 8] + 112 * tmp[24]) * 187 % 193; (*io)[25] = (tmp[ 9] +  14 * tmp[25]) * 187 % 193;
    (*io)[26] = (tmp[10] +  50 * tmp[26]) * 187 % 193; (*io)[27] = (tmp[11] + 151 * tmp[27]) * 187 % 193;
    (*io)[28] = (tmp[12] +  43 * tmp[28]) * 187 % 193; (*io)[29] = (tmp[13] + 126 * tmp[29]) * 187 % 193;
    (*io)[30] = (tmp[14] +  64 * tmp[30]) * 187 % 193; (*io)[31] = (tmp[15] +   8 * tmp[31]) * 187 % 193;
}

/*
 * Number theoretic transform mod 641
 * 16⁻¹ = 621
 */
void ntt_mod641(unsigned int **io)
{
    unsigned int tmp[32];
    
    // Initialize.
    tmp[ 0] = (*io)[ 0]; tmp[ 1] = (*io)[16]; tmp[ 2] = (*io)[ 8]; tmp[ 3] = (*io)[24];
    tmp[ 4] = (*io)[ 4]; tmp[ 5] = (*io)[20]; tmp[ 6] = (*io)[12]; tmp[ 7] = (*io)[28];
    tmp[ 8] = (*io)[ 2]; tmp[ 9] = (*io)[18]; tmp[10] = (*io)[10]; tmp[11] = (*io)[26];
    tmp[12] = (*io)[ 6]; tmp[13] = (*io)[22]; tmp[14] = (*io)[14]; tmp[15] = (*io)[30];
    tmp[16] = (*io)[ 1]; tmp[17] = (*io)[17]; tmp[18] = (*io)[ 9]; tmp[19] = (*io)[25];
    tmp[20] = (*io)[ 5]; tmp[21] = (*io)[21]; tmp[22] = (*io)[13]; tmp[23] = (*io)[29];
    tmp[24] = (*io)[ 3]; tmp[25] = (*io)[19]; tmp[26] = (*io)[11]; tmp[27] = (*io)[27];
    tmp[28] = (*io)[ 7]; tmp[29] = (*io)[23]; tmp[30] = (*io)[15]; tmp[31] = (*io)[31];
    
    // 2-Point.
    (*io)[ 0] = (tmp[ 0] + tmp[ 1]) % 641; (*io)[ 1] = (tmp[ 0] + 640 * tmp[ 1]) % 641;
    (*io)[ 2] = (tmp[ 2] + tmp[ 3]) % 641; (*io)[ 3] = (tmp[ 2] + 640 * tmp[ 3]) % 641;
    (*io)[ 4] = (tmp[ 4] + tmp[ 5]) % 641; (*io)[ 5] = (tmp[ 4] + 640 * tmp[ 5]) % 641;
    (*io)[ 6] = (tmp[ 6] + tmp[ 7]) % 641; (*io)[ 7] = (tmp[ 6] + 640 * tmp[ 7]) % 641;
    (*io)[ 8] = (tmp[ 8] + tmp[ 9]) % 641; (*io)[ 9] = (tmp[ 8] + 640 * tmp[ 9]) % 641;
    (*io)[10] = (tmp[10] + tmp[11]) % 641; (*io)[11] = (tmp[10] + 640 * tmp[11]) % 641;
    (*io)[12] = (tmp[12] + tmp[13]) % 641; (*io)[13] = (tmp[12] + 640 * tmp[13]) % 641;
    (*io)[14] = (tmp[14] + tmp[15]) % 641; (*io)[15] = (tmp[14] + 640 * tmp[15]) % 641;
    (*io)[16] = (tmp[16] + tmp[17]) % 641; (*io)[17] = (tmp[16] + 640 * tmp[17]) % 641;
    (*io)[18] = (tmp[18] + tmp[19]) % 641; (*io)[19] = (tmp[18] + 640 * tmp[19]) % 641;
    (*io)[20] = (tmp[20] + tmp[21]) % 641; (*io)[21] = (tmp[20] + 640 * tmp[21]) % 641;
    (*io)[22] = (tmp[22] + tmp[23]) % 641; (*io)[23] = (tmp[22] + 640 * tmp[23]) % 641;
    (*io)[24] = (tmp[24] + tmp[25]) % 641; (*io)[25] = (tmp[24] + 640 * tmp[25]) % 641;
    (*io)[26] = (tmp[26] + tmp[27]) % 641; (*io)[27] = (tmp[26] + 640 * tmp[27]) % 641;
    (*io)[28] = (tmp[28] + tmp[29]) % 641; (*io)[29] = (tmp[28] + 640 * tmp[29]) % 641;
    (*io)[30] = (tmp[30] + tmp[31]) % 641; (*io)[31] = (tmp[30] + 640 * tmp[31]) % 641;
    
    // 4-Point.
    tmp[ 0] = ((*io)[ 0] +       (*io)[ 2]) % 641; tmp[ 1] = ((*io)[ 1] + 154 * (*io)[ 3]) % 641;
    tmp[ 2] = ((*io)[ 0] + 640 * (*io)[ 2]) % 641; tmp[ 3] = ((*io)[ 1] + 487 * (*io)[ 3]) % 641;
    tmp[ 4] = ((*io)[ 4] +       (*io)[ 6]) % 641; tmp[ 5] = ((*io)[ 5] + 154 * (*io)[ 7]) % 641;
    tmp[ 6] = ((*io)[ 4] + 640 * (*io)[ 6]) % 641; tmp[ 7] = ((*io)[ 5] + 487 * (*io)[ 7]) % 641;
    tmp[ 8] = ((*io)[ 8] +       (*io)[10]) % 641; tmp[ 9] = ((*io)[ 9] + 154 * (*io)[11]) % 641;
    tmp[10] = ((*io)[ 8] + 640 * (*io)[10]) % 641; tmp[11] = ((*io)[ 9] + 487 * (*io)[11]) % 641;
    tmp[12] = ((*io)[12] +       (*io)[14]) % 641; tmp[13] = ((*io)[13] + 154 * (*io)[15]) % 641;
    tmp[14] = ((*io)[12] + 640 * (*io)[14]) % 641; tmp[15] = ((*io)[13] + 487 * (*io)[15]) % 641;
    tmp[16] = ((*io)[16] +       (*io)[18]) % 641; tmp[17] = ((*io)[17] + 154 * (*io)[19]) % 641;
    tmp[18] = ((*io)[16] + 640 * (*io)[18]) % 641; tmp[19] = ((*io)[17] + 487 * (*io)[19]) % 641;
    tmp[20] = ((*io)[20] +       (*io)[22]) % 641; tmp[21] = ((*io)[21] + 154 * (*io)[23]) % 641;
    tmp[22] = ((*io)[20] + 640 * (*io)[22]) % 641; tmp[23] = ((*io)[21] + 487 * (*io)[23]) % 641;
    tmp[24] = ((*io)[24] +       (*io)[26]) % 641; tmp[25] = ((*io)[25] + 154 * (*io)[27]) % 641;
    tmp[26] = ((*io)[24] + 640 * (*io)[26]) % 641; tmp[27] = ((*io)[25] + 487 * (*io)[27]) % 641;
    tmp[28] = ((*io)[28] +       (*io)[30]) % 641; tmp[29] = ((*io)[29] + 154 * (*io)[31]) % 641;
    tmp[30] = ((*io)[28] + 640 * (*io)[30]) % 641; tmp[31] = ((*io)[29] + 487 * (*io)[31]) % 641;
    
    // 8-Point.
    (*io)[ 0] = (tmp[ 0] +       tmp[ 4]) % 641; (*io)[ 1] = (tmp[ 1] + 256 * tmp[ 5]) % 641;
    (*io)[ 2] = (tmp[ 2] + 154 * tmp[ 6]) % 641; (*io)[ 3] = (tmp[ 3] + 323 * tmp[ 7]) % 641;
    (*io)[ 4] = (tmp[ 0] + 640 * tmp[ 4]) % 641; (*io)[ 5] = (tmp[ 1] + 385 * tmp[ 5]) % 641;
    (*io)[ 6] = (tmp[ 2] + 487 * tmp[ 6]) % 641; (*io)[ 7] = (tmp[ 3] + 318 * tmp[ 7]) % 641;
    (*io)[ 8] = (tmp[ 8] +       tmp[12]) % 641; (*io)[ 9] = (tmp[ 9] + 256 * tmp[13]) % 641;
    (*io)[10] = (tmp[10] + 154 * tmp[14]) % 641; (*io)[11] = (tmp[11] + 323 * tmp[15]) % 641;
    (*io)[12] = (tmp[ 8] + 640 * tmp[12]) % 641; (*io)[13] = (tmp[ 9] + 385 * tmp[13]) % 641;
    (*io)[14] = (tmp[10] + 487 * tmp[14]) % 641; (*io)[15] = (tmp[11] + 318 * tmp[15]) % 641;
    (*io)[16] = (tmp[16] +       tmp[20]) % 641; (*io)[17] = (tmp[17] + 256 * tmp[21]) % 641;
    (*io)[18] = (tmp[18] + 154 * tmp[22]) % 641; (*io)[19] = (tmp[19] + 323 * tmp[23]) % 641;
    (*io)[20] = (tmp[16] + 640 * tmp[20]) % 641; (*io)[21] = (tmp[17] + 385 * tmp[21]) % 641;
    (*io)[22] = (tmp[18] + 487 * tmp[22]) % 641; (*io)[23] = (tmp[19] + 318 * tmp[23]) % 641;
    (*io)[24] = (tmp[24] +       tmp[28]) % 641; (*io)[25] = (tmp[25] + 256 * tmp[29]) % 641;
    (*io)[26] = (tmp[26] + 154 * tmp[30]) % 641; (*io)[27] = (tmp[27] + 323 * tmp[31]) % 641;
    (*io)[28] = (tmp[24] + 640 * tmp[28]) % 641; (*io)[29] = (tmp[25] + 385 * tmp[29]) % 641;
    (*io)[30] = (tmp[26] + 487 * tmp[30]) % 641; (*io)[31] = (tmp[27] + 318 * tmp[31]) % 641;
    
    // 16-Point.
    tmp[ 0] = ((*io)[ 0] +       (*io)[ 8]) % 641; tmp[ 1] = ((*io)[ 1] +  16 * (*io)[ 9]) % 641;
    tmp[ 2] = ((*io)[ 2] + 256 * (*io)[10]) % 641; tmp[ 3] = ((*io)[ 3] + 250 * (*io)[11]) % 641;
    tmp[ 4] = ((*io)[ 4] + 154 * (*io)[12]) % 641; tmp[ 5] = ((*io)[ 5] + 541 * (*io)[13]) % 641;
    tmp[ 6] = ((*io)[ 6] + 323 * (*io)[14]) % 641; tmp[ 7] = ((*io)[ 7] +  40 * (*io)[15]) % 641;
    tmp[ 8] = ((*io)[ 0] + 640 * (*io)[ 8]) % 641; tmp[ 9] = ((*io)[ 1] + 625 * (*io)[ 9]) % 641;
    tmp[10] = ((*io)[ 2] + 385 * (*io)[10]) % 641; tmp[11] = ((*io)[ 3] + 391 * (*io)[11]) % 641;
    tmp[12] = ((*io)[ 4] + 487 * (*io)[12]) % 641; tmp[13] = ((*io)[ 5] + 100 * (*io)[13]) % 641;
    tmp[14] = ((*io)[ 6] + 318 * (*io)[14]) % 641; tmp[15] = ((*io)[ 7] + 601 * (*io)[15]) % 641;
    tmp[16] = ((*io)[16] +       (*io)[24]) % 641; tmp[17] = ((*io)[17] +  16 * (*io)[25]) % 641;
    tmp[18] = ((*io)[18] + 256 * (*io)[26]) % 641; tmp[19] = ((*io)[19] + 250 * (*io)[27]) % 641;
    tmp[20] = ((*io)[20] + 154 * (*io)[28]) % 641; tmp[21] = ((*io)[21] + 541 * (*io)[29]) % 641;
    tmp[22] = ((*io)[22] + 323 * (*io)[30]) % 641; tmp[23] = ((*io)[23] +  40 * (*io)[31]) % 641;
    tmp[24] = ((*io)[16] + 640 * (*io)[24]) % 641; tmp[25] = ((*io)[17] + 625 * (*io)[25]) % 641;
    tmp[26] = ((*io)[18] + 385 * (*io)[26]) % 641; tmp[27] = ((*io)[19] + 391 * (*io)[27]) % 641;
    tmp[28] = ((*io)[20] + 487 * (*io)[28]) % 641; tmp[29] = ((*io)[21] + 100 * (*io)[29]) % 641;
    tmp[30] = ((*io)[22] + 318 * (*io)[30]) % 641; tmp[31] = ((*io)[23] + 601 * (*io)[31]) % 641;
    
    // 32-Point.
    (*io)[ 0] = (tmp[ 0] +       tmp[16]) % 641; (*io)[ 1] = (tmp[ 1] +   4 * tmp[17]) % 641;
    (*io)[ 2] = (tmp[ 2] +  16 * tmp[18]) % 641; (*io)[ 3] = (tmp[ 3] +  64 * tmp[19]) % 641;
    (*io)[ 4] = (tmp[ 4] + 256 * tmp[20]) % 641; (*io)[ 5] = (tmp[ 5] + 383 * tmp[21]) % 641;
    (*io)[ 6] = (tmp[ 6] + 250 * tmp[22]) % 641; (*io)[ 7] = (tmp[ 7] + 359 * tmp[23]) % 641;
    (*io)[ 8] = (tmp[ 8] + 154 * tmp[24]) % 641; (*io)[ 9] = (tmp[ 9] + 616 * tmp[25]) % 641;
    (*io)[10] = (tmp[10] + 541 * tmp[26]) % 641; (*io)[11] = (tmp[11] + 241 * tmp[27]) % 641;
    (*io)[12] = (tmp[12] + 323 * tmp[28]) % 641; (*io)[13] = (tmp[13] +  10 * tmp[29]) % 641;
    (*io)[14] = (tmp[14] +  40 * tmp[30]) % 641; (*io)[15] = (tmp[15] + 160 * tmp[31]) % 641;
    (*io)[16] = (tmp[ 0] + 640 * tmp[16]) % 641; (*io)[17] = (tmp[ 1] + 637 * tmp[17]) % 641;
    (*io)[18] = (tmp[ 2] + 625 * tmp[18]) % 641; (*io)[19] = (tmp[ 3] + 577 * tmp[19]) % 641;
    (*io)[20] = (tmp[ 4] + 385 * tmp[20]) % 641; (*io)[21] = (tmp[ 5] + 258 * tmp[21]) % 641;
    (*io)[22] = (tmp[ 6] + 391 * tmp[22]) % 641; (*io)[23] = (tmp[ 7] + 282 * tmp[23]) % 641;
    (*io)[24] = (tmp[ 8] + 487 * tmp[24]) % 641; (*io)[25] = (tmp[ 9] +  25 * tmp[25]) % 641;
    (*io)[26] = (tmp[10] + 100 * tmp[26]) % 641; (*io)[27] = (tmp[11] + 400 * tmp[27]) % 641;
    (*io)[28] = (tmp[12] + 318 * tmp[28]) % 641; (*io)[29] = (tmp[13] + 631 * tmp[29]) % 641;
    (*io)[30] = (tmp[14] + 601 * tmp[30]) % 641; (*io)[31] = (tmp[15] + 481 * tmp[31]) % 641;
}

// Inverse number theoretic transform mod 641.
void intt_mod641(unsigned int **io)
{
    unsigned int tmp[32];
    
    // Initialize.
    tmp[ 0] = (*io)[ 0]; tmp[ 1] = (*io)[16]; tmp[ 2] = (*io)[ 8]; tmp[ 3] = (*io)[24];
    tmp[ 4] = (*io)[ 4]; tmp[ 5] = (*io)[20]; tmp[ 6] = (*io)[12]; tmp[ 7] = (*io)[28];
    tmp[ 8] = (*io)[ 2]; tmp[ 9] = (*io)[18]; tmp[10] = (*io)[10]; tmp[11] = (*io)[26];
    tmp[12] = (*io)[ 6]; tmp[13] = (*io)[22]; tmp[14] = (*io)[14]; tmp[15] = (*io)[30];
    tmp[16] = (*io)[ 1]; tmp[17] = (*io)[17]; tmp[18] = (*io)[ 9]; tmp[19] = (*io)[25];
    tmp[20] = (*io)[ 5]; tmp[21] = (*io)[21]; tmp[22] = (*io)[13]; tmp[23] = (*io)[29];
    tmp[24] = (*io)[ 3]; tmp[25] = (*io)[19]; tmp[26] = (*io)[11]; tmp[27] = (*io)[27];
    tmp[28] = (*io)[ 7]; tmp[29] = (*io)[23]; tmp[30] = (*io)[15]; tmp[31] = (*io)[31];
    
    // 2-Point.
    (*io)[ 0] = (tmp[ 0] + tmp[ 1]) % 641; (*io)[ 1] = (tmp[ 0] + 640 * tmp[ 1]) % 641;
    (*io)[ 2] = (tmp[ 2] + tmp[ 3]) % 641; (*io)[ 3] = (tmp[ 2] + 640 * tmp[ 3]) % 641;
    (*io)[ 4] = (tmp[ 4] + tmp[ 5]) % 641; (*io)[ 5] = (tmp[ 4] + 640 * tmp[ 5]) % 641;
    (*io)[ 6] = (tmp[ 6] + tmp[ 7]) % 641; (*io)[ 7] = (tmp[ 6] + 640 * tmp[ 7]) % 641;
    (*io)[ 8] = (tmp[ 8] + tmp[ 9]) % 641; (*io)[ 9] = (tmp[ 8] + 640 * tmp[ 9]) % 641;
    (*io)[10] = (tmp[10] + tmp[11]) % 641; (*io)[11] = (tmp[10] + 640 * tmp[11]) % 641;
    (*io)[12] = (tmp[12] + tmp[13]) % 641; (*io)[13] = (tmp[12] + 640 * tmp[13]) % 641;
    (*io)[14] = (tmp[14] + tmp[15]) % 641; (*io)[15] = (tmp[14] + 640 * tmp[15]) % 641;
    (*io)[16] = (tmp[16] + tmp[17]) % 641; (*io)[17] = (tmp[16] + 640 * tmp[17]) % 641;
    (*io)[18] = (tmp[18] + tmp[19]) % 641; (*io)[19] = (tmp[18] + 640 * tmp[19]) % 641;
    (*io)[20] = (tmp[20] + tmp[21]) % 641; (*io)[21] = (tmp[20] + 640 * tmp[21]) % 641;
    (*io)[22] = (tmp[22] + tmp[23]) % 641; (*io)[23] = (tmp[22] + 640 * tmp[23]) % 641;
    (*io)[24] = (tmp[24] + tmp[25]) % 641; (*io)[25] = (tmp[24] + 640 * tmp[25]) % 641;
    (*io)[26] = (tmp[26] + tmp[27]) % 641; (*io)[27] = (tmp[26] + 640 * tmp[27]) % 641;
    (*io)[28] = (tmp[28] + tmp[29]) % 641; (*io)[29] = (tmp[28] + 640 * tmp[29]) % 641;
    (*io)[30] = (tmp[30] + tmp[31]) % 641; (*io)[31] = (tmp[30] + 640 * tmp[31]) % 641;
    
    // 4-Point.
    tmp[ 0] = ((*io)[ 0] +       (*io)[ 2]) % 641; tmp[ 1] = ((*io)[ 1] + 487 * (*io)[ 3]) % 641;
    tmp[ 2] = ((*io)[ 0] + 640 * (*io)[ 2]) % 641; tmp[ 3] = ((*io)[ 1] + 154 * (*io)[ 3]) % 641;
    tmp[ 4] = ((*io)[ 4] +       (*io)[ 6]) % 641; tmp[ 5] = ((*io)[ 5] + 487 * (*io)[ 7]) % 641;
    tmp[ 6] = ((*io)[ 4] + 640 * (*io)[ 6]) % 641; tmp[ 7] = ((*io)[ 5] + 154 * (*io)[ 7]) % 641;
    tmp[ 8] = ((*io)[ 8] +       (*io)[10]) % 641; tmp[ 9] = ((*io)[ 9] + 487 * (*io)[11]) % 641;
    tmp[10] = ((*io)[ 8] + 640 * (*io)[10]) % 641; tmp[11] = ((*io)[ 9] + 154 * (*io)[11]) % 641;
    tmp[12] = ((*io)[12] +       (*io)[14]) % 641; tmp[13] = ((*io)[13] + 487 * (*io)[15]) % 641;
    tmp[14] = ((*io)[12] + 640 * (*io)[14]) % 641; tmp[15] = ((*io)[13] + 154 * (*io)[15]) % 641;
    tmp[16] = ((*io)[16] +       (*io)[18]) % 641; tmp[17] = ((*io)[17] + 487 * (*io)[19]) % 641;
    tmp[18] = ((*io)[16] + 640 * (*io)[18]) % 641; tmp[19] = ((*io)[17] + 154 * (*io)[19]) % 641;
    tmp[20] = ((*io)[20] +       (*io)[22]) % 641; tmp[21] = ((*io)[21] + 487 * (*io)[23]) % 641;
    tmp[22] = ((*io)[20] + 640 * (*io)[22]) % 641; tmp[23] = ((*io)[21] + 154 * (*io)[23]) % 641;
    tmp[24] = ((*io)[24] +       (*io)[26]) % 641; tmp[25] = ((*io)[25] + 487 * (*io)[27]) % 641;
    tmp[26] = ((*io)[24] + 640 * (*io)[26]) % 641; tmp[27] = ((*io)[25] + 154 * (*io)[27]) % 641;
    tmp[28] = ((*io)[28] +       (*io)[30]) % 641; tmp[29] = ((*io)[29] + 487 * (*io)[31]) % 641;
    tmp[30] = ((*io)[28] + 640 * (*io)[30]) % 641; tmp[31] = ((*io)[29] + 154 * (*io)[31]) % 641;
    
    // 8-Point.
    (*io)[ 0] = (tmp[ 0] +       tmp[ 4]) % 641; (*io)[ 1] = (tmp[ 1] + 318 * tmp[ 5]) % 641;
    (*io)[ 2] = (tmp[ 2] + 487 * tmp[ 6]) % 641; (*io)[ 3] = (tmp[ 3] + 385 * tmp[ 7]) % 641;
    (*io)[ 4] = (tmp[ 0] + 640 * tmp[ 4]) % 641; (*io)[ 5] = (tmp[ 1] + 323 * tmp[ 5]) % 641;
    (*io)[ 6] = (tmp[ 2] + 154 * tmp[ 6]) % 641; (*io)[ 7] = (tmp[ 3] + 256 * tmp[ 7]) % 641;
    (*io)[ 8] = (tmp[ 8] +       tmp[12]) % 641; (*io)[ 9] = (tmp[ 9] + 318 * tmp[13]) % 641;
    (*io)[10] = (tmp[10] + 487 * tmp[14]) % 641; (*io)[11] = (tmp[11] + 385 * tmp[15]) % 641;
    (*io)[12] = (tmp[ 8] + 640 * tmp[12]) % 641; (*io)[13] = (tmp[ 9] + 323 * tmp[13]) % 641;
    (*io)[14] = (tmp[10] + 154 * tmp[14]) % 641; (*io)[15] = (tmp[11] + 256 * tmp[15]) % 641;
    (*io)[16] = (tmp[16] +       tmp[20]) % 641; (*io)[17] = (tmp[17] + 318 * tmp[21]) % 641;
    (*io)[18] = (tmp[18] + 487 * tmp[22]) % 641; (*io)[19] = (tmp[19] + 385 * tmp[23]) % 641;
    (*io)[20] = (tmp[16] + 640 * tmp[20]) % 641; (*io)[21] = (tmp[17] + 323 * tmp[21]) % 641;
    (*io)[22] = (tmp[18] + 154 * tmp[22]) % 641; (*io)[23] = (tmp[19] + 256 * tmp[23]) % 641;
    (*io)[24] = (tmp[24] +       tmp[28]) % 641; (*io)[25] = (tmp[25] + 318 * tmp[29]) % 641;
    (*io)[26] = (tmp[26] + 487 * tmp[30]) % 641; (*io)[27] = (tmp[27] + 385 * tmp[31]) % 641;
    (*io)[28] = (tmp[24] + 640 * tmp[28]) % 641; (*io)[29] = (tmp[25] + 323 * tmp[29]) % 641;
    (*io)[30] = (tmp[26] + 154 * tmp[30]) % 641; (*io)[31] = (tmp[27] + 256 * tmp[31]) % 641;
    
    // 16-Point.
    tmp[ 0] = ((*io)[ 0] +       (*io)[ 8]) % 641; tmp[ 1] = ((*io)[ 1] + 601 * (*io)[ 9]) % 641;
    tmp[ 2] = ((*io)[ 2] + 318 * (*io)[10]) % 641; tmp[ 3] = ((*io)[ 3] + 100 * (*io)[11]) % 641;
    tmp[ 4] = ((*io)[ 4] + 487 * (*io)[12]) % 641; tmp[ 5] = ((*io)[ 5] + 391 * (*io)[13]) % 641;
    tmp[ 6] = ((*io)[ 6] + 385 * (*io)[14]) % 641; tmp[ 7] = ((*io)[ 7] + 625 * (*io)[15]) % 641;
    tmp[ 8] = ((*io)[ 0] + 640 * (*io)[ 8]) % 641; tmp[ 9] = ((*io)[ 1] +  40 * (*io)[ 9]) % 641;
    tmp[10] = ((*io)[ 2] + 323 * (*io)[10]) % 641; tmp[11] = ((*io)[ 3] + 541 * (*io)[11]) % 641;
    tmp[12] = ((*io)[ 4] + 154 * (*io)[12]) % 641; tmp[13] = ((*io)[ 5] + 250 * (*io)[13]) % 641;
    tmp[14] = ((*io)[ 6] + 256 * (*io)[14]) % 641; tmp[15] = ((*io)[ 7] +  16 * (*io)[15]) % 641;
    tmp[16] = ((*io)[16] +       (*io)[24]) % 641; tmp[17] = ((*io)[17] + 601 * (*io)[25]) % 641;
    tmp[18] = ((*io)[18] + 318 * (*io)[26]) % 641; tmp[19] = ((*io)[19] + 100 * (*io)[27]) % 641;
    tmp[20] = ((*io)[20] + 487 * (*io)[28]) % 641; tmp[21] = ((*io)[21] + 391 * (*io)[29]) % 641;
    tmp[22] = ((*io)[22] + 385 * (*io)[30]) % 641; tmp[23] = ((*io)[23] + 625 * (*io)[31]) % 641;
    tmp[24] = ((*io)[16] + 640 * (*io)[24]) % 641; tmp[25] = ((*io)[17] +  40 * (*io)[25]) % 641;
    tmp[26] = ((*io)[18] + 323 * (*io)[26]) % 641; tmp[27] = ((*io)[19] + 541 * (*io)[27]) % 641;
    tmp[28] = ((*io)[20] + 154 * (*io)[28]) % 641; tmp[29] = ((*io)[21] + 250 * (*io)[29]) % 641;
    tmp[30] = ((*io)[22] + 256 * (*io)[30]) % 641; tmp[31] = ((*io)[23] +  16 * (*io)[31]) % 641;
    
    // 32-Point.
    (*io)[ 0] = (tmp[ 0] +       tmp[16]) * 621 % 641; (*io)[ 1] = (tmp[ 1] + 481 * tmp[17]) * 621 % 641;
    (*io)[ 2] = (tmp[ 2] + 601 * tmp[18]) * 621 % 641; (*io)[ 3] = (tmp[ 3] + 631 * tmp[19]) * 621 % 641;
    (*io)[ 4] = (tmp[ 4] + 318 * tmp[20]) * 621 % 641; (*io)[ 5] = (tmp[ 5] + 400 * tmp[21]) * 621 % 641;
    (*io)[ 6] = (tmp[ 6] + 100 * tmp[22]) * 621 % 641; (*io)[ 7] = (tmp[ 7] +  25 * tmp[23]) * 621 % 641;
    (*io)[ 8] = (tmp[ 8] + 487 * tmp[24]) * 621 % 641; (*io)[ 9] = (tmp[ 9] + 282 * tmp[25]) * 621 % 641;
    (*io)[10] = (tmp[10] + 391 * tmp[26]) * 621 % 641; (*io)[11] = (tmp[11] + 258 * tmp[27]) * 621 % 641;
    (*io)[12] = (tmp[12] + 385 * tmp[28]) * 621 % 641; (*io)[13] = (tmp[13] + 577 * tmp[29]) * 621 % 641;
    (*io)[14] = (tmp[14] + 625 * tmp[30]) * 621 % 641; (*io)[15] = (tmp[15] + 637 * tmp[31]) * 621 % 641;
    (*io)[16] = (tmp[ 0] + 640 * tmp[16]) * 621 % 641; (*io)[17] = (tmp[ 1] + 160 * tmp[17]) * 621 % 641;
    (*io)[18] = (tmp[ 2] +  40 * tmp[18]) * 621 % 641; (*io)[19] = (tmp[ 3] +  10 * tmp[19]) * 621 % 641;
    (*io)[20] = (tmp[ 4] + 323 * tmp[20]) * 621 % 641; (*io)[21] = (tmp[ 5] + 241 * tmp[21]) * 621 % 641;
    (*io)[22] = (tmp[ 6] + 541 * tmp[22]) * 621 % 641; (*io)[23] = (tmp[ 7] + 616 * tmp[23]) * 621 % 641;
    (*io)[24] = (tmp[ 8] + 154 * tmp[24]) * 621 % 641; (*io)[25] = (tmp[ 9] + 359 * tmp[25]) * 621 % 641;
    (*io)[26] = (tmp[10] + 250 * tmp[26]) * 621 % 641; (*io)[27] = (tmp[11] + 383 * tmp[27]) * 621 % 641;
    (*io)[28] = (tmp[12] + 256 * tmp[28]) * 621 % 641; (*io)[29] = (tmp[13] +  64 * tmp[29]) * 621 % 641;
    (*io)[30] = (tmp[14] +  16 * tmp[30]) * 621 % 641; (*io)[31] = (tmp[15] +   4 * tmp[31]) * 621 % 641;
}

- (AZGRealNumber *)realNumberByMultiplyingBy:(AZGRealNumber *)operand
{
    // Handle special cases.
    if (self.isZero || operand.isZero) {
        // Any number multiplied zero is zero.
        return [AZGRealNumber zero];
    } else if ((_length == 1) && (_mantissa[0] == 1)) {
        // 10 ^ n * opd.
        AZGRealNumber *result = [[AZGRealNumber alloc] initWithRealNumber:operand];
        result->_exponent += _exponent;
        result->_isNegative = (_isNegative != operand->_isNegative);
        return result;
    } else if ((operand->_length == 1) && (operand->_mantissa[0] == 1) && (operand->_exponent == 0)) {
        // self * 10 ^ n.
        AZGRealNumber *result = [[AZGRealNumber alloc] initWithRealNumber:self];
        result->_exponent += operand->_exponent;
        result->_isNegative = (_isNegative != operand->_isNegative);
        return result;
    }
    
    int exponent = _exponent + operand->_exponent;
    BOOL isNegative = _isNegative != operand->_isNegative;
    
    AZGRealNumber *realNumber = self;
    
    char s[29];
    char *p = s;
    int i, j, k, carry;
    
    memset(s, '0', sizeof(s) - 1);
    
    unsigned int m_mod193[32] = {0};
    unsigned int m_mod641[32];
    unsigned int opd_m_mod193[32] = {0};
    unsigned int opd_m_mod641[32];
    unsigned int *m = m_mod193;
    
    BOOL shouldLoopBack = YES;
    
MUL_HANDLE_MANTISSA:
    mantissaToCString(realNumber, &p);
    
    for (i = 0; i < strlen(p) / 2; ++i) {
        m[i] = (p[strlen(p) - 2 * (i + 1)] - '0') * 10 + p[strlen(p) - 2 * i - 1] - '0';
    }
    
    if (strlen(p) & 1) {
        m[i] = p[strlen(p) - 2 * i - 1] - '0';
    }
    
    if (shouldLoopBack) {
        realNumber = operand;
        
        m = opd_m_mod193;
        memset(s, '0', sizeof(s) - 1);
        shouldLoopBack = NO;
        p = s;
        
        goto MUL_HANDLE_MANTISSA;
    }
    
    memcpy(m_mod641, m_mod193, 32 * sizeof(unsigned int));
    memcpy(opd_m_mod641, opd_m_mod193, 32 * sizeof(unsigned int));
    
    // Number Theoretic Transform.
    m = m_mod193;
    ntt_mod193(&m);
    m = m_mod641;
    ntt_mod641(&m);
    m = opd_m_mod193;
    ntt_mod193(&m);
    m = opd_m_mod641;
    ntt_mod641(&m);
    
    // Multiply.
    for (i = 0; i < 32; ++i) {
        m_mod193[i] = m_mod193[i] * opd_m_mod193[i] % 193;
        m_mod641[i] = m_mod641[i] * opd_m_mod641[i] % 641;
    }
    
    // Inverse Number Theoretic Transform.
    m = m_mod193;
    intt_mod193(&m);
    m = m_mod641;
    intt_mod641(&m);
    
    // Chinese Remainder Theorem.
    // Perform carry.
    int crt_mod641, crt_mod193;
    carry = 0;
    for (i = 0; i < 32; ++i) {
        crt_mod193 = 17948 * m_mod193[i];
        crt_mod641 = 17949 * m_mod641[i];
        
        if (crt_mod193 <= crt_mod641) {
            m_mod193[i] = (crt_mod641 - crt_mod193) % 123713 + carry;
        } else {
            m_mod193[i] = (105765 * m_mod193[i]  + 17949 * m_mod641[i]) % 123713 + carry;
        }
        
        if (m_mod193[i] > 99) {
            carry = m_mod193[i] / 100;
            m_mod193[i] %= 100;
        } else {
            carry = 0;
        }
    }
    
    for (i = 31; i >= 0; --i) {
        if (m_mod193[i] != 0) {
            break;
        }
    }
    
    if (i > 14) {
        // Need truncation.
        exponent += 2 * (i - 14);
        
        // Left shift digit one place if the first part contains only one digit.
        if (m_mod193[i] < 10) {
            --exponent;
            for (j = i; j >= i - 13; --j) {
                m_mod193[j] = 10 * m_mod193[j] + m_mod193[j - 1] / 10;
                m_mod193[j - 1] %= 10;
            }
        }
        
        // Round off extra parts.
        j = i - 14;
        carry = (m_mod193[j - 1] > 49);
        for (; j <= i; ++j) {
            if (carry) {
                m_mod193[j - 1] -= 100;
                ++m_mod193[j];
                carry = m_mod193[j] / 100;
            } else {
                break;
            }
        }
        
        k = i - 14;
    } else {
        k = 0;
    }
    
    memset(s, '0', sizeof(s) - 1);
    p = s;
    for (j = i; j >= k; --j) {
        p += sprintf(p, "%02i", m_mod193[j]);
    }
    *p = '\0';
    
    return [AZGRealNumber realNumberWithMantissa:[NSString stringWithUTF8String:s] exponent:exponent isNegative:isNegative];
}

- (AZGRealNumber *)realNumberByReciprocal
{
    // Avoid division by zero.
    if (self.isZero) {
        [[NSException exceptionWithName:@"AZGRealNumber Undefined Calculation." reason:@"Division by Zero." userInfo:nil] raise];
        return nil;
    }
    
    AZGRealNumber *result;
    int i;
    
    // Handle special case.
    if ((_length == 1) && (_mantissa[0] == 1)) {
        // 1 / (1 * 10 ^ n) == 1 * 10 ^ (-n).
        result = [[AZGRealNumber alloc] initWithRealNumber:self];
        result->_exponent = -result->_exponent;
        return result;
    }
    
    BOOL isNegative = _isNegative;
    
    int offset;
    char s[30];
    char *p = s;
    mantissaToCString(self, &p);
    
    AZGRealNumber *tmp;
    
    AZGRealNumber *error = [AZGRealNumber numericalError];
    
    // Newton-Raphson Method.
    
    // Normalize. (0.1 <= normalized < 1.0)
    AZGRealNumber *normalized = self.absoluteValue;
    offset = normalized->_exponent + (int)strlen(s);
    normalized->_exponent = -(int)strlen(s);
    
    // Inverse.
    // Slope k = -1.882352941176470588235294118
    AZGRealNumber *k = [[AZGRealNumber alloc] init];
    k->_mantissa[0] = 42406u;
    k->_mantissa[1] = 42405u;
    k->_mantissa[2] = 114u;
    k->_mantissa[3] = 26896u;
    k->_mantissa[4] = 3005u;
    k->_mantissa[5] = 1557u;
    k->_exponent = -27;
    k->_length = 6;
    k->_isNegative = YES;
    
    // y Intercept b = 2.823529411764705882352941176
    AZGRealNumber *b = [[AZGRealNumber alloc] init];
    b->_mantissa[0] = 30840u;
    b->_mantissa[1] = 63608u;
    b->_mantissa[2] = 171u;
    b->_mantissa[3] = 7576u;
    b->_mantissa[4] = 37276u;
    b->_mantissa[5] = 2335u;
    b->_exponent = -27;
    b->_length = 6;
    b->_isNegative = NO;
    
    // 2.
    AZGRealNumber *two = [[AZGRealNumber alloc] init];
    two->_mantissa[0] = 2u;
    
    // First approximation: x0 = k * normalized + b.
    tmp = [[k realNumberByMultiplyingBy:normalized] realNumberByAdding:b];
    
    while (YES) {
        // Iteration: x1 = x0 * (2 - normalized * x0)
        result = [[two realNumberBySubtracting:[normalized realNumberByMultiplyingBy:tmp]] realNumberByMultiplyingBy:tmp];
        if ([[result realNumberBySubtracting:tmp] absoluteCompare:error] == AZGOrderedDescending) {
            // Need more precision.
            tmp = [[AZGRealNumber alloc] initWithRealNumber:result];
        } else {
            // Achieved required precision.
            break;
        }
    }

    // Denormalize.
    result->_exponent -= offset;
    result->_isNegative = isNegative;
    
    s[0] = '0';
    p = s + 1;
    mantissaToCString(result, &p);
    
    if (strlen(p) == 28) {
        // Round off last two digits to ensure accuracy.
        result->_exponent += 2;
        
        i = 25;
        p[i] += (p[i + 1] > '4');
        p[i + 1] = '\0';
        
        while (p[i] > '9') {
            p[i] -= 10;
            ++p[--i];
        }
        
        result = [AZGRealNumber realNumberWithMantissa:[NSString stringWithFormat:@"%s", s] exponent:result->_exponent isNegative:isNegative];
    }
    
    return result;
}

- (AZGRealNumber *)realNumberByDividingBy:(AZGRealNumber *)operand
{
    return [self realNumberByMultiplyingBy:[operand realNumberByReciprocal]];
}

- (AZGRealNumber *)realNumberBySquaring
{
    // Handle special cases.
    if ((_length == 1) && (_mantissa[0] == 0)) {
        // Any number multiplied zero is zero.
        return [AZGRealNumber zero];
    } else if ((_length == 1) && (_mantissa[0] == 1)) {
        // 1 * opd = opd.
        AZGRealNumber *result = [[AZGRealNumber alloc] initWithRealNumber:self];
        result->_exponent += _exponent;
        result->_isNegative = NO;
        return result;
    }
    
    int exponent = _exponent * 2;
    BOOL isNegative = NO;
    
    char s[29];
    char *p = s;
    int i, j, k, carry;
    
    memset(s, '0', sizeof(s) - 1);
    
    unsigned int m_mod193[32] = {0};
    unsigned int m_mod641[32];
    unsigned int *m = m_mod193;
    
    mantissaToCString(self, &p);
    
    for (i = 0; i < strlen(p) / 2; ++i) {
        m[i] = (p[strlen(p) - 2 * (i + 1)] - '0') * 10 + p[strlen(p) - 2 * i - 1] - '0';
    }
    
    if (strlen(p) & 1) {
        m[i] = p[strlen(p) - 2 * i - 1] - '0';
    }
    
    memcpy(m_mod641, m_mod193, 32 * sizeof(unsigned int));
    
    // Number Theoretic Transform.
    m = m_mod193;
    ntt_mod193(&m);
    m = m_mod641;
    ntt_mod641(&m);
    
    // Multiply.
    for (i = 0; i < 32; ++i) {
        m_mod193[i] = m_mod193[i] * m_mod193[i] % 193;
        m_mod641[i] = m_mod641[i] * m_mod641[i] % 641;
    }
    
    // Inverse Number Theoretic Transform.
    m = m_mod193;
    intt_mod193(&m);
    m = m_mod641;
    intt_mod641(&m);
    
    // Chinese Remainder Theorem.
    // Perform carry.
    int crt_mod641, crt_mod193;
    carry = 0;
    for (i = 0; i < 32; ++i) {
        crt_mod193 = 17948 * m_mod193[i];
        crt_mod641 = 17949 * m_mod641[i];
        
        if (crt_mod193 <= crt_mod641) {
            m_mod193[i] = (crt_mod641 - crt_mod193) % 123713 + carry;
        } else {
            m_mod193[i] = (105765 * m_mod193[i]  + 17949 * m_mod641[i]) % 123713 + carry;
        }
        
        if (m_mod193[i] > 99) {
            carry = m_mod193[i] / 100;
            m_mod193[i] %= 100;
        } else {
            carry = 0;
        }
    }
    
    for (i = 31; i >= 0; --i) {
        if (m_mod193[i] != 0) {
            break;
        }
    }
    
    if (i > 14) {
        // Need truncation.
        exponent += 2 * (i - 14);
        
        // Left shift digit one place if the first part contains only one digit.
        if (m_mod193[i] < 10) {
            --exponent;
            for (j = i; j >= i - 13; --j) {
                m_mod193[j] = 10 * m_mod193[j] + m_mod193[j - 1] / 10;
                m_mod193[j - 1] %= 10;
            }
        }
        
        // Round off extra parts.
        j = i - 14;
        carry = (m_mod193[j - 1] > 49);
        for (; j <= i; ++j) {
            if (carry) {
                m_mod193[j - 1] -= 100;
                ++m_mod193[j];
                carry = m_mod193[j] / 100;
            } else {
                break;
            }
        }
        
        k = i - 14;
    } else {
        k = 0;
    }
    
    memset(s, '0', sizeof(s) - 1);
    p = s;
    for (j = i; j >= k; --j) {
        p += sprintf(p, "%02i", m_mod193[j]);
    }
    *p = '\0';
    
    return [AZGRealNumber realNumberWithMantissa:[NSString stringWithUTF8String:s] exponent:exponent isNegative:isNegative];
}

- (AZGRealNumber *)realNumberByRaisingToPower:(AZGRealNumber *)power
{
    // Handle special case.
    if (power.isZero) {
        return [AZGRealNumber positiveOne];
    }
    
    AZGRealNumber *i = [AZGRealNumber positiveOne];
    AZGRealNumber *two = [[AZGRealNumber alloc] init];
    two->_mantissa[0] = 2;
    AZGRealNumber *square = [self realNumberBySquaring];
    AZGRealNumber *result;
    
    if (((power->_mantissa[0]) & 1) && (power->_exponent == 0)) {
        // Odd number.
        result = self;
    } else {
        //Even number.
        result = square;
    }
    
    while ([i compare:[[power realNumberByDividingBy:two] realNumberByRoundingInMode:AZGRoundDown withScale:0]] == AZGOrderedAscending) {
        result = [result realNumberByMultiplyingBy:square];
        i = [i realNumberByAdding:[AZGRealNumber positiveOne]];
    }
    
    return result;
}

- (AZGRealNumber *)realNumberByRaisingToRoot:(AZGRealNumber *)root
{
    // Avoid even root of negative number.
    if (root.isEven && self.isNegative) {
        [[NSException exceptionWithName:@"Domain Exceeded." reason:@"Even Root of Negative Number" userInfo:nil] raise];
    }
    
    // Handle special case.
    if (self.isZero) {
        // 0 ^ n = 0.
        return [AZGRealNumber zero];
    } else if ([self compare:[AZGRealNumber positiveOne]] == AZGOrderedSame) {
        // 1 ^ n = 1.
        return self;
    }
    
    AZGRealNumber *result;
    
    AZGRealNumber *tmp;
    AZGRealNumber *rootMinusOne = [root realNumberBySubtracting:[AZGRealNumber positiveOne]];
    
    AZGRealNumber *error = [AZGRealNumber numericalError];
    
    // Newton-Raphson Method.
    
    // First approximation: x0 = self / root.
    tmp = [self realNumberByDividingBy:root];
    
    while (YES) {
        // Iteration: x1 = 1 / n * (a / (x ^ (n - 1)) + (n - 1) * x0).
        result = [[root realNumberByReciprocal] realNumberByMultiplyingBy:[[self realNumberByDividingBy:[tmp realNumberByRaisingToPower:rootMinusOne]] realNumberByAdding:[rootMinusOne realNumberByMultiplyingBy:tmp]]];
        if ([[result realNumberBySubtracting:tmp] absoluteCompare:error] == AZGOrderedDescending) {
            // Need more precision.
            tmp = [[AZGRealNumber alloc] initWithRealNumber:result];
        } else {
            // Achieved required precision.
            break;
        }
    }
    
    int i;
    char s[30];
    char *p = s + 1;
    s[0] = '0';
    mantissaToCString(result, &p);
    
    if (strlen(p) == 28) {
        // Round off last two digits to ensure accuracy.
        result->_exponent += 2;
        
        i = 25;
        p[i] += (p[i + 1] > '4');
        p[i + 1] = '\0';
        
        while (p[i] > '9') {
            p[i] -= 10;
            ++p[--i];
        }
        
        result = [AZGRealNumber realNumberWithMantissa:[NSString stringWithFormat:@"%s", s] exponent:result->_exponent isNegative:result->_isNegative];
    }
    
    return result;
}

- (AZGRealNumber *)realNumberByFactorial
{
    AZGRealNumber *result = [[AZGRealNumber alloc] initWithRealNumber:self];
    AZGRealNumber *one = [AZGRealNumber positiveOne];
    AZGRealNumber *multiplier = [self realNumberBySubtracting:one];
    
    while ([multiplier compare:one] != AZGOrderedSame) {
        result = [result realNumberByMultiplyingBy:multiplier];
        multiplier = [multiplier realNumberBySubtracting:one];
    }
    
    return result;
}

- (AZGRealNumber *)realNumberByModulus:(AZGRealNumber *)operand
{
    if ([self absoluteCompare:operand] == AZGOrderedSame) {
        return [AZGRealNumber zero];
    } else if ([self absoluteCompare:operand] == AZGOrderedAscending) {
        if (_isNegative) {
            return [operand.absoluteValue realNumberByAdding:self];
        } else {
            return self;
        }
    } else {
        // [self absoluteCompare:operand] == AZGOrderedDescending.
        return [self realNumberBySubtracting:[[[self realNumberByDividingBy:operand] realNumberByRoundingInMode:AZGRoundDown withScale:0] realNumberByMultiplyingBy:operand]];
    }
}

- (AZGRealNumber *)greatestCommonDivisor:(AZGRealNumber *)operand
{
    // Euclidean Algorithm.
    AZGRealNumber *num1 = operand;
    AZGRealNumber *num2 = [self realNumberByModulus:operand];
    AZGRealNumber *tmp;
    
    while ([num2 compare:[AZGRealNumber zero]] != AZGOrderedSame) {
        tmp = num1;
        num1 = num2;
        num2 = [tmp realNumberByModulus:num2];
    }
    
    return num1.absoluteValue;
}

- (AZGRealNumber *)leastCommonMultiple:(AZGRealNumber *)operand
{
    AZGRealNumber *tmp = [self greatestCommonDivisor:operand];
    
    return [[[self realNumberByDividingBy:tmp] realNumberByMultiplyingBy:[operand realNumberByDividingBy:tmp]] realNumberByMultiplyingBy:tmp].absoluteValue;
}

# pragma mark - Description
- (NSString *)description
{
    char s[37];
    char *p = s + 1;
    char e[30];//[12];
    
    mantissaToCString(self, &p);
    
    if (_isNegative) {
        *(--p) = '-';
    }

    memset(e, 0, sizeof(e) - 1);
    
    if (_exponent != 0) {
        sprintf(e, "e%+i", _exponent);
    }
    
    return [NSString stringWithFormat:@"%s%s", p, e];
}

@end
