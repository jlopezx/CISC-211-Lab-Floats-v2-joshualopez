/*** asmFmax.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data  
.align

@ Define the globals so that the C code can access them

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Joshua Lopez"  
 
.align

/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global f0,f1,fMax,signBitMax,storedExpMax,realExpMax,mantMax
.type f0,%gnu_unique_object
.type f1,%gnu_unique_object
.type fMax,%gnu_unique_object
.type sbMax,%gnu_unique_object
.type storedExpMax,%gnu_unique_object
.type realExpMax,%gnu_unique_object
.type mantMax,%gnu_unique_object

.global sb0,sb1,storedExp0,storedExp1,realExp0,realExp1,mant0,mant1
.type sb0,%gnu_unique_object
.type sb1,%gnu_unique_object
.type storedExp0,%gnu_unique_object
.type storedExp1,%gnu_unique_object
.type realExp0,%gnu_unique_object
.type realExp1,%gnu_unique_object
.type mant0,%gnu_unique_object
.type mant1,%gnu_unique_object
 
.align
@ use these locations to store f0 values
f0: .word 0
sb0: .word 0
storedExp0: .word 0  /* the unmodified 8b exp value extracted from the float */
realExp0: .word 0
mant0: .word 0
 
@ use these locations to store f1 values
f1: .word 0
sb1: .word 0
realExp1: .word 0
storedExp1: .word 0  /* the unmodified 8b exp value extracted from the float */
mant1: .word 0
 
@ use these locations to store fMax values
fMax: .word 0
sbMax: .word 0
storedExpMax: .word 0
realExpMax: .word 0
mantMax: .word 0

.global nanValue 
.type nanValue,%gnu_unique_object
nanValue: .word 0x7FFFFFFF            

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
 function name: initVariables
    input:  none
    output: initializes all f0*, f1*, and *Max varibales to 0
********************************************************************/
.global initVariables
 .type initVariables,%function
initVariables:
    /* YOUR initVariables CODE BELOW THIS LINE! Don't forget to push and pop! */
    push {r4-r11, lr}	/*Save registers and lr*/
    
    mov r8, 0		/*Set up r8 with 0 to use for label initialization in loop_assignment*/
    ldr r4, =f0		/*Start memory address. In this case f0 memory address*/
    ldr r5, =mantMax	/*End memory address. Use mantMax mem address to end loop later*/
    str r8, [r4]
    
    /*Initializes the rest of the variables to 0*/    
    loop_assignment:
    /*add r3, r3, 4	/*Increments to the next address by adding 4 to the current mem address (bytes)*/
    str r8, [r4, 4]!	/*Permanently pre-indexes to the next mem address and stores 0 in it*/
    cmp r4, r5		/*Checks to see if we reached the end. In this case it would be mantMax mem address*/
    bne loop_assignment /*Loops if we haven't reached mantMax mem address*/
    
    
    pop {r4-r11, lr}    /*Restore saved registers and lr*/
    bx lr		/*Return from the function*/
    
    /* YOUR initVariables CODE ABOVE THIS LINE! Don't forget to push and pop! */

    
/********************************************************************
 function name: getSignBit
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store sign bit (bit 31).
                Store a 1 if the sign bit is negative,
                Store a 0 if the sign bit is positive
                use sb0, sb1, or signBitMax for storage, as needed
    output: [r1]: mem location given by r1 contains the sign bit
********************************************************************/
.global getSignBit
.type getSignBit,%function
getSignBit:
    /* YOUR getSignBit CODE BELOW THIS LINE! Don't forget to push and pop! */
    push {r4-r11, lr}	/*Save registers and lr*/
   
    ldr r4, [r0]	/*Loads r4 with f* value*/
    lsr r4, r4, 31	/*Isolates the MSB of the 16 bit value in B16-B31*/
    str r4, [r1]	/*Stores the sign bit in r1 which is the sb* mem location*/
    
    pop {r4-r11, lr}    /* Restore saved registers and lr*/
    bx lr		/* Return from the function*/
    /* YOUR getSignBit CODE ABOVE THIS LINE! Don't forget to push and pop! */
    

    
