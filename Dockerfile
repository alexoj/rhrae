from ubuntu:trusty

run apt-get update --fix-missing
run apt-get install -y --no-install-recommends ruby ruby-dev zlib1g-dev \
	build-essential phantomjs
run gem install bundler

run useradd -m user

add . /home/user
workdir /home/user

run bundle

cmd bundle exec ruby rhrae.rb
