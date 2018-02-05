
include hello

task :default => :test

desc 'rake.rb seems working!'
task :test do
	puts "testing from Rake!"
end

namespace 'get_doc' do

	desc 'generates documentation'
	task :trial do
		puts "hello from Rake!"
	end

end

