require 'res/ir'

module Res
  module Parsers
    class AndroidJunit
      attr_accessor :io
     
      def initialize(instrument_output)
        result = Array.new
        result = parse(instrument_output)
        ir = ::Res::IR.new( :type        => 'AndroidJUnitRunner', 
                            :started     => "",
                            :finished    => Time.now(),
                            :results     => result
                            )
        @io = File.open("./instruments.res", "w")
        @io.puts ir.json
        @io.close
      end

      def parse(output)
        class_name = Array.new
        test = Array.new
        result = Array.new
        test = {
          type: "AndroidJUnit::Test",
          name: 'UNKNOWN',
          status: "passed"
        }
        File.open(output) do |f|
          f.each_line do |line|
            if line.include?("INSTRUMENTATION_STATUS_CODE")
              result.last[:children] << test
              test = {
                type: "AndroidJUnit::Test",
                name: 'UNKNOWN',
                status: "passed"
              }
            end

            if line.include?("class")
              line = line.gsub("INSTRUMENTATION_STATUS: class=", "").strip
              if !class_name.include? line
                class_name.push(line) 
                result << {
                  type: "AndroidJUnit::Class",
                  name: class_name.last,
                  children: Array.new
                }
              end
            elsif line.include?("test=")
              test[:name] = line.gsub("INSTRUMENTATION_STATUS: test=", "").strip
            elsif line.include?("Error in ")
              test[:status] = 'failed'
            end
          end
        end
        result
      end
    end
  end
end
