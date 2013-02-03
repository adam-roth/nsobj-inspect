//
//  NSObject+Inspect.m
//
//  Created by aroth on 4/02/13.
//
//

#import "NSObject+Inspect.h"

@implementation NSObject (Inspect)

#import </usr/include/objc/objc-class.h>
#import <malloc/malloc.h>

- (void) inspect {
    [self inspect:self toDepth:0];
}

- (void) inspectToDepth: (int)maxDepth {
    [self inspect:self toDepth:maxDepth];
}

- (void) inspect: (id)anObject toDepth: (int) maxDepth {
    if (! anObject) {
        anObject = self;
    }
    if (maxDepth < 0) {
        maxDepth = 0;
    }
    NSMutableArray* state = [[NSMutableArray alloc] initWithCapacity: 1024];
    [self printObjectInternal:anObject printState: state friendlyName: [[anObject class] description] withIndent: @"" fromDepth: 0 toDepth: maxDepth];
    [state release];
}

- (NSString*) appendTo: (NSString*) base with: (NSString*) rest {
    return [NSString stringWithFormat:@"%@%@", base, rest];
}

- (void) printObjectInternal:(id)anObject printState: (NSMutableArray*)state friendlyName: (NSString*) objName withIndent: (NSString*)indent fromDepth: (int)currentDepth toDepth: (int)maxDepth {
    if (anObject == nil || anObject == NULL || currentDepth > maxDepth) {
        //nothing to do
        return;
    }
    
    [state addObject:anObject];
    
    //process properties for the class and its superclass(es)
    int mySuperclassDepth = currentDepth;
    Class processingClass = [anObject class];
    while (processingClass != nil && processingClass != [NSObject class] && mySuperclassDepth <= maxDepth) {
        unsigned int numFields = 0;
        
        //methods
        Method* methods = class_copyMethodList(processingClass, &numFields);
        NSLog(@"[%@] - %@  Printing object:  type=%@ : %@ ...", objName, indent, processingClass, class_getSuperclass(processingClass));
        NSLog(@"[%@] - %@  Printing object methods:  type=%@, numMethods=%d", objName, indent, processingClass, numFields);
        for (int index = 0; index < numFields; index++) {
            unsigned int numArgs = method_getNumberOfArguments(methods[index]);
            const char* name = sel_getName(method_getName(methods[index]));
            NSString* argString = @"";
            char* copyReturnType = method_copyReturnType(methods[index]);
            for (int argIndex = 0; argIndex < numArgs; argIndex++) {
                char* argType = method_copyArgumentType(methods[index], argIndex);
                if (argIndex > 2) {
                    argString = [argString stringByAppendingFormat:@" argName%d: (%@) arg%d", argIndex - 2, [self codeToReadableType: argType], argIndex - 2];
                }
                else if (argIndex > 1) {
                    argString = [argString stringByAppendingFormat:@" (%@) arg%d", [self codeToReadableType: argType], argIndex - 2];
                }
                free(argType);
            }
            
            if (numArgs <= 2) {
                NSLog(@"[%@] - %@ (%@)  - (%@) %s;", objName, indent, processingClass, [self codeToReadableType: copyReturnType], name);
            }
            else {
                NSLog(@"[%@] - %@ (%@)  - (%@) %s %@;", objName, indent, processingClass, [self codeToReadableType: copyReturnType], name, argString);
            }
            free(copyReturnType);
        }
        
        //properties (i.e. things declared with '@property')
        objc_property_t* props = class_copyPropertyList(processingClass, &numFields);
        NSLog(@"[%@] - %@  Printing object properties:  type=%@, numFields=%d", objName, indent, processingClass, numFields);
        for (int index = 0; index < numFields; index++) {
            objc_property_t prop = props[index];
            const char* fieldName = property_getName(prop);
            const char* fieldType = property_getAttributes(prop);
            NSLog(@"[%@] - %@ (%@) @property %@ %s;", objName, indent, processingClass, [self codeToReadableType: fieldType], fieldName);
            
            @try {
                id fieldValue = [anObject valueForKey:[NSString stringWithFormat:@"%s", fieldName]];
                NSString* typeString = [NSString stringWithFormat:@"%s", fieldType];
                NSRange range = [typeString rangeOfString:@"T@\""];
                if (range.location == 0 && fieldValue && ! [state containsObject:fieldValue]) {
                    //the field is an object-type, so print its size as well
                    NSLog(@"[%@] - %@ (%@)\t  Expanding property [%s]:", objName, indent, processingClass, fieldName);
                }
            }
            @catch (id ignored) {
                //couldn't get it with objectForKey, so try an alternate way
                void* fieldValue = NULL;
                object_getInstanceVariable(anObject, fieldName, &fieldValue);
            }
        }
        
        //ivars (i.e. declared instance members)
        Ivar* ivars = class_copyIvarList(processingClass, &numFields);
        NSLog(@"[%@] - %@ (%@) Printing object ivars:  type=%@, numFields=%d", objName, indent, processingClass, processingClass, numFields);
        for (int index = 0; index < numFields; index++) {
            Ivar ivar = ivars[index];
            id fieldValue = object_getIvar(anObject, ivar);
            
            const char* fieldName = ivar_getName(ivar);
            const char* fieldType = ivar_getTypeEncoding(ivar);
            
            NSLog(@"[%@] - %@ (%@) %@ %s;", objName, indent, processingClass, [self codeToReadableType: fieldType], fieldName);
            int mSize = malloc_size(fieldValue);
            
            @try {
                NSString* typeString = [NSString stringWithFormat:@"%s", fieldType];
                NSRange range = [typeString rangeOfString:@"@"];
                if (range.location == 0 && (! [state containsObject:fieldValue]) && mSize > 0) {
                    //the field is an object-type, so print its size as well
                    NSLog(@"[%@] - %@ (%@)\t  Expanding ivar [%s]:", objName, indent, processingClass, fieldName);
                    //see if it's a countable type, just for fun
                    if ([fieldValue respondsToSelector:@selector(count)]) {
                        //if we can count it, print the count
                        NSLog(@"[%@] - %@ (%@)\t\t  Container Count:  name=%s, type=%s, count=%d", objName, indent, processingClass, fieldName, fieldType, [fieldValue count]);
                    }
                }
            }
            @catch (id ignored) {
                //couldn't print it
            }
        }
        
        //process indexed ivars (extra bytes allocated at end of object; no name available, just size)
        void* extraBytes = object_getIndexedIvars(anObject);
        NSLog(@"[%@] - %@ (%@) Printing object indexedIvars:  type=%@, extraBytes=%lu", objName, indent, processingClass, processingClass, malloc_size(extraBytes));
        
        //process superclass
        NSLog(@"[%@] - %@ (%@) Superclass of %@ is %@", objName, indent, processingClass, processingClass, class_getSuperclass(processingClass));
        processingClass = class_getSuperclass(processingClass);
        mySuperclassDepth++;
    }
}

