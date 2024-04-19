`include "definitions.vh"

module tetris(GPIO_0, clk, reset, sw, sw1, sw2, MTL2_DCLK, MTL2_R, MTL2_G, MTL2_B, MTL2_HSD, MTL2_VSD);
input clk;
input sw;
input sw1;
input sw2;
input reset;
inout [33:0] GPIO_0;

output MTL2_DCLK;
output [7:0] MTL2_R;
output [7:0] MTL2_G;
output [7:0] MTL2_B;
output MTL2_HSD;
output MTL2_VSD;

reg [7:0] red, green, blue;
wire res=~reset;
wire display_on;	
wire [11:0] hpos;
wire [11:0] vpos;
reg clk25 = 0;

localparam BOARD_WIDTH = 11;
localparam BOARD_HEIGHT = 6;
localparam BOARD_SIZE = BOARD_WIDTH * BOARD_HEIGHT;

// Define the game board as a 1D array
reg [BOARD_SIZE-1:0] game_board;

// Initialize the game board to be empty
initial begin
  integer i;
  for (i = 0; i < BOARD_SIZE; i = i + 1) begin
    game_board[i] <= 0;
  end
end

integer i, j, k;
integer index;
reg [1:0] current_block_index = 0;

// Function to check if a block has landed
function has_collision;
  input [11:0] hpos;
  input [11:0] vpos;
  input [5:0] block;
  begin
    // Check for collisions with the game board boundaries
    if (hpos + block_size >= 666) begin
      has_collision = 1;
    end
    
    // Check for collisions with existing blocks on the game board
    for (i = 0; i < 3; i = i + 1) begin
      for (j = 0; j < 2; j = j + 1) begin
        if (block[i*2 + j] && game_board[(hpos + j * block_size)/block_size 
		  + ((vpos + i * block_size)/block_size) * BOARD_WIDTH]) begin
          has_collision = 1;
        end
      end
    end
    
    has_collision = 0;
  end
endfunction


reg [5:0] blocks [3:0]; // 4 blocks, each is a [5:0] matrix representing it
reg [5:0] L_block = 6'b111010; // L block
reg [5:0] T_block = 6'b011101; // T block
reg [5:0] Z_block = 6'b011110; // Z block
reg [5:0] I_block = 6'b101010; // I block

reg [5:0] LR_block = 6'b010111;
reg [5:0] TR_block = 6'b101110; // T block reversed (upside down)
reg [5:0] IR_block = 6'b010101;
reg [5:0] ZR_block = 6'b101101; 

initial begin
    blocks[0] = L_block;
    blocks[1] = T_block;
    blocks[2] = Z_block;
    blocks[3] = I_block;
end

initial begin
    blocks[0] = L_block;
    blocks[1] = T_block;
    blocks[2] = Z_block;
    blocks[3] = I_block;
end

reg [5:0] block = 6'b111010; // L block initial

function [5:0] rotate_L_block;
    input [5:0] block;
	 if (block == L_block) begin
		rotate_L_block = LR_block;
	 end else begin
		rotate_L_block = L_block;
	 end
endfunction

function [5:0] rotate_T_block;
    input [5:0] block;
    if (block == T_block) begin
		rotate_T_block = TR_block;
	 end else begin
		rotate_T_block = T_block;
	 end
endfunction

function [5:0] rotate_Z_block;
    input [5:0] block;
    if (block == Z_block) begin
		rotate_Z_block = ZR_block;
	 end else begin
		rotate_Z_block = Z_block;
	 end
endfunction

function [5:0] rotate_I_block;
    input [5:0] block;
    if (block == I_block) begin
		rotate_I_block = IR_block;
	 end else begin
		rotate_I_block = I_block;
	 end
endfunction

always @(posedge clk) clk25<=~clk25;
hvsync test(
 .clk(clk25), .reset(0),
 .data_enable(display_on), .hsync(MTL2_HSD),
 .vsync(MTL2_VSD), .hpos(hpos),
 .vpos(vpos)
);

wire data_enable = ((hpos <= `LINE && hpos >= 0) && (vpos <= `SCREEN && vpos >= 0));
localparam block_size = 50;

reg[11:0] block_hpos = `H_INIT;
reg[11:0] block_vpos = `V_INIT;
reg [31:0] delay_counter = 0; // Initialize a delay counter

// score initialization
integer score = 0;
integer idx;
integer d;

always @(negedge MTL2_VSD) 
begin

 delay_counter <= delay_counter + 1; // Increment the delay counter on each clock cycle

 if(delay_counter == 40) begin // Adjust this value to change the speed of the ball
		delay_counter <= 0;

	if (block_hpos < 12'd666) begin
		block_hpos = block_hpos + 12'd50;
	end

	if(GPIO_0[5] && block_vpos <= 12'd320) begin
	   block_vpos = block_vpos + 12'd50;
	end
	if(GPIO_0[6] && block_vpos > 12'd16)
	begin
		block_vpos = block_vpos - 12'd50;
	end
	
	if (!GPIO_0[7]) begin
        // Rotate the block based on the current block index
        case(current_block_index)
            0: block <= rotate_L_block(block);
            1: block <= rotate_T_block(block);
            2: block <= rotate_Z_block(block);
            3: block <= rotate_I_block(block);
            default: block <= block; // No rotation for unknown block
        endcase
		  score = score + 1; 
		  if (score == 10) begin
		  score = 0;
		  end
		  d = d + 1;
		  if(d == 10) begin
		  d = 0;
		  end
    end
	if (has_collision(block_hpos, block_vpos + block_size, block)) begin
		// Block has landed, handle collision
		for (i = 0; i < 3; i = i + 1) begin
			for (j = 0; j < 2; j = j + 1) begin
				index = (block_hpos + j * block_size)/block_size + ((block_vpos + i * block_size)/block_size) * BOARD_WIDTH;
					if (block[i*2 + j]) begin game_board[index] <= 1;
					end
			end
		end
      // Prepare for next block
      current_block_index <= (current_block_index + 1) % 4;
      block <= blocks[current_block_index];
      block_hpos <= `H_INIT;
      block_vpos <= `V_INIT;
   end
end
	if (!GPIO_0[8]) begin
        // Reset the game
        // Clear the game board
        for (idx = 0; idx < BOARD_SIZE; idx = idx + 1) begin
            game_board[idx] <= 0;
        end

        // Reset game state
        score = 0;
        block_hpos = `H_INIT;  // Ensure this is the correct top position
        block_vpos = `V_INIT;  // Ensure this is the correct top position
        if (d == 0) begin
		  block <= L_block; end
		  else if (d == 1) begin
		  block <= T_block; end
		  else if (d == 2) begin
		  block <= Z_block; end
		  else if (d == 3) begin
		  block <= I_block; end
		  else if (d == 4) begin
		  block <= L_block; end
		  else if (d == 5) begin
		  block <= Z_block; end
		  else if (d == 6) begin
		  block <= I_block; end
		  else if (d == 7) begin
		  block <= T_block; end
		  else if (d == 8) begin
		  block <= L_block; end
		  else if (d == 9) begin
		  block <= 6'b111111; end

        // Additional reset actions
        block_has_landed = 0;  // Reset any landing flags
	end
end

wire [11:0] hdif = hpos - block_hpos;
wire [11:0] vdif = vpos - block_vpos;
wire block_hgfx = hdif < block_size;
wire block_vgfx = vdif < block_size;
wire block_gfx = block_hgfx && block_vgfx;

integer x, y, cell_value;
reg block_has_landed = 0; // Flag to indicate if the block has landed
integer row_filled;


always @(posedge clk25)
begin 

 if(block_gfx && data_enable) begin
  red <= 8'h00;
  green <= 8'h00;  blue <= 8'h00;
 end
 else begin
  red<=8'd0;  green<=8'd0;
  blue<=8'd0; 
 end
 
 if (score == 0 && ( 
 	(hpos >= 34 && hpos <= 114) && ((vpos >= 35 && vpos <= 55) || (vpos >= 75 && vpos <= 95)) ||
	(vpos >= 55 && vpos <= 75) && ((hpos >= 34 && hpos <= 54) || (hpos >= 94 && hpos <= 114)) 
	)
 ) 
 begin
	red <= 8'h00;
	green <= 8'hee;
	blue <= 8'h00;	// display 0 	
 end 
 else if (score == 1 && ((vpos >= 35 && vpos <= 55) && (hpos >= 34 && hpos <= 114))) 
 begin
	red <= 8'h00;
	green <= 8'hee;
	blue <= 8'h00; // display 1
 end 
 else if (score == 2 && (
	(hpos >= 34 && hpos <= 54) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 34 && hpos <= 84) && (vpos >= 35 && vpos <= 55) ||
	(hpos >= 64 && hpos <= 84) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 64 && hpos <= 114) && (vpos >= 75 && vpos <= 95) ||
	(hpos >= 94 && hpos <= 114) && (vpos >= 35 && vpos <= 95))
 ) 
 begin
	red <= 8'h00;
	green <= 8'hee;
	blue <= 8'h00; // display 2
 end 
 else if (score == 3 && (
	(hpos >= 34 && hpos <= 54) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 34 && hpos <= 114) && (vpos >= 35 && vpos <= 55) || 
	(hpos >= 64 && hpos <= 84) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 94 && hpos <= 114) && (vpos >= 35 && vpos <= 95))
 ) 
 begin
	red <= 8'h00;
	green <= 8'hee;
	blue <= 8'h00; // display 3
 end 
 else if (score == 4 && (
	(hpos >= 34 && hpos <= 114) && (vpos >= 35 && vpos <= 55) ||
	(hpos >= 34 && hpos <= 74) && (vpos >= 75 && vpos <= 95) ||
	(hpos >= 54 && hpos <= 74) && (vpos >= 35 && vpos <= 95) )
 ) 
 begin
	red <= 8'h00;
	green <= 8'hee;
	blue <= 8'h00; // display 4
 end 
 else if (score == 5 && (
	(hpos >= 94 && hpos <= 114) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 34 && hpos <= 44) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 34 && hpos <= 74) && (vpos >= 75 && vpos <= 95) ||
	(hpos >= 64 && hpos <= 74) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 64 && hpos <= 114) && (vpos >= 35 && vpos <= 55))
 ) 
 begin
	red <= 8'h00;
	green <= 8'hee;
	blue <= 8'h00; // display 5
 end 
 else if (score == 6 && (
	(hpos >= 34 && hpos <= 114) && (vpos >= 75 && vpos <= 95) ||
	(hpos >= 34 && hpos <= 54) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 74 && hpos <= 84) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 104 && hpos <= 114) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 74 && hpos <= 114) && (vpos >= 35 && vpos <= 55) )
 ) 
 begin
	red <= 8'h00;
	green <= 8'hee;
	blue <= 8'h00; // display 6
 end 
 else if (score == 7 && (
	(hpos >= 34 && hpos <= 114) && (vpos >= 35 && vpos <= 55) ||
	(hpos >= 34 && hpos <= 54) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 34 && hpos <= 54) && (vpos >= 75 && vpos <= 95) )
 ) 
 begin
	red <= 8'h00;
	green <= 8'hee;
	blue <= 8'h00; // display 7
 end 
 else if (score == 8 && (
	(hpos >= 34 && hpos <= 114) && (vpos >= 35 && vpos <= 55) || 
	(hpos >= 34 && hpos <= 44) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 34 && hpos <= 114) && (vpos >= 75 && vpos <= 95) || 
	(hpos >= 64 && hpos <= 84) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 104 && hpos <= 114) && (vpos >= 35 && vpos <= 95) )	
 ) 
 begin
	red <= 8'h00;
	green <= 8'hee;
	blue <= 8'h00; // display 8
 end 
 else if (score == 9 && (
	(hpos >= 34 && hpos <= 114) && (vpos >= 35 && vpos <= 55) ||
	(hpos >= 34 && hpos <= 44) && (vpos >= 35 && vpos <= 95) ||
	(hpos >= 34 && hpos <= 74) && (vpos >= 75 && vpos <= 95) ||
	(hpos >= 64 && hpos <= 74) && (vpos >= 35 && vpos <= 95) )
 ) 
 begin
	red <= 8'h00;
	green <= 8'hee;
	blue <= 8'h00; // display 9
 end

 if(hpos >= `BORDER_HBOTTOM || hpos >= 0 && hpos < `BORDER_HTOP || 
 hpos > `BORDER_HMID_TOP && hpos < `BORDER_HMID_BOTTOM || vpos < `BORDER_VRIGHT || vpos > `BORDER_VLEFT)
 begin // border
    red <= 8'hff;
    green <= 8'hee;
    blue <= 8'hff;
 end
	
	if (has_collision(block_hpos, block_vpos, block)) begin
    // Handle collision
    for (i = 0; i < 3; i = i + 1) begin
      for (j = 0; j < 2; j = j + 1) begin
        index = (block_hpos + j * block_size)/block_size + ((block_vpos + i * block_size)/block_size) * BOARD_WIDTH;
        if (block[i*2 + j]) begin
          game_board[index] <= 1;
        end
      end
    end
    
	 // Switch to the next block
    current_block_index <= current_block_index + 1;
    if (current_block_index == 4) begin
      current_block_index <= 0;
    end
    
    block <= blocks[current_block_index];
    
    // Reset the block position to the initial position
    block_hpos <= `H_INIT;
    block_vpos <= `V_INIT;
	 
	 for (i = 464 - block_size; i >= 15; i = i - block_size) begin // Iterate over rows from the bottom
    row_filled = 1;
    for (j = 0; j < 13; j = j + 1) begin // Iterate over columns
        if (!game_board[j + i/block_size * BOARD_WIDTH]) begin
            row_filled = 0;
            break;
        end
    end
    if (row_filled) begin
			score <= score + 1;
        // Move rows above down
        for (k = i - block_size; k >= 15; k = k - block_size) begin
            for (j = 0; j < 13; j = j + 1) begin
                game_board[j + (k + block_size)/block_size * BOARD_WIDTH] <= game_board[j + k/block_size * BOARD_WIDTH];
            end
        end
        
        // Clear the filled row at the top
        for (j = 0; j < 13; j = j + 1) begin
            game_board[j + 15/block_size * BOARD_WIDTH] <= 0;
        end
    end 
	 end
  end
	
for (i = 0; i < 3; i = i + 1) begin
    for (j = 0; j < 2; j = j + 1) begin
        cell_value = block[i*2 + j];
        x = block_hpos + j * block_size;
        y = block_vpos + i * block_size;
        
        // Check if the pixel is within the block cell
        if (hpos >= x && hpos < x + block_size && vpos >= y && vpos < y + block_size) begin
            if(cell_value == 1) begin
                // This pixel should be lit
                red <= 8'hee;
                green <= 8'h00;
                blue <= 8'h00;
        end
    end
end

end  
end

assign MTL2_DCLK=clk25;
assign MTL2_R=red;
assign MTL2_G=green;
assign MTL2_B=blue;
endmodule