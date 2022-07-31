# mysql2postgres - MySQL to PostgreSQL Data Translation

[![Run Linters](https://github.com/AlphaNodes/mysql2postgres/workflows/Run%20Rubocop/badge.svg)](https://github.com/AlphaNodes/mysql2postgres/actions/workflows/rubocop.yml) [![Run Tests](https://github.com/AlphaNodes/mysql2postgres/workflows/Tests/badge.svg)](https://github.com/AlphaNodes/mysql2postgres/actions/workflows/tests.yml)

Convert MySQL database to PostgreSQL database.

## Requirements

- Ruby `>= 2.7` (only maintained ruby versions are supported)

## Installation

Add Gem to your Gemfile:

```ruby
gem 'mysql2postgres'
```

## Configuration

Configuration is written in [YAML format](http://www.yaml.org/ "YAML Ain't Markup Language")
and passed as the first argument on the command line.

Configuration file has be provided with config/database.yml, see [config/default.database.yml](config/default.database.yml) for an example and for configuration information.

## Usage

After providing settings, start migration with

```sh
# set destination to use
MYSQL2POSTGRES_ENV=test
# use can also use (MYSQL2POSTGRES_ENV is used, if both are defined)
RAILS_ENV=test

# with default configuration, which use config/database.yml
bundle exec mysql2postgres
# OR with specified configuration file
bundle exec mysql2postgres /home/you/mysql2postgres.yml
```

## Tests

```sh
rake test
```

## License

Licensed under [the MIT license](MIT-LICENSE).
