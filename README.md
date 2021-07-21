# Discord Bot Web App

Has a leaderboard web app, and API endpoints for choosing fair teams and reporting match results.

https://ratings.fortressone.org/

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

To change result of match with id 333 to red win:
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