- (NSString*) codeToReadableType: (const char*) code {
    NSString* codeString = [NSString stringWithFormat:@"%s", code];
    NSString* result = [NSString string];
    
    bool array = NO;
    NSString* arrayString;
    //note:  we parse our type from left to right, but build our result string from right to left
    for (int index = 0; index < [codeString length]; index++) {
        char nextChar = [codeString characterAtIndex:index];
        switch (nextChar) {
            case 'T':
                //a placeholder code, the actual type will be specified by the next character
                break;
            case ',':
                //used in conjunction with 'T', indicates the end of the data that we care about
                //we could further process the character(s) after the comma to work out things like 'nonatomic', 'retain', etc., but let's not
                index = [codeString length];
                break;
            case 'i':
                //int or id
                if (index + 1 < [codeString length] && [codeString characterAtIndex:index + 1] == 'd') {
                    //id
                    result = [self appendTo: (array ? @"id[" : @"id") with: result];
                    index++;
                }
                else {
                    //int
                    result = [self appendTo: (array ? @"int[" : @"int") with: result];
                }
                break;
            case 'I':
                //unsigned int
                result = [self appendTo: (array ? @"unsigned int[" : @"unsigned int") with: result];
                break;
            case 's':
                //short
                result = [self appendTo: (array ? @"short[" : @"short") with: result];
                break;
            case 'S':
                //unsigned short
                result = [self appendTo: (array ? @"unsigned short[" : @"unsigned short") with: result];
                break;
            case 'l':
                //long
                result = [self appendTo: (array ? @"long[" : @"long") with: result];
                break;
            case 'L':
                //unsigned long
                result = [self appendTo: (array ? @"unsigned long[" : @"unsigned long") with: result];
                break;
            case 'q':
                //long long
                result = [self appendTo: (array ? @"long long[" : @"long long") with: result];
                break;
            case 'Q':
                //unsigned long long
                result = [self appendTo: (array ? @"unsigned long long[" : @"unsigned long long") with: result];
                break;
            case 'f':
                //float
                result = [self appendTo: (array ? @"float[" : @"float") with: result];
                break;
            case 'd':
                //double
                result = [self appendTo: (array ? @"double[" : @"double") with: result];
                break;
            case 'B':
                //bool
                result = [self appendTo: (array ? @"bool[" : @"bool") with: result];
                break;
            case 'b':
                //char and BOOL; is stored as "bool", so need to ignore the next 3 chars
                result = [self appendTo: (array ? @"BOOL[" : @"BOOL") with: result];
                index += 3;
                break;
            case 'c':
                //char?
                result = [self appendTo: (array ? @"char[" : @"char") with: result];
                break;
            case 'C':
                //unsigned char
                result = [self appendTo: (array ? @"unsigned char[" : @"unsigned char") with: result];
                break;
            case 'v':
                //void
                result = [self appendTo: @"void" with: result];
                break;
            case ':':
                //selector
                result = [self appendTo: @"SEL" with: result];
                break;
            case '^':
                //pointer
                result = [self appendTo: @"*" with: result];
                break;
            case '@': {
                //object instance, may or may not include the type in quotes, like @"NSString"
                if (index + 1 < [codeString length] && [codeString characterAtIndex:index + 1] == '"') {
                    //we can get the exact type
                    int endIndex = index + 2;
                    NSString* theType = @"";
                    while ([codeString characterAtIndex:endIndex] != '"') {
                        theType = [NSString stringWithFormat:@"%@%c", theType, [codeString characterAtIndex:endIndex]];
                        endIndex++;
                    }
                    theType = [self appendTo: theType with: @"*"];
                    result = [self appendTo: theType with: result];
                    
                    index = endIndex + 1;
                }
                else {
                    //all we know is that it's an object of some kind
                    result = [self appendTo: @"NSObject*" with: result];
                }
                break;
            }
            case '{': {
                //struct, we don't fully process these; just echo them
                index++;
                int numBraces = 1;
                NSString* theType = @"{";
                while (numBraces > 0) {
                    char next = [codeString characterAtIndex:index];
                    theType = [NSString stringWithFormat:@"%@%c", theType, next];
                    if (next == '{') {
                        numBraces++;
                    }
                    else if (next == '}') {
                        numBraces--;
                    }
                    
                    index++;
                }
                result = [NSString stringWithFormat:@"struct %@%@", theType, result];
                
                index--;
                break;
            }
            case '?':
                //IMP and function pointer
                result = [self appendTo: @"IMP" with: result];
                break;
            case '[':
                //array type
                array = YES;
                arrayString = @"";
                result = [self appendTo: @"]" with: result];
                break;
            case ']':
                //array type
                array = NO;
                break;
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                //for a statically-sized array, indicates the number of elements
                if (array) {
                    arrayString = [NSString stringWithFormat:@"%@%c", arrayString, nextChar];
                }
                break;
            default:
                break;
        }
    }
    
    return result;
}

@end
