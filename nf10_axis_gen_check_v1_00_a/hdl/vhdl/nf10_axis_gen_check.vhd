------------------------------------------------------------------------------
--
--  NetFPGA-10G http://www.netfpga.org
--
--  File:
--        nf10_axis_gen_check.vhd
--
--  Library:
--        hw/std/pcores/nf10_axis_gen_check_v1_00_a
--
--  Author:
--        Michaela Blott
--
--  Description:
--                Hardware component that generates and checks packets.
--        Currently the generator generates bit-wise shifted pattern. No valid
--        packet pattern and/or higher layer structure is programmed.
--
--  Copyright notice:
--        Copyright (C) 2010, 2011 Xilinx, Inc.
--
--  Licence:
--        This file is part of the NetFPGA 10G development base package.
--
--        This file is free code: you can redistribute it and/or modify it under
--        the terms of the GNU Lesser General Public License version 2.1 as
--        published by the Free Software Foundation.
--
--        This package is distributed in the hope that it will be useful, but
--        WITHOUT ANY WARRANTY; without even the implied warranty of
--        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--        Lesser General Public License for more details.
--
--        You should have received a copy of the GNU Lesser General Public
--        License along with the NetFPGA source package.  If not, see
--        http://www.gnu.org/licenses/.
--
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity nf10_axis_gen_check is
generic (
   C_BASEADDR          : std_logic_vector(31 downto 0) := x"00000000";
   C_HIGHADDR          : std_logic_vector(31 downto 0) := x"00000002";
   C_M_AXIS_DATA_WIDTH : integer := 64; -- max 256bit supported
   C_S_AXIS_DATA_WIDTH : integer := 64; -- max 256bit supported
   C_S_AXIS_TUSER_WIDTH  	   : integer := 128;
   C_M_AXIS_TUSER_WIDTH  	   : integer := 128;
   C_GEN_PKT_SIZE      : integer := 16; -- in words;
   C_CHECK_PKT_SIZE    : integer := 16; -- in words;
   C_IFG_SIZE          : integer := 5;  -- in words irrespective of backpressure
   C_S_AXI_ADDR_WIDTH  : integer := 32;
   C_S_AXI_DATA_WIDTH  : integer := 32
);
port (
   ACLK               : in  std_logic;
   ARESETN            : in  std_logic;
   -- axi streaming data interface
   M_AXIS_TDATA       : out std_logic_vector (C_M_AXIS_DATA_WIDTH-1 downto 0);
   M_AXIS_TSTRB       : out std_logic_vector (C_M_AXIS_DATA_WIDTH/8-1 downto 0);
   M_AXIS_TUSER       : out std_logic_vector (C_M_AXIS_TUSER_WIDTH-1 downto 0);
   M_AXIS_TVALID      : out std_logic;
   M_AXIS_TREADY      : in  std_logic;
   M_AXIS_TLAST       : out std_logic;
   S_AXIS_TDATA       : in  std_logic_vector (C_S_AXIS_DATA_WIDTH-1 downto 0);
   S_AXIS_TSTRB       : in  std_logic_vector (C_S_AXIS_DATA_WIDTH/8-1 downto 0);
   S_AXIS_TUSER       : in  std_logic_vector (C_S_AXIS_TUSER_WIDTH-1 downto 0);
   S_AXIS_TVALID      : in  std_logic;
   S_AXIS_TREADY      : out std_logic;
   S_AXIS_TLAST       : in  std_logic;
   -- axi lite control/status interface
   S_AXI_ACLK         : in  std_logic;
   S_AXI_ARESETN      : in  std_logic;
   S_AXI_AWADDR       : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
   S_AXI_AWVALID      : in  std_logic;
   S_AXI_AWREADY      : out std_logic;
   S_AXI_WDATA        : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
   S_AXI_WSTRB        : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
   S_AXI_WVALID       : in  std_logic;
   S_AXI_WREADY       : out std_logic;
   S_AXI_BRESP        : out std_logic_vector(1 downto 0);
   S_AXI_BVALID       : out std_logic;
   S_AXI_BREADY       : in  std_logic;
   S_AXI_ARADDR       : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
   S_AXI_ARVALID      : in  std_logic;
   S_AXI_ARREADY      : out std_logic;
   S_AXI_RDATA        : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
   S_AXI_RRESP        : out std_logic_vector(1 downto 0);
   S_AXI_RVALID       : out std_logic;
   S_AXI_RREADY       : in  std_logic;
	LED03 : out std_logic;
	CS_M_AXIS_TDATA0    :out std_logic;
	CS_M_AXIS_TDATA1    :out std_logic;
	CS_M_AXIS_TDATA2    :out std_logic;
	CS_M_AXIS_TDATA3    :out std_logic;
	CS_M_AXIS_TDATA4    :out std_logic;
	CS_M_AXIS_TDATA5    :out std_logic;
	CS_M_AXIS_TDATA6    :out std_logic;
	CS_M_AXIS_TDATA7    :out std_logic;
	CS_M_AXIS_TDATA8    :out std_logic;
	CS_M_AXIS_TDATA9    :out std_logic;
	CS_M_AXIS_TDATA10   :out std_logic;
	CS_M_AXIS_TDATA11   :out std_logic;
	CS_M_AXIS_TDATA12   :out std_logic;
	CS_M_AXIS_TDATA13   :out std_logic;
	CS_M_AXIS_TDATA14   :out std_logic;
	CS_M_AXIS_TDATA15   :out std_logic; 
	CS_M_AXIS_TDATA16   :out std_logic;
	CS_M_AXIS_TDATA17   :out std_logic;
	CS_M_AXIS_TDATA18   :out std_logic;
	CS_M_AXIS_TDATA19   :out std_logic;
	CS_M_AXIS_TDATA20   :out std_logic;
	CS_M_AXIS_TDATA21   :out std_logic;
	CS_M_AXIS_TDATA22   :out std_logic;
	CS_M_AXIS_TDATA23   :out std_logic;
	CS_M_AXIS_TDATA24   :out std_logic;
	CS_M_AXIS_TDATA25   :out std_logic;
	CS_M_AXIS_TDATA26   :out std_logic;
	CS_M_AXIS_TDATA27   :out std_logic;
	CS_M_AXIS_TDATA28   :out std_logic;
	CS_M_AXIS_TDATA29   :out std_logic;
	CS_M_AXIS_TDATA30   :out std_logic;
	CS_M_AXIS_TDATA31   :out std_logic ; 
	CS_M_AXIS_TDATA32   :out std_logic;
	CS_M_AXIS_TDATA33   :out std_logic;
	CS_M_AXIS_TDATA34   :out std_logic;
	CS_M_AXIS_TDATA35   :out std_logic;
	CS_M_AXIS_TDATA36   :out std_logic;
	CS_M_AXIS_TDATA37   :out std_logic;
	CS_M_AXIS_TDATA38   :out std_logic;
	CS_M_AXIS_TDATA39   :out std_logic;
	CS_M_AXIS_TDATA40   :out std_logic;
	CS_M_AXIS_TDATA41   :out std_logic;
	CS_M_AXIS_TDATA42   :out std_logic;
	CS_M_AXIS_TDATA43   :out std_logic;
	CS_M_AXIS_TDATA44   :out std_logic;
	CS_M_AXIS_TDATA45   :out std_logic;
	CS_M_AXIS_TDATA46   :out std_logic;
	CS_M_AXIS_TDATA47   :out std_logic ; 
	CS_M_AXIS_TDATA48   :out std_logic;
	CS_M_AXIS_TDATA49   :out std_logic;
	CS_M_AXIS_TDATA50   :out std_logic;
	CS_M_AXIS_TDATA51   :out std_logic;
	CS_M_AXIS_TDATA52   :out std_logic;
	CS_M_AXIS_TDATA53   :out std_logic;
	CS_M_AXIS_TDATA54   :out std_logic;
	CS_M_AXIS_TDATA55   :out std_logic;
	CS_M_AXIS_TDATA56   :out std_logic;
	CS_M_AXIS_TDATA57   :out std_logic;
	CS_M_AXIS_TDATA58   :out std_logic;
	CS_M_AXIS_TDATA59   :out std_logic;
	CS_M_AXIS_TDATA60   :out std_logic;
	CS_M_AXIS_TDATA61   :out std_logic;
	CS_M_AXIS_TDATA62   :out std_logic;
	CS_M_AXIS_TDATA63   :out std_logic  
);
end entity;



