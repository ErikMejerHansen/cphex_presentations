defmodule ToggleButton do
  @behaviour :gen_statem

  def start_link do
    :gen_statem.start_link(__MODULE__, [], [])
  end

  @impl :gen_statem
  def init(_opts) do
    {:ok, :off, []}
  end

  @impl :gen_statem
  def callback_mode(), do: :state_functions

  def push(pid), do: :gen_statem.call(pid, :push)

  def on({:call, from}, :push, data),
    do: {:next_state, :off, data, [{:reply, from, "Turning off"}]}

  def off({:call, from}, :push, data),
    do: {:next_state, :on, data, [{:reply, from, "Turning on"}]}
end
