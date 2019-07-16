# Robinhood Yolo
[![Build Status](https://travis-ci.org/edmundpf/robinhood_yolo.svg?branch=master)](https://travis-ci.org/edmundpf/robinhood_yolo)
[![npm version](https://badge.fury.io/js/robinhood-yolo.svg)](https://badge.fury.io/js/robinhood-yolo)
> Robinhood Options API written in Coffeescript and console CLI w/ included stop_loss, account history, positions watch, etc. ☕
## Install
* `npm i -g robinhood-yolo`
## Usage
``` bash
$ yolo -h
```
## Setup
* Add account
	``` bash
	$ yolo -c add_account
	```
	* Requires username, password, and device token
		* To retrieve device token, log into a browser and run the following command
			``` javascript
			x=document.getElementsByTagName('script');for(i of x){y=i.innerText.match(/(?<=clientId: ").[^"]+/);if(y!=null){console.log(y[0])}}
			```
			* The output will be your device token, save this
		* Enter your credentials in the prompt
	* Confirm account is added
		``` bash
		$ yolo -c show_accounts
		```
## CLI Commands
![CLI Help](https://i.imgur.com/1musfQe.jpg "CLI Help")
* Use flag *-c* to enter a command
* Use additional flags for command arguments
* Examples
	* **dashboard**
		* Shows robinhood dashboard
		``` bash
		$ yolo -c dashboard
		```
	* **trades**
		* Shows profits/losses from all trades
		``` bash
		$ yolo -c trades
		```
	* **watch**
		* Watch current positions with statistics/metrics
		``` bash
		$ yolo -c watch
		```
	* **stop_loss**
		* Enable adaptive stop loss on open positions. 
			* **NOTE:** this can prevent gains or could cause poor fills if used too close to market open, warnings are put in place to prevent this, but please use at own risk
			* Stops max loss after 20% loss on option price
			* If option is between 10%-20% gains, stop loss will preserve gains and will sell if price drops to $0.01 over original buy price
			* If option is greater than 20% gains, stop loss will sell after a 20% loss from the *high* price after the option was purchased
		``` bash
		$ yolo -c stop_loss
		```
	* **quote**
		* Get quote for stock symbol
		``` bash
		$ yolo -c quote --ticker TSLA
		```
	* **position**
		* Show details on open positions and unfilled orders
		``` bash
		$ yolo -c positions
		```
	* **find**
		* Find option contracts
		* Find single contract
			* To find a TSLA call expiring 2019-07-19 that is the current 2nd out of the money option (depth is 0-based)
			```bash
			$ yolo -c find --ticker TSLA --expiry 2019-07-19 --option_type call --strike_type otm --depth 1
			```
		* Find range of contracts
			* To find the current 3 otm and 3 itm call options expiring 2019-07-19 (6 total)
			```bash
			$ yolo -c find --ticker TSLA --expiry 2019-07-19 --option_type call --range 3
			```
	* **buy**
		* Buy option
		``` bash
		$ yolo -c buy --url OPTION_URL_HERE --quantity X_CONTRACTS_HERE --price X_PRICE_PER_CONTRACT_HERE
		```
	* **sell**
		* Sell option
		``` bash
		$ yolo -c sell --url OPTION_URL_HERE --quantity X_CONTRACTS_HERE --price X_PRICE_PER_CONTRACT_HERE
		```
	* **replace**
		``` bash
		$ yolo -c replace --id ORDER_ID_HERE --quantity X_CONTRACTS_HERE --price X_PRICE_PER_CONTRACT_HERE
		```
		* *order id* can be found with the *position* command. Replaceable orders will be listed under *Unfilled Orders*
	* **cancel**
		``` bash
		$ yolo -c cancel --url CANCEL_URL_HERE
		```
		* *cancel url* can be found with the *position* command. Cancelable orders will be listed under *Unfilled Orders*
	* **show_accounts**
		* Shows accounts in config
		``` bash
		$ yolo -c show_accounts
		```
	* **add_account**
		* Adds account to config
		``` bash
		$ yolo -c add_account
		```
	* **edit_account**
		* Edits account in config
		``` bash
		$ yolo -c edit_account
		```
	* **delete_account**
		* Deletes account from config
		``` bash
		$ yolo -c delete_account
		```
## API
* **TO-DO:** API Usage
