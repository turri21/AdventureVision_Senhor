//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_MIX = 0;

assign LED_USER = 0;
assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

// Status Bit Map: (0..31 => "O", 32..63 => "o")
// 0         1         2         3          4         5         6
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// XXXXXXX XX

`include "build_id.v" 
localparam CONF_STR = {
	"AVision;;",
	"-;",
	"F1,BIN,Load Game;",
	"-;",
	"O89,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O46,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"O23,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"-;",
	"O1,Simulate Mirror,Off,On;",
	"O7,Custom Palette,Off,On;",
	"D0FC3,GBP,Load Palette;",
	"-;",
	"R0,Reset;",
	"J1,1,2,3,4;",
	"jn,X,A,B,Y;",
	"jp,X,A,B,Y;;",
	"V,v",`BUILD_DATE 
};

wire forced_scandoubler;
wire  [1:0] buttons;
wire [31:0] status;
wire [10:0] ps2_key;

wire        ioctl_download;
wire [24:0] ioctl_addr;
wire [7:0]  ioctl_dout;
wire        ioctl_wait;
wire        ioctl_wr;
wire  [7:0] ioctl_index;

wire [15:0] joystick0, joystick1;
wire [21:0] gamma_bus;

assign ioctl_wait = 0;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(gamma_bus),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wait(ioctl_wait),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick0),
	.joystick_1(joystick1),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask(~status[7]),
	
	.ps2_key(ps2_key)
);

wire cart_download = (ioctl_index[5:0] == 0 || ioctl_index[5:0] == 1) && ioctl_download;
wire palette_download = (ioctl_index[5:0] == 3) && ioctl_download;

///////////////////////   CLOCKS   ///////////////////////////////

wire clk_sys, clk_vid;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_vid)
);

wire reset = RESET | status[0] | buttons[1] | cart_download;

//////////////////////////////////////////////////////////////////

wire HBlank;
wire VBlank;

wire [1:0] av_audio;
wire [39:0] av_led_n;
wire av_disp_photo_int;
wire por_n;
wire [11:0] av_bus_a;
wire [7:0] av_cart_dout;
wire av_cart_select;
wire hsync_n, vsync_n;
wire [2:0] Red;

// av_audio(1) : volume 0 = high, 1 = low
// av_audio(0) : digital sound waveform
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;
assign AUDIO_L = {av_audio[0], (av_audio[1] ? 8'd0 : 12'd0)};

// Physical button layout
//   1          1
// 2   4  JS  4   2
//   3          3
// I'll assume the right buttons are considered primary

wire joy_up     = ~joystick0[3] & ~joystick1[3];
wire joy_down   = ~joystick0[2] & ~joystick1[2];
wire joy_left   = ~joystick0[1] & ~joystick1[1];
wire joy_right  = ~joystick0[0] & ~joystick1[0];

wire [7:0] vdd8_s = 8'hFF; // Simulate a pulled up expansion bus

av_machine AdventureVision
(
	//-- System Interface -------------------------------------------------------
	.clk_11m_i         (clk_sys),                               //: in  std_logic;
	.reset_n_i         (~reset),                                //: in  std_logic;
	.por_n_o           (por_n),                                 //: out std_logic;
	//-- Cartridge Interface ----------------------------------------------------
	.cart_a_o          (av_bus_a),                              //: out std_logic_vector(11 downto 0);
	.cart_oe_n_o       (av_cart_select),                        //: out std_logic;
	.cart_d_i          (av_cart_dout),                          //: in  std_logic_vector( 7 downto 0);
	//-- Buttons and Stick Interface --------------------------------------------
	.but_1_n_i         (~joystick0[4] & ~joystick1[4]),         //: in  std_logic;
	.but_2_n_i         (~joystick0[5] & ~joystick1[5]),         //: in  std_logic;
	.but_3_n_i         (~joystick0[6] & ~joystick1[6]),         //: in  std_logic;
	.but_4_n_i         (~joystick0[7] & ~joystick1[7]),         //: in  std_logic;
	.stick_l_n_i       (joy_left),                              //: in  std_logic;
	.stick_r_n_i       (joy_right),                             //: in  std_logic;
	.stick_u_n_i       (joy_up),                                //: in  std_logic;
	.stick_d_n_i       (joy_down),                              //: in  std_logic;
	//-- Sound Interface --------------------------------------------------------
	.audio_o           (av_audio),                              //: out std_logic_vector( 1 downto 0);
	//-- Display Interface ------------------------------------------------------
	.led_n_o           (av_led_n),                              //: out std_logic_vector(39 downto 0);
	.disp_p24_n_o      (),                                      //: out std_logic;
	.disp_photo_int_o  (av_disp_photo_int),                     //: out std_logic;
	//-- Expansion Interface ----------------------------------------------------
	.exp_t0_i          (vdd8_s),                                //: in  std_logic;
	.exp_t0_o          (),                                      //: out std_logic;
	.exp_t0_dir_o      (),                                      //: out std_logic;
	.exp_rd_n_o        (),                                      //: out std_logic;
	.exp_psen_n_o      (),                                      //: out std_logic;
	.exp_wr_n_o        (),                                      //: out std_logic;
	.exp_ale_o         (),                                      //: out std_logic;
	.exp_d_i           (vdd8_s),                                //: in  std_logic_vector( 7 downto 0);
	.exp_d_o           (),                                      //: out std_logic_vector( 7 downto 0);
	.exp_p1_i          (vdd8_s),                                //: in  std_logic_vector( 7 downto 3);
	.exp_p1_o          (),                                      //: out std_logic_vector( 7 downto 3);
	.exp_p1_low_imp_o  (),                                      //: out std_logic;
	.exp_p2_i          (vdd8_s),                                //: in  std_logic_vector( 3 downto 0);
	.exp_p2_o          (),                                      //: out std_logic_vector( 3 downto 0);
	.exp_p2l_low_imp_o (),                                      //: out std_logic;
	.exp_p2h_low_imp_o (),                                      //: out std_logic;
	.exp_prog_n_o      ()                                       //: out std_logic
);

