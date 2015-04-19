require "fibre"
require "eventmachine"

require "emmy_machine/version"
require "emmy_machine/connection"
require "emmy_machine/class_methods"

module EmmyMachine
  include ClassMethods
  extend self
end
