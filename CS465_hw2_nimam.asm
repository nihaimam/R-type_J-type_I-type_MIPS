.data 
	instruction: .asciiz "Instruction to decode? "
	address: .asciiz "Instruction address? "
	format: .asciiz "Format type: "
	r_type: .asciiz "R-type\n"
	i_type: .asciiz "I-type\n"
	j_type: .asciiz "J-type\n"
	destination: .asciiz "Destination register: "
	next: .asciiz "Next PC: "
	invalid: .asciiz "invalid\n"
	none: .asciiz "none\n"
	slash: .asciiz " / "
	buffer: .space 9

.text
.globl main
main:
	#take in a hex string and convert it to int/decimal
	#prompt user for an instruction
	la $a0, instruction	# load prompt
	li $v0, 4		# print instruction
	syscall
	li $v0, 8       	# take in input
	la $a0, buffer		# load byte space into address
	li $a1, 10		# allot the byte space for string 8 numbers and null space
	syscall
	
	#extract instruction value
	jal extraction
	move $s0, $v0		# save address string to s0
	
	#prompt user for an address
	la $a0, address		# load prompt
	li $v0, 4		# print instruction
	syscall
	li $v0, 8       	# take in input
	la $a0, buffer		# load byte space into address
	li $a1, 10		# allot the byte space for string 8 numbers and null space
	syscall
	
	#extract address value
	jal extraction
	move $s1, $v0		# save address string to s1
	
	#subroutine #1
	move $a0, $s0		#move instruction into arguement
	jal get_type
	move $s3, $v0		# $s3 = format type
	move $a1, $v0		# as arguement for dest_reg $a1
	beqz $s3, not_supported	
	beq $s3, 1, R_type
	beq $s3, 2, I_type
	beq $s3, 3, J_type
	
	# print format type
not_supported:			# invalid type
	li $v0, 4
	la $a0, format
	syscall
	li $v0, 4
	la $a0, invalid
	syscall
	j done_one
R_type:				# r_type format
	li $v0, 4
	la $a0, format
	syscall
	li $v0, 4
	la $a0, r_type
	syscall
	j done_one
I_type:				# i_type format
	li $v0, 4
	la $a0, format
	syscall
	li $v0, 4
	la $a0, i_type
	syscall
	j done_one
J_type:				# j_type format
	li $v0, 4
	la $a0, format
	syscall
	li $v0, 4
	la $a0, j_type
	syscall
	j done_one

done_one:
	move $a0, $s0		# move instruction into arguement
	jal get_dest_reg	# call subroutine
	move $s3, $v0		# $s3 = destination register
	beq $s3, $zero, invalid_destination	# invalid destination
	beq $s3, 32, no_dest_reg		# no destination
	li $v0, 4		# print the destination prompt
	la $a0, destination
	syscall
	li $v0, 1		# print the destination register
	move $a0, $s3
	syscall
	j done_two
invalid_destination:		# invalid destination
	li $v0, 4
	la $a0, destination
	syscall
	li $v0, 4
	la $a0, invalid
	syscall
	j done_two
no_dest_reg:			# no destination
	li $v0, 4
	la $a0, destination
	syscall
	li $v0, 4
	la $a0, none
	syscall
	j done_two

done_two:
	move $a0, $s0		# move instruction in arg 1
	move $a1, $s1		# move address in arg 2
	jal get_type
	move $a3, $v0		# move format type in arg 3
	jal get_next_pc		# call subroutine
	srl $t2, $t0, 26	# $t3 = opcode
	beq $t2, 4, branch_address		# print branch address
	beqz $v0, invalid_pc_address		# invalid format = invalid address
	move $t0, $v0		# move the address to temp var
	li $v0, 4		# print next pc prompt
	la $a0, next
	syscall
	li $v0, 34		# print address as hex
	move $a0, $t0
	syscall
	j end
invalid_pc_address:		# invalid address
	li $v0, 4
	la $a0, next
	syscall
	li $v0, 4
	la $a0, invalid
	syscall
	j end
branch_address:			# branch address
	move $t0, $v0		# temp0 is retval0
	move $t1, $v1		# temp1 is retval1
	li $v0, 4		# print next pc prompt
	la $a0, next
	syscall
	li $v0, 34		# print next address as hex (not taken)
	move $a0, $t0
	syscall
	li $v0, 4		
	la $a0, slash
	syscall
	li $v0, 34		# print next address as hex (taken)
	move $a0, $t1
	syscall
	j end

.globl get_type
get_type:
	move $t0, $a0		# move instruction to temp var
	srl $t1, $t0, 26	# shift bits to get opcode
	beqz $t1, validity_check# check validity	
	beq $t1, 1, i_opcode	# print i format
	beq $t1, 2, j_opcode	# print j format
	beq $t1, 3, j_opcode	# print j format
	sge $t2, $t1, 4		# if 4 <= x < 64
	slti $t3, $t1, 64
	and $t2, $t2, $t3	
	beq $t2, 1, i_opcode	# print i format
