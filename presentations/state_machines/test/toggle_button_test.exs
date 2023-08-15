defmodule ToggleButtonTest do
  use ExUnit.Case, async: true

  describe "Toggle buttons can be toggled on and off" do
    setup [:start_toggle_button_state_machine]

    test "pushing the button once turns it on", %{pid: pid} do
      assert ToggleButton.push(pid) == "Turning on"
    end

    test "pushing the button twice leaves turned off", %{pid: pid} do
      ToggleButton.push(pid)
      assert ToggleButton.push(pid) == "Turning off"
    end
  end

  defp start_toggle_button_state_machine(_context) do
    pid =
      start_link_supervised!(%{
        id: ToggleButton,
        start: {ToggleButton, :start_link, []}
      })

    %{pid: pid}
  end
end
