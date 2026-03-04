module clock_divider (
    input clk, // 100 Mhz
    input rst,
    output dclk // 25Mhz
)
    reg [1:0] counter_25Mhz = 2'd0;

    always(@posedge clk or posedge rst) begin
        if (rst) begin
            counter_25Mhz <= 2'd0;
            clk_25Mhz = 1'b0;
        end else begin
            if(counter_25Mhz == 1'd1) begin
                counter_25Mhz <= 2'd0;
                clk_25Mhz <= ~clk_25Mhz;
            end
            else begin
                counter_25Mhz <= counter_25Mhz + 1'b1;
            end  
        end   
    end

endmodule