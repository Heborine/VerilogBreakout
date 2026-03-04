module display_shape (
    input wire enabled,
    
    input pixelX[9:0],
    input pixelY[9:0],

    input wire [9:0] lowerX,
    input wire [9:0] lowerY,
    input wire [9:0] upperX,
    input wire [9:0] upperY,

    input wire [2:0] redVal,
    input wire [2:0] greenVal,
    input wire [1:0] blueVal, 
2
    output wire inShape,
    output wire [2:0] redOut,
    output wire [2:0] greenOut,
    output wire [2:0] blueOut
);
    assign inShape = enabled &&
        (lowerX <= pixelX && pixelX < upperX) &&
        (lowerY <= pixelY && pixelY < upperY);
    
    assign redOut = inShape ? redVal : 3'b000;
    assign greenOut = inShape ? greenVal : 3'b000;
    assign blueOut = inShape ? blueVal : 2'b00;

endmodule //display_shape