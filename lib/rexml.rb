require 'diff/lcs'
require 'rexml/document'
require 'delegate'

module REXML

	class Text
		def deep_clone
			clone
		end
	end

	class HashableElementDelegator < DelegateClass(Element)
		def initialize(sub)
			super sub
		end
		def == other
			res = other.to_s.strip == self.to_s.strip
			res
		end

		def eql? other
			self == other
		end

		def[](k)
			r = super
			if r.kind_of? __getobj__.class
				self.class.new(r)
			else
				r
			end
		end

		def hash
			r = __getobj__.to_s.hash
			r
		end
	end

end
