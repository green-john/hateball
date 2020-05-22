mix deps.get --only prod
mix compile
npm run deploy --prefix ./assets
mix phx.digest

# Run using
# PORT=4001 MIX_ENV=prod mix phx.server

