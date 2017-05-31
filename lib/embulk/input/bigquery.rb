require "embulk/input/bigquery/version"
require "google/cloud/bigquery"
require 'erb'

module Embulk
  module Input
    class InputBigquery < InputPlugin
			Plugin.register_input('bigquery', self)

			def self.transaction(config, &control)
				sql = config[:sql]
				params = {}
				unless sql
					sql_erb = config[:sql_erb]
					erb = ERB.new(sql_erb)
					erb_params = config[:erb_params]
					erb_params.each do |k, v|
						params[k] = eval(v)
					end

					sql = erb.result(binding)
				end

				task = {
					project: config[:project],
					keyfile: config[:keyfile],
					sql: sql,
					columns: config[:columns],
					params: params,
					synchronous_method: config[:synchronous_method],
					asynchronous_method: config[:asynchronous_method],
					dataset: config[:dataset],
					table: config[:table],
					option: {
						cache: config[:cache],
						standard_sql: config[:standard_sql],
						legacy_sql: config[:legacy_sql],
					}
				}

				if task[:synchronous_method] || !task[:asynchronous_method]
					task[:option].merge!(
						{
							max: config[:max],
							timeout: config[:timeout],
							dryrun:  config[:dryrun],
						}
					)
				else
					task[:option].merge!(
						{
							large_results: config[:legacy_sql],
							write: config[:write],
						}
					)
				end

				columns = []
				config[:columns].each_with_index do |c, i|
					columns << Column.new(i, c['name'], c['type'].to_sym)
				end

				yield(task, columns, 1)

				return {}
			end

			def run
				bq = Google::Cloud::Bigquery.new(project: @task[:project], keyfile: @task[:keyfile])
				params = @task[:params]
				@task[:columns] = values_to_sym(@task[:columns], 'name')
				option = keys_to_sym(@task[:option])
				if @task[:synchronous_method] || @task[:asynchronous_method].nil?
					run_synchronous_query(bq, option)
				else
					if @task[:dataset]
						dataset = bq.dataset(@task[:dataset])
						option[:table] = dataset.table(@task[:table])
						if option[:table].nil?
							option[:table] = dataset.create_table(@task[:table])
						end
					end
					run_asynchronous_query(bq, option)
				end
				@page_builder.finish
				return {}
			end

			def run_synchronous_query(bq, option)
				rows = bq.query(@task[:sql], **option)
				rows.each do |row|
					record = extract_record(row)
					@page_builder.add(record)
				end
			end

			def run_asynchronous_query(bq, option)
				job = bq.query_job(@task[:sql], **option)
				job.wait_until_done!
				return {} if job.failed?
				results = job.query_results
				while results
					results.each do |row|
						record = extract_record(row)
						@page_builder.add(record)
					end
					results = results.next
				end
			end

			def extract_record(row)
				columns = []
				@task[:columns].each do |c|
					val = row[c['name']]
					if c['eval']
						val = eval(c['eval'], binding)
					end
					columns << val
				end
				return columns
			end

			def values_to_sym(hashs, key)
				hashs.map do |h|
					h[key] = h[key].to_sym
					h
				end
			end

			def keys_to_sym(hash)
				ret = {}
				hash.each do |key, value|
					ret[key.to_sym] = value
				end
				ret
			end
    end
  end
end
