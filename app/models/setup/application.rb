module Setup
  class Application
    include CenitScoped
    include NamespaceNamed
    include Slug

    BuildInDataType.regist(self).referenced_by(:namespace, :name).and('properties' => { 'configuration' => { 'type' => 'object' } })

    embeds_many :actions, class_name: Setup::Action.to_s, inverse_of: :application
    embeds_many :application_parameters, class_name: Setup::ApplicationParameter.to_s, inverse_of: :application

    accepts_nested_attributes_for :actions, :application_parameters, allow_destroy: true

    field :configuration_attributes, type: Hash, default: {}

    def configuration
      @config ||= configuration_model.new(configuration_attributes)
    end

    def configuration_schema
      schema =
        {
          type: 'object',
          properties: properties = {}
        }
      application_parameters.each { |p| properties[p.name] = p.schema }
      schema.stringify_keys
    end


    def configuration_model
      @mongoff_model ||= Mongoff::Model.for(data_type: self.class.data_type,
                                            schema: configuration_schema,
                                            name: self.class.configuration_model_name)
    end

    class << self

      def configuration_model_name
        "#{Setup::Application}::Config"
      end

      def stored_properties_on(record)
        stored = %w(namespace name)
        %w(actions application_parameters).each { |f| stored << f if record.send(f).present? }
        stored << 'configuration'
        stored
      end
    end
  end
end