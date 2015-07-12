PACKAGES=""
# Standard shit
PACKAGES="${PACKAGES} git"
# So ruby compiles properly when installed with rbenv
PACKAGES="${PACKAGES} libssl-dev"
# For Phusion Passenger https APT repo
PACKAGES="${PACKAGES} apt-transport-https ca-certificates"

DEPLOY_HOME="/home/deploy"
CURRENT_USER=`whoami`

echo " -- Updating System"
#sudo apt-get -qq update
#sudo apt-get -yqq upgrade

echo " -- Installing Packages"
#sudo apt-get -qq install ${PACKAGES}

id -u deploy &> /dev/null

if [ $? -ne 0 ]; then
  echo " -- Creating user deploy"
  useradd -m -g deploy -s /bin/bash deploy

  echo " -- Adding user deploy to sudoers"
  chmod +w /etc/sudoers
  echo "deploy ALL=(ALL) ALL" >> /etc/sudoers
  chmod -w /etc/sudoers
else
  echo " -- deploy user already exists"
fi

if [ -d $DEPLOY_HOME/.rbenv ]; then
	echo " -- Rbenv already installed "
else
	echo " -- Installing Rbenv to ${DEPLOY_HOME}"
	sudo git clone https://github.com/sstephenson/rbenv.git ${DEPLOY_HOME}/.rbenv

	sudo git clone https://github.com/sstephenson/ruby-build.git ${DEPLOY_HOME}/.rbenv/plugins/ruby-build

	sudo chown -R deploy:deploy ${DEPLOY_HOME}/.rbenv
	sudo chmod 777 ${DEPLOY_HOME}/.bashrc
	sudo echo '# Initialize rbenv and source binaries in path' >> ${DEPLOY_HOME}/.bashrc
	sudo echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ${DEPLOY_HOME}/.bashrc
	sudo echo 'eval "$(rbenv init -)"' >> ${DEPLOY_HOME}/.bashrc
	sudo chmod 644 ${DEPLOY_HOME}/.bashrc
fi



apt-key list | grep 'Phusion' &> /dev/null

if [ $? -ne 0 ]; then
echo " -- Adding Phusion Repo"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
else
echo " -- Phusion Repo already added"
fi

#	Adding this caused a warning in apt that there was a duplicate.  Possible that it's redundant.

#if [ -f /etc/apt/sources.list.d/passenger.list ]; then
#echo " -- Phusion repo source in place"
#else
#echo " -- Creating Phusion repo source"
#	sudo touch /etc/apt/sources.list.d/passenger.list
#	sudo chmod 777 /etc/apt/sources.list.d/passenger.list
#	sudo echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list
#	sudo chown root: /etc/apt/sources.list.d/passenger.list
#	sudo chmod 600 /etc/apt/sources.list.d/passenger.list
#fi

# Here we search Installed: none because apt-cache outputs the version of package installed
# We can't reliably search for that, so instead we check if it's installed at all
apt-cache policy nginx-extras passenger | grep "Installed: (none)"  &> /dev/null

# If both nginx-extras and Passenger are installed
if [ $? -ne 0 ]; then
	echo " -- nginx and Passenger already Installed"
else
	echo " -- Installing nginx and Passenger"
	#sudo apt-get -qq update
	#sudo apt-get -qq install nginx-extras passenger
fi

echo " -- Configuring nginx and Passenger"
sudo sed -i 's/#passenger_root/passenger_root/g' /etc/nginx/nginx.conf
sudo sed -i 's/#passenger_ruby/passenger_ruby/g' /etc/nginx/nginx.conf

sudo service nginx restart

echo " -- All Done :) "
