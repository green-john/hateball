defmodule Hateball.Repo do
  use Ecto.Repo,
    otp_app: :hateball,
    adapter: Ecto.Adapters.Postgres
end
