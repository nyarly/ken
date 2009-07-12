module Ken
  class Resource
    include Extlib::Assertions
    
    FETCH_DATA_QUERY = {
      # :id => id, # needs to be merge!d in instance method
      :name => nil,
      :"ken:type" => [{
        :id => nil,
        :name => nil,
        :properties => [{
          :id => nil,
          :name => nil,
          :expected_type => nil,
          :unique => nil,
          :reverse_property => nil,
          :master_property => nil,
        }]
      }],
      :"/type/reflect/any_master" => [
        {
          :id => nil,
          :link => nil,
          :name => nil,
          :optional => true
        }
      ],
      :"/type/reflect/any_reverse" => [
        {
          :id => nil,
          :link => nil,
          :name => nil,
          :optional => true
        }
      ],
      :"/type/reflect/any_value" => [
        {
          :link => nil,
          :value => nil,
          :optional => true
          # TODO: support multiple language
          # :lang => "/lang/en",
          # :type => "/type/text"
        }
      ]
    }
    
    # initializes a resource using a json result
    def initialize(data)
      assert_kind_of 'data', data, Hash
      @schema_loaded, @attributes_loaded, @data = false, false, data
      @data_fechted = data["/type/reflect/any_master"] != nil
    end
    
    # resource id
    # @api public
    def id
      @data["id"] || ""
    end
    
    # resource name
    # @api public
    def name
      @data["name"] || ""
    end
    
    # @api public
    def to_s
      name || id || ""
    end
    
    # @api public
    def inspect
      result = "#<Resource id=\"#{id}\" name=\"#{name || "nil"}\">"
    end
    
    # returns all assigned types
    # @api public
    def types
      load_schema! unless schema_loaded?
      @types
    end
    
    # returns all available views based on the assigned types
    # @api public
    def views
      @views ||= Ken::Collection.new(types.map { |type| Ken::View.new(self, type) })
    end
    
    # returns all the properties from all assigned types
    # @api public
    def properties
      @properties = Ken::Collection.new
      types.each do |type|
        @properties.concat(type.properties)
      end
      @properties
    end
    
    # returns all attributes for every type the resource is an instance of
    # @api public
    def attributes
      load_attributes! unless attributes_loaded?
      @attributes.values
    end
    
    # returns true if type information is already loaded
    # @api public
    def schema_loaded?
      @schema_loaded
    end
    
    # returns true if attributes are already loaded
    # @api public
    def attributes_loaded?
      @attributes_loaded
    end
    # returns true if json data is already loaded
    # @api public
    def data_fetched?
      @data_fetched
    end
    
    private
    # executes the fetch data query in order to load the full set of types, properties and attributes
    # more info at http://lists.freebase.com/pipermail/developers/2007-December/001022.html
    # @api private
    def fetch_data
      return @data if @data["/type/reflect/any_master"]
      @data = Ken.session.mqlread(FETCH_DATA_QUERY.merge!(:id => id))
    end
    
    # loads the full set of attributes using reflection
    # information is extracted from master, value and reverse attributes
    # @api private
    def load_attributes!
      fetch_data unless data_fetched?
      # master & value attributes
      raw_attributes = Ken::Util.convert_hash(@data["/type/reflect/any_master"])
      raw_attributes.merge!(Ken::Util.convert_hash(@data["/type/reflect/any_value"]))
      @attributes = {}
      raw_attributes.each_pair do |a, d|
        properties.select { |p| p.id == a}.each do |p|
          @attributes[p.id] = Ken::Attribute.create(d, p)
        end
      end
      # reverse properties
      raw_attributes = Ken::Util.convert_hash(@data["/type/reflect/any_reverse"])
      raw_attributes.each_pair do |a, d|
        properties.select { |p| p.master_property == a}.each do |p|
          @attributes[p.id] = Ken::Attribute.create(d, p)
        end
      end
      @attributes_loaded = true
    end
    
    # loads the resource's metainfo
    # @api private
    def load_schema!
      fetch_data unless data_fetched?
      @types = Ken::Collection.new(@data["ken:type"].map { |type| Ken::Type.new(type) })
      @schema_loaded = true
    end
  end # class Resource
end # module Ken