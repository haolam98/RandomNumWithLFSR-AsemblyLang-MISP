    .data
askUserNUM:     .asciiz "\n\nEnter a number : "
askQuit:        .asciiz "\n\nDo you want to continue generate Random Num?\n(Enter 0 to quit; 1 to continue):"
yourRandNUM:    .asciiz "\nYour random number is: "
    .globl main
    .text
main:
        li $s0, 0

        la $a0, askUserNUM
        li $v0,4
        syscall

        #readin value, save into s0
        li  $v0,5	
    	syscall	
    	move $s0,$v0

        j generateNumber
do_loop:
#ASK USER enter a random number to set the initial state
#s0 hold user input
        #print ask
        la $a0, askQuit
        li $v0,4
        syscall

         #readin value, save into t6
        li  $v0,5	
    	syscall	
    	move $t6,$v0

        beqz $t6,exit           # if read-in t6=0 then exit program
#else continue generate rand num:
generateNumber:
#GENERATE random number by calling funct generateRANDOM(user_input)
#t9 hold return value -> random number output from funct call
        #store s0 into memory
        addi $sp ,$sp, -4 
        sw $s0, 0($sp)

        #call funct
        jal generateRANDOM

        lw $s0,0 ($sp) #->load back new state for later generate
        #save return value into t9
        move $t9,$v0

        #deallocate
        addi $sp,$sp,4 

#PRINT OUT RANDOM NUMBER
        #print ouput
        la $a0,yourRandNUM
        li $v0,4
        syscall 

        move $a0,$t9
        li $v0, 1
        syscall
#JUMP BACK to the loop
        j do_loop

exit:
        li $v0,10
        syscall


################
generateRANDOM:
###  int generateRANDOM (int userInput_RandNUM)
#t0 hold tap
#t1 hold user_input
#t2 hold B= state & 0x1;
#t3 hold randnum
#t9= int i (use in for loop)

        #tap =  x^20 + x^19 + x^16 + x^14 (leave last digit)=0000000000001100101000000000000
        #store tap in t0        
        li $t0,0x000CA000 

        #set t3=randnum=0
        li $t3,0

        #load user_input from memory into t1
        lw $t1, 0($sp)

        #generate random num (5-bit) using for loop
# t9= int i
        li $t9, 0

        j FOR_check
        # for (int i=0; i<5; i++)
FOR_loop:

	#CALL FUNCT: state = LFSR (state)
            #call LFSR(state)
            addi $sp,$sp, -20
            sw $t0,0($sp)
            sw $t1,4($sp)
            sw $t3,8($sp)
            sw $t9, 12($sp)
            sw $ra, 16($sp)

            jal LFSR #CALL

            #load back original value for tap, i and $ra 
            lw $t0,0 ($sp)
            lw $t3,8 ($sp)
            lw $t9,12($sp)
            lw $ra,16($sp)

            #set state= new state (return value)
            move $t1, $v0

            #deallocate
            addi $sp,$sp, 20

            #STORE BACK NEW STATE to memory
             sw $t1, 0($sp)
	#CALCULATE B= state & 0x1;
#t2 hold B value
#t8 hold 0x01 value (temp)

            #calculate
            li $t8, 0x01
            and $t2, $t1, $t8 

	#GENERATE rand= (rand <<1) | B;  #rand shift left, then or with B
#t3 hold randnum
            # randnum shift left 1
            sll $t3,$t3,1

            # randnum or with B
            or $t3,$t3,$t2

        #INCREASE count , t9++
        addi $t9,$t9,1

FOR_check:
        blt $t9,5,FOR_loop

        #return value
        move $v0,$t3
        jr $ra

######################################################       
LFSR:
## int LFSR (int state, int tap)
#t0 hold tap
#t1 hold state
#t3 hold LSB

        lw $t0, 0($sp)          #load tap
        lw $t1, 4($sp)          #load state
        # t3 = t1 & 1 = LSB
        andi $t3,$t1,1           #find the LSB; LSB=t3
        #check t3 if (t3==1)
        beq $t3,1,withTap 
        # shift right t1 to 1 
        srl $t1,$t1,1            #shift t1 to 1 bit and store in t1
     
        #return new state in t1
        move $v0,$t1
        jr $ra
withTap:
        # shift right t1 to 1 
        srl $t1,$t1,1            #shift t1 to 1 bit and store in t1
        #xor with taps
        xor $t1,$t1,$t0      
       
        # then return new state in t1
        move $v0, $t1
        jr $ra