architecture structural of nf10_axis_gen_check is

component axi4_lite_regs
generic (
   ADDR_WIDTH  : integer := 32;
   DATA_WIDTH  : integer := 32
);
port (
   tx_count     : in std_logic_vector(31 downto 0);
   rx_count     : in std_logic_vector(31 downto 0);
   err_count    : in std_logic_vector(31 downto 0);
   count_reset  : out std_logic;
   AXIS_ACLK    : in std_logic;

   -- axi lite control/status interface
   ACLK         : in  std_logic;
   ARESETN      : in  std_logic;
   AWADDR       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
   AWVALID      : in  std_logic;
   AWREADY      : out std_logic;
   WDATA        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
   WSTRB        : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0);
   WVALID       : in  std_logic;
   WREADY       : out std_logic;
   BRESP        : out std_logic_vector(1 downto 0);
   BVALID       : out std_logic;
   BREADY       : in  std_logic;
   ARADDR       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
   ARVALID      : in  std_logic;
   ARREADY      : out std_logic;
   RDATA        : out std_logic_vector(DATA_WIDTH-1 downto 0);
   RRESP        : out std_logic_vector(1 downto 0);
   RVALID       : out std_logic;
   RREADY       : in  std_logic
);
end component;


   -- ROM should be inferred as BRAM during XST
   constant CHECK_IDLE           : std_logic_vector(1 downto 0) := "00";
   constant CHECK_FINISH         : std_logic_vector(1 downto 0) := "01";
   constant CHECK_COMPARE        : std_logic_vector(1 downto 0) := "11";
   constant CHECK_WAIT_LAST      : std_logic_vector(1 downto 0) := "10";

   constant GEN_PKT              : std_logic_vector(1 downto 0) := "00";
   constant GEN_IFG              : std_logic_vector(1 downto 0) := "01";
   constant GEN_FINISH           : std_logic_vector(1 downto 0) := "11";

   signal gen_word_num       : std_logic_vector(15 downto 0);
   signal gen_state          : std_logic_vector(1  downto 0);
   signal check_state        : std_logic_vector(1  downto 0);
   signal check_word_num     : std_logic_vector(15 downto 0);
   signal tx_count           : std_logic_vector(31 downto 0);
   signal rx_count           : std_logic_vector(31 downto 0);
   signal err_count          : std_logic_vector(31 downto 0);
   signal count_reset        : std_logic;
   signal ok                 : std_logic;
   signal pkt_tx_buf         : std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
   signal pkt_rx_buf         : std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
   signal seed               : std_logic_vector(255 downto 0);

	signal ledcnt : unsigned (19 downto 0);
	signal led_reg : std_logic := '0';
