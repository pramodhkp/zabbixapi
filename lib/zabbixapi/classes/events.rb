class ZabbixApi
  class Events < Basic

    def initialize(client)
      @client = client
      @request = {
        :method => "event.get",
        :params => {
          :output => "extend",
          :select_items => "extend",
          :select_functions => "extend"
        }
      }
    end

    def add_params(params)
      params.each do |k, v|
        @request[:params][k.to_sym] = v
      end
      self
    end

    def filter(filter_hash)
      @request[:filter] = {}
      filter_hash.each do |k, v|
        @request[:filter][k.to_sym] = v
      end
      self
    end

    def method_name
      "event"
    end

    def indentify
      "description"
    end

    def dump_by_id(data)
      log "[DEBUG] Call dump_by_id with parametrs: #{data.inspect}"

      @client.api_request(@request)
    end

    def safe_update(data)
      log "[DEBUG] Call update with parametrs: #{data.inspect}"

      dump = {}
      item_id = data[key.to_sym].to_i
      dump_by_id(key.to_sym => data[key.to_sym]).each do |item|
        dump = symbolize_keys(item) if item[key].to_i == data[key.to_sym].to_i
      end

      expression = dump[:items][0][:key_]+"."+dump[:functions][0][:function]+"("+dump[:functions][0][:parameter]+")"
      dump[:expression] = dump[:expression].gsub(/\{(\d*)\}/,"{#{expression}}") #TODO ugly regexp
      dump.delete(:functions)
      dump.delete(:items)

      old_expression = data[:expression]
      data[:expression] = data[:expression].gsub(/\{.*\:/,"{") #TODO ugly regexp
      data.delete(:templateid)

      log "[DEBUG] expression: #{dump[:expression]}\n data: #{data[:expression]}"

      if hash_equals?(dump, data)
        log "[DEBUG] Equal keys #{dump} and #{data}, skip update"
        item_id
      else
        data[:expression] = old_expression
        # disable old trigger
        log "[DEBUG] disable :" + @client.api_request(:method => "#{method_name}.update", :params => [{:triggerid=> data[:triggerid], :status => "1" }]).inspect
        # create new trigger
        data.delete(:triggerid)
        create(data)
      end
    end
  end
end