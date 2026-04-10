NASM       = "c:\program files\nasm\nasm.exe"
OBJ_DIR    = build64
SRC_DIR    = src
TARGET_OBJ = $(OBJ_DIR)\interupt.obj

NASM_FLAGS = -f win64 -g -F cv8

# --- Rules ---

# 'all' 
all: $(TARGET_OBJ)

# main rule
$(TARGET_OBJ): $(SRC_DIR)\interupt.asm | $(OBJ_DIR)
	$(NASM) $(NASM_FLAGS) $(SRC_DIR)\interupt.asm -o $(TARGET_OBJ)
$(OBJ_DIR):
	mkdir $(OBJ_DIR)