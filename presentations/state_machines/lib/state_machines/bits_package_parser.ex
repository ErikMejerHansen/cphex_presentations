defmodule BitsPackageParserStateMachine do
  @behaviour :gen_statem

  # Does not actually get called when you set module as callback module
  # on an already running StateMachine
  @impl :gen_statem
  def init(_args) do
    {:ok, :ready, nil}
  end

  @impl :gen_statem
  def callback_mode(), do: :state_functions

  # This is the state we hit with the "hand over" event
  def ready(:internal, :start_parsing, data) do
    # First part of packet is the version field. Use action to push us to that state.
    {:next_state, :parse_version, data, [{:next_event, :internal, :continue_parse}]}
  end

  def parse_version(:internal, _, data) do
    # Grab three bits from the Stream
    # StreamSplit is super need for when you need to read trough a strem
    {[bit1, bit2, bit3], tail} = StreamSplit.take_and_drop(data.source, 3)

    version_parsed =
      BitsFieldParsers.parse_version_field(<<bit1::bitstring, bit2::bitstring, bit3::bitstring>>)

    updated_data =
      data
      # Update the state with the "forwareded" stream
      |> Map.put(:source, tail)
      # Start building the new packet
      |> Map.put(:current_packet, %{version: version_parsed})

    # Next step is parsing the packet type
    {:next_state, :parse_type, updated_data, [{:next_event, :internal, :continue_parse}]}
  end

  def parse_type(:internal, _, data) do
    # Type is three bits
    {[bit1, bit2, bit3], tail} = StreamSplit.take_and_drop(data.source, 3)

    type_parsed =
      BitsFieldParsers.parse_type_field(<<bit1::bitstring, bit2::bitstring, bit3::bitstring>>)

    updated_data =
      data
      # Remember to send the "forwarded" stream forward
      |> Map.put(:source, tail)
      # Update the current packet
      |> put_in([:current_packet, :type], type_parsed)

    case type_parsed do
      :literal ->
        raise "we'll handle these later"

      _ ->
        # Next we need to figure out which lenght type this packet has
        {:next_state, :parse_length_type, updated_data,
         [{:next_event, :internal, :continue_parse}]}
    end
  end

  def parse_length_type(:internal, _, data) do
    # Length indicator is just one bit
    {[bit1], tail} = StreamSplit.take_and_drop(data.source, 1)

    length_type = BitsFieldParsers.parse_sub_packet_length_type(bit1)

    updated_data =
      data
      # Remember to send the "forwarded" stream forward
      |> Map.put(:source, tail)

    # Select the next state based on which lenght type we're looking at
    case length_type do
      :bit_length ->
        {:next_state, :parse_length_type_15, updated_data,
         [{:next_event, :internal, :continue_parse}]}

      :sub_packet_count ->
        {:next_state, :parse_length_type_11, updated_data,
         [{:next_event, :internal, :continue_parse}]}
    end
  end

  def parse_length_type_11(:internal, _, data) do
    {[bit1, bit2, bit3, bit4, bit5, bit6, bit7, bit8, bit9, bit10, bit11], tail} =
      StreamSplit.take_and_drop(data.source, 11)

    # Yeah, this looks dumb... and proably is :)
    length =
      BitsFieldParsers.parse_sub_packet_length_type_11(<<
        bit1::bitstring,
        bit2::bitstring,
        bit3::bitstring,
        bit4::bitstring,
        bit5::bitstring,
        bit6::bitstring,
        bit7::bitstring,
        bit8::bitstring,
        bit9::bitstring,
        bit10::bitstring,
        bit11::bitstring
      >>)

    updated_data =
      data
      |> Map.put(:source, tail)
      |> put_in([:current_packet, :sub_packet_count], length)

    # Pretend that we're done and send the parsed packet downstream
    send(data.sink, {:package, updated_data.current_packet})

    # Transition to next state... but this is where we stop today
    {:keep_state_and_data, []}
  end

  def parse_length_type_15(:internal, _, _data) do
    raise "Not implemented"
  end
end
