# Trustly-client-ruby

This is an example implementation of communication with the Trustly API using Ruby. This a ruby gem that allows you use Trustly Api calls in ruby. It's based on [trustly-client-python] (https://github.com/trustly/trustly-client-python) and [turstly-client-php] (https://github.com/trustly/trustly-client-php)

It implements the standard Payments API as well as gives stubs for executing calls against the API used by the backoffice.

For full documentation on the Trustly API internals visit our developer website: http://trustly.com/developer . All information about software flows and call patters can be found on that site. The documentation within this code will only cover the code itself, not how you use the Trustly API.

This code is provided as-is, use it as inspiration, reference or drop it directly into your own project and use it.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trustly-client-ruby',:require=>'trustly'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install trustly-client-ruby

If you use rails, you can use this generator in order to let trustly find your certificates:

    $ rails g trustly:install

This will copy trustly public certificates under certs/trustly folder:
    
    certs/trustly/test.trustly.public.pem
    certs/trustly/live.trustly.public.pem

You will need to copy test and live private certificates using this naming convention (if you want Trustly to load them automatically but you can use different path and names):

    certs/trustly/test.merchant.private.pem
    certs/trustly/live.merchant.private.pem 

## Usage

Currently only **Deposit** and **Refund** api calls. However, other calls can be implemented very easily.

### Api

In order to use Trustly Api, we'll need to create a **Trustly::Api::Signed**. Example:

```ruby
api = Trustly::Api::Signed.new({
	:username=>"yourusername",
	:password=>"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
})
```

This will automatically load pem files from **certs/trustly** with default optons. If you want to specify other paths or options then you can call:

```ruby
api = Trustly::Api::Signed.new({
	 :username=>"yourusername",
	 :password=>"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    :host        => 'test.trustly.com',
    :port        => 443,
    :is_https    => true,
    :private_pem => "#{Rails.root}/certs/trustly/test.merchant.private.pem",
    :public_pem  => "#{Rails.root}/certs/trustly/test.trustly.public.pem"
})
```

### Deposit call

Deposit is straightfoward call. Only required arguments example:

```ruby
deposit = api.deposit({"EndUserID"=>10002,"MessageID"=>12349,"Amount"=>3})
```
Optional arguments are:

- Locale:  default value "es_ES"
- Country: default "ES"
- Currency default "EUR"
- SuggestedMinAmount
- SuggestedMaxAmount
- Amount
- Currency
- Country
- IP
- SuccessURL: default "https://www.trustly.com/success"
- FailURL   : default "https://www.trustly.com/fail"
- TemplateURL
- URLTarget
- MobilePhone
- Firstname
- Lastname
- NationalIdentificationNumber
- ShopperStatement
- NotificationURL: default "https://test.trustly.com/demo/notifyd_test"

This will return a **Trustly::Data::JSONRPCResponse**:

```ruby
> deposit.get_data('url')
=> "https://test.trustly.com/_/orderclient.php?SessionID=755ea475-dcf1-476e-ac70-07913501b34e&OrderID=4257552724&Locale=es_ES"

> deposit.get_data()
=> {
	"orderid" => "4257552724", 
	"url"     => "https://test.trustly.com/_/orderclient.php?SessionID=755ea475-dcf1-476e-ac70-07913501b34e&OrderID=4257552724&Locale=es_ES"
}
```

You can check if there was an error:

```ruby
> deposit.error?
=> true

> deposit.success?
=> false

> deposit.error_msg
=> "ERROR_DUPLICATE_MESSAGE_ID"
```

### Refund call

Required parameters:

- OrderID
- Amount
- Currency / default to "EUR"

Example:

```ruby
> api.refund({"OrderID"=>2205700591,"Amount"=>3,"Currency"=>"EUR"})
```


### Notifications

After a **deposit** or **refund** call, Trustly will send a notification to **NotificationURL**. If you are using rails the execution flow will look like this:

```ruby
def controller_action
	api = Trustly::Api::Signed.new({..}) 
	notification = Trustly::JSONRPCNotificationRequest.new(params)
	if api.verify_trustly_signed_notification(notification)
	   # do something with notification
	   ...
	   # reply to trustly
	   response = api.notification_response(notification,true)
	   render :text => response.json()
	else
		render :nothing => true, :status => 200
	end
end
``` 

You can use **Trustly::JSONRPCNotificationRequest** object to access data provided using the following methods:

```ruby
 notification.get_data
=> {"amount"=>"902.50", "currency"=>"EUR", "messageid"=>"98348932", "orderid"=>"87654567", "enduserid"=>"32123", "notificationid"=>"9876543456", "timestamp"=>"2010-01-20 14:42:04.675645+01", "attributes"=>{}}

> notification.get_method
=> "credit"

> notification.get_uuid
=> "258a2184-2842-b485-25ca-293525152425"

> notification.get_signature
=> "R9+hjuMqbsH0Ku ... S16VbzRsw=="

> notification.get_data('amount')
=> "902.50"
```



## Contributing

1. Fork it ( https://github.com/jcarreti/trustly-client-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