invalid_type:			# invalid format
	li $v0, 0
	jr $ra 
validity_check:			# check if funct is one of the given
	sll $t4, $a0, 26	
	srl $t4, $t4, 26	# t4 has funct
	beq $t4, 0x20, r_opcode	# add
	beq $t4, 0x22, r_opcode	# sub
	beq $t4, 0x2a, r_opcode	# slt
	j invalid_type		# else ivalid
r_opcode:			# print r format	
	li $v0, 1
	jr $ra 
i_opcode:			# print i format
	li $v0, 2
	jr $ra 
j_opcode:			# print j format
	li $v0, 3
	jr $ra

.globl get_dest_reg
get_dest_reg:
	move $t0, $a0		# $t0 = instruction
	beqz $a1, invalid_dest_reg	# arg2 = int from get_type
	srl $t1, $t0, 26		# $t1 = opcode
	beqz $t1, r_type_opcode		# opcode is r type
	beq $t1, 2, no_destination	# opcode is j type
	beq $t1, 3, no_destination	# opcode is j type
	beq $t1, 4, no_destination	# opcode is branching
	sgt $t3, $t1, 4			# if 4 <= x < 64
	slti $t4, $t1, 64
	and $t3, $t3, $t4
	beq $t3, 1, i_type_opcode	# opcode is i type
invalid_dest_reg:		# invalid
	li $v0, 0		
	jr $ra
r_type_opcode:			# r-type destination
	sll $t2, $a0, 16
	srl $t2, $t2, 27	# $t2 = rd
	move $v0, $t2
	jr $ra
i_type_opcode:			# i-type destination
	sll $t2, $a0, 12
	srl $t2, $t2, 27	# $t2 = rt
	move $v0, $t2
	jr $ra
no_destination:			# beq/j-type destination
	li $v0, 32		# beq, j_type
	jr $ra

.globl get_next_pc
get_next_pc:
	move $t0, $a0		# $t0 is arg1 - instruction
	move $t1, $a1		# $t1 is arg2 - address
	move $t3, $a3 		# $t3 is arg3 - format type
	beq $t3, 0, invalid_pc	# if format type 0 - invalid
	beq $t3, 2, i_type_pc	# if format type 2 - i type
	add $v0, $a1, 4		# next address is PC+4
	jr $ra
invalid_pc:			# invalid PC - return 0
	move $v0, $zero
	jr $ra
i_type_pc:			# i type PC 
	srl $t2, $t0, 26 	# extract opcode
	beq $t2, 4, branch_pc	# check if opcode is 0x04 for beq
	add $v0, $a1, 4		# else next address is PC+4
	jr $ra
branch_pc:			# branch - opcode is 0x04
	addi $v0, $a1, 4 	# PC+4
	sll $t4, $a0, 16	
	srl $t4, $t4, 16	# extract constant/address/offset
	mul $t4,$t4,4		# offset * 4
	move $v1, $v0		# PC+4 is $v0
	add $v1,$v1,$t4		# (offset * 4) + (PC+4) is $v1
	jr $ra

extraction:			# extract hex from string
	li $t3, 0		
	li $t5, 0		# ctr
	move $t0, $a0
hexcheck:	
	add $t5, $t5, 1		# ctr++
	beq $t5, 9, end_hex	# branch if ctr = 9
	lb $t1, 0($t0)		# load 1st ascii value
	beqz $t1, end_hex	
	slti  $t2, $t1, 65	# check if less than 65
	beq $t2, $zero, letter	# if greater than 65 -> letter
	sll $t3, $t3, 1		
	add $t3, $t3, $t1	
	subi $t3, $t3, 48	# subtract 48 to get number
	sll $t4, $t4, 4		# shift $t4 by 4 bits
	or $t4, $t4, $t3	# or $t4 and $t3
	addi $t0, $t0, 1	# increment $t0
	add $t3, $zero, $zero	# $t3 = 0
	j hexcheck		# loop back
letter:
	sll $t3, $t3, 1
	add $t3, $t3, $t1
	subi $t3, $t3, 65	# subtract 65
	addi $t3, $t3, 10	# add 10 to letter
	sll $t4, $t4, 4		# shift $t4 by 4 bits
	or $t4, $t4, $t3	# or $t4 and $t3
	addi $t0, $t0, 1	# increment $t0
	add $t3, $zero, $zero	# $t3 = 0
	j hexcheck		# loop back to hexcheck
end_hex:
	move $v0, $t4
	jr $ra

end:				# end program
	li $v0, 10
	syscall