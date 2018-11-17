# frozen_string_literal: true

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'parslet'
require 'pp'

tree = { bud: { stem: [] } }

class Spring < Parslet::Transform
  rule(stem: sequence(:branches)) do
    { stem: (branches + [{ branch: :leaf }]) }
  end
end
class Summer < Parslet::Transform
  rule(stem: subtree(:branches)) do
    new_branches = branches.map { |_b| { branch: %i[leaf flower] } }
    { stem: new_branches }
  end
end
class Fall < Parslet::Transform
  rule(branch: sequence(:x)) do
    x.each { |e| puts 'Fruit!' if e == :flower }
    x.each { |e| puts 'Falling Leaves!' if e == :leaf }
    { branch: [] }
  end
end
class Winter < Parslet::Transform
  rule(stem: subtree(:x)) do
    { stem: [] }
  end
end

def do_seasons(tree)
  [Spring, Summer, Fall, Winter].each do |season|
    p "And when #{season} comes"
    tree = season.new.apply(tree)
    pp tree
    puts
  end
  tree
end

# What marvel of life!
tree = do_seasons(tree)
tree = do_seasons(tree)
