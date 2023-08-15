defmodule BitsParser do
  def start_link() do
    :gen_statem.start_link(WaitForAttachmentsStateMachine, [], [])
  end

  def attach_source(pid, stream) do
    :gen_statem.call(pid, {:attach_source, stream})
  end

  def attach_sink(pid, sink) do
    :gen_statem.call(pid, {:attach_sink, sink})
  end
end
