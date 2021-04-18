nop # Test with new instruction
nop
nop
nop
nop
nop
addi $r1, $r1, 5 # r1 = 5
addi $r5, $r5, 1 # r5 = 1
lnf $r1, $r5, 4 # r1 = r5 shift 4 linear, actually 0