#mix deps.get --only prod
#MIX_ENV=prod mix compile
#npm run deploy --prefix ./assets
#mix phx.digest

scp -r * mysrv:/opt/web/hateball
