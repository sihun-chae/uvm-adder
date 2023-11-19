all:
	xvlog -L uvm --sv adder.sv testbench.sv
	xelab -L uvm -debug typical -relax -top my_testbench -snapshot my_testbench_snapshot
	xsim my_testbench_snapshot -R

clean:
	rm -rf xsim.dir *.log *.pb *.jou *.wdb
