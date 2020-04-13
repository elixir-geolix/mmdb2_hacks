defmodule MMDB2Hacks do
  @moduledoc false

  use Bitwise, only_operators: true

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
        offset
        |> MMDB2Decoder.lookup_pointer!(data)
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

  @doc """
  Extract all pointers referenced in the lookup tree.
  """
  @spec tree_pointers(Path.t()) :: [non_neg_integer]
  def tree_pointers(database_path) do
    {:ok, meta, tree, _data} =
      database_path
      |> File.read!()
      |> MMDB2Decoder.parse_database()

    tree
    |> tree_pointers_extract(meta, [])
    |> Enum.uniq()
    |> Enum.map(&(&1 - meta.node_count - 16))
  end

  defp tree_pointers_extract("", _, pointers), do: pointers

  defp tree_pointers_extract(
         tree,
         %{node_count: node_count, record_size: record_size} = meta,
         pointers
       ) do
    record_half = rem(record_size, 8)
    record_left = record_size - record_half

    <<left_low::size(record_left), left_high::size(record_half), pointer_right::size(record_size),
      rest::binary>> = tree

    pointer_left = left_low + (left_high <<< record_left)

    pointers =
      if pointer_left > node_count do
        [pointer_left | pointers]
      else
        pointers
      end

    pointers =
      if pointer_right > node_count do
        [pointer_right | pointers]
      else
        pointers
      end

    tree_pointers_extract(rest, meta, pointers)
  end
end
