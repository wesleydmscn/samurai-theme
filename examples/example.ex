defmodule Shop.Product do
  @enforce_keys [:id, :name, :price, :stock]
  defstruct [:id, :name, :price, :stock]

  @type t :: %__MODULE__{
    id:    String.t(),
    name:  String.t(),
    price: float(),
    stock: non_neg_integer()
  }

  def new(id, name, price, stock) do
    %__MODULE__{id: id, name: name, price: price, stock: stock}
  end
end

defmodule Shop.Cart do
  alias Shop.Product

  @type item  :: %{product: Product.t(), qty: pos_integer()}
  @type t     :: %{items: %{String.t() => item()}}

  def new, do: %{items: %{}}

  def add(%{items: items} = cart, %Product{} = product, qty \\ 1) do
    updated = Map.update(items, product.id,
      %{product: product, qty: qty},
      fn item -> %{item | qty: item.qty + qty} end
    )
    %{cart | items: updated}
  end

  def remove(%{items: items} = cart, product_id) do
    %{cart | items: Map.delete(items, product_id)}
  end

  def subtotal(%{items: items}) do
    Enum.reduce(items, 0.0, fn {_, %{product: p, qty: q}}, acc ->
      acc + p.price * q
    end)
  end

  def total(cart, discount_fn \\ &Function.identity/1) do
    cart |> subtotal() |> discount_fn.()
  end
end

defmodule Shop.Discount do
  def percentage(rate) do
    fn price -> Float.round(price * (1 - rate / 100), 2) end
  end

  def fixed(amount) do
    fn price -> max(0.0, price - amount) end
  end

  def best_of(price, strategies) do
    strategies
    |> Enum.map(& &1.(price))
    |> Enum.min()
  end
end

defmodule Shop.Repository do
  def new, do: %{}

  def save(repo, key, entity), do: Map.put(repo, key, entity)

  def find(repo, key), do: Map.fetch(repo, key)

  def find!(repo, key) do
    case Map.fetch(repo, key) do
      {:ok, entity} -> entity
      :error        -> raise KeyError, "Not found: #{key}"
    end
  end

  def all(repo), do: Map.values(repo)
end

defmodule Shop.Math do
  def fibonacci(n) do
    Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
    |> Enum.take(n)
  end

  def sieve(limit) do
    flags = for i <- 0..limit, into: %{}, do: {i, i >= 2}

    Enum.reduce(2..floor(:math.sqrt(limit)), flags, fn i, acc ->
      if acc[i] do
        Enum.reduce(Stream.iterate(i * i, &(&1 + i)), acc, fn j, a ->
          if j > limit, do: throw(:done), else: Map.put(a, j, false)
        end)
      else
        acc
      end
    end)
    |> Enum.filter(fn {_, v} -> v end)
    |> Enum.map(fn {k, _} -> k end)
    |> Enum.sort()
  catch
    :done -> []
  end
end

defmodule Shop do
  alias Shop.{Cart, Discount, Math, Product, Repository}

  def run do
    repo =
      Repository.new()
      |> Repository.save("1", Product.new("1", "Laptop",   999.99, 10))
      |> Repository.save("2", Product.new("2", "Mouse",     29.99, 50))
      |> Repository.save("3", Product.new("3", "Keyboard",  79.99, 30))

    cart =
      Cart.new()
      |> Cart.add(Repository.find!(repo, "1"), 1)
      |> Cart.add(Repository.find!(repo, "2"), 2)

    discount = Discount.percentage(10)

    IO.puts("Subtotal:   $#{:erlang.float_to_binary(Cart.subtotal(cart), decimals: 2)}")
    IO.puts("After 10%: $#{:erlang.float_to_binary(Cart.total(cart, discount), decimals: 2)}")

    affordable =
      repo
      |> Repository.all()
      |> Enum.filter(&(&1.price < 100))
      |> Enum.sort_by(& &1.price)
      |> Enum.map(& &1.name)

    IO.puts("Affordable: #{Enum.join(affordable, ", ")}")
    IO.puts("Fibonacci(8): #{inspect(Math.fibonacci(8))}")

    with {:ok, mouse} <- Repository.find(repo, "2") do
      IO.puts("Found: #{mouse.name}")
    end
  end
end

Shop.run()