av_video #(.is_pal_g(0)) av_video
(
	.clk_11m_i         (clk_sys),
	.por_n_i           (por_n),
	.disp_photo_int_i  (av_disp_photo_int),
	.led_n_i           (av_led_n),
	.rgb_r_o           (Red),
	.rgb_hsync_n_o     (hsync_n),
	.rgb_vsync_n_o     (vsync_n),
	.rgb_csync_n_o     (),
	.hblank            (HBlank),
	.vblank            (VBlank),
	.fixed_intensity   (~status[1])
);

dpram #(.addr_width_g(12)) cart_ram
(
	.clk_b_i           (clk_sys),
	.addr_b_i          (av_bus_a),
	.data_b_o          (av_cart_dout),
	
	.clk_a_i           (clk_sys),
	.addr_a_i          (ioctl_addr),
	.data_a_i          (ioctl_dout),
	.we_i              (ioctl_wr && cart_download)
);

reg [127:0] palette = 128'h828214517356305A5F1A3B4900000000;

always @(posedge clk_sys) begin
	if (palette_download & ioctl_wr) begin
			palette[127:0] <= {palette[119:0], ioctl_dout[7:0]};
	end
end

wire [23:0] color_fg = {palette[127:104]};
wire [23:0] color_bg = {palette[55:32]};

wire [2:0] scale = status[6:4];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;
wire HSync = ~hsync_n;
wire VSync = ~vsync_n;

typedef struct packed {
	logic [7:0] Red;
	logic VBlank;
	logic VSync;
	logic HBlank;
	logic HSync;
	logic ce_pix;
} video_t;

video_t [3:0] vid_pipe;

wire vid_de;

wire [7:0] r_pal, g_pal, b_pal;

wire use_pal = status[7];

assign r_pal = vid_de ? (use_pal ? (|vid_pipe[3].Red ? color_fg[23:16] : color_bg[23:16]) : vid_pipe[3].Red) : 8'd0;
assign g_pal = vid_de ? (use_pal ? (|vid_pipe[3].Red ? color_fg[15:8] : color_bg[15:8]) : 8'd0) : 8'd0;
assign b_pal = vid_de ? (use_pal ? (|vid_pipe[3].Red ? color_fg[7:0] : color_bg[7:0]) : 8'd0) : 8'd0;

video_mixer #(.LINE_LENGTH(450),.GAMMA(1),.HALF_DEPTH(0)) video_mixer
(
	.CLK_VIDEO              (CLK_VIDEO),            // should be multiple by (ce_pix*4)
	.CE_PIXEL               (CE_PIXEL),             // output pixel clock enable
	.ce_pix                 (vid_pipe[3].ce_pix),   // input pixel clock or clock_enable
	.scandoubler            (scale || forced_scandoubler),
	.hq2x                   (scale == 1),           // high quality 2x scaling
	.gamma_bus              (gamma_bus),
	.R                      (r_pal),
	.G                      (g_pal),
	.B                      (b_pal),
	.HSync                  (vid_pipe[3].HSync),
	.VSync                  (vid_pipe[3].VSync),
	.HBlank                 (vid_pipe[3].HBlank),
	.VBlank                 (vid_pipe[3].VBlank),
	.HDMI_FREEZE            (),
	.freeze_sync            (),
	.VGA_R                  (VGA_R),
	.VGA_G                  (VGA_G),
	.VGA_B                  (VGA_B),
	.VGA_VS                 (VGA_VS),
	.VGA_HS                 (VGA_HS),
	.VGA_DE                 (vid_de)
);

wire [1:0] ar = status[9:8];

video_freak video_freak
(
	.CLK_VIDEO              (CLK_VIDEO),
	.CE_PIXEL               (CE_PIXEL),
	.VGA_VS                 (VGA_VS),
	.HDMI_WIDTH             (HDMI_HEIGHT),
	.HDMI_HEIGHT            (HDMI_WIDTH),
	.VGA_DE                 (VGA_DE),
	.VIDEO_ARX              (VIDEO_ARX),
	.VIDEO_ARY              (VIDEO_ARY),
	.VGA_DE_IN              (vid_de),
	.ARX                    ((!ar) ? 12'd1387 : (ar - 1'd1)),
	.ARY                    ((!ar) ? 12'd962 : 12'd0),
	.CROP_SIZE              (10'd0),
	.CROP_OFF               (0),
	.SCALE                  (status[3:2])
);

reg [1:0] pix_div;

always @(posedge clk_vid) begin
	pix_div <= pix_div + 1'd1;

	vid_pipe[0].Red <= {Red, Red, Red[2:1]};
	vid_pipe[0].HSync <= HSync;
	vid_pipe[0].VSync <= VSync;
	vid_pipe[0].HBlank <= HBlank;
	vid_pipe[0].VBlank <= VBlank;
	vid_pipe[0].ce_pix <= &pix_div;

	vid_pipe[3:1] <= vid_pipe[2:0];
end

assign CLK_VIDEO = clk_vid;
assign VGA_SL = sl[1:0];

endmodule
