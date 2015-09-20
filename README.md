# Resque::Reports

Make your custom reports to CSV in background using Resque with simple DSL.

## Instalation

Add this line to your application's Gemfile:

```ruby
gem 'resque-reports'
```

And then execute:

    $ bundle

## Examples:

### Basic usage

``` ruby
class CsvUserReport < Ruby::Reports::CsvReport
  config(
    queue: :csv_reports,
    source: :select_data,
    directory: Rails.root.join('public/reports')
  )

  table do
    column 'ID', :id
    column 'Name', :name
  end

  def query
    @query ||= Query.new
  end

  class Query
    def select_data
      User.all
    end
  end
end
```

in you controller:

``` ruby
class ReportsController < ApplicationController
  def create
    job_id = report.bg_build

    render json: {job_id: job_id}
  end

  def show
    if report.exists?
      send_file(report.filename, filename: 'users.csv')
    else
      redirect :back
    end
  end

  private

  def report
    @report ||= CsvUserReports.new
  end
end
```

### Advanced usage

``` ruby
class CsvUserReports < Ruby::Reports::CsvReport
  config(
    queue: :csv_reports,
    source: :select_data,
    encoding: Ruby::Reports::CP1251,
    directory: Rails.root.join('public/reports')
  )

  attr_reader :age, :date
  def initialize(age, date)
    super
    @age = age
    @date = date
  end

  table do
    column 'ID', :id
    column 'Name', :name
    column 'Created at', :created_at, formatter: :date
  end

  def query
    @query ||= Query.new(self)
  end

  def formatter
    @formatter ||= Formatter.new
  end

  class Query
    pattr_initialize :report
    def select_data
      User.where('age = ? and create_at >= ?', [report.age, report.date])
    end
  end

  class Formatter
    def date(value)
      Date.parse(value).strftime('%d.%m.%Y')
    end
  end
end
```

in you controller:

``` ruby
class ReportsController < ApplicationController
  #...

  private

  def report
    @report ||= CsvUserReports.new(params[:age], params[:date])
  end
end
```

Copyright (c) 2015 Dolganov Sergey, released under the MIT license
