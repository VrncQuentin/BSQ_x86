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
SRC			=	src/main.asm				\
#					src/file/get_size.asm		\
#					src/file/retrieve.asm		\
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
