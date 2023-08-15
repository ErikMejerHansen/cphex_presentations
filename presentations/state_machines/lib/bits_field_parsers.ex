defmodule BitsFieldParsers do
  @moduledoc false

  def parse_version_field(<<version::3>>) do
    version
  end

  def parse_type_field(<<field_type::3>>) do
    case field_type do
      0 -> :sum
      1 -> :product
      2 -> :min
      3 -> :max
      4 -> :literal
      5 -> :greater_than
      6 -> :less_than
      7 -> :equals
    end
  end

  def parse_sub_packet_length_type(<<0::1>>),
    do: :bit_length

  def parse_sub_packet_length_type(<<1::1>>),
    do: :sub_packet_count

  def parse_sub_packet_length_type_11(<<length::11>>), do: length
end
