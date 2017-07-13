# Embulk::Input::Bigquery

This is Embulk input plugin from Bigquery.

## Installation

install it yourself as:

    $ embulk gem install embulk-input-bigquery

## Usage

```
in:
  type: bigquery
  project: 'project-name'
  keyfile: '/home/hogehoge/bigquery-keyfile.json'
  sql: 'SELECT price,category_id FROM [ecsite.products] GROUP BY category_id'
  columns:
    - {name: price, type: long}
    - {name: category_id, type: string}
  max: 2000
  synchronous_method: true
out:
  type: stdout
```

If, table name is changeable, then

```
in:
  type: bigquery
  project: 'project-name'
  keyfile: '/home/hogehoge/bigquery-keyfile.json'
  sql_erb: 'SELECT price,category_id FROM [ecsite.products_<%= params["date"].strftime("%Y%m")  %>] GROUP BY category_id'
  erb_params:
    date: "require 'date'; (Date.today - 1)"
  columns:
    - {name: price, type: long}
    - {name: category_id, type: long}
    - {name: month, type: timestamp, format: '%Y-%m', eval: 'require "time"; Time.parse(params["date"]).to_i'}
```

## Optional Configuration
This plugin uses the gem [`google-cloud(Google Cloud Client Library for Ruby)`](https://github.com/GoogleCloudPlatform/google-cloud-ruby) and queries data using the synchronous method or the asynchronous  method.
Therefore some optional configuration items comply with the Google Cloud Client Library.

### optional bigquery parameter 

The detail of follows params is [here](https://github.com/GoogleCloudPlatform/google-cloud-ruby/blob/master/google-cloud-bigquery/lib/google/cloud/bigquery/project.rb).

- max :
  - default value : **null** and null value is interpreted as no maximum row count in the Google Cloud Client Library. This param is supported only synchronous method.
- cache :
  - default value : **null** and null value is interpreted as true in the Google Cloud Client Library. 
- timeout :
  - default value : **null** and null value is interpreted as 10000 milliseconds in the Google Cloud Client Library. This param is supported only synchronous method.
- dryrun :
  - default value : **null** and null value is interpreted as false in the Google Cloud Client Library. This param is supported only synchronous method.
- standard_sql :
  - default value : **null** and null value is interpreted as true in the Google Cloud Client Library.
- legacy_sql :
  - default value : **null** and null value is interpreted as false in the Google Cloud Client Library.
- large_results :
  - default value : **null** and null value is interpreted as false in the Google Cloud Client Library. This param is supported only asynchronous method.
- write : 
  - default value : **null** and null value is interpreted as empty in the Google Cloud Client Library. This param is supported only asynchronous method.

### the bigquery method
Big query library in Google Cloud Client Library has [two methods](https://github.com/GoogleCloudPlatform/google-cloud-ruby/blob/master/google-cloud-bigquery/lib/google/cloud/bigquery/project.rb) for query.

The default method in this plugin is synchronous_method.
The logic which how select query method is [here](https://github.com/ykoyano/embulk-input-bigquery/blob/master/lib/embulk/input/bigquery.rb#L41).
 
- synchronous_method:
   - type : boolean
   - default value : **null**
   - This method uses `query` method in the Google Cloud Client Library.
   - It should be noted that the number of records for `query` method is **limited**. Therefore, if you get many records, you should use `query_job` method with asynchronous_method option.
- asynchronous_method:
   - type : boolean
   - default value : **null**
   - This method uses `query_job` method in the Google Cloud Client Library.
