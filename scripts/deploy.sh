mix deps.get --only prod
MIX_ENV=prod mix compile
npm run deploy --prefix ./assets
mix phx.digest

PORT=4001 MIX_ENV=prod mix phx.server

