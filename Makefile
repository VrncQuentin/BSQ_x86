# Basics
#################
SHELL			?=	/bin/sh
RM				=	-@rm -rf
CC				=	gcc
AS				=	nasm
#################

# Flags
#################
ASFLAGS		=	-f elf64 -g
#################

# Source
#################
SRC			=	main.asm
#################

# Obj
#################
OBJ			=	$(SRC:.asm=.o)
#################

# End file
#################
BIN			=	bsq
#################

# Compilation.
all:	$(BIN)
$(BIN):	$(OBJ)
	$(CC) $(OBJ) -o $(BIN)

tests_run: $(BIN)
	@./tests/mouli
# [END] Compilation

## Conversion.
%.o: %.asm
	$(AS) $(ASFLAGS) $^ -o $@
# [END] Compilation.

# Clean Rules
clean:
	$(RM) $(OBJ)

fclean:	clean
	$(RM) $(BIN)
# [END] Clean

# Misc.
re: fclean all
.PHONY: all re clean fclean $(BIN)
# [END] Misc.
