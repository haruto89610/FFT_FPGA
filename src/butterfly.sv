module butterfly (
    input signed [15:0] real_a, imag_a,
    input signed [15:0] real_b, imag_b,
    input signed [15:0] twiddle_real, twiddle_imag,
    output reg signed [15:0] out1_real, out1_imag,
    output reg signed [15:0] out2_real, out2_imag
);

always @(*) begin
    out1_real = real_a + ((real_b * twiddle_real - imag_b * twiddle_imag) >>> 15);
    out1_imag = imag_a + ((real_b * twiddle_imag + imag_b * twiddle_real) >>> 15);

    out2_real = real_a - ((real_b * twiddle_real - imag_b * twiddle_imag) >>> 15);
    out2_imag = imag_a - ((real_b * twiddle_imag + imag_b * twiddle_real) >>> 15);
end

endmodule