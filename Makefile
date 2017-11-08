.PHONY: prepare upload clean

PROJECT = top
SRCS = $(filter _tb.v, $(wildcard *.v))


upload: $(PROJECT).bin
	sudo iceprog -S $(PROJECT).bin

$(PROJECT).bin: $(PROJECT).txt
	icepack $(PROJECT).txt $(PROJECT).bin

$(PROJECT).txt: $(PROJECT).blif
	arachne-pnr -d 8k -p ice40hx8k-evn-b.pcf -o $(PROJECT).txt $(PROJECT).blif

$(PROJECT).blif: $(PROJECT).v $(SRCS)
	yosys -p "read_verilog $(SRCS) $(PROJECT).v; synth_ice40 -blif $(PROJECT).blif"

clean:
	-rm -f $(PROJECT).bin $(PROJECT).txt $(PROJECT).blif

prepare:
	git submodule init
	git submodule update
	cd icestorm;make -j9;sudo make install;cd -
	cd arachne-pnr;make -j9;sudo make install;cd -
	cd yosys;make -j9;sudo make install; cd -
	cd yodl;./configure;cd -
	cd yodl/vhdlpp;make -j9;sudo make install;cd -
	sudo echo 'ACTION=="add", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE:="666"' >/etc/udev/rules.d/53-lattice-ftdi.rules

