require "reflection/version"

module Reflection
  def self.included(klass)
    klass.extend Definition
    klass.extend Arguments
    klass.extend Properties
    
    klass.instance_exec do 
      define_method :initialize do |*args|
        pre_initialize
        preprocess_arguments(args)
        # NOTE: a `pre_initialize` invokation by default with every argument defining an no-op method 
        klass.reflection.arguments.each_with_index do |arg, index|
          initialize_argument = args[index]
          arg.validate!(initialize_argument)
          instance_exec(initialize_argument, &arg.execute)
        end
        # NOTE: a `post_initialize` invokation by default with every argument defining an no-op method 
        post_initialize
      end
    end
  end

  # Generate a no-op method that can be overriden in the Class
  # This is the first method called in the #initialize
  def pre_initialize ; end

  # The incoming arguments may need to be processed in the initialize
  def preprocess_arguments(args)
    args
  end

  # Generate a no-op method that can be overriden in the Class
  # This method is called as a final step in the #initalize
  def post_initialize ; end

  module Definition
    def reflection
      @reflection ||= ReflectionDefinition.new 
    end

    class ReflectionDefinition
      def arguments
        @arguments ||= []
      end

      def properties
        @properties ||= []
      end

      def property(name)
        properties.find { |p| p.name.to_sym == name.to_sym }
      end
    end

    class PropertyFailsToConformToType < RuntimeError ; end
    class PropertyFailsToResponToError < PropertyFailsToConformToType ; end
    class PropertyFailsToBeClassError < PropertyFailsToConformToType ; end

    class Property
      attr_accessor :name, :type, :desc, :execute

      def examples
        @examples ||= []
      end

      def validate!(value)
        type.each do |t|
          if t.is_a?(Symbol)
            raise PropertyFailsToResponToError.new(self) unless value.respond_to?(t)
          elsif t.is_a?(Class)
            raise PropertyFailsToBeClassError.new(self) unless value.is_a?(t)
          end
        end
      end
    end
  end

  class ReflectionArgPropBuilder
    def build(name, &block)  
      argument.name = name
      instance_exec(&block)
      argument
    end

    attr_reader :argument

    def initialize
      @argument = Definition::Property.new
    end

    def type(*args)
      argument.type = args.flatten
    end

    def desc(text)
      argument.desc = text
    end

    def example(text)
      argument.examples.push(text)
    end

    def execute(&block)
      argument.execute = block
    end
  end

  module Arguments
    def argument(name, &block)
      built_argument = ReflectionArgPropBuilder.new.build(name, &block)
      reflection.arguments.push(built_argument)
    end
  end

  module Properties
    def property(name, &block)
      built_property = ReflectionArgPropBuilder.new.build(name, &block)
      reflection.properties.push(built_property)
      define_method(name, built_property.execute) if built_property.execute
    end
  end
end
