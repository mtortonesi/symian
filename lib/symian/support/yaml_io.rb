require 'yaml'

module Symian
  module YAMLSerializable
    def to_yaml_properties
      self.class.const_get('TRACED_ATTRIBUTES').map{|attr| "@#{attr.to_s}"}
    end
  end
end
