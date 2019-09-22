defmodule MMDB2Hacks do
  @moduledoc false

  @decode_options [double_precision: nil, float_precision: nil, map_keys: :strings]

  @doc """
  Extract all countries from a database.
  """
  @spec countries(Path.t()) :: [map]
  def countries(database_path) do
    {:ok, _meta, _tree, data} =
      database_path
      |> File.read!()
      |> MMDB2Decoder.parse_database()

    Range.new(0, byte_size(data) - 1)
    |> Enum.map(fn offset ->
      try do
        data
        |> MMDB2Decoder.Data.value(offset, @decode_options)
        |> Map.take(["geoname_id", "iso_code", "names"])
      rescue
        _ -> nil
      end
    end)
    |> Enum.filter(
      &(is_map(&1) && Map.has_key?(&1, "geoname_id") && Map.has_key?(&1, "iso_code") &&
          Map.has_key?(&1, "names"))
    )
    |> Enum.uniq_by(&Map.get(&1, "geoname_id"))
  end
end
