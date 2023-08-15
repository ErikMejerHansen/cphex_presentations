defmodule WaitForAttachmentsStateMachine do
  @behaviour :gen_statem

  @impl :gen_statem
  def init(_args) do
    {:ok, :idle, %{}}
  end

  @impl :gen_statem
  def callback_mode(), do: :state_functions

  def idle({:call, from}, {:attach_source, stream}, data) do
    new_data = Map.put(data, :source, stream)

    {:next_state, :waiting_for_sink, new_data, [{:reply, from, {:waiting, "Waiting for sink"}}]}
  end

  def idle({:call, from}, {:attach_sink, pid}, data) do
    new_data = Map.put(data, :sink, pid)

    {:next_state, :waiting_for_source, new_data,
     [{:reply, from, {:waiting, "Waiting for source"}}]}
  end

  def waiting_for_source({:call, from}, {:attach_source, source}, data) do
    new_data = Map.put(data, :source, source)

    handle_ready(from, new_data)
  end

  def waiting_for_sink({:call, from}, {:attach_sink, pid}, data) do
    new_data = Map.put(data, :sink, pid)

    handle_ready(from, new_data)
  end

  defp handle_ready(from, data) do
    {:next_state, :ready, data,
     [
       # Switch state machines
       {:change_callback_module, BitsPackageParserStateMachine},
       # Send an event to get the next state machine running
       {:next_event, :internal, :start_parsing},
       # Reply
       {:reply, from, {:ok, "Ready"}}
     ]}
  end
end
