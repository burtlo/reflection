require 'spec_helper'

class Ball
  include Reflection

  argument :radius do
    desc "A ball is a sphere and can be described with a single measurement."

    example <<~EXAMPLE
      # Create a ball with a radius of 3.0
      Ball.new(3.0)
    EXAMPLE

    example <<~EXAMPLE
      # Create a ball with a radius of 5
      Ball.new("5")
    EXAMPLE

    type Numeric

    # NOTE: This execution happens in the initialize but the name execute doesn't
    #   really give indication of that when a better name could more clearly describe it.
    execute do |radius|
      @radius = radius
    end
  end

  property :radius do
    desc "The radius of the ball"

    example <<~EXAMPLE
      # Create a ball with a radius of 3.0
      ball = Ball.new(3.0)
      ball.radius # => 3.0
    EXAMPLE

    type :to_f

    # NOTE: Properties that return instance variables should be
    #   easier to define and more clear what is going on...  
    execute do
      @radius.to_f
    end
  end

  property :volume do
    desc "The volume of the ball calculated from the radius"

    example <<~EXAMPLE
      # Create a ball with a radius of 3.0
      ball = Ball.new(3.0)
      ball.volume # => 113.1
    EXAMPLE

    type :to_f

    execute do
      (4.0 / 3.0 * Math::PI * (radius ** 3.0)).round(1)
    end
  end
end

RSpec.describe Ball do
  context "valid radius" do
    let(:subject) { Ball.new(3.0) }
    it "has a volume" do
      expect(subject.volume).to eq(113.1)
    end
  end

  context "invalid radius" do
    it "generates an error" do
      expect { described_class.new('tree-point-oh') }.to raise_error(Reflection::Definition::PropertyFailsToConformToType)
    end
  end
end

RSpec.describe Ball do
  let(:subject) { Ball.reflection }

  it "has a reflection" do
    expect(subject).not_to be_nil
  end

  describe "arguments" do
    it "has one argument" do
      expect(subject.arguments.count).to eq(1)
    end
    
    describe "radius" do
      let(:subject) { Ball.reflection.arguments.first }

      it "has a name" do
        expect(subject.name).to eq(:radius)
      end

      it "has a type" do
        expect(subject.type).to eq([Numeric])
      end

      it "has examples" do
        expect(subject.examples.count).to eq(2)
      end
    end
  end

  describe "properties" do
    it "has two properties" do
      expect(subject.properties.count).to eq(2)
    end
    
    describe "radius" do
      let(:subject) { Ball.reflection.property(:radius) }
      
      it "exists" do
        expect(subject).not_to be_nil
      end
      
      it "has a type" do
        expect(subject.type).to eq([:to_f])
      end
      
      it "has an example" do
        expect(subject.examples).not_to be_empty
      end
    end

    describe "volume" do
      let(:subject) { Ball.reflection.property(:volume) }
      
      it "exists" do
        expect(subject).not_to be_nil
      end
      
      it "has a type" do
        expect(subject.type).to eq([:to_f])
      end

      it "has an example" do
        expect(subject.examples).not_to be_empty
      end
    end
  end
end