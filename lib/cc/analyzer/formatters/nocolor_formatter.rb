require "tty/spinner"
require "active_support/number_helper"

module CC
  module Analyzer
    module Formatters
      class NoColorFormatter < Formatter

        def started
          puts("Starting analysis")
        end

        def write(data)
          if data.present?
            json = JSON.parse(data)
            if @active_engine
              json["engine_name"] = @active_engine.name
            end

            case json["type"].downcase
            when "issue"
              issues << json
            when "warning"
              warnings << json
            else
              raise "Invalid type found: #{json["type"]}"
            end
          end
        end

        def finished
          puts

          issues_by_path.each do |path, file_issues|
            puts("== #{path} (#{pluralize(file_issues.size, "issue")}) ==")

            IssueSorter.new(file_issues).by_location.each do |issue|
              if location = issue["location"]
                print(LocationDescription.new(location, ": "))
              end

              print(issue["description"])
              print(" [#{issue["engine_name"]}]")
              puts
            end
            puts
          end

          print("Analysis complete! Found #{pluralize(issues.size, "issue")}")
          if warnings.size > 0
            print(" and #{pluralize(warnings.size, "warning")}")
          end
          puts(".")
        end

        def engine_running(engine)
          @active_engine = engine
          with_spinner("Running #{engine.name}: ") do
            yield
          end
          @active_engine = nil
        end

        def failed(output)
          spinner.stop("Failed")
          puts("\nAnalysis failed with the following output:")
          puts output
          exit 1
        end

        private

        def spinner(text = nil)
          @spinner ||= Spinner.new(text)
        end

        def with_spinner(text)
          spinner(text).start
          yield
        ensure
          spinner.stop
          @spinner = nil
        end

        def issues
          @issues ||= []
        end

        def issues_by_path
          issues.group_by { |i| i['location']['path'] }.sort
        end

        def warnings
          @warnings ||= []
        end

        def pluralize(number, noun)
          "#{ActiveSupport::NumberHelper.number_to_delimited(number)} #{noun.pluralize(number)}"
        end
      end
    end
  end
end
