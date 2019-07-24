# Robinhood Yolo
[![Build Status](https://travis-ci.org/edmundpf/robinhood_yolo.svg?branch=master)](https://travis-ci.org/edmundpf/robinhood_yolo)
[![npm version](https://badge.fury.io/js/robinhood-yolo.svg)](https://badge.fury.io/js/robinhood-yolo)
> Robinhood Options API written in Coffeescript and console CLI w/ included stop-loss, account history, positions watch, etc. ☕

![CLI Help](https://i.imgur.com/1musfQe.jpg "CLI Help")
## Install
* To use the CLI
	* `npm i -g robinhood-yolo`
	* Updating
		* `npm i -g robinhood-yolo@latest`
* To use the API in your project
	* `npm i -S robinhood-yolo`
	* Updating
		* `npm i -S robinhood-yolo@latest`
## CLI Usage
``` bash
$ yolo -h
```
## Setup
* Add account
	``` bash
	$ yolo -c add_account
	```
	* Requires username, password, and device token
		* To retrieve device token, log into Robinhood in a browser and run the following command
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
		* Use **stop_loss_sim** command to get printouts **ONLY**, no orders will be placed
		``` bash
		# Stop Loss (places orders)
		$ yolo -c stop_loss
		# Stop Loss Simulation (printouts only, no orders placed)
		$ yolo -c stop_loss_sim
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
## API Usage
``` javascript
// Uses CLI local data, account(s) need to be added via CLI before first use then credentials persist
api = require('robinhood-yolo')()
// You can also manage your own data elsewhere and the API will not automatically persist data as follows
api = require('robinhood-yolo')({
	configData: {
		d_t: 'BASE64_ENCODED_DEVICE_TOKEN_HERE',
		u_n: 'BASE64_ENCODED_PASSWORD_HERE',
		p_w: 'BASE64_ENCODED_USERNAME_HERE',
		a_t: 'ROBINHOOD_ACCESS_TOKEN_HERE',
		r_t: 'ROBINHOOD_REFRESH_TOKEN_HERE',
		a_b: 'ROBINHOOD_BEARER_TOKEN_HERE',
		t_s: 'ROBINHOOD_LOGIN_TIMESTAMP_HERE'
	}
})
```
* Initialization
	``` javascript
	api = require('robinhood-yolo')({ newLogin: true, configIndex: 0, configData: null, print: true })
	```
	* Optional args
		* newLogin (boolean)
			* if true does new login request, else uses stored auth token for quicker login
		* configIndex (int)
			* user index in config file (for multi-user use, does not apply if configData is defined)
		* configData (object)
			* By default CLI stores account data with no dependencies, allowing users to login with no credentials after adding the account details 
			* If configData arg is null or undefined, credentials will need to be added before using API with `yolo -c add_account`
			* Else, configData expects object for login data as follows
				* d_t: Device token (Base64 encoded)
				* u_n: Username (Base64 encoded)
				* p_w: Password (Base64 encoded)
				* a_t: Robinhood access token
				* r_t: Robinhood refresh token
				* a_b: Robinhood bearer token
				* t_s: Login timestamp
	* Returns true if configData is null/undefined, else returns configData object with updated values
		* print (boolean)
			* If false, will skip optional print statements in functions, else will print all info
* *login()*
	``` javascript
	await api.login({ newLogin: true, configIndex: 0 })
	```
	* Logs user into Robinhood
	* Optional args
		* newLogin (boolean)
			* if true does new login request, else uses stored auth token for quicker login
		* configIndex (int)
			* user index in config file (for multi-user use)
		* Must be called before using login-only methods, overrides initialization args
* *getAccount()*
	``` javascript
	await api.getAccount()
	```
	* Gets account info
	* Returns dict
* *getTransfers()*
	``` javascript
	await api.getTransfers()
	```
	* Gets account bank transfers
	* Returns list
* *getMarketHours()*
	``` javascript
	await api.getMarketHours('2019-07-19')
	```
	* Gets Market Hours info for date
	* Required args
		* date (string)
* *getWatchList()*
	``` javascript
	await api.getWatchList({ watchList: 'Default', instrumentData: false, quoteData: false })
	```
	* Gets Watch List items
	* Optional args
		* watchList (string)
			* Watch list name
		* instrumentData (boolean)
			* if true includes instrument data
		* quoteData (boolean)
			* if true includes quote data
* *quotes()*
	``` javascript
	await api.quotes('TSLA')
	await api.quotes('TSLA', { chainData: false })
	```	
	* Gets quotes for single ticker or list of tickers
	* Returns dict for single ticker, list for list of tickers
	* Required args
		* ticker(s) (string || array)
	* Optional args
		* chainData (boolean)
			* If false does not include chain data, else includes chain data
* *historicals()*
	``` javascript
	await api.historicals('TSLA')
	await api.historicals('TSLA', { span: 'year', bounds: 'regular' })
	```		
	* Gets historical quotes for single ticker or list of tickers
	* Returns dict for single ticker, list for list of tickers
	* Required args
		* ticker(s) (string || array)
	* Optional args
		* span	(string)
			* time span (see src/endpoints.coffee for allowed interval/span combinations)
		* bounds (string)
* *getOptions()*
	``` javascript
	await api.getOptions('TSLA', '2019-07-19')
	await api.getOptions('TSLA', '2019-07-19', { optionType: 'call', marketData: false, expired: false })
	```
	* Gets list of available options for ticker
	* Returns list
	* Required args
		* symbol (string)
		* expirationDate (string)
	* Optional args
		* optionType (string)
			* *call* || *put*
		* marketData (boolean)
			* If false does not include market data, otherwise includes market data
		* expired (boolean)
			* if true includes expired options in search, else excludes expired options
* *findOptions()*
	``` javascript
	await api.findOptions('TSLA', '2019-07-19')
	await api.findOptions('TSLA', '2019-07-19', { optionType: 'call', strikeType: 'itm', strikeDepth: 0, marketData: false, range: null, strike: null, expired: false })
	```	
	* Finds options by args
	* Either returns a list of a range of options, or a single option dict
	* Required args
		* symbol (string)
		* expirationDate (string)	
	* Optional args
		* optionType (string)
			* *call* || *put*
		* marketData (boolean)
			* If false does not include market data, otherwise includes market data
		* strikeType (string)
			* *itm* || *otm*
		* strikeDepth (int)
			* strike price depth, 0-based
		* range (int)
			* if not null, will return list of range. For example, if range equals 3, 3 otm and 3 itm options will be returned
		* strike (Number)
			* if not null, will return option at exact strike price
		* expired (boolean)
			* if true includes expired options in search, else excludes expired options
* *findOptionsHistoricals()*
	``` javascript
	await api.findOptionsHistoricals('TSLA', '2019-07-19')
	await api.findOptionsHistoricals('TSLA', '2019-07-19', { optionType: 'call', strikeType: 'itm', strikeDepth: 0, strike: null, expired: true, span: 'month' })
	```	
	* Finds option historical data
	* Returns list of data
	* Required args
		* symbol (string)
		* expirationDate (string)	
	* Optional args
		* optionType (string)
			* *call* || *put*
		* strikeType (string)
			* *itm* || *otm*
		* strikeDepth (int)
			* strike price depth, 0-based
		* strike (Number)
			* if not null, will return option at exact strike price
		* expired (boolean)
			* if true includes expired options in search, else excludes expired options
		* span	(string)
			* time span (see src/endpoints.coffee for allowed interval/span combinations)
* *optionsPositions()*
	``` javascript
	await api.optionsPositions()
	await api.optionsPositions({ marketData: false, orderData: false, openOnly: true, notFilled: false })
	```
	* Gets list of options positions
	* Returns list
	* Optional args
		* marketData (boolean)
			* If false does not include market data, otherwise includes market data
		* orderData (boolean)
			* If false does not include order data, otherwise includes order data
		* openOnly (boolean)
			* If true includes open positions only, if false includes all positions
		* notFilled (boolean)
			* If true includes unfilled positions, if false excludes unfilled positions
* *optionsOrders()*
	``` javascript
	await api.optionsOrders()
	await api.optionsOrders({ urls: null, id: null, notFilled: false, buyOnly: false })
	```
	* Returns list of options orders
	* Optional args
		* urls (list)
			* If not null, gets orders from list of option order urls
		* id (string)
			* If not null, gets order by id
		* notFilled (boolean)
			* If true includes unfilled orders, if false excludes unfilled orders
		* buyOnly (boolean)
			* Only include buy orders if true, else include all
* *placeOptionOrder()*
	``` javascript
	await api.placeOptionOrder('OPTION_URL_HERE', 1.0, 0.53)
	await api.placeOptionOrder('OPTION_URL_HERE', 1.0, 0.53, { direction: 'debit', side: 'buy', positionEffect: 'open', legs: null })
	```
	* Places option order, returns order confirmation
	* Required args
		* option (string)
			* option url
		* quantity (int)
		* price (Number)
			* Price for one contract
	* Optional args
		* direction (string)
			* *debit* || *credit*
		* side (string)
			* *buy* || *sell*
		* positionEffect (string)
			* *open* || *close*
		* legs (array)
			* order legs, if not null, other args will be ignored and legs will be used instead
* *cancelOptionOrder()*
	``` javascript
	await api.cancelOptionOrder('CANCEL_URL_HERE')
	```
	* Cancels option order
	* Required args
		* cancelUrl (string)
* *replaceOptionOrder()*
	``` javascript
	await api.replaceOptionOrder(1.0, 0.53, { orderId: 'ORDER_ID_HERE' })
	```
	* Replaces option order
	* Required args
		* quantity (int)
		* price (Number)
			* Price for one contract
	* Optional args (must use *order* || *orderId*)
		* order (dict)
			* order object, information will be extracted from order object to replace order
		* orderId (string)
			* will get data from order id to replace order
## Contributing
* To contribute, please submit a pull request!
* If making changes to the API, run `npm run test` and confirm all tests are working
* Include tests for new methods in src/tests/test.coffee
* **NOTE:** If the method actually buys or sells anything, please add test logic to ensure testing is only allowed **AFTER** market close, do not allow tests before market open to ensure a queued order isn't accidentally filled. Please also ensure that the test ammounts are ridiculous bids/asks that could not possibly be filled anyways, I.E. a deep-itm AMZN option for $0.01.