begin

   seed <= x"CAFEBEEFCAFEBEEFCAFEBEEFCAFEBEEFCAFEBEEFCAFEBEEFCAFEBEEFCAFEBEEF";

   regs : axi4_lite_regs
     generic map
        (
        ADDR_WIDTH       => C_S_AXI_ADDR_WIDTH,
        DATA_WIDTH       => C_S_AXI_DATA_WIDTH
        )

     port map
        (
        tx_count  => tx_count,
        rx_count  => rx_count,
        err_count => err_count,
        count_reset => count_reset,
        AXIS_ACLK => ACLK,

        ACLK => S_AXI_ACLK,
        ARESETN => S_AXI_ARESETN,
        AWADDR => S_AXI_AWADDR,
        AWVALID => S_AXI_AWVALID,
        AWREADY => S_AXI_AWREADY,
        WDATA => S_AXI_WDATA,
        WSTRB => S_AXI_WSTRB,
        WVALID => S_AXI_WVALID,
        WREADY => S_AXI_WREADY,
        BRESP => S_AXI_BRESP,
        BVALID => S_AXI_BVALID,
        BREADY => S_AXI_BREADY,
        ARADDR => S_AXI_ARADDR,
        ARVALID => S_AXI_ARVALID,
        ARREADY => S_AXI_ARREADY,
        RDATA => S_AXI_RDATA,
        RRESP => S_AXI_RRESP,
        RVALID => S_AXI_RVALID,
        RREADY => S_AXI_RREADY
        );


