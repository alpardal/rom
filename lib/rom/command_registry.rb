require 'rom/commands/result'

module ROM
  # Command registry exposes "try" interface for executing commands
  #
  # @public
  class CommandRegistry < Registry
    class Evaluator
      include Concord.new(:registry)

      private

      # Call a command when method is matching command name
      #
      # TODO: this will be replaced by explicit definition of methods for all
      #       registered commands
      #
      # @api public
      def method_missing(name, *args, &block)
        command = registry[name]

        super unless command

        if args.size > 1
          command.new(*args, &block)
        else
          command.call(*args, &block)
        end
      end
    end

    # Try to execute a command in a block
    #
    # @example
    #
    #   rom.command(:users).try { create(name: 'Jane') }
    #   rom.command(:users).try { update(:by_id, 1).set(name: 'Jane Doe') }
    #   rom.command(:users).try { delete(:by_id, 1) }
    #
    # @return [Commands::Result]
    #
    # @api public
    def try(&f)
      Commands::Result::Success.new(Evaluator.new(self).instance_exec(&f))
    rescue CommandError => e
      Commands::Result::Failure.new(e)
    end
  end
end
