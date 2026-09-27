`timescale 1ns/1ps
module tb_mac_16bit;
    logic clk;
    logic rst_n;
    logic signed [15:0] a;
    logic signed [15:0] b;
    logic en;
    logic clr;
    logic signed [35:0] out;
    logic valid_out;
    logic ovf;

    mac_16bit u_mac_16bit(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .clr(clr),
        .in_a(a),
        .in_b(b),
        .out_acc(out),
        .valid_out(valid_out),
        .ovf(ovf)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    //golden model
    logic signed [35:0] expected_q[$];
    logic expected_ovf_q[$];
    logic signed [35:0] golden_acc = '0;
    int match_count = 0;
    int error_count = 0;

    //task reset phần cứng
    task automatic reset_dut();
        rst_n = 1'b0;
        en = 1'b0;
        clr = 1'b0;
        a = '0;
        b = '0;
        golden_acc = '0;
        expected_q.delete();
        expected_ovf_q.delete();
        match_count = 0;
        error_count = 0;
        repeat(3) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
    endtask

    //task bơm dư liệu theo chu kì
    task automatic drive (
        input logic signed [15:0] val_a,
        input logic signed [15:0] val_b,
        input logic val_en,
        input logic val_clr
    );
        logic signed [36:0] g_sum;
        logic exp_ovf;
        @(negedge clk);
        a = val_a;
        b = val_b;
        en = val_en;
        clr = val_clr;

        //----GOLDEN MODEL----
        if (val_en) begin
            logic signed [31:0] prod;
            prod = val_a * val_b;
            if (val_clr) begin
                golden_acc = 36'(prod);
                exp_ovf = 1'b0;
            end else begin
                g_sum = 37'(golden_acc) + 37'(prod);
                golden_acc = g_sum[35:0];
                exp_ovf = (g_sum[36] != g_sum[35]);
            end
            
            //lưu kết quả vào queue
            expected_ovf_q.push_back(exp_ovf);
            expected_q.push_back(golden_acc);
        end  
    endtask

    //scoreboard
    always @(posedge clk) begin
        if (rst_n && valid_out) begin
            if (expected_q.size() > 0) begin
                logic signed [35:0] exp_val; 
                logic exp_ovf;
                exp_val = expected_q.pop_front();
                exp_ovf = expected_ovf_q.pop_front();

                if ((out == exp_val) && (ovf == exp_ovf)) begin
                    $display("[PASS] Time=%0t | DUT out=%0d, ovf=%0b | Exp out=%0d, ovf=%0b", $time, out, ovf, exp_val, exp_ovf);
                    match_count++;
                end else begin
                    $display("[FAIL ERROR] Time=%0t | DUT out=%0d, ovf=%0b | Exp out=%0d, ovf=%0b", $time, out, ovf, exp_val, exp_ovf);
                    error_count++;
                end
            end else begin
                $display("[FATAL] Time=%0t | valid_out bat len nhung khong co du lieu ky vong trong Queue!", $time);
                error_count++;
            end
        end
    end

    initial begin
        logic signed [15:0] rand_a, rand_b;
        logic rand_en, rand_clr;
        int num_tests;
        num_tests = 1000;

        reset_dut();

        //1. Chạy corner case cơ bản
        $display("---- GIAI DOAN 1: CORNER CASES & OVERFLOW TEST ----");
        drive(16'd1, 16'd2, 1'b1, 1'b1);
        //cực đại dương x cực đại dương
        drive(16'sd32767, 16'sd32767, 1'b1, 1'b0);                
        //cực tiểu âm x cực đại dương
        drive(-16'sd32768, 16'sd32767, 1'b1, 1'b1);
        //cực tiểu âm x cực tiêu âm
        drive(-16'sd32768, -16'sd32768, 1'b1, 1'b1);
        //cực tiểu âm x (-1)
        drive(-16'sd32768, -16'sd1, 1'b1, 1'b1);
        //triệt tiêu với 0
        drive(16'sd0, -16'sd32768, 1'b1, 1'b1); 
        //test cờ tràn
        repeat(33) begin
            drive(16'sd32767, 16'sd32767, 1'b1, 1'b0);                
        end                   
        //xóa dữ liệu
        drive('0, '0, 1'b0, 1'b0);
        wait (expected_q.size() == 0);
        
        //2. Chạy constraint random testing
        $display("---- GIAI DOAN 2: RANDOM STRESS-TEST (%0d GIAO DICH) ----", num_tests);
        for (int i = 0; i < num_tests; i++) begin
            rand_a = $urandom();
            rand_b = $urandom();
            rand_en = ($urandom_range(0, 99) < 85);
            rand_clr = ($urandom_range(0, 99) < 5);
            drive(rand_a, rand_b, rand_en, rand_clr);
        end
        
        //xóa dữ liệu
        drive('0, '0, 1'b0, 1'b0);
        wait (expected_q.size() == 0);
        repeat (3) @(negedge clk);

        // 4. Bảng tổng kết kết quả kiểm thử
        $display("\n============================================");
        $display("        BAO CAO KIEM THU (FINAL REPORT)     ");
        $display("============================================");
        $display("Tong so transactions kiem tra : %0d", match_count + error_count);
        $display("So ca PASS                   : %0d", match_count);
        $display("So ca FAIL                   : %0d", error_count);
        $display("Du lieu con sot trong Queue  : %0d", expected_q.size());
        $display("============================================");

        if (error_count == 0 && expected_q.size() == 0) begin
            $display("===> KET LUAN: DUT PASSED HOAN TOAN! <===\n");
        end else begin
            $display("===> KET LUAN: PHAT HIEN LOI THIET KE! <===\n");
        end
        
        $display("----Ket thuc mo phong----");
        $stop;
    end

endmodule