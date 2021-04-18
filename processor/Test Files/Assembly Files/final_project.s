# Final Project assembly File
nop
nop
nop
nop
nop
# Need to figure out how many cycles we will run the game for, based on that we can use the randomizer
# would need to initialize our special register with addi instructions and then use new instruction lcf until the end
addi $r1, $r1, 5 # r1 = 5
addi $r5, $r5, 2 # r5 = 2
lnf $r1, $r5, 3 # r1 = 2
# and we would probably continue this pattern