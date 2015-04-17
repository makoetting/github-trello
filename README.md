#Overview
Allows you to append commit messages to Trello cards and move cards according to branching. Commit messages with cards referenced move cards to in progress. Cards merged into master can be moved to a merged and closed list. From there if a commit is merged into a staging branch, the Trello card will move to staging, and the same applies for a production branch.

##Commands
Commit messages are searched for `(start|card|close|fix)e?s? \D?([0-9]+)` to find the card short id. All commands will add the commit message to the card and move the card to in progress if the commit is on a branch other than master, staging, or production.

- Any commit message containing a permutation of `start`, `card`, `close`, `fix` followed by the Trello card will add the commit message to the card. Then, depending on the branch, the card will be moved to in progress, closed & merged, staging, or production.


```
git branch todo_124
```
git checkout todo_124
```
git commit -m 'Added a class to start 124'
```
This will move card #124 to the "in progress" list

```
git commit -m 'Added a few more tests card 124'
```
This will add a message to card #124 but nothing more (as it is already in "in progress")

```
pull request into master
```
This will move card #124 to the "closed & merged" list.
```
merge into staging
```
This will move card #124 to the "staging" list. Ideally, you will have a deploy hook configured to trigger an automatic deployment of the staging branch to your staging server
```
merge into production
```
This will move card #124 to the "production" list. Like staging, a deploy hook would ideall trigger an automatic depoloyment of the production branch to your production server



##Installation

###Gather config values
- **api_key** - Go to [https://trello.com/1/appKey/generate](https://trello.com/1/appKey/generate)
- **oauth_token** - Go to _https://trello.com/1/authorize?response_type=token&name=Trello+Github+Integration&scope=read,write&expiration=never&key=[your-key-here]_ replacing __[your-key-here]__ with the **api_key** from above. Authorize the request and record the token.
- **board_id** - You can get the board id from the URL, for example https://trello.com/board/trello-development/4d5ea62fd76aa1136000000c the board id is _4d5ea62fd76aa1136000000ca_.
- **…list_target_id** - These can be found by opening a card in the list, exporting it as json, and grabbing the "idList" value.

###Deploy to Warpspeed.io
Create a Ruby site on Warpspeed.io to run the github-trello code. Use the Nginx config to set the environmental variables according to the `passenger_env_var [variable] [value]` specification

- Environmental Variables:

	`api_key=[API_KEY]`
	`oauth_token=[OATH_TOKEN]` 
	`board_id=[BOARD_ID]` 
	`inprogress_list_target_id=[ID]` 
	`merged_list_target_id=[ID]` 
	`staging_list_target_id=[ID]`
	`production_list_target_id=[ID]`


###Set up GitHub
Simply add you your github-trello url + "/posthook-github" as a WebHook url under "Admin" for your repository. Example:

`http://github-trello.examplesite/posthook-github`