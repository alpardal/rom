require 'rom/setup/schema_dsl'
require 'rom/setup/mapper_dsl'
require 'rom/setup/command_dsl'

require 'rom/setup/finalize'

module ROM
  # Exposes DSL for defining schema, relations, mappers and commands
  #
  # @public
  class Setup
    include Equalizer.new(:repositories, :env)

    # @api private
    attr_reader :repositories, :env

    # @api private
    def initialize(repositories)
      @repositories = repositories
      @schema = {}
      @relations = {}
      @mappers = []
      @commands = {}
      @adapter_relation_map = {}
      @env = nil
    end

    # Schema definition DSL
    #
    # @example
    #
    #   setup.schema do
    #     base_relation(:users) do
    #       repository :sqlite
    #
    #       attribute :id
    #       attribute :name
    #     end
    #   end
    #
    # @api public
    def schema(&block)
      SchemaDSL.new(self, @schema, &block)
    end

    # Relation definition DSL
    #
    # @example
    #
    #   setup.relation(:users) do
    #     def names
    #       project(:name)
    #     end
    #   end
    #
    # @api public
    def relation(name, &block)
      @relations.update(name => block)
    end

    # Mapper definition DSL
    #
    # @example
    #
    #   setup.mappers do
    #     define(:users) do
    #       model name: 'User'
    #     end
    #
    #     define(:names, parent: :users) do
    #       exclude :id
    #     end
    #   end
    #
    # @api public
    def mappers(&block)
      dsl = MapperDSL.new(&block)
      @mappers.concat(dsl.mappers)
    end

    # Command definition DSL
    #
    # @example
    #
    #   setup.commands(:users) do
    #     define(:create) do
    #       input NewUserParams
    #       validator NewUserValidator
    #       result :one
    #     end
    #
    #     define(:update) do
    #       input UserParams
    #       validator UserValidator
    #       result :many
    #     end
    #
    #     define(:delete) do
    #       result :many
    #     end
    #   end
    #
    # @api public
    def commands(name, &block)
      dsl = CommandDSL.new(&block)
      @commands.update(name => dsl.commands)
    end

    # Finalize the setup
    #
    # @return [Env] frozen env with access to repositories, schema, relations,
    #                mappers and commands
    #
    # @api public
    def finalize
      raise EnvAlreadyFinalizedError if env

      finalize = Finalize.new(
        repositories, @schema, @relations, @mappers, @commands
      )

      @env = finalize.run!
    end

    # Returns repository identified by name
    #
    # @return [Repository]
    #
    # @api private
    def [](name)
      repositories.fetch(name)
    end

    # Hook for respond_to? used internally
    #
    # @api private
    def respond_to_missing?(name, _include_context = false)
      repositories.key?(name)
    end

    private

    # Returns repository if method is a name of a registered repository
    #
    # @return [Repository]
    #
    # @api private
    def method_missing(name, *)
      if repositories.key?(name)
        repositories.fetch(name)
      else
        super
      end
    end
  end
end
