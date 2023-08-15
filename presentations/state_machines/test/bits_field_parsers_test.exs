defmodule StateMachinesTest do
  use ExUnit.Case, async: true

  test "it can parse the version field" do
    assert BitsFieldParsers.parse_version_field(<<1::1, 1::1, 0::1>>) == 6
  end

  test "it can parse the type field into atoms" do
    assert BitsFieldParsers.parse_type_field(<<0::1, 0::1, 0::1>>) == :sum
    assert BitsFieldParsers.parse_type_field(<<0::1, 0::1, 1::1>>) == :product
    assert BitsFieldParsers.parse_type_field(<<0::1, 1::1, 0::1>>) == :min
    assert BitsFieldParsers.parse_type_field(<<0::1, 1::1, 1::1>>) == :max
    assert BitsFieldParsers.parse_type_field(<<1::1, 0::1, 0::1>>) == :literal
    assert BitsFieldParsers.parse_type_field(<<1::1, 0::1, 1::1>>) == :greater_than
    assert BitsFieldParsers.parse_type_field(<<1::1, 1::1, 0::1>>) == :less_than
    assert BitsFieldParsers.parse_type_field(<<1::1, 1::1, 1::1>>) == :equals
  end

  test "it can parse sub-packets length indicator type 15" do
    assert BitsFieldParsers.parse_sub_packet_length_type(<<0::1>>) ==
             :bit_length
  end

  test "it can parse sub-packets length indicator type 11" do
    assert BitsFieldParsers.parse_sub_packet_length_type(<<1::1>>) ==
             :sub_packet_count
  end

  test "it can parse sub-packets length of length type 11" do
    assert BitsFieldParsers.parse_sub_packet_length_type_11(<<0b10000000001::11>>) ==
             1025
  end
end
