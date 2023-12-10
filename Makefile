RM=rm
NASM=nasm
BASIC_WRAP=python3 wrap.py

.PHONY: clean

all: biosdump.bas helloworld.bas helloserial.bas soundtest.bas disksense.bas

clean:
	$(RM) -fv *.bin *.lst *.bas

%.bas: %.bin
	$(BASIC_WRAP) $< $@

%.bin: %.asm
	$(NASM) -f bin -o $@ $<

