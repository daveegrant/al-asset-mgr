#!/bin/sh

sudo npm -g install bower
sudo npm -g install gulp
sudo npm -g install forever

cd ..
npm install
bower install
gulp build

cd /etc
sudo ln -s /space/projects/al-asset-mgr.live/etc/prod al-asset-mgr
cd /etc/init.d
sudo ln -s /space/projects/al-asset-mgr.live/etc/init.d/node-express-service al-asset-mgr
sudo chkconfig --add al-asset-mgr
sudo chkconfig --levels 2345 al-asset-mgr on
