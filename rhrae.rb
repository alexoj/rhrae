require 'capybara'
require 'capybara/poltergeist'
require 'open-uri'

# define poltergeist as the capybara driver
# this allows capybara to process pages that need
# javascript
Capybara.default_driver = :poltergeist

class AmbiguousSearchError < Exception
	# word->id dict
	attr_reader :alternatives

	def initialize(alternatives)
		@alternatives = alternatives
	end
end

class Entry
	attr_accessor :name, :origin, :definitions, :compound_forms

	def to_s
		result = "Name: #{name}\n"
		result += "Origin: #{origin}\n" if origin
		if not definitions.empty?
			definitions.each do |x|
				result += " - #{x}\n"
			end
		end
		if not compound_forms.empty?
			result += "Compound forms:\n"
			compound_forms.each do |x|
				result += " - #{x.to_s}\n"
			end
		end

		result
	end
end

class CompoundForm
	attr_accessor :name, :definitions

	def to_s
		result = "#{name}\n"

		if not definitions.empty?
			definitions.each do |x|
				result += "    - #{x}\n"
			end
		end

		result
	end
end

class RaeService
	include Capybara::DSL

	# returns a word array
	# or raises an ambiguous search exception
	def by_search(query)
		visit 'http://lema.rae.es/drae/srv/search?val=' +
			URI::encode(query)

		# do we have a disambiguation page?
		elem = all('body > ul > li > a')
		if not elem.empty?
			alternatives = {}

			elem.each do |x|
				word = x.text.chomp('.')
				id = /\Asearch\?id=(.+)\z/.match(x[:href]).captures[0]

				alternatives[word] = id
			end

			raise AmbiguousSearchError.new(alternatives)
		end

		return parse_results(all('body > div'))
	end

	def by_id(id)
		visit 'http://lema.rae.es/drae/srv/search?id=' +
			URI::encode(id)

		return parse_results(all('body > div'))
	end

	def parse_results(elements)
		result = []
		elements.each do |x|
			# remove superindices and fix up spacing
			name = x.all('p.p').first.all('span.f b, span.f span').map{|y| y.text if y.all('*').empty? }.join(' ')
			name = name.gsub('  ', ' ')
			name = name.gsub(' , ', ', ')
			name = name.gsub(' .', '.')
			name = name.chomp('.')
			name = name.chomp

			origin = x.all('span.a')
			if origin.empty?
				origin = nil
			else
				origin = origin.first.text

				# remove parenthesis
				m = /\A\((.*)\)\.?\z/.match(origin)
				if m
					origin = m.captures[0]
				end
			end

			definition_nodes = x.all(:xpath, "p[@class='q' and count(preceding-sibling::p[@class='p']/span[@class='k']) = 0]/span[@class='b']/..")
			definitions = definition_nodes.map {|y| y.all('.b').map{|z| z.text}.join}

			entry = Entry.new
			entry.name = name
			entry.origin = origin
			entry.definitions = definitions
			entry.compound_forms = []

			compound_nodes = x.all(:xpath, "p[@class='p']/span[@class='k']/..")

			i = 0
			compound_nodes.each do |y|
				i += 1

				compound = CompoundForm.new
				compound.name = y.text

				definition_nodes = x.all(:xpath, "p[@class='q' and count(preceding-sibling::p[@class='p']/span[@class='k']) = #{i}]/span[@class='k']/../span[@class='b']/..")
				compound.definitions = definition_nodes.map {|y| y.all('.b').map{|z| z.text}.join}

				entry.compound_forms << compound
			end

			result << entry
		end

		result
	end
end

rae = RaeService.new

print 'Search: '
query = gets.chomp

begin
	puts rae.by_search query
rescue AmbiguousSearchError => e
	puts "Ambiguous search detected, getting all alternatives..."
	e.alternatives.each do |word, id|
		puts "Getting results for #{word}..."
		puts rae.by_id id
	end
end
