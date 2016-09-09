# msgpack-inspect

This is a command line tool to inspect/show a data serialized by [MessagePack](http://msgpack.org/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'msgpack-inspect'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install msgpack-inspect

## Usage

```
Usage: msgpack-inspect [options] FILE

Options:

    -f, --format FORMAT              output format of inspection result (yaml/json) [default: yaml]
    -r, --require LIB                ruby file path to require (to load ext type definitions)
    -h, --help                       Show this message
```

FILE is a file which msgpack binary stored. Specify `-` to inspect data from STDIN.
This command shows the all data contained in specified format (YAML in default).

```
---
- :format: :false
  :header: c2
  :data: c2
  :value: false
- :format: :true
  :header: c3
  :data: c3
  :value: true
```

TODO: show more example

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/tafomoris/msgpack-inspect].

