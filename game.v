module Top(
        input clk, // 100 MHz clock
        input rst,
        output reg [6:0] seg,
        output reg [3:0] an
    );
    reg [6:0] score;
    reg reset_sync1;
    reg reset_sync2;
    reg reset_debounce;
    reg reset_prev;
    reg [16:0] debounce_count_reset;

    always @(posedge clk) begin
        reset_sync1 <= rst;
        reset_sync2 <= reset_sync1;
    end

    if(reset_debounce != reset_sync2) begin
        debounce_count_reset <= debounce_count_reset + 1;
        //1ms = 0.001s 
        //0.001 * 100000000 = 100000 cycles
        if(debounce_count_reset >= 17'd100000) begin
             debounce_count_reset <= 0;
             reset_debounce <= reset_sync2;
        end
    end else begin
        debounce_count_reset <= 0;
    end

    reset_prev <= reset_debounce;

    if (reset_debounce && !reset_prev) begin
    end

endmodule