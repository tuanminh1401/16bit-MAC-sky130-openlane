module mac_16bit (
    input logic clk, 
    input logic rst_n,
    input logic en,
    input logic clr,
    input logic signed [15:0] in_a,
    input logic signed [15:0] in_b,
    output logic signed [35:0] out_acc,
    output logic valid_out,
    output logic ovf
);
    //STAGE 1
    logic signed [31:0] reg_tmp;
    logic clr_delay;
    logic en_delay;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_tmp <= '0;
            clr_delay <= 1'b0;
            en_delay <= 1'b0;
        end else begin
            en_delay <= en;
            if (en) begin
                reg_tmp <= in_a * in_b;
                clr_delay <= clr;
            end
        end
    end

    //STAGE 2
    logic signed [35:0] add_tmp;
    assign add_tmp = {{4{reg_tmp[31]}}, reg_tmp};

    //báo tràn
    logic signed [36:0] sum_37;
    assign sum_37 = 37'(out_acc) + 37'(add_tmp);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin   
            valid_out <= 1'b0;
            out_acc <= '0;
            ovf <= 1'b0;
        end else begin
            valid_out <= en_delay;
            if (en_delay) begin
                if (clr_delay) begin
                    out_acc <= add_tmp;
                    ovf <= 1'b0;                                    //chỉ test tràn khi cộng dồn
                end else begin
                    out_acc <= sum_37[35:0];
                    ovf <= (sum_37[36] != sum_37[35]);
                end
            end else ovf <= 1'b0;
        end
    end

endmodule