/********************************************************************
 function name: getExponent
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the unpacked original STORED exponent bits,
                shifted into the lower 8b of the register. Range 0-255.
            r1: always contains the REAL exponent, equal to r0 - 127.
                It is a signed 32b value. This function doesn't
                check for +/-Inf or +/-0, so r1 always contains
                r0 - 127.
                
********************************************************************/
.global getExponent
.type getExponent,%function
getExponent:
    /* YOUR getExponent CODE BELOW THIS LINE! Don't forget to push and pop! */
    push {r4-r11, lr}	/*Save registers and lr*/

    ldr r8, =0x7F800000	/*Load r8 with exponent bits all set to 1*/
    ldr r4, [r0]	/*Loads r4 with f* value to be masked*/
    and r0, r4, r8	/*Focuses on the exponent bits and removes the rest & stores in r0. This would be the storedExp**/
    lsr r0, r0, 23	/*storedExp is shifted to the LSBs position and stores in r0 to be returned*/
    cmp r0, 0		/*If storedExp is 0 than we're dealing with a subnormal number*/
    beq subnormal	/*Branches if equal to deal with subnoral*/
    sub r1, r0, 127	/*Subtracts 127 from storedExp* to get realExp* and stores it in r1 to be returned*/
    b doneExp		/*Branches to exit*/
    subnormal:
    add r1, r0, -126	/*If we have a subnormal, subtract 126 instead and return it through r1*/
    
    doneExp:
    
    pop {r4-r11, lr}    /* Restore saved registers and lr*/
    bx lr		/* Return from the function*/
    /* YOUR getExponent CODE ABOVE THIS LINE! Don't forget to push and pop! */
   

    
