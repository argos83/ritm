## Advanced settings

### SSL pass through

You can specify a list of HTTPS destinations for which RubyInTheMiddle won't perform any interception. So the client will handle the SSL connection
towards the end server directly (as a regular non-interception proxy would do).

The destinations will be matched via their `hostname:port` specification. You can include in this list strings (to match specific servers) or regular
expression for a more complex matching.

```ruby
Ritm.conf.misc.ssl_pass_through << 'www.google.com:443' # Don't intercept requests to www.google.com
Ritm.conf.misc.ssl_pass_through << /.+:(?!443)/ # Don't intercept SSL requests to any port different than 443
Ritm.conf.misc.ssl_pass_through << /.+\.google\.com:\d+)/ # Don't intercept SSL requests to any *.google.com server on any port
```

The `ssl_pass_through` setting is an ordinary ruby Array object. So you can update or reset settings using Array methods such as:

```ruby
Ritm.conf.misc.ssl_pass_through.clear # remove all the matchers
Ritm.conf.misc.ssl_pass_through.concat ['www.google.com:443', /.+:4443/] # add several matchers at once
```
