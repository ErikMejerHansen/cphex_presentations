defmodule BitsParserTest do
  use ExUnit.Case, async: true

  describe "Bits Protocol Parser" do
    setup [:start_bits_parser, :setup_sample_data_input_stream]

    test "a parsed package is returned", %{pid: pid, stream: stream} do
      # Using the test process as the sink
      {:waiting, "Waiting for source"} = BitsParser.attach_sink(pid, self())
      {:ok, "Ready"} = BitsParser.attach_source(pid, stream)

      # Use assert_receive to assert that BitsParser sent us a parsed packet.
      assert_receive {:package, %{version: 7, type: :max, sub_packet_count: 3}}
    end
  end

  defp start_bits_parser(_context) do
    pid =
      start_link_supervised!(%{
        id: BitsParser,
        start: {BitsParser, :start_link, []}
      })

    %{pid: pid}
  end

  defp setup_sample_data_input_stream(_context) do
    # Example grabbed directly from the Stream.resource docs
    stream =
      Stream.resource(
        fn ->
          {:ok, pid} = StringIO.open("11101110000000001101010000001100100000100011000001100000")
          pid
        end,
        fn pid ->
          case IO.getn(pid, "", 1) do
            :eof -> {:halt, pid}
            # Really horrible way of turning the char into a one-bit bitstring
            # Open to suggestions 😂
            char -> {[<<char |> Integer.parse(2) |> elem(0)::1>>], pid}
          end
        end,
        fn pid -> StringIO.close(pid) end
      )

    %{stream: stream}
  end
end
