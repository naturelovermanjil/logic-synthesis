-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 08
-- Project    : 
-------------------------------------------------------------------------------
-- File       : audio_codec_model.vhd
-- Author     : Group 27: Tomas Rinne & Manjil Basnet
-- Company    : TUT/DCS
-- Created    : 2008-11-28
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: DA7212 audio codec model for Slave left justified mode
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-03-11  1.0      Group 27    Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.all;

-- Define entity for the audio codec model
entity audio_codec_model is
  generic (
    data_width_g : integer := 16
    );
  port (
    rst_n           : in  std_logic;
    aud_data_in     : in  std_logic;
    aud_bclk_in     : in  std_logic;
    aud_lrclk_in    : in  std_logic;
    value_left_out  : out std_logic_vector(data_width_g-1 downto 0);
    value_right_out : out std_logic_vector(data_width_g-1 downto 0)
    );
end entity;

architecture rtl of audio_codec_model is

  -- Define custom state type for the state machine
  type state_type is (wait_for_input, read_left, read_right);

  signal current_state : state_type;

  -- Define internal signals for storing the left and right channel values
  signal left_value  : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
  signal right_value : std_logic_vector(data_width_g-1 downto 0) := (others => '0');

  signal aud_blck_last     : std_logic := '0';
  signal aud_lrclk_in_last : std_logic := '0';
  -- Counter
  signal bit_counter       : integer;

begin
  -- Synchronous process for state machine that models the audio process
  model_process : process(aud_bclk_in, rst_n, aud_lrclk_in, aud_blck_last, current_state, bit_counter, aud_data_in, aud_lrclk_in_last, left_value, right_value)
  begin
    aud_blck_last <= aud_bclk_in;
    if (rst_n = '0') then
      -- Reset state machine and output values
      current_state   <= wait_for_input;
      left_value      <= (others => '0');
      right_value     <= (others => '0');
      value_left_out  <= (others => '0');
      value_right_out <= (others => '0');
      bit_counter     <= data_width_g - 2;
    elsif (aud_blck_last = '0' and aud_bclk_in = '1') then  -- Rising edge
      -- Update state machine based on LR clock
      aud_lrclk_in_last <= aud_lrclk_in;
      case current_state is
        when wait_for_input =>
          if (aud_lrclk_in_last = '0' and aud_lrclk_in = '1') then
            current_state <= read_left;
            left_value    <= (data_width_g - 1 => aud_data_in, others => '0');  -- read data transition bit
          else
            current_state <= wait_for_input;
          end if;
        when read_left =>
          bit_counter <= bit_counter - 1;
          if (aud_lrclk_in_last = '1' and aud_lrclk_in = '0') then
            right_value    <= (data_width_g - 1 => aud_data_in, others => '0');  -- read data transition bit
            value_left_out <= left_value;    -- Data read finished
            current_state  <= read_right;
            bit_counter    <= data_width_g - 2;
          else
            left_value(bit_counter) <= aud_data_in;
          end if;
        when read_right =>
          bit_counter <= bit_counter - 1;
          if (aud_lrclk_in_last = '0' and aud_lrclk_in = '1') then
            left_value      <= (data_width_g - 1 => aud_data_in, others => '0');  -- read data transition bit
            value_right_out <= right_value;  -- Data read finished
            current_state   <= read_left;
            bit_counter     <= data_width_g - 2;
          else
            right_value(bit_counter) <= aud_data_in;
          end if;
      end case;
    end if;
  end process;

end architecture;
