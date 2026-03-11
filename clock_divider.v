module clock_divider (
    input wire clk, // 100 Mhz
    input wire rst,
    output reg dclk // 25Mhz
);

    reg [1:0] counter_25Mhz = 2'd0;

    always @(posedge clk) begin
        if(counter_25Mhz == 1'd1) begin
            counter_25Mhz <= 2'd0;
            dclk <= ~dclk;
        end
        else begin
            counter_25Mhz <= counter_25Mhz + 1'b1;
        end
    end

endmodule