module lcd_controller (
    input  wire        clk50M,
    input  wire        reset,
    input  wire [9:0]  pc_instrucao,     // PC atual (0 a 1023)
    input  wire [3:0]  pid_processo,     // Processo corrente (0 a 10)
    input  wire [3:0]  prox_proc1,       // Próximo processo na fila (ex: 2)
    input  wire [3:0]  prox_proc2,       // Segundo próximo (ex: 3)
    input  wire [3:0]  prox_proc3,       // Terceiro próximo (ex: 4)

    // Interface física com o LCD da DE2-115
    output wire [7:0]  lcd_data,
    output wire        lcd_rs,
    output wire        lcd_rw,
    output wire        lcd_en,
    output wire        lcd_on,
    output wire        lcd_blon
);

    assign lcd_on   = 1'b1;
    assign lcd_blon = 1'b1;
    assign lcd_rw   = 1'b0;

    // Base de tempo de 1 kHz (~1 ms) para estabilidade do LCD
    reg [19:0] clk_div;
    reg        lcd_tick;

    always @(posedge clk50M or posedge reset) begin
        if (reset) begin
            clk_div  <= 20'd0;
            lcd_tick <= 1'b0;
        end else if (clk_div >= 20'd50_000) begin
            clk_div  <= 20'd0;
            lcd_tick <= 1'b1;
        end else begin
            clk_div  <= clk_div + 1'b1;
            lcd_tick <= 1'b0;
        end
    end

    function [7:0] to_ascii;
        input [3:0] digit;
        begin
            to_ascii = 8'h30 + {4'd0, digit};
        end
    endfunction

    // Decomposição decimal do PC
    wire [3:0] pc_m = (pc_instrucao / 10'd1000) % 10'd10;
    wire [3:0] pc_c = (pc_instrucao / 10'd100)  % 10'd10;
    wire [3:0] pc_d = (pc_instrucao / 10'd10)   % 10'd10;
    wire [3:0] pc_u =  pc_instrucao % 10'd10;

    // Buffer da Linha 1 (16 chars): "P:01    PC: 0016"
    wire [7:0] linha1 [0:15];
    assign linha1[0]  = "P";
    assign linha1[1]  = ":";
    assign linha1[2]  = to_ascii((pid_processo / 4'd10) % 4'd10);
    assign linha1[3]  = to_ascii(pid_processo % 4'd10);
    assign linha1[4]  = " ";
    assign linha1[5]  = " ";
    assign linha1[6]  = " ";
    assign linha1[7]  = "P";
    assign linha1[8]  = "C";
    assign linha1[9]  = ":";
    assign linha1[10] = " ";
    assign linha1[11] = to_ascii(pc_m);
    assign linha1[12] = to_ascii(pc_c);
    assign linha1[13] = to_ascii(pc_d);
    assign linha1[14] = to_ascii(pc_u);
    assign linha1[15] = " ";

    // Buffer da Linha 2 (16 chars): "FILA: 02  03  04"
    wire [7:0] linha2 [0:15];
    assign linha2[0]  = "F";
    assign linha2[1]  = "I";
    assign linha2[2]  = "L";
    assign linha2[3]  = "A";
    assign linha2[4]  = ":";
    assign linha2[5]  = " ";
    assign linha2[6]  = to_ascii((prox_proc1 / 4'd10) % 4'd10);
    assign linha2[7]  = to_ascii(prox_proc1 % 4'd10);
    assign linha2[8]  = " ";
    assign linha2[9]  = " ";
    assign linha2[10] = to_ascii((prox_proc2 / 4'd10) % 4'd10);
    assign linha2[11] = to_ascii(prox_proc2 % 4'd10);
    assign linha2[12] = " ";
    assign linha2[13] = " ";
    assign linha2[14] = to_ascii((prox_proc3 / 4'd10) % 4'd10);
    assign linha2[15] = to_ascii(prox_proc3 % 4'd10);

    // FSM de controle do LCD
    localparam S_BOOT      = 4'd0,
               S_INIT_1    = 4'd1, // Function Set: 8-bit, 2 lines
               S_INIT_2    = 4'd2, // Display ON
               S_INIT_3    = 4'd3, // Clear Display
               S_INIT_4    = 4'd4, // Entry Mode Set
               S_SET_LINE1 = 4'd5, // Endereço 0x80 (Linha 1)
               S_WR_LINE1  = 4'd6,
               S_TG_LINE1  = 4'd7,
               S_SET_LINE2 = 4'd8, // Endereço 0xC0 (Linha 2)
               S_WR_LINE2  = 4'd9,
               S_TG_LINE2  = 4'd10;

    reg [3:0] state;
    reg [3:0] idx;
    reg [7:0] out_data;
    reg       out_rs;
    reg       out_en;

    assign lcd_data = out_data;
    assign lcd_rs   = out_rs;
    assign lcd_en   = out_en;

    always @(posedge clk50M or posedge reset) begin
        if (reset) begin
            state    <= S_BOOT;
            idx      <= 4'd0;
            out_data <= 8'h00;
            out_rs   <= 1'b0;
            out_en   <= 1'b0;
        end else if (lcd_tick) begin
            case (state)
                S_BOOT: begin
                    out_en <= 1'b0;
                    state  <= S_INIT_1;
                end

                S_INIT_1: begin
                    out_rs   <= 1'b0;
                    out_data <= 8'h38; // 2 linhas, 5x8 dots
                    out_en   <= 1'b1;
                    state    <= S_INIT_2;
                end

                S_INIT_2: begin
                    out_en   <= 1'b0;
                    out_rs   <= 1'b0;
                    out_data <= 8'h0C; // Display ligado, cursor desligado
                    state    <= S_INIT_3;
                end

                S_INIT_3: begin
                    out_en   <= 1'b1;
                    out_rs   <= 1'b0;
                    out_data <= 8'h01; // Limpa LCD
                    state    <= S_INIT_4;
                end

                S_INIT_4: begin
                    out_en   <= 1'b0;
                    out_rs   <= 1'b0;
                    out_data <= 8'h06; // Incremento automático
                    state    <= S_SET_LINE1;
                end

                // Inicia escrita da Linha 1
                S_SET_LINE1: begin
                    out_en   <= 1'b1;
                    out_rs   <= 1'b0;
                    out_data <= 8'h80; // Início Linha 1
                    idx      <= 4'd0;
                    state    <= S_WR_LINE1;
                end

                S_WR_LINE1: begin
                    out_en   <= 1'b0;
                    out_rs   <= 1'b1;
                    out_data <= linha1[idx];
                    state    <= S_TG_LINE1;
                end

                S_TG_LINE1: begin
                    out_en <= 1'b1;
                    if (idx == 4'd15) begin
                        state <= S_SET_LINE2;
                    end else begin
                        idx   <= idx + 1'b1;
                        state <= S_WR_LINE1;
                    end
                end

                // Inicia escrita da Linha 2
                S_SET_LINE2: begin
                    out_en   <= 1'b1;
                    out_rs   <= 1'b0;
                    out_data <= 8'hC0; // Início Linha 2
                    idx      <= 4'd0;
                    state    <= S_WR_LINE2;
                end

                S_WR_LINE2: begin
                    out_en   <= 1'b0;
                    out_rs   <= 1'b1;
                    out_data <= linha2[idx];
                    state    <= S_TG_LINE2;
                end

                S_TG_LINE2: begin
                    out_en <= 1'b1;
                    if (idx == 4'd15) begin
                        state <= S_SET_LINE1; // Loop de atualização contínua
                    end else begin
                        idx   <= idx + 1'b1;
                        state <= S_WR_LINE2;
                    end
                end

                default: state <= S_BOOT;
            endcase
        end
    end

endmodule
