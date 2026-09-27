###############################################################################
# SDC FILE: mac_16bit.sdc
# Technology: SkyWater 130nm (sky130_fd_sc_hd)
# Target Frequency: 100 MHz (Period: 10.0 ns)
###############################################################################

# 1. KHAI BÁO XUNG NHỊP CƠ BẢN (CLOCK DEFINITION)
create_clock -name clk -period 10.0 -waveform {0.0 5.0} [get_ports clk]

# 2. BÙ TRỪ ĐỘ KHÔNG ỔN ĐỊNH VÀ ĐỘ DỐC XUNG NHỊP (CLOCK REALISM)
set_clock_uncertainty 0.25 [get_clocks clk]
set_clock_transition 0.15 [get_clocks clk]

# 3. RÀNG BUỘC TRỄ NGÕ VÀO (INPUT DELAY)
set_input_delay -clock clk -max 2.0 [get_ports {en clr in_a[*] in_b[*]}]
set_input_delay -clock clk -min 0.5 [get_ports {en clr in_a[*] in_b[*]}]

# 4. RÀNG BUỘC TRỄ NGÕ RA (OUTPUT DELAY)
set_output_delay -clock clk -max 2.0 [get_ports {out_acc[*] valid_out ovf}]
set_output_delay -clock clk -min 0.5 [get_ports {out_acc[*] valid_out ovf}]

# 5. MÔ HÌNH HÓA ĐẶC TÍNH ĐIỆN VẬT LÝ (DRIVING & LOAD)
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_2 [get_ports {en clr in_a[*] in_b[*]}]
set_load 0.035 [get_ports {out_acc[*] valid_out ovf}]

# 6. NGOẠI LỆ THỜI GIAN (TIMING EXCEPTIONS)
set_false_path -from [get_ports rst_n]