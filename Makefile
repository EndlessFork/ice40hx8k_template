.PHONY: prepare

prepare:
	cd icestorm;make -j9;sudo make install;cd -
	cd arachne-pnr;make -j9;sudo make install;cd -
	cd yosys;make -j9;sudo make install; cd -
	cd yodl;./configure;cd -
	cd yodl/vhdlpp;make -j9;sudo make install;cd -
	sudo echo 'ACTION=="add", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE:="666"' >/etc/udev/rules.d/53-lattice-ftdi.rules