/********************************************************************
 function name: getMantissa
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the mantissa WITHOUT the implied 1 bit added
                to bit 23. The upper bits must all be set to 0.
            r1: contains the mantissa WITH the implied 1 bit added
                to bit 23. Upper bits are set to 0. 
********************************************************************/
.global getMantissa
.type getMantissa,%function
getMantissa:
    /* YOUR getMantissa CODE BELOW THIS LINE! Don't forget to push and pop! */
    push {r4-r11, lr}	/*Save registers and lr*/
    
    ldr r4, [r0]	/*Loads r4 with f* value*/
    ldr r8, =0x7FFFFF	/*Sets the mantissa bits to all 1s*/
    and r4, r4, r8	/*Masks f* value with mantissa mask and stores it in r4*/
    bl getExponent	/*Branch link to getExponent sublabel. r0 should already be loaded with f* mem address*/
   
    cmp r0, 0		/*getExponent returned (r0) stored and (r1) real exponents*/
    beq zero_or_large	/*If storedExp* is 0, we got a subnormal exponent, so we branch to zero_or_large*/
    cmp r0, 255		/*If storedExp* is 255, we got infinity (very large)*/
    beq zero_or_large	/*Branch to zero_or_large if equal*/

    mov r0, r4		/*If here, exponent is valid and we move the mantissa w/o the 
			 *implied bit to r0 (this will be returned in r0)*/
    eor r1, r4, (1<<23) /*Left bitwise shift is used to flip bit 23 in r4 and 
			 *stores it in r1 to be returned(Implied bit)*/
    b done_mantissa	/*Branches to done_mantissa to exit*/
    
    zero_or_large:
    mov r0, r4		/*returns the mantissa to r0 without the implied bit*/
    mov r1, r4		/*reutnrs the mantissa to r1 without the implied bit*/
    
    done_mantissa:
    pop {r4-r11, lr}    /* Restore saved registers and lr*/
    bx lr		/* Return from the function*/
    /* YOUR getMantissa CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsZero
    input:  r0: address of mem containing 32b float to be checked
                for +/- 0
      
    output: r0:  0 if floating point value is NOT +/- 0
                 1 if floating point value is +0
                -1 if floating point value is -0
      
********************************************************************/
.global asmIsZero
.type asmIsZero,%function
asmIsZero:
    /* YOUR asmIsZero CODE BELOW THIS LINE! Don't forget to push and pop! */

    push {r4-r11, lr}	/*Save registers and lr*/

    ldr r4, [r0]	/*Loads r4 with f* value. r0 was passed with f* mem address*/
    ldr r8, =0x7FFFFFFF	/*Sets up r8 with mask to check for all 1s in all bits except sign bit (31)*/
    and r5, r4, r8	/*Masks f* value and stores new value in r5*/
    cmp r5, 0		/*Zero if exponent and mantissa are both 0*/
    beq zero_found	/*If zero, we found it and we branch to check positive or negative*/
    mov r0, 0		/*If we're here, we have no zero, so we return 0 in r0 for no zero haha*/
    b done_zero		/*We branch to done_zero to exit*/

    zero_found:
    lsr r5, r4, 31	/*We found zero, so let's check its sign bit by isolating the MSB*/
    cmp r5, 0		/*Check if sign bit is 0 (positive) or 1 (negative)*/
    beq positive_zero	/*Branch to positive zero if we have 0 MSB*/
    mov r0, -1		/*Else return -1 to r0 indicating -0*/
    b done_zero		/*Branch to the exit*/
    
    positive_zero:	
    mov r0, 1		/*Move 1 to r0 meaning we have positive 0*/
    
    done_zero:		/*Exit*/
    
    pop {r4-r11, lr}    /* Restore saved registers and lr*/
    bx lr		/*Link back to caller*/
    /* YOUR asmIsZero CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsInf
    input:  r0: address of mem containing 32b float to be checked
                for +/- infinity
      
    output: r0:  0 if floating point value is NOT +/- infinity
                 1 if floating point value is +infinity
                -1 if floating point value is -infinity
      
********************************************************************/
.global asmIsInf
.type asmIsInf,%function
asmIsInf:
    /* YOUR asmIsInf CODE BELOW THIS LINE! Don't forget to push and pop! */
    push {r4-r11, lr}	/*Save registers and lr*/

    ldr r4, [r0]	/*Loads r4 with f* value. r0 was passed with f* mem address*/
    ldr r8, =0x7F800000	/*Sets up r8 with mask to check for all 1s in exponent bits*/
    and r5, r4, r8	/*Masks f* value with mask to get only those bits*/
    cmp r5, r8		/*infinity if exponents are all 1s*/
    beq infinity_found	/*If exponents are all 1s, we found infinity (and beyond hehe)*/
    mov r0, 0		/*If we pass the above branch, no infinity value so we return 0 in r0*/
    b done_infinity	/*We're done finding infinity*/
	
    infinity_found:	/*Uh oh, we found infinity*/
    lsr r5, r4, 31	/*Is infinity negative or positive? let's check its MSB*/
    cmp r5, 0		/*If MSB is 0, then we have positive infinity and we will branch to positive_infinity*/
    beq positive_infinity
    mov r0, -1		/*If we passed the above branch, then we got negative infinity and we will pass -1 into r0*/
    b done_infinity	/*We're done with infinity*/
    
    positive_infinity:
    mov r0, 1		/*Returns 1 for positive infinity to r0*/
    
    done_infinity:
    
    pop {r4-r11, lr}    /* Restore saved registers and lr*/
    bx LR		/*Links back to caller*/
    /* YOUR asmIsInf CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
function name: asmFmax
function description:
     max = asmFmax ( f0 , f1 )
     
where:
     f0, f1 are 32b floating point values passed in by the C caller
     max is the ADDRESS of fMax, where the greater of (f0,f1) must be stored
     
     if f0 equals f1, return either one
     notes:
        "greater than" means the most positive number.
        For example, -1 is greater than -200
     
     The function must also unpack the greater number and update the 
     following global variables prior to returning to the caller:
     
     signBitMax: 0 if the larger number is positive, otherwise 1
     realExpMax: The REAL exponent of the max value, adjusted for
                 (i.e. the STORED exponent - (127 o 126), see lab instructions)
                 The value must be a signed 32b number
     mantMax:    The lower 23b unpacked from the larger number.
                 If not +/-INF and not +/- 0, the mantissa MUST ALSO include
                 the implied "1" in bit 23! (So the student's code
                 must make sure to set that bit).
                 All bits above bit 23 must always be set to 0.     

********************************************************************/    
.global asmFmax
.type asmFmax,%function
asmFmax:   

    /* YOUR asmFmax CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    push {r4-r11, lr}	/*Save registers and lr*/
    
    bl initVariables	/*Initializes all the variables(labels) to 0*/

    /*These registers are loaded to permanently hold the respective mem addresses for asmFmax*/
    ldr r8, =f0
    ldr r9, =mant0
    ldr r10, =fMax

    /*-----------------Step 1-2 unpacking r0 and r1 to f0 and f1 respectively-----------------*/

    ldr r4, =f0		/*Sets up r4 as f0 mem address to store value in r0*/
    ldr r5, =f1		/*Sets up r5 as f1 mem address to store value in r1*/
    ldr r6, =fMax	/*Used as the end address for the loop*/
    mov r7, r4		/*Let r7 hold f0 mem address*/
    str r0, [r4]	/*Stores r0 value into f0 mem address*/
    str r1, [r5]	/*Stores r1 value into f1 mem address*/

    loop_vars:
    mov r0, r4		/*Sets up r0 with f0 mem address*/
    add r4, r4, 4	/*Offsets r4 by 4 bytes move to sb0*/
    mov r1, r4		/*Sets r1 as the mem address of sb0*/
    bl getSignBit	/*r0 is set up with f0 mem address and r1 sb0 mem address to pass into getSignBit*/
    bl getExponent	/*When we return, r0 is still set up with f0 mem address, this gets passed in*/
    str r0, [r4, 4]!	/*When we return, r0 and r1 are loaded with storedExp0 and realExp0 respecitvely*/
    str r1, [r4, 4]!	/*Both these str instructions prem pre-index to move to storedExp0 and realExp0 mem addresse*/

    mov r0, r7		/*r7 holds f0 mem address to pass into r0 for getMantissa sublabel (function)*/
    bl getMantissa	/*Calls getMantissa, returns r0 and r1 but we only care about r1 in this project*/
    str r1, [r4, 4]!	/*R1 holds the implied 23 bit value and stores it into mant0 after it pre-indexs*/
    add r4, r4, 4	/*Moves to f1 mem address*/
    add r7, r7, 20	/*shifts r7 to f1 mem address to temporarily hold it*/
    cmp r4, r6		/*Checks if we reached fMax which is our end address*/
    bne loop_vars	/*Loops if we didn't already reach fMax yet*/

    /*-----------------------------Steps 3-6 checking for infinity-----------------------------*/

    mov r4, r8		/*Holds a temp copy of f0 to use the start of the address.*/
    ldr r1, =fMax	/*This is used as the end address for the loop*/

    ldr r0, =f0		/*Checking f0 for infinity by setting it up in r0 to be passed into asmIsInf*/
    infit_check:
    bl asmIsInf		/*Branches to infinity sublabel with f0 mem address passed in to check for infinity*/
    cmp r0, 0		/*0 means no infinity*/
    addeq r4, r4, 20    /*shifts to f1 to check it for infinity next. This adds if f* is not infinity*/
    beq not_infinity
    cmp r0, 1		/*1 means positive infinity*/
    beq pos_infinity    /*Branches to positive infinity if 1 else it was -1 and simply steps down*/

    /*Steps 5 and 6 negative infinity*/
    sub r1, r1, 20	/*Subtracts 20 bytes from fMax to get to f1, this will help check which iteration we're on
			 *if not equal, the first iteration, if equal then second iteration*/
    cmp r4, r1		/*Checks if r0 is equal to f1, if it is, then we looped twice*/
    subeq r4, r4, 20    /*This will add f0 to fMax if we're in the second iteration*/
    addne r4, r4, 20	/*This will add f1 to fMax if we're in the first iteration*/
    mov r8, r4		/*sets r8 up with the mem address for asmLoop*/
    add r9, r4, 16	/*Shifts f* to its mant* for asmLoop*/

    b asmLoop

    /*Steps 3 and 4 positive  infinity*/
    pos_infinity:

    mov r8, r4		/*Sets r8 up with the mem address for asmLoop*/
    add r9, r4, 16	/*Shifts f* to its mant for asmLoop*/

    b asmLoop

    not_infinity:
    cmp r4, r1		/*Checks if r0 is equal to f1, if it is, then we looped twice*/
    movne r0, r4	/*When not equal, we move r4 to r0 to set up r0 with the current mem address for the 2nd loop*/
    bne infit_check	/*Branches back up to complete second loop to check f1*/

    /*-----------------------------Step 7 checking sign bits-----------------------------*/

    /*Loads sign bits for later comparison*/
    ldr r4, =sb0
    ldr r5, =sb1
    ldr r4, [r4]
    ldr r5, [r5]

    /*If sign bits are unequal, we branch to handle comparison, else, branch to its respecitve path(+ or -)*/
    cmp r4, r5
    bne sign_bits_unequal
    /*If r4 is 0, then both bits are positive, else they are negative and branch respecitvely*/
    cmp r4, 0
    beq positive_sign_bits
    bne negative_sign_bits

    /*We check to see is r4 is positive, if it's not then f1 is the positive value, hence we add
    * 20 bytes to shift to f1*/
    sign_bits_unequal:
    cmp r4, 0
    addne r8, r8, 20	/*If r4 is not 0(positive) than r5 is positive, then shift r8 20 bytes to f1*/
    addne r9, r9, 20	/*If r4 is not 0(positive) than r5 is positive, then shift r9 20 bytes to mant1*/

    b asmLoop


    /*-----------------------------Step 8 checking real exponents-----------------------------*/

    /*If we're here, we have positive sign bits, need to check exponent equivalency*/
    positive_sign_bits:
    /*Load real exponents for later comparison*/
    ldr r4, =realExp0	/*Checking real exponent 0*/
    ldr r5, =storedExp1	/*Issue with label alignment. StoredExp1 actually stored realExp1*/
    ldr r4, [r4]
    ldr r5, [r5]

    /*Compares exponents, if not equal, then we want the greater exponent
    *positive sign bits and positive exponents means the larger exponent is greater
    **/
    cmp r4, r5
    beq exponents_equal_pos
    /*Below addition instructions are executed if r4 is less than r5. r8 and r9 are used for asmLoop*/
    addlt r8, r8, 20	/*If r4 is less than r5, then shift 20 bytes to f1*/
    addlt r9, r9, 20	/*If r4 is less than r5, then shift 20 bytes to mant1*/

    b asmLoop

    /*If we're here, we have negative sign bits, need to check exponent equivalency*/
    negative_sign_bits:
    /*Load real exponents for later comparison*/
    ldr r4, =realExp0	/*Checking real exponent 0*/
    ldr r5, =storedExp1	/*Issue with label alignment. StoredExp1 actually stored realExp1*/	
    ldr r4, [r4]
    ldr r5, [r5]

    /*Compares exponents, if not equal, then we want the lesser exponent,
    *negative sign bits flips the logic to make the lesser exponent greater on both scenarios
    *for positive and negative exponents
    **/	
    cmp r4, r5
    beq exponents_equal_neg

    addgt r8, r8, 20	/*If r4 is greater than r5, then shift 20 bytes to f1*/
    addgt r9, r9, 20	/*If r4 is greater than r5, then shift 20 bytes to mant1*/

    b asmLoop

    /*--------------------------------------Step 9--------------------------------------*/

    /*Exponents are equal, positive bits*/
    exponents_equal_pos:
    /*Load mantissa's to registers for later comparison*/
    ldr r4, =mant0
    ldr r5, =mant1
    ldr r4, [r4]
    ldr r5, [r5]
    /*If mantissa's are not equal, and the sign bits are positive,
     *then for both scenarios of positive and negative exponents
     *the mantissa with the largest number is the greater of the two
     **/
    cmp r4, r5
    beq mant_equal
    b large_mant_handler

    /*Exponents are equal, negative bits*/
    exponents_equal_neg:
    ldr r0, =f0
    ldr r1, =mant0

    /*Load mantissa's to registers for later comparison*/
    ldr r4, =mant0
    ldr r5, =mant1
    ldr r4, [r4]
    ldr r5, [r5]

    /*If mantissa's are not equal, and the sign bits are negative,
     *then for both scenarios of positive and negative exponents
     *the mantissa with the smallest number is the greater of the two
     **/
    cmp r4, r5
    beq mant_equal
    b small_mant_handler

    /*If here, we want the smaller mantissa*/
    small_mant_handler:
    cmp r4, r5		/*This compares the mantissa's that are loaded in these registers*/
    addgt r8, r8, 20    /*If r4 is greater than r5, then shift 20 bytes to get f1*/
    addgt r9, r9, 20    /*If r4 is greater than r5, then shift 20 bytes to get mant1*/

    b asmLoop

    /*If here, we want the larger mantissa*/
    large_mant_handler:
    cmp r4, r5		/*This compares the mantissa's that are loaded in these registers*/
    addlt r8, r8, 20    /*If r4 is less than r5, then shift 20 bytes to get f1*/
    addlt r9, r9, 20    /*If r4 is less than r5, then shift 20 bytes to get mant1*/

    b asmLoop
    
    /*--------------------------------------Step 10--------------------------------------*/
    
    /*mantissa's are equal therefore, at this point, the numbers should be the same*/
    mant_equal:
    b asmLoop



    /***********asmLoop is used to store f* values to fMax labels. This is used multiple times***********/
    asmLoop:
    add r9, r9, 4	/*Need this to handle the offset caused by post increments below*/

    asm_loop:
    ldr r3, [r8], 4	/*Sets up r3 with the f* value to store in the next step*/
    str r3, [r10], 4    /*Stores f* values to fMax labels*/

    cmp r8, r9		/*If r8 and r9 are equal, we iterated through all 5 values*/
    beq done		/*When r8 and r9 are equal, we are done*/
    b asm_loop	    

    done:
    ldr r0, =fMax	/*Figured out this is needed for pointer check test*/
    pop {r4-r11, lr}    /*Restore saved registers and lr*/
    bx LR		/*Link back to caller*/
    /* YOUR asmFmax CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           



