nop # Test with new instruction
nop
nop
nop
nop
nop
addi $r1, $r1, 5 # r1 = 5
addi $r5, $r5, 2 # r5 = 2
lnf $r1, $r5, 3 # r1 = r5 shift 3, will be 1
addi $r3, $r3, 7 # r3 = 7