M_AXIS_TLAST <= '1' when (gen_word_num = C_GEN_PKT_SIZE - 1) else '0';
M_AXIS_TUSER <= (others => '0'); -- Dummy TUSER

gen_p: process(ACLK, ARESETN)
begin
   if (ARESETN='0') then
      M_AXIS_TSTRB <= (others => '0');
      M_AXIS_TVALID <= '0';
      gen_word_num <= (others => '0');
      tx_count <= (others => '0');
      gen_state <= GEN_IFG; -- initiate to between frames
   elsif (ACLK = '1' and ACLK'event) then
      if gen_state = GEN_PKT then
		 M_AXIS_TSTRB <= (others => '1');
         M_AXIS_TVALID <= '1';
         if (M_AXIS_TREADY='1') then
            gen_word_num <= gen_word_num + 1;
            if (gen_word_num = C_GEN_PKT_SIZE - 1) then
                M_AXIS_TSTRB <= (others => '0');
         		M_AXIS_TVALID <= '0';
         		tx_count <= tx_count + 1;
         		gen_state <= GEN_IFG;
            else
                pkt_tx_buf <= pkt_tx_buf(0) & pkt_tx_buf(C_M_AXIS_DATA_WIDTH -1 downto 1);
                M_AXIS_TDATA <= pkt_tx_buf(0) & pkt_tx_buf(C_M_AXIS_DATA_WIDTH -1 downto 1);
            end if;
         end if;
      elsif gen_state = GEN_IFG then
         M_AXIS_TSTRB <= (others => '0');
         M_AXIS_TVALID <= '0';
         if (M_AXIS_TREADY='1') then
             gen_word_num <= gen_word_num + 1;
             if gen_word_num = C_GEN_PKT_SIZE+C_IFG_SIZE-1 then
                 if(count_reset = '1') then
          			gen_state <= GEN_IFG; -- Hold state at GEN_IFG gently...
          			tx_count <= (others => '0');
          		 else
          		    gen_state <= GEN_FINISH;
      			 end if;
             end if;
         end if;
      elsif gen_state = GEN_FINISH then
         M_AXIS_TSTRB <= (others => '1');
         M_AXIS_TVALID <= '1';
         M_AXIS_TDATA <= seed(C_M_AXIS_DATA_WIDTH -1 downto 0);
         pkt_tx_buf <= seed(C_M_AXIS_DATA_WIDTH -1 downto 0);
         gen_word_num <= (others => '0');
         gen_state <= GEN_PKT;
      end if;
   end if;
	CS_M_AXIS_TDATA63 <= pkt_tx_buf(63) ;
	CS_M_AXIS_TDATA62 <= pkt_tx_buf(62) ;
	CS_M_AXIS_TDATA61 <= pkt_tx_buf(61) ;
	CS_M_AXIS_TDATA60 <= pkt_tx_buf(60) ;
	CS_M_AXIS_TDATA59 <= pkt_tx_buf(59) ;
	CS_M_AXIS_TDATA58 <= pkt_tx_buf(58) ;
	CS_M_AXIS_TDATA57 <= pkt_tx_buf(57) ;
	CS_M_AXIS_TDATA56 <= pkt_tx_buf(56) ;
	CS_M_AXIS_TDATA55 <= pkt_tx_buf(55) ;
	CS_M_AXIS_TDATA54 <= pkt_tx_buf(54) ;
	CS_M_AXIS_TDATA53 <= pkt_tx_buf(53) ;
	CS_M_AXIS_TDATA52 <= pkt_tx_buf(52) ;
	CS_M_AXIS_TDATA51 <= pkt_tx_buf(51) ;
	CS_M_AXIS_TDATA50 <= pkt_tx_buf(50) ;
	CS_M_AXIS_TDATA49 <= pkt_tx_buf(49) ;
	CS_M_AXIS_TDATA48 <= pkt_tx_buf(48) ;
	CS_M_AXIS_TDATA47 <= pkt_tx_buf(47) ;
	CS_M_AXIS_TDATA46 <= pkt_tx_buf(46) ;
	CS_M_AXIS_TDATA45 <= pkt_tx_buf(45) ;
	CS_M_AXIS_TDATA44 <= pkt_tx_buf(44) ;
	CS_M_AXIS_TDATA43 <= pkt_tx_buf(43) ;
	CS_M_AXIS_TDATA42 <= pkt_tx_buf(42) ;
	CS_M_AXIS_TDATA41 <= pkt_tx_buf(41) ;
	CS_M_AXIS_TDATA40 <= pkt_tx_buf(40) ;
	CS_M_AXIS_TDATA39 <= pkt_tx_buf(39) ;
	CS_M_AXIS_TDATA38 <= pkt_tx_buf(38) ;
	CS_M_AXIS_TDATA37 <= pkt_tx_buf(37) ;
	CS_M_AXIS_TDATA36 <= pkt_tx_buf(36) ;
	CS_M_AXIS_TDATA35 <= pkt_tx_buf(35) ;
	CS_M_AXIS_TDATA34 <= pkt_tx_buf(34) ;
	CS_M_AXIS_TDATA33 <= pkt_tx_buf(33) ;
	CS_M_AXIS_TDATA32 <= pkt_tx_buf(32) ;
	CS_M_AXIS_TDATA31 <= pkt_tx_buf(31) ;
	CS_M_AXIS_TDATA30 <= pkt_tx_buf(30) ;
	CS_M_AXIS_TDATA29 <= pkt_tx_buf(29) ;
	CS_M_AXIS_TDATA28 <= pkt_tx_buf(28) ;
	CS_M_AXIS_TDATA27 <= pkt_tx_buf(27) ;
	CS_M_AXIS_TDATA26 <= pkt_tx_buf(26) ;
	CS_M_AXIS_TDATA25 <= pkt_tx_buf(25) ;
	CS_M_AXIS_TDATA24 <= pkt_tx_buf(24) ;
	CS_M_AXIS_TDATA23 <= pkt_tx_buf(23) ;
	CS_M_AXIS_TDATA22 <= pkt_tx_buf(22) ;
	CS_M_AXIS_TDATA21 <= pkt_tx_buf(21) ;
	CS_M_AXIS_TDATA20 <= pkt_tx_buf(20) ;
	CS_M_AXIS_TDATA19 <= pkt_tx_buf(19) ;
	CS_M_AXIS_TDATA18 <= pkt_tx_buf(18) ;
	CS_M_AXIS_TDATA17 <= pkt_tx_buf(17) ;
	CS_M_AXIS_TDATA16 <= pkt_tx_buf(16) ;
	CS_M_AXIS_TDATA15 <= pkt_tx_buf(15) ;
	CS_M_AXIS_TDATA14 <= pkt_tx_buf(14) ;
	CS_M_AXIS_TDATA13 <= pkt_tx_buf(13) ;
	CS_M_AXIS_TDATA12 <= pkt_tx_buf(12) ;
	CS_M_AXIS_TDATA11 <= pkt_tx_buf(11) ;
	CS_M_AXIS_TDATA10 <= pkt_tx_buf(10) ;
	CS_M_AXIS_TDATA9  <= pkt_tx_buf(9) ;
	CS_M_AXIS_TDATA8  <= pkt_tx_buf(8) ;
	CS_M_AXIS_TDATA7  <= pkt_tx_buf(7) ;
	CS_M_AXIS_TDATA6  <= pkt_tx_buf(6) ;
	CS_M_AXIS_TDATA5  <= pkt_tx_buf(5) ;
	CS_M_AXIS_TDATA4  <= pkt_tx_buf(4) ;
	CS_M_AXIS_TDATA3  <= pkt_tx_buf(3) ;
	CS_M_AXIS_TDATA2  <= pkt_tx_buf(2) ;
	CS_M_AXIS_TDATA1  <= pkt_tx_buf(1) ;
	CS_M_AXIS_TDATA0  <= pkt_tx_buf(0) ;
end process;

S_AXIS_TREADY <= '1';
check_p: process(ACLK, ARESETN)
begin
   if (ARESETN='0') then
        check_state <= (others => '0');
        rx_count <= (others => '0');
        err_count <= (others => '0');
        ok <= '1';
		check_word_num <= (others => '0');
   elsif (ACLK = '1' and ACLK'event) then
      if check_state = CHECK_IDLE then
         -- waiting for a pkt
         if S_AXIS_TVALID = '1' then
            ok <= '1';
            pkt_rx_buf <= S_AXIS_TDATA(0) & S_AXIS_TDATA(C_S_AXIS_DATA_WIDTH -1 downto 1);
            check_word_num <= (others => '0');
            check_state <= CHECK_COMPARE;
         end if;
      elsif check_state = CHECK_COMPARE then
		 -- checking the packet
         -- check packet size and last
         if (S_AXIS_TVALID = '1') then
             pkt_rx_buf <= pkt_rx_buf(0) & pkt_rx_buf(C_S_AXIS_DATA_WIDTH -1 downto 1);
             check_word_num <= check_word_num + 1;

             if( S_AXIS_TDATA = pkt_rx_buf ) then
                 ok <= ok;
             else
                 ok <= '0';
             end if;
		     if (check_word_num = C_CHECK_PKT_SIZE -2) then
		          if (S_AXIS_TLAST='1') then
		              check_state <= CHECK_FINISH; -- finish up
		          else
		              ok <= '0';
		              check_state <= CHECK_WAIT_LAST; -- Wait for last
		          end if;
             end if;
		 end if;
      elsif check_state = CHECK_FINISH then
         -- finish up
         if (ok='1') then
			rx_count <= rx_count + 1;
		 else
			err_count <= err_count + 1;
		 end if;
		 check_state <= CHECK_IDLE;
		 ok <='1';
      elsif check_state = CHECK_WAIT_LAST then
         -- Wait for last
	     if (S_AXIS_TLAST='1' and S_AXIS_TVALID = '1') then
		    check_state <= CHECK_FINISH;
		 end if;
      end if;

      if(count_reset = '1') then -- Don't touch check state machine..
          rx_count <= (others => '0');
          err_count <= (others => '0');
      end if;
   end if;
end process;

process (ACLK)
begin
  if rising_edge(ACLK) then
    if ARESETN = '0' then
	   ledcnt <= (others => '0');
		led_reg <= '0';
	 else
	    if ledcnt = 4191 then
		   ledcnt <= (others => '0');
		   led_reg <= not led_reg;
	    else
		   ledcnt <= ledcnt +1;
		 end if;
	  end if;
  end if;
end process;

LED03 <= led_reg;

end structural;
