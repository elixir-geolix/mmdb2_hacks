defmodule MMDB2Hacks.MixProject do
  use Mix.Project

  def project do
    [
      app: :mmdb2_hacks,
      version: "0.1.0-dev",
      elixir: "~> 1.10",
      deps: deps()
    ]
  end

  def application, do: []

  defp deps do
    [
      {:mmdb2_decoder, "~> 2.0"}
    ]
  end
end
