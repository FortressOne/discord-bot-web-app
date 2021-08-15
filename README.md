# Discord Bot Web App

Has a leaderboard web app, and API endpoints for choosing fair teams and reporting match results.

http://ratings.fortressone.org/

Hosted on Heroku.

To run app locally:
```
bundle exec rails server
```

To access production console:
- Log into heroku.
- Run:
		```
		bundle exec rails console -e production
		```

To deploy:
```
git push heroku master
```

To change result of match with id 333 to blue win:
```
match = Match.find(333)
blue = match.teams.first
blue.result = 1
blue.save
red = match.teams.last
red.result = -1
red.save
```

To recalculate all ratings from the beginning of time:
```
heroku run bundle exec rake ratings:build
```

To dump production data and import locally:
```
heroku pg:backups:capture
heroku pg:backups:download
pg_restore --verbose --clean --no-acl --no-owner -h localhost -U $USER -d discord_bot_web_app_development latest.dump
```
