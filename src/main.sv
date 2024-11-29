module main (
    input wire clk, rst,
    input wire signed [15:0] real_x [0:7],
    input wire signed [15:0] imag_x [0:7],
    output reg signed [15:0] real_X [0:7],
    output reg signed [15:0] imag_X [0:7],
    output reg valid
);

reg signed [15:0] twiddle_real [0:3];
reg signed [15:0] twiddle_imag [0:3];

reg signed [15:0] stage1_real [0:7];
reg signed [15:0] stage1_imag [0:7];
reg signed [15:0] stage2_real [0:7];
reg signed [15:0] stage2_imag [0:7];

butterfly bfly(
    .real_a(),
    .imag_a(),
    .real_b(),
    .imag_b(),
    .twiddle_real(),
    .twiddle_imag,
    .out1_real(),
    .out1_imag(),
    .out2_real(),
    .out2_imag()
);

initial begin
    // W8^0 = 1
    twiddle_real[0] = 16'h7FFF;  // 1.0 in Q15 format
    twiddle_imag[0] = 16'h0000;  // 0.0
    
    // W8^1 = cos(2π/8) - j*sin(2π/8)
    twiddle_real[1] = 16'h5A82;  // 0.707 in Q15
    twiddle_imag[1] = 16'hA57E;  // -0.707 in Q15
    
    // W8^2 = cos(4π/8) - j*sin(4π/8)
    twiddle_real[2] = 16'h0000;  // 0
    twiddle_imag[2] = 16'h8000;  // -1.0
    
    // W8^3 = cos(6π/8) - j*sin(6π/8)
    twiddle_real[3] = 16'hA57E;  // -0.707
    twiddle_imag[3] = 16'h5A82;  // 0.707
end

integer i, j, k;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        valid <= 0;
        for (i = 0; i < 8; i = i + 1) begin
            real_X <= 0;
            imag_X <= 0;
        end
    end else begin
        // Bit-reversal input stage
        stage1_real[0] = x_real[0];
        stage1_imag[0] = x_imag[0];
        stage1_real[1] = x_real[4];
        stage1_imag[1] = x_imag[4];
        stage1_real[2] = x_real[2];
        stage1_imag[2] = x_imag[2];
        stage1_real[3] = x_real[6];
        stage1_imag[3] = x_imag[6];
        stage1_real[4] = x_real[1];
        stage1_imag[4] = x_imag[1];
        stage1_real[5] = x_real[5];
        stage1_imag[5] = x_imag[5];
        stage1_real[6] = x_real[3];
        stage1_imag[6] = x_imag[3];
        stage1_real[7] = x_real[7];
        stage1_imag[7] = x_imag[7];
        
        // First stage of FFT (4 groups of 2)
        for (k = 0; k < 4; k = k + 1) begin
            // Butterfly for each pair
            stage2_real[k] = stage1_real[k] + stage1_real[k+4];
            stage2_imag[k] = stage1_imag[k] + stage1_imag[k+4];
            stage2_real[k+4] = stage1_real[k] - stage1_real[k+4];
            stage2_imag[k+4] = stage1_imag[k] - stage1_imag[k+4];
        end
        
        // Second stage (2 groups of 4)
        for (k = 0; k < 2; k = k + 1) begin
            // First pair
            X_real[k*4] = stage2_real[k*4] + stage2_real[k*4+2];
            X_imag[k*4] = stage2_imag[k*4] + stage2_imag[k*4+2];
            
            // Multiply pairs with twiddle factors
            X_real[k*4+2] = stage2_real[k*4] - stage2_real[k*4+2];
            X_imag[k*4+2] = stage2_imag[k*4] - stage2_imag[k*4+2];
            
            // Second pair
            X_real[k*4+1] = stage2_real[k*4+1] + stage2_real[k*4+3];
            X_imag[k*4+1] = stage2_imag[k*4+1] + stage2_imag[k*4+3];
            X_real[k*4+3] = stage2_real[k*4+1] - stage2_real[k*4+3];
            X_imag[k*4+3] = stage2_imag[k*4+1] - stage2_imag[k*4+3];
        end
        
        // Final stage with twiddle factor multiplication
        X_real[1] = X_real[1] * twiddle_real[1] - X_imag[1] * twiddle_imag[1];
        X_imag[1] = X_real[1] * twiddle_imag[1] + X_imag[1] * twiddle_real[1];
        
        X_real[3] = X_real[3] * twiddle_real[3] - X_imag[3] * twiddle_imag[3];
        X_imag[3] = X_real[3] * twiddle_imag[3] + X_imag[3] * twiddle_real[3];
        
        X_real[5] = X_real[5] * twiddle_real[1] - X_imag[5] * twiddle_imag[1];
        X_imag[5] = X_real[5] * twiddle_imag[1] + X_imag[5] * twiddle_real[1];
        
        X_real[7] = X_real[7] * twiddle_real[3] - X_imag[7] * twiddle_imag[3];
        X_imag[7] = X_real[7] * twiddle_imag[3] + X_imag[7] * twiddle_real[3];
        
        // Set valid flag
        valid <= 1;
    end
end