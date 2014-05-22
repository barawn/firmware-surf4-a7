KCPSM6 =  /usr/bin/kcpsm6

all	:	l4_i2c_rom.vhd rfp_dummy.vhd
%.vhd :	%.psm %.vhd_template
	cp $*.vhd_template ROM_form.vhd
	$(KCPSM6) $*.psm
	rm -rf ROM_form.vhd
